---
layout: article
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

<hr class="mt-4 mb-3">

## General

#### **What *is* Apache Arrow?**

Apache Arrow is a software development platform for building high performance
applications that process and transport large data sets. It is designed to both
improve the performance of analytical algorithms and the efficiency of moving
data from one system (or programming language to another).

A critical component of Apache Arrow is its **in-memory columnar format**, a
standardized, language-agnostic specification for representing structured,
table-like datasets in-memory. This data format has a rich data type system
(included nested and user-defined data types) designed to support the needs of
analytic database systems, data frame libraries, and more.

The project also contains implementations of the Arrow columnar format in many
languages, along with utilities for reading and writing it to many common
storage formats.  These official libraries enable third-party projects to work
with Arrow data without having to implement the Arrow columnar format
themselves.  For those that want to implement a small subset of the format, the
Arrow project contains some tools, such as a C data interface, to assist with
interoperability with the official Arrow libraries.

The Arrow libraries contain many software components that assist with systems
problems related to getting data in and out of remote storage systems and
moving Arrow-formatted data over network interfaces. Some of these components
can be used even in scenarios where the columnar format is not used at all.

Lastly, alongside software that helps with data access and IO-related issues,
there are libraries of algorithms for performing analytical operations or
queries against Arrow datasets.

#### **Why define a standard for columnar in-memory?**

Traditionally, data processing engine developers have created custom data
structures to represent datasets in-memory while they are being
processed. Given the "custom" nature of these data structures, they must also
develop serialization interfaces to convert between these data structures and
different file formats, network wire protocols, database clients, and other
data transport interface. The net result of this is an incredible amount of
waste both in developer time and in CPU cycles spend serializing data from one
format to another.

The rationale for Arrow's in-memory columnar data format is to provide an
out-of-the-box solution to several interrelated problems:

* A general purpose tabular data representation that is highly efficient to
  process on modern hardware while also being suitable for a wide spectrum of
  use cases. We believe that fewer and fewer systems will create their own data
  structures and simply use Arrow.
* Supports both random access and streaming / scan-based workloads.
* A standardized memory format facilitates reuse of libraries of
  algorithms. When custom in-memory data formats are used, common algorithms
  must often be rewritten to target those custom data formats.
* Systems that both use or support Arrow can transfer data between them at
  little-to-no cost. This results in a radical reduction in the amount of
  serialization overhead in analytical workloads that can often represent
  80-90% of computing costs.
* The language-agnostic design of the Arrow format enables systems written in
  different programming languages (even running on the JVM) to communicate
  datasets without serialization overhead. For example, a Java application can
  call a C or C++ algorithm on data that originated in the JVM.

<hr class="my-5">

## Project status

#### **How stable is the Arrow format? Is it safe to use in my application?**

The Arrow columnar format and protocol is considered stable, and we intend to
make only backwards-compatible changes, such as additional data types.  It is
used by many applications already, and you can trust that compatibility will
not be broken. See [the documentation]({{ site.baseurl
}}/docs/format/Versioning.html) for details on Arrow format versioning and
stability.

#### **How stable are the Arrow libraries?**

We refer you to the [implementation matrix]({{ site.baseurl }}/docs/status.html).

#### **MIME types (IANA Media types) for Arrow data**

Official IANA Media types (MIME types) have been registered for Apache
Arrow IPC protocol data, both stream and file variants:

* <https://www.iana.org/assignments/media-types/application/vnd.apache.arrow.stream>
* <https://www.iana.org/assignments/media-types/application/vnd.apache.arrow.file>

We recommend ".arrow" as the IPC file format file extension:

* <https://arrow.apache.org/docs/format/Columnar.html#ipc-file-format>

and ".arrows" for the IPC streaming format file extension:

* <https://arrow.apache.org/docs/format/Columnar.html#ipc-streaming-format>

<hr class="my-5">

## Getting started

#### **Where can I get Arrow libraries?**

Arrow libraries for many languages are available through the usual package
managers. See the [install]({{ site.baseurl }}/install/) page for specifics.

<hr class="my-5">

## Getting involved

#### **I have some questions. How can I get help?**

The [Arrow mailing lists]({{ site.baseurl }}/community/) are the best place
to ask questions. Don't be shy--we're here to help.

#### **I tried to use Arrow and it didn't work. Can you fix it?**

Hopefully! Please make a detailed bug report--that's a valuable contribution to
the project itself.  See the [contribution guidelines]({{ site.baseurl
}}/docs/developers/contributing.html) for how to make a report.

