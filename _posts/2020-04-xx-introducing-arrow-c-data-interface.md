---
layout: post
title: "Introducing the Apache Arrow C data interface"
description: "This post introduces the Arrow C data interface, a simple C-based
interoperability standard to simplify interactions between independent users
and implementors of the Arrow in-memory format."
date: "2020-04-02 00:00:00 +0100"
author: apitrou
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

Apache Arrow is a cross-language, platform-independent in-memory format
allowing zero-copy data sharing and transfer between heterogenous runtimes
and applications.

The easiest way to benefit from the Arrow format has always been to depend
on one of the concrete implementations developed by the Apache Arrow community.
There are 11 such implementations, each for a different language and ecosystem
(Java, C++, Python, Rust, R, Javascript, C#, Go...).

However, packaging and ABI issues in C++ can deter from depending on the
Arrow C++ library.  We have therefore provided an alternative which
exchanges data at the C level, conforming to a simple data
definition.  The C ABI is a platform-wide standard that is unlikely to
definition.  The C ABI is a platform-wide standard that is unlikely to
change (and practically never changes), because it ensures portability of
libraries and executable binaries.

The best way to learn about the C Data Interface is to read the
[spec](https://arrow.apache.org/docs/format/CDataInterface.html).
However, we will quickly go over its strong points.

## Two simple struct definitions

To interact with the C Data Interface from you C or C++ level, the only
thing you have to include in your code is two struct type declarations
(and a couple of ``#define`` for constant values).  Those declarations
only depend on standard C types.  You can simply paste them in a header
file.

## Zero-copy data sharing

The C Data Interface passes Arrow buffers through memory pointers.  So,
by construction, it allows you to share or pass data from one runtime to
another without copying it.  Since the data is supposed to be in standard
[Arrow in-memory format](https://arrow.apache.org/docs/format/Columnar.html),
its layout is well-defined and unambiguous.

## Reduced marshalling

The C Data Interface stays close to the natural way of expressing Arrow-like
data in C or C++.  Only two aspects involve non-trivial marshalling:

* the encoding of data types, using a very simple string-based language
* the encoding of optional metadata, using a very simple length-prefixed format

## Separate type and data representation

Some applications will produce many instances of data of a single datatype
(for example, as a stream of record batches).  To allow those applications
to reduce the overhead of datatype representation and reconstruction, the
C Data Interface defines two independent structures: one representing a
datatype (and optional metadata), one representing a piece of data.

## Lifetime handling

One common difficulty of data sharing between heterogenous runtimes is to
correctly handle the lifetime of data.  The C Data Interface solves that issue
by letting the data producer define a pointer to a release callback that the
consumer must call when it has done using the data.  This way, the producer
is free to define its memory management scheme.  For example, the Arrow C++
library, when used as a producer, passes a release callback which simply
decrements a `shared_ptr`'s reference count.
