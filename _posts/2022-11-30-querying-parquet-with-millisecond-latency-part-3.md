---
layout: post
title: "Querying Parquet with Millisecond Latency, Part 3"
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

In our third and final part of this series, we explain predicate pushdown as well



# Predicate Pushdown

Similar to projection pushdown, **predicate** pushdown also avoids fetching and decoding data from Parquet files, but does so using filter expressions. This technique typically requires closer integration with a query engine such as [DataFusion](https://arrow.apache.org/datafusion/), to determine valid predicates and evaluate them during the scan. Unfortunately without careful API design, the Parquet decoder and query engine can end up tightly coupled, preventing reuse (e.g. there are different Impala and Spark implementations in [Cloudera Parquet Predicate Pushdown docs](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cdh_ig_predicate_pushdown_parquet.html#concept_pgs_plb_mgb)). The Rust Parquet reader uses the [RowSelection](https://docs.rs/parquet/27.0.0/parquet/arrow/arrow_reader/struct.RowSelector.html) API to avoid this coupling.


## RowGroup Pruning

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


Note that pruning on minimum and maximum values is effective for many data layouts and column types, but not all. Specifically, it is not as effective for columns with many distinct pseudo random values (e.g. identifiers or uuids). Thankfully for this use case Parquet also supports per ColumnChunk [Bloom Filters](https://github.com/apache/parquet-format/blob/master/BloomFilter.md). We are actively working on[ adding bloom filter](https://github.com/apache/arrow-rs/issues/3023) support in Apache Rust’s implementation.


## Page Pruning

A more sophisticated form of predicate pushdown uses the optional [page index](https://github.com/apache/parquet-format/blob/master/PageIndex.md) in the footer metadata to rule out entire Data Pages. The decoder decodes only the corresponding rows from other columns, often skipping entire pages.

This optimization is complicated by the fact that pages in different ColumnChunks often contain different numbers of rows due to various reasons. While the page index may identify what pages are needed from one column, pruning a page from one column doesn’t immediately rule out entire pages in other columns.

Page pruning proceeds as follows::



* Use the predicates in combination with the page index to identify pages to skip
* Use the offset index to determine what row ranges correspond to non-skipped pages
* Computes the intersection of ranges across non-skipped pages, and decodes only those rows

This last point is highly non-trivial to implement, especially for nested lists where [a single row may correspond to multiple values](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/). Fortunately, the Rust Parquet reader hides this complexity internally, and can decode arbitrary [RowSelection](https://docs.rs/parquet/27.0.0/parquet/arrow/arrow_reader/struct.RowSelection.html)s.

For example, to scan Columns A and B,  stored in 5 Data Pages as shown in the figure below:

If the predicate is A > 35,



* Page 1 is pruned using the page index (max value is 20), leaving a RowSelection of  [200->onwards],
* Parquet reader skips Page 3 entirely (as its last row index is 99)
* (Only) the relevant rows are read by reading pages 2, 4 and 5.

If the predicate is instead A > 35 AND B = "F" the page index is even more effective



* Using A > 35, yields a RowSelection of [200->onwards] as before
* Using B = "F" on the remaining Page 4 and Page 5 of B, yields a RowSelection of [100-244]
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


Support for reading and writing these indexes from Arrow C++, and by extension pyarrow/pandas, is tracked in [PARQUET-1404](https://issues.apache.org/jira/browse/PARQUET-1404)


## Late Materialization

The two previous forms of predicate pushdown have only operated on metadata stored for RowGroups, ColumnChunks, and Data Pages prior to decoding values. However, the same techniques also extend to values of one or more columns *after* they have been decoded but prior to decoding other columns,  which is often called “late materialization”.

This technique is especially effective when:



* The predicate is very selective, i.e. filters out large numbers of rows
* Each row is large, either due to wide rows (e.g. JSON blobs) or many columns
* The selected data is clustered together
* The columns required by the predicate are relatively inexpensive to decode, e.g. PrimitiveArray / DictionaryArray

There is additional discussion in [SPARK-36527](https://issues.apache.org/jira/browse/SPARK-36527) and[ Impala](https://docs.cloudera.com/cdw-runtime/cloud/impala-reference/topics/impala-lazy-materialization.html).

For example, given the predicate A > 35 AND B = "F" from above where the engine has used the page index to determine only 50 rows within RowSelection of [100-244] could match, using late materialization, the Parquet decoder:



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
       240   │         40         │─ ─ ─ ─ ─ ─▶│         40         │
             └────────────────────┘            └────────────────────┘
                      ...                               ...
             ┌────────────────────┐            ┌────────────────────┐
      244    │         26         │            │        "D"         │
             └────────────────────┘            └────────────────────┘


                   Column A                          Column B
                    Values                            Values


```


In certain cases, such as our example where B stores single character values, the cost of late materialization machinery can outweigh the savings in decoding. However, the savings can be substantial when some of the conditions listed above are fulfilled. The query engine must decide which predicates to push down and in which order to apply them for optimal results.

While it is outside the scope of this document, the same technique can be applied for multiple predicates as well as predicates on multiple columns.  See the [RowFilter](https://docs.rs/parquet/latest/parquet/arrow/arrow_reader/struct.RowFilter.html)  interface in the Parquet crate for more information and the [row_filter](https://github.com/apache/arrow-datafusion/blob/58b43f5c0b629be49a3efa0e37052ec51d9ba3fe/datafusion/core/src/physical_plan/file_format/parquet/row_filter.rs#L40-L70) implementation in DataFusion a corresponding query engine implementation.


# IO Pushdown

While Parquet was designed for efficient access on the [HDFS distributed file system](https://hadoop.apache.org/docs/r1.2.1/hdfs_design.html), it works very well with commodity blob storage systems such as AWS S3 as they have very similar characteristics:



* **Relatively slow “random access” reads**: it is much more efficient to read large (MBs) sections of data in each request than issue many requests for smaller portions
* **Significant latency to before the first byte is retrieved**
* **High per-request cost: **Often billed per request, regardless of number of bytes read, which incentivizes fewer requests which each read a large contiguous section of data.

To read optimally from such systems, a Parquet reader must:



1. Minimize the number of I/O requests, while also applying the various pushdown techniques to avoid fetching large amounts of unused data.
2. Integrate with the appropriate task scheduling mechanism to interleave IO and processing on the data that is fetched to avoid pipeline bottlenecks.

As these are substantial engineering and integration challenges, many Parquet readers still require the files to be fetched in their entirety to local storage.

Fetching the entire files in order to process them is not ideal for several reasons:



1. **High Latency**: Decoding can not begin until the entire file to be fetched (Parquet metadata is at the end of the file, so the decoder must see the end prior to decoding the rest)
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
* Integrates with Rust’s futures ecosystem to avoid blocking threads waiting on network IO [and easily can interleave CPU and network ](https://www.influxdata.com/blog/using-rustlangs-async-tokio-runtime-for-cpu-bound-tasks/)
* Requests multiple ranges simultaneously, to allow the implementation to coalesce adjacent ranges, fetch ranges in parallel, etc…
* Uses the pushdown techniques described previously to eliminate fetching data where possible
* Integrates easily with the Apache Arrow [object_store](https://docs.rs/object_store/latest/object_store/) crate which you can read more about [here](https://www.influxdata.com/blog/rust-object-store-donation/)

To give a sense of what is possible, the following picture shows a timeline of fetching the footer metadata from remote files, using that metadata to determine what DataPages to read, and then fetching data and decoding simultaneously. This process often must be done for more than one file at a time in order to match network latency, bandwidth and available CPU.


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
             │ ░░░read░░░   ▒▒▒data▒▒▒   ▒▒▒data▒▒▒        request latency1
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

We hope you enjoyed reading about the Parquet file format, and the various techniques used to query them so quickly.

We believe that the reason most open source implementations of Parquet do not have the breadth of features described in this post is that it takes a monumental effort, that was previously only possible at well financed commercial enterprises which kept their implementations closed source.

However, with the growth and quality of the Apache Arrow community, both Rust practitioners and the wider Arrow community, our ability to collaborate and build a cutting edge open source implementation is exhilarating and immensely satisfying. The technology described in this blog is the result of the contributions of many engineers spread across companies, hobbyists, and the world in several repositories, notably [Apache Arrow DataFusion](https://github.com/apache/arrow-datafusion), [Apache Arrow](https://github.com/apache/arrow-rs) and [Apache Arrow Ballista.](https://github.com/apache/arrow-ballista)

If you are interested in joining, come find us at [https://arrow.apache.org/datafusion/contributor-guide/communication.html](https://arrow.apache.org/datafusion/contributor-guide/communication.html)
