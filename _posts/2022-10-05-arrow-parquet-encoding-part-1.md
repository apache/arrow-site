---
layout: post
title: "Arrow and Parquet Part 1: Primitive Types and Nullability"
date: "2022-10-05 00:00:00"
author: "tustvold and alamb"
categories: [parquet, arrow]
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

## Introduction

We recently completed a long-running project within [Rust Apache Arrow](https://github.com/apache/arrow-rs) to complete support for reading and writing arbitrarily nested Parquet and Arrow schemas. This is a complex topic, and we encountered a lack of approachable technical information, and thus wrote this blog to share our learnings with the community.

[Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.

It is increasingly common for analytic systems to use Arrow to process data stored in Parquet files, and therefore fast, efficient, and correct translation between them is a key building block.

Historically analytic processing primarily focused on querying data with a tabular schema, where there are a fixed number of columns, and each row contains a single value for each column. However, with the increasing adoption of structured document formats such as XML, JSON, etc…, only supporting tabular schema can be frustrating for users, as it necessitates often non-trivial data transformation to first flatten the document data.

As of version [20.0.0](https://crates.io/crates/arrow/20.0.0), released in August 2022, the Rust Arrow implementation for reading structured types is feature complete. Instructions for getting started can be found [here](https://docs.rs/parquet/latest/parquet/arrow/index.html) and feel free to raise any issues on our [bugtracker](https://github.com/apache/arrow-rs/issues).

In this series we will explain how Parquet and Arrow represent nested data, highlighting the similarities and differences between them, and give a flavor of the practicalities of converting between the formats.

## Columnar vs Record-Oriented

First, it is necessary to take a step back and discuss the difference between columnar and record-oriented data formats. In a record oriented data format, such as newline-delimited JSON (NDJSON), all the values for a given record are stored contiguously.

For example

```python
{"Column1": 1, "Column2": 2}
{"Column1": 3, "Column2": 4, "Column3": 5}
{"Column1": 5, "Column2": 4, "Column3": 5}
```

In a columnar representation, the data for a given column is instead stored contiguously

```python
Column1: [1, 3, 5]
Column2: [2, 4, 4]
Column3: [null, 5, 5]
```

Aside from potentially yielding better data compression, a columnar layout can dramatically improve performance of certain queries. This is because laying data out contiguously in memory allows both the compiler and CPU to better exploit opportunities for parallelism. The specifics of [SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data) and [ILP](https://en.wikipedia.org/wiki/Instruction-level_parallelism) are well beyond the scope of this post, but the important takeaway is that processing large blocks of data without intervening conditional branches has substantial performance benefits.


## Parquet vs Arrow
Parquet and Arrow are complementary technologies, and they make some different design tradeoffs. In particular, Parquet is a storage format designed for maximum space efficiency, whereas Arrow is an in-memory format intended for operation by vectorized computational kernels.

The major distinction is that Arrow provides `O(1)` random access lookups to any array index, whilst Parquet does not. In particular, Parquet uses [dremel record shredding](https://akshays-blog.medium.com/wrapping-head-around-repetition-and-definition-levels-in-dremel-powering-bigquery-c1a33c9695da), [variable length encoding schemes](https://github.com/apache/parquet-format/blob/master/Encodings.md), and [block compression](https://github.com/apache/parquet-format/blob/master/Compression.md) to drastically reduce the data size, but these techniques come at the loss of performant random access lookups.

A common pattern that plays to each technologies strengths, is to stream data from a compressed representation, such as Parquet, in thousand row batches in the Arrow format, process these batches individually, and accumulate the results in a more compressed representation. This benefits from the ability to efficiently perform computations on Arrow data, whilst keeping memory requirements in check, and allowing the computation kernels to be agnostic to the encodings of the source and destination.

**Arrow is primarily an in-memory format, whereas Parquet is a storage format.**


## Non-Nullable Primitive Column

Let us start with the simplest case of a non-nullable list of 32-bit signed integers.

In Arrow this would be represented as a `PrimitiveArray`, which would store them contiguously in memory

```text
┌─────┐
│  1  │
├─────┤
│  2  │
├─────┤
│  3  │
├─────┤
│  4  │
└─────┘
Values
```

Parquet has multiple [different encodings](https://parquet.apache.org/docs/file-format/data-pages/encodings/) that may be used for integer types, the exact details of which are beyond the scope of this post. Broadly speaking the data will be stored in one or more [*DataPage*](https://parquet.apache.org/docs/file-format/data-pages/)s containing the integers in an encoded form

```text
┌─────┐
│  1  │
├─────┤
|  2  │
├─────┤
│  3  │
├─────┤
│  4  │
└─────┘
Values
```

# Nullable Primitive Column

Now let us consider the case of a nullable column, where some of the values might have the special sentinel value `NULL` that designates "this value is unknown".

In Arrow, nulls are stored separately from the values in the form of a [validity bitmask](https://arrow.apache.org/docs/format/Columnar.html#validity-bitmaps), with arbitrary data in the corresponding positions in the values buffer. This space efficient encoding means that the entire validity mask for the following example is stored using 5 bits


```text
┌─────┐   ┌─────┐
│  1  │   │  1  │
├─────┤   ├─────┤
│  0  │   │ ??  │
├─────┤   ├─────┤
│  1  │   │  3  │
├─────┤   ├─────┤
│  1  │   │  4  │
├─────┤   ├─────┤
│  0  │   │ ??  │
└─────┘   └─────┘
Validity   Values
```

In Parquet the validity information is also stored separately from the values, however, instead of being encoded as a validity bitmask it is encoded as a list of 16-bit integers called *definition levels*. Like other data in Parquet, these integer definition levels are stored using high efficiency encoding, and will be expanded upon in the next post, but for now a definition level of `1` indicates a valid value, and `0` a null value. Unlike Arrow, nulls are not encoded in the list of values

```text
┌─────┐    ┌─────┐
│  1  │    │  1  │
├─────┤    ├─────┤
│  0  │    │  3  │
├─────┤    ├─────┤
│  1  │    │  4  │
├─────┤    └─────┘
│  1  │
├─────┤
│  0  │
└─────┘
Definition  Values
 Levels
```

## Next up: Nested and Hierarchical Data

Armed with the foundational understanding of how Arrow and Parquet store nullability / definition differently we are ready to move on to more complex nested types, which you can read about in our [next blog post on the topic](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/).
