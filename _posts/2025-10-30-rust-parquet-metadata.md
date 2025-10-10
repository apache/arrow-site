---
layout: post
title: "Using a Custom Thrift Parser to Speedup Apache Parquet Metadata Parsing 2x in Rust"
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

*Editors Note: While [Apache Arrow] and [Apache Parquet] are separate
projects, this post is part of the arrow site because the Arrow [arrow-rs]
repository hosts the development of the [parquet] Rust crate, a widely used and
high performance implementation of the Parquet format. *

## Summary

Version `57.0.0` of the  [parquet] Rust crate decodes parquet metadata twice as
fast as previous versions thanks to a new custom Apache Thrift parser. The new
parser is not only 2x faster in all cases, it sets the stage for further
improvements such as skipping unnecessary fields and selectively parsing only
the minimum fields needed for a particular query.

<!-- AAL: TODO: update the benchmark and charts with results from 57.0.0 -->


<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/results.png" width="100%" class="img-responsive" alt="" aria-hidden="true">
</div>

**Figure 1**: Performance of [Apache Parquet] metadata parsing using a
[custom thrift decoder] in [arrow-rs] version [57.0.0]. No
changes are needed to the Parquet format itself. 
See the [benchmark page] for more details.

[parquet]: https://crates.io/crates/parquet
[Apache Arrow]: https://arrow.apache.org/
[Apache Parquet]: https://parquet.apache.org/
[custom thrift decoder]: https://github.com/apache/arrow-rs/issues/5854
[arrow-rs]: https://github.com/apache/arrow-rs
[57.0.0]: https://github.com/apache/arrow-rs/issues/7835

[benchmark page]: https://github.com/alamb/parquet_footer_parsing

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/scaling.png" width="100%" class="img-responsive" alt="Scaling behavior of custom thrift parser" aria-hidden="true">
</div>

**Figure 2**: Speedup of the [custom thrift decoder] for both string and floating point 
types, for `100`, `1000`, and `100,000` columns. The new parser is faster in all cases,
and the speedup is similar for all cases. See the [benchmark page] for more details.

## Introduction

[Apache Parquet] is a popular columnar storage format for big data processing. It
is designed to be efficient for both storage and query performance. Parquet
files consist of a header, a series of row groups, and a footer as shown in Figure 3. The footer
contains metadata about the file, including the schema, statistics, and other
information needed to read and process the data.

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/parquet.png" width="100%" class="img-responsive" alt="Physical File Structure of Parquet" aria-hidden="true">
</div>

**Figure 3:** Structure of a Parquet file, showing the header, row groups, and footer.

Footer parsing is often a critical step in reading Parquet files, as it provides
the necessary information to interpret the data stored in those Parsing the footer is
often on the critical query path for systems
that do not cache the required information from the footer (stateless), so the performance of
footer parsing can be a significant amount of query performance, especially
when reading from fast  local storage such as modern NVMe SSDs. Footer parsing
performance is especially important for files with many columns or row groups,
when queries only need to read a subset of columns, or when reading many small files.

Even though many low latency systems cache the parsed footer to avoid this cost,
explained in [Using External Indexes, Metadata Stores, Catalogs and Caches to Accelerate Queries on Apache Parquet],
the performance of footer parsing is still important when the cache is cold or 
the hit rate is low. 

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/flow.png" width="100%" class="img-responsive" alt="Typical parquet processing flow" aria-hidden="true">
</div>

**Figure 4**: Typical processing flow for processing of Parquet files for stateless and stateful systems.
The performance of footer parsing is important for both types of systems, but especially
for stateless systems that do not cache the parsed footer.

[Using External Indexes, Metadata Stores, Catalogs and Caches to Accelerate Queries on Apache Parquet]: https://datafusion.apache.org/blog/2025/08/15/external-parquet-indexes/

The speed of parsing metadata has grown in importance as parquet has been used
in more and more real time applications, where the latency of reading many
parquet files is important, such as in observability (TODO find citations),
interactive analytics, and most recently single point lookups for Results
Augmented Generation (RAG) applications to feed LLMs (TODO find citations),
which the latency of reading data from parquet files can be a significant part
of the overall latency.

An often criticized part of the Parquet format is that it uses [Apache Thrift]
for serialization of the metadata. Thrift is a flexible and efficient
serialization framework, but does not provide random access parsing. Other
formats such as [Flatbuffers] which do provide zero copy and random access
parsing have [been proposed as alternatives] given their theoretical performance
advantages. However, changing the Parquet format is a significant undertaking,
and requires buy-in from the community and ecosystem and can take years to be
adopted.

Despite the very real disadvantage of thrift, we have previously theorized in
[How Good is Parquet for Wide Tables (Machine Learning Workloads) Really?] that
there is still room for significant performance improvements in Parquet footer
parsing in Rust using the existing thrift format but improving the thrift
decoder implementation.

[How Good is Parquet for Wide Tables (Machine Learning Workloads) Really?]: https://www.influxdata.com/blog/how-good-parquet-wide-tables/
[Apache Thrift]: https://thrift.apache.org/
[Flatbuffers]: https://google.github.io/flatbuffers/



