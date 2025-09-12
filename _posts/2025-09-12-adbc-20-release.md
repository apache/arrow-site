---
layout: post
title: "Apache Arrow ADBC 20 (Libraries) Release"
date: "2025-09-12 00:00:00"
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

The Apache Arrow team is pleased to announce the version 20 release of
the Apache Arrow ADBC libraries. This release includes [**44
resolved issues**][1] from [**29 distinct contributors**][2].

This is a release of the **libraries**, which are at version 20.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.8.0
- C#: 0.20.0
- Java: 0.20.0
- R: 0.20.0
- Rust: 0.20.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

Driver managers now support loading driver manifests.  To learn more about
this feature, please see the [documentation][driver-manifests].

The Rust crates were reorganized.  **This is a breaking change.**  Now,
FFI-related code is part of `adbc_ffi` and the driver manager is part of
`adbc_driver_manager`.  Previously these were features of a single crate
`adbc_core`, which now only contains API definitions
([#3381](https://github.com/apache/arrow-adbc/pull/3381),
[#3197](https://github.com/apache/arrow-adbc/pull/3197)).  Also, some enums
are no longer marked as `#[non_exhaustive]`
([#3245](https://github.com/apache/arrow-adbc/pull/3245)).

The Java JNI bindings support a few more features
([#3373](https://github.com/apache/arrow-adbc/pull/3373),
[#3372](https://github.com/apache/arrow-adbc/pull/3372),
[#3370](https://github.com/apache/arrow-adbc/pull/3370),
[#3348](https://github.com/apache/arrow-adbc/pull/3348)).

The BigQuery driver properly uses microsecond timestamps
([#3364](https://github.com/apache/arrow-adbc/pull/3364)), has an improved
error message if your user account lacks the proper permissions
([#3297](https://github.com/apache/arrow-adbc/pull/3297)), properly handles
nested data ([#3240](https://github.com/apache/arrow-adbc/pull/3240)), and
supports service account impersonation
([#3174](https://github.com/apache/arrow-adbc/pull/3174)).  The C#
Databricks/HiveServer2 Thrift-protocol drivers continues to expand their
featureset, such as support for cancelling statements, token exchange, and
better tracing ([#3304](https://github.com/apache/arrow-adbc/pull/3304),
[#3302](https://github.com/apache/arrow-adbc/pull/3302),
[#3301](https://github.com/apache/arrow-adbc/pull/3301),
[#3224](https://github.com/apache/arrow-adbc/pull/3224),
[#3218](https://github.com/apache/arrow-adbc/pull/3218),
[#3192](https://github.com/apache/arrow-adbc/pull/3192),
[#3177](https://github.com/apache/arrow-adbc/pull/3177),
[#3137](https://github.com/apache/arrow-adbc/pull/3137),
[#3127](https://github.com/apache/arrow-adbc/pull/3127)).  The PostgreSQL
driver will properly bind `arrow.json` extension arrays as JSON parameters
([#3333](https://github.com/apache/arrow-adbc/pull/3333)).  The Snowflake
driver supports more authentication methods
([#3366](https://github.com/apache/arrow-adbc/pull/3366)).  The SQLite driver
can bind parameters by name instead of position
([#3362](https://github.com/apache/arrow-adbc/pull/3362)).

The C# library has been upgraded to .NET 8
([#3120](https://github.com/apache/arrow-adbc/pull/3120)).

GLib has more bindings to ADBC functions
([#3118](https://github.com/apache/arrow-adbc/pull/3118)).

The Go library has some experimental helpers to simplify getting driver
metadata ([#3239](https://github.com/apache/arrow-adbc/pull/3239)) and
ingesting Arrow data
([#3150](https://github.com/apache/arrow-adbc/pull/3150)).  The `database/sql`
adapter handles `time.Time` values for bind parameters now
([#3109](https://github.com/apache/arrow-adbc/pull/3109)).  Drivers will
forward SQLSTATE and other error metadata across the FFI boundary
([#2801](https://github.com/apache/arrow-adbc/pull/2801)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-19..apache-arrow-adbc-20
    28	David Li
    14	Todd Meng
    13	Bryce Mecum
    13	eitsupi
    12	Jacky Hu
    12	Matt Topol
     8	Bruce Irschick
     7	Matthijs Brobbel
     6	davidhcoe
     5	eric-wang-1990
     4	Alex Guo
     3	Daijiro Fukuda
     3	Felipe Oliveira Carvalho
     3	Sutou Kouhei
     2	Curt Hagenlocher
     2	Jade Wang
     2	Mandukhai Alimaa
     2	amangoyal
     1	Arseny Tsypushkin
     1	Dewey Dunnington
     1	Even Rouault
     1	Ian Cook
     1	Jordan E
     1	Lucas Valente
     1	Mila Page
     1	Ryan Syed
     1	Sudhir Reddy Emmadi
     1	Xuliang (Harry) Sun
     1	Yu Ishikawa
```

## Roadmap

A Go-based driver for Databricks is in the works from a contributor.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/24
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-20/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/20/format/specification.html

[driver-manifests]: https://arrow.apache.org/adbc/current/format/driver_manifests.html#driver-manifests
