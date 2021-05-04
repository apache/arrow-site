---
layout: post
title: "Ballista: A Distributed Scheduler for Apache Arrow"
description: "We are excited to announce that Ballista has been donated to the Apache Arrow project. Ballista is a distributed scheduler for the Rust implementation of Apache Arrow."
date: "2021-04-12 00:00:00 -0600"
author: agrove
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

We are excited to announce that [Ballista](https://github.com/apache/arrow-datafusion/tree/master/ballista) has been donated 
to the Apache Arrow project. 

Ballista is a distributed compute platform primarily implemented in Rust, and powered by Apache Arrow. It is built
on an architecture that allows other programming languages (such as Python, C++, and Java) to be supported as
first-class citizens without paying a penalty for serialization costs.

The foundational technologies in Ballista are:

- [Apache Arrow](https://arrow.apache.org/) memory model and compute kernels for efficient processing of data.
- [Apache Arrow DataFusion](https://github.com/apache/arrow-datafusion) query planning and 
  execution framework, extended by Ballista to provide distributed planning and execution.
- [Apache Arrow Flight Protocol](https://arrow.apache.org/blog/2019/10/13/introducing-arrow-flight/) for efficient
  data transfer between processes.
- [Google Protocol Buffers](https://developers.google.com/protocol-buffers) for serializing query plans.
- [Docker](https://www.docker.com/) for packaging up executors along with user-defined code.

Ballista can be deployed as a standalone cluster and also supports [Kubernetes](https://kubernetes.io/). In either
case, the scheduler can be configured to use [etcd](https://etcd.io/) as a backing store to (eventually) provide
redundancy in the case of a scheduler failing.

## Status

The Ballista project is at an early stage of development. However, it is capable of running complex analytics queries 
in a distributed cluster with reasonable performance (comparable to more established distributed query frameworks).

One of the benefits of Ballista being part of the Arrow codebase is that there is now an opportunity to push parts of 
the scheduler down to DataFusion so that is possible to seamlessly scale across cores in DataFusion, and across nodes 
in Ballista, using the same unified query scheduler.

## Contributors Welcome!

If you are excited about being able to use Rust for distributed compute and ETL and would like to contribute to this 
work then there are many ways to get involved. The simplest way to get started is to try out Ballista against your own 
datasets and file bug reports for any issues that you find. You could also check out the current 
[list of issues](https://issues.apache.org/jira/issues/?jql=project%20%3D%20ARROW%20AND%20component%20%3D%20%22Rust%20-%20Ballista%22) and have a go at fixing one.

The [Arrow Rust Community](https://github.com/apache/arrow/blob/master/rust/README.md#arrow-rust-community)
section of the Rust README provides information on other ways to interact with the Ballista contributors and 
maintainers.

