---
layout: post
title: "A Practical Dive Into Late Materialization in arrow-rs Parquet Reads"
description: "How arrow-rs pipelines predicates and projections to minimize work during Parquet scans"
date: "2025-12-03 00:00:00"
author: hhhizzz
categories: [application]
translations:
  - language: 简体中文
    post_id: 2025-12-03-parquet-late-materialization-deep-dive-zh
---
<!--
{% comment %}
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to you under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
{% endcomment %}
-->

This article dives into the decisions and pitfalls of Late Materialization in `arrow-rs` (the engine powering DataFusion). We'll see how a humble file reader has evolved into something with the complex logic of a query engine—effectively becoming a **tiny query engine** in its own right.

## 1. Why Late Materialization?

Columnar reads are a constant battle between **I/O bandwidth** and **CPU decode costs**. While skipping data is generally good, the act of skipping itself carries a computational cost. The goal in `arrow-rs` is **pipeline-style late materialization**: evaluate predicates first, then access projected columns, keeping the pipeline tight at the page level to ensure minimal reads and minimal decode work.

Borrowing Abadi's classification from his [paper](https://www.cs.umd.edu/~abadi/papers/abadiicde2007.pdf), the target architecture is **LM-pipelined**: interleaving predicates and data column access instead of reading all columns at once and trying to **stitch them back together** into rows.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig1.png" alt="LM-pipelined late materialization pipeline" width="100%" class="img-responsive">
</figure>

Take `SELECT B, C FROM table WHERE A > 10 AND B < 5` as a running example:

1.  Read column `A`, build a `RowSelection` (a sparse mask), and obtain the initial set of surviving rows.
2.  Use that `RowSelection` to read column `B`, decoding and filtering on the fly to make the selection even sparser.
3.  Use the refined `RowSelection` to read column `C` (a projection column), decoding only the final surviving rows.

The rest of this post zooms into how the code makes this path work.

---

## 2. Late Materialization in the Rust Parquet Reader

### 2.1 LM-pipelined

"LM-pipelined" might sound like something from a textbook. In `arrow-rs`, it simply refers to a pipeline that runs sequentially: "read predicate column → generate row selection → read data column". This contrasts with a **parallel** strategy, where all predicate columns are read simultaneously. While parallelism can maximize multi-core CPU usage, the pipelined approach is often superior in columnar storage because each filtering step drastically reduces the amount of data subsequent steps need to read and parse.

To achieve this, we defined these core roles:

