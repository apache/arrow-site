---
layout: post
title: "Community Highlights 2025"
date: "2026-03-04 00:00:00"
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

This blog post has been created as an effort to improve the value of
an individual contributor with recognition and visibility. As per
IEEE Software paper [^1] concrete evidence of our progress and
accomplishments can help with motivation and better collaboration in
the open source community.

---

## New contributors

It has been great to see many new contributors joining the project
in the past year, with over 300 such individuals observed across the main
Apache Arrow language implementations.

| Repository/Implementation | Number of new contributors |
|---|---|
| arrow | 125 |
| arrow-rust | 131 |
| arrow-java | 28 |
| arrow-go | 35 |
<br>

Worth highlighting is [alinaliBQ](https://github.com/alinaliBQ) who
has been very active on the C++ Flight SQL ODBC Driver work together
with [justing-bq](https://github.com/justing-bq) .

[AntoinePrv](https://github.com/AntoinePrv) has done huge amount of
work on the C++ Parquet implementation and [andishgar](https://github.com/andishgar)
in the C++ Statistics area.

[rmnskb](https://github.com/rmnskb) got involved with PyArrow in
EuroPython sprints and has contributed multiple PRs since then. On the
same event [paddyroddy](https://github.com/paddyroddy) also started with
his first contribution and helped on the Python packaging side further on.

<!-- TODO: Add Rust and Go new contribs content -->

#### Notable New Contributors in apache/arrow for 2025 are:

| Author | # of prs | # of line changes (+ and -) |
|---|---|---|
| alinaliBQ | 36 | 15754 |
| andishgar | 19 | 2926 |
| AntoinePrv | 8 | 79257 |
| rmnskb | 7 | 550 |
| justing-bq | 4 | 12607 |

#### Notable New Contributors in apache/arrow-rs for 2025 are:

| Author | # of prs | # of line changes (+ and -) |
|---|---|---|
| scovich | 50 | 21006 |
| jecsand838 | 38 | 26753 |
| friendlymatthew | 33 | 7203 |
| rambleraptor | 4 | 333 |
| sdf-jkl | 4 | 388 |

#### Notable New Contributors in apache/arrow-go for 2025 are:

| Author | # of prs | # of line changes (+ and -) |
|---|---|---|
| Mandukhai-Alimaa | 6 | 1392 |
| hamilton-earthscope | 5 | 2998 |


## Release, Packaging and CI

A lot of work has been done around the Continuous Integration and
Developer Tools area. Ensuring a project with the reach of Arrow is properly working
requires validation on a huge matrix of operating systems, architectures, libraries,
versions. Needless to say that maintenance work has tremendous importance for the
health of the project and the positive contributor experience.

The most active contributors in the main repository are the ones contributing
heavily on those areas while also providing the most review capacity. Shout out
to [kou](https://github.com/kou) and [raulcd](https://github.com/raulcd).

Notable contributions worth mentioning are enhanced release automation and
reproducible builds for sources, migrating remaining AppVeyor and Azure jobs
to GitHub actions, improving dev experience with more pre-commit checks instead
of custom made linting tools.

Moving some implementations out of the main repository (apache/arrow on GitHub)
helped with easier releases and maintenance of the main repository and also of
separate language implementations. The current apache/arrow repo now holds the format
specification, C++ implementation together with all the bindings to it (Python, R, Ruby
and C GLib). Other languages now live in their own apache repos namely
[apache/arrow-java](https://github.com/apache/arrow-java),
[apache/arrow-js](https://github.com/apache/arrow-js),
[apache/arrow-rs](https://github.com/apache/arrow-rs),
[apache/arrow-go](https://github.com/apache/arrow-go),
[apache/arrow-dotnet](https://github.com/apache/arrow-dotnet) and
[apache/arrow-swift](https://github.com/apache/arrow-swift).

#### Notable Contributors in apache/arrow for 2025 are:

| Author | # of prs | # of line changes (+ and -) |
|---|---|---|
| kou | 221 | 141015 |
| AntoinePrv | 8 | 79257 |
| raulcd | 110 | 46645 |
| pitrou | 101 | 36585 |
| jbonofre | 1 | 20061 |


#### Notable Components in apache/arrow for 2025 are:

| Component label | # of merged prs | # of line changes (+ and -) |
|---|---|---|
| Parquet | 100 | 103828 |
| C++ | 387 | 82744 |
| FlightRPC | 43 | 52659 |
| CI | 237 | 42249 |
| Ruby | 74 | 20676 |


## Migration of infrastructure from Voltron Data

As Voltron Data has wind down its operations in 2025, the Arrow project
had to migrate benchmarking infrastructure and nightly report from
Voltron-managed services to Arrow managed AWS account. This work has been
driven by [rok](https://github.com/rok).

## Closing of Stale issues

[thisisnic](https://github.com/thisisnic) was working on closing of stale
issues in the apache/arrow repository which helped surfacing important
issues that were overlooked or forgotten.

## Code contributions

### C++ implementation

Community support for maintenance and development of the Acero C++
is continuing with multiple bigger contributions in 2025 done by
[pitrou](https://github.com/pitrou) and [zanmato1984](https://github.com/zanmato1984).

Many kernels have been moved from the integrated compute module into
a separate, optional package for improvement of modularity and distribution
size when optional compute functionality is not being used. The work has
been done by [raulcd](https://github.com/raulcd).

### Arrow C++ Parquet implementation

There have been multiple contributions to fix and improve fuzzing
support for Parquet. Fuzzing work is lead by [pitrou](https://github.com/pitrou)
who is also the most active member of the community guiding other
developers and supporting us with abundant review capacity.

Multiple newer types have also been supported in the last year,
namely: VARIANT, UUID, GEOMETRY and GEOGRAPHY contributed
by [neilechao](https://github.com/neilechao) and
[paleolimbot](https://github.com/paleolimbot).

An important feature added has also been Content-Defined Chunking
which improves deduplication of Parquet files with mostly identical
contents, by choosing data page boundaries based on actual contents
rather than a number of values [^2]. This work has been done by
[kszucs](https://github.com/kszucs).

There have been improvements in the Parquet encryption support for
most of the releases in the last year. These efforts have been
driven mostly by [EnricoMi](https://github.com/EnricoMi),
[pitrou](https://github.com/pitrou), [adamreeve](https://github.com/adamreeve)
and [kapoisu](https://github.com/kapoisu).

### PyArrow

A lot of work has been put into adding type annotations. It all
started in July at EuroPython sprints and the code is now ready to be 
reviewed and merged. Some more review capacity will be needed to get
this over the finish line. The work has been championed by
[rok](https://github.com/rok).

### Rust

Arrow Rust community invested heavily in the Rust parquet reader for
which they created several blog posts [^3], [^4]. The work has been
championed by [alamb](https://github.com/alamb) and
[etseidl](https://github.com/etseidl).

#### Notable Components in apache/arrow-rs for 2025 are:

| component | merged_prs | line_changes |
|---|---|---|
| parquet | 333 | 140958 |
| arrow | 436 | 76590 |
| parquet-variant | 125 | 41832 |
| api-change | 59 | 33938 |
| arrow-avro | 48 | 29487 |

### Java

Biggest changes apache/arrow-java for 2025 have been connected
to Flight and Avro components plus Sphinx support due to Java
implementation being moved into a separate apache repository.
Contributors involved in the above are [lidavidm](https://github.com/lidavidm)
and [martin-traverse](https://github.com/martin-traverse).

### Go

There has been a lot of work related to new variant type in
Parquet implementation done in apache/arrow-go all by
[zeroshade](https://github.com/zeroshade).

---

## Arrow Summit 25

One last thing to highlight would be our first Arrow Summit 25 that
was held in Paris in October 2025. The event was a great success and
it brought users, contributors and maintainers together. It
definitely was a highlight of the year for many of us. Thanks to
[raulcd](https://github.com/raulcd) and [pitrou](https://github.com/pitrou)
for organizing the event.

<!-- TODO: Would it be possible to add a group picture here? -->

---

## Thank you!

We would like to thank every single contributor to Apache Arrow for
being a part of this great community and project! Hope this blog
post helps to validate all the work you have done and motivates us
to continue collaborating and growing together!

---

<br>

The Notebooks with the analysis for this blog post can be found
in [^5].

Note not all language implementations are mentioned. Some due to being
moved into a separate repository in 2025 resulting in missing information
for large amount of merged pull requests. Others due to having lower
number of bigger contributions in the past year.


---

[^1]: [Developer Thriving: Four Sociocognitive Factors That Create Resilient Productivity on Software Teams](https://ieeexplore.ieee.org/abstract/document/10491133)
[^2]: [Parquet Content-Defined Chunking](https://huggingface.co/blog/parquet-cdc)
[^3]: [A Practical Dive Into Late Materialization in arrow-rs Parquet Reads](https://arrow.apache.org/blog/2025/12/11/parquet-late-materialization-deep-dive/)
[^4]: [3x-9x Faster Apache Parquet Footer Metadata Using a Custom Thrift Parser in Rust](https://arrow.apache.org/blog/2025/10/23/rust-parquet-metadata/)
[^5]: [arrow-maintenance/explorations](https://github.com/arrow-maintenance/explorations/tree/main/yearly_highlights)

