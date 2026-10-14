---
layout: post
title: "Implementing Analytic File Formats Sans I/O"
description: "How the Arrow Rust Parquet push decoder exposes byte requirements so applications can control storage I/O"
date: "2026-10-12 00:00:00"
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

A **Sans I/O** decoder interprets bytes but never fetches them. When it cannot
continue, it returns the byte ranges it needs; the application supplies buffers
and decides when to resume decoding. This exposes a boundary where an
application can use its own cache, storage scheduler, and memory policy.

Sans I/O is an established pattern in [network protocol libraries][sans-io].
This post introduces the [Arrow Rust Parquet reader's][arrow-rs-parquet] push
API, shows how an application drives it, and explains what control that API
provides. We plan to cover prefetching and its measured performance in a
follow-up post.

## The Sans I/O contract

The decoder performs no I/O, including through callbacks. Each time the
application asks it to advance, it does one of three things:

1. Produces decoded data.
2. Reports that decoding is finished.
3. Returns the byte ranges needed to make progress.

[`ParquetPushDecoder`] exposes this interaction through [`try_decode`] and
[`push_ranges`]. In simplified Rust, with application-provided `fetch` and
`consume` helpers:

```rust
loop {
    match decoder.try_decode()? {
        DecodeResult::NeedsData(ranges) => {
            // Return one buffer for each logical range, in order.
            let buffers = io_policy.fetch(&ranges)?;
            decoder.push_ranges(ranges, buffers)?;
        }
        DecodeResult::Data(batch) => consume(batch)?,
        DecodeResult::Finished => break,
    }
}
```

These APIs are available in `arrow-rs` `57.1.0`, the version linked here.
The loop starts after file metadata is available; footer and metadata decoding
use the same request-and-supply pattern through [`ParquetMetaDataPushDecoder`].
Errors propagate through the API as usual.

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/architecture.png"
       alt="An integrated reader invokes a storage callback from its decoding loop; a Sans I/O decoder returns byte requirements for the application to schedule and supply"
       class="img-fluid">
  <figcaption>Figure 1: The decoder determines its byte dependencies; the application schedules the I/O that satisfies them.</figcaption>
</figure>

"Push" describes the application supplying bytes to the decoder. It does not
prescribe the execution model of the rest of the query engine.

## Why Parquet needs a conversation

Streaming CSV and JSON parsers can accept chunks and ask for more input, usually
at the next position in the stream. [Apache Parquet] reads are non-sequential
and depend on earlier data.

<figure class="centered">
  <img src="{{ site.baseurl }}/img/sans-io-analytic-formats/parquet-state-machine.png"
       alt="Parquet decoding alternates between I/O and CPU stages for the file footer, metadata, optional pruning structures, and data pages"
       width="520" class="img-fluid">
  <figcaption>Figure 2: A simplified Parquet decoding state machine. Pink states perform I/O, yellow states perform CPU work, and dashed states are optional.</figcaption>
</figure>

The trailing footer locates metadata, which locates row groups and column
chunks. Optional Bloom filters and page indexes can help eliminate row groups
or pages. Evaluating a predicate on one column can further reduce the pages
needed from another. The decoder retains this format-dependent state machine:
the application supplies the projection, row selections, and predicates, then
satisfies the byte requests that result.

`NeedsData` describes what is missing **now**, not every range that might be
needed later. In particular, a predicate that has not yet run may eliminate
future reads. Selective prefetching therefore needs additional planning
information; the basic push loop does not provide a complete future read plan.

## From logical ranges to physical reads

The ranges in `NeedsData` specify the decoder's requirements. They need not map
one-to-one to storage requests. Consider an illustrative request for
`100..200` and `220..300`, using exclusive end offsets:

| Policy | Physical reads | Bytes fetched | Buffers supplied to the decoder |
| --- | --- | --- | --- |
| Exact ranges | `100..200`, `220..300` | 180 | The two fetched buffers |
| Coalesced range | `100..300` | 200 | Slices `0..100` and `120..200` of the fetched buffer |

For this particular request, a coalescing policy could use the following code.
`read_range` is an application helper returning a reference-counted `Bytes`
buffer:

```rust
let buffer = read_range(100..300)?;
decoder.push_ranges(
    vec![100..200, 220..300],
    vec![buffer.slice(0..100), buffer.slice(120..200)],
)?;
```

The decoder receives the same logical bytes in both cases. Coalescing replaces
two storage reads with one by fetching the 20-byte gap. The slices share the
allocation without copying their contents. Whether saving a request outweighs
reading extra bytes depends on the storage system; this example demonstrates
the mechanism, not a measured speedup. Decoding and decompression can still
allocate output buffers.

A cache fits at the same boundary. If `100..300` is already resident, the host
can supply those slices without another read. If it fetches beyond the current
request, it can retain the extra bytes in its own cache and use them to satisfy
later requests. That also makes the host responsible for retaining and evicting
those bytes. Our [example driver][prototype driver] implements several such
policies around the same decoder.

## Scheduling decoding and I/O

A storage callback can already implement caching, retries, and request
coalescing. An async callback can submit requests to a shared scheduler. These
capabilities do not inherently require Sans I/O, as the [original design
discussion][async-callback] also considered.

The push API makes advancing the decoder a separate operation from satisfying
its requests. A host can keep missing ranges as ordinary data and resume each
decoder when its scheduler is ready. Additional control requires additional API
support. For example, [`try_next_reader`] returns a
`ParquetRecordBatchReader` once the input needed for that reader is available.
The host can then:

1. Send that reader to a CPU worker to produce batches from buffered input.
2. Advance the push decoder to discover the next byte requirements.
3. Fetch those bytes while the worker decodes the preceding data.

The independent reader is what makes this handoff possible. The host must still
bound active readers and pending reads, and preserve output order where
required. Merely using an async fetch callback does not define that handoff.
Likewise, reducing the output batch size does not by itself reduce the input
that must be buffered before a reader is ready.

This separation builds on existing designs: [`parquet2`][parquet2] separates
page reading from decompression and deserialization, while cuDF's
[experimental hybrid scan reader][cudf-hybrid] exposes staged byte-range and
buffer operations. The push decoder packages Parquet's dependent read steps
into a state machine that the host can drive through one request-and-supply
interface.

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

## What comes next

The API gives applications explicit byte requirements and control over when to
resume decoding. Effective prefetching also needs information about future
reads and a policy for spending bandwidth and memory.

Recent work addresses those pieces separately: [`scan_plan()`][scan-plan] has
merged into `arrow-rs` main to expose candidate future ranges, while
[batch-granular decoding][batch-decoding] and a [DataFusion read-ahead
prototype][datafusion-read-ahead] are under review. These additions are separate
from the `57.1.0` examples above. We plan to use a follow-up post to explain the
prefetching policy and evaluate it on object storage alongside a local-storage
baseline.

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
[`ParquetMetaDataPushDecoder`]: https://docs.rs/parquet/57.1.0/parquet/file/metadata/struct.ParquetMetaDataPushDecoder.html
[async-callback]: https://github.com/apache/arrow-rs/issues/7983#issuecomment-3165065017
[prototype driver]: https://github.com/xudong963/push_decoder_policies
[parquet2]: https://docs.rs/crate/parquet2/0.17.2
[cudf-hybrid]: https://github.com/NVIDIA/cudf/blob/4f4de11b87d5f639d51f1ace71dbb3c19eaa15dc/cpp/include/cudf/io/experimental/hybrid_scan.hpp
[scan-plan]: https://github.com/apache/arrow-rs/pull/10555
[batch-decoding]: https://github.com/apache/arrow-rs/pull/11238
[datafusion-read-ahead]: https://github.com/apache/datafusion/pull/24086
[CC BY 4.0]: https://creativecommons.org/licenses/by/4.0/
