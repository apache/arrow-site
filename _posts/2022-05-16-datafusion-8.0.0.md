---
layout: post
title: Apache Arrow DataFusion 8.0.0 Release
date: "2022-05-16 00:00:00"
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

[DataFusion](https://arrow.apache.org/datafusion/) is an extensible query execution framework, written in Rust, that 
uses Apache Arrow as its in-memory format.

When you want to extend your Rust project with [SQL support](https://arrow.apache.org/datafusion/user-guide/sql/sql_status.html), 
a DataFrame API, or the ability to read and process Parquet, JSON, Avro or CSV data, DataFusion is definitely worth 
checking out.

DataFusion's  SQL, `DataFrame`, and manual `PlanBuilder` API let users access a sophisticated query optimizer and 
execution engine capable of fast, resource efficient, and parallel execution that takes optimal advantage of 
today's multicore hardware. Being written in Rust means DataFusion can offer *both* the safety of dynamic languages and 
the resource efficiency of a compiled language.

The Apache Arrow team is pleased to announce the DataFusion 8.0.0 release (and also the release of version 0.7.0 of 
the Ballista subproject). This covers 3 months of development work and includes 279 commits from the following 49 
distinct contributors.

<!--
$ git log --pretty=oneline 7.0.0..8.0.0 datafusion datafusion-cli datafusion-examples ballista ballista-cli ballista-examples | wc -l
279

$ git shortlog -sn 7.0.0..8.0.0 datafusion datafusion-cli datafusion-examples ballista ballista-cli ballista-examples | wc -l
49

(feynman han, feynman.h, Feynman Han were assumed to be the same person)
-->

```
    39  Andy Grove
    33  Andrew Lamb
    21  DuRipeng
    20  Yijie Shen
    19  Yang Jiang
    17  Raphael Taylor-Davies
    11  Dan Harris
    11  Matthew Turner
    11  yahoNanJing
     9  dependabot[bot]
     8  jakevin
     6  Kun Liu
     5  Jiayu Liu
     4  Daniël Heres
     4  mingmwang
     4  xudong.w
     3  Carol (Nichols || Goulding)
     3  Dmitry Patsura
     3  Eduard Karacharov
     3  Jeremy Dyer
     3  Kaushik
     3  Rich
     3  comphead
     3  gaojun2048
     3  Feynman Han
     2  Jie Han
     2  Jon Mease
     2  Tim Van Wassenhove
     2  Yt
     2  Zhang Li
     2  silence-coding
     1  Alexander Spies
     1  George Andronchik
     1  Guillaume Balaine
     1  Hao Xin
     1  Jiacai Liu
     1  Jörn Horstmann
     1  Liang-Chi Hsieh
     1  Max Burke
     1  NaincyKumariKnoldus
     1  Nga Tran
     1  Patrick More
     1  Pierre Zemb
     1  Remzi Yang
     1  Sergey Melnychuk
     1  Stephen Carman
     1  doki
```

The following section highlights some of the improvements in this release. Of course, many other bug fixes and 
improvements have also been made and we refer you to the complete 
[changelog](https://github.com/apache/arrow-datafusion/blob/8.0.0/datafusion/CHANGELOG.md) for full details.

# Summary

## DDL Support

DDL support has been expanded to include the following commands for creating databases, schemas, and views. This 
allows DataFusion to be used more effectively from the CLI.

- `CREATE DATABASE`
- `CREATE VIEW`
- `CREATE SCHEMA`
- `CREATE EXTERNAL TABLE` now supports JSON files, `IF NOT EXISTS`, and partition columns

## SQL Query Planner

The SQL query planner now supports a number of new SQL features, including support for `IN`, `EXISTS`, and scalar 
subquery expressions, and support for advanced aggregates with CUBE and ROLLUP grouping sets. There are also many 
bug fixes around normalizing identifiers consistently. Note that the physical plan does not yet support all of the 
new features but these changes make DataFusion more compelling for projects looking for a SQL parser and query 
planner to translate to their own execution engines.

## Query Execution & Internals

Here are some of the improvements and new features in the query execution engine:

- The ExecutionContext has been renamed to SessionContext and now supports multi-tenancy
- The ExecutionPlan trait is no longer async
- There is a work-in-progress new Morsel-Driven Scheduler based on the ["Morsel-Driven Parallelism: A NUMA-Aware Query
  Evaluation Framework for the Many-Core Age"](https://15721.courses.cs.cmu.edu/spring2016/papers/p743-leis.pdf) whitepaper
- There is a new sort-merge join operator
- There is a new JIT code generation crate. This is not yet integrated into the physical plans
- There is a new serialization API for serializing plans to bytes (based on protobuf)

## Improved file support

DataFusion now supports JSON, both for reading and writing. There are also new DataFrame methods for writing query 
results to files in CSV, Parquet, and JSON format.

## Ballista

Ballista continues to mature and now supports a wider range of operators and expressions. There are also improvements 
to the scheduler to support UDFs, and there are some robustness improvements, such as cleaning up work directories 
and persisting session configs to allow schedulers to restart and continue processing in-flight jobs.

## Upcoming Work

Here are some of the initiatives that the community plans on working on prior to the next release.

- There is a proposal (LINK) to move Ballista to its own top-level arrow-ballista repository to decouple DataFusion 
and Ballista releases and to allow each project to have documentation better targeted at its particular audience.
- We plan on increasing the frequency of DataFusion releases, with monthly releases now instead of quarterly. This 
  is driven by requests from the increasing number of projects that now depend on DataFusion.
- There is ongoing work to implement new optimizer rules to rewrite queries containing subquery expressions as 
  joins, to support a wider range of queries.
- The new scheduler based on morsel-driven execution will continue to evolve in this next release, with work to 
 refine IO abstractions to improve performance and integration with the new scheduler.

# How to Get Involved

If you are interested in contributing to DataFusion, and learning about state-of-the-art query processing, we would 
love to have you join us on the journey! You can help by trying out DataFusion on some of your own data and projects 
and let us know how it goes or contribute a PR with documentation, tests or code. A list of open issues suitable 
for beginners is [here](https://github.com/apache/arrow-datafusion/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

Check out our new [Communication Doc](https://arrow.apache.org/datafusion/community/communication.html) on more
ways to engage with the community.
