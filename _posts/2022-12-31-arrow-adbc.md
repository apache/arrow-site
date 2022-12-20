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
**ADBC aims to be an columnar, minimal-overhead alternative JDBC/ODBC for analytical applications**.
It defines vendor-agnostic and Arrow-based APIs for common database tasks, like executing queries and getting basic metadata.
These APIs are available, either directly or via bindings, in C/C++, Go, Java, Python, Ruby, and soon R.

With ADBC, developers get both the benefits of using columnar Arrow data and having generic API abstractions.
Like [JDBC][jdbc]/[ODBC][odbc], ADBC defines database-independent interaction APIs, and relies on drivers to implement those APIs for particular databases.
ADBC aims to bring all of these together under a single API:

- Vendor-specific Arrow-native protocols, like [Arrow Flight SQL][flight-sql] or those offered by ClickHouse or Google BigQuery;
- Non-columnar protocols, like the PostgreSQL wire format;
- Non-columnar API abstractions, like JDBC/ODBC.

In other words: **ADBC is a single API for getting Arrow data in and out of databases**.
Underneath, ADBC driver implementations take care of bridging the actual system:

- Databases with Arrow-native protocols can directly pass data through without conversion.
- Otherwise, drivers can be built for specific row-based protocols, optimizing conversions to and from Arrow data as best as possible for particular databases.
- As a fallback, drivers can be built that convert data from JDBC/ODBC, bridging existing databases into an Arrow-native API.

In all cases, the application is saved the trouble of wrapping APIs and doing data conversions.

## Motivation

Applications often use API standards like JDBC and ODBC to work with databases.
This lets them use the same API regardless of the underlying database, saving on development time.
Roughly speaking, when an application executes a query with these APIs:

1. The application submits a SQL query via the JDBC/ODBC APIs.
2. The query is passed on to the driver.
3. The driver translates the query to a database-specific protocol and sends it to the database.
4. The database executes the query and returns the result set in a database-specific format.
5. The driver translates the result format into the JDBC/ODBC API.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBCFlow1.svg" width="90%" class="img-responsive" alt="A diagram showing the query execution flow.">
  <figcaption>The query execution flow.</figcaption>
</figure>

When columnar data comes into play, however, problems arise.
JDBC is a row-oriented API, and while ODBC can support columnar data, the type system and data representation is not a perfect match with Arrow.
In both cases, this leads to data conversions around steps 4–5, spending resources without performing "useful" work.

This mismatch is problematic for columnar database systems, such as ClickHouse, Dremio, DuckDB, and Google BigQuery.
On the client side, tools such as Apache Spark and pandas would be better off getting columnar data directly, skipping that conversion.
Meanwhile, traditional database systems aren't going away, and these clients still want to consume data from them.

In response, we've seen a few solutions:

- *Just provide JDBC/ODBC drivers*.
  These standards are here to stay, and it makes sense to provide these interfaces for applications that want them.
  But if both sides are columnar, that means converting data into rows for JDBC/ODBC, only for the client to convert them back into columns!
- *Provide converters from JDBC/ODBC to Arrow*.
  Some examples include [Turbodbc][turbodbc] and [arrow-jdbc][arrow-jdbc].
  This approach reduces the burden on client applications, but doesn't fundamentally solve the problem.
  Unnecessary data conversions are still required.
