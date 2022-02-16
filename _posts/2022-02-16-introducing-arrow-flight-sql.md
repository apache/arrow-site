---
layout: post
title: "Introducing Apache Arrow Flight SQL: Accelerating Database Access"
description: "This post introduces Arrow Flight SQL, a protocol for interacting
with SQL databases over Arrow Flight. We have been working on this protocol
over the last six months, and are looking for feedback, interested
contributors, and early adopters."
date: "2022-02-16 00:00:00 -0500"
author: José Almeida, James Duong, Vinicius Fraga, Juscelino Junior, David Li, Kyle Porter, Rafael Telles
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

We would like to introduce Flight SQL, a new client-server protocol developed by the Apache Arrow community for interacting with SQL databases that makes use of the Arrow in-memory columnar format and the Flight RPC framework.

Flight SQL aims to provide broadly similar functionality to existing APIs like JDBC and ODBC, including executing queries; creating prepared statements; and fetching metadata about the supported SQL dialect, available types, defined tables, and so on.
By building on Apache Arrow, however, Flight SQL makes it easy for clients to talk to Arrow-native databases without converting data.
And by using [Flight][introducing-flight], it provides an efficient implementation of a wire format that supports features like encryption and authentication out of the box, while allowing for further optimizations like parallel data access.

While it can be directly used for database access, it is not a direct replacement for JDBC/ODBC. Instead, Flight SQL serves as a concrete wire protocol/driver implementation that can support a JDBC/ODBC driver and reduces implementation burden on databases.

<!-- mermaidjs:

graph LR
    JDBC[JDBC]
    ODBC
    FlightSQL[Flight SQL<br>libraries]
    ANA[Arrow-native app]
    DB[(Database with<br>Flight SQL endpoint)]

    JDBC --&gt; FlightSQL
    ODBC --&gt; FlightSQL
    ANA --&gt; FlightSQL

    FlightSQL --&gt;|Flight RPC| DB

-->

<div align="center">
<img src="{{ site.baseurl }}/img/20220216-flight-sql-jdbc-odbc.svg"
     alt="Illustration of where Flight SQL sits in the stack. JDBC and ODBC drivers can wrap Flight SQL, or an Arrow-native application can directly use the Flight SQL libraries. Flight SQL in turn talks over Arrow Flight to a database exposing a Flight SQL endpoint."
     width="90%" class="img-responsive">
</div>


## Motivation

While standards like [JDBC][jdbc] and [ODBC][odbc] have served users well for decades, they fall short for databases and clients which wish to use Apache Arrow or columnar data in general.
Row-based APIs like JDBC or [PEP 249][pep-249] require transposing data in this case, and for a database which is itself columnar, this means that data has to be transposed twice—once to present it in rows for the API, and once to get it back into columns for the consumer.
Meanwhile, while APIs like ODBC do provide bulk access to result buffers, this data must still be copied into Arrow arrays for use with the broader Arrow ecosystem, as implemented by projects like [Turbodbc][turbodbc].
Flight SQL aims to get rid of these intermediate steps.

Flight SQL means database servers can implement a standard interface that is designed around Apache Arrow and columnar data from the start.
Just like how Arrow provides a standard in-memory format, Flight SQL saves developers from having to design and implement an entirely new wire protocol.
As mentioned, Flight already implements features like encryption on the wire and authentication of requests, which databases do not need to re-implement.

For clients, Flight SQL provides bulk access to query results without having to convert data from another API or format.
Additionally, by pushing the work of implementing the wire protocol into the Flight and Flight SQL libraries, less code has to be written for each client language or driver.
And by using Flight underneath, clients and servers can cooperate to implement optimizations like parallel data access, [one of the original goals of Flight itself][flight-parallel].
Databases can return multiple "endpoints" to a Flight SQL client, which can then pull data from all of them in parallel, enabling the database backend to horizontally scale.

## Flight SQL Basics

Flight SQL makes full use of the Flight RPC framework and its extensibility, defining additional request/response messages via [Protobuf][protobuf].
We'll go over the Flight SQL protocol briefly, but C++ and Java already implement clients that manage much of this work.
The full [protocol][flight-sql-protocol] can be found on GitHub.

