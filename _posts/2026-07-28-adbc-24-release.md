---
layout: post
title: "Apache Arrow ADBC 24 (Libraries) Release"
date: "2026-07-28 00:00:00"
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

The Apache Arrow team is pleased to announce the version 24 release of
the Apache Arrow ADBC libraries. This release includes [**57
resolved issues**][1] from [**28 distinct contributors**][2].

This is a release of the **libraries**, which are at version 24.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.12.0
- C#: 0.24.0
- Java: 0.24.0
- R: 0.24.0
- Rust: 0.24.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

Note: we are planning to require C++20 starting from the next release.

### Breaking/Major Changes

- The documentation has been overhauled, in particular to make it clearer how
  to use ADBC and where to download drivers.
- We have stopped development on drivers for Apache DataFusion, BigQuery,
  Databricks, and Snowflake. Existing packages will continue to be available,
  but the code has been removed and we may archive pages on PyPI and other
  package indices. All four of these systems now have ADBC drivers developed
  by the vendors themselves or other third parties; see
  [Drivers](https://arrow.apache.org/adbc/24/driver/index.html) in the
  documentation for details.
- Similarly, support for Amazon Redshift in the PostgreSQL driver has been
  removed. This support was always experimental and incomplete, and a
  dedicated driver has been available from a third party.
- Java API definitions were narrowed so that `close` is only declared to throw
  `AdbcException` as a checked
  exception. ([#4451](https://github.com/apache/arrow-adbc/pull/4451))
- The PostgreSQL driver now lazily initializes transactions to make it work
  better with connection
  pools. ([#4424](https://github.com/apache/arrow-adbc/pull/4424))

### Core APIs & Client Libraries

C# now has a native driver manager, allowing it to load drivers, manifests,
and profiles ([#4075](https://github.com/apache/arrow-adbc/pull/4075),
[#4340](https://github.com/apache/arrow-adbc/pull/4340),
[#4341](https://github.com/apache/arrow-adbc/pull/4341),
[#4330](https://github.com/apache/arrow-adbc/pull/4330)). The core libraries
are now compatible with AOT compilation, enabling drivers to be built as
standalone shared libaries
([#4243](https://github.com/apache/arrow-adbc/pull/4243),
[#4318](https://github.com/apache/arrow-adbc/pull/4318)).

The Go `database/sql` adapter now supports converting more Arrow types to Go
types ([#4416](https://github.com/apache/arrow-adbc/pull/4416)).

The Java core APIs now support a "fluent" style ingest API (#4466). Also,
support for dynamically loading drivers for use in Java has been greatly
expanded and should now support all of the ADBC APIs and features expected of
a client library ([#4452](https://github.com/apache/arrow-adbc/pull/4452),
[#4211](https://github.com/apache/arrow-adbc/pull/4211),
[#4411](https://github.com/apache/arrow-adbc/pull/4411),
[#4202](https://github.com/apache/arrow-adbc/pull/4202),
[#4359](https://github.com/apache/arrow-adbc/pull/4359),
[#4212](https://github.com/apache/arrow-adbc/pull/4212),
[#4263](https://github.com/apache/arrow-adbc/pull/4263),
[#4229](https://github.com/apache/arrow-adbc/pull/4229),
[#4203](https://github.com/apache/arrow-adbc/pull/4203),
[#4361](https://github.com/apache/arrow-adbc/pull/4361),
[#4362](https://github.com/apache/arrow-adbc/pull/4362),
[#4249](https://github.com/apache/arrow-adbc/pull/4249),
[#4250](https://github.com/apache/arrow-adbc/pull/4250),
[#4398](https://github.com/apache/arrow-adbc/pull/4398),
[#4397](https://github.com/apache/arrow-adbc/pull/4397),
[#4423](https://github.com/apache/arrow-adbc/pull/4423),
[#4395](https://github.com/apache/arrow-adbc/pull/4395),
[#4396](https://github.com/apache/arrow-adbc/pull/4396),
[#4391](https://github.com/apache/arrow-adbc/pull/4391)).

The JavaScript client library no longer requires the `driver` parameter and
can infer the driver to load based on the URI, or can accept a profile
([#4357](https://github.com/apache/arrow-adbc/pull/4357)).

The R client library no longer requires the `driver` parameter and can infer
the driver to load based on the URI, or can accept a profile
([#4535](https://github.com/apache/arrow-adbc/pull/4535)).

Some tweaks have been made to the Rust core APIs to better support interop
with dynamically loaded drivers and make certain conventions clearer
([#4427](https://github.com/apache/arrow-adbc/pull/4427),
[#4510](https://github.com/apache/arrow-adbc/pull/4510),
[#4350](https://github.com/apache/arrow-adbc/pull/4350),
[#4141](https://github.com/apache/arrow-adbc/pull/4141),
[#4181](https://github.com/apache/arrow-adbc/pull/4181),
[#4473](https://github.com/apache/arrow-adbc/pull/4473),
[#4469](https://github.com/apache/arrow-adbc/pull/4469)).

### Drivers

The Flight SQL driver now recognizes URIs with the `flightsql://` scheme
([#4488](https://github.com/apache/arrow-adbc/pull/4488)). It also has more
support for logging and OpenTelemetry tracing
([#4322](https://github.com/apache/arrow-adbc/pull/4322),
[#4486](https://github.com/apache/arrow-adbc/pull/4486)).

The PostgreSQL driver now uses libpq version 18.4 (up from 16.9)
([#4566](https://github.com/apache/arrow-adbc/pull/4566)). Several bugs have
been fixed around handling of the NUMERIC type, and it has been optimized on
platforms where int128 is available (generally, platforms other than Windows)
([#4536](https://github.com/apache/arrow-adbc/pull/4536),
[#4499](https://github.com/apache/arrow-adbc/pull/4499),
[#4523](https://github.com/apache/arrow-adbc/pull/4523),
[#4498](https://github.com/apache/arrow-adbc/pull/4498)). GetObjects now
populates the `xdbc_type_name` field
([#4457](https://github.com/apache/arrow-adbc/pull/4457)). JSON columns are
now returned with the `arrow.json` extension type
([#4415](https://github.com/apache/arrow-adbc/pull/4415)), and ingesting into
JSONB columns is now supported
([#4505](https://github.com/apache/arrow-adbc/pull/4505)).

The SQLite driver now uses SQLite version 3.53.1 (up from 3.51.2)
([#4566](https://github.com/apache/arrow-adbc/pull/4566)). It now recognizes
URIs with the `sqlite://` scheme
([#4463](https://github.com/apache/arrow-adbc/pull/4463)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-23..apache-arrow-adbc-24
    58	David Li
    16	Bryce Mecum
    11	Fredrik Fornwall
     7	Curt Hagenlocher
     7	eitsupi
     6	Mandukhai Alimaa
     5	davidhcoe
     4	Matt Topol
     4	takuya kodama
     3	Ian Cook
     3	복준수
     2	Artur Rakhmatulin
     2	Austin Bonander
     2	Bruce Irschick
     2	Daniel_McBride
     2	Emil Sadek
     1	Arnold Wakim
     1	Aurélien Pupier
     1	Dan Liu
     1	Felipe Oliveira Carvalho
     1	Kent Wu
     1	Neal Richardson
     1	Nir Portal
     1	Pavel Agafonov
     1	Rishav Rungta
     1	Shubham Pandey
     1	mete
     1	xinyu.lin
```

## Roadmap

We are working on the next revision of the API standard, focusing on missing
features (primarily metadata/catalog data). We welcome anyone interested in
contributing. Current progress can be found in the [1.2.0 specification
milestone](https://github.com/apache/arrow-adbc/milestone/9).

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/28
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-24/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/24/format/specification.html
