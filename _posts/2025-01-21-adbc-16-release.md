---
layout: post
title: "Apache Arrow ADBC 16 (Libraries) Release"
date: "2025-01-21 00:00:00"
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

The Apache Arrow team is pleased to announce the version 16 release of
the Apache Arrow ADBC libraries. This release includes [**15
resolved issues**][1] from [**11 distinct contributors**][2].

This is a release of the **libraries**, which are at version 16.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.4.0
- C#: 0.16.0
- Java: 0.16.0
- R: 0.16.0
- Rust: 0.16.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

This release focused mostly on bugfixes.

The C# ADO.NET adapter can now parse connection properties from the connection string ([#2352](https://github.com/apache/arrow-adbc/pull/2352)).  The driver for various Thrift-based systems (Hive/Impala/Spark) now supports timeout options ([#2312](https://github.com/apache/arrow-adbc/pull/2312)).  A package was added to wrap the Arrow Flight SQL driver (written in Go) from C# ([#2214](https://github.com/apache/arrow-adbc/pull/2214)).

The PostgreSQL driver was fixed to properly return unknown types as `arrow.opaque` again ([#2450](https://github.com/apache/arrow-adbc/pull/2450)) and to avoid issuing an unnecessary `COMMIT` which would cause the driver and connection state to get out of sync ([#2412](https://github.com/apache/arrow-adbc/pull/2412)).

Python packages only require manylinux2014 again; the baseline glibc requirement was unintentionally raised in the last release and has now been reverted ([#2350](https://github.com/apache/arrow-adbc/issues/2350)).

A breaking change was made in the unstable Rust APIs to return a `Result` from a fallible function ([#2334](https://github.com/apache/arrow-adbc/pull/2334)).  An `adbc_snowflake` crate was added to wrap the Snowflake driver (written in Go) into the Rust APIs, though it is not yet being published ([#2207](https://github.com/apache/arrow-adbc/pull/2207)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-15..apache-arrow-adbc-16
    23	David Li
     8	Matthijs Brobbel
     4	davidhcoe
     3	Bruce Irschick
     2	Matt Topol
     1	Albert LI
     1	Cocoa
     1	Curt Hagenlocher
     1	Jacob Wujciak-Jens
     1	Julian Brandrick
     1	qifanzhang-ms
```

## Roadmap

There is some discussion on a potential second revision of ADBC to include more missing functionality and asynchronous API support.  For more, see the [milestone](https://github.com/apache/arrow-adbc/milestone/8); the proposed C Data Interface extensions have been accepted.

We would welcome comments on APIs that could be added or extended, for instance see [#1704](https://github.com/apache/arrow-adbc/issues/1704).

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/20
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-16/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/16/format/specification.html
