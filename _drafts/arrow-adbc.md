---
layout: post
title: "Introducing ADBC: Database Access for Apache Arrow"
date: "2022-10-03 09:00:00 -0500"
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

The Arrow community has formally accepted the [ADBC][adbc] (Arrow Database Connectivity) specification.
ADBC is an API standard for Arrow-based database access in C/C++ (and related languages), Go, and Java.
It defines Arrow-based APIs for common database tasks, like executing queries, fetching result sets in Arrow format, and getting basic metadata about tables.

ADBC is analogous to standards like JDBC and ODBC, which define database-independent interaction APIs, and rely on drivers to implement those APIs for particular databases.
Similarly, the ADBC API standard is implemented by drivers using some underlying protocol.
This means that ADBC can abstract over Arrow-native projects, like [Arrow Flight SQL][flight-sql]; vendor-specific APIs that offer Arrow data, such as those supported by ClickHouse or Google BigQuery; and even non-columnar standards like JDBC, which are still popular.

In other words: **ADBC offers applications a simple API abstraction for getting Arrow data in and out of databases**.
Underneath, ADBC driver implementations take care of bridging the actual system, whether it's Arrow-native or not.

## Examples

We can get Arrow data out of a Postgres database in a few lines of Python:

```python
import adbc_driver_postgres.dbapi

uri = "postgres://localhost:5432/postgres?user=postgres&password=password"
with adbc_driver_postgres.dbapi.connect(uri) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer")
        table = cur.fetch_arrow_table()
```

In C++:

```cpp
```

And talking to a Flight SQL-enabled database instead:

```python
import pyarrow.flight_sql

uri = "grpc://localhost:1234"
with pyarrow.flight_sql.connect(uri) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer")
        table = cur.fetch_arrow_table()
```

Or we can pull Arrow data out of JDBC:

```java
```

## Context

Applications often use API standards like JDBC and ODBC to work with databases.
These standards are valuable because they offer a uniform API regardless of the underlying database.
Roughly speaking, a query follows the following steps:

<div align="center">
<img src="{{ site.baseurl }}/img/ADBCFlow1.svg"
     width="90%" class="img-responsive">
</div>

1. The application submits a SQL query via the JDBC/ODBC APIs.
2. The query is passed on to the driver.
3. The driver translates the query to a database-specific protocol and sends the query to the database.
4. The database executes the query and returns the result set in a database-specific format.
5. The driver translates the result format into the JDBC/ODBC API.

When Arrow data comes into play, however, cracks start to show.
JDBC is a row-oriented API, and while ODBC can be made to support columnar data, the type system and data representation is not a perfect match with Arrow.
In both cases, this leads to data conversions around steps 4–5, spending memory, CPU, and electricity without performing "useful" work.

This mismatch is more important now that several Arrow-native database systems exist, such as ClickHouse, Dremio, DuckDB, Google BigQuery, and others.
Client applications and libraries, such as Apache Spark and Pandas, want to consume columnar data from these systems, but they also want to consume data from traditional database systems.

In response, we've seen a few types of solutions.

- *Just provide JDBC/ODBC drivers*:
  these standards aren't going away, and it makes sense to provide these interfaces for applications that want them.
  But for an Arrow-native database system, the server or driver has to convert data from columns to rows, sacrificing some of the advantages of columnar data.
  And an application that wants columnar data then has to spend more time converting the data back.
