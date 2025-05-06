---
layout: post
title: "Apache Arrow ADBC 18 (Libraries) Release"
date: "2025-05-06 00:00:00"
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

The Apache Arrow team is pleased to announce the version 18 release of
the Apache Arrow ADBC libraries. This release includes [**28
resolved issues**][1] from [**22 distinct contributors**][2].

This is a release of the **libraries**, which are at version 18.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.6.0
- C#: 0.18.0
- Java: 0.18.0
- R: 0.18.0
- Rust: 0.18.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

Using Meson to build the project has been improved (#2735, #2746).

The C# bindings and its drivers have seen a lot of activity in this release.  A Databricks Spark driver is now available (#2672, #2737, #2743, #2692), with support for features like CloudFetch (#2634, #2678, #2691).  The general Spark driver now has better retry behavior for 503 responses (#2664), supports LZ4 compression applied outside of the Arrow IPC format (#2669), and supports OAuth (#2579), among other improvements.  The "Apache" driver for various Thrift-based systems now supports Apache Hive in addition to Apache Spark and Apache Impala (#2540), among other improvements.  The BigQuery driver adds more authentication and other configuration settings (#2655, #2566, #2541, #2698).

The Flight SQL driver supports OAuth (#2651).

The Java bindings experimentally support a JNI wrapper around drivers exposing the ADBC C API (#2401).  These are not currently distributed via Maven and must be built by hand.

The Go bindings now support union types in the `database/sql` wrapper (#2637).  The Golang-based BigQuery driver returns more metadata about tables (#2697).

The PostgreSQL driver now avoids spurious commit/rollback commands (#2685).  It also handles improper usage more gracefully (#2653).

The Python bindings now make it easier to pass options in various places (#2589, #2700).  Also, the DB-API layer can be minimally used without PyArrow installed, making it easier for users of libraries like polars that don't need or want a second Arrow implementation (#2609).

The Rust bindings now avoid locking the driver on every operation, allowing concurrent usage (#2736).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-17..apache-arrow-adbc-18
    20	David Li
     6	William Ayd
     5	Curt Hagenlocher
     5	davidhcoe
     4	Alex Guo
     4	Felipe Oliveira Carvalho
     4	Jade Wang
     4	Matthijs Brobbel
     4	Sutou Kouhei
     4	eric-wang-1990
     3	Bruce Irschick
     2	Milos Gligoric
     2	Sudhir Reddy Emmadi
     2	Todd Meng
     1	Bryce Mecum
     1	Dewey Dunnington
     1	Filip Wojciechowski
     1	Hiroaki Yutani
     1	Hélder Gregório
     1	Marin Nozhchev
     1	amangoyal
     1	qifanzhang-ms
```

## Roadmap

There is some discussion on a potential second revision of ADBC to include more missing functionality and asynchronous API support.  For more, see the [milestone](https://github.com/apache/arrow-adbc/milestone/8).  We would welcome suggestions on APIs that could be added or extended.  Some of the contributors are planning to begin work on a proposal in the near future.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/22
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-18/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/18/format/specification.html
