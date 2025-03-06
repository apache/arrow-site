---
layout: post
title: "Fast Streaming Inserts in DuckDB with ADBC"
description: "ADBC enables high throughput insertion into DuckDB"
date: "2025-03-04 00:00:00"
author: loicalleyne
categories: [application]
image:
  path: /img/adbc-duckdb/adbc-duckdb.png
  height: 560
  width: 1200
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

# Fast Streaming Inserts in DuckDB with ADBC

<img src="{{ site.baseurl }}/img/adbc-duckdb/adbc-duckdb.png" width="100%" class="img-responsive" alt="" aria-hidden="true"> 
# TL;DR

DuckDB is rapidly becoming an essential part of data practitioners' toolbox, finding use cases in data engineering, machine learning, and local analytics. In many cases DuckDB has been used to query and process data that has already been saved to storage (file-based or external database) by another process. Arrow Database Connectivity APIs enable high-throughput data processing using DuckDB as the engine.

# How it started

The company I work for is the leading digital out-of-home marketing platform, including a programmatic ad tech stack. For several years, my technical operations team was making use of logs emitted by the real-time programmatic auction system in the [Apache Avro](http://avro.apache.org/) format. Over time we've built an entire operations and analytics back end using this data. Avro files are row-based which is less than ideal for analytics at scale, in fact it's downright painful. So much so that I developed and contributed an Avro reader feature to the [Apache Arrow  Go](https://github.com/apache/arrow-go) library to be able to convert Avro files to parquet. This data pipeline is now humming along transforming hundreds of GB/day from Avro to Parquet.

Since "any problem in computer science can be solved with another layer of indirection", the original system has grown layers (like an onion) and started to emit other logs, this time in [Apache Parquet](https://parquet.apache.org/) format...  
<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/adbc-duckdb/muchrejoicing.gif" width="80%" class="img-responsive" alt="Figure 1: And there was much rejoicing">
  <figcaption>Figure 1: A pseudo-medieval tapestry displaying intrepid data practitioners rejoicing due to a columnar data storage format.</figcaption>
</figure> 
As we learned in Shrek, onions are like ogres: they're green, they have layers and they make you cry, so this rejoicing was rather short-lived, as the mechanism chosen to emit the parquet files was rather inefficient:

* the new onion-layer (ahem...system component) sends Protobuf encoded messages to Kafka topics  
* a Kafka Connect cluster with the S3 sink connector consumes topics and saves the parquet files to object storage

Due to the firehose of data, the cluster size over time grew to \> 25 nodes and was producing thousands of small Parquet files (13 MB or smaller) an hour. This led to ever-increasing query latency, in some cases breaking our tools due to query timeouts (aka [the small files problem](https://www.dremio.com/blog/compaction-in-apache-iceberg-fine-tuning-your-iceberg-tables-data-files/#h-the-small-files-problem)). Not to mention that running aggregations on the raw data in our data warehouse wasn't fast or cheap.

# DuckDB to the rescue... I think

I'd used DuckDB to process and analyse Parquet data so I knew it could do that very quickly. Then I came across this post on LinkedIn ([Real-Time Analytics using Kafka and DuckDB](https://www.linkedin.com/posts/shubham-dhal-349626ba_real-time-analytics-with-kafka-and-duckdb-activity-7258424841538555904-xfU6)), where someone has built a system for near-realtime analytics in Go using DuckDB.

The slides listed DuckDB's limitations:  
<img src="{{ site.baseurl }}/img/adbc-duckdb/duckdb.png" width="100%" class="img-responsive" alt="DuckDB limitations: Single Pod, *Data should fit in memory, *Low Query Concurrency, *Low Ingest Rate - *Solvable with some efforts" aria-hidden="true"> 
The poster's solution batches data at the application layer managing to scale up ingestion 100x to \~20k inserts/second, noting that they thought that using the DuckDB Appender API could possibly increase this 10x. So, potentially \~200k inserts/second. Yayyyyy...  

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/adbc-duckdb/Yay.gif" width="40%" class="img-responsive" alt="Figure 2: Yay">
</figure> 

Then I noticed the data schema in the slides was flat and had only 4 fields (vs. [OpenRTB](https://github.com/InteractiveAdvertisingBureau/openrtb2.x/blob/main/2.6.md#31---object-model-) schema with deeply nested Lists and Structs); and then looked at our monitoring dashboards whereupon I realized that at peak our system was emitting \>250k events/second. \[cue sad trombone\]

Undeterred (and not particularly enamored with the idea of setting up/running/maintaining a Spark cluster), I suspected that Apache Arrow's columnar memory representation might still make DuckDB viable since it has an Arrow API; getting Parquet files would be as easy as running `COPY...TO (format parquet)`.

Using a pattern found in a Github issue, I wrote a POC using [github.com/marcboeker/go-duckdb](http://github.com/marcboeker/go-duckdb) to connect to a DB, retrieve an Arrow, create an Arrow Reader, register a view on the reader, then run an INSERT statement from the view. 

This felt a bit like a rabbit pulling itself out of a hat, but no matter, it managed between \~74k and \~110k rows/sec on my laptop.

To make sure this was really the right solution, I also tried out DuckDB's Appender API (at time of writing the official recommendation for fast inserts) and managed... \~63k rows/sec on my laptop. OK, but... meh.

# A new hope

In a discussion on the Gopher Slack, Matthew Topol aka [zeroshade](https://github.com/zeroshade) suggested using [ADBC](http://arrow.apache.org/adbc) with its much simpler API. Who is Matt Topol you ask? Just the guy who *literally* wrote the book on Apache Arrow, that's who ([***In-Memory Analytics with Apache Arrow: Accelerate data analytics for efficient processing of flat and hierarchical data structures 2nd Edition***](https://www.packtpub.com/en-us/product/in-memory-analytics-with-apache-arrow-9781835461228)). It's an excellent resource and guide for working with Arrow.   
BTW, should you prefer an acronym to remember the name of the book, it's ***IMAAA:ADAFEPOFAHDS2E***.  
<img src="{{ site.baseurl }}/img/adbc-duckdb/imaaapfedaobfhsd2e.png" width="100%" class="img-responsive" alt="Episode IX: In-Memory Analytics with Apache Arrow: Perform fast and efficient data analytics on both flat and hierarchical structured data 2nd Edition aka IMAAA:PFEDAOBFHSD2E by Matt Topol" aria-hidden="true">  
But I digress. Matt is also a member of the Apache Arrow PMC, a major contributor to the Go implementation of Apache Iceberg and generally a nice, helpful guy.

# ADBC

Going back to the drawing board, I created [Quacfka](https://github.com/loicalleyne/quacfka), a Go library built using ADBC and split out my system into 3 worker pools, connected by channels:

* Kafka clients consuming topic messages and writing the bytes to a message channel  
* Processing routines using the [Bufarrow](https://github.com/loicalleyne/bufarrow) library to deserialize Protobuf data and append it to Arrow arrays, writing Arrow Records to a record channel  
* DuckDB inserters binding the Arrow Records to ADBC statements and executing insertions

I first ran these in series to determine how fast each could run:

  *2025/01/23 23:39:27 kafka read start with 8 readers*  
  *2025/01/23 23:39:41 read 15728642 kafka records in 14.385530 secs @ 1093365.498477 messages/sec*  
  *2025/01/23 23:39:41 deserialize \[\]byte to proto, convert to arrow records with 32 goroutines start*  
  *2025/01/23 23:40:04 deserialize to arrow done \- 15728642 records in 22.283532 secs @ 705841.509812 messages/sec*  
  *2025/01/23 23:40:04 ADBC IngestCreateAppend start with 32 connections*  
  *2025/01/23 23:40:25 duck ADBC insert 15728642 records in 21.145649535 secs @ **743824.007783 rows/sec***

<img src="{{ site.baseurl }}/img/adbc-duckdb/holdmybeer.png" width="100%" class="img-responsive" alt="20k rows/sec? Hold my beer" aria-hidden="true">  

With this architecture decided, I then started running the workers concurrently, instrumenting the system, profiling my code to identify performance issues and tweaking the settings to maximize throughput. It seemed to me that there was enough performance headroom to allow for in-flight aggregations.

One issue: Despite DuckDB's excellent [lightweight compression](https://duckdb.org/2022/10/28/lightweight-compression.html), inserts from this source were making the file size increase at a rate of ***\~8GB/minute***. Putting inserts on hold to export the Parquet files and release the storage would reduce the overall throughput to an unacceptable level. I decided to implement a rotation of database files based on a file size threshold. 

DuckDB being able to query Hive partitioned parquet on disk or in object storage, the analytics part could be decoupled from the data ingestion pipeline by running a separate querying server pointing at wherever the parquet files would end up. 

Iterating, I created several APIs to try to make in-flight aggregations efficient enough to keep the overall throughput above my 250k rows/second target. 

The first two either ran into issues of data locality or weren't optimized enough:

*    **CustomArrows** : functions to run on each Arrow Record to create a new Record to insert along with the original
*    **DuckRunner** : run a series of queries on the database file before rotation


Reasoning that if unnesting deeply nested data in Arrow Record arrays was causing data locality issues:

*   **Normalizer**: a Bufarrow API used in the in the deserialization function to normalize the message data and append it to another Arrow Record, inserted into a separate table

This approach allowed throughput to go back to levels almost as high as without Normalizer \- flat data is much faster to process and insert.

# Oh, we're halfway there...livin' on a prayer

Next, I tried opening concurrent connections to multiple databases. **BAM\!** ***Segfault***. DuckDB concurrency model isn't [designed](https://duckdb.org/docs/stable/connect/concurrency.html#handling-concurrency) that way. From within a process only a single database (in-memory or file) can be opened, then other database files can be [attached](https://duckdb.org/docs/stable/sql/statements/attach.html) to the central db's catalog. 

Having already decided to rotate DB files, I decided to make a separate program ([Runner](https://github.com/loicalleyne/quacfka-runner)) to process the database files as they were rotated, running aggregations on normalized data and table dumps to parquet. This meant setting up an RPC connection between the two and figuring out a backpressure mechanism to avoid `disk full` events.

However having the two running simultaneously was causing memory pressure issues, not to mention massively slowing down the throughput. Upgrading the VM to one with more vCPUs and memory only helped a little, there was clearly some resource contention going on.

Since Go 1.5, the default `GOMAXPROCS` value is the number of CPU cores available. What if this was reduced to "sandbox" the ingestion process, along with setting the DuckDB thread count in the Runner? This actually worked so well, it increased the overall throughput. [Runner](https://github.com/loicalleyne/quacfka-runner) runs the `COPY...TO...parquet` queries, walks the parquet output folder, uploads files to object storage and deletes the uploaded files. Balancing the DuckDB file rotation size threshold in [Quafka-Service](https://github.com/loicalleyne/quacfka-service) allows Runner to keep up and avoid a backlog of DB files on disk. 

# Results

<img src="{{ site.baseurl }}/img/adbc-duckdb/btop.png" width="100%" class="img-responsive" alt="btop utility showing CPU and memory usage of quacfka-service and runner" aria-hidden="true">  
Note: both runs with `GOMAXPROCS` set to 24 (the number of DuckDB insertion routines)

Ingesting the raw data (14 fields with one deeply nested LIST.STRUCT.LIST field) \+ normalized data:  
  *num\_cpu: 60*  
  *runtime\_os: linux*  
  *kafka\_clients: 5*  
  *kafka\_queue\_cap: 983040*  
  *processor\_routines: 32*  
  *arrow\_queue\_cap: 4*  
  *duckdb\_threshold\_mb: 4200*  
  *duckdb\_connections: 24*  
  *normalizer\_fields: 10*  
  *start\_time: 2025-02-24T21:06:23Z*  
  *end\_time: 2025-02-24T21:11:23Z*  
  *records: 123\_686\_901.00*  
  *norm\_records: 122\_212\_452.00*  
  *data\_transferred: 146.53 GB*  
  *duration: 4m59.585s*  
  ***records\_per\_second: 398\_271.90***  
  ***total\_rows\_per\_second: 806\_210.41***  
  *transfer\_rate: 500.86 MB/second*  
  *duckdb\_files: 9*  
  *duckdb\_files\_MB: 38429*  
  *file\_avg\_duration: 33.579s*

How many rows/second could we get if we only inserted the flat, normalized data? (Note: original records are still processed, just not inserted) 
  *num\_cpu: 60*  
  *runtime\_os: linux*  
  *kafka\_clients: 10*  
  *kafka\_queue\_cap: 1228800*  
  *processor\_routines: 32*  
  *arrow\_queue\_cap: 4*  
  *duckdb\_threshold\_mb: 4200*  
  *duckdb\_connections: 24*  
  *normalizer\_fields: 10*  
  *start\_time: 2025-02-25T19:04:33Z*  
  *end\_time: 2025-02-25T19:09:36Z*  
  *records: 231\_852\_772.00*  
  *norm\_records: 363\_247\_327.00*  
  *data\_transferred: 285.76 GB*  
  *duration: 5m3.059s*  
  *records\_per\_second: 0.00*  
  ***total\_rows\_per\_second: 1\_198\_601.39***  
  *transfer\_rate: 965.54 MB/second*  
  *duckdb\_files: 5*  
  *duckdb\_files\_MB: 20056*  
  *file\_avg\_duration: 58.975s*  
<img src="{{ site.baseurl }}/img/adbc-duckdb/onemillionrows.png" width="100%" class="img-responsive" alt="One million rows/second" aria-hidden="true"> 

Once deployed, the number of parquet files fall from ~3000 small files per hour to ~12 files per hour. Goodbye small files!

<img src="{{ site.baseurl }}/img/adbc-duckdb/kip_yes.gif" width="25%" class="img-responsive" alt="Yesss" aria-hidden="true"> 

# Challenges/Learnings

* DuckDB insertions are the bottleneck; network speed, Protobuf deserialization, **building Arrow Records are not**  
* For fastest insertion into DuckDB Arrow Records should contain at least 122880 rows (to align with DuckDB storage row group size)   
* DuckDB won't let you open more than one database at once within the same process (results in a segfault). DuckDB is designed to run only once in a process, with a central database's catalog having the ability to add connections to other databases.   
  * Workarounds: 
    - Separate processes for writing and reading multiple database files
    - Open a single DuckDB database and use [ATTACH](https://duckdb.org/docs/stable/sql/statements/attach.html) to attach other DB files
* Flat data is much, much faster to insert than nested data

<img src="{{ site.baseurl }}/img/adbc-duckdb/whatdoesitallmean.gif" width="100%" class="img-responsive" alt="Whoopdy doo, what does it all mean Basil?" aria-hidden="true"> 

ADBC provides DuckDB with a truly high-throughput data ingestion API, unlocking a slew of use cases for using DuckDB with streaming data, making this an ever more useful tool for data practitioners. 