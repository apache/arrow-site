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

This article explores the decisions, pitfalls, and specific code locations that enable `arrow-rs` to behave like a tiny query engine when reading Parquet with late materialization.

## 1. Why Late Materialization?

Columnar reads are a constant battle between **I/O bandwidth** and **CPU decode costs**. While skipping data is generally good, the act of skipping itself carries a computational cost. The goal in `arrow-rs` is **pipeline-style late materialization**: evaluate predicates first, then access projected columns, keeping the pipeline tight at the page level to ensure minimal reads and minimal decode work.

Borrowing Abadi's classification from his [paper](https://www.cs.umd.edu/~abadi/papers/abadiicde2007.pdf), the target architecture is **LM-pipelined**: interleaving predicates and data column access instead of creating a massive "materialize everything" barrier.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/LM-pipelined.png" alt="LM-pipelined late materialization pipeline" width="100%" class="img-responsive">
</figure>

Take `SELECT B, C FROM table WHERE A > 10 AND B < 5` as a running example:

1.  Read column `A`, build a `RowSelection` (a sparse mask), and obtain the initial set of surviving rows.
2.  Use that `RowSelection` to read column `B`, decoding and filtering on the fly to make the selection even sparser.
3.  Use the refined `RowSelection` to read column `C` (a projection column), decoding only the final surviving rows.

The rest of this post zooms into how the code makes this path work.

---

## 2. Late Materialization in the Rust Parquet Reader

### 2.1 LM-pipelined

"LM-pipelined" might sound academic. In `arrow-rs`, it simply refers to a pipeline that runs sequentially: "read predicate column → generate row selection → read data column". This contrasts with a **parallel** strategy, where all predicate columns are read simultaneously. While parallelism can maximize multi-core CPU usage, the pipelined approach is often superior in columnar storage because each filtering step drastically reduces the amount of data subsequent steps need to read and parse.

To achieve this, we defined these core roles:

-   **ReadPlan / ReadPlanBuilder**: Encodes "which columns to read and with what row subset" into a plan. It does not pre-read all predicate columns. It reads one, tightens the selection, and then moves on.
-   **RowSelection**: Describes "skip/select N rows" via RLE (`RowSelector::select/skip`) or a bitmask. This is the core mechanism that carries sparsity through the pipeline.
-   **ArrayReader**: The component responsible for I/O and decoding. It receives a `RowSelection` and decides which pages to read and which values to decode.

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
Traverse both lists at once, zipper-style:

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

