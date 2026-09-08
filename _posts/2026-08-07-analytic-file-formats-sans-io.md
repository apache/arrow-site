---
layout: post
title: "Implementing Analytic File Formats Sans I/O"
description: "Why separating Parquet decoding from storage I/O makes analytic file readers more composable, and how arrow-rs puts the design into practice"
date: "2026-08-07 00:00:00"
author: "Andrew Lamb, Xudong Wang, Neil Conway, and Daniël Heres"
categories: [parquet, arrow]
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

Opening a file, constructing a reader, and calling `next()` is a wonderfully
simple interface. It is also where many analytic file libraries accidentally
make a much larger architectural decision: **the decoder, rather than the
application, controls I/O**.

That choice works well until the decoder is embedded in a system with its own
storage runtime, buffer manager, cache, or scheduler. Such a system may want to
race object-store reads, use `io_uring`, account for every buffered byte, or
reuse pages that are already resident in memory. If the file reader performs
I/O internally, the application is limited to the policies anticipated by the
library author.

This post presents a different foundation for analytic file readers: **Sans
I/O**. A Sans I/O decoder contains all the knowledge needed to interpret a file,
but never reads the file itself. It reports which byte ranges it needs, and the
application decides how to obtain them.

> **The core idea:** format knowledge belongs in the decoder; I/O policy belongs
> in the application.

This post distills our CIDR 2027 paper, *Implementing Analytic File Formats Sans
I/O*, and describes the production implementation in the [Apache Arrow Rust
Parquet reader][arrow-rs-parquet].

## A Parquet reader is a small query engine

[Apache Parquet] is a good example of why the I/O boundary matters. Reading a
Parquet file is not a single sequential operation. Even a simplified decoder
alternates between I/O and CPU work across at least nine states.

The two diagrams in this post are reproduced from the paper under [CC BY 4.0].

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/parquet-state-machine.png"
       alt="Parquet decoding alternates between I/O and CPU stages for the file footer, metadata, optional pruning structures, and data pages"
       width="520" class="img-fluid">
  <figcaption>Figure 1 (paper Figure 2): The Parquet decoding state machine. Pink states perform I/O, yellow states perform CPU work, and dashed states are optional.</figcaption>
</figure>

The footer reveals where the file metadata lives. The metadata identifies row
groups and column chunks. Bloom filters and page indexes may eliminate some of
those chunks, and only then does the decoder know which data pages survive. The
answer to "what bytes are needed next?" therefore depends on information
decoded in earlier states, along with the query's projection, filters, and
limit.

There are several valid ways to orchestrate these reads:

- Prefetch the next predicted range while the CPU decodes the current one.
- Coalesce nearby ranges to reduce request count, at the cost of reading and
  buffering extra bytes.
- Interleave or race remote reads to reduce tail latency.
- Skip indexes that cannot help the current query or maintenance task.
- Reuse pages already owned by the application's buffer manager.

The best choice depends on the environment. Local NVMe, remote object storage,
an in-memory cache, `mmap`, RDMA, `O_DIRECT`, and `io_uring` have very different
latency, concurrency, alignment, and memory requirements. There is no single
read policy that is best for all of them.

## The hidden policy inside a pull API

Most analytic file libraries expose a pull interface modeled after a database
iterator. For example, the main Parquet Java API is conceptually as simple as:

```java
ParquetReader<Group> reader = ParquetReader.builder(
    new GroupReadSupport(), path
).build();

Group record;
while ((record = reader.read()) != null) {
  process(record);
}
```

The caller sees records, not reads. When the decoder needs another page, it
internally calls methods such as `seek` and `readFully` on a
`SeekableInputStream`. This is convenient for both the library implementer and
applications whose own execution model is also an iterator.

However, a replaceable storage interface is not the same thing as Sans I/O. A
callback such as `read_at(offset, length)` lets the application choose *where*
bytes come from, but the decoder still chooses *which* ranges to read, *when*
to issue each request, and often *where* to buffer the result.

This has two important consequences:

1. **I/O optimization is limited to what the reader implements.** Adding a
   new policy such as read racing or a workload-specific prefetcher requires a
   change inside the format library.
2. **Memory ownership becomes blurred.** Either the reader maintains a sizable
   private buffer pool, or the application adapts its own buffer manager to the
   reader's I/O abstraction. Both make global memory accounting harder.

### Async is useful, but it is not Sans I/O

An asynchronous reader can return control while an I/O operation is pending,
so a thread does not need to sit idle. That changes *how execution waits*. It
does not necessarily change *who owns the I/O policy*.

In most async readers, a future or stream still computes and issues reads
internally. The caller can await the result, but cannot inspect the decoder's
future byte requirements or substitute a different schedule for those reads.
By contrast, a Sans I/O decoder reports those requirements as data. It can be
driven by synchronous code, async code, a thread pool, a custom runtime, or no
runtime at all.

## The Sans I/O contract

