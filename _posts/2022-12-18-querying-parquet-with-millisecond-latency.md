---
layout: post
title: "Querying Parquet with Millisecond Latency"
date: "2022-12-18 00:00:00"
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



# Querying Parquet with Millisecond Latency

Note: this article was originally published on the [InfluxData Blog]([https://www.influxdata.com/blog/querying-parquet-millisecond-latency/](https://www.influxdata.com/blog/querying-parquet-millisecond-latency/).

We believe that querying data in [Apache Parquet](https://parquet.apache.org/) files directly can achieve similar or better storage efficiency and query performance than most specialized file formats. While it requires significant engineering effort, the benefits of Parquet's open format and broad ecosystem support make it the obvious choice for a wide class of data systems.

In this article we explain several advanced techniques needed to query data stored in the Parquet format quickly that we implemented in the [Apache Arrow Rust Parquet reader](https://docs.rs/parquet/27.0.0/parquet/). Together these techniques make the Rust implementation one of, if not the, fastest implementation for querying Parquet files — be it on local disk or remote object storage. It is able to query GBs of Parquet in a [matter of milliseconds](https://github.com/tustvold/access-log-bench).

We would like to acknowledge and thank [InfluxData](https://www.influxdata.com/) for their support of this work. InfluxData has a deep and continuing commitment to Open source software, and it sponsored much of our time for writing this blog post as well as many contributions as part of building the [InfluxDB IOx Storage Engine](https://www.influxdata.com/blog/influxdb-engine/).


# Background

[Apache Parquet](https://parquet.apache.org/) is an increasingly popular open format for storing [analytic datasets](https://www.influxdata.com/glossary/olap/), and has become the de-facto standard for cost-effective, DBMS-agnostic data storage. Initially created for the Hadoop ecosystem, Parquet’s reach now expands broadly across the data analytics ecosystem due to its compelling combination of:


* High compression ratios
* Amenability to commodity blob-storage such as S3
* Broad ecosystem and tooling support
* Portability across many different platforms and tools
* Support for [arbitrarily structured data](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/)

Increasingly other systems, such as [DuckDB](https://duckdb.org/2021/06/25/querying-parquet.html) and [Redshift](https://docs.aws.amazon.com/redshift/latest/dg/c-using-spectrum.html#c-spectrum-overview) allow querying data stored in Parquet directly, but support is still often a secondary consideration compared to their native (custom) file formats. Such formats include the DuckDB `.duckdb` file format, the Apache IOT [TsFile](https://github.com/apache/iotdb/blob/master/tsfile/README.md), the [Gorilla format](https://www.vldb.org/pvldb/vol8/p1816-teller.pdf), and others.

For the first time, access to the same sophisticated query techniques, previously only available in closed source commercial implementations, are now available as open source. The required engineering capacity comes from large, well-run open source projects with global contributor communities, such as [Apache Arrow](https://arrow.apache.org/) and [Apache Impala](https://impala.apache.org/).


# Parquet file format

Before diving into the details of efficiently reading from [Parquet](https://www.influxdata.com/glossary/apache-parquet/), it is important to understand the file layout. The file format is carefully designed to quickly locate the desired information, skip irrelevant portions, and decode what remains efficiently.


* The data in a Parquet file is broken into horizontal slices called RowGroups
* Each RowGroup contains a single ColumnChunk for each column in the schema

For example, the following diagram illustrates a Parquet file with three columns "A", "B" and "C" stored in two RowGroups for a total of 6 ColumnChunks.


```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃┏━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━┓          ┃
┃┃┌ ─ ─ ─ ─ ─ ─ ┌ ─ ─ ─ ─ ─ ─ ┐┌ ─ ─ ─ ─ ─ ─  ┃          ┃
┃┃             │                            │            ┃
┃ │             │             ││              ┃          ┃
┃┃             │                            │ ┃          ┃
┃┃│             │             ││              ┃ RowGroup ┃
┃┃             │                            │       1    ┃
┃ │             │             ││              ┃          ┃
┃┃             │                            │ ┃          ┃
┃┃└ ─ ─ ─ ─ ─ ─ └ ─ ─ ─ ─ ─ ─ ┘└ ─ ─ ─ ─ ─ ─  ┃          ┃
┃┃ColumnChunk 1  ColumnChunk 2 ColumnChunk 3             ┃
┃  (Column "A")   (Column "B")  (Column "C")  ┃          ┃
┃┗━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━┛          ┃
┃┏━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━┓          ┃
┃┃┌ ─ ─ ─ ─ ─ ─ ┌ ─ ─ ─ ─ ─ ─ ┐┌ ─ ─ ─ ─ ─ ─  ┃          ┃
┃┃             │                            │            ┃
┃ │             │             ││              ┃          ┃
┃┃             │                            │ ┃          ┃
┃┃│             │             ││              ┃ RowGroup ┃
┃┃             │                            │       2    ┃
┃ │             │             ││              ┃          ┃
┃┃             │                            │ ┃          ┃
┃┃└ ─ ─ ─ ─ ─ ─ └ ─ ─ ─ ─ ─ ─ ┘└ ─ ─ ─ ─ ─ ─  ┃          ┃
┃┃ColumnChunk 4  ColumnChunk 5 ColumnChunk 6             ┃
┃  (Column "A")   (Column "B")  (Column "C")  ┃          ┃
┃┗━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━┛          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```



The logical values for a ColumnChunk are written using one of the many [available encodings](https://parquet.apache.org/docs/file-format/data-pages/encodings/) into one or more Data Pages appended sequentially in the file. At the end of a Parquet file is a footer, which contains important metadata, such as:



* The file’s schema information such as column names and types
* The locations of the RowGroup and ColumnChunks in the file

The footer may also contain other specialized data structures:



* Optional statistics for each ColumnChunk including min/max values and null counts
* Optional pointers to [OffsetIndexes](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L926-L932) containing the location of each individual Page
* Optional pointers to [ColumnIndex](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L938) containing row counts and summary statistics for each Page
* Optional pointers to [BloomFilterData](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L621-L630), which can quickly check if a value is present in a ColumnChunk

For example, the logical structure of 2 Row Groups and 6 ColumnChunks in the previous diagram might be stored in a Parquet file as shown in the following diagram (not to scale). The pages for the ColumnChunks come first, followed by the footer. The data, the effectiveness of the encoding scheme, and the settings of the Parquet encoder determine the number of and size of the pages needed for each ColumnChunk. In this case, ColumnChunk 1 required 2 pages while ColumnChunk 6 required only 1 page. In addition to other information, the footer contains the locations of each Data Page and the types of the columns.


```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 1 ("A")             ◀─┃─ ─ ─│
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃     │
┃ Data Page for ColumnChunk 1 ("A")               ┃
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃     │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 2 ("B")               ┃     │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃     │
┃ Data Page for ColumnChunk 3 ("C")               ┃
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃     │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 3 ("C")               ┃     │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃     │
┃ Data Page for ColumnChunk 3 ("C")               ┃
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃     │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 4 ("A")             ◀─┃─ ─ ─│─ ┐
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃     │  │
┃ Data Page for ColumnChunk 5 ("B")               ┃
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃     │  │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 5 ("B")               ┃     │  │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃     │  │
┃ Data Page for ColumnChunk 5 ("B")               ┃
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃     │  │
┃┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┃
┃ Data Page for ColumnChunk 6 ("C")               ┃     │  │
┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃     │  │
┃┃Footer                                        ┃ ┃
┃┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃ ┃     │  │
┃┃ ┃File Metadata                             ┃ ┃ ┃
┃┃ ┃ Schema, etc                              ┃ ┃ ┃     │  │
┃┃ ┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓     ┃ ┃ ┃
┃┃ ┃ ┃Row Group 1 Metadata              ┃     ┃ ┃ ┃     │  │
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓             ┃     ┃ ┃ ┃
┃┃ ┃ ┃┃Column "A" Metadata┃ Location of ┃     ┃ ┃ ┃     │  │
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛ first Data  ┣ ─ ─ ╋ ╋ ╋ ─ ─
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓ Page, row   ┃     ┃ ┃ ┃        │
┃┃ ┃ ┃┃Column "B" Metadata┃ counts,     ┃     ┃ ┃ ┃
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛ sizes,      ┃     ┃ ┃ ┃        │
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓ min/max     ┃     ┃ ┃ ┃
┃┃ ┃ ┃┃Column "C" Metadata┃ values, etc ┃     ┃ ┃ ┃        │
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛             ┃     ┃ ┃ ┃
┃┃ ┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛     ┃ ┃ ┃        │
┃┃ ┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓     ┃ ┃ ┃
┃┃ ┃ ┃Row Group 2 Metadata              ┃     ┃ ┃ ┃        │
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓ Location of ┃     ┃ ┃ ┃
┃┃ ┃ ┃┃Column "A" Metadata┃ first Data  ┃     ┃ ┃ ┃        │
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛ Page, row   ┣ ─ ─ ╋ ╋ ╋ ─ ─ ─ ─
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓ counts,     ┃     ┃ ┃ ┃
┃┃ ┃ ┃┃Column "B" Metadata┃ sizes,      ┃     ┃ ┃ ┃
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛ min/max     ┃     ┃ ┃ ┃
┃┃ ┃ ┃┏━━━━━━━━━━━━━━━━━━━┓ values, etc ┃     ┃ ┃ ┃
┃┃ ┃ ┃┃Column "C" Metadata┃             ┃     ┃ ┃ ┃
┃┃ ┃ ┃┗━━━━━━━━━━━━━━━━━━━┛             ┃     ┃ ┃ ┃
┃┃ ┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛     ┃ ┃ ┃
┃┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃ ┃
┃┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```


There are many important criteria to consider when creating Parquet files such as how to optimally order/cluster data and structure it into RowGroups and Data Pages. Such “physical design” considerations are complex, worthy of their own series of articles, and not addressed in this blog post. Instead, we focus on how to use the available structure to make queries very fast.


# Optimizing queries

In any query processing system, the following techniques generally improve performance:



1. Reduce the data that must be transferred from secondary storage for processing (reduce I/O)
2. Reduce the computational load for decoding the data (reduce CPU)
3. Interleave/pipeline the reading and decoding of the data (improve parallelism)

The same principles apply to querying Parquet files, as we describe below:


# Decode optimization

Parquet achieves impressive compression ratios by using [sophisticated encoding techniques](https://parquet.apache.org/docs/file-format/data-pages/encodings/) such as run length compression, dictionary encoding, delta encoding, and others. Consequently, the CPU-bound task of decoding can dominate query latency. Parquet readers can use a number of techniques to improve the latency and throughput of this task, as we have done in the Rust implementation.


## Vectorized decode

Most analytic systems decode multiple values at a time to a columnar memory format, such as Apache Arrow, rather than processing data row-by-row. This is often called vectorized or columnar processing, and is beneficial because it:



* Amortizes dispatch overheads to switch on the type of column being decoded
* Improves cache locality by reading consecutive values from a ColumnChunk
* Often allows multiple values to be decoded in a single instruction.
* Avoid many small heap allocations with a single large allocation, yielding significant savings for variable length types such as strings and byte arrays

Thus, Rust Parquet Reader implements specialized decoders for reading Parquet directly into a [columnar](https://www.influxdata.com/glossary/column-database/) memory format (Arrow Arrays).


## Streaming decode

There is no relationship between which rows are stored in which Pages across ColumnChunks. For example, the logical values for the 10,000th row may be in the first page of column A and in the third page of column B.

The simplest approach to vectorized decoding, and the one often initially implemented in Parquet decoders, is to decode an entire RowGroup (or ColumnChunk) at a time.

However, given Parquet’s high compression ratios, a single RowGroup may well contain millions of rows. Decoding so many rows at once is non-optimal because it:



* **Requires large amounts of intermediate RAM**: typical in-memory formats optimized for processing, such as Apache Arrow, require much more than their Parquet-encoded form.
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


## Dictionary preservation

Dictionary Encoding, also called [categorical](https://pandas.pydata.org/docs/user_guide/categorical.html) encoding, is a technique where each value in a column is not stored directly, but instead, an index in a separate list called a “Dictionary” is stored. This technique achieves many of the benefits of [third normal form](https://en.wikipedia.org/wiki/Third_normal_form#:~:text=Third%20normal%20form%20(3NF)%20is,in%201971%20by%20Edgar%20F.) for columns that have repeated values (low [cardinality](https://www.influxdata.com/glossary/cardinality/)) and is especially effective for columns of strings such as “City”.

The first page in a ColumnChunk can optionally be a dictionary page, containing a list of values of the column’s type. Subsequent pages within this ColumnChunk can then encode an index into this dictionary, instead of encoding the values directly.

Given the effectiveness of this encoding, if a Parquet decoder simply decodes dictionary data into the native type, it will inefficiently replicate the same value over and over again, which is especially disastrous for string data. To handle dictionary-encoded data efficiently, the encoding must be preserved during decode. Conveniently, many columnar formats, such as the Arrow [DictionaryArray](https://docs.rs/arrow/27.0.0/arrow/array/struct.DictionaryArray.html), support such compatible encodings.

Preserving dictionary encoding drastically improves performance when reading to an Arrow array, in some cases in excess of [60x](https://github.com/apache/arrow-rs/pull/1180), as well as using significantly less memory.

The major complicating factor for preserving dictionaries is that the dictionaries are stored per ColumnChunk, and therefore the dictionary changes between RowGroups. The reader must automatically recompute a dictionary for batches that span multiple RowGroups, while also optimizing for the case that batch sizes divide evenly into the number of rows per RowGroup. Additionally a column may be only [partly dictionary encoded](https://github.com/apache/parquet-format/blob/111dbdcf8eff2e9f8e0d4e958cecbc7e00028aca/README.md?plain=1#L194-L199), further complicating implementation. More information on this technique and its complications can be found in the [blog post](https://arrow.apache.org/blog/2019/09/05/faster-strings-cpp-parquet/) on applying this technique to the C++ Parquet reader.


# Projection pushdown

The most basic Parquet optimization, and the one most commonly described for Parquet files, is _projection pushdown_, which reduces both I/Oand CPU requirements. Projection in this context means “selecting some but not all of the columns.” Given how Parquet organizes data, it is straightforward to read and decode only the ColumnChunks required for the referenced columns.

For example, consider a SQL query of the form


```
SELECT B from table where A > 35
```


This query only needs data for columns A and B (and not C) and the projection can be “pushed down” to the Parquet reader.

Specifically, using the information in the footer, the Parquet reader can entirely skip fetching (I/O) and decoding (CPU) the Data Pages that store data for column C (ColumnChunk 3 and ColumnChunk 6 in our example).


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
skipping any data          │         ┃└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┃
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



# Predicate pushdown

Similar to projection pushdown, **predicate** pushdown also avoids fetching and decoding data from Parquet files, but does so using filter expressions. This technique typically requires closer integration with a query engine such as [DataFusion](https://arrow.apache.org/datafusion/), to determine valid predicates and evaluate them during the scan. Unfortunately without careful API design, the Parquet decoder and query engine can end up tightly coupled, preventing reuse (e.g. there are different Impala and Spark implementations in [Cloudera Parquet Predicate Pushdown docs](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cdh_ig_predicate_pushdown_parquet.html#concept_pgs_plb_mgb)). The Rust Parquet reader uses the [RowSelection](https://docs.rs/parquet/27.0.0/parquet/arrow/arrow_reader/struct.RowSelector.html) API to avoid this coupling.


## RowGroup pruning

The simplest form of predicate pushdown, supported by many Parquet based query engines, uses the statistics stored in the footer to skip entire RowGroups. We call this operation RowGroup _pruning_, and it is analogous to [partition pruning](https://docs.oracle.com/database/121/VLDBG/GUID-E677C85E-C5E3-4927-B3DF-684007A7B05D.htm#VLDBG00401) in many classical data warehouse systems.

For the example query above, if the maximum value for A in a particular RowGroup is less than 35, the decoder can skip fetching and decoding any ColumnChunks from that **entire** RowGroup.


```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃Row Group 1 Metadata                      ┃
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃Column "A" Metadata    Min:0 Max:15   ┃◀╋ ┐
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃ │
┃ ┃Column "B" Metadata                   ┃ ┃
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃ │
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃Column "C" Metadata                   ┃ ┃ │     Using the min and max values
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃       from the metadata, RowGroup
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ├ ─ ─ 1  can be entirely skipped
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓       (pruned) when searching for
┃Row Group 2 Metadata                      ┃ │     rows with A > 35,
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃Column "A" Metadata   Min:10 Max:50   ┃◀╋ ┘
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃Column "B" Metadata                   ┃ ┃
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃
┃ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ ┃
┃ ┃Column "C" Metadata                   ┃ ┃
┃ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

Note that pruning on minimum and maximum values is effective for many data layouts and column types, but not all. Specifically, it is not as effective for columns with many distinct pseudo-random values (e.g. identifiers or uuids). Thankfully for this use case, Parquet also supports per ColumnChunk [Bloom Filters](https://github.com/apache/parquet-format/blob/master/BloomFilter.md). We are actively working on [adding bloom filter](https://github.com/apache/arrow-rs/issues/3023) support in Apache Rust’s implementation.


## Page pruning

A more sophisticated form of predicate pushdown uses the optional [page index](https://github.com/apache/parquet-format/blob/master/PageIndex.md) in the footer metadata to rule out entire Data Pages. The decoder decodes only the corresponding rows from other columns, often skipping entire pages.

The fact that pages in different ColumnChunks often contain different numbers of rows, due to various reasons, complicates this optimization. While the page index may identify the needed pages from one column, pruning a page from one column doesn’t immediately rule out entire pages in other columns.

Page pruning proceeds as follows:



* Uses the predicates in combination with the page index to identify pages to skip
* Uses the offset index to determine what row ranges correspond to non-skipped pages
* Computes the intersection of ranges across non-skipped pages, and decodes only those rows

This last point is highly non-trivial to implement, especially for nested lists where [a single row may correspond to multiple values](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/). Fortunately, the Rust Parquet reader hides this complexity internally, and can decode arbitrary [RowSelections](https://docs.rs/parquet/27.0.0/parquet/arrow/arrow_reader/struct.RowSelection.html).

For example, to scan Columns A and B, stored in 5 Data Pages as shown in the figure below:

If the predicate is A > 35,



* Page 1 is pruned using the page index (max value is 20), leaving a RowSelection of  [200->onwards],
* Parquet reader skips Page 3 entirely (as its last row index is 99)
* (Only) the relevant rows are read by reading pages 2, 4, and 5.

If the predicate is instead A > 35 AND B = "F" the page index is even more effective



* Using A > 35, yields a RowSelection of [200->onwards] as before
* Using B = "F", on the remaining Page 4 and Page 5 of B, yields a RowSelection of [100-244]
* Intersecting the two RowSelections leaves a combined RowSelection [200-244]
* Parquet reader only decodes those 50 rows from Page 2 and Page 4.


```
┏━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━
   ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ┃
┃     ┌──────────────┐  │     ┌──────────────┐  │  ┃
┃  │  │              │     │  │              │     ┃
┃     │              │  │     │     Page     │  │
   │  │              │     │  │      3       │     ┃
┃     │              │  │     │   min: "A"   │  │  ┃
┃  │  │              │     │  │   max: "C"   │     ┃
┃     │     Page     │  │     │ first_row: 0 │  │
   │  │      1       │     │  │              │     ┃
┃     │   min: 10    │  │     └──────────────┘  │  ┃
┃  │  │   max: 20    │     │  ┌──────────────┐     ┃
┃     │ first_row: 0 │  │     │              │  │
   │  │              │     │  │     Page     │     ┃
┃     │              │  │     │      4       │  │  ┃
┃  │  │              │     │  │   min: "D"   │     ┃
┃     │              │  │     │   max: "G"   │  │
   │  │              │     │  │first_row: 100│     ┃
┃     └──────────────┘  │     │              │  │  ┃
┃  │  ┌──────────────┐     │  │              │     ┃
┃     │              │  │     └──────────────┘  │
   │  │     Page     │     │  ┌──────────────┐     ┃
┃     │      2       │  │     │              │  │  ┃
┃  │  │   min: 30    │     │  │     Page     │     ┃
┃     │   max: 40    │  │     │      5       │  │
   │  │first_row: 200│     │  │   min: "H"   │     ┃
┃     │              │  │     │   max: "Z"   │  │  ┃
┃  │  │              │     │  │first_row: 250│     ┃
┃     └──────────────┘  │     │              │  │
   │                       │  └──────────────┘     ┃
┃   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ┃
┃       ColumnChunk            ColumnChunk         ┃
┃            A                      B
 ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━━ ━━┛
```


Support for reading and writing these indexes from Arrow C++, and by extension pyarrow/pandas, is tracked in [PARQUET-1404](https://issues.apache.org/jira/browse/PARQUET-1404).


## Late materialization

The two previous forms of predicate pushdown only operated on metadata stored for RowGroups, ColumnChunks, and Data Pages prior to decoding values. However, the same techniques also extend to values of one or more columns *after* decoding them but prior to decoding other columns, which is often called “late materialization”.

This technique is especially effective when:



* The predicate is very selective, i.e. filters out large numbers of rows
* Each row is large, either due to wide rows (e.g. JSON blobs) or many columns
* The selected data is clustered together
* The columns required by the predicate are relatively inexpensive to decode, e.g. PrimitiveArray / DictionaryArray

There is additional discussion about the benefits of this technique in [SPARK-36527](https://issues.apache.org/jira/browse/SPARK-36527) and[ Impala](https://docs.cloudera.com/cdw-runtime/cloud/impala-reference/topics/impala-lazy-materialization.html).

For example, given the predicate A > 35 AND B = "F" from above where the engine uses the page index to determine only 50 rows within RowSelection of [100-244] could match, using late materialization, the Parquet decoder:



* Decodes the 50 values of Column A
* Evaluates  A > 35 on those 50 values
* In this case, only 5 rows pass, resulting in the RowSelection:
    * RowSelection[205-206]
    * RowSelection[238-240]
* Only decodes the 5 rows for column B for those selections




```


  Row Index
             ┌────────────────────┐            ┌────────────────────┐
       200   │         30         │            │        "F"         │
             └────────────────────┘            └────────────────────┘
                      ...                               ...
             ┌────────────────────┐            ┌────────────────────┐
       205   │         37         │─ ─ ─ ─ ─ ─▶│        "F"         │
             ├────────────────────┤            ├────────────────────┤
       206   │         36         │─ ─ ─ ─ ─ ─▶│        "G"         │
             └────────────────────┘            └────────────────────┘
                      ...                               ...
             ┌────────────────────┐            ┌────────────────────┐
       238   │         36         │─ ─ ─ ─ ─ ─▶│        "F"         │
             ├────────────────────┤            ├────────────────────┤
       239   │         36         │─ ─ ─ ─ ─ ─▶│        "G"         │
             ├────────────────────┤            ├────────────────────┤
       240   │         40         │─ ─ ─ ─ ─ ─▶│        "G"         │
             └────────────────────┘            └────────────────────┘
                      ...                               ...
             ┌────────────────────┐            ┌────────────────────┐
      244    │         26         │            │        "D"         │
             └────────────────────┘            └────────────────────┘


                   Column A                          Column B
                    Values                            Values


```



In certain cases, such as our example where B stores single character values, the cost of late materialization machinery can outweigh the savings in decoding. However, the savings can be substantial when some of the conditions listed above are fulfilled. The query engine must decide which predicates to push down and in which order to apply them for optimal results.

While it is outside the scope of this document, the same technique can be applied for multiple predicates as well as predicates on multiple columns. See the [RowFilter](https://docs.rs/parquet/latest/parquet/arrow/arrow_reader/struct.RowFilter.html) interface in the Parquet crate for more information, and the [row_filter](https://github.com/apache/arrow-datafusion/blob/58b43f5c0b629be49a3efa0e37052ec51d9ba3fe/datafusion/core/src/physical_plan/file_format/parquet/row_filter.rs#L40-L70) implementation in DataFusion.


# I/O pushdown

While Parquet was designed for efficient access on the [HDFS distributed file system](https://hadoop.apache.org/docs/r1.2.1/hdfs_design.html), it works very well with commodity blob storage systems such as AWS S3 as they have very similar characteristics:



* **Relatively slow “random access” reads**: it is much more efficient to read large (MBs) sections of data in each request than issue many requests for smaller portions
* **Significant latency before retrieving the first byte **
* **High per-request cost: **Often billed per request, regardless of number of bytes read, which incentivizes fewer requests that each read a large contiguous section of data.

To read optimally from such systems, a Parquet reader must:



1. Minimize the number of I/O requests, while also applying the various pushdown techniques to avoid fetching large amounts of unused data.
2. Integrate with the appropriate task scheduling mechanism to interleave I/O and processing on the data that is fetched to avoid pipeline bottlenecks.

As these are substantial engineering and integration challenges, many Parquet readers still require the files to be fetched in their entirety to local storage.

Fetching the entire files in order to process them is not ideal for several reasons:



1. **High Latency**: Decoding cannot begin until the entire file is fetched (Parquet metadata is at the end of the file, so the decoder must see the end prior to decoding the rest)
2. **Wasted work**: Fetching the entire file fetches all necessary data, but also potentially lots of unnecessary data that will be skipped after reading the footer. This increases the cost unnecessarily.
3. **Requires costly “locally attached” storage (or memory)**: Many cloud environments do not offer computing resources with locally attached storage – they either rely on expensive network block storage such as AWS EBS or else restrict local storage to certain classes of VMs.

Avoiding the need to buffer the entire file requires a sophisticated Parquet decoder, integrated with the I/O subsystem, that can initially fetch and decode the metadata followed by ranged fetches for the relevant data blocks, interleaved with the decoding of Parquet data. This optimization requires careful engineering to fetch large enough blocks of data from the object store that the per request overhead doesn’t dominate gains from reducing the bytes transferred. [SPARK-36529](https://issues.apache.org/jira/browse/SPARK-36529) describes the challenges of sequential processing in more detail.


```
                       ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                                                                          │
                       │
               Step 1: Fetch                                              │
 Parquet       Parquet metadata
 file on ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▼━━━━━┓
 Remote  ┃          ▒▒▒▒▒▒▒▒▒▒            ▒▒▒▒▒▒▒▒▒▒                 ░░░░░░░░░░ ┃
 Object  ┃          ▒▒▒data▒▒▒            ▒▒▒data▒▒▒                 ░metadata░ ┃
  Store  ┃          ▒▒▒▒▒▒▒▒▒▒            ▒▒▒▒▒▒▒▒▒▒                 ░░░░░░░░░░ ┃
         ┗━━━━━━━━━━━━━━━▲━━━━━━━━━━━━━━━━━━━━━▲━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                         │                     └ ─ ─ ─
                                                      │
                         │                   Step 2: Fetch only
                          ─ ─ ─ ─ ─ ─ ─ ─ ─ relevant data blocks


```


Not included in this diagram picture are details like coalescing requests and ensuring minimum request sizes needed for an actual implementation.

The Rust Parquet crate provides an async Parquet reader, to efficiently read from any [AsyncFileReader](https://docs.rs/parquet/latest/parquet/arrow/async_reader/trait.AsyncFileReader.html) that:



* Efficiently reads from any storage medium that supports range requests
* Integrates with Rust’s futures ecosystem to avoid blocking threads waiting on network I/O [and easily can interleave CPU and network ](https://www.influxdata.com/blog/using-rustlangs-async-tokio-runtime-for-cpu-bound-tasks/)
* Requests multiple ranges simultaneously, to allow the implementation to coalesce adjacent ranges, fetch ranges in parallel, etc.
* Uses the pushdown techniques described previously to eliminate fetching data where possible
* Integrates easily with the Apache Arrow [object_store](https://docs.rs/object_store/latest/object_store/) crate which you can read more about [here](https://www.influxdata.com/blog/rust-object-store-donation/)

To give a sense of what is possible, the following picture shows a timeline of fetching the footer metadata from remote files, using that metadata to determine what Data Pages to read, and then fetching data and decoding simultaneously. This process often must be done for more than one file at a time in order to match network latency, bandwidth, and available CPU.


```
                           begin
          metadata        read of   end read
            read  ─ ─ ─ ┐   data    of data          │
 begin    complete         block     block
read of                 │   │        │               │
metadata  ─ ─ ─ ┐                                       At any time, there are
             │          │   │        │               │     multiple network
             │  ▼       ▼   ▼        ▼                  requests outstanding to
  file 1     │ ░░░░░░░░░░   ▒▒▒read▒▒▒   ▒▒▒read▒▒▒  │    hide the individual
             │ ░░░read░░░   ▒▒▒data▒▒▒   ▒▒▒data▒▒▒        request latency
             │ ░metadata░                         ▓▓decode▓▓
             │ ░░░░░░░░░░                         ▓▓▓data▓▓▓
             │                                       │
             │
             │ ░░░░░░░░░░  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒read▒▒▒▒│▒▒▒▒▒▒▒▒▒▒▒▒▒▒
   file 2    │ ░░░read░░░  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒data▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
             │ ░metadata░                            │              ▓▓▓▓▓decode▓▓▓▓▓▓
             │ ░░░░░░░░░░                                           ▓▓▓▓▓▓data▓▓▓▓▓▓▓
             │                                       │
             │
             │                                     ░░│░░░░░░░  ▒▒▒read▒▒▒  ▒▒▒▒read▒▒▒▒▒
   file 3    │                                     ░░░read░░░  ▒▒▒data▒▒▒  ▒▒▒▒data▒▒▒▒▒      ...
             │                                     ░m│tadata░            ▓▓decode▓▓
             │                                     ░░░░░░░░░░            ▓▓▓data▓▓▓
             └───────────────────────────────────────┼──────────────────────────────▶Time


                                                     │


```



## Conclusion

We hope you enjoyed reading about the Parquet file format, and the various techniques used to quickly query parquet files.

We believe that the reason most open source implementations of Parquet do not have the breadth of features described in this post is that it takes a monumental effort, that was previously only possible at well-financed commercial enterprises which kept their implementations closed source.

However, with the growth and quality of the Apache Arrow community, both Rust practitioners and the wider Arrow community, our ability to collaborate and build a cutting-edge open source implementation is exhilarating and immensely satisfying. The technology described in this blog is the result of the contributions of many engineers spread across companies, hobbyists, and the world in several repositories, notably [Apache Arrow DataFusion](https://github.com/apache/arrow-datafusion), [Apache Arrow](https://github.com/apache/arrow-rs) and [Apache Arrow Ballista.](https://github.com/apache/arrow-ballista)

If you are interested in joining the DataFusion Community, please [get in touch](https://arrow.apache.org/datafusion/contributor-guide/communication.html).
