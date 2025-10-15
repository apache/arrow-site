---
layout: post
title: "3x-8x Faster Apache Parquet Footer Metadata Using a Custom Thrift Parser in Rust"
date: "2025-10-08 00:00:00"
author: "Andrew Lamb (InfluxData)"
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

*Editor’s Note: While [Apache Arrow] and [Apache Parquet] are separate
projects, this post is part of the Arrow site because the Arrow [arrow-rs]
repository hosts the development of the [parquet] Rust crate, a widely used and
high-performance implementation of the Parquet format.*

## Summary

Version `57.0.0` of the [parquet] Rust crate decodes metadata roughly three times as
fast as previous versions thanks to a new custom [Apache Thrift] parser. The new
parser is 3× faster in all cases and enables further performance improvements not
possible with generated parsers, such as skipping unnecessary fields and selective parsing.

<!-- AAL: TODO: update the benchmark and charts with results from 57.0.0 -->

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/results.png" width="100%" class="img-responsive" alt="" aria-hidden="true">
</div>

*Figure 1:* Performance comparison of [Apache Parquet] metadata parsing using a generated
Thrift parser (versions `56.2.0` and earlier) and the new
[custom Thrift decoder] in [arrow-rs] version [57.0.0]. No
changes are needed to the Parquet format itself.
See the [benchmark page] for more details.

[parquet]: https://crates.io/crates/parquet
[Apache Arrow]: https://arrow.apache.org/
[Apache Parquet]: https://parquet.apache.org/
[custom Thrift decoder]: https://github.com/apache/arrow-rs/issues/5854
[arrow-rs]: https://github.com/apache/arrow-rs
[57.0.0]: https://github.com/apache/arrow-rs/issues/7835

[benchmark page]: https://github.com/alamb/parquet_footer_parsing

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/scaling.png" width="100%" class="img-responsive" alt="Scaling behavior of custom Thrift parser" aria-hidden="true">
</div>

*Figure 2:* Speedup of the [custom Thrift decoder] for string and floating-point data types,
for `100`, `1000`, and `100,000` columns. The new parser is faster in all cases,
and the speedup is similar regardless of the number of columns. See the [benchmark page] for more details.

## Introduction: Parquet and the Importance of Metadata Parsing

[Apache Parquet] is a popular columnar storage format. It
is designed to be efficient for both storage and query performance. Parquet
files consist of a header, a series of data pages, and a footer, as shown in Figure 3. The footer
contains metadata about the file, including schema, statistics, and other
information needed to decode the data.

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/parquet.png" width="100%" class="img-responsive" alt="Physical File Structure of Parquet" aria-hidden="true">
</div>

*Figure 3:* Structure of a Parquet file showing the header, data pages, and footer metadata.

Getting information stored in the footer is typically the first step in reading
a Parquet file, as it is required to interpret the data pages. *Parsing* the
footer is often performance critical when reading data:

* When reading from fast local storage, such as modern NVMe SSDs, footer parsing
  must be completed to know what data pages to read, placing it directly on the critical
  I/O path.
* Footer parsing scales linearly with the number of columns and row groups in a
  Parquet file and thus can be a bottleneck for tables with many columns or files
  with many row groups.
* For systems that cache the parsed footer in memory, as explained in [Using
  External Indexes, Metadata Stores, Catalogs and Caches to Accelerate Queries
  on Apache Parquet], the footer must still be parsed on cache miss.

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/flow.png" width="100%" class="img-responsive" alt="Typical Parquet processing flow" aria-hidden="true">
</div>

*Figure 4:* Typical processing flow for Parquet files for stateless and stateful
systems. Stateless engines read the footer on every query, and the time taken to
parse the footer directly adds to query latency. Stateful systems cache some or
all of the parsed footer in advance of queries. The performance of footer
parsing is important for both types of systems, but especially for stateless.

[Using External Indexes, Metadata Stores, Catalogs and Caches to Accelerate Queries on Apache Parquet]: https://datafusion.apache.org/blog/2025/08/15/external-parquet-indexes/

The speed of parsing metadata has grown even more important as Parquet spreads
throughout the data ecosystem and is used for more latency-sensitive workloads such
as observability, interactive analytics, and single-point
lookups for Retrieval-Augmented Generation (RAG) applications feeding LLMs. 
As overall query times decrease, the proportion spent on footer parsing increases.

## Background: Apache Thrift