- *Provide special SDKs*.
  All of the columnar systems listed above do offer ways to get Arrow data, such as via [Arrow Flight SQL][flight-sql].
  But client applications need to spend time to integrate with each of them.
  (Just look at all the [connectors](https://trino.io/docs/current/connector.html) that Trino implements.)
  And not every system offers this option.

ADBC combines the advantages of the latter two solutions under one API.
In other words, ADBC provides a set of API definitions that client applications code to.
These API definitions are Arrow-based.
The application then links to or loads drivers for the actual database, which implement the API definitions.
If the database is Arrow-native, the driver can just pass the data through without conversion.
Otherwise, the driver converts the data to Arrow format first.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBCFlow2.svg" alt="A diagram showing the query execution flow with ADBC." width="90%" class="img-responsive">
  <figcaption>The query execution flow with two different ADBC drivers.</figcaption>
</figure>

1. The application submits a SQL query via the ADBC APIs.
2. The query is passed on to the ADBC driver.
3. The driver translates the query to a database-specific protocol and sends the query to the database.
4. The database executes the query and returns the result set in a database-specific format, which is ideally Arrow data.
5. The driver translates the result format into Arrow data if needed.

No matter what, a given application will only ever use one API, and will always get Arrow data.

## Examples

*Note: implementations are still under development, separate from the API standard itself. Examples are subject to change.*

We can get Arrow data out of a Postgres database in a few lines of Python:

```python
import adbc_driver_postgresql.dbapi

uri = "postgresql://localhost:5432/postgres?user=postgres&password=password"
with adbc_driver_postgresql.dbapi.connect(uri) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer")
        table = cur.fetch_arrow_table()
        # Process the results
```

The ADBC Python packages offer a familiar [DBAPI 2.0 (PEP 249)][pep-249]-style API, along with extensions to get Arrow data.

In Java, we can pull Arrow data out of a JDBC connection.
The ADBC driver takes care of converting the data for the application:

```java
final Map<String, Object> parameters = new HashMap<>();
parameters.put(
    AdbcDriver.PARAM_URL,
    "jdbc:postgresql://localhost:5432/postgres?user=postgres&password=password");
try (final AdbcDatabase database = JdbcDriver.INSTANCE.open(parameters);
    final AdbcConnection connection = database.connect();
    final AdbcStatement stmt = connection.createStatement()) {
  stmt.setSqlQuery("SELECT * FROM " + tableName);
  try (AdbcStatement.QueryResult queryResult = stmt.executeQuery()) {
    while (queryResult.getReader().loadNextBatch()) {
      // Process the results
    }
  }
}
```

## In More Detail

As mentioned, ADBC is an API standard.
You can read the [C/C++ header][adbc.h], [Go interfaces][adbc-go], and the [Java interfaces][adbc-core] for yourself.
The project has built several libraries around this standard:

- Driver implementations implement the API standard on top of a particular protocol or vendor.
  See the drivers for [libpq (PostgreSQL)][adbc-libpq] and [JDBC][adbc-jdbc].
- The driver manager library provides an easy way to use multiple drivers from a single program, and also load drivers at runtime if desired.

This infrastructure is reusable by other drivers/vendors and accessible to other languages.
For example, the Python bindings shown above are actually generic Python bindings for any ADBC driver, courtesy of the driver manager.

ADBC builds on several existing Arrow projects.

- The [Arrow C Data Interface][c-data-interface] provides a cross-language way to pass Arrow data between ADBC implementations and ADBC users.
- [Flight SQL][flight-sql] is used to implement an ADBC driver, making Flight SQL accessible to languages like Python.
- [Nanoarrow][nanoarrow] is used to implement some ADBC drivers, making them lightweight and independent of the core Arrow libraries.

Also, ADBC provides API support for the emerging [Substrait][substrait] specification.
Applications can pass queries either as strings (of SQL) or binary blobs (of serialized Substrait plans).

## What about {Flight RPC, Flight SQL, JDBC, ODBC, …}?

ADBC fills a specific niche that related projects do not address. It is both:

- **Arrow-native**: ADBC can pass through Arrow data with no overhead thanks to the [C Data Interface][c-data-interface].
  JDBC is row-oriented, and ODBC has implementation caveats, as discussed, that make it hard to use with Arrow.
- **Vendor-agnostic**: ADBC drivers can implement the API using any underlying protocol, while Flight SQL requires server-side support that may not be easy to add.

ADBC is both vendor-agnostic and columnar, while Flight SQL is vendor-specific, and JDBC/ODBC are (generally) row-oriented:

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
      <th scope="row">Columnar</th>
      <td class="table-success"><strong>ADBC</strong></td>
      <td>Arrow Flight SQL<br>BigQuery Storage gRPC API</td>
    </tr>
    <tr>
      <th scope="row">Row-oriented</th>
      <td>JDBC<br>ODBC (typically row-oriented)</td>
      <td>Postgres wire protocol<br>Tabular Data Stream (Microsoft SQL Server)</td>
    </tr>
  </tbody>
</table>

**ADBC doesn't intend to replace JDBC or ODBC in general**, but we think ADBC makes more sense for applications that just want bulk columnar data access.

Similarly, within the Arrow project, ADBC does not replace Flight SQL, but instead *complements* it.
ADBC gives client applications a uniform **API** to multiple database protocols and APIs—including Flight SQL.
Meanwhile, Flight SQL gives database servers a single **wire protocol** that can be implemented to simultaneously target ADBC users, [JDBC users][flight-sql-jdbc], and ODBC users.

## Conclusion/Getting Involved

In summary, ADBC works as part of the Arrow ecosystem to "cover the bases" for database interaction:

- Arrow offers a universal columnar data format,
- [Substrait][substrait] offers a universal query specification,
- ADBC offers a universal client database API,
- and Arrow Flight SQL offers a universal server database protocol.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/ADBC.svg"
       alt="ADBC abstracts over protocols and APIs like Flight SQL and JDBC for client applications. Flight SQL provides implementations of APIs like ADBC and JDBC for database servers."
       width="90%" class="img-responsive">
</figure>

To start using ADBC today, see the [repository][adbc] on how to build and install the packages, or look at the [documentation][adbc-docs] for a short tutorial.
(A formal release of the packages are still under way.)
If you're interested in learning more or contributing, please reach out on the [mailing list][dev@arrow.apache.org] or on [GitHub Issues][adbc-issues].

ADBC was only possible with the help and involvement of several Arrow community members and projects.
In particular, we would like to thank members of the [DuckDB project][duckdb] and the [R DBI project][dbi], who constructed prototypes based on early revisions of the standard and provided feedback on the design.

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
