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

本文将深入探讨在 `arrow-rs` 中实现 Parquet 晚物化读取时的决策、陷阱以及具体的代码位置。正是这些设计细节，让 `arrow-rs` 的行为像极了一个微型查询引擎。

## 1. 为什么需要晚物化？

列式读取本质上是一场 **I/O 带宽** 与 **CPU 解码开销** 之间的博弈。虽然跳过数据通常有益，但跳过操作本身也伴随着计算成本。`arrow-rs` 的目标是实现 **流水线式的晚物化**：首先评估谓词，然后访问投影列，并将流水线紧密控制在 Page 级别，以确保最小的读取量和最小的解码工作。

借用 Abadi [论文](https://www.cs.umd.edu/~abadi/papers/abadiicde2007.pdf)中的分类，我们的目标架构是 **LM-pipelined**：将谓词评估与数据列读取交织进行，而不是创建一个巨大的“物化所有数据”的屏障。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/LM-pipelined.png" alt="LM-pipelined 流水线示意" width="100%" class="img-responsive">
</figure>

以 `SELECT B, C FROM table WHERE A > 10 AND B < 5` 为例：

1.  读取列 `A`，构建一个 `RowSelection`（稀疏掩码），并获得初始的幸存行集合。
2.  使用该 `RowSelection` 读取列 `B`，在解码的同时进行过滤，使选择集变得更加稀疏。
3.  使用进一步提炼后的 `RowSelection` 读取列 `C`（投影列），仅解码最终幸存的行。

本文接下来的部分将详细剖析代码是如何实现这一路径的。

---

## 2. Rust Parquet Reader 中的晚物化

### 2.1 LM-pipelined

"LM-pipelined" 听起来很学术；在 `arrow-rs` 中，它指的是一条按顺序执行“读取谓词列 → 生成行选择 → 读取数据列”的流水线。与之相对的是并行（parallel）策略，即同时读取所有谓词列。虽然并行策略能利用多核 CPU 优势，但在列式存储中，流水线策略通常更优，因为每个过滤步骤都能减少后续需要读取和解析的数据量。

为了实现这个目标，我们定义了这些核心角色：

-   **ReadPlan / ReadPlanBuilder**：将“读取哪些列以及使用什么行子集”编码为计划。它不会预先读取所有谓词列，而是读取一列，收紧选择集，然后再继续。
-   **RowSelection**：通过 RLE (`RowSelector::select/skip`) 或位掩码 (bitmask) 来描述“跳过/选择 N 行”。这是在流水线中传递“哪些行需要被保留”的核心数据结构。
-   **ArrayReader**：负责 I/O 和解码的组件。它接收一个 `RowSelection` 并决定哪些 Page 需要读取，哪些值需要解码。

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

虽然理论上相对直观，但在生产级系统（如 `arrow-rs`）中实现晚物化需要大量的工程工作。以前，由于实现难度大，这项技术通常只存在于专有引擎中，在开源社区中很难落地（参见 [DataFusion 关于启用过滤器下推的 issue](https://github.com/apache/datafusion/issues/3463)）。经过几年的努力，晚物化已经能在典型的工作负载上与全量物化相抗衡。要达到这一目标，需要几个关键的实现细节，如下所述。

### 3.1 自适应 RowSelection 策略 (Bitmask vs. RLE)

- **极度稀疏**（例如每 10,000 行取 1 行）：位掩码浪费内存（每行 1 bit），而 RLE 只需要几个 selector。
- **间隙微小的稀疏**（例如连续的“读 1 跳 1”）：RLE 会让解码器频繁触发；位掩码反而胜出。

我们没有采用全局策略，而是使用了自适应策略：

- 将平均 selector 段长与阈值（目前为 32）进行比较。如果选择被拆成很多短段，倾向于使用位掩码；否则 selector (RLE) 胜出。
- **安全回退**：位掩码配合 Page 级裁剪可能会产生“缺页” panic，因为掩码可能会尝试过滤那些从未读取过的 Page 中的行。`RowSelection` 会检测到这种情况并强制使用 RLE，以确保在跳过行之前读取必要的 Page（见 3.1.2）。

#### 3.1.1 阈值与基准测试

阈值 32 来自于对多种分布（均匀间隔、指数稀疏、随机稀疏）和列类型的基准测试。它能很好地区分“细碎但密集”与“长区段跳过”的情况。未来的启发式算法可能会结合数据类型和分布进行更精细的调整。

下图展示了 selector (RLE) 与位掩码的性能对比：纵轴代表选择时间（越低越好），横轴代表选择的平均长度。你可以看到性能曲线在 32 左右交叉。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.1.1.png" alt="选择策略阈值基准测试结果" width="100%" class="img-responsive">
</figure>

#### 3.1.2 位掩码的陷阱：缺页

位掩码看起来是非常不错的设计，但它引入了一个隐蔽的工程陷阱，即与 Page 级裁剪（Page Pruning）的冲突。

在介绍这个之前，需要先说明 Page 的设计（详见 3.2 节）。简单来说，Parquet 列数据是按 Page 拆分的。为了减少 I/O，如果我们知道某一整页都不会被读取，那么这一页就不会被解压和解码，它的地址甚至不会被记录在 `ArrayReader` 的元数据中。

**示例场景：**

读取一段数据，只有第一行和最后一行匹配谓词；中间的四行被跳过。文件每页仅存储两行，因此中间的 Page 被完全裁剪掉，不会被 `ArrayReader` 记录。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig1.jpg" alt="Page 裁剪示例：仅首尾行命中" width="100%" class="img-responsive">
</figure>

如果我们使用 RLE 编码（即 `RowSelector`），当执行 `Skip(4)` 时，中间的页会被正确跳过。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig3.jpg" alt="RLE 跳过被裁剪 Page 的路径" width="100%" class="img-responsive">
</figure>

**问题所在：**

在掩码模式下，Reader 仍然会先解码全部 6 行再应用掩码。由于被裁剪的 Page 从未加载，一旦解码推进到这个缺口就会 panic。`ArrayReader` 的设计是流式的，不会在上层携带 Page 边界信息，因此也无法提前判断掩码是否会踩到被裁剪的 Page。

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/3.3.2-fig2.jpg" alt="位掩码命中缺页的错误示例" width="100%" class="img-responsive">
</figure>

**解决方案：**

我们目前的修复方案是保守地使用回退机制：**只要发现了 Page 裁剪，就不再使用位掩码，强制回退到 RLE 模式。**

```rust
// Auto 首选位掩码，但 Page 级裁剪强制切回 RLE
let policy = RowSelectionPolicy::Auto { threshold: 32 };
let plan_builder = ReadPlanBuilder::new(1024).with_row_selection_policy(policy);
let plan_builder = override_selector_strategy_if_needed(
    plan_builder,
    &projection_mask,
    Some(offset_index), // page index 开启了 page 裁剪
);
assert_eq!(plan_builder.row_selection_policy(), &RowSelectionPolicy::Selectors);
```

### 3.2 Page 级裁剪

最理想的高性能意味着 **根本不发出磁盘读取请求**。在实际场景中（尤其是从对象存储读取时），细碎的范围请求代价可能很高。有 Page Index 时，`arrow-rs` 会在 `scan_ranges` 里按页生成范围请求，**不会**主动合并；某些存储后端可能为效率合并这些请求，从而削弱带宽节省。不过，裁剪仍然有价值：如果后端按范围执行可以减少读取字节量；即便被合并，也能通过 **完全跳过被裁剪 Page 的解压和解码** 节省 CPU。

* **挑战**：如果 `RowSelection` 触及 Page 中的哪怕一行，我们也必须解压这个 Page，将其交给解码器处理。
* **实现**：`scan_ranges` 使用每个 Page 的 `first_row_index` 和 `compressed_page_size` 来计算哪些 Page 范围是完全跳过的，并返回我们需要发出的读取请求的 `(offset, length)` 列表。解码阶段随后使用 `skip_records` 跳过 Page 内部的行。

```rust
// 示例：两页；page0 覆盖 0..100，page1 覆盖 100..200
let locations = vec![
    PageLocation { offset: 0, compressed_page_size: 10, first_row_index: 0 },
    PageLocation { offset: 10, compressed_page_size: 10, first_row_index: 100 },
];
// RowSelection 只保留 150..160；page0 全跳过，page1 必须读取
let sel: RowSelection = vec![
    RowSelector::skip(150),
    RowSelector::select(10),
    RowSelector::skip(40),
].into();
let ranges = sel.scan_ranges(&locations);
assert_eq!(ranges.len(), 1); // 只请求 page1
```

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/late-materialization/fig4.jpg" alt="Page 级裁剪请求范围示意" width="100%" class="img-responsive">
</figure>

### 3.3 智能缓存

晚物化意味着同一列经常既作为谓词又作为投影列。没有缓存的话，列 `B` 会在过滤时解码一次，在投影时又解码一次——浪费 I/O 和 CPU。`CachedArrayReader` 简化了这一点：**在第一次解码时缓存批次，下次直接复用。**

为什么要有两层缓存？一层缓存应该是 **可共享的 (shareable)**；另一层应该是 **保证自用的 (guarantee self-use)**。常见情况：列 B 在谓词阶段被读取，然后在投影阶段再次被读取。如果投影阶段命中了 Shared Cache，它可以复用已解码的 Arrow array。Shared Cache 可能会驱逐条目（由于容量限制或其他 Reader），所以 Local Cache 是安全网——如果共享条目消失了，你仍然可以读取自己的批次或回退到重新解码。正确性永远不会受到威胁；只有性能会变化。

作用域被刻意收得很窄：Shared Cache 仅在单个行组 (Row Group) 内有效，并在行组之间重置，这样我们就不会永远占用 100MB 内存。批次 ID 也是行组局部的 (`row_offset / batch_size`)，因此谓词批次和投影批次天然对齐。

为了保持内存使用是尖峰状而不是阶梯状，缓存有容量上限并驱逐旧批次；消费者在消费完批次后也会主动丢弃更早的批次。

### 3.4 零拷贝 (Zero-Copy)

Parquet 解码中常见的开销之一是“解码到 `Vec`，然后 memcpy 到 Arrow buffer”。定长类型受害最深：布局相同，大小相同，但仍然被拷贝。`PrimitiveArrayReader` 在定长路径上通过零拷贝修复了这个问题：它将解码后的 `Vec<T>` 的所有权直接移交给 Arrow `Buffer`，跳过了 memcpy。数值列的解码收尾几乎没有额外成本。

### 3.5 对齐的考验 (The Alignment Gauntlet)

在级联过滤中，每个算子使用不同的坐标系。过滤器 N 中的“第 1 行”可能是文件的“第 10,001 行”。

* **修复**：每个 `RowSelection` 操作（`split_off`, `and_then`, `trim`）都有模糊测试 (fuzz tests) 来保证在任何 Skip/Select 模式下相对偏移量和绝对偏移量之间的精确转换。这里的正确性决定了 Reader 能否在批次边界、稀疏选择和 Page 级裁剪的三重压力下保持稳定。

```rust
// 示例：裁剪前 100 行，然后在裁剪后的窗口中取 10 行
let a: RowSelection = vec![RowSelector::skip(100), RowSelector::select(50)].into();
let b: RowSelection = vec![RowSelector::select(10), RowSelector::skip(40)].into();
let result = a.and_then(&b);
assert_eq!(
    Vec::<RowSelector>::from(result),
    vec![RowSelector::skip(100), RowSelector::select(10), RowSelector::skip(40)]
);
```

## 4. 总结

`arrow-rs` 的 Parquet reader 不仅仅是一个格式解析器——它是一个 **微型查询引擎**。像谓词下推和晚物化这样的技术被直接嵌入在文件读取器中。通过 `ReadPlanBuilder` 编排级联计划和 `RowSelection` 保持精确控制，Reader 避免了解压和解码你不需要的数据，同时保持正确性无损。

