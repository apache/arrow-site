---
layout: post
title: "A journey with Apache Arrow (part 1)"
date: "2023-04-02 00:00:00"
author: lquerel
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

Apache Arrow is a technology widely adopted in big data, analytics, and machine learning applications. This article discusses our journey with Arrow, specifically its application to telemetry, and the challenges we encountered while optimizing the OpenTelemetry protocol to significantly reduce bandwidth costs. The promising results we achieved inspired us to share our insights. This article specifically focuses on transforming data from an XYZ format into an efficient Arrow representation that optimizes both compression ratio, transport, and data processing. Our benchmarks thus far have shown promising results, with compression ratio improvements ranging from 1.5x to 6x, depending on the data type (metrics, logs, traces) and distribution. The approaches presented for addressing these challenges may be applicable to other Arrow domains as well. This article serves as the first installment in a two-part series.

## What is Apache Arrow

[Apache Arrow](https://arrow.apache.org/docs/index.html) is an open-source project offering a standardized, language-agnostic in-memory format for representing structured and semi-structured data. This enables data sharing and zero-copy data access between systems, eliminating the need for serialization and deserialization when exchanging datasets between varying CPU architectures and programming languages. Furthermore, Arrow features an extensive set of high-performance, parallel, and vectorized kernel functions designed for efficiently processing massive amounts of columnar data. These features make Arrow an appealing technology for big data processing, data transport, analytics, and machine learning applications. The growing number of [products and open-source projects](https://arrow.apache.org/powered_by/) that have adopted Apache Arrow at their core or offer Arrow support reflects the widespread recognition and appreciation of its benefits (refer to this [article](https://www.dremio.com/blog/apache-arrows-rapid-growth-over-the-years/) for an in-depth overview of the Arrow ecosystem and adoption). Over 11,000 GitHub users support this project, and 840+ are contributors who make this project an undeniable success.

Very often people ask about the differences between Arrow and [Apache Parquet](https://parquet.apache.org/) or other columnar file formats. Arrow is designed and optimized for in-memory processing, while Parquet is tailored for disk-based storage. In reality, these technologies are complementary, with bridges existing between them to simplify interoperability. In both cases, data is represented in columns to optimize access, data locality and compressibility. However, the tradeoffs differ slightly. Arrow prioritizes data processing speed over the optimal data encoding. Complex encodings that don’t benefit from SIMD instruction sets are generally not natively supported by Arrow, unlike formats such as Parquet. Storing data in Parquet format and processing and transporting it in Arrow format has become a prevalent model within the big data community.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/journey-apache-arrow/row-vs-columnar.svg" width="100%" class="img-responsive" alt="Memory representations: row vs columnar data.">
  <figcaption>Fig 1: Memory representations: row vs columnar data.</figcaption>
</figure>

Figure 1 illustrates the differences in memory representation between row-oriented and column-oriented approaches. The column-oriented approach groups data from the same column in a continuous memory area, which facilitates parallel processing (SIMD) and enhances compression performance.

## Why are we interested in Apache Arrow

At F5, we’ve adopted [OpenTelemetry](https://opentelemetry.io/) (OTel) as the standard for all telemetry across our products, such as BIGIP and NGINX. These products may generate large volumes of metrics and logs for various reasons, from performance evaluation to forensic purposes. The data produced by these systems is typically centralized and processed in dedicated systems. Transporting and processing this data accounts for a significant portion of the cost associated with telemetry pipelines. In this context, we became interested in Apache Arrow. Instead of reinventing yet another telemetry solution, we decided to invest in the OpenTelemetry project, working on improvements to the protocol to significantly increase its efficiency with high telemetry data volumes. We collaborated with [Joshua MacDonald](https://github.com/jmacd) from [Lightstep](https://lightstep.com/) to integrate these optimizations into an [experimental OTel collector](https://github.com/open-telemetry/experimental-arrow-collector) and are currently in discussions with the OTel technical committee to finalize a code [donation](https://github.com/open-telemetry/community/issues/1332). 

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/journey-apache-arrow/performance.svg" width="100%" class="img-responsive" alt="Performance improvement in the OpenTelemetry Arrow experimental project.">
  <figcaption>Fig 2: Performance improvement in the OpenTelemetry Arrow experimental project.</figcaption>
</figure>

This project has been divided into two phases. The first phase, which is nearing completion, aims to enhance the protocol's compression ratio. The second phase, planned for the future, focuses on improving end-to-end performance by incorporating Apache Arrow throughout all levels, eliminating the need for conversion between old and new protocols. The results so far are promising, with our benchmarks showing compression ratio improvements ranging from x1.5 to x6, depending on the data type (metrics, logs, traces) and distribution. For the second phase, our estimates suggest that data processing acceleration could range from x2 to x12, again depending on the data's nature and distribution. For more information, we encourage you to review the [specifications](https://github.com/lquerel/oteps/blob/main/text/0156-columnar-encoding.md) and the [reference implementation](https://github.com/f5/otel-arrow-adapter).

Arrow relies on a schema to define the structure of data batches that it processes and transports. The subsequent sections will discuss various techniques that can be employed to optimize the creation of these schemas.

## How to leverage Arrow to optimize network transport cost

Apache Arrow is a complex project with a rapidly evolving ecosystem, which can sometimes be overwhelming for newcomers. Fortunately the Arrow community has published three introductory articles [1](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/), [2](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/), and [3](https://arrow.apache.org/blog/2022/10/17/arrow-parquet-encoding-part-3/) that we recommend for those interested in exploring this technology.

This article primarily focuses on transforming data from an XYZ format into an efficient Arrow representation that optimizes both compression ratio and data processing. There are numerous approaches to this transformation, and we will examine how these methods can impact compression ratio, CPU usage, and memory consumption during the conversion process, among other factors.

<figure style="text-align: center;">
  <img src="{{ site.baseurl }}/img/journey-apache-arrow/schema-optim-process.svg" width="100%" class="img-responsive" alt="Fig 3: Optimization process for the definition of an Arrow schema.">
  <figcaption>Fig 3: Optimization process for the definition of an Arrow schema.</figcaption>
</figure>