We call an analytic file decoder Sans I/O if it performs no I/O, directly or
indirectly, and communicates all byte requirements to its caller.

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/architecture.png"
       alt="Side-by-side comparison of an integrated decoder, where I/O is orchestrated by the library and performed through a storage callback, and a Sans I/O decoder, where I/O is orchestrated and performed by the application"
       class="img-fluid">
  <figcaption>Figure 2 (paper Figure 1): An integrated reader accepts a storage callback but owns the read schedule. A Sans I/O reader leaves both orchestration and execution of I/O to the application.</figcaption>
</figure>

The contract has a small feedback loop. Each time the application asks the
decoder to advance, the decoder does one of three things:

1. Produces a decoded batch.
2. Reports that decoding is finished.
3. Returns the precise byte ranges needed to make progress.

For the third outcome, the application fetches those ranges using any strategy
and pushes the resulting buffers into the decoder. It may supply more data than
was requested, which permits prefetching. The decoder keeps all format
semantics, including pruning and the order in which metadata must be decoded,
while the host owns concurrency, caching, request coalescing, retries, memory,
and cost.

In simplified Rust, the interaction looks like this:

```rust
loop {
    match decoder.try_decode()? {
        DecodeResult::NeedsData(ranges) => {
            // Any storage API, cache, runtime, or policy can be used here.
            let buffers = io_policy.fetch(&ranges)?;
            decoder.push_ranges(ranges, buffers)?;
        }
        DecodeResult::Data(batch) => consume(batch)?,
        DecodeResult::Finished => break,
    }
}
```

This is a push-style storage API: the application asks the decoder to advance,
then pushes bytes into it when requested. "Push" here describes the boundary
between storage and decoding, not the execution model used by the rest of the
query engine.

## Putting the design into arrow-rs

The [`ParquetPushDecoder`] implementation was released in `arrow-rs` `57.1.0`.
It was motivated by two related problems: maintaining parallel synchronous and
asynchronous readers, and repeated requests from users who needed more control
over Parquet I/O.

A Sans I/O Parquet decoder cannot simply pause in the middle of a normal
function and wait for a read. It must preserve enough state to explain what it
needs and later resume after the caller supplies the bytes. The arrow-rs
implementation therefore models decoding as an explicit state machine. Its
[`try_decode`] method advances until it produces a batch, finishes, or
returns `NeedsData(Vec<Range<u64>>)`. [`push_ranges`] adds reference-counted
`Bytes` buffers without prescribing how they were fetched.

The explicit state machine pays off in reuse. The existing asynchronous
[`ParquetRecordBatchStream`] was [rewritten as a thin adapter][pr-8159] around
the push decoder: it fetches each `NeedsData` request through
`AsyncFileReader`, pushes
the buffers back, and exposes the familiar stream API. Applications that do
not need custom I/O still get a convenient reader, while format behavior lives
in one decoder core.

The decoding loop shown earlier starts after the file metadata is available. Footer and metadata
decoding follow the same pattern through [`ParquetMetaDataPushDecoder`], so the
application can control I/O from the first footer read through the final data
page.

## One decoder, many I/O policies

To demonstrate what the separation enables, our [prototype driver] uses the
same Arrow Rust decoder with four deliberately different policies:

<div class="table-responsive">
<table class="table">
  <thead>
    <tr>
      <th>Policy</th>
      <th>Physical reads</th>
      <th>Primary benefit</th>
      <th>Primary cost</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Exact range</td>
      <td>Read exactly the requested ranges</td>
      <td>Minimum over-read and buffering</td>
      <td>Potentially many requests</td>
    </tr>
    <tr>
      <td>Request coalescing</td>
      <td>Merge adjacent or nearby ranges</td>
      <td>Fewer physical requests</td>
      <td>Extra bytes and buffering</td>
    </tr>
    <tr>
      <td>Read-ahead</td>
      <td>Extend requested ranges and retain unused bytes</td>
      <td>Fewer future stalls and more cache hits</td>
      <td>More bandwidth and memory</td>
    </tr>
    <tr>
      <td>Full-file cache</td>
      <td>Fetch the file once and return zero-copy slices</td>
      <td>Zero-copy hits on subsequent requests (models a buffer manager or hot cache)</td>
      <td>Buffers the entire file</td>
    </tr>
  </tbody>
</table>
</div>

These policies optimize different things; the point is not that one always
wins. The point is that none requires a second Parquet implementation. A local
backend can use `io_uring`; an object-store backend can coalesce or race reads;
a database cache can return already-resident buffers by reference. The decoder
continues to request the same logical ranges and decode the same format.

This separation also makes measurement clearer. The application can account
independently for logical ranges requested by the decoder, physical storage
requests after policy decisions, bytes over-read, and peak buffered memory.

## What existing readers expose

