---
layout: post
title: "Announcing Apache Arrow DataFusion is now Apache DataFusion"
date: "2024-05-07 00:00:00"
author: pmc
categories: [subprojects]
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



## Introduction

TLDR; [Apache Arrow] DataFusion --> [Apache DataFusion]

The Arrow PMC and newly created DataFusion PMC are happy to announce that as of
April 16, 2024 the Apache Arrow DataFusion subproject is now a top level
[Apache Software Foundation] project.

[Apache Arrow]: https://arrow.apache.org/
[Apache DataFusion]: https://datafusion.apache.org/
[Apache Software Foundation]: https://www.apache.org/

## Background

Apache DataFusion is a fast, extensible query engine for building high-quality
data-centric systems in Rust, using the Apache Arrow in-memory format.

When DataFusion was [donated to the Apache Software Foundation] in 2019, the
DataFusion community was not large enough to stand on its own and the Arrow
project agreed to help support it. The community has grown significantly since
2019, benefiting immensely from being part of Arrow and following [The Apache
Way].

[donated to the Apache Software Foundation]: https://arrow.apache.org/blog/2019/02/04/datafusion-donation/
[The Apache Way]: https://www.apache.org/theapacheway/

## Why now?

The community [discussed graduating to a top level project publicly] for almost
a year, as the project seemed ready to stand on its own and would benefit from
more focused governance. For example, earlier in DataFusion's life many
contributed to both [arrow-rs] and DataFusion, but as DataFusion has matured many
contributors, committers and PMC members focused more and more exclusively on
DataFusion.

[discussed graduating to a top level project publicly]: https://github.com/apache/datafusion/discussions/6475
[arrow-rs]: https://github.com/apache/arrow-rs

## Looking forward

The future looks bright. There are now [10s of known projects built with
DataFusion], and that number continues to grow. We recently held our [first in
person meetup] passed [5000 stars] on GitHub, [wrote a paper that was accepted
at SIGMOD 2024], and began work on [Comet], an [Apache Spark] accelerator
[initially donated by Apple].

Thank you to everyone in the Arrow community who helped DataFusion grow and
mature over the years, and we look forward to continuing our collaboration as
projects. All future blogs and announcements will be posted on the [Apache
DataFusion] website.


[10s of known projects built with DataFusion]: https://datafusion.apache.org/user-guide/introduction.html#known-users
[first in person meetup]: https://github.com/apache/datafusion/discussions/8522
[5000 stars]: https://github.com/apache/datafusion/stargazers
[wrote a paper that was accepted at SIGMOD 2024]: https://github.com/apache/datafusion/issues/8373#issuecomment-2025133714
[Comet]: https://github.com/apache/datafusion-comet
[Apache Spark]: https://spark.apache.org/
[initially donated by Apple]: https://arrow.apache.org/blog/2024/03/06/comet-donation/

## Get Involved

If you are interested in joining the community, we would love to have you join
us. Get in touch using [Communication Doc] and learn how to get involved in the
[Contributor Guide]. We welcome everyone to try DataFusion on their
own data and projects and let us know how it goes, contribute suggestions,
documentation, bug reports, or a PR with documentation, tests or code.


[communication doc]: https://datafusion.apache.org/contributor-guide/communication.html
[Contributor Guide]: https://datafusion.apache.org/contributor-guide/index.html
