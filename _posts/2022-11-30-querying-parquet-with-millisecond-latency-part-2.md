---
layout: post
title: "Querying Parquet with Millisecond Latency, Part 2"
date: "2022-11-30 00:00:00"
author: "tustvold and alamb"
categories: [arrow]
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


In [Part 1]({% post_url 2022-11-30-querying-parquet-with-millisecond-latency-part-1 %}) of this series, we reviewed how Parquet files are structured, and in this part explain commonly implemented decode optimizations as well as projection pushdown.


# Optimizing Queries

In any query processing system, performance is generally improved in the following ways:

1. Reduce the data that must be transferred from secondary storage for processing (reduce I/O)
2. Reduce the computational load to decoding the data (reduce CPU)
3. Interleave / pipeline the reading and decoding of the data (improve parallelism)

The same principles apply to querying Parquet files, as we describe below:


# Decode Optimization

Parquet achieves impressive compression ratios by using [sophisticated encoding techniques](https://parquet.apache.org/docs/file-format/data-pages/encodings/) such as run length compression, dictionary encoding, delta encoding, and others. Consequently query latency can be dominated by the CPU bound task of decoding. Parquet readers can use a number of techniques to improve the latency and throughput of this task, as we have done in the Rust implementation.


## Vectorized Decode

Most analytic systems decode multiple values at a time to a columnar memory format, such as Apache Arrow, rather than processing data row-by-row. This is often called vectorized or columnar processing, and is beneficial because it:



* Amortises dispatch overheads to switch on the type of column being decoded
* Improves cache locality by reading consecutive values from a ColumnChunk
* Often allows multiple values to be decoded in a single instruction.
* Avoid many small heap allocations with a single large allocation, yielding significant savings for variable length types such as strings and byte arrays

Thus, Rust Parquet Reader implements specialized decoders for reading directly Parquet into a [columnar](https://www.influxdata.com/glossary/column-database/) memory format (Arrow Arrays).


## Streaming Decode

There is no relationship between which rows are stored in which Pages across ColumnChunks. For example, the logical values for the 10,000th row may be in the first page of column A and in the third page of column B.

The simplest approach to vectorized decoding, and the one often initially implemented in Parquet decoders, is to decode an entire RowGroup (or ColumnChunk) at a time.

However, given Parquet’s high compression ratios, a single RowGroup may well contain millions of rows. Decoding so many rows at once is non optimal because it:



* **Requires large amounts of intermediate RAM**: typical in-memory formats optimized for processing. such as Apache Arrow, require much more than their Parquet encoded form.
* **Increases query latency**: Subsequent processing steps (like filtering or aggregation) can only begin once the entire RowGroup (or ColumnChunk) is decoded.

As such, the best Parquet readers support “streaming” data out in by producing configurable sized batches of rows on demand. The batch size must be large enough to amortize decode overhead, but small enough for efficient memory usage and to allow downstream processing to begin concurrently while the subsequent batch is decoded.


```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃
┃ Data Page for ColumnChunk 1 │◀╋ ┐                                ┌── ─── ─── ─── ─── ┐
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃      ┏━━━━━━━━━━━━━━━━━━━┓         ┌ ─ ┐ ┌ ─ ┐ ┌ ─ ┐ │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃ │    ┃                   ┃       │                   │
┃ Data Page for ColumnChunk 1 │ ┃      ┃                   ┃   ┌ ─▶│ │   │ │   │ │   │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃ ├ ─ ─┃                   ┃─ ─    │  ─ ─   ─ ─   ─ ─  │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃      ┃                   ┃   │        A    B     C   │
┃ Data Page for ColumnChunk 2 │◀╋ ┤    ┗━━━━━━━━━━━━━━━━━━━┛       └── ─── ─── ─── ─── ┘
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃                              │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃ │      Parquet Decoder                    ...
┃ Data Page for ColumnChunk 3 │ ┃                              │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃ │                                ┌── ─── ─── ─── ─── ┐
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃                              │     ┌ ─ ┐ ┌ ─ ┐ ┌ ─ ┐ │
┃ Data Page for ColumnChunk 3 │◀╋ ┘                                │                   │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃                              └ ─▶│ │   │ │   │ │   │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃                                  │  ─ ─   ─ ─   ─ ─  │
┃ Data Page for ColumnChunk 3 │ ┃                                       A    B     C   │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┃                                  └── ─── ─── ─── ─── ┘
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


      Parquet file                                                   Smaller in memory
                                                                        batches for
                                                                        processing
```


While streaming is not a complicated feature to explain, the stateful nature of decoding, especially across multiple columns and [arbitrarily nested data](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/), where the relationship between rows and values is not fixed, requires [complex intermediate buffering](https://github.com/apache/arrow-rs/blob/b7af85cb8dfe6887bb3fd43d1d76f659473b6927/parquet/src/arrow/record_reader/mod.rs) and significant engineering effort to handle correctly.


## Dictionary Preservation

Dictionary Encoding, also called [categorical](https://pandas.pydata.org/docs/user_guide/categorical.html) encoding, is a technique where each value in a column is not stored directly, but instead, an index in a separate list called a “Dictionary” is stored. This technique achieves many of the benefits of [third normal form](https://en.wikipedia.org/wiki/Third_normal_form) for columns that have repeated values (low [cardinality](https://www.influxdata.com/glossary/cardinality/)) and is especially effective for columns of strings such as “City”.

The first page in a ColumnChunk can optionally be a dictionary page, containing a list of values of the column’s type. Subsequent pages within this ColumnChunk can then encode an index into this dictionary, instead of encoding the values directly.

Given the effectiveness of this encoding, if a Parquet decoder simply decodes dictionary data into the native type, it will inefficiently replicate the same value over and over again, which is especially disastrous for string data. To handle dictionary encoded data efficiently, the encoding must be preserved during decode. Conveniently many columnar formats, such as the Arrow [DictionaryArray](https://docs.rs/arrow/27.0.0/arrow/array/struct.DictionaryArray.html), support such compatible encodings.

Preserving dictionary encoding drastically improves performance when reading to an Arrow array, in some cases in excess of [60x](https://github.com/apache/arrow-rs/pull/1180), as well as using significantly less memory.

The major complicating factor for preserving dictionaries is that the dictionaries are per ColumnChunk, and therefore the dictionary changes between RowGroups. The reader must automatically recompute a dictionary for batches that span multiple RowGroups, while also optimizing for the case that batch sizes divide evenly into the number of rows per RowGroup. Additionally a column may be only[ partly dictionary encoded](https://github.com/apache/parquet-format/blob/111dbdcf8eff2e9f8e0d4e958cecbc7e00028aca/README.md?plain=1#L194-L199), further complicating implementation. More information on this technique and its complications can be found in the [blog post](https://arrow.apache.org/blog/2019/09/05/faster-strings-cpp-parquet/) on applying this technique to the C++ Parquet reader.


# Projection Pushdown

The most basic parquet optimization, and the one that is most commonly described for Parquet files is _projection pushdown_, which reduces both IO and CPU requirements. Projection in this context means “selecting some but not all of the columns.” Given how data in Parquet is organized, it is straightforward to read and decode only the ColumnChunks required for the referenced columns.

For example, consider a SQL query of the form


```
SELECT B from table where A > 35
```


This query only needs data for columns A and B (and not C) and the projection can be “pushed down” to the Parquet reader.

Specifically, using the information in the footer, the Parquet reader can entirely skip fetching (IO) and decoding (CPU) the Data Pages that store data for column C (ColumnChunk 3 and ColumnChunk 6 in our example).


```
                                     ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                                     ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ┌─────────▶ Data Page for ColumnChunk 1 ("A")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ├─────────▶ Data Page for ColumnChunk 1 ("A")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ├─────────▶ Data Page for ColumnChunk 2 ("B")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           │         ┃ Data Page for ColumnChunk 3 ("C")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
   A query that            │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
  accesses only            │         ┃ Data Page for ColumnChunk 3 ("C")  ┃
 columns A and B           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
can read only the          │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
 relevant pages,  ─────────┤         ┃ Data Page for ColumnChunk 3 ("C")  ┃
skipping any Data          │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
  for column C             │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ├─────────▶ Data Page for ColumnChunk 4 ("A")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ├─────────▶ Data Page for ColumnChunk 5 ("B")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           ├─────────▶ Data Page for ColumnChunk 5 ("B")  ┃
                           │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                           │         ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                           └─────────▶ Data Page for ColumnChunk 5 ("B")  ┃
                                     ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                                     ┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┃
                                     ┃ Data Page for ColumnChunk 6 ("C")  ┃
                                     ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
                                     ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

# Next up

In [Part 3]({% post_url 2022-11-30-querying-parquet-with-millisecond-latency-part-3 %}) we explain how the concept of projection pushdown can be extended to filtering as well as how to push IO.
