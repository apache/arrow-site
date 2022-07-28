---
layout: article
title: Powered by
description: List of projects powered by Apache Arrow
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

## Project and Product Names Using "Apache Arrow"

Organizations creating products and projects for use with Apache Arrow, along
with associated marketing materials, should take care to respect the trademark
in "Apache Arrow" and its logo. Please refer to [ASF Trademarks Guidance][1]
and associated [FAQ][2] for comprehensive and authoritative guidance on proper
usage of ASF trademarks.

Names that do not include "Apache Arrow" at all have no potential trademark
issue with the Apache Arrow project. This is recommended.

Names like "Apache Arrow BigCoProduct" are not OK, as are names including
"Apache Arrow" in general. The above links, however, describe some exceptions,
like for names such as "BigCoProduct, powered by Apache Arrow" or
"BigCoProduct for Apache Arrow".

It is common practice to create software identifiers (Maven coordinates, module
names, etc.) like "arrow-foo". These are permitted. Nominative use of trademarks
in descriptions is also always allowed, as in "BigCoProduct is a widget for
Apache Arrow".

Projects and documents that want to include a logo for Apache Arrow should use
the official logo, and adhere to the guidelines listed on the [Visual Identity]({{ site.baseurl }}/visual_identity/) page:

<img src="{{ site.baseurl }}/img/arrow-logo_horizontal_black-txt_white-bg.png" style="max-width: 100%;"/>

## Projects Powered By Apache Arrow

To add yourself to the list, please open a [pull request][27] adding your
organization name, URL, a list of which Arrow components you are using, and a
short description of your use case.

* **[Apache Parquet][3]:** A columnar storage format available to any project
  in the Hadoop ecosystem, regardless of the choice of data processing
  framework, data model or programming language. The C++ and Java
  implementation provide vectorized reads and write to/from Arrow data
  structures.
* **[Apache Spark][7]:** Apache Spark™ is a fast and general engine for
  large-scale data processing. Spark uses Apache Arrow to
  1. improve performance of conversion between Spark DataFrame and pandas DataFrame
  2. enable a set of vectorized user-defined functions (`pandas_udf`) in PySpark.
* **[ArcPy][43]:** ArcPy is Esri’s comprehensive and powerful API for working within 
  the ArcGIS suite of products to perform and automate spatial analysis, data management,
  and conversion tasks (license required). ArcPy supports Arrow Tables as input
  and output.
* **[AWS Data Wrangler][34]:** Extends the power of Pandas library to AWS connecting 
  DataFrames and AWS data related services such as Amazon Redshift, AWS Glue, Amazon Athena, 
  Amazon EMR, Amazon QuickSight, etc.
* **[Bodo][36]:** Bodo is a universal Python analytics engine that democratizes High Performance 
   Computing (HPC) architecture for mainstream enterprises, allowing Python analytics workloads to
   scale efficiently. Bodo uses Arrow to support I/O for Parquet files, as well as internal support for data operations.
* **[ClickHouse][44]:** An open-source analytical database management system. 
   ClickHouse is using Apache Arrow for data import and export, and for direct querying of external datasets 
   in Arrow, ArrowStream, Parquet and ORC formats.
* **[Cylon][35]:**  An open-source high performance distributed data processing library 
  that can be seamlessly integrated with existing Big Data and AI/ML frameworks. Cylon
  uses Arrow memory format and exposes language bindings to C++, Java, and Python.
* **[Dask][15]:** Python library for parallel and distributed execution of
  dynamic task graphs. Dask supports using pyarrow for accessing Parquet
  files
* **[Data Preview][31]:** Data Preview is a Visual Studio Code extension
  for viewing text and binary data files. Data Preview uses Arrow JS API
  for loading, transforming and saving Arrow data files and schemas.
* **[Dremio][9]:** A self-service data platform. Dremio makes it easy for
  users to discover, curate, accelerate, and share data from any source.
  It includes a distributed SQL execution engine based on Apache Arrow.
  Dremio reads data from any source (RDBMS, HDFS, S3, NoSQL) into Arrow
  buffers, and provides fast SQL access via ODBC, JDBC, and REST for BI,
  Python, R, and more (all backed by Apache Arrow).
* **[Falcon][25]:** An interactive data exploration tool with coordinated views.
  Falcon loads Arrow files using the Arrow JavaScript module. Since Arrow does
  not need to be parsed (like text-based formats like CSV and JSON), startup cost
  is significantly minimized.
