---
layout: post
title: Apache Arrow DataFusion 7.0.0 Release
date: "2022-02-28 00:00:00"
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

The Apache Arrow team is pleased to announce the DataFusion 7.0.0 release. This covers 4 months of development work
and includes 195 commits from the following 37 distinct contributors.

<!--
git log --pretty=oneline 5.0.0..6.0.0 datafusion datafusion-cli datafusion-examples | wc -l
     134

git shortlog -sn 5.0.0..6.0.0 datafusion datafusion-cli datafusion-examples | wc -l
      29

      Carlos and xudong963 are same individual
-->

```
    44  Andrew Lamb
    24  Kun Liu
    23  Jiayu Liu
    17  xudong.w
    11  Yijie Shen
     9  Matthew Turner
     7  Liang-Chi Hsieh
     5  Lin Ma
     4  Stephen Carman
     4  James Katz
     4  Dmitry Patsura
     4  QP Hou
     3  dependabot[bot]
     3  Remzi Yang
     3  Yang
     3  ic4y
     3  Daniël Heres
     2  Andy Grove
     2  Raphael Taylor-Davies
     2  Jason Tianyi Wang
     2  Dan Harris
     2  Sergey Melnychuk
     1  Nitish Tiwari
     1  Dom
     1  Eduard Karacharov
     1  Javier Goday
     1  Boaz
     1  Marko Mikulicic
     1  Max Burke
     1  Carol (Nichols || Goulding)
     1  Phillip Cloud
     1  Rich
     1  Toby Hede
     1  Will Jones
     1  r.4ntix
     1  rdettai
```

