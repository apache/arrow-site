---
layout: post
title: "Apache Arrow ADBC 19 (Libraries) Release"
date: "2025-07-09 00:00:00"
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

The Apache Arrow team is pleased to announce the version 19 release of
the Apache Arrow ADBC libraries. This release includes [**60
resolved issues**][1] from [**27 distinct contributors**][2].

This is a release of the **libraries**, which are at version 19.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.7.0
- C#: 0.19.0
- Java: 0.19.0
- R: 0.19.0
- Rust: 0.19.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

- Apache, Databricks: these drivers has received a plethora of improvements,
  optimizations, and bug fixes.
- DataFusion: the arrow crate version requirement is now independent from that
  of the `adbc_core` crate, to make it easier to use older versions of the
  dependency when not using the DataFusion driver
  ([#3017](https://github.com/apache/arrow-adbc/pull/3017)).
- Driver Manager: drivers can now be loaded by searching configuration
  directories (or on Windows, the registry) for 'manifest' files describing
  where the driver is located
  ([#2918](https://github.com/apache/arrow-adbc/pull/2918),
  [#3018](https://github.com/apache/arrow-adbc/pull/3018),
  [#3021](https://github.com/apache/arrow-adbc/pull/3021),
  [#3036](https://github.com/apache/arrow-adbc/pull/3036),
  [#3041](https://github.com/apache/arrow-adbc/pull/3041)).  Add freethreaded
  wheels for the driver manager in Python 3.13.  These are still experimental;
  please [file a bug report](https://github.com/apache/arrow-adbc/issues) with
  any feedback ([#3063](https://github.com/apache/arrow-adbc/pull/3063)).
  Make it easier to use the DB-API layer in Python without depending on
  PyArrow, to make it easier for users of polars and other libraries
  ([#2839](https://github.com/apache/arrow-adbc/pull/2839)).
- Flight SQL (Go): the last release unintentionally renamed the entrypoint
  symbol.  Both the old and 'new' names are now present
  ([#3056](https://github.com/apache/arrow-adbc/pull/3056)).
  Use custom certificates (when present) for OAuth
  ([#2829](https://github.com/apache/arrow-adbc/pull/2829)).
- PostgreSQL: ingest zoned timestamps as `TIMESTAMP WITH TIME ZONE`
  ([#2904](https://github.com/apache/arrow-adbc/pull/2904)) and support
  reading the `int2vector` type
  ([#2919](https://github.com/apache/arrow-adbc/pull/2919)).
- Snowflake: fix issues with COPY concurrency options
  ([#2805](https://github.com/apache/arrow-adbc/pull/2805)), logging spam
  ([#2807](https://github.com/apache/arrow-adbc/pull/2807)), and boolean
  result columns ([#2854](https://github.com/apache/arrow-adbc/pull/2854)).
  Add an option to return timestamps in microseconds to avoid overflow with
  extreme values ([#2917](https://github.com/apache/arrow-adbc/pull/2917)).
- Rust: make a breaking change from `&mut self` to `&mut` in one API to enable
  fearless concurrency
  ([#2788](https://github.com/apache/arrow-adbc/pull/2788)).
- Add experimental support for integrating with
  [OpenTelemetry](https://opentelemetry.io/), starting with the Snowflake
  driver.  ([#2729](https://github.com/apache/arrow-adbc/pull/2729),
  [#2825](https://github.com/apache/arrow-adbc/pull/2825),
  [#2847](https://github.com/apache/arrow-adbc/pull/2847),
  [#2951](https://github.com/apache/arrow-adbc/pull/2951)).
- Improve the build experience when using Meson
  ([#2848](https://github.com/apache/arrow-adbc/pull/2848),
  [#2849](https://github.com/apache/arrow-adbc/pull/2849)).
  Make it easier to statically link drivers
  ([#2738](https://github.com/apache/arrow-adbc/pull/2738)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-18..apache-arrow-adbc-19
    32	David Li
    20	Daijiro Fukuda
    16	Todd Meng
    10	eric-wang-1990
     7	eitsupi
     6	Matt Topol
     6	davidhcoe
     5	Bruce Irschick
     5	Sutou Kouhei
     3	Dewey Dunnington
     3	Jacky Hu
     2	Alex Guo
     2	Bryce Mecum
     2	Jade Wang
     2	James Thompson
     2	William Ayd
     2	qifanzhang-ms
     1	Arseny Tsypushkin
     1	Felipe Oliveira Carvalho
     1	Hiroyuki Sato
     1	Hélder Gregório
     1	Jan-Hendrik Zab
     1	Jarro van Ginkel
     1	Jolan Rensen
     1	Sergei Grebnov
     1	Sudhir Reddy Emmadi
     1	amangoyal
```

## Roadmap

We plan to continue expanding support for features like OpenTelemetry that
have been introduced experimentally.

There is some discussion on a potential second revision of ADBC to include
more missing functionality and asynchronous API support.  For more, see the
[milestone](https://github.com/apache/arrow-adbc/milestone/8).  We would
welcome suggestions on APIs that could be added or extended.  Some of the
contributors are planning to begin work on a proposal in the eventual future.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/23
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-19/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/19/format/specification.html
