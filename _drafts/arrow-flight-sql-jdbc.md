---
layout: post
title: "Expanding Arrow's Reach with a JDBC Driver for Arrow Flight SQL"
date: "2022-09-14 09:00:00 -0500"
author: pmc
categories: [application]
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

We're excited to announce that the Arrow project now includes a
[JDBC][jdbc] driver [implementation][impl] based on [Arrow Flight
SQL][flight-sql].  This is possible courtesy of a software grant from
[Dremio][dremio], who developed and open-sourced this driver
implementation, in addition to designing and contributing Flight SQL
itself.

## Background

[Arrow Flight RPC][flight] is a framework for efficient transfer of
Arrow data across the network.  While it is agnostic to the type of
application using it, from the beginning, it was designed with an eye
towards modern databases and other data systems.  Flight SQL realized
that goal by defining how to use Flight RPC as a protocol[^1] for
database communications: how a client should talk to a server and
execute queries, fetch result sets, and so on.

With this new JDBC driver, applications using the JDBC API can talk to
any database server implementing the Flight SQL protocol, while still
using a familiar Java interface.  Underneath, the driver sends queries
to the server via Flight SQL and adapts responses to the ``ResultSet``
interface.

Put another way, Flight SQL is a database protocol designed for 1)
columnar data and 2) implementation by multiple databases.  Some
projects do things like reimplement the Postgres wire protocol to
benefit from existing driver implementations.  Flight SQL, on the
other hand, provides a protocol that is:

1. Columnar, using Arrow data for bulk result sets,
2. Designed to be implemented by multiple databases, and
3. Designed to be adapted to APIs like JDBC and ODBC.

Just columnar data alone can be a [significant speedup][hannes] for
analytical use cases.

[^1]: Despite the name, Flight SQL is **not** a SQL dialect, nor is it
    even tied to SQL itself!

## Why JDBC?

JDBC offers a row-oriented API which is at odds with Arrow's columnar
structure.  However, it is a popular and time-tested choice for many
applications, such as business intelligence (BI) tools that take
advantage of JDBC to interoperate generically with multiple databases.
An Arrow-native database may still wish to be accessible to all of
this existing software, without having to implement multiple client
interfaces itself.

This JDBC driver implementation demonstrates the generality of Arrow
and Flight SQL, and increases the reach of Arrow-based applications.
Now, by just implementing Flight SQL, a database can provide
Arrow-native database access to clients that want it via standards
like [ADBC][adbc], while simultaneously supporting the vast body of
existing code that uses JDBC, all without having to implement two
separate wire protocols.

## Getting Involved

The JDBC driver was merged for the Arrow 10.0.0 release, and the
[source code][impl] can be found in the Arrow repository.  Once Arrow
10.0.0 is released (which should be around October 2022), official
builds of the driver will be available alongside other Arrow
libraries.  Dremio is already making use of the driver, and we're
looking forward to seeing what gets built on top.  Of course, there
are still improvements to be made.  If you're interested in
contributing, or have feedback or questions, please reach out on the
[mailing list][ml] or [GitHub][github].

For documentation on the driver, please see the [Arrow
documentation][driver-docs].

[adbc]: htttps://github.com/apache/arrow-adbc
[dremio]: https://www.dremio.com/
[driver-docs]: TODO
[flight]: {{ site.baseurl }}/docs/format/Flight.html
[flight-sql]: {{ site.baseurl }}/docs/format/FlightSql.html
[github]: htttps://github.com/apache/arrow
[hannes]: https://ir.cwi.nl/pub/26415
[impl]: https://github.com/apache/arrow/tree/master/java/flight/flight-sql-jdbc-driver
[jdbc]: https://docs.oracle.com/javase/tutorial/jdbc/overview/index.html
[ml]: {% link community.md %}
