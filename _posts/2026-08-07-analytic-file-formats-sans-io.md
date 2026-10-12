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
simple interface. The reader handles fetching, buffering, and decoding, and
many applications need nothing more. The boundary becomes harder to work with
when the application already has a storage runtime, buffer manager, cache, or
scheduler of its own.

Consider a query engine scanning several Parquet files under a shared memory
budget. It wants to serve cached ranges immediately, prioritize reads for one
query, and overlap decoding with remote I/O. To coordinate that work, it needs
to know both **what bytes the decoder needs** and **when decoding can proceed**.
A storage callback exposes some of this information, but the rest may remain
inside the reader's control loop.

A **Sans I/O** decoder makes that boundary explicit. It interprets bytes but
never fetches them. When it cannot continue, it returns the byte ranges it
needs; the application supplies buffers and decides when to resume decoding.
Familiar blocking and asynchronous readers can be adapters around this core.

> **The core idea:** the decoder determines its byte dependencies; the
> application schedules the I/O that satisfies them.

Sans I/O is an established pattern in [network protocol libraries][sans-io].
This post explores its application to analytic file formats, using the
[Apache Arrow Rust Parquet reader][arrow-rs-parquet]. The benefit is a reusable
decoder that can fit different execution and storage policies. Performance
still depends on the policy, workload, and implementation.

## The Sans I/O contract

The decoder performs no I/O, including through callbacks. Each time the
application asks it to advance, it does one of three things:

1. Produces decoded data.
2. Reports that decoding is finished.
3. Returns the byte ranges needed to make progress.

For the third outcome, the application obtains the bytes from storage or a
cache, supplies them to the decoder, and tries again. Errors propagate through
the API as usual. In simplified Rust, with application-provided `fetch` and
`consume` helpers, the interaction looks like this:

```rust
loop {
    match decoder.try_decode()? {
        DecodeResult::NeedsData(ranges) => {
            // Fetch or reuse one buffer for each logical range, in order.
            let buffers = io_policy.fetch(&ranges)?;
            decoder.push_ranges(ranges, buffers)?;
        }
        DecodeResult::Data(batch) => consume(batch)?,
        DecodeResult::Finished => break,
    }
}
```

The logical ranges describe the decoder's requirements, not necessarily the
physical reads. A policy can merge nearby ranges into one storage request and
return slices of the resulting buffer. It can also retain extra bytes in a
cache for later requests. The decoder does not need to know which happened.

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/architecture.png"
       alt="An integrated reader invokes a storage callback from its decoding loop; a Sans I/O decoder returns byte requirements for the application to schedule and supply"
       class="img-fluid">
  <figcaption>Figure 1: Moving byte requests out of the decoder's control loop gives the application an explicit boundary for scheduling I/O and decoding.</figcaption>
</figure>

This is a push-style storage API: the application asks the decoder to advance,
then pushes bytes into it. "Push" describes the boundary between storage and
decoding, not the execution model of the rest of the query engine.

## A Parquet reader is a small query engine

Streaming CSV and JSON parsers already use a similar pattern: accept a byte
chunk, emit records or tokens, and ask for more input. Their next input is
usually the next chunk in the stream. [Apache Parquet] requires a more complex
conversation because its reads are non-sequential and depend on earlier data.

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/parquet-state-machine.png"
       alt="Parquet decoding alternates between I/O and CPU stages for the file footer, metadata, optional pruning structures, and data pages"
       width="520" class="img-fluid">
  <figcaption>Figure 2: A simplified Parquet decoding state machine. Pink states perform I/O, yellow states perform CPU work, and dashed states are optional.</figcaption>
</figure>

The file's trailing footer tells the reader how much metadata to fetch. That
metadata locates row groups and column chunks. Optional Bloom filters and page
indexes can help eliminate row groups or pages before reading their data.
Evaluating a predicate on one column can further reduce which pages are needed
from another. The next byte requirements therefore depend on previously
decoded information, as well as the query's projection and filters.

A reusable decoder must preserve these dependencies while letting the host
choose how to satisfy them. Query planning still supplies choices such as
columns, row selections, and predicates; the decoder handles the format logic
needed to execute that selection. Separating I/O does not require giving up
filter pushdown or moving Parquet parsing into the application.

