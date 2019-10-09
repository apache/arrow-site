---
layout: post
title: "Introducing Apache Arrow Flight: A Framework for Fast Data Transport"
description: "This post introduces Arrow Flight, a framework for building high
performance data services. We have been building Flight over the last 18 months
and are looking for developers and users to get involved."
date: "2019-10-09 00:00:00 -0600"
author: Wes McKinney
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

Over the last 18 months, the Apache Arrow community has been busy designing and
implementing **Flight**, a new general-purpose client-server framework to
simplify high performance transport of large datasets over network interfaces.

Flight initially is focused on optimized transport of the Arrow columnar format
(i.e. "Arrow record batches") over [gRPC][1], Google's popular HTTP/2-based
general-purpose RPC library and framework. While we have focused on integration
with gRPC, as a development framework Flight is not intended to be exclusive to
gRPC.

In the upcoming 0.15.0 Apache Arrow release, we have developed Flight
implementations in C++ (with Python bindings) and Java. These libraries are
ready for beta users who are comfortable being on the bleeding edge while we
continue to refine some low-level details in the Flight internals.

## Motivation

Many people have experienced the pain associated with accessing large datasets
over a network. There are many different transfer protocols and tools for
reading datasets from remote data services, such as ODBC and JDBC. Over the
last 10 years, file-based data warehousing in formats like CSV, Avro, and
Parquet has become popular, but this also presents challenges as raw data must
be transferred to local hosts before being deserialized.

The work we have done since the beginning of Apache Arrow holds exciting
promise for accelerating data transport in a number of ways. The [Arrow
columnar format][2] has key features that can help us:

* It is an "on-the-wire" representation of tabular data that does not require
  deserialization on receipt
* Its natural mode is that of "streaming batches", larger datasets are
  transported a batch of rows at a time (called "record batches" in Arrow
  parlance). In this post we will talk about "data streams", these are
  sequences of Arrow record batches using the project's binary protocol
* The format is language-independent and now has library support in 11
  languages and counting. For

Implementations of standard protocols like ODBC generally implement their own
custom on-wire binary protocols that must be marshalled to and from each
library's public interface. The performance of ODBC or JDBC libraries varies
greatly from case to case.

Our design goal for Flight is to create a new protocol for data services that
uses the Arrow columnar format as both the over-the-wire data representation as
well as the public API presented to developers. In doing so, we reduce or
remove the serialization costs associated with data transport and increase the
overall efficiency of distributed data systems. Additionally, two systems that
are already using Apache Arrow for other purposes can communicate data to each
other with extreme efficiency.

## Flight Basics

The Arrow Flight libraries provide a development framework for implementing a
service that can send and receive data streams. A Flight server supports
several basic kinds of requests:

* **ListFlights**: return a list of available data streams
* **GetSchema**: return the schema for a data stream
* **GetFlightInfo**: return a "query plan" for a dataset of interest, possibly
  requiring consuming multiple data streams
* **DoGet**: send a data stream to a client
* **DoPut**: receive a data stream from a client
* **DoAction**: a perform an implementation-specific action and
  return any results, i.e. a generalized function call
* **ListActions**: return a list of available action types

A simple Flight setup might consist of a single server to which clients connect
and make DoGet requests.

FIGURE

## Optimizing Data Throughput over gRPC

While using a general-purpose messaging library like gRPC has numerous specific
benefits beyond the obvious ones (taking advantage of all the engineering that
Google has done on the problem).

The best-supported way to use gRPC is to define services using an extended
version of [Protocol Buffers][3] aka "Protobuf". A Protobuf plugin for gRPC
generates a gRPC service that you can implement in your applications. RPC
commands and data messages are serialized using the [Protobuf wire
format][4]. Because we use "vanilla gRPC and Protocol Buffers", gRPC clients
that are ignorant of the Arrow columnar format can still interact with Flight
services and handle the Arrow data opaquely.

The main data-related Protobuf type in Flight is called `FlightData`. Reading
and writing Protobuf messages in general is not free, so we implemented some
low-level optimizations in gRPC in both C++ and Java to do the following:

* Generate the Protobuf wire format for `FlightData` including the Arrow record
  batch being sent without going through any intermediate memory copying or
  serialization steps.
* Reconstruct a Arrow record batch from the Protobuf representation of
  `FlightData` without any memory copying or deserialization.

In a sense we are "having our cake and eat it, too". Flight implementations
having these optimizations will have better performance, while naive gRPC
clients talking to the Flight service can still use a Protobuf library to
deserialize `FlightData` (with some performance penalty).

## Horizontal Scalability: Parallel and Partitioned Data Access

## Actions: Extending Flight with application business logic

## Security and Authentication

## Tracing and Middleware

## gRPC, but not only gRPC

[1]: https://grpc.io/
[2]: https://github.com/apache/arrow/blob/master/docs/source/format/Columnar.rst
[3]: https://github.com/protocolbuffers/protobuf
[4]: https://developers.google.com/protocol-buffers/docs/encoding
[5]: https://github.com/apache/arrow/blob/apache-arrow-0.15.0/format/Flight.proto#L291