Most requests follow this pattern:
1. The client constructs a request using one of the defined Protobuf messages.
2. The client sends the request via the GetSchema RPC method (to get the schema of the response) or the GetFlightInfo RPC method (to execute the request).
3. The client makes request(s) to the endpoints returned from GetFlightInfo to get the response.

Flight SQL defines methods to query database metadata, execute queries, or manipulate prepared statements.

Metadata requests:
- CommandGetCatalogs: list catalogs in a database.
- CommandGetCrossReference: list foreign key columns that reference a particular other table.
- CommandGetDbSchemas: list schemas in a catalog.
- CommandGetExportedKeys: list foreign keys referencing a table.
- CommandGetImportedKeys: list foreign keys of a table.
- CommandGetPrimaryKeys: list primary keys of a table.
- CommandGetSqlInfo: get information about the database itself and its supported SQL dialect.
- CommandGetTables: list tables in a catalog/schema.
- CommandGetTableTypes: list table types supported (e.g. table, view, system table).

Queries:
- CommandStatementQuery: execute a one-off SQL query.
- CommandStatementUpdate: execute a one-off SQL update query.

Prepared statements:
- ActionClosePreparedStatementRequest: close a prepared statement.
- ActionCreatePreparedStatementRequest: create a new prepared statement.
- CommandPreparedStatementQuery: execute a prepared statement.
- CommandPreparedStatementUpdate: execute a prepared statement that updates data.

For example, to list all tables:

<!-- mermaidjs:

sequenceDiagram
    Client->>Server: GetFlightInfo(CommandGetTables)
    Server->>Client: FlightInfo{..., Ticket, ...}
    Client->>Server: DoGet(Ticket)
    Server->>Client: list of tables as Arrow data

-->

<div align="center">
<img src="{{ site.baseurl }}/img/20220216-flight-sql-gettables.svg"
     alt="Sequence diagram showing how to use CommandGetTables. First, the client calls the GetFlightInfo RPC method with a serialized CommandGetTables message as the argument. The server returns a FlightInfo message containing a Ticket message. The client then calls the DoGet RPC method with the Ticket as the argument, and gets back a stream of Arrow record batches containing the tables in the database."
     height="363" class="img-responsive">
</div>

To execute a query:

<!-- mermaidjs:

sequenceDiagram
    Client->>Server: GetFlightInfo(CommandStatementQuery)
    Server->>Client: FlightInfo{..., Ticket, ...}
    Client->>Server: DoGet(Ticket)
    Server->>Client: query results as Arrow data

-->

<div align="center">
<img src="{{ site.baseurl }}/img/20220216-flight-sql-query.svg"
     alt="Sequence diagram showing how to use CommandStatementQuery. First, the client calls the GetFlightInfo RPC method with a serialized CommandStatementQuery message as the argument. This message contains the SQL query. The server returns a FlightInfo message containing a Ticket message. The client then calls the DoGet RPC method with the Ticket as the argument, and gets back a stream of Arrow record batches containing the query results."
     height="363" class="img-responsive">
</div>

To create and execute a prepared statement to insert rows:

<!-- mermaidjs:

sequenceDiagram
    Client->>Server: DoAction(ActionCreatePreparedStatementRequest)
    Server->>Client: ActionCreatePreparedStatementResult
    Client->>Server: DoPut(CommandPreparedStatementUpdate)
    Client--&gt;>Server: Arrow data representing parameter values
    Server->>Client: DoPutUpdateResult
    Client->>Server: DoAction(ActionClosePreparedStatementRequest)
-->

<div align="center">
<img src="{{ site.baseurl }}/img/20220216-flight-sql-prepared.svg"
     alt="Sequence diagram showing how to use ActionCreatePreparedStatementResult. First, the client calls the DoAction RPC method with a serialized ActionCreatePreparedStatementResult message as the argument. This message contains the SQL query. The server returns a serialized ActionCreatePreparedStatementResult message containing an opaque handle for the prepared statement. The client then calls the DoPut RPC method with a CommandPreparedStatementUpdate message, containing the opaque handle, as the argument, and uploads a stream of Arrow record batches containing query parameters. The server responds with a serialized DoPutUpdateResult message containing the number of affected rows. Finally, the client calls DoAction again with ActionClosePreparedStatementRequest to clean up the prepared statement."
     height="459" class="img-responsive">