## Why not just use a storage callback or async reader?

A replaceable storage interface is already powerful. A `read_at(offset,
length)` callback can serve cache hits, retry failures, or race reads against
multiple replicas. An async implementation can queue requests in a shared
scheduler and return futures for their results. These optimizations do not
inherently require Sans I/O; the [Arrow Rust design discussion][async-callback]
explicitly considered such an arrangement.

The distinction is which decisions the public API exposes. A storage callback
sees requests when the reader issues them. It does not, by itself, expose a
separate operation to advance format processing, obtain ready-to-decode work,
or discover requirements beyond the reader's current suspension point. A
batched or asynchronous callback can offer substantial scheduling control, but
that control still depends on the reader's buffering and execution contract.

Async changes how execution waits. Sans I/O makes the decoder's byte
dependencies and resumption points explicit, independently of any particular
I/O interface. The host can keep pending requirements as ordinary data and
advance each decoder when its scheduler is ready. Reproducing this boundary
with callbacks is possible, but can require coordinating channels, futures,
and polling around the reader's control loop.

If a reader's existing callbacks and buffering policy fit the application,
there is no need to replace them. Sans I/O is useful when the application needs
the lower-level boundary as a supported library API.

## Where the boundary helps in practice

Two discussions that motivated the Arrow Rust work show why that boundary
matters.

In [the original design issue][io-motivation], Andrew described
buffering entire files in memory or on local SSD because the reader did not
expose enough information to coordinate more selective prefetching. The
alternative was a series of smaller reads interleaved with decoding, a poor
fit for high-latency remote storage. Whole-file buffering was a workable
integration strategy, but it consumed resources and gave up some of the
benefits of reading only selected columns and pages.

A [separate discussion about incremental decoding][incremental-decoding]
described the memory cost of buffering the pages for all selected columns in a
row group. A later [production report][wide-column-report] highlighted the
problem for columns containing very large values. A storage callback can
change how the bytes arrive, but it cannot change a decoder's requirement to
buffer that set of pages before making progress. This case also illustrates a
limit of the abstraction: exposing byte requests alone does not make a decoder
incremental at every page boundary.

### Overlapping decoding and reads

Arrow Rust provides a concrete example of a richer boundary through
[`try_next_reader`]. Once the required data is available, this method returns a
`ParquetRecordBatchReader` over buffered data. The application can then:

1. Send that reader to a CPU worker to produce batches.
2. Advance the push decoder to discover the next set of byte requirements.
3. Schedule those reads while the worker decodes the preceding data.
4. Limit the number of active readers and pending reads according to its
   memory and CPU budgets.

This gives the scheduler separate handles for batch decoding and further I/O.
An ordinary storage callback cannot create that handoff on its own: the reader
also needs to expose a suitable unit of decoding work. Our [example
driver][prototype driver] demonstrates the handoff; a production scheduler
would also bound the worker queue and preserve batch order where required.

A decoder integrated into a database can implement the same overlap. The
reason to expose it in a shared library is to let other systems use that
format implementation with their own scheduling policy.

## Putting the design into arrow-rs

The APIs described here are available in `arrow-rs` `57.1.0`.
[`ParquetPushDecoder`] preserves decoding state between calls to [`try_decode`]
and returns `NeedsData(Vec<Range<u64>>)` when bytes are missing. [`push_ranges`]
accepts reference-counted `Bytes` buffers, allowing the caller to share
resident input without copying it at the API boundary. Decompression and
construction of Arrow arrays can still require allocations.

The earlier loop starts after file metadata is available. Footer and metadata
decoding use the same pattern through [`ParquetMetaDataPushDecoder`], so the
application can control fetching from the first footer read onward.

The existing asynchronous [`ParquetRecordBatchStream`] was [rewritten as an
adapter][pr-8159] around the push decoder. It fetches `NeedsData` requests
through `AsyncFileReader`, supplies the buffers, and exposes the familiar
stream API. This consolidates decoding control flow while retaining a
convenient entry point for applications that do not need custom orchestration.

## What the decoder can tell a prefetcher

`NeedsData` describes what is missing at the current decoding step. It is not
a complete plan for all future reads. If a predicate has not yet been
evaluated, the decoder may not know which pages of another column will survive.
A range-only interface also does not tell the host whether a request is for
metadata, a predicate column, or output data.

