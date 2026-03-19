---
layout: post
title: "Community Highlights 2025"
date: "2026-03-19 00:00:00"
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

As you may have read in a previous blog post [^1], the Apache Arrow project
recently turned 10 years old. We are grateful to everyone who helped us
achieve this milestone, and we wanted to celebrate the community's
accomplishments, by publishing our community highlights from 2025.

We were inspired by the research by Dr Cat Hicks et al [^2], who found
that concrete evidence of progress and accomplishments is instrumental
to motivation and collaboration in developer teams. We think the same
should hold for open source.

---

## New contributors

It has been great to see many new contributors joining the project
in the past year, with over 300 such individuals observed across the main
Apache Arrow language implementations.

<table class="table">
  <caption>Number of new contributors per repository.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Repository/Implementation</th>
      <th>Number of new contributors</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>arrow</td>
      <td>125</td>
    </tr>
    <tr>
      <td>arrow-rs</td>
      <td>132</td>
    </tr>
    <tr>
      <td>arrow-java</td>
      <td>28</td>
    </tr>
    <tr>
      <td>arrow-go</td>
      <td>35</td>
    </tr>
  </tbody>
</table>

Worth highlighting is [alinaliBQ](https://github.com/alinaliBQ) who
has been very active on the C++ Flight SQL ODBC Driver work together
with [justing-bq](https://github.com/justing-bq).

[AntoinePrv](https://github.com/AntoinePrv) has done a huge amount of
work on the C++ Parquet implementation and [andishgar](https://github.com/andishgar)
in the C++ Statistics area.

[rmnskb](https://github.com/rmnskb) got involved with PyArrow in
EuroPython sprints and has contributed multiple PRs since then. On the
same event [paddyroddy](https://github.com/paddyroddy) also started with
his first contribution and helped on the Python packaging side further on.


[sdf-jkl](https://github.com/sdf-jkl), [liamzwbao](https://github.com/liamzwbao),
[friendlymatthew](https://github.com/friendlymatthew), and
[klion26](https://github.com/klion26) helped drive early Variant
functionality in the Rust Parquet implementation and contributed a number
of follow-up improvements.

[jecsand838](https://github.com/jecsand838) drove major improvements to the
Rust `arrow-avro` crate, work highlighted in the
[Introducing Arrow Avro](https://arrow.apache.org/blog/2025/10/23/introducing-arrow-avro/)
blog post.

<table class="table">
  <caption>Notable New Contributors in apache/arrow for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Author</th>
      <th>Number of prs</th>
      <th>Number of line changes (+ and -)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>alinaliBQ</td>
      <td>36</td>
      <td>15754</td>
    </tr>
    <tr>
      <td>andishgar</td>
      <td>19</td>
      <td>2926</td>
    </tr>
    <tr>
      <td>AntoinePrv</td>
      <td>8</td>
      <td>79257</td>
    </tr>
    <tr>
      <td>rmnskb</td>
      <td>7</td>
      <td>550</td>
    </tr>
    <tr>
      <td>justing-bq</td>
      <td>4</td>
      <td>12607</td>
    </tr>
  </tbody>
</table>

<table class="table">
  <caption>Notable New Contributors in apache/arrow-rs for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Author</th>
      <th>Number of prs</th>
      <th>Number of line changes (+ and -)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>scovich</td>
      <td>50</td>
      <td>21006</td>
    </tr>
    <tr>
      <td>jecsand838</td>
      <td>38</td>
      <td>26753</td>
    </tr>
    <tr>
      <td>friendlymatthew</td>
      <td>33</td>
      <td>7203</td>
    </tr>
    <tr>
      <td>sdf-jkl</td>
      <td>4</td>
      <td>388</td>
    </tr>
    <tr>
      <td>rambleraptor</td>
      <td>4</td>
      <td>333</td>
    </tr>
  </tbody>
</table>

<table class="table">
  <caption>Notable New Contributors in apache/arrow-go for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Author</th>
      <th>Number of prs</th>
      <th>Number of line changes (+ and -)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Mandukhai-Alimaa</td>
      <td>6</td>
      <td>1392</td>
    </tr>
    <tr>
      <td>hamilton-earthscope</td>
      <td>5</td>
      <td>2998</td>
    </tr>
  </tbody>
</table>


## Release, Packaging and CI

A lot of work has been done around the Continuous Integration and
Developer Tools area. Ensuring a project with the reach of Arrow is properly working
requires validation on a huge matrix of operating systems, architectures, libraries,
versions. Needless to say that maintenance work has tremendous importance for the
health of the project and the positive contributor experience.

The most active contributors in the main repository are the ones contributing
heavily on those areas while also providing the most review capacity. Shout out
to [kou](https://github.com/kou) and [raulcd](https://github.com/raulcd) for
taking such good care of the project and devoting countless hours so that everything
runs smoothly.

Notable contributions worth mentioning are enhanced release automation and
reproducible builds for sources, migrating remaining AppVeyor and Azure jobs
to GitHub actions, improving dev experience with more pre-commit checks instead
of custom made linting tools.

Moving some implementations out of the main repository (apache/arrow on GitHub)
helped with easier releases and maintenance of the main repository and also of
separate language implementations. The current apache/arrow repo now holds the format
specification, C++ implementation together with all the bindings to it (Python, R, Ruby
and C GLib). Other languages now live in their own apache/ repos namely
[apache/arrow-java](https://github.com/apache/arrow-java),
[apache/arrow-js](https://github.com/apache/arrow-js),
[apache/arrow-rs](https://github.com/apache/arrow-rs),
[apache/arrow-go](https://github.com/apache/arrow-go),
[apache/arrow-nanoarrow](https://github.com/apache/arrow-nanoarrow),
[apache/arrow-dotnet](https://github.com/apache/arrow-dotnet) and
[apache/arrow-swift](https://github.com/apache/arrow-swift).

<table class="table">
  <caption>Notable Contributors in apache/arrow for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Author</th>
      <th>Number of prs</th>
      <th>Number of line changes (+ and -)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>kou</td>
      <td>221</td>
      <td>141015</td>
    </tr>
    <tr>
      <td>AntoinePrv</td>
      <td>8</td>
      <td>79257</td>
    </tr>
    <tr>
      <td>raulcd</td>
      <td>110</td>
      <td>46645</td>
    </tr>
    <tr>
      <td>pitrou</td>
      <td>101</td>
      <td>36585</td>
    </tr>
    <tr>
      <td>jbonofre</td>
      <td>1</td>
      <td>20061</td>
    </tr>
  </tbody>
</table>


<table class="table">
  <caption>Notable Components in apache/arrow for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>Component label</th>
      <th>Number of merged prs</th>
      <th>Number of line changes (+ and -)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Parquet</td>
      <td>100</td>
      <td>103828</td>
    </tr>
    <tr>
      <td>C++</td>
      <td>387</td>
      <td>82744</td>
    </tr>
    <tr>
      <td>FlightRPC</td>
      <td>43</td>
      <td>52659</td>
    </tr>
    <tr>
      <td>CI</td>
      <td>237</td>
      <td>42249</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td>74</td>
      <td>20676</td>
    </tr>
  </tbody>
</table>


## Migration of infrastructure from Voltron Data

As Voltron Data has wound down its operations in 2025, the Arrow project
had to migrate benchmarking infrastructure and nightly report from
Voltron-managed services to an Arrow-managed AWS account. This work has been
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
support for Parquet. Fuzzing work is led by [pitrou](https://github.com/pitrou)
who is also one of the most active members of the community guiding other
developers and supporting us with abundant review capacity.

Multiple newer types have also been supported in the last year,
namely: VARIANT, UUID, GEOMETRY and GEOGRAPHY contributed
by [neilechao](https://github.com/neilechao) and
[paleolimbot](https://github.com/paleolimbot).

An important feature added has also been Content-Defined Chunking
which improves deduplication of Parquet files with mostly identical
contents, by choosing data page boundaries based on actual contents
rather than a number of values [^3]. This work has been done by
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
which they created several blog posts [^4], [^5]. The work has been
championed by [alamb](https://github.com/alamb) and
[etseidl](https://github.com/etseidl).

<table class="table">
  <caption>Notable Components in apache/arrow-rs for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>component</th>
      <th>merged_prs</th>
      <th>line_changes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>parquet</td>
      <td>333</td>
      <td>140958</td>
    </tr>
    <tr>
      <td>arrow</td>
      <td>436</td>
      <td>76590</td>
    </tr>
    <tr>
      <td>parquet-variant</td>
      <td>125</td>
      <td>41832</td>
    </tr>
    <tr>
      <td>api-change</td>
      <td>59</td>
      <td>33938</td>
    </tr>
    <tr>
      <td>arrow-avro</td>
      <td>48</td>
      <td>29487</td>
    </tr>
  </tbody>
</table>

### Java

The biggest changes in apache/arrow-java for 2025 have been connected
to Flight and Avro components plus Sphinx support due to the Java
implementation being moved into a separate Apache repository.
Contributors involved in the above are [lidavidm](https://github.com/lidavidm)
and [martin-traverse](https://github.com/martin-traverse).

### Go

There has been a lot of work related to new variant type in the
Parquet implementation done in apache/arrow-go all by
[zeroshade](https://github.com/zeroshade).

Noticeable emphasis was also visible on performance-focused PRs leading to
the addition of row seeking, bloom filter reading/writing, and reduction of
allocations in the Parquet library along with significant optimization work
in the ``compute.Take` kernels. Shout out to [pixelherodev](https://github.com/pixelherodev)
and [hamilton-earthscope](https://github.com/hamilton-earthscope) for the
emphasis they placed on improving performance.

<table class="table">
  <caption>Notable Components in apache/arrow-go for 2025.</caption>
  <thead style="background-color: #e9ecef">
    <tr>
      <th>component</th>
      <th>merged_prs</th>
      <th>line_changes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>parquet</td>
      <td>34</td>
      <td>27056</td>
    </tr>
    <tr>
      <td>arrow</td>
      <td>33</td>
      <td>14235</td>
    </tr>
  </tbody>
</table>

### Nanoarrow

Bigger work in nanoarrow include Decimal32/64 and ListView/LargeListView support,
LZ4 and ZSTD decompression in the IPC reader, and broader packaging via Conan, Homebrew,
and vcpkg. Contributors driving most above are [paleolimbot](https://github.com/paleolimbot)
and [WillAyd](https://github.com/WillAyd).

---

## Arrow Summit 25

One last thing to highlight would be our first Arrow Summit 25 that
was held in Paris in October 2025. The event was a great success and
it brought users, contributors and maintainers together. It
definitely was a highlight of the year for many of us. Thanks to
[raulcd](https://github.com/raulcd) and [pitrou](https://github.com/pitrou)
for organizing the event.

<img src="{{ site.baseurl }}/img/arrow_summit.jpeg" alt="Arrow Summit 25 group picture" width="100%">

---

## Thank you!

We would like to thank every single contributor to Apache Arrow for
being a part of this great community and project! Hope this blog
post helps to validate all the work you have done and motivates us
to continue collaborating and growing together!

---

<br>

The Notebooks with the analysis for this blog post can be found
in [^6].

Note not all language implementations are mentioned. Some due to being
moved into a separate repository in 2025 resulting in missing information
for large amount of merged pull requests. Others due to having lower
number of bigger contributions in the past year.


---

[^1]: [Apache Arrow is 10 years old 🎉](https://arrow.apache.org/blog/2026/02/12/arrow-anniversary/)
[^2]: [Developer Thriving: Four Sociocognitive Factors That Create Resilient Productivity on Software Teams](https://ieeexplore.ieee.org/abstract/document/10491133)
[^3]: [Parquet Content-Defined Chunking](https://huggingface.co/blog/parquet-cdc)
[^4]: [A Practical Dive Into Late Materialization in arrow-rs Parquet Reads](https://arrow.apache.org/blog/2025/12/11/parquet-late-materialization-deep-dive/)
[^5]: [3x-9x Faster Apache Parquet Footer Metadata Using a Custom Thrift Parser in Rust](https://arrow.apache.org/blog/2025/10/23/rust-parquet-metadata/)
[^6]: [arrow-maintenance/explorations](https://github.com/arrow-maintenance/explorations/tree/main/yearly_highlights)