While relatively straightforward in theory, actually implementing Late Materialization in a production-grade system such as `arrow-rs` requires significant engineering. Previously, the effort required meant that such technology was typically only available in proprietary engines and was difficult to implement in the open-source community (see [the DataFusion ticket about enabling filter pushdown](https://github.com/apache/datafusion/issues/3463)). After several years of effort, late materialization is now competitive with full materialization across typical workloads. Getting to this point required several major implementation details, which are described below.

### 3.1 Adaptive RowSelection Policy (Bitmask vs. RLE)

- **Ultra sparse** (e.g., take 1 row every 10,000): bitmask wastes memory (1 bit per row) while RLE needs just a few selectors.
- **Sparse with tiny gaps** (e.g., "read 1, skip 1" repeatedly): RLE makes the decoder fire constantly; bitmask wins.

Instead of a global strategy, we use an adaptive strategy:

- Compare the average selector run length against a threshold (currently 32). If the selection breaks into many short runs, prefer bitmask; otherwise selectors (RLE) win.
- **Safety override**: Bitmask plus page pruning can produce "missing page" panics because the mask might try to filter rows from pages never read. The `RowSelection` detects this and forces RLE so the necessary pages are read before skipping rows (see 3.1.2).

#### 3.1.1 Threshold and Benchmarks

The threshold 32 comes from benchmarks across multiple distributions (even spacing, exponential sparsity, random sparsity) and column types. It separates "choppy but dense" from "long skip regions" well. Future heuristics may incorporate data types and distributions for finer tuning.

A performance comparison between selectors (RLE) and bitmasks is shown below: the vertical axis represents the selection time (lower is better), and the horizontal axis represents the average length of the selection. You can see the performance curves cross at around 32.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.1.1.png" alt="Bitmask vs RLE benchmark threshold" width="100%" class="img-responsive">
</figure>

#### 3.1.2 The Bitmask Trap: Missing Pages

Bitmasks are an excellent design when every row will be decoded, but they introduce a hidden engineering trap: a conflict with Page Pruning.

Before diving in, note that Parquet columns are split into Pages (see Section 3.2). To reduce I/O, if we know an entire page won't be read, that page isn't decompressed or decoded, and its address isn't even recorded in the `ArrayReader`'s metadata.

**Example Scenario:**

We read a section of data where only the first and last rows match the predicate; the middle four rows are skipped. The file stores two rows per page, so the middle Page is fully pruned and not recorded by the `ArrayReader`.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig1.jpg" alt="Page pruning example with only first and last rows kept" width="100%" class="img-responsive">
</figure>

If we use RLE encoding (`RowSelector`), when we execute `Skip(4)`, the middle page is correctly skipped.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig3.jpg" alt="RLE skipping pruned pages safely" width="100%" class="img-responsive">
</figure>

**The Problem:**

In mask mode, the reader still attempts to decode all 6 rows and then apply the mask. Because the pruned page was never loaded, it panics as soon as decoding reaches that gap. The `ArrayReader` is intentionally stream-like—it does not carry page boundaries forward—so it cannot preflight whether a mask will wander into a pruned page.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig2.jpg" alt="Bitmask hitting a missing page panic" width="100%" class="img-responsive">
</figure>

**The Solution:**

Our current fix is a conservative fallback: **if Page Pruning is detected, we disable bitmasks and force a fallback to RLE mode.**

```rust
// Auto prefers bitmask, but page pruning forces a switch back to RLE
let policy = RowSelectionPolicy::Auto { threshold: 32 };
let plan_builder = ReadPlanBuilder::new(1024).with_row_selection_policy(policy);
let plan_builder = override_selector_strategy_if_needed(
    plan_builder,
    &projection_mask,
    Some(offset_index), // page index enables page pruning
);
assert_eq!(plan_builder.row_selection_policy(), &RowSelectionPolicy::Selectors);
```

### 3.2 Page Level Pruning

Ideally, high performance means **issuing no disk reads at all**. In practice—especially against object storage—small range requests can be expensive. When page indexes are present, `arrow-rs` emits per-page ranges from `scan_ranges`; it does **not** coalesce them. Some storage backends may merge those ranges for efficiency, which can blunt bandwidth savings, but pruning still pays off: if ranges are honored it reduces bytes read, and in all cases it saves CPU by **completely skipping the decompression and decoding** of pruned pages.

* **Challenge**: If `RowSelection` touches even one row in a page, we must decompress the entire page to hand it to the decoder.
* **Implementation**: `scan_ranges` uses each page's `first_row_index` and `compressed_page_size` to compute which page ranges are completely skipped and returns a list of `(offset, length)` for the reads we *must* issue. The decode phase then uses `skip_records` to skip rows inside the page.

```rust
// Example: two pages; page0 covers 0..100, page1 covers 100..200
let locations = vec![
    PageLocation { offset: 0, compressed_page_size: 10, first_row_index: 0 },
    PageLocation { offset: 10, compressed_page_size: 10, first_row_index: 100 },
];
// RowSelection only keeps 150..160; page0 fully skipped, page1 must be read
let sel: RowSelection = vec![
    RowSelector::skip(150),
    RowSelector::select(10),
    RowSelector::skip(40),
].into();
let ranges = sel.scan_ranges(&locations);
assert_eq!(ranges.len(), 1); // only request page1
```

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig4.jpg" alt="Page-level scan range calculation" width="100%" class="img-responsive">
</figure>

### 3.3 Smart Caching

Late materialization means the same column often plays both predicate and projection. Without caching, column `B` would be decoded once for filtering and again for projection—wasting I/O and CPU. `CachedArrayReader` simplifies this: **stash the batch the first time it is decoded and reuse it the next time.**

Why two cache layers? One cache should be **shareable**; another should **guarantee self-use**. The common case: column B is read during predicates, then read again during projection. If projection hits the Shared Cache, it can reuse the decoded Arrow array. The Shared Cache might evict entries (capacity limits or other readers), so a Local Cache is the safety net—if the shared entry is gone, you can still read your own batch or fall back to re-decode. Correctness is never at risk; only performance varies.

Scope is intentionally narrow: the Shared Cache lives only within a single row group and resets between groups so we do not pin 100MB forever. Batch IDs are also row-group local (`row_offset / batch_size`), so predicate and projection batches naturally align.

To keep memory spiky instead of staircase-shaped, caches have a size cap and evict older batches; consumers also drop earlier batches after they are consumed.

### 3.4 Zero-Copy

One of the common costs in Parquet decode is "decode into a Vec, then memcpy into an Arrow buffer." Fixed-width types suffer most: same layout, same size, but still copied. `PrimitiveArrayReader` fixes this with zero-copy on the fixed-width path: it hands ownership of the decoded `Vec<T>` directly to an Arrow `Buffer`, skipping the memcpy. Numeric columns finish decode with almost no tail cost.

### 3.5 The Alignment Gauntlet

In chained filtering, every operator uses a different coordinate system. The "first row" in filter N might be the "row 10,001" of the file.

* **Fix**: Every `RowSelection` operation (`split_off`, `and_then`, `trim`) has fuzz tests to guarantee exact translation between relative and absolute offsets under any Skip/Select pattern. Correctness here decides whether readers stay stable under the triple stress of batch boundaries, sparse selections, and page pruning.

```rust
// Example: trim the first 100 rows, then take 10 rows within the trimmed window
let a: RowSelection = vec![RowSelector::skip(100), RowSelector::select(50)].into();
let b: RowSelection = vec![RowSelector::select(10), RowSelector::skip(40)].into();
let result = a.and_then(&b);
assert_eq!(
    Vec::<RowSelector>::from(result),
    vec![RowSelector::skip(100), RowSelector::select(10), RowSelector::skip(40)]
);
```

## 4. Conclusion

The Parquet reader in `arrow-rs` is more than a format parser—it is a **mini query engine**. Techniques like predicate pushdown and late materialization are embedded right in the file reader. With `ReadPlanBuilder` orchestrating a cascading plan and `RowSelection` keeping precise control, the reader avoids decompressing and decoding data you do not need, while keeping correctness intact.
