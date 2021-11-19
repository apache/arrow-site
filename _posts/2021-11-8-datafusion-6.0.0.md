---
layout: post
title: Apache Arrow DataFusion 6.0.0 Release
date: "2021-11-19 00:00:00"
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

[DataFusion](https://arrow.apache.org/datafusion/) is an embedded
query engine which leverages the unique features of
[Rust](https://www.rust-lang.org/) and [Apache
Arrow](https://arrow.apache.org/) to provide a system that is high
performance, easy to connect, easy to embed, and high quality.

The Apache Arrow team is pleased to announce the DataFusion 6.0.0 release. This covers 4 months of development work
and includes 134 commits from the following 28 distinct contributors.

<!--
git log --pretty=oneline 5.0.0..6.0.0 datafusion datafusion-cli datafusion-examples | wc -l
     134

git shortlog -sn 5.0.0..6.0.0 datafusion datafusion-cli datafusion-examples | wc -l
      29

      Carlos and xudong963 are same individual
-->

```
    28  Andrew Lamb
    26  Jiayu Liu
    13  xudong963
     9  rdettai
     9  QP Hou
     6  Matthew Turner
     5  Daniël Heres
     4  Guillaume Balaine
     3  Francis Du
     3  Marco Neumann
     3  Jon Mease
     3  Nga Tran
     2  Yijie Shen
     2  Ruihang Xia
     2  Liang-Chi Hsieh
     2  baishen
     2  Andy Grove
     2  Jason Tianyi Wang
     1  Nan Zhu
     1  Antoine Wendlinger
     1  Krisztián Szűcs
     1  Mike Seddon
     1  Conner Murphy
     1  Patrick More
     1  Taehoon Moon
     1  Tiphaine Ruy
     1  adsharma
     1  lichuan6
```

The release notes below are not exhaustive and only expose selected highlights of the release. Many other bug fixes
and improvements have been made: we refer you to the complete
[changelog](https://github.com/apache/arrow-datafusion/blob/6.0.0/datafusion/CHANGELOG.md).

# New Website

Befitting a growing project, DataFusion now has its
[own website](https://arrow.apache.org/datafusion/) hosted as part of the
main [Apache Arrow Website](https://arrow.apache.org)

# Roadmap

The community worked to gather their thoughts about where we are
taking DataFusion into a public
[Roadmap](https://arrow.apache.org/datafusion/specification/roadmap.html)
for the first time

# New Features

- Runtime operator metrics collection framework
- Object store abstraction for unified access to local or remote storage
- Hive style table partitioning support, for Parquet, CSV, Avro and Json files
- DataFrame API support for: `except`, `intersect`, `show`, `limit` and window functions
- SQL
  - `EXPLAIN ANALYZE` with runtime metrics
  - `trim ( [ LEADING | TRAILING | BOTH ] [ FROM ] string text [, characters text ] )` syntax
  - Postgres style regular expression matching operators `~`, `~*`, `!~`, and `!~*`
  - SQL set operators `UNION`, `INTERSECT`, and `EXCEPT`
  - `cume_dist`, `percent_rank` window functions
  - `digest`, `blake2s`, `blake2b`, `blake3` crypto functions
  - HyperLogLog based `approx_distinct`
  - `is distinct from` and `is not distinct from`
  - `CREATE TABLE AS SELECT`
  - Accessing elements of nested `Struct` and `List` columns (e.g. `SELECT struct_column['field_name'], array_column[0] FROM ...`)
  - Boolean expressions in `CASE` statement
  - `DROP TABLE`
  - `VALUES` List
  - Postgres regex match operators
- Support for Avro format
- Support for `ScalarValue::Struct`
- Automatic schema inference for CSV files
- Better interactive editing support in `datafusion-cli` as well as `psql` style commands such as `\d`, `\?`, and `\q`
- Generic constant evaluation and simplification framework
- Added common subexpression eliminate query plan optimization rule
- Python binding 0.4.0 with all Datafusion 6.0.0 features

With these new features, we are also now passing TPC-H queries 8, 13 and 21.

For the full list of new features with their relevant PRs, see the
[enhancements section](https://github.com/apache/arrow-datafusion/blob/6.0.0/datafusion/CHANGELOG.md)
in the changelog.

# `async` planning and decoupling file format from table layout

Driven by the need to support Hive style table partitioning, @rdettai
introduced the following design change to the Datafusion core.

- The code for reading specific file formats (`Parquet`, `Avro`, `CSV`, and
`JSON`) was separated from the logic that handles grouping sets of
files into execution partitions.
- The query planning process was made `async`.

As a result, we are able to replace the old `Parquet`, `CSV` and `JSON` table
providers with a single `ListingTable` table provider.

This also sets up DataFusion and its plug-in ecosystem to
supporting a wide range of catalogs and various object store implementations.
You can read more about this change in the
[design document](https://docs.google.com/document/d/1Bd4-PLLH-pHj0BquMDsJ6cVr_awnxTuvwNJuWsTHxAQ)
and on the [arrow-datafusion#1010 PR](https://github.com/apache/arrow-datafusion/pull/1010).

# How to Get Involved

If you are interested in contributing to DataFusion, we would love to have you! You
can help by trying out DataFusion on some of your own data and projects and filing bug reports and helping to
improve the documentation, or contribute to the documentation, tests or code. A list of open issues suitable for
beginners is [here](https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
and the full list is [here](https://github.com/apache/arrow-datafusion/issues).

Check out our new [Communication Doc](https://arrow.apache.org/datafusion/community/communication.html) on more
ways to engage with the community.
