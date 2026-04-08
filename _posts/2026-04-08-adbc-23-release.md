---
layout: post
title: "Apache Arrow ADBC 23 (Libraries) Release"
date: "2026-04-07 00:00:00"
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

The Apache Arrow team is pleased to announce the version 23 release of
the Apache Arrow ADBC libraries. This release includes [**41
resolved issues**][1] from [**20 distinct contributors**][2].

This is a release of the **libraries**, which are at version 23.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.11.0
- C#: 0.23.0
- Java: 0.23.0
- R: 0.23.0
- Rust: 0.23.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

A breaking change has been made to the Rust APIs (pre-1.0): returned
`RecordBatchReader`s are now type-erased and boxed for caller flexibility;
this also fixes the returned reader lifetime accidentally being tied to input
argument lifetimes ([#3904](https://github.com/apache/arrow-adbc/pull/3904)).

A driver manager for Node.js is now available from NPM
([#4046](https://github.com/apache/arrow-adbc/pull/4046),
[#4091](https://github.com/apache/arrow-adbc/pull/4091),
[#4116](https://github.com/apache/arrow-adbc/pull/4116),
[#4125](https://github.com/apache/arrow-adbc/pull/4125), etc.).

The C++ and Rust driver managers now support [connection
profiles](https://arrow.apache.org/adbc/current/format/connection_profiles.html)
([#3876](https://github.com/apache/arrow-adbc/pull/3876),
[#3973](https://github.com/apache/arrow-adbc/pull/3973),
[#4080](https://github.com/apache/arrow-adbc/pull/4080),
[#4083](https://github.com/apache/arrow-adbc/pull/4083) etc.). (Note that
other bindings that use the C++ driver manager, including GLib/Ruby, Go, Java,
Python, R, and so on, inherit this support.)

The Go APIs have added interfaces that always take a `context.Context` for
consistency, and to make sure context like telemetry traces propagate properly
([#4009](https://github.com/apache/arrow-adbc/pull/4009)).

The Python driver manager has added specific parameters for using [connection
profiles](https://arrow.apache.org/adbc/current/format/connection_profiles.html)
as well ([#4078](https://github.com/apache/arrow-adbc/pull/4078),
[#4118](https://github.com/apache/arrow-adbc/pull/4118)). Also, non-string
option values are directly accepted for convenience
([#4088](https://github.com/apache/arrow-adbc/pull/4088)). `adbc_get_statistics`
has been added ([#4129](https://github.com/apache/arrow-adbc/pull/4129)).

The JNI bindings (allowing use of C/C++/Go/Rust/etc. drivers from Java) now
support more functions (GetObjects, GetInfo, ExecuteSchema, etc.)
([#3966](https://github.com/apache/arrow-adbc/pull/3966),
[#3972](https://github.com/apache/arrow-adbc/pull/3972),
[#4056](https://github.com/apache/arrow-adbc/pull/4056)).

Packages are now being uploaded to
[Homebrew](https://formulae.brew.sh/formula/apache-arrow-adbc)
([#4131](https://github.com/apache/arrow-adbc/pull/4131)).

Python wheels now require `manylinux_2_28`, up from `manylinux2010`, following
PyArrow ([#4146](https://github.com/apache/arrow-adbc/pull/4146)).  On macOS,
macOS 12 is now the minimum version due to upgrading to Go 1.25+ (including on
conda-forge, where the packages previously pinned Go 1.24 to avoid this).

The PostgreSQL driver tries to reconcile Arrow NA arrays with PostgreSQL types
when binding ([#4098](https://github.com/apache/arrow-adbc/pull/4098)). Also,
a bug in conversion from Arrow decimals to PostgreSQL numerics has been fixed
([#3787](https://github.com/apache/arrow-adbc/pull/3787)).

The SQLite driver now enables various optional features, like math functions
([#4147](https://github.com/apache/arrow-adbc/pull/4147)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-22..apache-arrow-adbc-23
    35	David Li
    12	Kent Wu
    10	Matt Topol
     8	eitsupi
     6	Bryce Mecum
     5	Bruce Irschick
     4	Mandukhai Alimaa
     3	Emil Sadek
     3	Tornike Gurgenidze
     2	Dewey Dunnington
     2	Felipe Oliveira Carvalho
     2	eric-wang-1990
     1	Curt Hagenlocher
     1	Ian Cook
     1	Madhavendra Rathore
     1	Mila Page
     1	Pavel Agafonov
     1	Roshan Banisetti
     1	davidhcoe
     1	oglego
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

[1]: https://github.com/apache/arrow-adbc/milestone/27
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-23/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/23/format/specification.html
