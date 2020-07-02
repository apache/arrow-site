---
layout: default
title: Format
description: Arrow Format
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

## Apache Arrow Overview

Apache Arrow is a software development platform for building high performance applications that process and transport large data sets. It is designed to both improve the performance of analytical algorithms and the efficiency of moving data from one system (or programming language to another).

A critical component of Apache Arrow is its **in-memory columnar format**, a standardized, language-agnostic specification for representing structured, table-like datasets in-memory. This data format has a rich data type system (included nested and user-defined data types) designed to support the needs of analytic database systems, data frame libraries, and more.

<div class="row mt-4">
  <div class="col-md-6">
    <h3>Columnar is Efficient</h3>
    <p>
      The Apache Arrow format allows computational routines and execution engines
      to maximize their efficiency when scanning and iterating large chunks of data.
      In particular, the contiguous columnar layout enables vectorization using
      the latest SIMD (Single Instruction, Multiple Data) operations included
      in modern processors.
    </p>
  </div>
  <div class="offset-md-1 col-md-5 mt-4">
    <img src="{{ site.baseurl }}/img/simd.png" alt="SIMD" class="img-fluid mx-auto" />
  </div>
</div>
<div class="row mt-4">
  <div class="col-md-6">
    <h3>Standard</h3>
      <p>Apache Arrow is backed by key developers of major open source projects, including Calcite, Cassandra, Drill, Hadoop, HBase, Ibis, Impala, Kudu, Pandas, Parquet, Phoenix, Spark, and Storm, making it the de-facto standard for columnar in-memory analytics.</p>
      <p>Learn more about projects that are <a href="{{ site.baseurl }}/powered_by/">powered by Apache Arrow</a></p>
  </div>
  <div class="offset-md-1 col-md-5 mt-4">
    <img src="{{ site.baseurl }}/img/copy.png" alt="common data layer" class="img-fluid mx-auto px-4 pb-4" />
    <ul>
        <li>Each system has its own internal memory format</li>
        <li>70-80% computation wasted on serialization and deserialization</li>
        <li>Similar functionality implemented in multiple projects</li>
    </ul>
    <img src="{{ site.baseurl }}/img/shared.png" alt="common data layer" class="img-fluid mx-auto" />
    <ul>
      <li>All systems utilize the same memory format</li>
      <li>No overhead for cross-system communication</li>
      <li>Projects can share functionality (eg, Parquet-to-Arrow reader)</li>
    </ul>
  </div>
</div>
