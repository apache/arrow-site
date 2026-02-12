---
layout: post
title: "Apache Arrow is 10 years old 🎉"
date: "2026-02-12 00:00:00"
author: pmc
categories: [arrow]
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

The Apache Arrow project was officially established and had its
[first git commit](https://github.com/apache/arrow/commit/d5aa7c46692474376a3c31704cfc4783c86338f2)
on February 5th 2016, and we are therefore enthusiastic to announce its 10-year
anniversary!

Looking back over these 10 years, the project has developed in many unforeseen
ways and we believe to have delivered on our objective of providing agnostic,
efficient, durable standards for the exchange of columnar data.

## How it started

From the start, Arrow has been a joint effort between practitioners of various
horizons looking to build common grounds to efficiently exchange columnar data
between different libraries and systems.
In [this blog post](https://sympathetic.ink/2024/02/06/Chapter-2-From-Parquet-to-Arrow.html),
Julien Le Dem recalls how some of the founders of the [Apache Parquet](https://parquet.apache.org/)
project participated in the early days of the Arrow design phase. The idea of Arrow
as an in-memory format was meant to address the other half of the interoperability
problem, the natural complement to Parquet as a persistent storage format.

## Apache Arrow 0.1.0

The first Arrow release, numbered 0.1.0, was tagged on October 7th 2016. It already
featured the main data types that are still the bread-and-butter of most Arrow datasets,
as evidenced in this [Flatbuffers declaration](https://github.com/apache/arrow/blob/e7080ef9f1bd91505996edd4e4b7643cc54f6b5f/format/Message.fbs#L96-L115):

```flatbuffers

/// ----------------------------------------------------------------------
/// Top-level Type value, enabling extensible type-specific metadata. We can
/// add new logical types to Type without breaking backwards compatibility

union Type {
  Null,
  Int,
  FloatingPoint,
  Binary,
  Utf8,
  Bool,
  Decimal,
  Date,
  Time,
  Timestamp,
  Interval,
  List,
  Struct_,
  Union
}
```

The [release announcement](https://lists.apache.org/thread/6ow4r2kq1qw1rxp36nql8gokgoczozgw)
made the bold claim that **"the metadata and physical data representation should
be fairly stable as we have spent time finalizing the details"**. Does that promise
hold? The short answer is: yes, almost! But let us analyse that in a bit more detail:

* the [Columnar format](https://arrow.apache.org/docs/format/Columnar.html), for
  the most part, has only seen additions of new datatypes since 2016.
  **One single breaking change** occurred: Union types cannot have a
  top-level validity bitmap anymore.

* the [IPC format](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc)
  has seen several minor evolutions of its framing and metadata format; these
  evolutions are encoded in the `MetadataVersion` field which ensures that new
  readers can read data produced by old writers. The single breaking change is
  related to the same Union validity change mentioned above.

## First cross-language integration tests

Arrow 0.1.0 had two implementations: C++ and Java, with bindings of the former
to Python. There were also no integration tests to speak of, that is, no automated
assessment that the two implementations were in sync (what could go wrong?).

Integration tests had to wait for [November 2016](https://issues.apache.org/jira/browse/ARROW-372)
to be designed, and the first [automated CI run](https://github.com/apache/arrow/commit/45ed7e7a36fb2a69de468c41132b6b3bbd270c92)
probably occurred in December of the same year. Its results cannot be fetched anymore,
so we can only assume the tests passed successfully. 🙂

From that moment, integration tests have grown to follow additions to the Arrow format,
while ensuring that older data can still be read successfully.  For example, the
integration tests that are routinely checked against multiple implementations of
Arrow have data files [generated in 2019 by Arrow 0.14.1](https://github.com/apache/arrow-testing/tree/master/data/arrow-ipc-stream/integration/0.14.1).

## No breaking changes... almost

As mentioned above, at some point the Union type lost its top-level validity bitmap,
breaking compatibility for the workloads that made use of this feature.

This change was [proposed back in June 2020](https://lists.apache.org/thread/przo99rtpv4rp66g1h4gn0zyxdq56m27)
and enacted shortly thereafter. It elicited no controversy and doesn't seem to have
caused any significant discontent among users, signaling that the feature was
probably not widely used (if at all).

Since then, there has been precisely zero breaking change in the Arrow Columnar and IPC
formats.

## Apache Arrow 1.0.0

We have been extremely cautious with version numbering and waited
[until July 2020](https://arrow.apache.org/blog/2020/07/24/1.0.0-release/)
before finally switching away from 0.x version numbers. This was signalling
to the world that Arrow had reached its "adult phase" of making formal compatibility
promises, and that the Arrow formats were ready for wide consumption amongst
the data ecosystem.

## Apache Arrow, today

Describing the breadth of the Arrow ecosystem today would take a full-fledged
article of its own, or perhaps even multiple Wikipedia pages. Our
["powered by"](https://arrow.apache.org/powered_by/) page can give a small taste.

As for the Arrow project, we will merely refer you to our official documentation:

1. [The various specifications](https://arrow.apache.org/docs/format/index.html#)
   that cater to multiple aspects of sharing Arrow data, such as
   [in-process zero-copy sharing](https://arrow.apache.org/docs/format/CDataInterface.html)
   between producers and consumers that know nothing about each other, or
   [executing database queries](https://arrow.apache.org/docs/format/ADBC.html)
   that efficiently return their results in the Arrow format.

2. [The implementation status page](https://arrow.apache.org/docs/status.html)
   that lists the implementations developed officially under the Apache Arrow
   umbrella (native software libraries for C, C++, C#, Go, Java, JavaScript,
   Julia, MATLAB, Python, R, Ruby, and Rust). But keep in mind that multiple
   third-party implementations exist in non-Apache projects, either open source
   or proprietary.

However, that is only a small part of the landscape. The Arrow project hosts
several official subprojects, such as [ADBC](https://arrow.apache.org/adbc)
and [nanoarrow](https://arrow.apache.org/nanoarrow). A notable success story is
[Apache DataFusion](https://datafusion.apache.org/), which began as an Arrow
subproject and later [graduated to become an independent top-level project](https://arrow.apache.org/blog/2024/05/07/datafusion-tlp)
in the Apache Software Foundation, reflecting the maturity and impact of the technology.

Beyond these subprojects, many third-party efforts have adopted the Arrow formats
for efficient interoperability. [GeoArrow](https://geoarrow.org/) is an impressive
example of how building on top of existing Arrow formats and implementations can
enable groundbreaking efficiency improvements in a very non-trivial problem space.

It should also be noted that Arrow, as an in-memory columnar format, is often used
hand in hand with Parquet for persistent storage; as a matter of fact, most official
Parquet implementations are nowadays being developed within Arrow repositories
(C++, Rust, Go).

## Tomorrow

The Apache Arrow community is primarily driven by consensus, and the project does
not have a formal roadmap. We will continue to welcome everyone who wishes to
participate constructively. While the specifications are stable, they still
welcome additions to cater for new use cases, as they have done in the past.

The Arrow implementations are actively maintained, gaining new features, bug fixes,
and performance improvements. We encourage people to contribute to their implementation
of choice, and to [engage with us and the community](https://arrow.apache.org/community/).

Now and going forward, a large amount of Arrow-related progress is happening
in the broader ecosystem of third-party tools and libraries. It is no longer
possible for us to keep track of all the work being done in those areas, but
we are proud to see that they are building on the same stable foundations that
have been laid 10 years ago.
