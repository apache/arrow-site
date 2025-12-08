---
layout: post
title: "A Practical Dive Into Late Materialization in arrow-rs Parquet Reads"
description: "How arrow-rs pipelines predicates and projections to minimize work during Parquet scans"
date: "2025-12-07 00:00:00"
author: "<a href=\"https://github.com/hhhizzz\">Huang Qiwei</a> and <a href=\"https://github.com/alamb\">Andrew Lamb</a>"
categories: [application]
translations:
  - language: 简体中文
    post_id: 2025-12-07-parquet-late-materialization-deep-dive-zh
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

This article dives into the decisions and pitfalls of implementing Late Materialization in the [Apache Parquet] reader from [`arrow-rs`] (the reader powering [Apache DataFusion] among other projects). We'll see how a seemingly humble file reader requires complex logic to evaluate predicates—effectively becoming a **tiny query engine** in its own right.

[Apache Parquet]: https://parquet.apache.org/
[Apache DataFusion]: https://datafusion.apache.org/
[`arrow-rs`]: https://github.com/apache/arrow-rs

## 1. Why Late Materialization?

Columnar reads are a constant battle between **I/O bandwidth** and **CPU decode costs**. While skipping data is generally good, the act of skipping itself carries a computational cost. The goal of the Parquet reader in `arrow-rs` is **pipeline-style late materialization**: evaluate predicates first, then access projected columns. For predicates that filter many rows, materializing after evaluation minimizes reads and decode work.

