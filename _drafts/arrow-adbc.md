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

Over the past several months, the Arrow community has been developing the [ADBC][adbc] (Arrow Database Connectivity) standard.
Now formally accepted as part of the Arrow, ADBC is an API standard for Arrow-based database access in C/C++ (and related languages), Go, and Java.
It defines C/Go/Java APIs for common database tasks, like executing queries, fetching the result sets in Arrow format, and getting basic metadata about tables.

While the Arrow project already includes protocols like [Arrow Flight SQL][flight-sql], ADBC solves a slightly different problem.
ADBC is specifically an API standard, with multiple “drivers” that implement the API using some underlying protocol.
The client application does not have to know or care about the difference.
This means that ADBC can abstract over Arrow-native technologies, like Flight SQL, as well as vendor-specific APIs that offer Arrow data.
But ADBC can also abstract over non-columnar systems like Postgres and JDBC, which are still popular.

In other words: ADBC offers applications an easy abstraction for getting Arrow data in and out of databases.
ADBC driver implementations take care of bridging the actual system underneath, whether it's Arrow-native or not.

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

## In More Detail

As mentioned, ADBC is an API standard.
[You can read the header for yourself][adbc.h].
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
  JDBC is row-oriented, and ODBC has [implementation caveats][odbc] that make it hard to use with Arrow.
- **Vendor-agnostic**: ADBC drivers can implement the API using any underlying protocol, while Flight SQL requires server-side support that may not be feasible to add.

Plotted along these axes, we see that ADBC is vendor-agnostic and Arrow-native, while Flight SQL is vendor-specific, and JDBC/ODBC are row-oriented:

<div align="center">
<img src="{{ site.baseurl }}/img/ADBCQuadrants.svg"
     alt="ADBC is Arrow-native and database-agnostic, while Flight SQL is Arrow-native and database-specific. JDBC and ODBC are row-oriented and database-agnostic, and wire protocols like Postgres's and SQL Server's are row-oriented and database-specific."
     width="90%" class="img-responsive">
</div>

Within the Arrow project, ADBC does not replace Flight SQL, but instead *complements* it.
ADBC targets client applications, giving them a uniform interface to multiple database protocols and APIs—including Flight SQL.
Meanwhile, Flight SQL targets database servers, giving them a single protocol that can be implemented to simultaneously target ADBC users, [JDBC users][flight-sql-jdbc], and ODBC users.

<div align="center">
<img src="{{ site.baseurl }}/img/ADBC.svg"
     alt="ADBC abstracts over protocols and APIs like Flight SQL and JDBC for client applications. Flight SQL provides implementations of APIs like ADBC and JDBC for database servers."
     width="90%" class="img-responsive">
</div>

## Next Steps/Getting Involved

To start using ADBC today, see the [documentation][adbc-docs].
While it's usable already, there's still much work to do.
Drivers targeting various generic APIs and protocols, such as ODBC or TDS, would be useful, as well as drivers targeting vendor-specific protocols.
The existing drivers could use optimization work.
As for the core API standard, while ADBC tries to cover a useful set of use cases, there's likely more useful functionality that could be exposed.
If you're interested in learning more or contributing, please reach out on the [mailing list][dev@arrow.apache.org] or on [GitHub Issues][adbc-issues].

ADBC was only possible with the help and involvement of several Arrow community members and projects.
In particular, the DuckDB project .
The R DBI project .

[adbc]: https://github.com/apache/arrow-adbc
[adbc-jdbc]: https://github.com/apache/arrow-adbc/tree/main/java/driver/jdbc
[adbc-issues]: https://github.com/apache/arrow-adbc/issues
[adbc-libpq]: https://github.com/apache/arrow-adbc/tree/main/c/driver/postgres
[adbc.h]: https://github.com/apache/arrow-adbc/blob/main/adbc.h
[c-data-interface]: {% link _posts/2020-05-04-introducing-arrow-c-data-interface.md %}
[dev@arrow.apache.org]: https://arrow.apache.org/community/
[flight-sql]: {% link _posts/2022-02-16-introducing-arrow-flight-sql.md %}
[flight-sql-jdbc]: TODO
[nanoarrow]: https://github.com/apache/arrow-nanoarrow
