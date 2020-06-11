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

Arrow is an open standard for how to represent columnar data in memory, along
with libraries in many languages that implement that standard.  The Arrow format
allows different programs and runtimes, perhaps written in different languages,
to share data efficiently using a set of rich data types (included nested
and user-defined data types).  The Arrow libraries make it easy to write such
programs, by sparing the programmer from implementing low-level details of the
Arrow format.

Arrow additionally defines a streaming format and a file format for
inter-process communication (IPC), based on the in-memory format.  It also
defines a generic client-server RPC mechanism (Arrow Flight), based on the
IPC format, and implemented on top of the gRPC framework.  <!-- TODO links -->

### Why create a new standard?

<!-- Fill this in -->

## Project status

### How stable is the Arrow format? Is it safe to use in my application?
<!-- Revise this -->

The Arrow *in-memory format* is considered stable, and we intend to make only
backwards-compatible changes, such as additional data types.  It is used by
many applications already, and you can trust that compatibility will not be
broken.

The Arrow *file format* (based on the Arrow IPC mechanism) is not recommended
for long-term disk persistence of data; that said, it is perfectly acceptable
to write Arrow memory to disk for purposes of memory mapping and caching.

We encourage people to start building Arrow-based in-memory computing
applications now, and choose a suitable file format for disk storage
if necessary. The Arrow libraries include adapters for several file formats,
including Parquet, ORC, CSV, and JSON.

### How stable are the Arrow libraries?

We refer you to the [implementation matrix](https://github.com/apache/arrow/blob/master/docs/source/status.rst).

## Getting started

### Where can I get Arrow libraries?

Arrow libraries for many languages are available through the usual package
managers. See the [install]({{ site.baseurl }}/install/) page for specifics.

## Getting involved

### I have some questions. How can I get help?

The [Arrow mailing lists]({{ site.baseurl }}/community/) are the best place
to ask questions. Don't be shy--we're here to help.

### I tried to use Arrow and it didn't work. Can you fix it?

Hopefully! Please make a detailed bug report--that's a valuable contribution
to the project itself.
See the [contribution guidelines]({{ site.baseurl }}/docs/developers/contributing.html)
for how to make a report.

### Arrow looks great and I'd totally use it if it only did X. When will it be done?

We use [JIRA](https://issues.apache.org/jira/browse/ARROW) for our issue tracker.
Search for an issue that matches your need. If you find one, feel free to
comment on it and describe your use case--that will help whoever picks up
the task. If you don't find one, make it.

Ultimately, Arrow is software written by and for the community. If you don't
see someone else in the community working on your issue, the best way to get
it done is to pitch in yourself. We're more than willing to help you contribute
successfully to the project.

### How can I report a security vulnerability?

Please send an email to [private@arrow.apache.org](mailto:private@arrow.apache.org).
See the [security]({{ site.baseurl }}/security/) page for more.

## Relation to other projects

### What is the difference between Apache Arrow and Apache Parquet?
<!-- Revise this -->

Parquet is a storage format designed for maximum space efficiency, using
advanced compression and encoding techniques.  It is ideal when wanting to
minimize disk usage while storing gigabytes of data, or perhaps more.
This efficiency comes at the cost of relatively expensive reading into memory,
as Parquet data cannot be directly operated on but must be decoded in
large chunks.

Conversely, Arrow is an in-memory format meant for direct and efficient use
for computational purposes.  Arrow data is not compressed (or only lightly so,
when using dictionary encoding) but laid out in natural format for the CPU,
so that data can be accessed at arbitrary places at full speed.

Therefore, Arrow and Parquet are not competitors: they complement each other
and are commonly used together in applications.  Storing your data on disk
using Parquet, and reading it into memory in the Arrow format, will allow
you to make the most of your computing hardware.

### What about "Arrow files" then?

Apache Arrow defines an inter-process communication (IPC) mechanism to
transfer a collection of Arrow columnar arrays (called a "record batch").
It can be used synchronously between processes using the Arrow "stream format",
or asynchronously by first persisting data on storage using the Arrow "file format".

The Arrow IPC mechanism is based on the Arrow in-memory format, such that
there is no translation necessary between the on-disk representation and
the in-memory representation.  Therefore, performing analytics on an Arrow
IPC file can use memory-mapping and pay effectively zero cost.

Some things to keep in mind when comparing the Arrow IPC file format and the
Parquet format:

* Parquet is safe for long-term storage and archival purposes, meaning if
  you write a file today, you can expect that any system that says they can
  "read Parquet" will be able to read the file in 5 years or 10 years.
  We are not yet making this assertion about long-term stability of the Arrow
  format.

* Reading Parquet files generally requires expensive decoding, while reading
  Arrow IPC files is just a matter of transferring raw bytes from the storage
  hardware.

* Parquet files are often much smaller than Arrow IPC files because of the
  elaborate encoding schemes that Parquet uses. If your disk storage or network
  is slow, Parquet may be a better choice even for short-term storage or caching.

### What about the "Feather" file format?

The Feather v1 format started as a separate specification, but the Feather v2
format is just another, easier to remember name for the Arrow IPC file format.

### How does Arrow relate to Flatbuffers?

Flatbuffers is a low-level building block for binary data serialization.
It is not adapted to the representation of large, structured, homogenous
data, and does not sit at the right abstraction layer for data analysis tasks.

Arrow is a data layer aimed directly at the needs of data analysis, providing
elaborate data types (including extensible logical types), built-in support
for "null" values (representing missing data), and an expanding toolbox of I/O
and computing facilities.

The Arrow file format does use Flatbuffers under the hood to facilitate low-level
metadata serialization, but the Arrow data format uses its own representation
for optimal access and computation.
