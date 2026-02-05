---
layout: post
title: "Introducing a Security Model for Arrow"
date: "2026-02-05 00:00:00"
author: pmc
categories: [arrow, security]
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

We are thrilled to announce the official publication of a
[Security model](https://arrow.apache.org/docs/dev/format/Security.html) for Apache Arrow.

The Arrow security model covers a core subset of the Arrow specifications:
the [Arrow columnar format](https://arrow.apache.org/docs/dev/format/Columnar.html),
the [Arrow C Data Interface](https://arrow.apache.org/docs/dev/format/CDataInterface.html) and the
[Arrow IPC format](https://arrow.apache.org/docs/dev/format/Columnar.html#serialization-and-interprocess-communication-ipc).
It sets expectations and gives guidelines for handling data coming from
untrusted sources.

The specifications covered by the Arrow security model are building blocks for
all the other Arrow specifications, such as Flight and ADBC.

The ideas underlying the Arrow security model were informally shared between
Arrow maintainers and have informed decisions for years, but they were left
undocumented until now.

Implementation-specific security considerations, such as proper API usage and
runtime safety guarantees, will later be covered in these implementations'
respective documentations.