Parquet stores metadata using [Apache Thrift], a framework for
network data types and service interfaces. It includes a [data definition
language] similar to [Protocol Buffers]. Thrift definition files describe data
types in a language-neutral way, and systems use code generators to
automatically create code for a specific programming language to read and write
those data types.

The [parquet.thrift] file defines the format of the metadata 
serialized at the end of each Parquet file in the [Thrift Compact 
protocol], as shown below in Figure 5. The binary encoding is "variable-length",
meaning that the length of each element depends on its content, not
just its type. Smaller-valued primitive types are encoded in fewer bytes than
larger values, and strings and lists are stored inline, prefixed with their
length.

This encoding is space-efficient but, due to being variable-length, does not
support random access: it is not possible to locate a particular field without
scanning all previous fields. Other formats such as [FlatBuffers] provide
random-access parsing and have been [proposed as alternatives] given their
theoretical performance advantages. However, changing the Parquet format is a
significant undertaking, requires buy-in from the community and ecosystem,
and would likely take years to be adopted.

[How Good is Parquet for Wide Tables (Machine Learning Workloads) Really?]: https://www.influxdata.com/blog/how-good-parquet-wide-tables/
[Apache Thrift]: https://thrift.apache.org/
[FlatBuffers]: https://google.github.io/flatbuffers/
[proposed as alternatives]: https://lists.apache.org/thread/j9qv5vyg0r4jk6tbm6sqthltly4oztd3

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/thrift-compact-encoding.png" width="100%" class="img-responsive" alt="Thrift Compact Encoding Illustration" aria-hidden="true">
</div>

*Figure 5:* Parquet metadata is serialized using the [Thrift Compact protocol].
Each field is stored using a variable number of bytes that depends on its value.
Primitive types use a variable-length encoding and strings and lists are
prefixed with their lengths.

[Thrift Compact protocol]: https://github.com/apache/thrift/blob/master/doc/specs/thrift-compact-protocol.md
[Protocol Buffers]: https://developers.google.com/protocol-buffers
[data definition language]: https://thrift.apache.org/docs/idl
[parquet.thrift]: https://github.com/apache/parquet-format/blob/master/src/main/thrift/parquet.thrift
[gRPC]: https://grpc.io/
[Xiangpeng Hao]: https://xiangpeng.systems/

Despite Thrift's very real disadvantage due to lack of random access, software
optimizations are much easier to deploy than format changes. [Xiangpeng Hao]'s
previous analysis theorized significant (2x–4x) potential performance
improvements simply by optimizing the implementation of Parquet footer parsing.
See the blog post [How Good is Parquet for Wide Tables (Machine Learning
Workloads) Really?] for more details.

## Processing Thrift Using Generated Parsers

*Parsing* Parquet metadata is the process of decoding the Thrift-encoded bytes
into in-memory structures that can be used for computation. Most Parquet
implementations use one of the existing [Thrift compilers] to generate a parser
that converts Thrift binary data into generated code structures, and then copy
relevant portions of those generated structures into API-level structures.
For example, the [C/C++ Parquet implementation] includes a [two]-[step] process,
as does [parquet-java]. [DuckDB] also contains a Thrift compiler–generated
parser.

In versions `56.2.0` and earlier, the Apache Arrow Rust implementation used the
same pattern. The [format] module contains a parser generated by the [thrift
crate] and the [parquet.thrift] definition. Parsing metadata involves:

1. Invoke the generated parser on the Thrift binary data, producing
   generated in-memory structures (e.g., [`struct FileMetaData`]), then
2. Copy the relevant fields into a more user-friendly representation,
   [`ParquetMetadata`].

[thrift crate]: https://crates.io/crates/thrift
[format]: https://docs.rs/parquet/56.2.0/parquet/format/index.html
[`ParquetMetadata`]: https://docs.rs/parquet/56.2.0/parquet/file/metadata/struct.ParquetMetaData.html
[`struct FileMetaData`]: https://docs.rs/parquet/56.2.0/parquet/format/struct.FileMetaData.html

