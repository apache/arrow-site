---
layout: post
title: "Apache Arrow ADBC 17 (Libraries) Release"
date: "2025-03-07 00:00:00"
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

The Apache Arrow team is pleased to announce the version 17 release of
the Apache Arrow ADBC libraries. This release includes [**18
resolved issues**][1] from [**13 distinct contributors**][2].

This is a release of the **libraries**, which are at version 17.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.5.0
- C#: 0.17.0
- Java: 0.17.0
- R: 0.17.0
- Rust: 0.17.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

The CMake config can now build against system dependencies instead of forcing vendored dependencies ([#2546](https://github.com/apache/arrow-adbc/pull/2546)).  Also, CMake files are now installed even for the drivers written in Go ([#2506](https://github.com/apache/arrow-adbc/issues/2506)).  Packages for Ubuntu 24.04 LTS are now available ([#2482](https://github.com/apache/arrow-adbc/pull/2482)).

The performance of `AdbcDataReader` and `ValueAt` has been improved in C# ([#2534](https://github.com/apache/arrow-adbc/pull/2534)).  The C# BigQuery driver will now use a default project ID if one is not specified ([#2471](https://github.com/apache/arrow-adbc/pull/2471)).

The Flight SQL and Snowflake drivers allow passing low-level options in Go (gRPC dial options in [#2563](https://github.com/apache/arrow-adbc/pull/2563) and gosnowflake options in [#2558](https://github.com/apache/arrow-adbc/pull/2558)).  The Flight SQL driver should now provide column-level metadata ([#2481](https://github.com/apache/arrow-adbc/pull/2481)).  The Snowflake driver now no longer requires setting the current schema to get metadata ([#2517](https://github.com/apache/arrow-adbc/issues/2517)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-16..apache-arrow-adbc-17
    15	David Li
     6	Matthijs Brobbel
     2	Hélder Gregório
     2	Matt Topol
     2	Matthias Kuhn
     2	Sutou Kouhei
     2	davidhcoe
     1	Curt Hagenlocher
     1	Felipe Oliveira Carvalho
     1	Felipe Vianna
     1	Marius van Niekerk
     1	Shuoze Li
     1	amangoyal
```

## Roadmap

There is some discussion on a potential second revision of ADBC to include more missing functionality and asynchronous API support.  For more, see the [milestone](https://github.com/apache/arrow-adbc/milestone/8).  We would welcome suggestions on APIs that could be added or extended.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/21
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-17/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/17/format/specification.html