There are several levels of prefetching. A host can read ahead around a known
range, or speculatively fetch a larger file tail to avoid a second metadata
read. With `try_next_reader`, it can discover later requirements while earlier
batches are being decoded. More selective lookahead may need additional
format-aware planning APIs that expose candidate ranges and their dependencies.
Those candidates can change after pruning; a scheduler must distinguish them
from ranges required to make progress now.

Sans I/O therefore gives a prefetcher a place to operate, but does not supply
all the information a sophisticated prefetcher needs. Useful format knowledge
must remain accessible through the library's API rather than be reconstructed
in every storage adapter.

## One decoder, many I/O policies

Our [example driver][prototype driver] uses the same decoder with four I/O
policies. They illustrate different choices at this boundary:

<div class="table-responsive">
<table class="table">
  <thead>
    <tr>
      <th>Policy</th>
      <th>Physical reads</th>
      <th>When to consider it</th>
      <th>Primary cost</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Exact range</td>
      <td>Read only the requested ranges</td>
      <td>Low-latency storage or expensive over-reading</td>
      <td>Potentially many requests</td>
    </tr>
    <tr>
      <td>Request coalescing</td>
      <td>Merge adjacent or nearby ranges, then return slices</td>
      <td>High per-request overhead and small gaps between ranges</td>
      <td>Extra bytes and buffering</td>
    </tr>
    <tr>
      <td>Read-ahead</td>
      <td>Extend requested ranges and cache unused bytes</td>
      <td>Likely reuse of nearby bytes and available memory</td>
      <td>Wasted bandwidth and memory when predictions miss</td>
    </tr>
    <tr>
      <td>Full-file cache</td>
      <td>Fetch once and return shared slices</td>
      <td>Small files, repeated scans, or already-resident data</td>
      <td>Retains the entire file</td>
    </tr>
  </tbody>
</table>
</div>

The tradeoff is between request overhead, extra bytes read, and retained
memory. Coalescing is attractive when the avoided request costs more than
reading the intervening bytes. Read-ahead depends on those bytes being useful
soon enough to justify retaining them. Full-file caching can be appropriate
for a small hot file and wasteful for a large selective scan.

These are composable choices: a host might satisfy cache hits first and
coalesce only the misses. The examples show that policies can change without
changing the decoder; they do not establish a universally faster policy.

## Building on existing designs