[two]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/build-support/update-thrift.sh#L23
[step]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/src/parquet/thrift_internal.h#L56
[C/C++ Parquet implementation]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/src/parquet
[parquet-java]: https://github.com/apache/parquet-java/blob/0fea3e1e22fffb0a25193e3efb9a5d090899458a/parquet-format-structures/pom.xml#L69-L88
[DuckDB]: https://github.com/duckdb/duckdb/blob/8f512187537c65d36ce6d6f562b75a37e8d4ee54/third_party/parquet/parquet_types.h#L1-L6

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/original-pipeline.png" width="100%" class="img-responsive" alt="Original Parquet Parsing Pipeline" aria-hidden="true">
</div>

*Figure 6:* Two-step process to read Parquet metadata: A parser created with the
`thrift` crate and `parquet.thrift` parses the metadata bytes
into generated in-memory structures. These structures are then converted into
API objects.

The parsers generated by standard Thrift compilers typically parse *all* fields
in a single pass over the Thrift-encoded bytes, copying data into in-memory,
heap-allocated structures (e.g., Rust [`Vec`], or C++ [`std::vector`]) as shown
in Figure 7 below. 

Parsing all fields is straightforward and a good default
choice given Thrift's original design goal of encoding network messages.
Network messages typically don't contain extra information irrelevant for receivers; 
however, Parquet metadata often *does* contain information
that is not needed for a particular query. In such cases, parsing the entire
metadata into in-memory structures is wasteful. 

For example, a query on a file with 1,000 columns that reads 
only 10 columns and has a single column predicate
(e.g., `time > now() - '1 minute'`) only needs 

1. [`Statistics`] (or [`ColumnIndex`]) for the `time` column
2. [`ColumnChunk`] information for the 10 selected columns 

The default strategy to parse (allocating and copying) all statistics and all
`ColumnChunks` results in 999 more statistics and 990 more `ColumnChunks` being
parsed than are necessary. As discussed above, given the
variable encoding used for the metadata, all metadata bytes must still be
fetched and scanned; however, CPUs are (very) fast at scanning data, and
skipping *parsing* of unneeded fields speeds up overall metadata performance
significantly.

