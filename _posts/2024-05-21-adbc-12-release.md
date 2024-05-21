---
layout: post
title: "Apache Arrow ADBC 12 (Libraries) Release"
date: "2024-05-21 00:00:00"
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

The Apache Arrow team is pleased to announce the 12th release of
the Apache Arrow ADBC libraries. This covers includes [**56
resolved issues**][1] from [**13 distinct contributors**][2].

This is a release of the **libraries**, which are at version 12.
The **API specification** is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.0.0
- C#: 0.12.0
- Java: 0.12.0
- R: 0.12.0
- Rust: 0.12.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

There is a [known issue](https://github.com/apache/arrow-adbc/issues/1841)
with multiple drivers in a single process due to using languages with runtimes
as the basis for many drivers.

Option strings in C# are now case-sensitive.  In general, the C# bindings are
rapidly progressing.  A driver that wraps the Hive Thrift API was added.

The Flight SQL driver now supports the new "stateless" prepared statement
proposal.

Rust libraries were not released to Cargo, but the implementation has made
rapid progress.

The Snowflake driver now supports bind parameters.  Also, some queries which
only return JSON data (e.g. `SHOW TABLES`) are now supported.  Quoting of
names in bulk ingestion was fixed to conform to Snowflake SQL syntax.

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-0.11.0..apache-arrow-adbc-12
    25	David Li
    19	Curt Hagenlocher
     5	Matt Topol
     5	Sutou Kouhei
     4	Dewey Dunnington
     3	Alexandre Crayssac
     3	Matthijs Brobbel
     2	Bruce Irschick
     2	Cocoa
     2	davidhcoe
     1	Bryce Mecum
     1	Hyunseok Seo
     1	Joel Lubinitsky
```

## Roadmap

A Google BigQuery driver is being developed in Go.  We anticipate C# will
reach stability soon and Rust should start seeing releases as well.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/16
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-12/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
