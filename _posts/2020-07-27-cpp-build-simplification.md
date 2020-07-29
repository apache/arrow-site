---
layout: post
title: "Making Arrow C++ Builds Simpler, Smaller, and Faster"
date: "2020-07-29 00:00:00 -0600"
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

Over the last four and a half years, we've worked to build a
"batteries-included" development platform for high-performance analytics
applications in C++. As the scope of the project has grown, we have sometimes
taken on additional library dependencies to support a wide variety of systems
and data processing tasks.

While these dependencies give us leverage on hard problems, in some cases they
have added complexity for projects that depend on Arrow. Some projects have thus
been concerned about depending on the Arrow C++ library, particularly if their
use of the Arrow library's features is limited. Indeed, in the earlier stages of
the Arrow project development, dependency management issues did cause problems
for early adopters.

We want developers to trust that they can use and depend on our libraries, and
that doing so doesn't add a burden for their own project maintenance or for
their users. Over the last year, we have undertaken a number of significant
projects to accommodate the different ways that people want to depend on Arrow
C++. We've aimed to make the build process simple by default, without requiring
special environment setup, yet also highly configurable for those who need to
specialize. This includes a *zero-dependency option* for projects that wish to use
the Arrow C++ core but take on no transitive dependencies. We've also worked to
make builds faster and more compact, even as we continue to add new
functionality.

This post covers many of the efforts we've made, both in the C++ libraries and
in the Arrow Python and R packages that depend on them. Compared to a year ago,
the build experience is much more reliable on a wider range of platforms,
requires fewer dependencies, and yields smaller package sizes.

## Minimal default build options

One rough edge for people using Arrow as a dependency was that many optional
project components were enabled in the build by default, thus requiring any
extra dependencies of those optional components. Rather than expecting users to
disable optional components one by one, we have made the default for all
optional components to be `OFF` so that the default configuration is a
dependency-free minimal core build.

