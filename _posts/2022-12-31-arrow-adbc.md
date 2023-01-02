---
layout: post
title: "Introducing ADBC: Database Access for Apache Arrow"
date: "2022-12-31 00:00:00"
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

The Arrow community would like to introduce version 1.0.0 of the [Arrow Database Connectivity (ADBC)][adbc] specification.
ADBC is a columnar, minimal-overhead alternative to JDBC/ODBC for analytical applications.
Or in other words: **ADBC is a single API for getting Arrow data in and out of different databases**.

## Motivation

Applications often use API standards like [JDBC][jdbc] and [ODBC][odbc] to work with databases.
That way, they can code to the same API regardless of the underlying database, saving on development time.
Roughly speaking, when an application executes a query with these APIs:

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBCFlow1.svg" width="90%" class="img-responsive" alt="A diagram showing the query execution flow.">
  <figcaption>The query execution flow.</figcaption>
</figure>

1. The application submits a SQL query via the JDBC/ODBC API.
2. The query is passed on to the driver.
3. The driver translates the query to a database-specific protocol and sends it to the database.
4. The database executes the query and returns the result set in a database-specific format.
5. The driver translates the result into the format required by the JDBC/ODBC API.
6. The application iterates over the result rows using the JDBC/ODBC API.

When columnar data comes into play, however, problems arise.
JDBC is a row-oriented API, and while ODBC can support columnar data, the type system and data representation is not a perfect match with Arrow.
So generally, columnar data must be converted to rows in step 5, spending resources without performing "useful" work.

This mismatch is problematic for columnar database systems, such as ClickHouse, Dremio, DuckDB, and Google BigQuery.
On the client side, tools such as Apache Spark and pandas would be better off getting columnar data directly, skipping that conversion.
Otherwise, they're leaving performance on the table.
At the same time, that conversion isn't always avoidable.
Row-oriented database systems like PostgreSQL aren't going away, and these clients will still want to consume data from them.

Developers have a few options:

- *Just use JDBC/ODBC*.
  These standards are here to stay, and it makes sense for databases to support them for applications that want them.
  But when both the database and the application are columnar, that means converting data into rows for JDBC/ODBC, only for the client to convert them right back into columns!
  Performance suffers, and developers have to spend time implementing the conversions.
- *Use JDBC/ODBC-to-Arrow conversion libraries*.
  Libraries like [Turbodbc][turbodbc] and [arrow-jdbc][arrow-jdbc] handle row-to-columnar conversions for clients.
  But this doesn't fundamentally solve the problem.
  Unnecessary data conversions are still required.