* **[FASTDATA.io][26]**: Plasma Engine (unrelated to Arrow's Plasma In-Memory
  Object Store) exploits the massive parallel processing power of GPUs for
  stream and batch processing. It supports Arrow as input and output, uses
  Arrow internally to maximize performance, and can be used with existing
  Apache Spark™ APIs.
* **[Fletcher][20]:** Fletcher is a framework that can integrate FPGA
  accelerators with tools and frameworks that use the Apache Arrow in-memory
  format. From a set of Arrow Schemas, Fletcher generates highly optimized
  hardware structures that allow accelerator kernels to read and write
  RecordBatches at system bandwidth through easy-to-use interfaces.
* **[GeoMesa][8]:** A suite of tools that enables large-scale geospatial query
  and analytics on distributed computing systems. GeoMesa supports query
  results in the Arrow IPC format, which can then be used for in-browser
  visualizations and/or further analytics.
* **[GOAI][19]:** Open GPU-Accelerated Analytics Initiative for Arrow-powered
  analytics across GPU tools and vendors
* **[graphique][41]** GraphQL service for arrow tables and parquet data sets. The schema for a query API is derived automatically.
* **[Graphistry][18]:** Supercharged Visual Investigation Platform used by
  teams for security, anti-fraud, and related investigations. The Graphistry
  team uses Arrow in its NodeJS GPU backend and client libraries, and is an
  early contributing member to GOAI and Arrow\[JS\] focused on bringing these
  technologies to the enterprise.
* **[HASH][39]:** HASH is an open-core platform for building, running, and learning
  from simulations, with an in-browser IDE. HASH Engine uses Apache Arrow to power
  the datastore for simulation state during computation, enabling zero-copy data
  transfer between simulation logic written across Rust, JavaScript, and Python.
* **[InAccel][29]:** A machine learning acceleration framework which leverages
  FPGAs-as-a-service. InAccel supports dataframes backed by Apache Arrow to
  serve as input for our implemented ML algorithms. Those dataframes can be
  accessed from the FPGAs with a single DMA operation by implementing a shared
  memory communication schema.
* **[InfluxDB IOx][42]:** InfluxDB IOx is an open source time series database
  written in Rust.  It is the future core of InfluxDB; supporting
  industry standard SQL, InfluxQL, and Flux. IOx uses Apache Arrow as its in-memory
  format, Apache Parquet as its persistence format and Apache Arrow Flight for RPC.
* **[libgdf][14]:** A C library of CUDA-based analytics functions and GPU IPC
  support for structured data. Uses the Arrow IPC format and targets the Arrow
  memory layout in its analytic functions. This work is part of the [GPU Open
  Analytics Initiative][11]
* **[MATLAB][30]:** A numerical computing environment for engineers and
  scientists. MATLAB uses Apache Arrow to support reading and writing Parquet
  and Feather files.
* **[OmniSci][10] (formerly MapD):** In-memory columnar SQL engine designed to run
  on both GPUs and CPUs. OmniSci supports Arrow for data ingest and data interchange
  via CUDA IPC handles. This work is part of the [GPU Open Analytics Initiative][11]
* **[pandas][12]:** data analysis toolkit for Python programmers. pandas
  supports reading and writing Parquet files using pyarrow. Several pandas
  core developers are also contributors to Apache Arrow.
* **[Perspective][23]:** Perspective is a streaming data visualization engine in JavaScript for building real-time & user-configurable analytics entirely in the browser.
* **[Petastorm][28]:** Petastorm enables single machine or distributed training
  and evaluation of deep learning models directly from datasets in Apache
  Parquet format. Petastorm supports popular Python-based machine learning
  (ML) frameworks such as Tensorflow, Pytorch, and PySpark. It can also be
  used from pure Python code.
* **[Polars][40]:** Polars is a blazingly fast DataFrame library and query engine 
  that aims to utilize modern hardware efficiently. 
  (e.g. multi-threading, SIMD vectorization, hiding memory latencies). 
  Polars is built upon Apache Arrow and uses its columnar memory, compute kernels,
  and several IO utilities. Polars is written in Rust and available in Rust and Python.
* **[Quilt Data][13]:** Quilt is a data package manager, designed to make
  managing data as easy as managing code. It supports Parquet format via
  pyarrow for data access.
