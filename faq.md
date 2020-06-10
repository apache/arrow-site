---
layout: default
title: FAQ
description: Frequently asked questions about the Apache Arrow project
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

# Frequently Asked Questions

## General

### What *is* Arrow?

Arrow is fundamentally a standard for how to represent columnar data in memory, along with libraries in many languages that implement that standard. By implementing the Arrow format, these libraries allow different processes, perhaps written in different languages, to share data efficiently.

In addition to serving as a universal standard for data interchange, many projects, both within the core `apache/arrow` repository and in the broader community, use Arrow as a foundation for fast data analysis.

### Why create a new standard?

## Project status

### How stable is the Arrow format? Is it safe to use in my application?

The Arrow in-memory format is considered stable, and we intend to make only backwards-compatible changes, such as additional data types. We do not yet recommend the Arrow file format for long-term disk persistence of data; that said, it is perfectly acceptable to write Arrow memory to disk for purposes of memory mapping and caching.

We encourage people to start building Arrow-based in-memory computing applications now, and choose a suitable file format for disk storage if necessary. The Arrow libraries include adapters for several file formats, including Parquet, ORC, CSV, and JSON.

## Getting started

### Where can I get Arrow libraries?

Arrow libraries for many languages are available through the usual package managers. See the [install](/install/) page for specifics.

## Getting involved

### I have some questions. How can I get help?

The [Arrow mailing lists](/community/) are the best place to ask questions. Don't be shy--we're here to help.

### I tried to use Arrow and it didn't work. Can you fix it?

Hopefully! Please make a detailed bug report--that's a valuable contribution to the project itself. See the [contribution guidelines](https://arrow.apache.org/docs/developers/contributing.html) for how to make a report.

### Arrow looks great and I'd totally use it if it only did X. When will it be done?

We use [JIRA](https://issues.apache.org/jira/browse/ARROW) for our issue tracker. Search for an issue that matches your need. If you find one, feel free to comment on it and describe your use case--that will help whoever picks up the task. If you don't find one, make it.

Ultimately, Arrow is software written by and for the community. If you don't see someone else in the community working on your issue, the best way to get it done is to pitch in yourself. We're more than willing to help you contribute successfully to the project.

### How can I report a security vulnerability?

Please send an email to [private@arrow.apache.org](mailto:private@arrow.apache.org). See the [security](/security/) page for more.

## Relation to other projects

### What is the difference between Apache Arrow and Apache Parquet?

In short, Parquet files are designed for disk storage, while Arrow is designed for in-memory use, but you can put it on disk and then memory-map later. Arrow and Parquet are intended to be compatible with each other and used together in applications.

Parquet is a columnar file format for data serialization. Reading a Parquet file requires decompressing and decoding its contents into some kind of in-memory data structure. It is designed to be space/IO-efficient at the expensive CPU utilization for decoding. It does not provide any data structures for in-memory computing. Parquet is a streaming format which must be decoded from start-to-end; while some "index page" facilities have been added to the storage format recently, random access operations are generally costly.

Arrow on the other hand is first and foremost a library providing columnar data structures for *in-memory computing*. When you read a Parquet file, you can decompress and decode the data *into* Arrow columnar data structures so that you can then perform analytics in-memory on the decoded data. The Arrow columnar format has some nice properties: random access is O(1) and each value cell is next to the previous and following one in memory, so it's efficient to iterate over.

What about "Arrow files" then? Apache Arrow defines a binary "serialization" protocol for arranging a collection of Arrow columnar arrays (called a "record batch") that can be used for messaging and interprocess communication. You can put the protocol anywhere, including on disk, which can later be memory-mapped or read into memory and sent elsewhere.

This Arrow protocol is designed so that you can "map" a blob of Arrow data without doing any deserialization, so performing analytics on Arrow protocol data on disk can use memory-mapping and pay effectively zero cost. The protocol is used for many other things as well, such as streaming data between Spark SQL and Python for running pandas functions against chunks of Spark SQL data (these are called "pandas udfs").

In some applications, Parquet and Arrow can be used interchangeably for on-disk data serialization. Some things to keep in mind:

* Parquet is intended for "archival" purposes, meaning if you write a file today, we expect that any system that says they can "read Parquet" will be able to read the file in 5 years or 7 years. We are not yet making this assertion about long-term stability of the Arrow format.
* Parquet is generally a lot more expensive to read because it must be decoded into some other data structure. Arrow protocol data can simply be memory-mapped.
* Parquet files are often much smaller than Arrow-protocol-on-disk because of the data encoding schemes that Parquet uses. If your disk storage or network is slow, Parquet may be a better choice.

### How does Arrow relate to Flatbuffers?

Flatbuffers is a domain-agnostic low-level building block for binary data formats. It cannot be used directly for data analysis tasks without a lot of manual scaffolding. Arrow is a data layer aimed directly at the needs of data analysis, providing elaborate data types (including extensible logical types), built-in support for "null" values (a.k.a "N/A"), and an expanding toolbox of I/O and computing facilities.

The Arrow file format does use Flatbuffers under the hood to facilitate low-level metadata serialization. However, Arrow data has much richer semantics than Flatbuffers data.
