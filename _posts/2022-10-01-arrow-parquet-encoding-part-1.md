---
layout: post
title: Arrow and Parquet Part 1: Primitive Types and Nullability
date: "2022-10--01 00:00:00"
author: tustvold, alamb
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

A long-running project within the [Rust Apache Arrow](https://github.com/apache/arrow-rs) implementation has been complete support for reading and writing arbitrarily nested parquet schema. This is a complex topic (as we will show), and we noticed a lack of available approachable technical information, and thus want to share our learnings with the community.

[Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.

It is increasingly common for analytic systems to use Arrow to process data stored in Parquet files, so fast, efficient, and correct translation between them is a key building block.

Historically analytic processing primarily focused on querying data with a tabular schema, that is one where there are a fixed number of columns, and each row contains a single value for a given column. However, with the increasing adoption of structured document formats such as XML, JSON, etc…, this schema limitation can seem antiquated and unnecessarily limiting.

As of version [20.0.0](https://crates.io/crates/arrow/20.0.0), released in August 2022, the Rust implementation is feature complete. Instructions for getting started can be found [here](https://docs.rs/parquet/latest/parquet/arrow/index.html) and feel free to raise any issues on our [bugtracker](https://github.com/apache/arrow-rs/issues).

In this series article we will explain how Parquet and Arrow represent nested data, highlighting the similarities and differences between them, and giving a flavor of the practicalities of supporting reading and writing between them.

## Columnar vs Record-Oriented

First, it is necessary to take a step back and discuss the difference between columnar and record-oriented data formats. In a record oriented data format, such as JSON, all the values for a given record are stored contiguously.

For example

```json
{“Column1”: 1, “Column2”: 2}
{“Column1”: 3, “Column2”: 4, “Column3”: 5}
{“Column1”: 5, “Column2”: 4, “Column3”: 5}
```

In a columnar representation, the data for a given column is instead stored contiguously

```text
Column1: [1, 3, 5]
Column2: [2, 4, 4]
Column3: [null, 5, 5]
```

Aside from potentially yielding better data compression, a columnar layout can dramatically improve performance of certain queries. This is because laying data out contiguously in memory allows both the compiler and CPU to better exploit opportunities to process the data in parallel. The specifics of [SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data) and [ILP](https://en.wikipedia.org/wiki/Instruction-level_parallelism) are well beyond the scope of this post, but the important takeaway is that processing large blocks of data without intervening conditional branches has substantial performance benefits.


## Parquet vs Arrow
Parquet and Arrow are complementary technologies, and they make some different design tradeoffs. In particular, Parquet is a storage format designed for maximum space efficiency, whereas Arrow is an in-memory format intended to be operated on by vectorized computational kernels.

The major distinction is that arrow provides O(1) random access lookups to any array index, whilst parquet does not. In particular, Parquet uses [dremel record shredding](https://akshays-blog.medium.com/wrapping-head-around-repetition-and-definition-levels-in-dremel-powering-bigquery-c1a33c9695da), [variable length encoding schemes](https://github.com/apache/parquet-format/blob/master/Encodings.md), and [block compression](https://github.com/apache/parquet-format/blob/master/Compression.md) to drastically reduce the data size, but these techniques come at the loss of performant random access lookups.

A common pattern that plays to each technologies strengths, is to stream data from a compressed representation, such as parquet, in thousand row batches in the arrow format, process these batches individually, and accumulate the results in a more compressed representation. This benefits from the ability to efficiently perform computations on arrow data, whilst keeping memory requirements in check, and allowing the computation kernels to be agnostic to the encodings of the source and destination.

**Arrow is primarily an interchange format, whereas Parquet is a storage format.**


## Non-Nullable Primitive Column

Let us start with the simplest case of a non-nullable list of 32-bit signed integers.

In arrow this would be represented as a `PrimitiveArray`, which would store them contiguously in memory

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

Parquet has multiple different encodings that it can use for integers types, the exact details of which are beyond the scope of this post, but broadly speaking it will encode the data as one or more pages containing the integers

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
 Data

 DataPage
```

# Nullable Primitive Column

Now let us consider the case of a nullable column, where some of the values might have the special sentinel value `NULL` that designates “this value is unknown.”

In Arrow nulls are stored separately from the values in the form of a validity bitmask, with arbitrary data in the corresponding positions in the values buffer.

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

In Parquet the validity information is also stored separately from the values, however, instead of being encoded as a validity bitmask it is encoded as a list of 16-bit integers called definition levels. These will be expanded upon later, but for now a definition level of 1 indicates a valid value, and 0 a null value. Unlike arrow, nulls are not encoded in the list of values

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

## Next up: Nested and Hierarchal Data

Armed with the foundational understanding of how Arrow and Parquet store nullability / definition differently we are ready to move on to more complex nested types, which you can read about in our upcoming blog post on the topic <!-- I propose to update this text with a link when when we have published the next blog -->.
