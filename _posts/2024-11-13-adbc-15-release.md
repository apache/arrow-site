---
layout: post
title: "Apache Arrow ADBC 15 (Libraries) Release"
date: "2024-11-13 00:00:00"
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

The Apache Arrow team is pleased to announce the version 15 release 
of the Apache Arrow ADBC libraries. This release includes [**31
resolved issues**][1] from [**13 distinct contributors**][2].

This is a release of the **libraries**, which are at version
15.  The [**API specification**](specification) is versioned 
separately and is at version 1.1.0.

The subcomponents are versioned independently:

- C/C++/GLib/Go/Python/Ruby: 1.3.0
- C#: 0.15.0
- Java: 0.15.0
- R: 0.15.0
- Rust: 0.15.0

The release notes below are not exhaustive and only expose selected
highlights of the release. Many other bugfixes and improvements have
been made: we refer you to the [complete changelog][3].

## Release Highlights

- The BigQuery driver is now properly released to PyPI.
- A basic driver for Apache DataFusion is now being developed.
- The documentation now includes the Doxygen API reference for C/C++, which should give a better/more native experience than the previous Breathe-based documentation.
- The Java libraries now use the latest arrow-java libraries, and as such require Java 11 or newer.
- The PostgreSQL driver has basic support for Redshift, though it cannot use the COPY optimizations for PostgreSQL and as such will not be as fast.
- The PostgreSQL driver can now handle ingesting Arrow list types.
- The PostgreSQL driver will use the [Opaque canonical extension type][opaque] for unknown types, instead of just returning bytes with no further context.
- We no longer build for Python 3.8.  We now build for Python 3.13.
- The Snowflake driver better handles catalog operations when not connected to a particular database.

## Contributors

```
$ git shortlog --perl-regexp --author='^((?!dependabot\[bot\]).*)$' -sn apache-arrow-adbc-14..apache-arrow-adbc-15
    24	David Li
    15	Dewey Dunnington
    14	Bruce Irschick
     5	Curt Hagenlocher
     5	davidhcoe
     3	Laurent Goujon
     3	Matthijs Brobbel
     3	William Ayd
     3	eitsupi
     2	Matt Topol
     2	Tornike Gurgenidze
     2	qifanzhang-ms
     1	Sudhir Reddy Emmadi
```

## Roadmap

There is some discussion on a potential second revision of ADBC to include more missing functionality and asynchronous API support.  For more, see the [milestone](https://github.com/apache/arrow-adbc/milestone/8); the proposed C Data Interface extensions have been accepted.

## Getting Involved

We welcome questions and contributions from all interested.  Issues
can be filed on [GitHub][4], and questions can be directed to GitHub
or the [Arrow mailing lists][5].

[1]: https://github.com/apache/arrow-adbc/milestone/19
[2]: #contributors
[3]: https://github.com/apache/arrow-adbc/blob/apache-arrow-adbc-15/CHANGELOG.md
[4]: https://github.com/apache/arrow-adbc/issues
[5]: {% link community.md %}

[opaque]: https://arrow.apache.org/docs/format/CanonicalExtensions.html#opaque
[specification]: https://arrow.apache.org/adbc/current/format/specification.html
