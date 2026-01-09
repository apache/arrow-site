---
layout: post
title: "Apache Arrow ADBC 22 (Libraries) Release"
date: "2026-01-09 00:00:00"
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

The Apache Arrow team is pleased to announce the version 22 release of
the Apache Arrow ADBC libraries. This release includes [**14
resolved issues**][1] from [**16 distinct contributors**][2].

This is a release of the **libraries**, which are at version 22.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.10.0
- C#: 0.22.0
- Java: 0.22.0
- R: 0.22.0
- Rust: 0.22.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

In the C++ driver manager and packages using it (such as the driver managers
for Go and Python), now it is possible to open a connection with only a URI
(the driver name will be assumed to be the URI scheme)
([#3694](https://github.com/apache/arrow-adbc/pull/3694),
[#3790](https://github.com/apache/arrow-adbc/pull/3790)).

For Windows users, C++ builds now generate import LIBs so DLLs can be properly
linked to ([#2858](https://github.com/apache/arrow-adbc/pull/2858)).

The C# Databricks driver has reduced memory usage
([#3654](https://github.com/apache/arrow-adbc/pull/3654),
[#3683](https://github.com/apache/arrow-adbc/pull/3683)).  Also, token
exchange was fixed ([#3715](https://github.com/apache/arrow-adbc/pull/3715)),
and a deadlock was fixed
([#3756](https://github.com/apache/arrow-adbc/pull/3756)).

The DataFusion driver allows setting the async runtime
([#3712](https://github.com/apache/arrow-adbc/pull/3712)).

The Arrow Flight SQL driver supports bulk ingestion with compatible servers
([#3808](https://github.com/apache/arrow-adbc/pull/3808)).  The Python package
also exposes constants for OAuth
([#3849](https://github.com/apache/arrow-adbc/pull/3849)).

The Go `database/sql` adapter now closes resources properly
([#3731](https://github.com/apache/arrow-adbc/pull/3731)).  All drivers built
with Go were updated to a newer Go and arrow-go to resolve CVEs reported
against Go itself (although we believe they do not affect the drivers) and to
resolve a crash when used with Polars
([#3758](https://github.com/apache/arrow-adbc/pull/3758)).

The PostgreSQL driver supports setting the transaction isolation level
([#3760](https://github.com/apache/arrow-adbc/pull/3760)), and a bug with the
GetObjects filter options was fixed
([#3855](https://github.com/apache/arrow-adbc/pull/3855)).

The Python driver manager will now close unclosed cursors for you when a
connection is closed
([#3810](https://github.com/apache/arrow-adbc/pull/3810)).

Driver shared libraries built with Rust will now catch panics and error
gracefully instead of terminating the entire process (although we do not
currently distribute any driver libraries built this way)
([#3819](https://github.com/apache/arrow-adbc/pull/3819)).  Also, the Rust
driver manager will no longer `dlclose` driver libraries as drivers built with
Go would hang if this was done on some platforms
([#3844](https://github.com/apache/arrow-adbc/pull/3844)).

The SQLite driver supports more info keys
([#3843](https://github.com/apache/arrow-adbc/pull/3843)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-21..apache-arrow-adbc-22
    19	David Li
     7	eric-wang-1990
     6	eitsupi
     5	Mandukhai Alimaa
     4	Bryce Mecum
     3	davidhcoe
     2	Matt Topol
     2	Pavel Agafonov
     2	Philip Moore
     1	Ali Alamiri
     1	Curt Hagenlocher
     1	Hélder Gregório
     1	Matt Corley
     1	Pranav Joglekar
     1	Sudhir Reddy Emmadi
     1	msrathore-db
```

## Roadmap

We are working on the next revision of the API standard.  After some
discussion, we will likely put aside async APIs to focus on addressing other
API gaps that users have reported.  However, we may still define
langauge-specific async APIs for ecosystems that expect them (like Rust).

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/26
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-22/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/22/format/specification.html