[`Vec`]: https://doc.rust-lang.org/std/vec/struct.Vec.html
[`std::vector`]: https://en.cppreference.com/w/cpp/container/vector.html
[Thrift compilers]: https://thrift.apache.org/lib/
[`Statistics`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L912
[`ColumnIndex`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L1163
[`ColumnChunk`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L958

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/thrift-parsing-allocations.png" width="100%" class="img-responsive" alt="Thrift Parsing Allocations" aria-hidden="true">
</div>

*Figure 7:* Generated Thrift parsers typically parse encoded bytes into
structures requiring many small heap allocations, which are expensive.

## New Design: Custom Thrift Parser

As is typical of generated code, opportunities for specializing
the behavior of generated Thrift parsers is limited:

1. It is not easy to modify (it is re-generated from the
   Thrift definitions when they change and carries the warning
   `/* DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING */`).
2. It typically maps one-to-one with Thrift definitions, limiting
   additional optimizations such as zero-copy parsing, field
   skipping, and amortized memory allocation strategies.
3. Its API is very stable (hard to change), which is important for easy maintenance when a large number
   of projects are built using the [thrift crate]. For example, the
   [last release of the Rust `thrift` crate] was almost three years ago at 
   the time of this writing.

[last release of the Rust `thrift` crate]: https://crates.io/crates/thrift/0.17.0


These limitations are a consequence of the design goals for producing code that
is general purpose and easy to embed in a wide variety of projects, rather than
any fundamental limitation of generated code.
Given our goal of fast Parquet metadata parsing, we concluded we
needed a custom parser that converts the Thrift binary directly into the needed
structures and is easier to optimize (Figure 8).

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/new-pipeline.png" width="100%" class="img-responsive" alt="New Parquet Parsing Pipeline" aria-hidden="true">
</div>

*Figure 8:* One-step Parquet metadata parsing using a custom Thrift parser. The
Thrift binary is parsed directly into the desired in-memory representation with
highly optimized code.

Our new custom parser is optimized for the specific subset of Thrift used by
Parquet and contains various performance optimizations, such as careful
memory allocation. The largest initial speedup came from removing
intermediate in-memory structures and directly creating the needed in-memory representation.
We also carefully hand-optimized several performance-critical code paths (see [#8574],
[#8587], and [#8599]).

[#8574]: https://github.com/apache/arrow-rs/pull/8574
[#8587]: https://github.com/apache/arrow-rs/pull/8587
[#8599]: https://github.com/apache/arrow-rs/pull/8599

### Maintainability

The largest concern with a custom parser is that it is more difficult
to maintain than generated parsers because the custom parser must be updated to
reflect any changes to [parquet.thrift]. This is a growing concern given the
resurgent interest in Parquet and the recent addition of new features such as
[Geospatial] and [Variant] types.

[Geospatial]: https://github.com/apache/parquet-format/blob/master/Geospatial.md
[Variant]: https://github.com/apache/parquet-format/blob/master/VariantEncoding.md

Thankfully, after discussions with the community, [Jörn Horstmann] developed
a [Rust macro based approach] for generating code with annotated Rust structs
that closely resemble the Thrift definitions while permitting additional hand
optimization where necessary. This approach is similar to the [serde] crate
where generic implementations can be generated with `#[derive]` annotations and
specialized serialization is written by hand where needed. [Ed Seidl] 
rewrote the metadata parsing code in the [parquet] crate using this
approach. Please see the [final PR] for details of the level of effort involved.

[final PR]: https://github.com/apache/arrow-rs/pull/8530
[Jörn Horstmann]: https://github.com/jhorstmann
[Ed Seidl]: https://github.com/etseidl
[Rust macro based approach]: https://github.com/jhorstmann/compact-thrift
[serde]: https://serde.rs/

For example, here is the original Thrift definition of the [`FileMetaData`] structure (comments omitted for brevity):

[`FileMetaData`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L1254C1-L1314C2

```thrift
struct FileMetaData {
  1: required i32 version
  2: required list<SchemaElement> schema;
  3: required i64 num_rows
  4: required list<RowGroup> row_groups
  5: optional list<KeyValue> key_value_metadata
  6: optional string created_by
  7: optional list<ColumnOrder> column_orders;
  8: optional EncryptionAlgorithm encryption_algorithm
  9: optional binary footer_signing_key_metadata
}
```

And here ([source]) is the corresponding Rust structure using the Thrift macros (before Ed wrote a custom version in [#8574]):

[source]: https://github.com/apache/arrow-rs/blob/02fa779a9cb122c5218293be3afb980832701683/parquet/src/file/metadata/thrift_gen.rs#L146-L158

```rust
thrift_struct!(
struct FileMetaData<'a> {
1: required i32 version
2: required list<'a><SchemaElement> schema;
3: required i64 num_rows
4: required list<'a><RowGroup> row_groups
5: optional list<KeyValue> key_value_metadata
6: optional string<'a> created_by
7: optional list<ColumnOrder> column_orders;
8: optional EncryptionAlgorithm encryption_algorithm
9: optional binary<'a> footer_signing_key_metadata
}
);
```

This system makes it easy to see the correspondence between the Thrift
definition and the Rust structure, and it is straightforward to support newly added
features such as `GeospatialStatistics`. The carefully hand-
optimized parsers for the most performance-critical structures, such as
`RowGroupMetaData` and `ColumnChunkMetaData`, are harder—though still
straightforward—to update (see [#8587]). However, those structures are less
likely to change frequently.

### Future Improvements

With the custom parser in place, we are working on additional improvements:

* Implementing special "skip" indexes to skip directly to the parts of the metadata
  that are needed for a particular query, such as the row group offsets.
* Selectively decoding only the statistics for columns that are needed for a particular query.
* Potentially contributing the macros back to the thrift crate.

### Conclusion

We believe metadata parsing in many open source Parquet
readers is slow primarily because they use parsers automatically generated by Thrift
compilers, which are not optimized for Parquet metadata parsing. By writing a
custom parser, we significantly sped up metadata parsing in the
[parquet] Rust crate, which is widely used in the [Apache Arrow] ecosystem.

While this is not the first open source custom Thrift parser for Parquet
metadata ([CUDF has had one] for many years), we hope that our results will
encourage additional Parquet implementations to consider similar optimizations.
The approach and optimizations we describe in this post are likely applicable to
Parquet implementations in other languages, such as C++ and Java. 

[CUDF has had one]: https://github.com/rapidsai/cudf/blob/branch-25.12/cpp/src/io/parquet/compact_protocol_reader.hpp

Previously, efforts like this were only possible at well-financed commercial
enterprises. On behalf of the arrow-rs and Parquet contributors, we are excited
to share this technology with the community in the upcoming [57.0.0] release and
invite you to [come join us] and help make it even better!

[come join us]: https://github.com/apache/arrow-rs/blob/main/CONTRIBUTING.md
