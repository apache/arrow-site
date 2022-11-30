---
layout: post
title: "Querying Parquet with Millisecond Latency, Part 1"
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


We believe that querying data in [Apache Parquet](https://parquet.apache.org/) files directly can achieve similar or better storage efficiency and query performance than most specialized file formats. While it requires significant engineering effort, the benefits of Parquet's open format and broad ecosystem support make it the obvious choice for a wide class of data systems.

In this series we explain several advanced techniques needed to query data stored in the Parquet format quickly that we have implemented in the [Apache Arrow Rust Parquet reader](https://docs.rs/parquet/27.0.0/parquet/). Together these techniques make the Rust implementation one of, if not the, fastest implementation for querying Parquet files, be it on local disk or remote object storage. It is able to query GBs of Parquet in a [matter of milliseconds](https://github.com/tustvold/access-log-bench).

We would like to acknowledge and thank [InfluxData](https://www.influxdata.com/) for their support of this work. InfluxData has a deep and continuing commitment to Open Source Software, and it sponsored much of our time for writing this blog post as well as many contributions as part of building the [InfluxDB IOx Storage Engine](https://www.influxdata.com/blog/influxdb-engine/).


# Background

[Apache Parquet](https://parquet.apache.org/) is an increasingly popular open format for storing [analytic datasets](https://www.influxdata.com/glossary/olap/), and has become the de-facto standard for cost-effective, DBMS-agnostic data storage. Initially created for the Hadoop ecosystem, Parquet’s reach has expanded broadly across the data analytics ecosystem due to its compelling combination of:



* High compression ratios
* Amenability to commodity blob-storage such as S3
* Broad ecosystem and tooling support
* Portability across many different platforms and tools
* Support for [arbitrarily structured data](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/)

Increasingly other systems, such as [DuckDB](https://duckdb.org/2021/06/25/querying-parquet.html) and [Redshift](https://docs.aws.amazon.com/redshift/latest/dg/c-using-spectrum.html#c-spectrum-overview) allow querying data stored in Parquet directly, but support is still often a secondary consideration compared to their native (custom) file formats. Such formats include the DuckDB `.duckdb` file format, the Apache IOT [TsFile](https://github.com/apache/iotdb/blob/master/tsfile/README.md), the [Gorilla format](https://www.vldb.org/pvldb/vol8/p1816-teller.pdf), and others.

For the first time, access to the same sophisticated query techniques, previously only available in closed source commercial implementations, are now available as open source. The required engineering capacity comes from large, well run open source projects with global contributor communities, such as [Apache Arrow](https://arrow.apache.org/) and [Apache Impala](https://impala.apache.org/).


# Parquet File Format

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

The footer may also contain other specialized data structures as well:



* Optional statistics for each ColumnChunk including min/max values and null counts
* Optional pointers to [OffsetIndexes](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L926-L932) containing the location of each individual Page
* Optional pointers to [ColumnIndex](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L938) containing row counts and summary statistics for each Page
* Optional pointers to [BloomFilterData](https://github.com/apache/parquet-format/blob/54e53e5d7794d383529dd30746378f19a12afd58/src/main/thrift/parquet.thrift#L621-L630), which can quickly check if a value is present in a ColumnChunk

For example, the logical structure of 2 Row Groups and 6 ColumnChunks in the previous diagram might be stored as in a Parquet file as shown in the following diagram (not to scale).  The Pages for the ColumnChunks come first, followed by the footer. The number of and size of the Pages needed for each ColumnChunk is determined by the data, the effectiveness of the encoding scheme, and the settings of the Parquet encoder. In this case, ColumnChunk 1 required 2 pages while ColumnChunk 6 required only 1 page. In addition to other information, the  footer contains the locations of each Data Page and the types of the columns.


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


There are many important criteria to consider when creating Parquet files such as how to optimally order / cluster data and structure it into RowGroups and Data Pages for expected query patterns. Such “physical design” considerations are complex, worthy of their own series of articles, and not addressed in this blog. We will instead focus on how to use the available structure to make queries very fast.



# Next up

Now that we have explained how Parquet files are structured, [Part 2]({% post_url 2022-11-30-querying-parquet-with-millisecond-latency-part-2 %}) explains important decode optimizations as well as Projection Pushdown.
