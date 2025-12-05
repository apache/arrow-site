---
layout: post
title: "Push Decoder: Fine-Grained Control over IO and CPU when Reading Parquet Files"
date: "2025-12-01 00:00:00"
author: alamb
categories: [arrow-rs]   
---
<!--
{% comment %}
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with this
work for additional information regarding copyright ownership.  The ASF
licenses this file to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance with the
License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
{% endcomment %}
-->

*Editor’s Note: While [Apache Arrow] and [Apache Parquet] are separate projects,
the Arrow [arrow-rs] repository hosts the development of the [parquet] Rust
crate, a widely used and high-performance Parquet implementation.*

## Summary

The new `ParquetPushDecoder` decouples IO from CPU for Parquet reads, giving
applications fine-grained control over *what* to fetch and *when* to decode. It
enables the same push-based workflow Arrow already provides for CSV and JSON,
removes duplicated sync/async reader code paths, and opens the door to smarter
prefetching, pluggable IO sources (beyond `object_store`), and lower latency on
remote storage.

## Background

Arrow’s Rust ecosystem already ships push decoders for [CSV] and [JSON], letting
callers decide how bytes are staged and when they are fed into the parser. By
contrast, Parquet only exposed "pull" readers. We also maintained separate sync
and `async` parquet readers, duplicating logic for filters, projections, and
tests. Integrations like [`object_store`] received first-class support while
other IO backends (for example, OpenDAL) required bespoke glue code.

Issue [#7983] describes why coupling IO and decode made it difficult to prefetch
row groups, overlap requests, or share code between sync/async paths. Issue
[#8035] asked for this post to explain the new push decoder and how it addresses
those gaps.

## Motivation: Why a Push Decoder?

*Fine-grained prefetching:* Existing readers can prefetch at the row-group
granularity, but cannot ask for specific page ranges ahead of time. With a push
decoder, callers see the exact byte ranges the decoder needs next and can
schedule fetches that match their storage and caching strategy.

*sans-IO for columnar formats:* The design follows the [sans-IO] pattern, moving
all IO decisions to the application while keeping Parquet decoding pure and
deterministic.

*Classic pull flow (before):*

```
Caller --> next_batch() --> Parquet reader
                          | (decides when/what to read)
                          v
                       IO request
                          v
                       Decode + return batch
```

*Push flow (now):*

```
Caller              Decoder
  |   try_decode()    |
  |------------------>|
  |   NeedsData(r)    |
  |<------------------|
  | fetch ranges r    |
  | push_ranges(r, b) |
  |------------------>|
  |   Data(batch)     |
  |<------------------|
```

By separating IO, users can buffer whole files, stream small chunks, or overlap
multiple requests depending on latency and memory budgets.

## Design: How the Push Decoder Works

`ParquetPushDecoder` is a low-level API that only understands byte ranges and
Arrow schemas. It never performs IO itself. The workflow is:

1. Build a decoder with projection, filters, and optional cached metadata.
2. Call `try_decode()` (or `try_next_reader()`) to learn what byte ranges are
   needed next.
3. Fetch those ranges from *any* source (local files, `object_store`, OpenDAL,
   custom caches, or in-memory buffers).
4. Push the fetched bytes back via `push_range`/`push_ranges` and decode again.

Internally, the same decoding kernels power both sync and async adapters, so the
logic for row filters, column projections, and statistics is shared instead of
duplicated. That symmetry makes it easier to test and extend both paths
together.

## Examples

The API mirrors the CSV/JSON push decoders. From the docs:

```rust
use parquet::DecodeResult;

let mut decoder = get_decoder();
loop {
   match decoder.try_decode().unwrap() {
      DecodeResult::NeedsData(ranges) => {
        // Fetch the ranges, then feed them back
        push_data(&mut decoder, ranges);
      }
      DecodeResult::Data(batch) => {
        println!("Got batch with {} rows", batch.num_rows());
      }
      DecodeResult::Finished => break,
   }
}
```

To overlap IO and CPU, `try_next_reader()` returns a `ParquetRecordBatchReader`
once enough bytes are buffered, while also telling you what to fetch next:

```rust
use parquet::DecodeResult;

let mut decoder = get_decoder();
loop {
   match decoder.try_next_reader().unwrap() {
      DecodeResult::NeedsData(ranges) => push_data(&mut decoder, ranges),
      DecodeResult::Data(reader) => {
         std::thread::spawn(move || {
           for batch in reader {
             let batch = batch.unwrap();
             println!("Got batch with {} rows", batch.num_rows());
           }
         });
      }
      DecodeResult::Finished => break,
   }
}
```

See the [`ParquetPushDecoder` docs] and the [source examples] for additional
patterns and builder options.

## Performance

CPU cost is unchanged from the existing `ArrowReader` because the same decode
pipelines are reused. IO latency, however, can now be hidden or reduced:

* Remote object storage: overlap page fetches with decoding instead of serial
  pulls initiated inside the reader.
* Caches: feed already-cached ranges without constructing a custom
  `AsyncFileReader`.
* Batching: tune how much data to stage (page-level vs row-group-level) to match
  your workload’s memory and concurrency profile.

Early users report smoother S3 reads and simpler cache integration, and we plan
to publish benchmark numbers once the API hardens.

## Future Work

* Higher-level helpers for prefetch policies (row-group, page, metadata-only).
* Richer instrumentation (bytes buffered, time spent waiting for ranges).
* Reference adapters for OpenDAL and other object stores.
* DataFusion integration so executors can plug in their own IO schedulers.
* More end-to-end benchmarks on local SSDs, S3, and Azure.

If you want to experiment today, try the push decoder directly or follow the
tracking items in [#7983] and [#8035].

[Apache Arrow]: https://arrow.apache.org/
[Apache Parquet]: https://parquet.apache.org/
[arrow-rs]: https://github.com/apache/arrow-rs
[parquet]: https://crates.io/crates/parquet
[CSV]: https://docs.rs/arrow-csv/latest/arrow_csv/reader/struct.Decoder.html
[JSON]: https://docs.rs/arrow-json/latest/arrow_json/reader/struct.Decoder.html
[`object_store`]: https://docs.rs/object_store/latest/object_store/
[`ParquetPushDecoder` docs]: https://docs.rs/parquet/latest/parquet/arrow/push_decoder/struct.ParquetPushDecoder.html
[source examples]: https://github.com/apache/arrow-rs/blob/main/parquet/src/arrow/push_decoder/mod.rs
[sans-IO]: https://sans-io.readthedocs.io/
[#7983]: https://github.com/apache/arrow-rs/issues/7983
[#8035]: https://github.com/apache/arrow-rs/issues/8035
