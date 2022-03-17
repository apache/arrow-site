---
layout: post
title: Introducing Apache Arrow DataFusion Contrib
date: "2022-03-16 00:00:00"
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

[DataFusion](https://arrow.apache.org/datafusion/) is an extensible query execution framework, written in Rust, that uses Apache Arrow as its in-memory format.

When you want to extend your Rust project with [SQL support](https://arrow.apache.org/datafusion/user-guide/sql/sql_status.html), a DataFrame API, or the ability to read and process Parquet, JSON, Avro or CSV data, DataFusion is definitely worth checking out.

DataFusion's  SQL, `DataFrame`, and manual `PlanBuilder` API let users access a sophisticated query optimizer and execution engine capable of fast, resource efficient, and parallel execution that takes optimal advantage of todays multicore hardware. Being written in Rust means DataFusion can offer *both* the safety of dynamic languages as well as the resource efficiency of a compiled language.

The Apache Arrow DataFusion team is pleased to announce the creation of the [DataFusion-Contrib](https://github.com/datafusion-contrib) GitHub organization.  This organization was created to provide an unofficial testing ground for new DataFusion features and as home for extensions to the core DataFusion project.  There are currently five active repositories within this organization which are summarized below.

## DataFusion-Python

This [project](https://github.com/datafusion-contrib/datafusion-python) provides Python bindings to the core Rust implementation of DataFusion.  It already provides many core methods for working with DataFusion such as:

- Work with a SQL or DataFrame API for creating query plans, executing them in a multi-threaded environment, and returning results in Python
- Creation of User Defined Functions and User Defined Aggregate Functions for complex operations
- Provides zero copy between Python and underlying Rust based execution engine

### Upcoming enhancements

Going forward there will be a focus on exposing more features from the underlying Rust implementation of DataFusion and improving documentation.

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

This [crate](https://github.com/datafusion-contrib/datafusion-objectstore-s3) provides an `ObjectStore` implementation for querying data stored in S3 or S3 compatible storage.

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

Substrait provides a cross-language serialization format for relational algebra, based on protocol buffers.

This [crate](https://github.com/datafusion-contrib/datafusion-substrait) provides a Substrait producer and consumer for DataFusion.  A producer converts a DataFusion logical plan into a Substrait protobuf and a consumer does the reverse.

Examples of how to use this crate can be found [here](https://github.com/datafusion-contrib/datafusion-substrait/blob/main/src/lib.rs).

### Potential Use Cases

- Replace current DataFusion protobuf definition used in Ballista for passing query plan fragments to executors.
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

As context, the optimizer framework within DataFusion is currently under review with the objective of implementing a more strategic long term solution that is more efficient and simpler to develop.

Some of the benefits of using `egg` within DataFusion are:

- An optimized algorithm that is hard to match with manually written optimization passes
- Easier and less verbose to add simple rules
- Plugin framework to add slightly more complex optimizations
- Does not depend on rule order and combined with being able to apply multiple rules in one pass and until convergence, can optimize further than currently is possible (or what would be possible using a optimization strategy like Apache Spark)
- Cost based optimizations are easy to add

This is an exciting new area for DataFusion with lots of opportunity for community involvement!

## DataFusion-Java

This [project](https://github.com/datafusion-contrib/datafusion-java) created an initial set of Java bindings to DataFusion.  The project is currently in maintenance mode and is looking for maintainers to drive future development.

# How to Get Involved

If you are interested in contributing to DataFusion, and learning about state of
the art query processing, we would love to have you join us on the journey! You
can help by trying out DataFusion on some of your own data and projects and let us know how it goes or contribute a PR with documentation, tests or code. A list of open issues suitable for beginners is [here](https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

Check out our new [Communication Doc](https://arrow.apache.org/datafusion/community/communication.html) on more
ways to engage with the community.

Links for each DataFusion-Contrib repository are provided above if you would like to contribute to those.
