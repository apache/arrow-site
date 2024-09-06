---
layout: post
title: "Apache Arrow ADBC 14 (Libraries) Release"
date: "2024-09-05 00:00:00"
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

The Apache Arrow team is pleased to announce the 14 release of
the Apache Arrow ADBC libraries. This covers includes [**27
resolved issues**][1] from [**12 distinct contributors**][2].

This is a release of the **libraries**, which are at version
14.  The **API specification** is versioned separately and is
at version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.2.0
- C#: 0.14.0
- Java: 0.14.0
- R: 0.14.0
- Rust: 0.14.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

A new driver for Google BigQuery is now available in source form and will be available from conda-forge, however, Python wheels will not be available until the next release.  Thanks to [Cocoa Xu](https://github.com/cocoa-xu) for the major effort!

The C/C++ implementation now uses `arrow-adbc/adbc.h` as its include path to avoid polluting the `include` directory.  For now, `adbc.h` is still installed for backwards compatibility but we recommend updating include paths.

The C# ADO.NET bindings now support bind parameters.

The Rust library is now [uploaded to crates.io](https://crates.io/crates/adbc_core).

The PostgreSQL driver now properly handles reading JSONB columns and ingestion of list/large list columns.  It also finally properly supports bind parameters in prepared statements and can handle multiple statements in the same string.

We discovered a [performance regression](https://github.com/golang/go/issues/68587) in recent versions of Go when making FFI calls from the main thread.  Unfortunately, this affects the Arrow Flight SQL, BigQuery, and Snowflake driver implementations.  Python wheels are not affected as we are still building with an older version of Go.  However, if you are building the driver yourself or using the conda-forge package, you may run into this.  Mitigations include making fewer FFI calls if possible (e.g., reuse a single connection or cursor instead of creating new ones), or using a different thread than the main thread.

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-13..apache-arrow-adbc-14
    18	David Li
    11	Dewey Dunnington
    11	William Ayd
     4	Joel Lubinitsky
     3	davidhcoe
     2	Matt Topol
     1	Bruce Irschick
     1	Clive Cox
     1	Cocoa
     1	Curt Hagenlocher
     1	Hyunseok Seo
     1	Joris Van den Bossche
```

## Roadmap

There is some discussion on a potential second revision of ADBC to include more missing functionality and asynchronous API support.  For more, see the [milestone](https://github.com/apache/arrow-adbc/milestone/8) and the [async discussion](https://github.com/apache/arrow-adbc/issues/811)/[proposed C Data Interface API](https://github.com/apache/arrow/pull/43632).

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/18
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-14/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