* **[Ray][5]:** A flexible, high-performance distributed execution framework
  with a focus on machine learning and AI applications. Uses Arrow to
  efficiently store Python data structures containing large arrays of numerical
  data. Data can be accessed with zero-copy by multiple processes using the
  [Plasma shared memory object store][6] which originated from Ray and is part
  of Arrow now.
* **[Red Data Tools][16]:** A project that provides data processing
  tools for Ruby. It provides [Red Arrow][17] that is a Ruby bindings
  of Apache Arrow based on Apache Arrow GLib. Red Arrow is a core
  library for it. It also provides many Ruby libraries to integrate
  existing Ruby libraries with Apache Arrow. They use Red Arrow.
* **[SciDB][21]:** Paradigm4's SciDB is a scalable, scientific
  database management system that helps researchers integrate and
  analyze diverse, multi-dimensional, high resolution data - like
  genomic, clinical, images, sensor, environmental, and IoT data -
  all in one analytical platform. [SciDB streaming][22] and
  [accelerated_io_tools][24] are powered by Apache Arrow.
* **[TileDB][32]:** TileDB is an open-source, cloud-optimized engine for storing
  and accessing dense/sparse multi-dimensional arrays and dataframes. It is an
  embeddable C++ library that works on Linux, macOS, and Windows, which comes
  with numerous APIs and integrations. We use Arrow in our [TileDB-VCF][33]
  project for genomics to achieve zero-copying when accessing TileDB data from
  Spark and Dask.
* **[Turbodbc][4]:** Python module to access relational databases via the Open
  Database Connectivity (ODBC) interface. It provides the ability to return
  Arrow Tables and RecordBatches in addition to the Python Database API
  Specification 2.0.
* **[Vaex][38]:** Out-of-Core hybrid Apache Arrow/NumPy DataFrame for Python,
  ML, visualize and explore big tabular data at a billion rows per second.
* **[VAST][37]:** A network telemetry engine for data-driven security
  investigations. VAST uses Arrow as standardized data plane to provide a
  high-bandwidth output path for downstream analytics. This makes it easy and
  efficient to access security data via pyarrow and other available bindings.

[1]: https://www.apache.org/foundation/marks/
[2]: https://www.apache.org/foundation/marks/faq/
[3]: https://parquet.apache.org/
[4]: https://github.com/blue-yonder/turbodbc
[5]: https://github.com/ray-project/ray
[6]: https://ray-project.github.io/2017/08/08/plasma-in-memory-object-store.html
[7]: https://spark.apache.org/
[8]: https://github.com/locationtech/geomesa
[9]: https://www.dremio.com/
[10]: https://github.com/omnisci/mapd-core
[11]: https://gpuopenanalytics.com/
[12]: https://pandas.pydata.org
[13]: https://quiltdata.com/
[14]: https://github.com/gpuopenanalytics/libgdf
[15]: https://github.com/dask/dask
[16]: https://red-data-tools.github.io/
[17]: https://github.com/red-data-tools/red-arrow/
[18]: https://www.graphistry.com
[19]: http://gpuopenanalytics.com
[20]: https://github.com/abs-tudelft/fletcher
[21]: https://www.paradigm4.com
[22]: https://github.com/Paradigm4/stream
[23]: https://github.com/jpmorganchase/perspective
[24]: https://github.com/Paradigm4/accelerated_io_tools
[25]: https://github.com/uwdata/falcon
[26]: https://fastdata.io/
[27]: https://github.com/apache/arrow-site/edit/master/powered_by.md
[28]: https://github.com/uber/petastorm
[29]: https://www.inaccel.com/
[30]: https://www.mathworks.com
[31]: https://github.com/RandomFractals/vscode-data-preview
[32]: https://github.com/TileDB-Inc/TileDB
[33]: https://github.com/TileDB-Inc/TileDB-VCF
[34]: https://github.com/awslabs/aws-data-wrangler
[35]: https://cylondata.org/ 
[36]: https://bodo.ai
[37]: https://github.com/tenzir/vast
[38]: https://github.com/vaexio/vaex
[39]: https://hash.ai
[40]: https://github.com/pola-rs/polars
[41]: https://github.com/coady/graphique
[42]: https://github.com/influxdata/influxdb_iox
[43]: https://www.esri.com/en-us/arcgis/products/arcgis-python-libraries/libraries/arcpy
[44]: https://clickhouse.com/docs/en/interfaces/formats/#data-format-arrow
