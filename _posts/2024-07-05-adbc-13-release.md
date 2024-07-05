---
layout: post
title: "Apache Arrow ADBC 13 (Libraries) Release"
date: "2024-07-05 00:00:00"
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

The Apache Arrow team is pleased to announce the 13 release of
the Apache Arrow ADBC libraries. This covers includes [**24
resolved issues**][1] from [**11 distinct contributors**][2].

This is a release of the **libraries**, which are at version
13.  The **API specification** is versioned separately and is
at version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.1.0
- C#: 0.13.0
- Java: 0.13.0
- R: 0.13.0
- Rust: 0.13.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

The C/C++ components may now be optionally built with the Meson build system, which can be more convenient during development.  (CMake is still the preferred build system for releases.)  The PostgreSQL driver now avoids an error when ingesting large record batches.  We have worked around an issue in Snowflake when ingesting empty batches. Also, "privateLink" account identifiers should work as expected now.

The C# APIs have been overhauled to prepare for async support.

The Rust implementation is effectively ready, though it is not yet part of releases.

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-12..apache-arrow-adbc-13
    24	David Li
     7	Bruce Irschick
     5	Curt Hagenlocher
     3	Matt Topol
     2	Alexandre Crayssac
     2	Julian Brandrick
     2	William Ayd
     1	Cocoa
     1	Dewey Dunnington
     1	Joel Lubinitsky
     1	davidhcoe
```

## Roadmap

The Google BigQuery driver should be available in the next release.  We would like to begin uploading releases for Rust as well.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/17
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-13/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
