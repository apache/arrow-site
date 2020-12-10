---
layout: overview
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

Apache Arrow is a software development platform for building high performance
applications that process and transport large data sets. It is designed to both
improve the performance of analytical algorithms and the efficiency of moving
data from one system or programming language to another.

A critical component of Apache Arrow is its **in-memory columnar format**, a
standardized, language-agnostic specification for representing structured,
table-like datasets in-memory. This data format has a rich data type system
(included nested and user-defined data types) designed to support the needs of
analytic database systems, data frame libraries, and more.

<div class="row mt-4">
  <div class="col-md-6">
    <h3>Columnar is Fast</h3>
    <p>
      The Apache Arrow format allows computational routines and execution
      engines to maximize their efficiency when scanning and iterating large
      chunks of data.  In particular, the contiguous columnar layout enables
      vectorization using the latest SIMD (Single Instruction, Multiple Data)
      operations included in modern processors.
    </p>
  </div>
  <div class="col-md-6">
    <img src="{{ site.baseurl }}/img/simd.png" alt="SIMD" class="img-fluid mx-auto" />
  </div>
</div>

<div class="row mt-4">
  <div class="col-md-6">
    <img src="{{ site.baseurl }}/img/copy.png" alt="common data layer" class="img-fluid mx-auto" />
    <img src="{{ site.baseurl }}/img/shared.png" alt="common data layer" class="img-fluid mx-auto" />
  </div>
  <div class="col-md-6">
    <h3>Standardization Saves</h3>
    <p>
      Without a standard columnar data format, every database and language has
      to implement its own internal data format. This generates a lot of
      waste. Moving data from one system to another involves costly
      serialization and deserialization.  In addition, common algorithms must
      often be rewritten for each data format.
    </p>
    <p>
      Arrow's in-memory columnar data format is an out-of-the-box solution to
      these problems. Systems that use or support Arrow can transfer data
      between them at little-to-no cost. Moreover, they don't need to implement
      custom connectors for every other system. On top of these savings, a
      standardized memory format facilitates reuse of libraries of algorithms,
      even across languages.
    </p>
  </div>
</div>

<div class="row mt-4">
  <div class="col-md-12">
    <h3>Arrow Libraries</h3>
    <p>
      The Arrow project contains libraries that enable you to work with data in the Arrow columnar format in many languages. The <a href="{{ site.baseurl }}/docs/cpp/">C++</a>, <a href="https://github.com/apache/arrow/blob/master/csharp/README.md">C#</a>, <a href="https://godoc.org/github.com/apache/arrow/go/arrow">Go</a>, <a href="{{ site.baseurl }}/docs/java/">Java</a>, <a href="{{ site.baseurl }}/docs/js/">JavaScript</a>, <a href="https://arrow.juliadata.org/stable/">Julia</a>, and <a href="https://docs.rs/crate/arrow/">Rust</a> libraries
      contain distinct implementations of the Arrow format. These libraries are <a href="{{ site.baseurl }}/docs/status.html">integration-tested</a> against each other to ensure their fidelity to the format. In addition, Arrow libraries for <a href="{{ site.baseurl }}/docs/c_glib/">C (Glib)</a>, <a href="https://github.com/apache/arrow/blob/master/matlab/README.md">MATLAB</a>, <a href="{{ site.baseurl }}/docs/python/">Python</a>, <a href="{{ site.baseurl }}/docs/r/">R</a>, and <a href="https://github.com/apache/arrow/blob/master/ruby/README.md">Ruby</a> are built on top of the C++ library.
    </p>
    <p>
      These official libraries enable third-party projects to work with Arrow
      data without having to implement the Arrow columnar format
      themselves. They also contain many software components that assist with
      systems problems related to getting data in and out of remote storage
      systems and moving Arrow-formatted data over network interfaces, among
      other <a href="{{ site.baseurl }}/use_cases/">use cases</a>.
    </p>
  </div>
</div>