#### **Arrow looks great and I'd totally use it if it only did X. When will it be done?**

We use [JIRA](https://issues.apache.org/jira/browse/ARROW) for our issue
tracker.  Search for an issue that matches your need. If you find one, feel
free to comment on it and describe your use case--that will help whoever picks
up the task. If you don't find one, make it.

Ultimately, Arrow is software written by and for the community. If you don't
see someone else in the community working on your issue, the best way to get it
done is to pitch in yourself. We're more than willing to help you contribute
successfully to the project.

#### **How can I report a security vulnerability?**

Please send an email to [private@arrow.apache.org](mailto:private@arrow.apache.org).
See the [security]({{ site.baseurl }}/security/) page for more.

<hr class="my-5">

## Relation to other projects

#### **What is the difference between Apache Arrow and Apache Parquet?**

Parquet is not a "runtime in-memory format"; in general, file formats almost
always have to be deserialized into some in-memory data structure for
processing. We intend for Arrow to be that in-memory data structure.

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

Therefore, Arrow and Parquet complement each other
and are commonly used together in applications.  Storing your data on disk
using Parquet and reading it into memory in the Arrow format will allow
you to make the most of your computing hardware.

#### **What about "Arrow files" then?**

Apache Arrow defines an inter-process communication (IPC) mechanism to
transfer a collection of Arrow columnar arrays (called a "record batch").
It can be used synchronously between processes using the Arrow "stream format",
or asynchronously by first persisting data on storage using the Arrow "file format".

The Arrow IPC mechanism is based on the Arrow in-memory format, such that
there is no translation necessary between the on-disk representation and
the in-memory representation.  Therefore, performing analytics on an Arrow
IPC file can use memory-mapping, avoiding any deserialization cost and extra copies.

Some things to keep in mind when comparing the Arrow IPC file format and the
Parquet format:

* Parquet is designed for long-term storage and archival purposes, meaning if
  you write a file today, you can expect that any system that says they can
  "read Parquet" will be able to read the file in 5 years or 10 years.
  While the Arrow on-disk format is stable and will be readable by future
  versions of the libraries, it does not prioritize the requirements of
  long-term archival storage.

* Reading Parquet files generally requires efficient yet relatively complex
  decoding, while reading Arrow IPC files does not involve any decoding because
  the on-disk representation is the same as the in-memory representation.

* Parquet files are often much smaller than Arrow IPC files because of the
  columnar data compression strategies that Parquet uses. If your disk storage or network
  is slow, Parquet may be a better choice even for short-term storage or caching.

#### **What about the "Feather" file format?**

The Feather v1 format was a simplified custom container for writing a subset of
the Arrow format to disk prior to the development of the Arrow IPC file format.
"Feather version 2" is now exactly the Arrow IPC file format and we have
retained the "Feather" name and APIs for backwards compatibility.

#### **How does Arrow relate to Protobuf?**

Google's protocol buffers library (Protobuf) is not a "runtime in-memory
format."  Similar to Parquet, Protobuf's representation is not suitable for
processing.  Data must be deserialized into an in-memory representation like
Arrow for processing.

For example, unsigned integers in Protobuf are encoded as varint where each
integer could have a different number of bytes and the last three bits
contain the wire type of the field.  You could not use a CPU to add numbers
in this format.

Protobuf has libraries to do this deserialization but they do not aim for a
common in-memory format.  A message that has been deserialized by protoc
generated C# code is not going to have the same representation as one that has
been deserialized by protoc generated Java code.  You would need to marshal
the data from one language to the other.

Arrow avoids this but it comes at the cost of increased space.
Protobuf can be a better choice for serializing certain kinds of data
on the wire (like individual records or sparse data with many optional
fields).  Just like Parquet this means that Arrow and Protobuf
complement each other well.  For example, Arrow Flight uses gRPC and
Protobuf to serialize its commands, while data is serialized using the
binary Arrow IPC protocol.

#### **How does Arrow relate to Flatbuffers?**

Flatbuffers is a low-level building block for binary data serialization.
It is not adapted to the representation of large, structured, homogenous
data, and does not sit at the right abstraction layer for data analysis tasks.

Arrow is a data layer aimed directly at the needs of data analysis, providing a
comprehensive collection of data types required to analytics, built-in support
for "null" values (representing missing data), and an expanding toolbox of I/O
and computing facilities.

The Arrow file format does use Flatbuffers under the hood to serialize schemas
and other metadata needed to implement the Arrow binary IPC protocol,
but the Arrow data format uses its own representation
for optimal access and computation.