The only third-party library enabled by default is
[jemalloc](http://jemalloc.net/), the project's recommended memory allocator
(except on Windows, where it is also disabled). Given that Arrow applications
often process large volumes of data, we have found additionally that using
memory allocators provided by projects like jemalloc and
[mimalloc](https://microsoft.github.io/mimalloc/) yield significantly better
performance over the default system allocators. Even so, this can also be
disabled if desired.

To demonstrate a minimal build, we have provided a
[Dockerfile](https://github.com/apache/arrow/blob/master/cpp/examples/minimal_build/Dockerfile)
which can be used to build the project requiring only CMake and a C++ compiler
with zero dependencies. Additionally, we have included an
[example](https://github.com/apache/arrow/tree/master/cpp/examples/minimal_build)
of including Arrow as an external project dependency in another CMake project.

## Flexible dependency configuration in CMake

As part of improving our CMake-based build system, we have made the
configuration of build dependencies both flexible and consistent for different
users' needs. In some cases, developers want Arrow to build against dependencies
provided by an external package manager, such as apt in Debian-based Linux
distributions. In other cases, developers may want to avoid any quirks of system
libraries and build all dependencies together with the Arrow build.

For each package, the `${Library}_SOURCE` CMake option can be set to one of three
values:

* `SYSTEM`, when the dependency is to be provided externally (such as by a Linux distribution or Homebrew)
* `BUNDLED`, when you want the dependency to be built from source while building Arrow, and then statically-linked with the resulting libraries
* `AUTO`, which tries the `SYSTEM` approach but falls back on `BUNDLED` if the dependency cannot be located

We additionally have provided `CONDA` and `BREW` source types for the common
scenarios when developers are using the conda or Homebrew package managers.
These dependency sources can be configured on an individual dependency basis or
globally using the `ARROW_DEPENDENCY_SOURCE` CMake option. `AUTO` is default,
which enables builds to be faster by using pre-built system libraries where
possible but still succeed even if all dependencies are not available on the
system.

## Reduced external dependencies

Another area of focus was to audit our dependencies. We went through and found
places where we could drop external dependencies without losing useful
functionality and without having to rewrite a lot or copy too much code into our
codebase.

We have eliminated Boost as a dependency of the core Arrow library, and in other
components (Gandiva, Parquet, etc.), the use of Boost has been greatly reduced.
In addition, when building Boost "bundled" in the Arrow build, we stripped down
the Boost package we download to the minimum needed, cutting out 90 percent of
the download size.

We vendored a few small dependencies, such as the double-conversion and
uriparser libraries, so that they do not need to be downloaded and built
separately.

We also compiled the Flatbuffers and Thrift definitions (which are needed to
implement the Arrow and Parquet formats, respectively) and checked in the
resulting C++ code to the Arrow repository. This means that Flatbuffers is no
longer a build or runtime dependency of Arrow, and we only need the Thrift C++
library, not the Thrift compiler, which has additional dependencies on flex and
bison.

## C++ library size reductions

As the C++ codebase grows in size, so too does compilation times and the amount
of binary code generated by the C++ compiler. Over the last several months, we
have begun analyzing the Arrow libraries both compile times and generated code
sizes. This has yielded both significant size reductions (more than 30 percent
code size reduction since 0.17.0). We have also restructured header files to
avoid including unneeded header files, thus lightening the load on C++ compilers
and improving compilation times.

## Python wheels

The expectation for binary wheel packages on the Python Package Index (PyPI) is
that they are self-contained and have no external dependencies except on other
Python packages. Additionally, each user of pyarrow may need different things
from the project. Some users just want to read Parquet files and convert them to
pandas data frames while others want to use
[Flight]({% post_url 2019-09-30-introducing-arrow-flight %}) for
moving around large datasets. Thus, the "pyarrow" wheel has from the beginning
of the project been a fairly comprehensive build including as many optional
components as is practical for us to maintain.

A comprehensive wheel package has some downsides: most notably for users, it is large.
Additionally, through a snafu relating to C++ shared libraries, for several
releases the wheel packages would create two copies of each C++ library on disk,
resulting in double the amount of disk usage. This has caused problems for
people using pyarrow in space-constrained environments like AWS Lambda.

In the 1.0.0 release, we have implemented some changes that have reduced the
size of the wheels (both in `.whl` form and installed on disk) by about 75 percent:

* Working around the problems resulting in two copies of each shared library being created in the site-packages directory.
* Disabling Gandiva, which required the LLVM runtime, the largest statically-linked dependency. Gandiva is still available to conda users now--it's just not included in the wheels--and we hope to package it as a separate `pyarrow-llvm` package in the future.
* Reducing the size of the C++ shared libraries as discussed above

Now pyarrow is about the size of NumPy and thus much easier for Python projects
to take on as a hard dependency without worrying about large on-disk size.

Looking ahead, we have discussed [strategies](https://issues.apache.org/jira/browse/ARROW-8518)
for breaking up pyarrow into multiple wheel packages, sort of a "hub and spoke"
model where some optional pieces are installed as separate wheels so people only
needing some "core" functionality only have to install a small package. This
would be a significant project, though, so for now we've focused on improvements
to the comprehensive wheel package.

## R packaging

Packaging Arrow for R involves similar challenges to Python wheels, though the
technical details are unique. Like how `pip install pyarrow` should just work
everywhere, so should `install.packages("arrow")` in R, and we have invested
significant effort to get there. Because the R package depends on a C++ library
in active development, this is not trivial, particularly for all of the
combinations of C++ compilers and standard libraries on Linux.

In the initial CRAN release last year, version 0.14.1, only Windows and macOS
binary packages worked out of the box. For Linux, you had to install the C++
library separately, before installing the R package. While Python wheels contain
binary libraries even on Linux, CRAN only hosts source packages that must be
compiled on the user's machine at install time. This led to an experience that
was less than ideal for Linux users.

Starting in version 0.16, a source package installation on Linux handles its C++
dependencies automatically. By default, the package executes a [bundled
script](https://github.com/apache/arrow/blob/master/r/inst/build_arrow_static.sh)
that downloads and builds the Arrow C++ library with no system dependencies
beyond what R requires. On many common Linux distributions and versions, this
can be sped up by
[setting an environment variable]({{ site.baseurl }}/docs/r/articles/install.html)
to download a prebuilt static C++ library for inclusion in the package.

To accompany these improvements and to ensure that they succeeded on a wide
range of platforms, we added
[extensive](https://github.com/apache/arrow/blob/bebcc5db3cc2890a9c53ebd53bc60863ae5ebb49/dev/tasks/tasks.yml#L1704-L1785)
[nightly builds](https://github.com/ursa-labs/arrow-r-nightly/blob/master/.github/workflows/test-binary.yml)
to our continuous integration system. These are also easily extensible--all we
need is a Docker image containing R, and we can plug new environments into our
regular nightly testing.

Since then, we've continued to improve the installation experience and look for
ways to reduce build time and package size. The C++ library improvements
discussed above help the R package since most installations of the R package
either build or otherwise include the C++ library. Within the R package itself,
we've looked for ways to include just what is needed and nothing more. These
efforts have resulted in smaller downloads and installed package sizes. From
0.17.1 to 1.0.0, installed library sizes for macOS and Windows CRAN binaries are
down 10 percent, and the prebuilt static C++ libraries for Linux are 33 percent
smaller compared to 0.16.0, despite the addition of many new features.


<!-- macOS build 0.17.1:

checking installed package size ... NOTE
  installed size is 38.1Mb
  sub-directories of 1Mb or more:
    R 3.2Mb
    libs 34.5Mb

autobrew libs on master: 8.9mb

macOS 1.0.0
checking installed package size ... NOTE
  installed size is 35.0Mb
  sub-directories of 1Mb or more:
    R 3.2Mb
    libs 31.3Mb

windows 0.17.1:
checking installed package size ... NOTE
  installed size is 27.9Mb
  sub-directories of 1Mb or more:
    R 3.2Mb
    libs 24.3Mb

windows libs on 1.0.0:
checking installed package size ... NOTE
  installed size is 24.9Mb
  sub-directories of 1Mb or more:
    R 3.2Mb
    libs 21.2Mb

ubuntu-18.04 libarrow binaries:
0.16.0.2 18.84 MB
0.17.0 	  12.81 MB
1.0.0      12.45 MB -->

## C Interface

Finally, we have observed that some projects may wish to produce or consume a
subset of the Arrow format and do not want to take on any additional code
dependencies. There are also scenarios where two libraries need to share
in-memory Arrow data structures but are unable to depend on a common Arrow
library such as the reference C++ implementation. To address these use cases, we
designed the [C Interface]({{ site.baseurl }}/docs/format/CDataInterface.html)
to provide a lightweight way to exchange Arrow data at the C level without any
memory copying.

When using the C interface, a developer populates simple C data structures that
contain the schema (data type) information about an Arrow data structure and the
addresses of the pieces of memory that constitute the data. This permits
libraries to be plugged together easily in-memory without any shared code
(except the C interface structure definitions). Most programming languages have
the ability to manipulate C structures and so this interface can even be used
without having to write or compile C code. We have used the C interface to
[transfer data structures between Python and R]({{ site.baseurl }}/docs/r/articles/python.html)
in-memory using `reticulate`.

One exciting use case for the Arrow C interface is to add Arrow import and
export to database driver libraries which often contain a C API.

## Looking ahead

As the project grows, we will continue working to make the build process as
fast and reliable as possible. If you see ways we can improve it further, or if
you run into trouble, please bring it up on our
[mailing list](https://arrow.apache.org/community/#mailing-lists) or
[report an issue](https://issues.apache.org/jira/browse/ARROW).