## Background: Apache Thrift

[Apache Thrift] is a framework for defining network data types and service
interfaces and includes a data definition language similar to [Protocol Buffers].
Thrift [Definition Files] describe data types in a language-neutral way, and
then code generators exist to create code for a variety of programming languages
to read and write those data types.

Parquet metadata is defined in [parquet.thrift] and is stored in the files using
the [Thrift compact binary encoding format], as shown in the figure below. This
encoding is "variable length", meaning that the length of each element depends
on its content, not just its type. This means that smaller values for primitive
types use fewer bytes. Strings and lists are stored inline and prefixed with
their length in bytes. This encoding is space efficient, but its variable length
nature means it is not possible to locate a particular field without scanning
all previous fields.

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/thrift-compact-encoding.png" width="100%" class="img-responsive" alt="Original Parquet Parsing Pipeline" aria-hidden="true">
</div>

*Figure X:* Parquet metadata is serialized using the [Thrift compact binary
encoding format]. Each field is stored using a variable number of bytes that
depends on its value. Primitive types use a variable length encoding and strings
and lists are prefixed with their length in bytes. 

[Thrift compact binary encoding format]: https://github.com/apache/thrift/blob/master/doc/specs/thrift-compact-protocol.md
[Protocol Buffers]: https://developers.google.com/protocol-buffers
[Definition Files]: https://thrift.apache.org/docs/idl
[parquet.thrift]: https://github.com/apache/parquet-format/blob/master/src/main/thrift/parquet.thrift
[gRPC]: https://grpc.io/



## Parsing Thrift using Generated Parsers

*Parsing* Parquet metadata is the process of decoding the Thrift encoded data into
in-memory structures that can be used for computation, shown in the figure below. 
Most Parquet implementations use one of the existing [thrift compilers] to generate
the code to parse the Thrift binary data into in-memory structures as shown below.

Previously, the Apache Arrow Rust implementation used the [thrift crate] to
parse the thrift bytes into in-memory structures (the [format] module), and then copied the result
into an API structure [`ParquetMetadata`]. The [c++ Parquet implementation] uses
a similar [two] [step process] using the Apache Thrift C++ library as does
[parquet-java] and [duckdb].

[thrift crate]: https://crates.io/crates/thrift
[format]:https://docs.rs/parquet/56.2.0/parquet/format/index.html
[`ParquetMetadata`]: https://docs.rs/parquet/56.2.0/parquet/file/metadata/struct.ParquetMetaData.html

[two]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/build-support/update-thrift.sh#L23
[step process]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/src/parquet/thrift_internal.h#L56
[c++ Parquet implementation]: https://github.com/apache/arrow/blob/e1f727cbb447d2385949a54d8f4be2fdc6cefe29/cpp/src/parquet
[parquet-java]: https://github.com/apache/parquet-java/blob/0fea3e1e22fffb0a25193e3efb9a5d090899458a/parquet-format-structures/pom.xml#L69-L88
[duckdb]: https://github.com/duckdb/duckdb/blob/8f512187537c65d36ce6d6f562b75a37e8d4ee54/third_party/parquet/parquet_types.h#L1-L6

<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/original-pipeline.png" width="100%" class="img-responsive" alt="Original Parquet Parsing Pipeline" aria-hidden="true">
</div>

Figure 2: Two step process to read parquet metadata: use code generated by the thrift crate to parse
the thrift binary into in-memory structures, then convert the in-memory structures into arrow's

The parsers generated by standard Thrift compilers typically parse *all* fields
in a single pass over the thrift encoded bytes, copying data into in-memory, heap
allocated structures such as a Rust [`Vec`], or C++ [`std::vector`], as
shown in the figure below. This approach is simple and straightforward and a good
choice given Thrift's design point of encoding network messages, which typically
don't send extraneous information. However, reading all fields and allocating
memory for them is not necessary in many cases when reading Parquet metadata.


[`Vec`]: https://doc.rust-lang.org/std/vec/struct.Vec.html
[`std::vector`]: https://en.cppreference.com/w/cpp/container/vector.html
[thrift compilers]: https://thrift.apache.org/lib/

For some use cases, such as caching the parsed Parquet metadata, all the fields
are needed and thus must be parsed. However, for many use cases, parsing the
entire metadata into in memory structures is wasteful. For example, a query that
reads only 10 columns from a file with 1000 columns with a single column predicate
(e.g. `time > now() - '1 minute'`) only needs [`Statistics`] (or
[`ColumnIndex`]) for the predicate column and the [`ColumnChunk`] for the 10 columns. Parsing (allocating and copying)
statistics for remaining 999 columns which are not used in predicates is
unnecessary work. While all the metadata bytes must still be fetched and scanned
to find the relevant positions, CPUs are quite fast at scanning data, so skipping parsing
unnecessary data can speed up overall metadata parsing significantly.


