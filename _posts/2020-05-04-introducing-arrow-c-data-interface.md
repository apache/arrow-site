---
layout: post
title: "Introducing the Apache Arrow C Data Interface"
description: "This post introduces the Arrow C Data Interface, a simple C-based
interoperability standard to simplify interactions between independent users
and implementors of the Arrow in-memory format."
date: "2020-05-04 00:00:00 +0100"
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

Apache Arrow includes a cross-language, platform-independent in-memory
[columnar format](https://arrow.apache.org/docs/format/Columnar.html)
allowing zero-copy data sharing and transfer between heterogenous runtimes
and applications.

The easiest way to use the Arrow columnar format has always been to depend
on one of the concrete implementations developed by the Apache Arrow community.
The project codebase contains libraries for 11 different programming languages
so far, and will likely grow to include more languages in the future.

However, some projects may wish to import and export the Arrow columnar format
without taking on a new library dependency, such as the Arrow C++ library.
We have therefore designed an alternative which exchanges data at the C level,
conforming to a simple data definition.  The C Data Interface carries no dependencies
except a shared C ABI between binaries which use it.  C ABIs are platform-wide standards
which are necessarily adhered to by all compilers which generate binaries and are extremely
stable, ensuring portability of libraries and executable binaries.  Two libraries that utilize
the C structures defined by the C Data Interface can do zero-copy data
transfers at runtime without any build-time or link-time dependency
requirements.

The best way to learn about the C Data Interface is to read the
[spec](https://arrow.apache.org/docs/format/CDataInterface.html).
However, we will quickly go over its strong points.

## Two simple struct definitions

To interact with the C Data Interface at the C or C++ level, the only
thing you have to include in your code is two struct type declarations
(and a couple of `#define`s for constant values).  Those declarations
only depend on standard C types, and can simply be pasted in a header
file.  Other languages can also participate as long as they provide a
Foreign Function Interface layer; this is the case for most modern
languages, such as Python (with `ctypes` or `cffi`), Julia, Rust, Go, etc.

## Zero-copy data sharing

The C Data Interface passes Arrow data buffers through memory pointers.  So,
by construction, it allows you to share data from one runtime to
another without copying it.  Since the data is in standard
[Arrow in-memory format](https://arrow.apache.org/docs/format/Columnar.html),
its layout is well-defined and unambiguous.

This design also restricts the C Data Interface to *in-process* data sharing.
For interprocess communication, we recommend use of the Arrow
[IPC format](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc).

## Reduced marshalling

The C Data Interface stays close to the natural way of expressing Arrow-like
data in C or C++.  Only two aspects involve non-trivial marshalling:

* the encoding of data types, using a very simple string-based language
* the encoding of optional metadata, using a very simple length-prefixed format

## Separate type and data representation

For applications which produce many instances of data of a single datatype
(for example, as a stream of record batches), repeatedly reconstructing the
datatype from its string encoding would represent unnecessary overhead.  To
address this use case, the C Data Interface defines two independent structures:
one representing a datatype (and optional metadata), one representing a piece
of data.

## Lifetime handling

One common difficulty of data sharing between heterogenous runtimes is to
correctly handle the lifetime of data.  The C Data Interface allows the producer
to define its own memory management scheme through a release callback.
This is a simple function pointer which consumers will call when they are
finished using the data.  For example when used as a producer the Arrow C++
library passes a release callback which simply decrements a `shared_ptr`'s
reference count.

## Application: passing data between R and Python

The R and Python Arrow libraries are both based on the Arrow C++ library,
however their respective toolchains (mandated by the R and Python packaging
standards) are ABI-incompatible.  It is therefore impossible to pass data
directly at the C++ level between the R and Python bindings.

Using the C Data Interface, we have circumvented this restriction and provide
a zero-copy data sharing API between R and Python.  It is based on the R
[`reticulate`](https://rstudio.github.io/reticulate/) library.

Here is an example session mixing R and Python library calls:

```r
library(arrow)
library(reticulate)
use_virtualenv("arrow")
pa <- import("pyarrow")

# Create an array in PyArrow
a <- pa$array(c(1, 2, 3))
a

## Array
## <double>
## [
##   1,
##   2,
##   3
## ]

# Apply R methods on the PyArrow-created array:
a[a > 1]

## Array
## <double>
## [
##   2,
##   3
## ]

# Create an array in R and pass it to PyArrow
b <- Array$create(c(5, 6, 7))
a_and_b <- pa$concat_arrays(r_to_py(list(a, b)))
a_and_b

## Array
## <double>
## [
##   1,
##   2,
##   3,
##   5,
##   6,
##   7
## ]
```
