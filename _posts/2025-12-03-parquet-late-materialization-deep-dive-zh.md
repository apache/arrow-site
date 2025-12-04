---
layout: post
title: "Parquet 读取的晚物化策略深度剖析"
description: "arrow-rs 中流水线式晚物化的设计决策、陷阱与实现细节"
date: "2025-12-03 00:00:00"
author: hhhizzz
categories: [application,translation]
translations:
  - language: 原文（English）
    post_id: 2025-12-03-parquet-late-materialization-deep-dive
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

本文将深入探讨在 Datafusion 中的`arrow-rs`里Parquet 晚物化读取时的决策、陷阱，从中我们可以看到虽然它仅仅是一个文件读取器，但已经具备了类似查询引擎的复杂逻辑，可以看做一个微型的查询引擎。

## 1. 为什么需要晚物化(Late Materialization)？

列式读取本质上是一场 **I/O 带宽** 与 **CPU 解码开销** 之间的博弈。虽然跳过数据通常有益，但跳过操作本身也伴随着计算成本。`arrow-rs` 的目标是实现 **流水线式的晚物化（LM-pipelined）**：首先评估谓词，然后访问投影列，并将流水线紧密控制在 Page 级别，以确保最小的读取量和最小的解码工作。

借用 Abadi [论文](https://www.cs.umd.edu/~abadi/papers/abadiicde2007.pdf)中的分类，我们的目标架构是 **LM-pipelined**：将谓词评估与数据列读取交织进行，而不是把所有列一次性读出来拼成行。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/LM-pipelined.png" alt="LM-pipelined 流水线示意" width="100%" class="img-responsive">
</figure>

我们以这样一个查询 `SELECT B, C FROM table WHERE A > 10 AND B < 5` 为例：

1.  读取列 `A`，构建一个 `RowSelection`（稀疏掩码），并获得初始的幸存行集合。
2.  使用该 `RowSelection` 读取列 `B`，在解码的同时进行过滤，使选择集变得更加稀疏。
3.  使用进一步提炼后的 `RowSelection` 读取列 `C`（投影列），仅解码最终幸存的行。

本文接下来的部分将详细剖析代码是如何实现这一路径的。

---

## 2. Rust Parquet Reader 中的晚物化

### 2.1 LM-pipelined

"LM-pipelined" 听起来很学术；在 `arrow-rs` 中，它指的是一条按顺序执行“读取谓词列 → 生成行选择 → 读取数据列”的流水线。与之相对的是并行（parallel）策略，即同时读取所有谓词列。虽然并行策略能利用多核 CPU 优势，但在列式存储中，流水线策略通常更优，因为每个过滤步骤都能减少后续需要读取和解析的数据量。

为了实现这个目标，我们定义了这些核心角色：

-   **[ReadPlan](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L302) / [ReadPlanBuilder](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/read_plan.rs#L34)**：将“读取哪些列以及使用什么行子集”编码为计划。它不会预先读取所有谓词列，而是读取一列，收紧选择集，然后再继续。
-   **[RowSelection](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/arrow_reader/selection.rs#L139)**：通过 RLE (`RowSelector::select/skip`) 或位掩码 (bitmask) 来描述“跳过/选择 N 行”。这是在流水线中传递“哪些行需要被保留”的核心数据结构。
-   **[ArrayReader](https://github.com/apache/arrow-rs/blob/bab30ae3d61509aa8c73db33010844d440226af2/parquet/src/arrow/array_reader/mod.rs#L85)**：负责 I/O 和解码的组件。它接收一个 `RowSelection` 并决定哪些 Page 需要读取，哪些值需要解码。

> `RowSelection` 可以在 RLE (selectors) 和位掩码之间动态切换。当间隙很小且稀疏度很高时，位掩码更快；而 RLE 则对大范围的 Page 级跳过更友好。关于这种权衡的细节见 3.1 节。

可以通过一个包含两个过滤谓词的查询来理解 LM-pipelined 的实现：`SELECT * FROM table WHERE A > 10 AND B < 5`：

1.  **初始状态**：`selection = None`（等价于“全选”）。
2.  **读取 A 列**：`ArrayReader` 分批解码列 A；谓词构建布尔掩码；`RowSelection::from_filters` 将其转换为稀疏选择集。
3.  **收紧选择集**：`ReadPlanBuilder::with_predicate` 通过 `RowSelection::and_then` 级联新的掩码。
4.  **读取 B 列**：使用当前的 `selection` 构建列 B 的 reader；该 reader 仅对选中的行执行 I/O 和解码，生成更稀疏的掩码。
5.  **合并**：`selection = selection.and_then(selection_b)`；后续投影列现在只需解码极小的行集。

**代码位置与概要**：

```rust
// 贴近 read_plan.rs 的核心流程（简化）
let mut builder = ReadPlanBuilder::new(batch_size);

// 1) 注入外部裁剪（如 Page Index）：
builder = builder.with_selection(page_index_selection);

// 2) 串行追加谓词：
for predicate in predicates {
    builder = builder.with_predicate(predicate); // 内部使用 RowSelection::and_then
}

// 3) 构建 Reader，所有 ArrayReader 都共享最终的选择策略
let plan = builder.build();
let reader = ParquetRecordBatchReader::new(array_reader, plan);
```

我绘制了一个简单的流程图帮助你来理解：

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig2.jpg" alt="读取谓词再读取数据列的流水线流程图" width="100%" class="img-responsive">
</figure>

一旦流水线建立，下一个问题就是 **如何表示和组合这些稀疏选择**（即图中的 **Row Mask**），这正是 `RowSelection` 的用武之地。

### 2.2 行选择器的逻辑运算 (`RowSelection::and_then`)

`RowSelection`（定义在 `selection.rs` 中）是每个阶段传递的令牌。它大部分情况下使用 RLE (`RowSelector::select/skip(len)`) 来描述稀疏区间。`and_then` 是“将一个选择集应用到另一个选择集”的核心操作：左侧是“已经允许的行”，右侧是进一步过滤这些行，输出是二者的逻辑“与”。

**演示**：

* **输入 Selection A (已过滤范围)**：`[Skip 100, Select 50, Skip 50]` (物理行 100-150 被选中)
* **输入 Predicate B (在 A 的基础上再过滤)**：`[Select 10, Skip 40]` (意味着在 A 选中的那 50 行里，只有前 10 行满足 B)

**运算过程**：
像拉链一样同时遍历两个列表：

1. **前 100 行**：A 是 Skip → 结果是 Skip 100。
2. **接下来的 50 行**：A 是 Select。此时看 B：
   * B 的前 10 行是 Select → 结果 Select 10。
   * B 的后 40 行是 Skip → 结果 Skip 40。
3. **最后的 50 行**：A 是 Skip → 结果 Skip 50。

**结果**：`[Skip 100, Select 10, Skip 90]`。

这种方式在不断收窄过滤条件的同时，只触碰轻量级的元数据——没有数据拷贝。实现上是双指针线性扫描；复杂度与 selector 段数呈线性关系。谓词越早收缩选择集，后续的扫描成本就越低。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig3.jpg" alt="RowSelection 逻辑与的示意" width="100%" class="img-responsive">
</figure>

## 3. 工程挑战

理论上听起来挺简单的，但在 `arrow-rs` 这种生产级系统里搞晚物化，简直是工程上的噩梦。以前这玩意儿太难搞，通常只有闭源商业引擎才会有。开源社区这边，大家努力了好几年（看看 [DataFusion 这个 issue](https://github.com/apache/datafusion/issues/3463) 就知道了），现在总算能跟全量物化掰掰手腕了。要做到这一点，咱们得解决几个棘手的问题。

### 3.1 自适应 RowSelection 策略 (Bitmask vs. RLE)

- **极度稀疏**（比如 10,000 行里才取 1 行）：这时候用位掩码简直是浪费内存（每行还得占 1 bit），RLE 就很爽，几个 selector 就搞定了。
- **稀疏但间隙很小**（比如“读 1 行跳 1 行”）：RLE 会产生大量的碎片，让解码器跑断腿；这时候位掩码反而更高效。

既然各有优劣，那咱们就“成年人不做选择，我全都要”——搞了个自适应策略：

- 拿 selector 的平均长度跟一个阈值（目前是 32）比一比。如果切得太碎，就用位掩码；否则就用 selector (RLE)。
- **安全回退（兜底机制）**：位掩码配合 Page 级裁剪可能会出 bug（产生“缺页” panic），因为掩码可能会尝试去过滤那些根本没读进内存的 Page。`RowSelection` 会盯着这种情况，一旦发现苗头不对，立马强制切回 RLE，保证不崩（详见 3.1.2）。

#### 3.1.1 阈值是怎么来的？

这个“32”可不是拍脑袋定的，是我们拿各种分布数据（均匀的、指数级的、随机的）跑分测出来的。它能很好地区分“细碎但密集”和“大块跳过”这两种情况。以后说不定还会搞个更智能的算法，根据数据类型动态调整。

下面这张图就是 selector (RLE) 和位掩码的“比武”结果：纵轴是时间（越低越好），横轴是平均长度。你可以看到它们在 32 这个地方发生了交叉。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.1.1.png" alt="选择策略阈值基准测试结果" width="100%" class="img-responsive">
</figure>

#### 3.1.2 位掩码的陷阱：缺页

位掩码看着挺美，实际上是个坑。特别是碰上 **Page 级裁剪（Page Pruning）** 的时候，简直就是“火星撞地球”。

在细说之前，先复习下 Page 的设计（3.2 节会细讲）。简单说，Parquet 文件是切成一个个 Page 存的。为了省 I/O，如果我们知道某页数据完全没用，那这页 **压根就不会被解压和解码**，`ArrayReader` 甚至都不会记录它的存在。

**案发现场：**

假设我们要读一段数据，只有第一行和最后一行有用；中间那四行都要跳过。刚好中间这四行单独占了一个 Page，于是这个 Page 就被彻底裁剪掉了。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig1.jpg" alt="Page 裁剪示例：仅首尾行命中" width="100%" class="img-responsive">
</figure>

如果我们用 RLE（`RowSelector`），执行 `Skip(4)` 的时候，逻辑很清晰：直接跳过这部分，大家相安无事。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig3.jpg" alt="RLE 跳过被裁剪 Page 的路径" width="100%" class="img-responsive">
</figure>

**问题来了：**

如果用位掩码，Reader 会憨憨地试图先把这 6 行全解出来，然后再用掩码去过滤。可中间那个 Page 压根没加载啊！一旦解码器走到那个缺口，直接就是一个 panic。`ArrayReader` 是流式的，它可不知道上层把 Page 给裁了，完全没法预判。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig2.jpg" alt="位掩码命中缺页的错误示例" width="100%" class="img-responsive">
</figure>

**怎么修？**

目前的办法比较保守但有效：**只要发现了 Page 裁剪，就不允许用位掩码，强制回退到 RLE 模式。**

```rust
// Auto 模式本来想用位掩码，但一看 offset_index 说开启了 page 裁剪...
let policy = RowSelectionPolicy::Auto { threshold: 32 };
let plan_builder = ReadPlanBuilder::new(1024).with_row_selection_policy(policy);
let plan_builder = override_selector_strategy_if_needed(
    plan_builder,
    &projection_mask,
    Some(offset_index), // page index 开启了 page 裁剪
);
// ...立马老实了，切回 Selectors (RLE)
assert_eq!(plan_builder.row_selection_policy(), &RowSelectionPolicy::Selectors);
```

### 3.2 Page 级裁剪

性能优化的终极奥义就是 **干脆别读盘**。在实际场景中（特别是对象存储），发起一堆细碎的读取请求简直是自杀。既然有 Page Index，`arrow-rs` 会计算好，只请求那些真正有数据的 Page 范围。虽然底层的存储客户端可能会把相邻的小请求合并，但这不重要，裁剪的核心价值在于：即便数据读上来了，**被裁剪的 Page 完全不需要解压和解码**，这能省下大量的 CPU。

* **难点**：如果 `RowSelection` 哪怕只选了 Page 里的 **一行**，整个 Page 都得解压、解码。
* **实现**：`scan_ranges` 拿着每个 Page 的元数据（`first_row_index` 和 `compressed_page_size`）在那算，哪些范围是纯跳过的，最后只返回必要的 `(offset, length)` 列表。解码器之后再用 `skip_records` 在 Page 内部做微调。

```rust
// 举个栗子：两页；page0 (0..100)，page1 (100..200)
let locations = vec![
    PageLocation { offset: 0, compressed_page_size: 10, first_row_index: 0 },
    PageLocation { offset: 10, compressed_page_size: 10, first_row_index: 100 },
];
// RowSelection 只想要 150..160；page0 显然全废了，只读 page1
let sel: RowSelection = vec![
    RowSelector::skip(150),
    RowSelector::select(10),
    RowSelector::skip(40),
].into();
let ranges = sel.scan_ranges(&locations);
assert_eq!(ranges.len(), 1); // 结果：只请求 page1
```

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig4.jpg" alt="Page 级裁剪请求范围示意" width="100%" class="img-responsive">
</figure>

### 3.3 智能缓存

晚物化有个尴尬的地方：同一列数据，经常得读两遍——先是当过滤条件读一次，最后输出结果时又得读一次。如果不做缓存，这就相当于花了两份钱买一份货，亏大了。`CachedArrayReader` 就是为了解决这个问题：**第一次读完别扔，存起来，下次直接用。**

为什么要分两层缓存？一层是 **大家共享的 (shareable)**；另一层是 **自己兜底的 (guarantee self-use)**。
比如列 B，先被谓词读取，后来又被投影读取。如果投影的时候在 Shared Cache 里找到了，直接复用，美滋滋。但 Shared Cache 容量有限，可能被别的数据挤掉了，这时候 Local Cache 就是安全网——保证你自己刚读的东西还在。

为了防止内存爆炸，缓存的作用域被严格限制：Shared Cache 只在单个行组 (Row Group) 内有效，切行组就清空。这样就不会出现跑着跑着内存占了 100MB 下不来的情况。

### 3.4 零拷贝 (Zero-Copy)

Parquet 解码里有个典型的“冤大头”开销：先把数据解压到一个 `Vec` 里，然后再 `memcpy` 拷贝到 Arrow 的 Buffer 里。对于定长类型（比如整数、浮点数），这简直是脱裤子放屁——内存布局完全一样，拷来拷去干嘛？

`PrimitiveArrayReader` 在这块做了优化，实现了零拷贝：它直接把解码后的 `Vec<T>` 的所有权“过继”给 Arrow 的 `Buffer`。这样一来，数值列的解码几乎就没有额外成本了。

### 3.5 对齐的地狱 (The Alignment Gauntlet)

级联过滤最让人头秃的就是坐标系对齐。过滤器 N 说“我要第 1 行”，它指的可能是原始文件的“第 10,001 行”。

* **怎么保证不出错？**：我们在 `split_off`, `and_then`, `trim` 这些核心操作上上了大量的 **模糊测试 (fuzz tests)**。不管你怎么 Skip/Select，相对偏移量和绝对偏移量的转换必须分毫不差。这是 Reader 能在各种边缘情况（批次边界、稀疏选择、Page 裁剪）下不翻车的基石。

```rust
// 比如：先跳过 100 行，再在剩下的里面选 10 行
let a: RowSelection = vec![RowSelector::skip(100), RowSelector::select(50)].into();
let b: RowSelection = vec![RowSelector::select(10), RowSelector::skip(40)].into();
let result = a.and_then(&b);
// 结果应该是：跳过 100，选 10，再跳过 40
assert_eq!(
    Vec::<RowSelector>::from(result),
    vec![RowSelector::skip(100), RowSelector::select(10), RowSelector::skip(40)]
);
```

## 4. 总结

总结一下，`arrow-rs` 的 Parquet reader 可不是个简单的“文件读取器”，它骨子里其实是个 **微型查询引擎**。像谓词下推、晚物化这些高级货，都被我们塞进去了。通过 `ReadPlanBuilder` 运筹帷幄，再配合 `RowSelection` 的精准微操，Reader 成功做到了“只读该读的，只解该解的”，既省了资源，又保证了数据的绝对正确。

