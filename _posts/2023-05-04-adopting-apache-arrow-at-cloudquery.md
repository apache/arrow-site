---
layout: post
title: "Adopting Apache Arrow at CloudQuery"
date: "2023-05-04 00:00:00"
author: Yevgeny Pats
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

This post is a collaboration with CloudQuery and cross-posted on the CloudQuery [blog](https://cloudquery.io/blog/adopting-apache-arrow-at-cloudquery).

[CloudQuery](https://github.com/cloudquery/cloudquery) is an open source high performance ELT framework written in Go. We [previously](https://www.cloudquery.io/blog/building-cloudquery) discussed some of the [architecture](https://www.cloudquery.io/docs/developers/architecture) and design decisions that we took to build a performant ELT framework. A type system is a key component for creating a performant and scalable ELT framework where sources and destinations are decoupled. In this blog post we will go through why we decided to adopt Apache Arrow as our type system and replace our in-house implementation.

# What is a Type System?

Let’s quickly [recap](https://www.cloudquery.io/blog/building-cloudquery#type-system) what a type system is and why an ELT framework needs one. At a very high level, an ELT framework extracts data from some source and moves it to some destination with a specific schema.

```text
API ---> [Source Plugin]  ----->    [Destination Plugin]
                          ----->    [Destination Plugin]
                           gRPC
```


Sources and destinations are decoupled and communicate via gRPC. This is crucial to allowing the addition of new destinations and updating old destinations without requiring updates to source plugin code (which otherwise would introduce an unmaintainable architecture).

This is where a type system comes in. Source plugins extract information from APIs in the most performant way possible, defining a schema and then transforming the result from the API (JSON or any other format) to a well-defined type system. The destination plugin can then easily create the schema for its database and transform the incoming data to the destination types. So to recap, the source plugin sends mainly two things to a destination: 1) the schema 2) the records that fit the defined schema. In Arrow terminology, these are a schema and a record batch.

# Why Arrow?

Before Arrow, we used our own type system that supported more than 14 types. This served us well, but we started to hit limitations in various use-cases. For example, in database to database replication, we needed to support many more types, including nested types. Also, performance-wise, lots of the time spent in an ELT process is around converting data from one format to another, so we wanted to take a step back and see if we can avoid this [famous XKCD](https://xkcd.com/927/) (by building yet another format):

<figure style="text-align: center;">
  <img src="https://imgs.xkcd.com/comics/standards.png" width="100%" class="img-responsive" alt="Yet another standard XKCD">
</figure>


This is where Arrow comes in. Apache Arrow defines a language-independent columnar format for flat and hierarchical data, and brings the following advantages:

1. Cross-language with extensive libraries for different languages - The [format](https://arrow.apache.org/docs/format/Columnar.html) is defined via flatbuffers in such way that you can parse it in any language and already has extensive support in C/C++, C#, Go, Java, JavaScript, Julia, Matlab, Python, R, Ruby and Rust (at the time of writing). For CloudQuery this is important as it makes it much easier to develop source or destination plugins in different languages.
2. Performance: Arrow adoption is rising especially in columnar based databases ([DuckDB](https://duckdb.org/2021/12/03/duck-arrow.html), [ClickHouse](https://clickhouse.com/docs/en/integrations/data-formats/arrow-avro-orc), [BigQuery](https://cloud.google.com/bigquery/docs/samples/bigquerystorage-arrow-quickstart)) and file formats ([Parquet](https://arrow.apache.org/docs/python/parquet.html)) which makes it easier to write CloudQuery destination or source plugins for databases that already support Arrow as well as much more efficient as we remove the need for additional serialization and transformation step. Moreover, just the performance of sending Arrow format from source plugin to destination is already more performant and memory efficient, given its “zero-copy” nature and not needing serialization/deserialization.
3. Rich Data Types: Arrow supports more than [35 types](https://arrow.apache.org/docs/python/api/datatypes.html) including composite types (i.e. lists, structs and maps of all the available types) and ability to extend the type system with custom types. Also, there is already built-in mapping from/to the arrow type system and the parquet type system (including nested types) which already supported in many of the arrow libraries as explained [here](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/).

# Summary

Adopting Apache Arrow as the CloudQuery in-memory type system enables us to gain better performance, data interoperability and developer experience. Some plugins that are going to gain an immediate boost of rich type systems are our database-to-database replication plugins such as [PostgreSQL CDC](https://www.cloudquery.io/docs/plugins/sources/postgresql/overview) source plugin (and all [database destinations](https://www.cloudquery.io/docs/plugins/destinations/overview)) that are going to get support for all available types including nested ones.

We are excited about this step and joining the growing Arrow community. We already contributed more than [30](https://github.com/search?q=is%3Apr+author%3Ayevgenypats+author%3Ahermanschaaf+author%3Acandiduslynx+author%3Adisq+label%3A%22Component%3A+Go%22++is%3Amerged+&ref=simplesearch) upstream pull requests that were quickly reviewed by the Arrow maintainers, thank you!