-   **[ReadPlan](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L302) / [ReadPlanBuilder](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L34)**: Encodes "which columns to read and with what row subset" into a plan. It does not pre-read all predicate columns. It reads one, tightens the selection, and then moves on.
-   **[RowSelection](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L139)**: Describes "skip/select N rows" via RLE (`RowSelector::select/skip`) or a bitmask. This is the core mechanism that carries sparsity through the pipeline.
-   **[ArrayReader](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/array_reader/mod.rs#L85)**: The component responsible for I/O and decoding. It receives a `RowSelection` and decides which pages to read and which values to decode.

> `RowSelection` can switch dynamically between RLE (selectors) and bitmasks. Bitmasks are faster when gaps are tiny and sparsity is high; RLE is friendlier to large, page-level skips. Details on this trade-off appear in section 3.1.

Consider a query with two filters: `SELECT * FROM table WHERE A > 10 AND B < 5`:

1.  **Initial**: `selection = None` (equivalent to "select all").
2.  **Read A**: `ArrayReader` decodes column A in batches; the predicate builds a boolean mask; `RowSelection::from_filters` turns it into a sparse selection.
3.  **Tighten**: `ReadPlanBuilder::with_predicate` chains the new mask via `RowSelection::and_then`.
4.  **Read B**: Build column B's reader with the current `selection`; the reader only performs I/O and decode for selected rows, producing an even sparser mask.
5.  **Merge**: `selection = selection.and_then(selection_b)`; projection columns now decode a tiny row set.

**Code locations and sketch**:

```rust
// Close to the flow in read_plan.rs (simplified)
let mut builder = ReadPlanBuilder::new(batch_size);

// 1) Inject external pruning (e.g., Page Index):
builder = builder.with_selection(page_index_selection);

// 2) Append predicates serially:
for predicate in predicates {
    builder = builder.with_predicate(predicate); // internally uses RowSelection::and_then
}

// 3) Build readers; all ArrayReaders share the final selection strategy
let plan = builder.build();
let reader = ParquetRecordBatchReader::new(array_reader, plan);
```

I've drawn a simple flowchart to help you understand:

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig2.jpg" alt="Predicate-first pipeline flow" width="100%" class="img-responsive">
</figure>

Once the pipeline exists, the next question is **how to represent and combine these sparse selections** (the **Row Mask** in the diagram), which is where `RowSelection` comes in.

### 2.2 Logical ops on row selectors (`RowSelection::and_then`)

`RowSelection`—defined in `selection.rs`—is the token that every stage passes around. It mostly uses RLE (`RowSelector::select/skip(len)`) to describe sparse ranges. `and_then` is the core operator for "apply one selection to another": left-hand side is "rows already allowed," right-hand side further filters those rows, and the output is their boolean AND.

**Walkthrough**:

* **Input Selection A (already filtered)**: `[Skip 100, Select 50, Skip 50]` (physical rows 100-150 are selected)
* **Input Predicate B (filters within A)**: `[Select 10, Skip 40]` (within the 50 selected rows, only the first 10 survive B)

**How it runs**:
Think of it like a zipper: we traverse both lists simultaneously...

1. **First 100 rows**: A is Skip → result is Skip 100.
2. **Next 50 rows**: A is Select. Look at B:
   * B's first 10 are Select → result Select 10.
   * B's remaining 40 are Skip → result Skip 40.
3. **Final 50 rows**: A is Skip → result Skip 50.

**Result**: `[Skip 100, Select 10, Skip 90]`.

This keeps narrowing the filter while touching only lightweight metadata—no data copies. The implementation is a two-pointer linear scan; complexity is linear in selector segments. The sooner predicates shrink the selection, the cheaper later scans become.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig3.jpg" alt="RowSelection logical AND walkthrough" width="100%" class="img-responsive">
</figure>

## 3. Engineering Challenges

It sounds simple enough in theory, but implementing Late Materialization in a production-grade system like `arrow-rs` is an absolute **engineering nightmare**. Historically, this stuff was so tricky that it was locked away in proprietary engines. In the open source world, we've been grinding away at this for years (just look at [the DataFusion ticket](https://github.com/apache/datafusion/issues/3463)), and finally, we can **flex our muscles** and go toe-to-toe with full materialization. To pull this off, we had to tackle some serious headaches.

### 3.1 Adaptive RowSelection Policy (Bitmask vs. RLE)

- **Ultra sparse** (e.g., 1 row every 10,000): Using a bitmask here is just wasteful (1 bit per row adds up), whereas RLE is super clean—just a few selectors and you're done.
- **Sparse but with tiny gaps** (e.g., "read 1, skip 1"): RLE creates a fragmented mess that makes the decoder work overtime; here, bitmasks are way more efficient.

Since both have their pros and cons, we decided to get the **best of both worlds** with an adaptive strategy:

- We look at the average run length of the selectors and compare it to a threshold (currently 32). If things are getting too choppy, we switch to bitmasks; otherwise, we stick with selectors (RLE).
- **The Safety Net**: Bitmasks look great until you hit Page Pruning, which can cause a nasty "missing page" panic because the mask might blindly try to filter rows from pages that were never even read. The `RowSelection` logic watches out for this **recipe for disaster** and forces a switch back to RLE to keep things from crashing (see 3.1.2).

#### 3.1.1 Where did the threshold come from?

The number 32 wasn't just pulled out of thin air. It came from a data-driven "face-off" using various distributions (even spacing, exponential sparsity, random noise). It does a solid job of distinguishing between "choppy but dense" and "long skip regions." In the future, we might get even fancier with heuristics based on data types.

The chart below shows the showdown between selectors (RLE) and bitmasks. Vertical axis is time (lower is better), horizontal is average run length. You can see the performance curves cross right around 32.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.1.1.png" alt="Bitmask vs RLE benchmark threshold" width="100%" class="img-responsive">
</figure>

#### 3.1.2 The Bitmask Trap: Missing Pages

Bitmasks seem perfect on paper, but they hide a nasty trap. When combined with **Page Pruning**, it's basically a **head-on collision**.

Before we get into the weeds, a quick refresher on Pages (more in Section 3.2). Parquet files are sliced into Pages. To save I/O, if we know a page is useless, we **don't even touch it**—no decompression, no decoding. The `ArrayReader` doesn't even know it exists.

**The Scene of the Crime:**

Imagine reading a chunk of data where only the first and last rows matter; the middle four rows are junk. It just so happens those middle four rows sit in their own Page, so that Page gets completely pruned.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig1.jpg" alt="Page pruning example with only first and last rows kept" width="100%" class="img-responsive">
</figure>

If we use RLE (`RowSelector`), executing `Skip(4)` is smooth sailing: we just jump over the gap.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig3.jpg" alt="RLE skipping pruned pages safely" width="100%" class="img-responsive">
</figure>

**The Problem:**

If we use a bitmask, the Reader blindly tries to decode all 6 rows first, intending to filter them later. But that middle Page isn't there! As soon as the decoder hits that gap, it panics. The `ArrayReader` is a stream processing unit—it doesn't know the layer above decided to prune a page, so it can't see the cliff coming.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig2.jpg" alt="Bitmask hitting a missing page panic" width="100%" class="img-responsive">
</figure>

**The Fix:**

Our solution is conservative but bulletproof: **if we detect Page Pruning, we ban bitmasks and force a fallback to RLE.**

```rust
// Auto prefers bitmask, but... wait, offset_index says page pruning is on.
let policy = RowSelectionPolicy::Auto { threshold: 32 };
let plan_builder = ReadPlanBuilder::new(1024).with_row_selection_policy(policy);
let plan_builder = override_selector_strategy_if_needed(
    plan_builder,
    &projection_mask,
    Some(offset_index), // page index enables page pruning
);
// ...so we play it safe and switch to Selectors (RLE).
assert_eq!(plan_builder.row_selection_policy(), &RowSelectionPolicy::Selectors);
```

### 3.2 Page Level Pruning

The ultimate performance win is **not reading the disk at all**. In the real world (especially with object storage), firing off a million tiny read requests is a **performance killer**. Since we have the Page Index, `arrow-rs` calculates exactly which Pages contain data we actually need. Even if the underlying storage client merges adjacent requests, the real win is CPU: **we completely skip the heavy lifting of decompressing and decoding pruned pages.**

* **The Catch**: If `RowSelection` selects even a **single row** in a Page, the whole Page has to be decompressed and decoded.
* **Implementation**: `scan_ranges` crunches the numbers using each page's metadata (`first_row_index` and `compressed_page_size`) to figure out which ranges are total skips, returning only the essential `(offset, length)` list. The decoder then cleans up the rest using `skip_records` inside the page.

```rust
// Example: two pages; page0 covers 0..100, page1 covers 100..200
let locations = vec![
    PageLocation { offset: 0, compressed_page_size: 10, first_row_index: 0 },
    PageLocation { offset: 10, compressed_page_size: 10, first_row_index: 100 },
];
// RowSelection wants 150..160; page0 is total junk, only read page1
let sel: RowSelection = vec![
    RowSelector::skip(150),
    RowSelector::select(10),
    RowSelector::skip(40),
].into();
let ranges = sel.scan_ranges(&locations);
assert_eq!(ranges.len(), 1); // Only request page1
```

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig4.jpg" alt="Page-level scan range calculation" width="100%" class="img-responsive">
</figure>

### 3.3 Smart Caching

Late materialization puts us in a bit of a **Catch-22**: we often need to read the same column twice—first to filter it, and then again to project it. Without caching, you're basically **paying double** for the same data: decoding it once for the predicate, and again for the output. `CachedArrayReader` fixes this: **stash the batch the first time you see it, and reuse it later.**

Why the dual-layer cache? One layer is **shareable**, the other is a **guarantee**.
Take column B: read by the predicate, then by the projection. If the projection finds it in the Shared Cache, great—free reuse! But the Shared Cache is finite and might evict data to make room for others. That's where the Local Cache comes in as a **safety net**, ensuring the data *you* just read is still there.

We keep the scope tight to avoid **memory bloat**: the Shared Cache is wiped clean between row groups so we don't hoard memory forever.

### 3.4 Zero-Copy

A classic **"unnecessary tax"** in Parquet decoding is decompressing data into a `Vec` and then `memcpy`-ing it into an Arrow Buffer. For fixed-width types (like integers or floats), this is completely redundant—the memory layout is identical. Why jump through hoops?

`PrimitiveArrayReader` cuts out the middleman with zero-copy: it simply **hands over ownership** of the decoded `Vec<T>` directly to the Arrow `Buffer`. No copying, no wasted cycles.

### 3.5 The Alignment Gauntlet

Chained filtering is a **hair-pulling** exercise in coordinate systems. "Row 1" in Filter N might actually be "Row 10,001" in the file.

* **How do we keep the train on the rails?**: We **fuzz the heck out of** every `RowSelection` operation (`split_off`, `and_then`, `trim`). We need absolute certainty that our translation between relative and absolute offsets is pixel-perfect. This correctness is the bedrock that keeps the Reader stable under the triple threat of batch boundaries, sparse selections, and page pruning.

```rust
// Example: Skip 100 rows, then take the next 10
let a: RowSelection = vec![RowSelector::skip(100), RowSelector::select(50)].into();
let b: RowSelection = vec![RowSelector::select(10), RowSelector::skip(40)].into();
let result = a.and_then(&b);
// Result should be: Skip 100, Select 10, Skip 40
assert_eq!(
    Vec::<RowSelector>::from(result),
    vec![RowSelector::skip(100), RowSelector::select(10), RowSelector::skip(40)]
);
```

## 4. Conclusion

To wrap it up: the Parquet reader in `arrow-rs` isn't just a humble file reader—it's a **mini query engine** in disguise. We've baked in high-end features like predicate pushdown and late materialization deep into its bones. With `ReadPlanBuilder` calling the shots and `RowSelection` handling the fine-grained control, the Reader manages to "read only what's needed, decode only what's necessary," saving resources without sacrificing a drop of correctness.
