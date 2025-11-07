---
layout: post
title: "Apache Arrow ADBC 21 (Libraries) Release"
date: "2025-11-07 00:00:00"
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

The Apache Arrow team is pleased to announce the version 21 release of
the Apache Arrow ADBC libraries. This release includes [**30
resolved issues**][1] from [**23 distinct contributors**][2].

This is a release of the **libraries**, which are at version 21.  The
[**API specification**][specification] is versioned separately and is at
version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.9.0
- C#: 0.21.0
- Java: 0.21.0
- R: 0.21.0
- Rust: 0.21.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

Language bindings:
- The driver manager reports better errors when it fails to find a driver ([#3646](https://github.com/apache/arrow-adbc/pull/3646)).
- The Python driver manager now searches for manifests in the proper location when inside a Python virtual environment ([#3490](https://github.com/apache/arrow-adbc/pull/3490)).
- Added convenience methods to the driver manager on top of the standard DBAPI-2.0/PEP249 APIs ([#3539](https://github.com/apache/arrow-adbc/pull/3539)).
- The signature for `connect` has been simplified, so you can connect without having to repeat the driver name or specify explicit keyword arguments depending on the driver ([#3537](https://github.com/apache/arrow-adbc/pull/3537)).
- Support for Python 3.9 has been dropped ([#3573](https://github.com/apache/arrow-adbc/pull/3573), [#3663](https://github.com/apache/arrow-adbc/pull/3663)).
- Support for Python 3.14 (including the free-threading variant) has been added ([#3575](https://github.com/apache/arrow-adbc/pull/3575), [#3620](https://github.com/apache/arrow-adbc/pull/3620), [#3663](https://github.com/apache/arrow-adbc/pull/3663)).
- The R bindings now support `replace` and `create_append` ingest modes.

Drivers:
- The Go BigQuery driver now supports service account impersonation ([#3488](https://github.com/apache/arrow-adbc/pull/3488)) and setting a quota project ([#3622](https://github.com/apache/arrow-adbc/pull/3622)).
- The Go BigQuery driver now returns more detailed type metadata in result sets ([#3604](https://github.com/apache/arrow-adbc/pull/3604)).
- The C# BigQuery driver allows setting a location ([#3494](https://github.com/apache/arrow-adbc/pull/3494)).
- The C# Databricks driver adjusted default settings to make small queries faster ([#3489](https://github.com/apache/arrow-adbc/pull/3489)).
- Memory usage of the C# Databricks driver was improved ([#3652](https://github.com/apache/arrow-adbc/pull/3652), [#3656](https://github.com/apache/arrow-adbc/pull/3656)).
- All C# HiveServer2-based drivers (Hive, Impala, Spark, Databricks) throw Unauthorized exceptions when appropriate ([#3551](https://github.com/apache/arrow-adbc/pull/3551)).
- JNI bindings to the C++ driver manager are now released, making it possible to use non-Java drivers from a Java application (in a very limited fashion) ([#3429](https://github.com/apache/arrow-adbc/pull/3429)).  Binary artifacts are available for amd64/arm64 Linux, arm64 macOS, and amd64 Windows.
- The PostgreSQL driver can now return the schema of any bind parameters in a prepared query ([#3579[(https://github.com/apache/arrow-adbc/pull/3579)]]).
- The PostgreSQL driver properly batches result sets with large string/binary values now ([#3616](https://github.com/apache/arrow-adbc/pull/3616)).
- The Snowflake driver now returns float64 for numeric columns when use_high_precision is false and scale is nonzero ([#3295](https://github.com/apache/arrow-adbc/pull/3295)).  (Previously it incorrectly truncated to int64.)
- Added an option to disable the "vectorized" scanner when ingesting data into Snowflake, which sometimes appeared to cause performance issues ([#3555](https://github.com/apache/arrow-adbc/pull/3555)).

Packaging:
- Added AlmaLinux 10 ([#3514](https://github.com/apache/arrow-adbc/pull/3514)).
- Added Debian Trixie ([#3513](https://github.com/apache/arrow-adbc/pull/3513)).

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-20..apache-arrow-adbc-21
    28	David Li
     9	Bruce Irschick
     7	eric-wang-1990
     6	Curt Hagenlocher
     5	eitsupi
     4	msrathore-db
     3	Bryce Mecum
     3	Mandukhai Alimaa
     3	Sutou Kouhei
     3	davidhcoe
     2	Anna Lee
     2	Jason Lin
     2	Kevin Liu
     1	Dewey Dunnington
     1	Ian Cook
     1	Jacky Hu
     1	Jade Wang
     1	Kristin Cowalcijk
     1	Lucas Valente
     1	Matthijs Brobbel
     1	bruceNu1l
     1	praveentandra
     1	rnowacoski
```

## Roadmap

We are starting work on async interfaces and other API enhancements, and
welcome comments or contributions from anyone interested.  See the initial
pull requests:

- https://github.com/apache/arrow-adbc/pull/3607
- https://github.com/apache/arrow-adbc/pull/3623

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/25
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-21/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}
[specification]: https://arrow.apache.org/adbc/21/format/specification.html