- *Use vendor-specific protocols*.
  For some databases, applications can use a database-specific protocol or SDK to directly get Arrow data.
  For example, applications could use Dremio via [Arrow Flight SQL][flight-sql].
  But client applications that want to support multiple database vendors would need to integrate with each of them.
  (Look at all the [connectors](https://trino.io/docs/current/connector.html) that Trino implements.)
  And databases like PostgreSQL don't offer an option supporting Arrow in the first place.

As is, clients must choose between either tedious integration work or leaving performance on the table. We can make this better.

## Introducing ADBC

ADBC is an Arrow-based, vendor-netural API for interacting with databases.
Applications that use ADBC receive Arrow data.
They don't have to do any conversions themselves, and they don't have to integrate each database's specific SDK.

Just like JDBC/ODBC, underneath the ADBC API are drivers that translate the API for specific databases.

* A driver for an Arrow-native database just passes Arrow data through without conversion.
* A driver for a non-Arrow-native database must convert the data to Arrow.
  This saves the application from doing that, and the driver can optimize the conversion for its database.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBCFlow2.svg" alt="A diagram showing the query execution flow with ADBC." width="90%" class="img-responsive">
  <figcaption>The query execution flow with two different ADBC drivers.</figcaption>
</figure>

1. The application submits a SQL query via the ADBC API.
2. The query is passed on to the ADBC driver.
3. The driver translates the query to a database-specific protocol and sends the query to the database.
4. The database executes the query and returns the result set in a database-specific format, which is ideally Arrow data.
5. If needed: the driver translates the result into Arrow data.
6. The application iterates over batches of Arrow data.

The application only deals with one API, and only works with Arrow data.

ADBC API and driver implementations are under development. For example, in Python, the ADBC packages offer a familiar [DBAPI 2.0 (PEP 249)][pep-249]-style interface, with extensions to get Arrow data.
We can get Arrow data out of PostgreSQL easily:

```python
import adbc_driver_postgresql.dbapi

uri = "postgresql://localhost:5432/postgres?user=postgres&password=password"
with adbc_driver_postgresql.dbapi.connect(uri) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer")
        table = cur.fetch_arrow_table()
        # Process the results
```

Or SQLite:

```python
import adbc_driver_sqlite.dbapi

uri = "file:mydb.sqlite"
with adbc_driver_sqlite.dbapi.connect(uri) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer")
        table = cur.fetch_arrow_table()
        # Process the results
```

*Note: implementations are still under development. See the [documentation][adbc-docs] for up-to-date examples.*

## What about {Flight SQL, JDBC, ODBC, …}?

ADBC fills a specific niche that related projects do not address. It is both:

- **Arrow-native**: ADBC can pass through Arrow data with no overhead thanks to the [C Data Interface][c-data-interface].
  JDBC is row-oriented, and ODBC has implementation caveats, as discussed, that make it hard to use with Arrow.
- **Vendor-agnostic**: ADBC drivers can implement the API using any underlying protocol, while Flight SQL requires server-side support that may not be easy to add.

<table class="table table-hover" style="table-layout: fixed">
  <caption>Comparing database APIs and protocols</caption>
  <thead class="thead-dark">
    <tr>
      <th></th>
      <th class="align-top" style="width: 40%" scope="col">Vendor-neutral (database APIs)</th>
      <th class="align-top" style="width: 40%" scope="col">Vendor-specific (database protocols)</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <th scope="row">Arrow-native</th>
      <td class="table-success"><strong>ADBC</strong></td>
      <td>Arrow Flight SQL<br>BigQuery Storage gRPC protocol</td>
    </tr>
    <tr>
      <th scope="row">Row-oriented</th>
      <td>JDBC<br>ODBC (typically row-oriented)</td>
      <td>PostgreSQL wire protocol<br>Tabular Data Stream (Microsoft SQL Server)</td>
    </tr>
  </tbody>
</table>

**ADBC doesn't intend to replace JDBC or ODBC in general**.
But for applications that just want bulk columnar data access, ADBC lets them avoid data conversion overhead and tedious integration work.

Similarly, within the Arrow project, ADBC does not replace Flight SQL, but instead *complements* it.
ADBC is an **API** that lets *clients* work with different databases easily.
Meanwhile, Flight SQL is a **wire protocol** that *database servers* can implement to simultaneously support ADBC, [JDBC][flight-sql-jdbc], and ODBC users.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBC.svg"
       alt="ADBC abstracts over protocols and APIs like Flight SQL and JDBC for client applications. Flight SQL provides implementations of APIs like ADBC and JDBC for database servers."
       width="90%" class="img-responsive">
</figure>

## Getting Involved

ADBC works as part of the Arrow ecosystem to "cover the bases" for database interaction:

- Arrow offers a universal columnar data format,
- Arrow Flight SQL offers a universal wire protocol for database servers,
- and ADBC offers a universal API for database clients.

To start using ADBC, see the [documentation][adbc-docs] for build instructions and a short tutorial.
(A formal release of the packages is still under way.)
If you're interested in learning more or contributing, please reach out on the [mailing list][dev@arrow.apache.org] or on [GitHub Issues][adbc-issues].

ADBC was only possible with the help and involvement of several Arrow community members and projects.
In particular, we would like to thank members of the [DuckDB project][duckdb] and the [R DBI project][dbi], who constructed prototypes based on early revisions of the standard and provided feedback on the design.
And ADBC builds on existing Arrow projects, including the [Arrow C Data Interface][c-data-interface] and [nanoarrow][nanoarrow].

Thanks to Fernanda Foertter for assistance with some of the diagrams.

[adbc]: https://github.com/apache/arrow-adbc
[adbc-core]: https://github.com/apache/arrow-adbc/tree/main/java/core
[adbc-docs]: https://arrow.apache.org/adbc/
[adbc-go]: https://github.com/apache/arrow-adbc/blob/main/go/adbc/adbc.goin/
[adbc-jdbc]: https://github.com/apache/arrow-adbc/tree/main/java/driver/jdbc
[adbc-issues]: https://github.com/apache/arrow-adbc/issues
[adbc-libpq]: https://github.com/apache/arrow-adbc/tree/main/c/driver/postgresql
[adbc.h]: https://github.com/apache/arrow-adbc/blob/main/adbc.h
[arrow-jdbc]: https://arrow.apache.org/docs/java/jdbc.html
[c-data-interface]: {% link _posts/2020-05-04-introducing-arrow-c-data-interface.md %}
[dbi]: https://www.r-dbi.org/
[dev@arrow.apache.org]: https://arrow.apache.org/community/
[duckdb]: https://duckdb.org/
[flight-sql]: {% link _posts/2022-02-16-introducing-arrow-flight-sql.md %}
[flight-sql-jdbc]: {% link _posts/2022-11-01-arrow-flight-sql-jdbc.md %}
[jdbc]: https://docs.oracle.com/javase/tutorial/jdbc/overview/index.html
[nanoarrow]: https://github.com/apache/arrow-nanoarrow
[odbc]: https://learn.microsoft.com/en-us/sql/odbc/reference/what-is-odbc?view=sql-server-ver16
[pep-249]: https://www.python.org/dev/peps/pep-0249/
[substrait]: https://substrait.io/
[turbodbc]: https://turbodbc.readthedocs.io/en/latest/
[why-arrow]: {% link faq.md %}#why-define-a-standard-for-columnar-in-memory
