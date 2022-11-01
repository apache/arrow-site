---
layout: post
title: "Expanding Arrow's Reach with a JDBC Driver for Arrow Flight SQL"
date: "2022-11-01 00:00:00"
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

We're excited to announce that as of version 10.0.0, the Arrow project
now includes a [JDBC][jdbc] driver [implementation][impl] based on
[Arrow Flight SQL][flight-sql].  This is courtesy of a software grant
from [Dremio][dremio-arrow], a data lakehouse platform. Contributors
from Dremio developed and open-sourced this driver implementation, in
addition to designing and contributing Flight SQL itself.

Flight SQL is a protocol for client-server database interactions.  It
defines how a client should talk to a server and execute queries,
fetch result sets, and so on.  Note that despite the name, Flight SQL
is *not* a SQL dialect, or even specific to SQL itself.  Underneath,
it builds on [Arrow Flight RPC][flight], a framework for efficient
transfer of Arrow data across the network.  While Flight RPC is
flexible and can be used in any type of application, from the
beginning, it was designed with an eye towards the kinds of use cases
that Flight SQL supports.

With this new JDBC driver, applications can talk to any database
server implementing the Flight SQL protocol using familiar JDBC APIs.
Underneath, the driver sends queries to the server via Flight SQL and
adapts the Arrow result set to the JDBC interface, so that the
database can support JDBC users without implementing additional APIs
or its own JDBC driver.

## Why use JDBC with Flight SQL?

JDBC offers a row-oriented API, which is opposite of Arrow's columnar
structure.  However, it is a popular and time-tested choice for many
applications.  For example, many business intelligence (BI) tools take
advantage of JDBC to interoperate generically with multiple databases.
An Arrow-native database may still wish to be accessible to all of
this existing software, without having to implement multiple client
drivers itself.  Additionally, columnar data transfer alone can be a
[significant speedup][hannes] for analytical use cases.

This JDBC driver implementation demonstrates the generality of Arrow
and Flight SQL, and increases the reach of Arrow-based applications.
Additionally, an [ODBC driver implementation][dremio-odbc] based on
Flight SQL is also available courtesy of Dremio, though it is not yet
part of the Arrow project due to dependency licensing issues.

Now, a database can support the vast body of existing code that uses
JDBC or ODBC, as well as Arrow-native applications, just by
implementing a single wire protocol: Flight SQL.  Some projects
instead do things like reimplementing the Postgres wire protocol to
benefit from its existing drivers.  But for Arrow-native databases,
this gives up the benefits of columnar data.  On the other hand,
Flight SQL is:

1. Columnar and Arrow-native, using Arrow for result sets to avoid
   unnecessary data copies and transformations;
2. Designed for implementation by multiple databases, with high-level
   C++ and Java libraries and a Protobuf protocol definition; and
3. Usable both through APIs like JDBC and ODBC thanks to this software
   grant, as well as directly (or via [ADBC][adbc]) for applications
   that want columnar data.

## Getting Involved

The JDBC driver was merged for the [Arrow 10.0.0 release][arrow-10], and
the [source code][impl] can be found in the Arrow repository.
Official builds of the driver are [available on Maven Central][maven].
Dremio is already making use of the driver, and we're looking forward
to seeing what else gets built on top.  Of course, there are still
improvements to be made.  If you're interested in contributing, or
have feedback or questions, please reach out on the [mailing list][ml]
or [GitHub][github].

To learn more about when to use the Flight SQL JDBC driver vs the
Flight SQL native client libraries, see this section of Dremio's
presentation, [“Apache Arrow Flight SQL: a universal standard for high
performance data transfers from databases”][dremio-presentation]
(starting at 22:23).  For more about how Dremio uses Apache Arrow, see
their [guide][dremio-arrow].

[adbc]: htttps://github.com/apache/arrow-adbc
[arrow-10]: {% link _posts/2022-10-31-10.0.0-release.md %}
[dremio]: https://www.dremio.com/
[dremio-arrow]: https://www.dremio.com/resources/guides/apache-arrow/
[dremio-odbc]: https://docs.dremio.com/software/drivers/arrow-flight-sql-odbc-driver/
[dremio-presentation]: https://www.youtube.com/watch?v=6q8AMrQV3vE&t=1343s
[flight]: {{ site.baseurl }}/docs/format/Flight.html
[flight-sql]: {{ site.baseurl }}/docs/format/FlightSql.html
[github]: htttps://github.com/apache/arrow
[hannes]: https://ir.cwi.nl/pub/26415
[impl]: https://github.com/apache/arrow/tree/master/java/flight/flight-sql-jdbc-driver
[jdbc]: https://docs.oracle.com/javase/tutorial/jdbc/overview/index.html
[maven]: https://search.maven.org/search?q=a:flight-sql-jdbc-driver
[ml]: {% link community.md %}