The following section highlights some of the improvements in this release. Of course, many other bug fixes and improvements have also been made and we refer you to the complete [changelog](https://github.com/apache/arrow-datafusion/blob/7.0.0/datafusion/CHANGELOG.md) for the full detail.

# Summary

- DataFusion Crate
  - The DataFusion crate is being split into multiple crates to decrease compilation times and improve the development experience. Initially, `datafusion-common` (the core DataFusion components) and `datafusion-expr` (DataFusion expressions, functions, and operators) have been split out. There will be additional splits after the 7.0 release.
- Performance Improvements and Optimizations
  - Arrow’s dyn scalar kernels are now used to enable efficient operations on `DictionaryArray`s [#1685](https://github.com/apache/arrow-datafusion/pull/1685)
  - Switch from `std::sync::Mutex` to `parking_lot::Mutex` [#1720](https://github.com/apache/arrow-datafusion/pull/1720)
- New Features
  - Support for memory tracking and spilling to disk
    - MemoryMananger and DiskManager [#1526](https://github.com/apache/arrow-datafusion/pull/1526)
    - Out of core sort [#1526](https://github.com/apache/arrow-datafusion/pull/1526)
    - New metrics
      - `Gauge` and `CurrentMemoryUsage` [#1682](https://github.com/apache/arrow-datafusion/pull/1682)
      - `Spill_count` and `spilled_bytes` [#1641](https://github.com/apache/arrow-datafusion/pull/1641)
  - New math functions
    - `Approx_quantile` [#1529](https://github.com/apache/arrow-datafusion/pull/1539)
    - `stddev` and `variance` (sample and population) [#1525](https://github.com/apache/arrow-datafusion/pull/1525)
    - `corr` [#1561](https://github.com/apache/arrow-datafusion/pull/1561)
  - Support decimal type [#1394](https://github.com/apache/arrow-datafusion/pull/1394)[#1407](https://github.com/apache/arrow-datafusion/pull/1407)[#1408](https://github.com/apache/arrow-datafusion/pull/1408)[#1431](https://github.com/apache/arrow-datafusion/pull/1431)[#1483](https://github.com/apache/arrow-datafusion/pull/1483)[#1554](https://github.com/apache/arrow-datafusion/pull/1554)[#1640](https://github.com/apache/arrow-datafusion/pull/1640)
  - Support for reading Parquet files with evolved schemas [#1622](https://github.com/apache/arrow-datafusion/pull/1622)[#1709](https://github.com/apache/arrow-datafusion/pull/1709)
  - Support for registering `DataFrame` as table [#1699](https://github.com/apache/arrow-datafusion/pull/1699)
  - Support for the `substring` function [#1621](https://github.com/apache/arrow-datafusion/pull/1621)
  - Support `array_agg(distinct ...)` [#1579](https://github.com/apache/arrow-datafusion/pull/1579)
  - Support `sort` on unprojected columns [#1415](https://github.com/apache/arrow-datafusion/pull/1415)
- Additional Integration Points
  - A new public Expression simplification API [#1717](https://github.com/apache/arrow-datafusion/pull/1717)
- [DataFusion-Contrib](https://github.com/datafusion-contrib)
  - A new GitHub organization created as a home for both `DataFusion` extensions and as a testing ground for new features.
    - Extensions
      - [DataFusion-Python](https://github.com/datafusion-contrib/datafusion-python)
      - [DataFusion-Java](https://github.com/datafusion-contrib/datafusion-java)
      - [DataFusion-hdsfs-native](https://github.com/datafusion-contrib/datafusion-hdfs-native)
      - [DataFusion-ObjectStore-s3](https://github.com/datafusion-contrib/datafusion-objectstore-s3)
    - New Features
      - [DataFusion-Streams](https://github.com/datafusion-contrib/datafusion-streams)
- [Arrow2](https://github.com/jorgecarleitao/arrow2)
  - An [Arrow2 Branch](https://github.com/apache/arrow-datafusion/tree/arrow2) has been created.  There are ongoing discussions in [DataFusion](https://github.com/apache/arrow-datafusion/issues/1532) and [arrow-rs](https://github.com/apache/arrow-rs/issues/1176) about migrating `DataFusion` to `Arrow2`

# Documentation and Roadmap

We are working to consolidate the documentation into the [official site](https://arrow.apache.org/datafusion).  You can find more details there on topics such as the [SQL status](https://arrow.apache.org/datafusion/user-guide/sql/index.html)  and a [user guide](https://arrow.apache.org/datafusion/user-guide/introduction.html#introduction). This is also an area we would love to get help from the broader community [#1821](https://github.com/apache/arrow-datafusion/issues/1821).

To provide transparency on DataFusion’s priorities to users and developers a three month roadmap will be published at the beginning of each quarter.  This can be found here [here](https://arrow.apache.org/datafusion/specification/roadmap.html).

# Upcoming Attractions

- Ballista is gaining momentum, and several groups are now evaluating and contributing to the project.
  - Some of the proposed improvements
    - [Improvements Overview](https://github.com/apache/arrow-datafusion/issues/1701)
    - [Extensibility](https://github.com/apache/arrow-datafusion/issues/1675)
    - [File system access](https://github.com/apache/arrow-datafusion/issues/1702)
    - [Cluster state](https://github.com/apache/arrow-datafusion/issues/1704)
- Continued improvements for working with limited resources and large datasets
  - Memory limited joins[#1599](https://github.com/apache/arrow-datafusion/issues/1599)
  - Sort-merge join[#141](https://github.com/apache/arrow-datafusion/issues/141)[#1776](https://github.com/apache/arrow-datafusion/pull/1776)
  - Introduce row based bytes representation [#1708](https://github.com/apache/arrow-datafusion/pull/1708)

# How to Get Involved

If you are interested in contributing to DataFusion, and learning about state of
the art query processing, we would love to have you join us on the journey! You
can help by trying out DataFusion on some of your own data and projects and let us know how it goes or contribute a PR with documentation, tests or code. A list of open issues suitable for beginners is [here](https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

Check out our new [Communication Doc](https://arrow.apache.org/datafusion/community/communication.html) on more
ways to engage with the community.
