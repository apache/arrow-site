---
layout: post
title: "Announcing Apache Arrow DataFusion Comet"
date: "2024-03-06 00:00:00"
author: pmc
categories: [release]
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

# Introduction
The Apache Arrow PMC is pleased to announce the donation of the [Comet project],
a native Spark SQL Accelerator built on [Apache Arrow DataFusion].

Comet is an Apache Spark plugin that uses Apache Arrow DataFusion to
accelerate Spark workloads. It is designed as a drop-in
replacement for Spark's JVM based SQL execution engine and offers significant
performance improvements for some workloads as shown below.

<figure style="text-align: center;">
  <img 
    src="{{ site.baseurl }}/img/datafusion-comet/comet-architecture.png" 
    width="100%" 
    class="img-responsive" 
    alt="Fig 1: Adaptive Arrow schema architecture overview."
  >
  <figcaption>
   <b>Figure 1</b>: With Comet, users interact with the same Spark ecosystem, tools
    and APIs such as Spark SQL. Queries still run through Spark's query optimizer and planner. 
    However, the execution is delegated to Comet,
    which is significantly faster and more resource efficient than a JVM based
    implementation.
</figcaption>
</figure>



[Rust]: https://www.rust-lang.org/

Comet is one of a growing class of projects that aim to accelerate Spark using
native columnar engines such as the proprietary [Databricks Photon Engine] and
open source projects [Gluten], [Spark RAPIDS], and [Blaze] (also built using
DataFusion).

Comet was originally implemented at Apple and the engineers who worked on the
project are also significant contributors to Arrow and DataFusion. Bringing 
Comet into the Apache Software Foundation will accelerate its development and 
grow its community of contributors and users.

[Comet project]: https://github.com/apache/arrow-datafusion-comet
[Apache Arrow DataFusion]: https://arrow.apache.org/datafusion
[Databricks Photon Engine]: https://www.databricks.com/product/photon
[Gluten]: https://incubator.apache.org/projects/gluten.html
[Blaze]: https://github.com/kwai/blaze
[Spark RAPIDS]: https://github.com/NVIDIA/spark-rapids

# Get Involved
Comet is still in the early stages of development and we would love to have you
join us and help shape the project. We are working on an initial release, and 
expect to post another update with more details at that time.

Before then, here are some ways to get involved:

* Learn more by visiting the [Comet project] page and reading the [mailing list
  discussion] about the initial donation.

* Help us plan out the [roadmap]

* Try out the project and provide feedback, file issues, and contribute code.

[mailing list discussion]: https://lists.apache.org/thread/0q1rb11jtpopc7vt1ffdzro0omblsh0s
[roadmap]: https://github.com/apache/arrow-datafusion-comet/issues/19

 