The approach closely mirrors the **LM-pipelined** strategy from [Materialization Strategies in a Column-Oriented DBMS](https://www.cs.umd.edu/~abadi/papers/abadiicde2007.pdf) by Abadi et al.: interleaving predicates and data column access instead of reading all columns at once and trying to **stitch them back together** into rows.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig1.png" alt="LM-pipelined late materialization pipeline" width="100%" class="img-responsive">
</figure>

To evaluate a query like `SELECT B, C FROM table WHERE A > 10 AND B < 5` using late materialization, the reader follows these steps:

1.  Read column `A` and evaluate `A > 10` to build a `RowSelection` (a sparse mask) representing the initial set of surviving rows.
2.  Use that `RowSelection` to read surviving values of column `B` and evaluate `B < 5` and update the `RowSelection` to make it even sparser.
3.  Use the refined `RowSelection` to read column `C` (a projection column), decoding only the final surviving rows.

The rest of this post zooms in on how the code makes this path work.

---

## 2. Late Materialization in the Rust Parquet Reader

### 2.1 LM-pipelined

"LM-pipelined" might sound like something from a textbook. In `arrow-rs`, it simply refers to a pipeline that runs sequentially: "read predicate column → generate row selection → read data column". This contrasts with a **parallel** strategy, where all predicate columns are read simultaneously. While parallelism can maximize multi-core CPU usage, the pipelined approach is often superior in columnar storage because each filtering step drastically reduces the amount of data subsequent steps need to read and parse.

The code is structured into a few core roles:

-   **[ReadPlan](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L302) / [ReadPlanBuilder](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L34)**: Encodes "which columns to read and with what row subset" into a plan. It does not pre-read all predicate columns. It reads one, tightens the selection, and then moves on.
-   **[RowSelection](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L139)**: Two implementations: use [Run-length encoding] (RLE) (via [`RowSelector`]) to "skip/select N rows", or use an Arrow [`BooleanBuffer`] bitmask to filter rows. This is the core mechanism that carries sparsity through the pipeline.
-   **[ArrayReader](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/array_reader/mod.rs#L85)**: Responsible for decoding. It receives a [`RowSelection`] and decides which pages to read and which values to decode.

[Run-length encoding]: https://en.wikipedia.org/wiki/Run-length_encoding
[`RowSelector`]: https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L66
[`BooleanBuffer`]: https://github.com/apache/arrow-rs/blob/a67cd19fff65b6c995be9a5eae56845157d95301/arrow-buffer/src/buffer/boolean.rs#L37

[`RowSelection`] can switch dynamically between RLE and bitmasks. Bitmasks are faster when gaps are tiny and sparsity is high; RLE is friendlier to large, page-level skips. Details on this trade-off appear in section 3.1.

Consider again the query: `SELECT B, C FROM table WHERE A > 10 AND B < 5`:

1.  **Initial**: `selection = None` (equivalent to "select all").
2.  **Read A**: `ArrayReader` decodes column A in batches; the predicate builds a boolean mask; [`RowSelection::from_filters`] turns it into a sparse selection.
3.  **Tighten**: [`ReadPlanBuilder::with_predicate`] chains the new mask via [`RowSelection::and_then`].
4.  **Read B**: Build column B's reader with the current `selection`; the reader only performs I/O and decoding for selected rows, producing an even sparser mask.
5.  **Merge**: `selection = selection.and_then(selection_b)`; projection columns now decode a tiny row set.

[`RowSelection::from_filters`]: https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L149
[`ReadPlanBuilder::with_predicate`]: https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L143
[`RowSelection::and_then`]: https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L345

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

I've drawn a simple flowchart that illustrates this flow to help you understand:

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig2.jpg" alt="Predicate-first pipeline flow" width="100%" class="img-responsive">
</figure>

Now that you understand how this pipeline works, the next question is **how to represent and combine these sparse selections** (the **Row Mask** in the diagram), which is where `RowSelection` comes in.

### 2.2 Combining row selectors (`RowSelection::and_then`)

[`RowSelection`] represents the set of rows that will eventually be produced. It currently uses RLE (`RowSelector::select/skip(len)`) to describe sparse ranges. [`RowSelection::and_then`] is the core operator for "apply one selection to another": the left-hand argument is "rows already passed" and the right-hand argument is "which of the passed rows also pass the second filter." The output is their boolean AND.

[`RowSelection`]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/arrow_reader/selection.rs#L139
[`RowSelection::and_then`]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/arrow_reader/selection.rs#L345

**Walkthrough Example**:

* **Input Selection A (already filtered)**: `[Skip 100, Select 50, Skip 50]` (physical rows 100-150 are selected)
* **Selection B (filters within A)**: `[Select 10, Skip 40]` (within the 50 selected rows, only the first 10 survive B)
* **Result**: `[Skip 100, Select 10, Skip 90]`.

**How it runs**:
Think of it like a zipper: we traverse both lists simultaneously, as shown below:

1. **First 100 rows**: A is Skip → result is Skip 100.
2. **Next 50 rows**: A is Select. Look at B:
   * B's first 10 are Select → result Select 10.
   * B's remaining 40 are Skip → result Skip 40.
3. **Final 50 rows**: A is Skip → result Skip 50.

**Result**: `[Skip 100, Select 10, Skip 90]`.

Here is an example in code:

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

This keeps narrowing the filter while touching only lightweight metadata—no data copies. The implementation is a two-pointer linear scan; complexity is linear in selector segments. The sooner predicates shrink the selection, the cheaper later scans become.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig3.jpg" alt="RowSelection logical AND walkthrough" width="100%" class="img-responsive">
</figure>


This keeps narrowing the filter while touching only lightweight metadata—no data copies. The current implementation of `and_then` is a two-pointer linear scan; complexity is linear in selector segments. The sooner predicates shrink the selection, the cheaper later scans become.

## 3. Engineering Challenges

Late Materialization sounds simple enough in theory, but implementing it in a production-grade system like `arrow-rs` is an absolute **engineering nightmare**. Historically, these techniques are so tricky they have been locked away in proprietary engines. In the open source world, we've been grinding away at this for years (just look at [the DataFusion ticket](https://github.com/apache/datafusion/issues/3463)), and finally, we can **flex our muscles** and go toe-to-toe with full materialization. To pull this off, we had to tackle several serious engineering challenges.

### 3.1 Adaptive RowSelection Policy (Bitmask vs. RLE)

One major hurdle is choosing the right internal representation for `RowSelection` because the best choice depends on the sparsity pattern.

- **Ultra sparse** (e.g., 1 row every 10,000): Using a bitmask here is just wasteful (1 bit per row adds up), whereas RLE is super clean—just a few selectors and you're done.
- **Sparse but with tiny gaps** (e.g., "read 1, skip 1"): RLE creates a fragmented mess that makes the decoder work overtime; here, bitmasks are way more efficient.

Since both have their pros and cons, we decided to get the **best of both worlds** with an adaptive strategy (see [#arrow-rs/8733] for more details):

- We look at the average run length of the selectors and compare it to a threshold (currently `32`). If the average is too small, we switch to bitmasks; otherwise, we stick with selectors (RLE).
- **The Safety Net**: Bitmasks look great until you hit Page Pruning, which can cause a nasty "missing page" panic because the mask might blindly try to filter rows from pages that were never even read. The `RowSelection` logic watches out for this **recipe for disaster** and forces a switch back to RLE to keep things from crashing (see 3.1.2).

[#arrow-rs/8733]: https://github.com/apache/arrow-rs/pull/8733

#### 3.1.1 Where did the threshold of `32` come from?

The number 32 wasn't just pulled out of thin air. It came from a [data-driven "face-off"] using various distributions (even spacing, exponential sparsity, random noise). It does a solid job of distinguishing between "choppy but dense" and "long skip regions." In the future, we might get even fancier with heuristics based on data types.

The chart below shows an example run from the showdown. Blue lines are `read_selector` (RLE) and orange lines are `read_mask` (bitmasks). The vertical axis is time (lower is better), and the horizontal axis is average run length. You can see the performance curves cross around 32.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.1.1.png" alt="Bitmask vs RLE benchmark threshold" width="100%" class="img-responsive">
</figure>

[data-driven "face-off"]: https://github.com/apache/arrow-rs/pull/8733#issuecomment-3468441165

#### 3.1.2 The Bitmask Trap: Missing Pages

When implementing the adaptive strategy, bitmasks seem perfect on paper, but they hide a nasty trap when combined with **Page Pruning**.

Before we get into the weeds, a quick refresher on pages (more in Section 3.2): Parquet files are sliced into pages. If we know a page has no rows in the selection, we **don't even touch it**—no decompression, no decoding. The `ArrayReader` doesn't even know it exists.

**The Scene of the Crime:**

Imagine reading a chunk of data and selecting only the first and last rows; the middle four rows are filtered out. It just so happens those middle four rows sit in their own page, so that page gets completely pruned.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig1.jpg" alt="Page pruning example with only first and last rows kept" width="100%" class="img-responsive">
</figure>

If we use RLE (`RowSelector`), executing `Skip(4)` is smooth sailing: we just jump over the gap.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig3.jpg" alt="RLE skipping pruned pages safely" width="100%" class="img-responsive">
</figure>

**The Problem:**

If we use a bitmask, however, the reader will decode all 6 rows first, intending to filter them later. But that middle page isn't there! As soon as the decoder hits that gap, it panics. The `ArrayReader` is a stream processing unit—it doesn't handle I/O and thus doesn't know the layer above decided to prune a page, so it can't see the cliff coming.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig2.jpg" alt="Bitmask hitting a missing page panic" width="100%" class="img-responsive">
</figure>

**The Fix:**

Our current solution is conservative but bulletproof: **if we detect Page Pruning, we ban bitmasks and force a fallback to RLE.** In the future, we hope to extend the bitmask logic to be Page Pruning-aware (see [#arrow-rs/8845]).

[#arrow-rs/8845]: https://github.com/apache/arrow-rs/issues/8845

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

### 3.2 Page Pruning

The ultimate performance win is **not doing I/O or decoding at all**. In the real world (especially with object storage), firing off a million tiny read requests is a **performance killer**. `arrow-rs` uses the Parquet [PageIndex] to calculate exactly which pages contain data we actually need. For very selective predicates, skipping pages can result in substantial I/O savings, even if the underlying storage client merges adjacent range requests. Another major win is reduced CPU: **we completely skip the heavy lifting of decompressing and decoding entirely pruned pages.**

[PageIndex]: https://parquet.apache.org/docs/file-format/pageindex/

* **The Catch**: If the `RowSelection` selects even a **single row** from a page, the whole page must be decompressed.
* **Implementation**: [`RowSelection::scan_ranges`] crunches the numbers using each page's metadata (`first_row_index` and `compressed_page_size`) to figure out which ranges are total skips, returning only the required `(offset, length)` list. 

[`RowSelection::scan_ranges`]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/arrow_reader/selection.rs#L204

Page skipping is illustrated in the following code example:

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

The following figure illustrates page skipping with RLE selections. The
first page is neither read nor decoded, as no rows are selected. The second page
is read and fully decompressed (e.g., zstd), and then only the needed rows are decoded. 
The third page is decompressed and decoded in full, as all rows are selected.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig4.jpg" alt="Page-level scan range calculation" width="100%" class="img-responsive">
</figure>

### 3.3 Smart Caching

Late materialization puts us in a bit of a **Catch-22**: arrow-rs evaluates predicates progressively on all rows in a row group. This approach uses a small number of large I/Os, which performs well for slow remote storage systems such as object storage. However, it means we may need to read the same column twice—first to filter it, and then again to produce the final rows necessary for the output projection. Without caching, you're **paying double** for the same data: decoding it once for the predicate, and again for the output. [`CachedArrayReader`], introduced in [#arrow-rs/7850], fixes this: **stash the batch the first time you see it, and reuse it later.**

[`CachedArrayReader`]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/array_reader/cached_array_reader.rs#L40-L68
[#arrow-rs/7850]: https://github.com/apache/arrow-rs/pull/7850

Why the dual-layer cache? One layer is **shareable**, the other is a **guarantee**. As with all caches, the cache in the reader has a (user configurable) memory limit and thus cannot guarantee that it can hold all decoded pages. 
For example, when reading column B for both predicate evaluation and projection (output), if the projection finds the relevant pages in the Shared Cache, great—free reuse! But the Shared Cache is finite and might evict data to make room for others. That's where the Local Cache comes in as a **safety net**, ensuring the data *you* just read is still there.

We keep the scope tight to avoid **memory bloat**: the Shared Cache is wiped clean between row groups so we don't hoard memory forever.

### 3.4 Minimizing Copies and Allocations

Another area where arrow-rs has significant optimization is **avoiding unnecessary copies**. Rust's [memory safe] design makes it easy to copy, and every extra allocation and copy wastes CPU cycles and memory bandwidth. Significant care has been taken with memory allocations to avoid the **"unnecessary tax"** from decompressing data into a `Vec` and then `memcpy`-ing it into an Arrow Buffer. For fixed-width types (like integers or floats), this is completely redundant—the memory layout is identical and Arrow offers [zero-copy conversions]. Why jump through hoops? [`PrimitiveArrayReader`] cuts out the middleman with zero-copy: it simply **hands over ownership** of the decoded `Vec<T>` directly to the Arrow `Buffer`. No copying, no wasted cycles.

[memory safe]: https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html
[zero-copy conversions]: https://docs.rs/arrow/latest/arrow/array/struct.PrimitiveArray.html#example-from-a-vec
[`PrimitiveArrayReader`]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/array_reader/primitive_array.rs#L102


### 3.5 The Alignment Gauntlet

Chained filtering is a **hair-pulling** exercise in coordinate systems. "Row 1" in filter N might actually be "Row 10,001" in the file due to prior filters.

* **How do we keep the train on the rails?**: We [fuzz test] every `RowSelection` operation (`split_off`, `and_then`, `trim`). We need absolute certainty that our translation between relative and absolute offsets is pixel-perfect. This correctness is the bedrock that keeps the Reader stable under the triple threat of batch boundaries, sparse selections, and page pruning.

[fuzz_test]: https://github.com/apache/arrow-rs/blob/ce4edd53203eb4bca96c10ebf3d2118299dad006/parquet/src/arrow/arrow_reader/selection.rs#L1309

## 4. Conclusion

The Parquet reader in `arrow-rs` isn't just a humble file reader—it's a **mini query engine** in disguise. We've baked in high-end features like predicate pushdown and late materialization. The reader reads only what's needed and decodes only what's necessary, saving resources while maintaining correctness. Previously, these features were restricted to proprietary or tightly integrated systems. Now, thanks to the community's efforts, `arrow-rs` brings the benefits of advanced query processing techniques to even lightweight applications.

We invite you to [join the community], explore the code, experiment with it, and contribute to its ongoing evolution. The journey of optimizing data access is never-ending, and together, we can push the boundaries of what's possible in open-source data processing.

[Join the community]: https://github.com/apache/arrow-rs?tab=readme-ov-file#arrow-rust-community