We surveyed eight production-grade open-source analytic file readers. The
snapshot below reflects the versions examined for the paper in mid-2026. Every
reader offered an integrated I/O path; only Arrow Rust offered a production
public Sans I/O API, while cuDF exposed an experimental hybrid path.

<div class="table-responsive">
<table class="table">
  <thead>
    <tr>
      <th>Implementation</th>
      <th>Format</th>
      <th>Public Sans I/O path</th>
      <th>Prefetch / coalescing</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Apache Arrow C++</td><td>Parquet</td><td>No</td><td>Internal and external</td></tr>
    <tr><td>Apache Parquet Java</td><td>Parquet</td><td>No</td><td>Internal</td></tr>
    <tr><td>Apache Arrow Go</td><td>Parquet</td><td>No</td><td>None</td></tr>
    <tr><td>Apache Arrow Rust</td><td>Parquet</td><td>Yes</td><td>External</td></tr>
    <tr><td>cuDF (RAPIDS)</td><td>Parquet</td><td>Experimental</td><td>Internal; experimental external path</td></tr>
    <tr><td>hyparquet</td><td>Parquet</td><td>No</td><td>Internal</td></tr>
    <tr><td>Vortex</td><td>Vortex</td><td>No</td><td>Internal and external</td></tr>
    <tr><td>Lance</td><td>Lance</td><td>No</td><td>Internal and external</td></tr>
  </tbody>
</table>
</div>

Many of these are well-designed readers with extensible storage interfaces,
zero-copy buffers, and sophisticated prefetchers. The distinction is about
control: even when the byte source is pluggable, an integrated decoder still
decides the read schedule. Some systems, including DuckDB and Polars, go
further and maintain embedded readers tightly coupled to their own runtimes and
buffer managers. Those readers can be very effective, but their format logic
is not available as a reusable public library.

## Why streaming CSV and JSON already look familiar

Sans I/O is not a new idea. The term came from the Python networking community,
where protocol libraries such as `h11` and `h2` operate as state machines over
caller-provided bytes. Streaming CSV and JSON parsers commonly use the same
shape: accept a byte chunk, emit records or tokens, and report when more input
is needed.

These formats have an easier answer to "what bytes are needed next?": usually,
the next bytes in the stream. Analytic formats such as Parquet must request
non-contiguous footers, metadata blocks, indexes, and selected pages. The idea
is the same, but the API must communicate byte ranges rather than simply ask
for another sequential chunk.

## Tradeoffs and design guidance

Sans I/O moves complexity to an explicit boundary; it does not make that
complexity disappear.

- **The decoder is harder to implement.** State that was implicit in a call
  stack or async future must become an explicit, testable state machine.
- **The host must drive the feedback loop.** Applications with no special I/O
  requirements should not have to write that loop themselves, so libraries
  should ship synchronous and asynchronous adapters.
- **Performance is not automatic.** Sans I/O enables a system-specific policy;
  the application still has to choose and implement a good one.
- **The boundary must preserve zero-copy operation.** Callers should be able to
  provide reference-counted or otherwise borrowed resident buffers, including
  data fetched speculatively.

For new analytic formats, we recommend making the Sans I/O state machine the
decoder core, then layering blocking, async, memory-mapped, and prefetching
readers on top. Format-specific choices such as pruning remain inside that
core. Storage-specific choices such as request size, concurrency, caching, and
buffer ownership remain outside.

## Conclusion

A file reader API is more than a convenience wrapper. It determines whether a
database can combine shared, well-tested format logic with the I/O and memory
architecture that makes the database distinctive.

Tightly integrated readers are easy to start with and remain useful as
adapters. But when they are the only API, applications must either accept the
reader's policy or build another decoder. Sans I/O provides a third option: one
reusable implementation of the format, with I/O orchestration owned by each
host system. That is a better fit for the increasingly composable data systems
being built around Arrow and Parquet.

The paper *Implementing Analytic File Formats Sans I/O* is by Andrew Lamb,
Xudong Wang, Neil Conway, and Daniël Heres and appears at CIDR 2027. The paper
is licensed under [CC BY 4.0]. We thank InfluxData, Massive, and Coralogix for
supporting this work.

[Apache Parquet]: https://parquet.apache.org/
[arrow-rs-parquet]: https://github.com/apache/arrow-rs/tree/57.1.0/parquet
[`ParquetPushDecoder`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html
[`try_decode`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.try_decode
[`push_ranges`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.push_ranges
[`ParquetRecordBatchStream`]: https://docs.rs/parquet/57.1.0/parquet/arrow/async_reader/struct.ParquetRecordBatchStream.html
[pr-8159]: https://github.com/apache/arrow-rs/pull/8159
[`ParquetMetaDataPushDecoder`]: https://docs.rs/parquet/57.1.0/parquet/file/metadata/struct.ParquetMetaDataPushDecoder.html
[prototype driver]: https://github.com/xudong963/push_decoder_policies
[CC BY 4.0]: https://creativecommons.org/licenses/by/4.0/