- *Provide special Arrow-enabled SDKs*:
  this means client applications need to spend time to integrate with each database they use.
  (Just look at all the [connectors](https://trino.io/docs/current/connector.html) that Trino implements.)
  And it doesn't help applications that also want to work with systems that don't provide such an SDK.
- *Provide converters from JDBC/ODBC to Arrow*:
  this approach, as demonstrated by [Turbodbc][turbodbc] and [arrow-jdbc][arrow-jdbc], reduces the burden on client applications, but doesn't fundamentally solve the problem: unnecessary data conversions are still required in all cases.

ADBC combines the advantages of the latter two solutions.
The API definitions are Arrow based, and ADBC lets the actual driver use any implementation they want.
If the database is Arrow-native, that means driver can pass the data through without conversion.
Otherwise, the driver converts the data to Arrow format first.
Either way, the application doesn't have to worry about this, and can use the same API in all cases.

<div align="center">
<img src="{{ site.baseurl }}/img/ADBCFlow2.svg"
     alt="The application submits the query with the ADBC API. This is sent to a driver, that may use something like Flight SQL or libpq to talk to the database. The database responds with Arrow data, or a vendor-specific format. In the latter case, the driver converts the data to Arrow format. Then, the driver returns Arrow data to the application."
     width="90%" class="img-responsive">
</div>

## In More Detail

As mentioned, ADBC is an API standard.
You can read the [C/C++ header][adbc.h] or the [Java interfaces][adbc-core] for yourself.
The project has built several libraries around this standard:

- Driver implementations implement the API standard on top of a particular protocol or vendor.
  See the drivers for [libpq (Postgres)][adbc-libpq], [Flight SQL][adbc-flight-sql], and [JDBC][adbc-jdbc].
- The driver manager library provides an easy way to use multiple drivers from a single program, and also load drivers at runtime if desired.

This infrastructure is reusable by other drivers/vendors and accessible to other languages.
For example, the Python bindings shown above are actually generic Python bindings for any ADBC driver, courtesy of the driver manager.

ADBC builds on several existing Arrow projects.

- The [Arrow C Data Interface][c-data-interface] provides a cross-language way to pass Arrow data between ADBC implementations and ADBC users.
- [Flight SQL][flight-sql] is used to implement an ADBC driver, making Flight SQL accessible to languages like Python.
- [Nanoarrow][nanoarrow] is used to implement some ADBC drivers, making them lightweight and independent of the core Arrow libraries.

## What about {Flight RPC, Flight SQL, JDBC, ODBC, …}?

ADBC fills a specific niche that related projects do not address:

- **Arrow-native**: ADBC can pass through Arrow data with no overhead thanks to the [C Data Interface][c-data-interface].
  JDBC is row-oriented, and ODBC has implementation caveats, as discussed, that make it hard to use with Arrow.
- **Vendor-agnostic**: ADBC drivers can implement the API using any underlying protocol, while Flight SQL requires server-side support that may not be feasible to add.

Plotted along these axes, we see that ADBC is vendor-agnostic and Arrow-native, while Flight SQL is vendor-specific, and JDBC/ODBC are row-oriented:

<div align="center">
<img src="{{ site.baseurl }}/img/ADBCQuadrants.svg"
     alt="ADBC is Arrow-native and database-agnostic, while Flight SQL is Arrow-native and database-specific. JDBC and ODBC are row-oriented and database-agnostic, and wire protocols like Postgres's and SQL Server's are row-oriented and database-specific."
     width="90%" class="img-responsive">
</div>

ADBC doesn't intend to replace JDBC or ODBC in general, but we think ADBC makes more sense for applications that just want bulk columnar data access.

Similarly, within the Arrow project, ADBC does not replace Flight SQL, but instead *complements* it.
ADBC targets client applications, giving them a uniform interface to multiple database protocols and APIs—including Flight SQL.
Meanwhile, Flight SQL targets database servers, giving them a single protocol that can be implemented to simultaneously target ADBC users, [JDBC users][flight-sql-jdbc], and ODBC users.

## Conclusion/Getting Involved

In summary, ADBC works as part of the Arrow ecosystem to “cover the bases” for database interaction:

- Arrow offers a universal columnar data format,
- [Substrait][substrait] offers a universal query specification,
- ADBC offers a universal client database API,
- and Arrow Flight SQL offers a universal server database protocol.

<div align="center">
<img src="{{ site.baseurl }}/img/ADBC.svg"
     alt="ADBC abstracts over protocols and APIs like Flight SQL and JDBC for client applications. Flight SQL provides implementations of APIs like ADBC and JDBC for database servers."
     width="90%" class="img-responsive">
</div>

To start using ADBC today, see the [documentation][adbc-docs].
While it's usable already, there's still much work to do.
If you're interested in learning more or contributing, please reach out on the [mailing list][dev@arrow.apache.org] or on [GitHub Issues][adbc-issues].

ADBC was only possible with the help and involvement of several Arrow community members and projects.
In particular, members of the [DuckDB project][duckdb] and the [R DBI project][dbi] constructed prototypes based on early revisions of the standard and provided feedback on the design.

[adbc]: https://github.com/apache/arrow-adbc
[adbc-core]: https://github.com/apache/arrow-adbc/tree/main/java/core
[adbc-jdbc]: https://github.com/apache/arrow-adbc/tree/main/java/driver/jdbc
[adbc-issues]: https://github.com/apache/arrow-adbc/issues
[adbc-libpq]: https://github.com/apache/arrow-adbc/tree/main/c/driver/postgres
[adbc.h]: https://github.com/apache/arrow-adbc/blob/main/adbc.h
[arrow-jdbc]: https://arrow.apache.org/docs/java/jdbc.html
[c-data-interface]: {% link _posts/2020-05-04-introducing-arrow-c-data-interface.md %}
[dbi]: https://www.r-dbi.org/
[dev@arrow.apache.org]: https://arrow.apache.org/community/
[duckdb]: https://duckdb.org/
[flight-sql]: {% link _posts/2022-02-16-introducing-arrow-flight-sql.md %}
[flight-sql-jdbc]: TODO
[nanoarrow]: https://github.com/apache/arrow-nanoarrow
[substrait]: https://substrait.io/
[turbodbc]: https://turbodbc.readthedocs.io/en/latest/