</div>

## Getting Started

Note that while Flight SQL is shipping as part of Apache Arrow 7.0.0, it is still under development, and detailed documentation is forthcoming.
However, implementations are already available in C++ and Java, which provide a low-level client that can be used as well as a server skeleton that can be implemented.

For those interested, a [server implementation wrapping Apache Derby](https://github.com/apache/arrow/blob/release-7.0.0/java/flight/flight-sql/src/test/java/org/apache/arrow/flight/sql/example/FlightSqlExample.java) and [one wrapping SQLite](https://github.com/apache/arrow/blob/release-7.0.0/cpp/src/arrow/flight/sql/example/sqlite_server.h) are available in the source.
A [simple CLI demonstrating the client](https://github.com/apache/arrow/blob/release-7.0.0/cpp/src/arrow/flight/sql/test_app_cli.cc) is also available. Finally, we can look at a brief example of executing a query and fetching results:

```cpp
flight::FlightCallOptions call_options;

// Execute the query, getting a FlightInfo describing how to fetch the results
std::cout << "Executing query: '" << FLAGS_query << "'" << std::endl;
ARROW_ASSIGN_OR_RAISE(std::unique_ptr<flight::FlightInfo> flight_info,
                      client->Execute(call_options, FLAGS_query));

// Fetch each partition sequentially (though this can be done in parallel)
for (const flight::FlightEndpoint& endpoint : flight_info->endpoints()) {
  // Here we assume each partition is on the same server we originally queried, but this
  // isn't true in general: the server may split the query results between multiple
  // other servers, which we would have to connect to.

  // The "ticket" in the endpoint is opaque to the client. The server uses it to
  // identify which part of the query results to return.
  ARROW_ASSIGN_OR_RAISE(auto stream, client->DoGet(call_options, endpoint.ticket));
  // Read all results into an Arrow Table, though we can iteratively process record
  // batches as they arrive as well
  std::shared_ptr<arrow::Table> table;
  ARROW_RETURN_NOT_OK(stream->ReadAll(&table));
  std::cout << "Read one partition:" << std::endl;
  std::cout << table->ToString() << std::endl;
}
```

The full source is [available on GitHub](https://github.com/apache/arrow/blob/master/cpp/examples/arrow/flight_sql_example.cc).

## What's Next & Getting Involved

Compared to existing libraries like PyODBC, [Arrow Flight is already as much as 20x faster][subsurface] (~00:21:00).
Flight SQL will package these performance advantages into a standard interface, ready for clients and databases to implement.

Further protocol refinements and extensions are expected.
Some of this work is to make it possible to implement APIs like JDBC on top of Flight SQL; a JDBC driver is being actively worked on.
While this again introduces the overhead of data conversion, it means a database can make itself accessible to both Arrow-native clients and traditional clients by implementing Flight SQL.
Other improvements in the future may include Python bindings, an ODBC driver, and more.

For anyone interested in getting involved, either as a contributor or adopter, please reach out on the [mailing list][mailing-lists] or join the discussion on [GitHub][github].

[flight-parallel]: {% link _posts/2019-09-30-introducing-arrow-flight.md %}#horizontal-scalability-parallel-and-partitioned-data-access
[flight-sql-protocol]: https://github.com/apache/arrow/blob/release-7.0.0/format/FlightSql.proto
[github]: https://github.com/apache/arrow
[introducing-flight]: {% link _posts/2019-09-30-introducing-arrow-flight.md %}
[jdbc]: https://docs.oracle.com/javase/8/docs/technotes/guides/jdbc/
[mailing-lists]: {% link community.md %}#mailing-lists
[odbc]: https://docs.microsoft.com/en-us/sql/odbc/reference/odbc-overview?view=sql-server-ver15
[pep-249]: https://www.python.org/dev/peps/pep-0249/
[protobuf]: https://developers.google.com/protocol-buffers/
[subsurface]: https://www.dremio.com/subsurface/arrow-flight-and-flight-sql-accelerating-data-movement/
[turbodbc]: https://turbodbc.readthedocs.io/en/latest/
