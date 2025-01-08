---
layout: post
title: "How the Apache Arrow Format Accelerates Query Result Transfer"
date: "2025-01-07 00:00:00"
author: Ian Cook, David Li, Matt Topol
categories: [application]
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

_This is the first in a series of posts that aims to demystify the use of Arrow as a data interchange format for databases and query engines._

_________________

“Why is this taking so long?”

This is a question that data practitioners often ponder while waiting for query results. It’s a question with many possible answers. Maybe your data source is poorly partitioned. Maybe your SaaS data warehouse is undersized. Maybe the query optimizer failed to translate your SQL statement into an efficient execution plan.

But surprisingly often, the answer is that you are using an inefficient protocol to transfer query results to the client. In a [2017 paper](https://www.vldb.org/pvldb/vol10/p1022-muehleisen.pdf){:target="_blank"}, Mark Raasveldt and Hannes Mühleisen observed that query result transfer time often dominates query execution time, especially for larger results. However, the bottleneck is not where you might expect.

Transferring a query result from a source to a destination involves three steps:

1. At the source, serialize the result from its original format into a transfer format.
2. Transmit the data over the network in the transfer format.[^1]
3. At the destination, deserialize the transfer format into the target format.

In the era of slower networks, the transmission step was usually the bottleneck, so there was little incentive to speed up the serialization and deserialization steps. Instead, the emphasis was on making the transferred data smaller, typically using compression, to reduce the transmission time. It was during this era that the most widely used database connectivity APIs (ODBC and JDBC) and database client protocols (such as the MySQL client/server protocol and the PostgreSQL frontend/backend protocol) were designed. But as networks have become faster and transmission times have dropped, the bottleneck has shifted to the serialization and deserialization steps.[^2] This is especially true for queries that produce the larger result sizes characteristic of many data engineering and data analytics pipelines.

Yet many query results today continue to flow through legacy APIs and protocols that add massive serialization and deserialization (“ser/de”) overheads by forcing data into inefficient transfer formats. In a [2021 paper](https://www.vldb.org/pvldb/vol14/p534-li.pdf){:target="_blank"}, Tianyu Li et al. presented an example using ODBC and the PostgreSQL protocol in which 99.996% of total query time was spent on ser/de. That is arguably an extreme case, but we have observed 90% or higher in many real-world cases. Today, for data engineering and data analytics queries, there is a strong incentive to choose a transfer format that speeds up ser/de.

Enter Arrow.

The Apache Arrow open source project defines a [data format](https://arrow.apache.org/docs/format/Columnar.html){:target="_blank"} that is designed to speed up—and in some cases eliminate—ser/de in query result transfer. Since its creation in 2016, the Arrow format and the multi-language toolbox built around it have gained widespread use, but the technical details of how Arrow is able to slash ser/de overheads remain poorly understood. To help address this, we outline five key attributes of the Arrow format that make this possible.

### 1. The Arrow format is columnar.

Columnar (column-oriented) data formats hold the values for each column in contiguous blocks of memory. This is in contrast to row-oriented data formats, which hold the values for each row in contiguous blocks of memory.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/arrow-result-transfer/part-1-figure-1-row-vs-column-layout.png" width="100%" class="img-responsive" alt="Figure 1: An illustration of row-oriented and column-oriented physical memory layouts of a logical table containing three rows and five columns.">
  <figcaption>Figure 1: An illustration of row-oriented and column-oriented physical memory layouts of a logical table containing three rows and five columns.</figcaption>
</figure>

High-performance analytic databases, data warehouses, query engines, and storage systems have converged on columnar architecture because it speeds up the most common types of analytic queries. Examples of modern columnar query systems include Amazon Redshift, Apache DataFusion, ClickHouse, Databricks Photon Engine, DuckDB, Google BigQuery, Microsoft Azure Synapse Analytics, OpenText Analytics Database (Vertica), Snowflake, and Voltron Data Theseus.

Likewise, many destinations for analytic query results (such as business intelligence tools, data application platforms, dataframe libraries, and machine learning platforms) use columnar architecture. Examples of columnar business intelligence tools include Amazon QuickSight, Domo, GoodData, Power BI, Qlik Sense, Spotfire, and Tableau. Examples of columnar dataframe libraries include cuDF, pandas, and Polars.

So it is increasingly common for both the source format and the target format of a query result to be columnar formats. The most efficient way to transfer data between a columnar source and a columnar target is to use a columnar transfer format. This eliminates the need for a time-consuming transpose of the data from columns to rows at the source during the serialization step and another time-consuming transpose of the data from rows to columns at the destination during the deserialization step.

Arrow is a columnar data format. The column-oriented layout of data in the Arrow format is similar—and in some cases identical—to the layout of data in many widely used columnar source systems and destination systems.

### 2. The Arrow format is self-describing and type-safe.

In a self-describing data format, the schema (the names and types of the columns) and other metadata that describe the data’s structure are included with the data. A self-describing format provides the receiving system with all the information it needs to safely and efficiently process the data. By contrast, when a format is not self-describing, the receiving system must scan the data to infer its schema and structure (a slow and error-prone process) or obtain the schema separately.

An important property of some self-describing data formats is the ability to enforce type safety. When a format enforces type safety, it guarantees that data values conform to their specified types, thereby allowing the receiving system to rule out the possibility of type errors when processing the data. By contrast, when a format does not enforce type safety, the receiving system must check the validity of each individual value in the data (a computationally expensive process) or handle type errors when processing the data.

When reading data from a non-self-describing, type-unsafe format (such as CSV), all this scanning, inferring, and checking contributes to large deserialization overheads. Worse, such formats can lead to ambiguities, debugging trouble, maintenance challenges, and security vulnerabilities.

The Arrow format is self-describing and enforces type safety. Furthermore, Arrow’s type system is similar—and in some cases identical—to the type systems of many widely used data sources and destinations. This includes most columnar data systems and many row-oriented systems such as Apache Spark and various relational databases. When using the Arrow format, these systems can quickly and safely convert data values between their native types and the corresponding Arrow types.


### 3. The Arrow format enables zero-copy.

A zero-copy operation is one in which data is transferred from one medium to another without creating any intermediate copies. When a data format supports zero-copy operations, this means that its structure in memory is the same as its structure on disk or on the network. So, for example, the data can be read off of the network directly into a usable data structure in memory without performing any intermediate copies or conversions.

The Arrow format supports zero-copy operations. Arrow defines a column-oriented tabular data structure called a [record batch](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc){:target="_blank"} which can be held in memory, sent over a network, or stored on disk. The binary structure of an Arrow record batch is the same regardless of which medium it is on. Also, to hold schemas and other metadata, Arrow uses FlatBuffers, a format created by Google which also has the same binary structure regardless of which medium it is on.

As a result of these design choices, Arrow can serve not only as a transfer format but also as an in-memory format and on-disk format. This is in contrast to text-based formats such as JSON and CSV, which encode data values as plain text strings separated by delimiters and other structural syntax. To load data from these formats into a usable in-memory data structure, the data must be parsed and decoded. This is also in contrast to binary formats such as Parquet and ORC, which use encodings and compression to reduce the size of the data on disk. To load data from these formats into a usable in-memory data structure, it must be decompressed and decoded.[^3]

This means that at the source system, if data exists in memory or on disk in Arrow format, that data can be transmitted over the network in Arrow format without any serialization. And at the destination system, Arrow-formatted data can be read off the network into memory or into Arrow files on disk without any deserialization.

The Arrow format was designed to be highly efficient as an in-memory format for analytic operations. Because of this, many columnar data systems have been built using Arrow as their in-memory format. These include Apache DataFusion, cuDF, Dremio, InfluxDB, Polars, Velox, and Voltron Data Theseus. When one of these systems is the source or destination of a transfer, ser/de overheads can be fully eliminated. With most other columnar data systems, the proprietary in-memory formats they use are very similar to Arrow. With those systems, serialization to Arrow and deserialization from Arrow format are fast and efficient.

### 4. The Arrow format enables streaming.

A streamable data format is one that can be processed sequentially, one chunk at a time, without waiting for the full dataset. When data is being transmitted in a streamable format, the receiving system can begin processing it as soon as the first chunk arrives. This can speed up data transfer in several ways: transfer time can overlap with processing time; the receiving system can use memory more efficiently; and multiple streams can be transferred in parallel, speeding up transmission, deserialization, and processing.

CSV is an example of a streamable data format, because the column names (if included) are in a header at the top of the file, and the lines in the file can be processed sequentially. Parquet and ORC are examples of data formats that do not enable streaming, because the schema and other metadata, which are required to process the data, are held in a footer at the bottom of the file, making it necessary to download the entire file before any processing can begin.

Arrow is a streamable data format. A dataset can be represented in Arrow as a sequence of record batches that all have the same schema. Arrow defines a [streaming format](https://arrow.apache.org/docs/format/Columnar.html#ipc-streaming-format){:target="_blank"} consisting of the schema followed by one or more record batches. A system receiving an Arrow stream can process the record batches sequentially as they arrive.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/arrow-result-transfer/part-1-figure-2-arrow-stream.png" width="100%" class="img-responsive" alt="Figure 2: An illustration of an Arrow stream transmitting the data from a logical table with three columns. The first record batch contains the values for the first three rows, the second record batch contains the values for the next three rows, and so on. Actual Arrow record batches might contain thousands to millions of rows.">
  <figcaption>Figure 2: An illustration of an Arrow stream transmitting the data from a logical table with three columns. The first record batch contains the values for the first three rows, the second record batch contains the values for the next three rows, and so on. Actual Arrow record batches might contain thousands to millions of rows.</figcaption>
</figure>

### 5. The Arrow format is universal.

Arrow has emerged as a de facto standard format for working with tabular data in memory. The Arrow format is a language-independent open standard. Libraries are available for working with Arrow data in languages including C, C++, C#, Go, Java, JavaScript, Julia, MATLAB, Python, R, Ruby, Rust, and Swift. Applications developed in virtually any mainstream language can add support for sending or receiving data in Arrow format. Data does not need to pass through a specific language runtime, like it must with some database connectivity APIs, including JDBC.

Arrow’s universality allows it to address a fundamental problem in speeding up real-world data systems: Performance improvements are inherently constrained by a system’s bottlenecks. This problem is known as [Amdahl’s law](https://www.geeksforgeeks.org/computer-organization-amdahls-law-and-its-proof/){:target="_blank"}. In real-world data pipelines, query results often flow through multiple stages, incurring ser/de overheads at each stage. If, for example, your data pipeline has five stages and you eliminate ser/de overheads in four of them, your system might be no faster than before because ser/de in the one remaining stage will bottleneck the full pipeline.

Arrow’s ability to operate efficiently in virtually any technology stack helps to solve this problem. Does your data flow from a Scala-based distributed backend with NVIDIA GPU-accelerated workers to a Jetty-based HTTP server then to a Rails-powered feature engineering app which users interact with through a Node.js-based machine learning framework with a Pyodide-based browser front end? No problem; Arrow libraries are available to eliminate ser/de overheads between all of those components.

### Conclusion

As more commercial and open source tools have added support for Arrow, fast query result transfer with low or no ser/de overheads has become increasingly common. Today, commercial data platforms and query engines including Databricks, Dremio, Google BigQuery, InfluxDB, Snowflake, and Voltron Data Theseus and open source databases and query engines including Apache DataFusion, Apache Doris, Apache Spark, ClickHouse, and DuckDB can all transfer query results in Arrow format. The speedups are substantial:

- Apache Doris: [faster “by a factor ranging from 20 to several hundreds”](https://doris.apache.org/blog/arrow-flight-sql-in-apache-doris-for-10x-faster-data-transfer){:target="_blank"}
- Google BigQuery: [up to “31x faster”](https://medium.com/google-cloud/announcing-google-cloud-bigquery-version-1-17-0-1fc428512171){:target="_blank"}
- Dremio: [“more than 10 times faster”](https://www.dremio.com/press-releases/dremio-announces-support-for-apache-arrow-flight-high-performance-data-transfer/){:target="_blank"}
- DuckDB: [“38x” faster](https://duckdb.org/2023/08/04/adbc.html#benchmark-adbc-vs-odbc){:target="_blank"}
- Snowflake: [“up to a 10x” faster](https://www.snowflake.com/en/blog/fetching-query-results-from-snowflake-just-got-a-lot-faster-with-apache-arrow/){:target="_blank"}

On the receiving side, data practitioners can maximize speedups by using Arrow-based tools and Arrow libraries, interfaces, and protocols. In 2025, as more projects and vendors implement support for the [ADBC](https://arrow.apache.org/adbc/){:target="_blank"} standard, we expect to see accelerating growth in the number of tools that can receive query results in Arrow format.

Stay tuned for upcoming posts in this series, which will compare the Arrow format to other data formats and describe the protocols and APIs that clients can use to fetch results in Arrow format.

_________________

[^1]: The transfer format may also be called the wire format or serialization format.
[^2]: From the 1990s to today, increases in network performance outpaced increases in CPU performance. For example, in the late 1990s, a mainstream desktop CPU could perform roughly 1 GFLOPS and a typical WAN connection speed was 56 Kb/s. Today, a mainstream desktop CPU can perform roughly 100 GFLOPS and WAN connection speeds of around 1 Gb/s are common. So while CPU performance increased by about 100x, network speed increased by about 10,000x.
[^3]: An upcoming post in this series will compare the Arrow format to these and other formats in more technical detail.
