---
layout: post
title: "Apache Arrow ADBC 25 (Libraries) Release"
date: "2026-10-26 00:00:00"
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

The Apache Arrow team is pleased to announce the version 25 release of
the Apache Arrow ADBC libraries. This release includes [**56
resolved issues**][1] and [**142 merged pull requests**][2] from
[**25 distinct contributors**](#contributors).

This is a release of the **libraries**, which are at version 25.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.13.0
- C#: 1.0.0 (core), 0.25.0 (drivers)
- Java: 0.25.0
- JavaScript: 0.25.0
- R: 0.25.0
- Rust: 0.25.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

We now have a [logo](https://arrow.apache.org/adbc/current/visual_identity.html) for ADBC ([#4870](https://github.com/apache/arrow-adbc/pull/4870)).

We now provide some support for Windows-on-ARM, including Node.js packages, Python wheels, and Java JNI JARs.

The C++ libraries now require C++20 ([#4610](https://github.com/apache/arrow-adbc/pull/4610)).

The C# core libraries are now version 1.0 and support ADBC 1.1 APIs ([#4923](https://github.com/apache/arrow-adbc/pull/4923) and many more). The ADO.NET client now supports canonical extension types like UUID and Variant ([#4919](https://github.com/apache/arrow-adbc/pull/4919)).

The Go libraries have been split: the core libraries and the drivers are now separate Go modules. This was done to stop driver-specific dependencies (and their associated CVEs) from leaking into _all_ Go projects using ADBC, but is a breaking change for those who were directly depending on Go drivers from a Go project ([#4754](https://github.com/apache/arrow-adbc/pull/4754)).

We now distribute Python wheels for Python 3.15 ([#4879](https://github.com/apache/arrow-adbc/pull/4879)). Python 3.10 went EOL before release, so it was dropped ([#4859](https://github.com/apache/arrow-adbc/pull/4859)).

The Rust libraries made several changes focused on reducing unsafe/undefined behavior, but note that certain low-level (but public) APIs had breaking changes as a result, and that exported drivers now require `Send` ([#4876](https://github.com/apache/arrow-adbc/pull/4876), [#4875](https://github.com/apache/arrow-adbc/pull/4875), [#4874](https://github.com/apache/arrow-adbc/pull/4874), [#4873](https://github.com/apache/arrow-adbc/pull/4873), [#4872](https://github.com/apache/arrow-adbc/pull/4872), [#4871](https://github.com/apache/arrow-adbc/pull/4871)). Also, the existing `cancel` API has been deprecated as it was never usable in a safe manner; instead a new approach based on a cancellation handle has been added ([#3905](https://github.com/apache/arrow-adbc/pull/3905)).

The Flight SQL driver now supports the new `is_update` field if reported by the server ([#4161](https://github.com/apache/arrow-adbc/pull/4161)).

Several fixes were made to the PostgreSQL driver; temporary tables are now shown in GetObjects, and ingesting TIME types is now supported ([#4850](https://github.com/apache/arrow-adbc/pull/4850), [#4848](https://github.com/apache/arrow-adbc/pull/4848), [#4824](https://github.com/apache/arrow-adbc/pull/4824), [#4819](https://github.com/apache/arrow-adbc/pull/4819), [#4798](https://github.com/apache/arrow-adbc/issues/4797), [#4710](https://github.com/apache/arrow-adbc/pull/4710)). `POSTGRESQL:type` field metadata is now included in result set schema fields to help disambiguate the exact data type for consumers ([#4687](https://github.com/apache/arrow-adbc/pull/4687)). The UUID canonical extension type is now supported for queries and bulk ingest ([#4612](https://github.com/apache/arrow-adbc/pull/4612)). Additionally performance of decimal ingestion was significantly improved on Windows ([#4847](https://github.com/apache/arrow-adbc/pull/4847)). (This was previously optimized for other platforms, but Windows did not benefit as the platform compiler/toolchain did not support int128.) We now test the driver against various PostgreSQL-compatible vendors: AlloyDB Omni, CedarDB, Citus, CockroachDB, CrateDB, Materialize, ParadeDB, TimescaleDB, and YugabyteDB ([#4696](https://github.com/apache/arrow-adbc/pull/4696)). We now support using a fixed lookup table for mapping PostgreSQL OIDs to their appropriate parsers; what this means is compatibility with certain vendors that don't implement certain system tables (some of the aforementioned vendors require this new option to be enabled), and improved startup performance for databases that have a large number of tables defined, but at the cost of not being able to read/write user-defined types. We plan to continue improving this feature to eliminate the downsides ([#4775](https://github.com/apache/arrow-adbc/pull/4775)).

Several fixes were made to the SQLite driver to bring it more on par with other drivers ([#4845](https://github.com/apache/arrow-adbc/pull/4845), [#4843](https://github.com/apache/arrow-adbc/pull/4843), [#4842](https://github.com/apache/arrow-adbc/pull/4842), [#4841](https://github.com/apache/arrow-adbc/pull/4841), [#4826](https://github.com/apache/arrow-adbc/pull/4826), ).

<a id="contributors"></a>
## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-24..apache-arrow-adbc-25
    76	David Li
    16	Curt Hagenlocher
     8	Bruce Irschick
     7	Bryce Mecum
     7	Ian Cook
     6	Fredrik Fornwall
     3	Efe
     2	Dewey Dunnington
     2	Jeremy Tan
     2	eitsupi
     1	Artur Rakhmatulin
     1	Hyukjin Kwon
     1	Jeroen Ooms
     1	Josh Ferguson
     1	Kevin Ushey
     1	Mandukhai Alimaa
     1	Pedro Matias
     1	Philip Moore
     1	Rusty Conover
     1	Sérgio Silveira
     1	Unik Dahal
     1	Yifan Chen
     1	grantframework0
     1	singhpratech
     1	İrem Çağın Yurttürk
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

[1]: https://github.com/apache/arrow-adbc/issues?q=is%3Aissue%20state%3Aclosed%20milestone%3A%22ADBC%20Libraries%2025%22
[2]: https://github.com/apache/arrow-adbc/pulls?q=is%3Apr%20state%3Aclosed%20milestone%3A%22ADBC%20Libraries%2025%22%20-author%3Aapp%2Fdependabot
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-25/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/25/format/specification.html
