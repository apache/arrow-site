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

The nanoarrow library is a set of helper functions to interpret and generate
[Arrow C Data Interface](https://arrow.apache.org/docs/format/CDataInterface.html)
and [Arrow C Stream Interface](https://arrow.apache.org/docs/format/CStreamInterface.html)
structures. The library is in active early development and users should update regularly
from the main branch of this repository.

Whereas the current suite of Arrow implementations provide the basis for a
comprehensive data analysis toolkit, this library is intended to support clients
that wish to produce or interpret Arrow C Data and/or Arrow C Stream structures
where linking to a higher level Arrow binding is difficult or impossible.

## Using the C library

The nanoarrow C library is intended to be copied and vendored. This can be done using
CMake or by using the bundled nanoarrow.h/nanorrow.c distribution available in the
dist/ directory in this repository. Examples of both can be found in the examples/
directory in this repository.

A simple producer example:

```c
#include "nanoarrow.h"

int make_simple_array(struct ArrowArray* array_out, struct ArrowSchema* schema_out) {
  struct ArrowError error;
  array_out->release = NULL;
  schema_out->release = NULL;

  NANOARROW_RETURN_NOT_OK(ArrowArrayInit(array_out, NANOARROW_TYPE_INT32));

  NANOARROW_RETURN_NOT_OK(ArrowArrayStartAppending(array_out));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 1));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 2));
  NANOARROW_RETURN_NOT_OK(ArrowArrayAppendInt(array_out, 3));
  NANOARROW_RETURN_NOT_OK(ArrowArrayFinishBuilding(array_out, &error));
  
  NANOARROW_RETURN_NOT_OK(ArrowSchemaInit(schema_out, NANOARROW_TYPE_INT32));

  return NANOARROW_OK;
}
```

A simple consumer example:

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

This folder contains a project that uses the bundled nanarrow.c and nanoarrow.h
files included in the dist/ directory of this repository (or that can be generated
using `cmake -DNANOARROW_BUNDLE=ON` from the root CMake project). Like the CMake
example, you must be careful to not expose nanoarrow's header outside your project
and make use of `#define NANOARROW_NAMESPACE MyProject` to prefix nanoarrow's symbol
names to ensure they do not collide with another copy of nanoarrow potentially
linked to by another project.

The nanoarrow.c and nanoarrow.h files included in this example are stubs to illustrate
how these files could fit in to a library and/or command-line application project.
The easiest way is to use the pre-generated versions in the dist/ folder of this
repository:

```bash
git clone https://github.com/apache/arrow-nanoarrow.git
cd arrow-nanoarrow/examples/vendored-minimal
cp ../../dist/nanoarrow.h src/nanoarrow.h
cp ../../dist/nanoarrow.c src/nanoarrow.c
```

If you use these, you will have to manually `#define NANOARROW_NAMESPACE MyProject`
manually next to `#define NANOARROW_BUILD_ID` in the header.

You can also generate the bundled versions with the namespace defined using `cmake`:

```bash
git clone https://github.com/apache/arrow-nanoarrow.git
cd arrow-nanoarrow
mkdir build && cd build
cmake .. -DNANOARROW_BUNDLE=ON -DNANOARROW_NAMESPACE=ExampleVendored
cmake --build .
cmake --install . --prefix=../examples/vendored-minimal/src
```

Then you can build/link the application/library using the build tool of your choosing:

```bash
cd src
cc -c library.c nanoarrow.c
ar rcs libexample_vendored_minimal_library.a library.o nanoarrow.o
cc -o example_vendored_minimal_app app.c libexample_vendored_minimal_library.a
```

This folder contains a CMake project that links to its own copy of
nanoarrow using CMake's `FetchContent` module. Whether vendoring or
using CMake, nanoarrow is intended to be vendored or statically
linked in a way that does not expose its headers or symbols to other
projects. To illustrate this, a small library is included (library.h
and library.c) and built in this way, linked to by a program (app.c)
that does not use nanoarrow (but does make use of the Arrow C Data
interface header, since this is ABI stable and intended to be used
in this way).

To build the project:

```bash
git clone https://github.com/apache/arrow-nanoarrow.git
cd arrow-nanoarrow/examples/cmake-minimal
mkdir build && cd build
cmake ..
cmake --build .
```


I come at this, of course, as a maintainer of several R packages in the r-spatial universe, a contributor to the [arrow R package](https://arrow.apache.org/docs/r/), a huge fan of [Arrow Database Connectivity (ADBC)](https://github.com/apache/arrow-adbc), and a contributor to the [brand-new in-development nanoarrow library](https://github.com/apache/arrow-nanoarrow) whose vision is that it should be trivial for other libraries to follow in GDAL's footsteps.


I hope I've painted a picture of a future where major library after major library has made its array- and table-like outputs available as fast and friendly (streams of) `ArrowArray`s. GDAL's 3.6 release is an example of how that future can provide immediate tangible benefits to users (via speed improvements) and developers (via code portability) alike. To get to that future, I think two things have to be true:

- **Building `ArrowArray`s needs to be trivial**: GDAL is fortunate to have a talented, hard-working, and forward-thinking maintainer that implemented creating the C-data interface structures from scratch. Open source maintenance time is at a premimum and not every library maintainer has the time/motivation to do this.
- **Converting `ArrowArray`s to data frames needs to be trivial**: Again, GDAL has a talented, hard-working, and forward-thinking maintainer that implemented his own conversions from `ArrowArray` streams into Python objects; not every library is going to do this. Many libraries can use the converters provided by Arrow implementations like [pyarrow](https://arrow.apache.org/docs/python), the [arrow R package](https://arrow.apache.org/docs/r), or the [Arrow C++ library](https://arrow.apache.org/docs/cpp) that powers them both; however, the size and scope of these libraries is often a poor fit for targets like GDAL (e.g., that have considerable install complexity to manage) or ADBC (e.g., that are composed of small components distributed as independent R/Python packages).

The [nanoarrow C and C++ library](https://github.com/apache/arrow-nanoarrow) is all about building `ArrowArray`s. For example, the [ADBC Postgres driver](https://github.com/apache/arrow-adbc/tree/main/c/driver/postgres) uses nanoarrow to create `ArrowArray`s from PostgreSQL results and more nanoarrow-based drivers (e.g., for SQLite3) are [in the works](https://github.com/apache/arrow-adbc/issues/120). You can use nanoarrow in your C/C++ code by copy/pasting [two files from the nanoarrow repo](https://github.com/apache/arrow-nanoarrow/tree/main/dist); there are utilities to build data types, arrays, and streams of all kinds. It will take some iteration to realize the vision in its entirity, but the idea is simple: with minimal effort, your library can expose an Arrow-based API, with all the speed and portability that entails.

The [nanoarrow R package](https://github.com/apache/arrow-nanoarrow/tree/main/r) is all about `data.frame()` conversion from (streams of) `ArrowArray`s. The dozen or so implementations I linked to above that were all doing various forms of creating the `data.frame()` from C/C++ are all solving the same rather hard problem of converting database/GDAL data row-by-row into R vector land. If you're the hard-working maintainer of a library that just made a super fast and flexible `ArrowArray`-based interface, the nanoarrow R package helps you make that that API to R users with minimal effort. For example, the [PR implementing GDAL's columnar interface in the sf package](https://github.com/r-spatial/sf/pull/2036) that I linked to earlier uses the nanoarrow R package.

Experiments with nanoarrow in Python are ongoing...if you have ideas about what that package might look like or how it should be implemented there's [an issue just for you!](https://github.com/apache/arrow-nanoarrow/issues/53). Stay tuned to the repo for updates as we move development focus from the core C/C++ library to bindings and extensions.

