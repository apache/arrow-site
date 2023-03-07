---
layout: post
title: "Introducing nanoarrow"
date: "2022-12-14 00:00:00"
author: paleolimbot
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

The adoption of the
[Arrow C Data Interface](https://arrow.apache.org/docs/format/CDataInterface.html)
and the [Arrow C Stream Interface](https://arrow.apache.org/docs/format/CStreamInterface.html)
since their
[introduction](https://arrow.apache.org/blog/2020/05/03/introducing-arrow-c-data-interface/)
have been impressive and enthusiastic: not only have Arrow language bindings
adopted the standard to pass data among themselves, a growing number of
high-profile libraries like
[GDAL](https://gdal.org/development/rfc/rfc86_column_oriented_api.html) and
[DuckDB](https://duckdb.org/2021/12/03/duck-arrow.html) use the standard to
improve performance and provide an ABI-stable interface to tabular input and output.

GDAL and DuckDB are fortunate to have hard-working and forward-thinking maintainers
that were motivated to provide support for the Arrow C Data and Stream interfaces
even though the code to do so required an intimate knowledge of both the interface
and the columnar specification on which it is based.

The vision of [nanoarrow](https://github.com/apache/arrow-nanoarrow)
is that it should be trivial for a library or application to implement an Arrow-based
interface: if a library consumes or produces tabular data, Arrow should be the
first place developers look. Developers shouldn't have to be familiar with the
details of the columnar specification---nor should they have to take on any
build-time dependencies---to get started.

The [Arrow Database Connectivity (ADBC)](https://arrow.apache.org/docs/format/ADBC.html)
specification is a good example of such a project, and provided a strong
motivator for the development of nanoarrow: at the heart of ADBC is the
idea of a core "driver manager" and database-specific drivers that are distributed
as independent C/C++/Python/R/Java/Go projects. At least in R and Python,
embedding an existing Arrow implementation (e.g., Arrow C++) is challenging
in the context of multiple packages intended to be loaded into the same process.
As of this writing, ADBC includes nanoarrow-based SQLite and PostgreSQL drivers
and a nanoarrow-based validation suite for drivers.

## Using nanoarrow in C

The nanoarrow C library is distributed as
[two files (nanoarrow.h and nanoarrow.c)](https://github.com/apache/arrow-nanoarrow/tree/main/dist)
that can be copied and vendored into an existing code base. This results in
a static library of about 50  KB and builds in less than a second. Some features
that nanoarrow provides are:

* [Helpers to create types, schemas, and metadata](https://apache.github.io/arrow-nanoarrow/dev/c.html#creating-schemas)
* [Growable buffers](https://apache.github.io/arrow-nanoarrow/dev/c.html#owning-growable-buffers),
  including the option for custom allocators/deallocators.
* [Bitmap (i.e., bitpacked boolean) utilities](https://apache.github.io/arrow-nanoarrow/dev/c.html#bitmap-utilities)
* An [API for building arrays from buffers](https://apache.github.io/arrow-nanoarrow/dev/c.html#creating-arrays)
* An [API for building arrays element-wise](https://apache.github.io/arrow-nanoarrow/dev/c.html#creating-arrays)
* An [API to extract elements element-wise](https://apache.github.io/arrow-nanoarrow/dev/c.html#reading-arrays)
  from an existing array.

For example, one can build an integer array element-wise:

```c
#include "nanoarrow.h"

int make_simple_array(struct ArrowArray* array_out, struct ArrowSchema* schema_out) {
  struct ArrowError error;
  array_out->release = NULL;
  schema_out->release = NULL;

  NANOARROW_RETURN_NOT_OK(ArrowArrayInitFromType(array_out, NANOARROW_TYPE_INT32));

  NANOARROW_RETURN_NOT_OK(ArrowArrayStartAppending(array_out));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 1));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 2));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 3));
  NANOARROW_RETURN_NOT_OK(ArrowArrayFinishBuilding(array_out, &error));

  NANOARROW_RETURN_NOT_OK(ArrowSchemaInitFromType(schema_out, NANOARROW_TYPE_INT32));

  return NANOARROW_OK;
}
```

Similarly, one can extract elements from an array:

```c
#include <stdio.h>
#include "nanoarrow.h"

int print_simple_array(struct ArrowArray* array, struct ArrowSchema* schema) {
  struct ArrowError error;
  struct ArrowArrayView array_view;
  NANOARROW_RETURN_NOT_OK(ArrowArrayViewInitFromSchema(&array_view, schema, &error));

  if (array_view.storage_type != NANOARROW_TYPE_INT32) {
    printf("Array has storage that is not int32\n");
  }

  int result = ArrowArrayViewSetArray(&array_view, array, &error);
  if (result != NANOARROW_OK) {
    ArrowArrayViewReset(&array_view);
    return result;
  }

  for (int64_t i = 0; i < array->length; i++) {
    printf("%d\n", (int)ArrowArrayViewGetIntUnsafe(&array_view, i));
  }

  ArrowArrayViewReset(&array_view);
  return NANOARROW_OK;
}
```

## Using nanoarrow in C++, R, and Python

Recognizing that many projects for which nanoarrow may be useful will have
access a higher-level runtime than C, there are experiments to provide
these users with a minimal set of useful tools.

For C++ projects, an experimental
["nanoarrow.hpp"](https://apache.github.io/arrow-nanoarrow/dev/cpp.html)
interface provides `unique_ptr`-like wrappers for nanoarrow C objects to
reduce the verbosity of using the nanoarrow API. For example, the previous
`print_simple_array()` implementation would collapse to:

```cpp
#include <stdio.h>
#include "nanoarrow.hpp"

int print_simple_array2(struct ArrowArray* array, struct ArrowSchema* schema) {
  struct ArrowError error;
  nanoarrow::UniqueArrayView array_view;
  NANOARROW_RETURN_NOT_OK(ArrowArrayViewInitFromSchema(array_view.get(), schema, &error));
  NANOARROW_RETURN_NOT_OK(ArrowArrayViewSetArray(array_view.get(), array, &error));
  for (int64_t i = 0; i < array->length; i++) {
    printf("%d\n", (int)ArrowArrayViewGetIntUnsafe(array_view.get(), i));
  }
  return NANOARROW_OK;
}
```

For R packages, experimental
[R bindings](https://apache.github.io/arrow-nanoarrow/dev/r/index.html) provide
a limited set of conversions between R vectors and Arrow arrays such that
R bindings for a library with an Arrow-based interface do not need to provide
this behaviour themselves. Additional features include printing and validating
the content of the C structures at the heart of the C Data and C Stream
interfaces to facilitate the development of bindings to Arrow-based libraries.

```r
# install.packages("remotes")
remotes::install_github("apache/arrow-nanoarrow/r", build = FALSE)
library(nanoarrow)

as_nanoarrow_array(1:5)
#> <nanoarrow_array int32[5]>
#>  $ length    : int 5
#>  $ null_count: int 0
#>  $ offset    : int 0
#>  $ buffers   :List of 2
#>   ..$ :<nanoarrow_buffer_validity[0 b] at 0x0>
#>   ..$ :<nanoarrow_buffer_data_int32[20 b] at 0x135d13c28>
#>  $ dictionary: NULL
#>  $ children  : list()
```

A [Python package skeleton](https://github.com/apache/arrow-nanoarrow/tree/main/python)
exists in the nanoarrow repository and further functionality may be added once
the C library interface has stabilized.

## Try nanoarrow

The nanoarrow library is brand new and everything about it is experimental
and contingent on user feedback! For any interested in giving nanoarrow a try, the
easiest way to get started is to clone the
[nanoarrow repository from GitHub](https://github.com/apache/arrow-nanoarrow)
and build/modify the
[minimal CMake build example](https://github.com/apache/arrow-nanoarrow/tree/main/examples/cmake-minimal).
For more realistic usage, one can refer to the
[ADBC SQLite driver](https://github.com/apache/arrow-adbc/tree/main/c/driver/sqlite)
and the [ADBC PostgreSQL driver](https://github.com/apache/arrow-adbc/tree/main/c/driver/postgresql).
An initial 0.1 release is planned for January 2023.
