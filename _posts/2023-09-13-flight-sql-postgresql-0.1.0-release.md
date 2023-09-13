---
layout: post
title: "Apache Arrow Flight SQL adapter for PostgreSQL 0.1.0 Release"
date: "2023-09-13 00:00:00"
author: pmc
categories: [release]
---
{% comment %}
<!--
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
-->
{% endcomment %}

The Apache Arrow team is pleased to announce the 0.1.0 release of
the Apache Arrow Flight SQL adapter for PostgreSQL. This includes
[**60 commits**][commits] from [**1 distinct
contributors**][contributors].

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bug fixes and improvements have
been made: we refer you to [the complete release notes][release-note].

## What is Apache Arrow Flight SQL adapter for PostgreSQL?

Apache Arrow Flight SQL adapter for PostgreSQL is a PostgreSQL
extension that adds an [Apache Arrow Flight
SQL](https://arrow.apache.org/docs/format/FlightSql.html) endpoint to
PostgreSQL.

Apache Arrow Flight SQL is a protocol to use [Apache Arrow
format](https://arrow.apache.org/docs/format/Columnar.html) to
interact with SQL databases. You can use Apache Arrow Flight SQL
instead of [the PostgreSQL wire
protocol](https://www.postgresql.org/docs/current/protocol.html) to
interact with PostgreSQL by Apache Arrow Flight SQL adapter for
PostgreSQL.

Apache Arrow format is designed for fast typed table data exchange. If
you want to get large data by `SELECT` or `INSERT`/`UPDATE` large
data, Apache Arrow Flight SQL will be faster than the PostgreSQL wire
protocol.

## Release Highlights

This is the initial release!

This includes the following basic features. Other features will be
implemented in the future releases.

* Literal `SELECT`/`INSERT`/`UPDATE`/`DELETE`
* Prepared `SELECT`/`INSERT`/`UPDATE`/`DELETE`
* `password`/`trust` authentications
* TLS connection
* Integer family types
* Floating point family types
* Text family types
* Binary family types
* Timestamp with time zone type

Packages for Debian GNU/Linux bookworm and Ubuntu 22.04 are available.

## Install

See [the install document][install] for details.

## Contributors

```console
$ git shortlog --perl-regexp --author=^((?!dependabot\[bot\]).*)$ -sn dc7f34e2636732acd0d015a7cd8259334f1acb16...0.1.0
    59	Sutou Kouhei
```

## Roadmap

* Add support for more data types
* Add support for mTLS
* Add support for [Apache Arrow Flight SQL commands to fetch
  metadata](https://arrow.apache.org/docs/format/FlightSql.html#sql-metadata)
* Add support for Apache Arrow Flight SQL transaction related APIs
* Add support for canceling a query
* Add more benchmark results
* Document architecture

## Getting Involved

We welcome questions and contributions from all interested. Issues can
be filed on [GitHub][issues], and questions can be directed to GitHub or
[the Apache Arrow mailing lists][mailing-list].

[commits]: https://github.com/apache/arrow-flight-sql-postgresql/compare/dc7f34e2636732acd0d015a7cd8259334f1acb16...0.1.0
[contributors]: #contributors
[release-note]: https://arrow.apache.org/flight-sql-postgresql/0.1.0/release-notes.html#version-0-1-0
[install]: https://arrow.apache.org/flight-sql-postgresql/0.1.0/install.html
[issues]: https://github.com/apache/arrow-flight-sql-postgresql/issues
[mailing-list]: {% link community.md %}
