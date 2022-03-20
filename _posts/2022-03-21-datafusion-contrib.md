---
layout: post
title: Introducing Apache Arrow DataFusion Contrib
date: "2022-03-21 00:00:00"
author: pmc
categories: [release]
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

# Introduction

Apache Arrow [DataFusion](https://arrow.apache.org/datafusion/) is an extensible query execution framework, written in Rust, that uses [Apache Arrow](https://arrow.apache.org) as its in-memory format.

When you want to extend your Rust project with [SQL support](https://arrow.apache.org/datafusion/user-guide/sql/sql_status.html), a DataFrame API, or the ability to read and process Parquet, JSON, Avro or CSV data, DataFusion is definitely worth checking out. DataFusion's pluggable design makes creating extensions at various points particular easy to build.

DataFusion's  SQL, `DataFrame`, and manual `PlanBuilder` API let users access a sophisticated query optimizer and execution engine capable of fast, resource efficient, and parallel execution that takes optimal advantage of todays multicore hardware. Being written in Rust means DataFusion can offer *both* the safety of dynamic languages as well as the resource efficiency of a compiled language.

The DataFusion team is pleased to announce the creation of the [DataFusion-Contrib](https://github.com/datafusion-contrib) GitHub organization to support and accelerate other projects.  While the core DataFusion library remains under Apache governance, the contrib organization provides a more flexible testing ground for new DataFusion features and a home for DataFusion extensions.  With this announcement, we are pleased to introduce the following inaugural DataFusion-Contrib repositories.

## DataFusion-Python

This [project](https://github.com/datafusion-contrib/datafusion-python) provides Python bindings to the core Rust implementation of DataFusion, which allows users to:

- Work with familiar SQL or DataFrame APIs to run queries in a safe, multi-threaded environment, returning results in Python
- Create User Defined Functions and User Defined Aggregate Functions for complex operations
- Pay no overhead to copy between Python and underlying Rust execution engine (by way of Apache Arrow arrays)

### Upcoming enhancements

The team is focusing on exposing more features from the underlying Rust implementation of DataFusion and improving documentation.

### How to install

From `pip`

```bash
pip install datafusion
```

Or

```bash
python -m pip install datafusion
```

## DataFusion-ObjectStore-S3

This [crate](https://github.com/datafusion-contrib/datafusion-objectstore-s3) provides an `ObjectStore` implementation for querying data stored in S3 or S3 compatible storage. This makes it almost as easy to query data that lives on S3 as lives in local files

- Ability to create `S3FileSystem` to register as part of DataFusion `ExecutionContext`
- Register files or directories stored on S3 with `ctx.register_listing_table`

### Upcoming enhancements

The current priority is adding python bindings for `S3FileSystem`.  After that there will be async improvements as DataFusion adopts more of that functionality and we are looking into S3 Select functionality.

### How to Install

Add the below to your `Cargo.toml` in your Rust Project with DataFusion.

```toml
datafusion-objectstore-s3 = "0.1.0"
```

## DataFusion-Substrait

[Substrait](https://substrait.io/) is an emerging standard that provides a cross-language serialization format for relational algebra (e.g. expressions and query plans).

This [crate](https://github.com/datafusion-contrib/datafusion-substrait) provides a Substrait producer and consumer for DataFusion.  A producer converts a DataFusion logical plan into a Substrait protobuf and a consumer does the reverse.

Examples of how to use this crate can be found [here](https://github.com/datafusion-contrib/datafusion-substrait/blob/main/src/lib.rs).

### Potential Use Cases

- Replace custom DataFusion protobuf serialization.
- Make it easier to pass query plans over FFI boundaries, such as from Python to Rust
- Allow Apache Calcite query plans to be executed in DataFusion

## DataFusion-BigTable

This [crate](https://github.com/datafusion-contrib/datafusion-bigtable) implements [Bigtable](https://cloud.google.com/bigtable) as a data source and physical executor for DataFusion queries.  It currently supports both UTF-8 string and 64-bit big-endian signed integers in Bigtable.  From a SQL perspective it supports both simple and composite row keys with `=`, `IN`, and `BETWEEN` operators as well as projection pushdown.  The physical execution for queries is handled by this crate while any subsequent aggregation, group bys, or joins are handled in DataFusion.

### Upcoming Enhancements

- Predicate pushdown
  - Value range
  - Value Regex
  - Timestamp range
- Multithreaded
- Partition aware execution
- Production ready

### How to Install

Add the below to your `Cargo.toml` in your Rust Project with DataFusion.

```toml
datafusion-bigtable = "0.1.0"
```

## DataFusion-HDFS

This [crate](https://github.com/datafusion-contrib/datafusion-objectstore-hdfs) introduces `HadoopFileSystem` as a remote `ObjectStore` which provides the ability to query HDFS files.  For HDFS access the [fs-hdfs](https://github.com/yahoNanJing/fs-hdfs) library is used.

## DataFusion-Tokomak

This [crate](https://github.com/datafusion-contrib/datafusion-tokomak) provides an e-graph based DataFusion optimization framework based on the Rust [egg](https://egraphs-good.github.io) library.  An e-graph is a data structure that powers the equality saturation optimization technique.

As context, the optimizer framework within DataFusion is currently [under review](https://github.com/apache/arrow-datafusion/issues/1972) with the objective of implementing a more strategic long term solution that is more efficient and simpler to develop.

Some of the benefits of using `egg` within DataFusion are:

- Implements optimized algorithms that are hard to match with manually written optimization passes
- Makes it easy and less verbose to add optimization rules
- Plugin framework to add more complex optimizations
- Egg does not depend on rule order and can lead to a higher level of optimization by being able to apply multiple rules at the same time until it converges
- Allows for cost-based optimizations

This is an exciting new area for DataFusion with lots of opportunity for community involvement!

## DataFusion-Tui

[DataFusion-tui](https://github.com/datafusion-contrib/datafusion-tui) aka `dft` provides a feature rich terminal application for using DataFusion.  It has drawn inspiration and several features from `datafusion-cli`.  In contrast to `datafusion-cli` the objective of this tool is to provide a light SQL IDE experience for querying data with DataFusion.  This includes features such as the following which are currently implemented:

- Tab Management to provide clean and structured organization of DataFusion queries, results, `ExecutionContext` information, and logs
  - SQL Editor
    - Text editor for writing SQL queries
  - Query History
    - History of executed queries, their execution time, and the number of returned rows
  - `ExecutionContext` information
    - Expose information on which physical optimizers are used and which `ExecutionConfig` settings are set
  - Logs
    - Logs from `dft`, DataFusion, and any dependent libraries
- Support for custom `ObjectStore`s
  - S3
- Preload DDL from `~/.datafusionrc` to enable having local "database" available at startup

### Upcoming Enhancements

- SQL Editor
  - Command to write query results to file
  - Multiple SQL editor tabs
- Expose more information from `ExecutionContext`
- A help tab that provides information on functions
- Query custom `TableProvider`s such as [DeltaTable](https://github.com/delta-io/delta-rs) or [BigTable](https://github.com/datafusion-contrib/datafusion-bigtable)

## DataFusion-Streams

[DataFusion-Stream](https://github.com/datafusion-contrib/datafusion-streams) is a new testing ground for creating a `StreamProvider` in DataFusion that will enable querying streaming data sources such as Apache Kafka.  The implementation for this feature is currently being designed and is under active review.  Once the design is finalized the trait and attendant data structures will be added back to the core DataFusion crate.

## DataFusion-Java

This [project](https://github.com/datafusion-contrib/datafusion-java) created an initial set of Java bindings to DataFusion.  The project is currently in maintenance mode and is looking for maintainers to drive future development.

# How to Get Involved

If you are interested in contributing to DataFusion, and learning about state of
the art query processing, we would love to have you join us on the journey! You
can help by trying out DataFusion on some of your own data and projects and let us know how it goes or contribute a PR with documentation, tests or code. A list of open issues suitable for beginners is [here](https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

The best way to find out about creating new extensions within DataFusion-Contrib is reaching out on the `#arrow-rust` channel of the Apache Software Foundation [Slack](https://join.slack.com/t/the-asf/shared_invite/zt-vlfbf7ch-HkbNHiU_uDlcH_RvaHv9gQ) workspace.

You can also check out our new [Communication Doc](https://arrow.apache.org/datafusion/community/communication.html) on more ways to engage with the community.

Links for each DataFusion-Contrib repository are provided above if you would like to contribute to those.
