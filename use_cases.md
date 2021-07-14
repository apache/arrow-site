---
layout: default
title: Use cases
description: Example use cases for the Apache Arrow project
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

# Use Cases

Here are some example applications of the Apache Arrow format and libraries.
For more, see our [blog]({{ site.baseurl }}/blog/) and the list of projects
[powered by Arrow]({{ site.baseurl }}/powered_by/).

## Reading/writing columnar storage formats

Many Arrow libraries provide convenient methods for reading and writing
columnar file formats, including the Arrow IPC file format ("Feather")
and the [Apache Parquet](https://parquet.apache.org/) format.

<!-- Link to implementation matrix? -->

* Feather: C++, [Python]({{ site.baseurl }}/docs/python/feather.html),
  [R]({{ site.baseurl }}/docs/r/reference/read_feather.html)
* Parquet: [C++]({{ site.baseurl }}/docs/cpp/parquet.html),
  [Python]({{ site.baseurl }}/docs/python/parquet.html),
  [R]({{ site.baseurl }}/docs/r/reference/read_parquet.html)

In addition to single-file readers, some libraries (C++,
[Python]({{ site.baseurl }}/docs/python/dataset.html),
[R]({{ site.baseurl }}/docs/r/articles/dataset.html)) support reading
entire directories of files and treating them as a single dataset. These
datasets may be on the local file system or on a remote storage system, such
as HDFS, S3, etc.

## Sharing memory locally

Arrow IPC files can be memory-mapped locally, which allow you to work with
data bigger than memory and to share data across languages and processes.
<!-- example? -->

The Arrow project includes [Plasma]({% post_url 2017-08-08-plasma-in-memory-object-store %}),
a shared-memory object store written in C++ and exposed in Python. Plasma
holds immutable objects in shared memory so that they can be accessed
efficiently by many clients across process boundaries.

The Arrow format also defines a [C data interface]({% post_url 2020-05-04-introducing-arrow-c-data-interface %}),
which allows zero-copy data sharing inside a single process without any
build-time or link-time dependency requirements. This allows, for example,
[R users to access `pyarrow`-based projects]({{ site.baseurl }}/docs/r/articles/python.html)
using the `reticulate` package.

## Moving data over the network

The Arrow format allows serializing and shipping columnar data
over the network - or any kind of streaming transport.
[Apache Spark](https://spark.apache.org/) uses Arrow as a
data interchange format, and both [PySpark]({% post_url 2017-07-26-spark-arrow %})
and [sparklyr]({% post_url 2019-01-25-r-spark-improvements %}) can take
advantage of Arrow for significant performance gains when transferring data.
[Google BigQuery](https://cloud.google.com/bigquery/docs/reference/storage),
[TensorFlow](https://www.tensorflow.org/tfx),
[AWS Athena](https://docs.aws.amazon.com/athena/latest/ug/connect-to-a-data-source.html),
and [others]({{ site.baseurl }}/powered_by/) also use Arrow similarly.

The Arrow project also defines [Flight]({% post_url 2019-09-30-introducing-arrow-flight %}),
a client-server RPC framework to build rich services exchanging data according
to application-defined semantics.

<!-- turbodbc -->

## In-memory data structure for analytics

The Arrow format is designed to enable fast computation. Some projects have
begun to take advantage of that design.  Within the Apache Arrow project,
[DataFusion]({% post_url 2019-02-04-datafusion-donation %}) is a query engine
using Arrow data built in Rust.

<!--
* Rapids?
* Dremio?
-->