The separation has substantial precedent. Beyond [networking Sans I/O][sans-io]
and streaming parsers, [`parquet2`][parquet2] separates reading compressed pages
from decompression and deserialization, leaving parallelism to its users.
[Polars' Parquet implementation][polars-parquet] also exposes distinct reading,
compression, and page modules. These are useful forms of separation, with
boundaries at different levels of the read pipeline.

cuDF's [experimental hybrid scan reader][cudf-hybrid] exposes methods to obtain
page-index and column-chunk byte ranges and to supply buffers for processing.
It illustrates how explicit byte dependencies can support a staged scan API,
even when the interface is specific to a particular execution environment.

Page-level building blocks let the host assemble its own scan control loop.
The push decoder keeps that format-dependent state machine in the library,
exposing its byte requirements across metadata, filtering, and data decoding.
This packages established separation-of-concerns ideas into a reusable API for
a format whose future reads depend on earlier results. Integrated readers can
also provide sophisticated scheduling; the useful boundary depends on which
parts of the scan the host needs to control.

## Costs and open challenges

Sans I/O moves complexity to an explicit boundary; it does not make that
complexity disappear.

- **State-machine complexity.** A decoder must preserve partially completed
  work, buffer references, and error state across resumptions. A refactor must
  retain the existing reader's handling of nested data, dictionaries, filters,
  and optional indexes. Shared conformance tests help keep adapters consistent.
- **Buffer ownership and accounting.** Reference-counted input avoids copies,
  but a small slice can keep a large allocation alive. The host must account
  for caches, outstanding reads, decoder inputs, decompression buffers, and
  output batches. Arrow Rust's [`buffered_bytes`] reports unconsumed input
  bytes, not total memory usage.
- **Backpressure and read granularity.** The host can stop advancing decoders
  or issuing speculative reads when its budget is full. It must still allow
  enough memory to satisfy a decoder's next dependency set. In the version
  described here, a step can require pages across the selected columns of a
  row group; reducing output batch size alone does not bound input buffering.
- **Concurrency and cancellation.** The host must track outstanding reads and
  their destination decoders, handle completions, and serialize mutation of
  each decoder. On cancellation, it must cancel or disregard pending results
  and release its buffers. Dropping the decoder alone does not cancel I/O
  owned by the application.
- **Preserving performance.** Matching a tuned integrated reader requires
  preserving effective pruning, coalescing, CPU/I/O overlap, and buffer reuse.
  Extra allocations, tiny requests, or excessive task handoffs can erase the
  benefits. The boundary makes these policies replaceable, not automatically
  efficient.

High-level adapters remain essential. Most users should be able to select a
file and iterate over batches without implementing a scheduler.

## A shared boundary across formats

The same architectural pattern could help hosts integrate Parquet, Lance,
Vortex, and future formats with a common cache, request scheduler, and memory
budget. Each decoder would explain its byte dependencies; the host would reuse
its storage machinery across them.

That is an architectural direction, not a claim that one standardized API
already fits every format. A common interface would need to specify file
identity, range and buffer lifetimes, errors, and cancellation. It would also
need room for optional lookahead and format-specific capabilities such as
pruning and decoding work on accelerators. Flattening everything to an
unannotated list of ranges could hide information the scheduler needs.

For libraries intended to serve several host systems, a practical starting
point is an I/O-free decoder core with useful planning hooks and convenient
adapters. Existing libraries can expose that boundary incrementally while
keeping their optimized high-level readers.

## Conclusion

A file reader API determines how easily an application can combine shared
format logic with its own storage and execution model. Sans I/O makes byte
dependencies explicit and lets the host decide how to satisfy them. Arrow
Rust shows how this can coexist with a familiar asynchronous reader and expose
additional control to applications that need it.

The goal is to make a well-tested decoder reusable across systems with
different scheduling, caching, and memory requirements, while preserving the
format knowledge that makes selective reads effective.

This post is based on *Implementing Analytic File Formats Sans I/O*, by Andrew
Lamb, Xudong Wang, Neil Conway, and Daniël Heres. The two diagrams are reproduced
from that manuscript under [CC BY 4.0]. We thank InfluxData, Massive, and
Coralogix for supporting this work.

[Apache Parquet]: https://parquet.apache.org/
[arrow-rs-parquet]: https://github.com/apache/arrow-rs/tree/57.1.0/parquet
[sans-io]: https://sans-io.readthedocs.io/
[`ParquetPushDecoder`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html
[`try_decode`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.try_decode
[`try_next_reader`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.try_next_reader
[`push_ranges`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.push_ranges
[`buffered_bytes`]: https://docs.rs/parquet/57.1.0/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html#method.buffered_bytes
[`ParquetRecordBatchStream`]: https://docs.rs/parquet/57.1.0/parquet/arrow/async_reader/struct.ParquetRecordBatchStream.html
[pr-8159]: https://github.com/apache/arrow-rs/pull/8159
[`ParquetMetaDataPushDecoder`]: https://docs.rs/parquet/57.1.0/parquet/file/metadata/struct.ParquetMetaDataPushDecoder.html
[io-motivation]: https://github.com/apache/arrow-rs/issues/7983
[async-callback]: https://github.com/apache/arrow-rs/issues/7983#issuecomment-3165065017
[incremental-decoding]: https://github.com/apache/arrow-rs/issues/6946
[wide-column-report]: https://github.com/apache/arrow-rs/issues/6946#issuecomment-5061172503
[prototype driver]: https://github.com/xudong963/push_decoder_policies
[parquet2]: https://docs.rs/crate/parquet2/0.17.2
[polars-parquet]: https://github.com/pola-rs/polars/tree/1b83c09eed30fd2fb4c59f26a1bc2d8c09cad22b/crates/polars-parquet/src/parquet
[cudf-hybrid]: https://github.com/NVIDIA/cudf/blob/4f4de11b87d5f639d51f1ace71dbb3c19eaa15dc/cpp/include/cudf/io/experimental/hybrid_scan.hpp
[CC BY 4.0]: https://creativecommons.org/licenses/by/4.0/