[`Statistics`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L912
[`ColumnIndex`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L1163
[`ColumnChunk`]: https://github.com/apache/parquet-format/blob/9fd57b59e0ce1a82a69237dcf8977d3e72a2965d/src/main/thrift/parquet.thrift#L958


<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/thrift-parsing-allocations.png" width="100%" class="img-responsive" alt="Original Parquet Parsing Pipeline" aria-hidden="true">
</div>

*Figure XX*: Generated thrift parsers typically parse into heap allocated structures requiring
many small heap allocations, which are expensive.



## New Design: Custom Thrift Parser

As is typical of code generated from another tool, opportunities for
optimization in the code generated by the thrift compilers are typically
limited:

1. The generated code is not easy to modify (it must be re-generated from from the thrift definitions when the definitions change)
2. Since the generated code must be general purpose and easy to embed, it typically
   maps one to one with thrift definitions, 
   which limits adding additional optimizations such as zero copy parsing, or 
   amortized memory allocation strategies.
3. Thrift compilers are quite stable, which is important to enable embedding 
   generated code, but also limits new optimizations. For example, the [last release of the Rust  `thrift` crate] 
   was almost three years ago.

[last release of the Rust `thrift` crate]: https://crates.io/crates/thrift/0.17.0

Thus, we concluded that we needed a custom thrift parser that could be optimized
for the specific subset of the Thrift format used by Parquet. 
So we instead wrote a custom parser that parses the thrift binary directly into the needed
structures as shown in the figure below. 


<!-- Image source: https://docs.google.com/presentation/d/1WjX4t7YVj2kY14SqCpenGqNl_swjdHvPg86UeBT3IcY -->
<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start;">
  <img src="{{ site.baseurl }}/img/rust-parquet-metadata/new-pipeline.png" width="100%" class="img-responsive" alt="New Parquet Parsing Pipeline" aria-hidden="true">
</div>

Figure 3: New one step process to read parquet metadata: use a custom parser to parse the thrift binary directly
own in-memory representation of parquet metadata.

The custom parser is optimized for the specific subset of the Thrift format used
by Parquet, and by using various performance optimizations, such as careful memory 
allocation and avoiding unnecessary copies. 

The largest initial speedup came from removing  intermediate in-memory
structures, and instead simply created the needed in-memory representation of
parquet metadata. We also carefully hand optimized certain thrift decoding and
memory allocation paths, 


### Maintainability

THe largest concern with this approach is that it is more difficult to maintain, as any changes to the [`parquet.thrift`] file 
must be manually reflected in the custom parser, and the thrift definitions
do get updated regularly (e.g. for the recent additions of [Geospatial] and [Variant] types)

[Geospatial]: https://github.com/apache/parquet-format/blob/master/Geospatial.md
[Variant]: https://github.com/apache/parquet-format/blob/master/VariantEncoding.md

However, [Jörn Horstmann] prototyped a [Rust macro
based approach] that generates parsing code for annotated Rust structs
that closely resemble the thrift definitions. Structs that need additional optimization
can be manually implemented (for example, in [this PR]. This approach is similar to how the [serde] crate
generates serialization and deserialization code for Rust structs.
[Ed Seidl] applied this approach and rewrote the metadata parsing code in the
[parquet] crate.


[this PR]: https://github.com/apache/arrow-rs/pull/8574/files

[Jörn Horstmann]: https://github.com/jhorstmann
[Ed Seidl]: https://github.com/etseidl
[Rust macro based approach]: https://github.com/jhorstmann/compact-thrift
[serde]: https://serde.rs/

<!-- https://x.com/jhorstmann23/status/1803426667748053448--> 

For example, here is the thrift definition of the [`FileMetaData`] structure (comments omitted for brevity):

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

And here ([source]) is the corresponding annotated Rust structure:

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

This organization makes it easy to see the correspondence between the thrift definition
and the Rust structure, and makes it easy to update the Rust structure when the
thrift definition changes.



### Future Improvements


With a custom parser, we can now also consider other improvements such as
* Implementing special "skip" indexes to skip directly to the parts of the metadata
  that are needed for a particular query, such as the row group offsets
* Selectively decode only the statistics for columns that are needed for a particular query

* Potentially contribute the macros back to the thrift crate to support skipping fields

### Conclusion

We believe that much of the reason metadata parsing in open source Parquet readers
is slow is that they use code generated by thrift compilers, which are not
optimized for the specific use case of Parquet metadata parsing. By writing a
custom parser, we were able to significantly speed up metadata parsing in the
[parquet] Rust crate, which is widely used in the [Apache Arrow] ecosystem.

This is the first effort we are aware of to write a custom thrift parser
specifically for Parquet metadata parsing. We believe that this approach can be
applied to other Parquet implementations in other languages, such as C++ and
Java, to achieve similar performance improvements. We hope that this work will
inspire others to explore similar optimizations in their own Parquet
implementations.

Finally, efforts such as this have previously only been possible at
well-financed commercial enterprises, which kept their implementations closed
source. We are excited to share this technology in the upcoming [57.0.0] release
of the [parquet] crate with the broader community and we hope you will join us
in further improving the performance of Parquet. Please [come join us]

[come join us]: https://github.com/apache/arrow-rs/blob/main/CONTRIBUTING.md
