---
layout: post
title: "Announcing arrow-avro in Arrow Rust"
description: "A new native Rust vectorized reader/writer for Avro to Arrow, with OCF, Single‑Object, and Confluent wire format support."
date: "2025-10-17 00:00:00"
author: jecsand838
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

`arrow-avro` is a Rust crate that reads and writes Avro data directly as Arrow `RecordBatch`es. It supports Avro Object Container Files (OCF), Single‑Object Encoding, and the Confluent Schema Registry wire format, with projection/evolution, tunable batch sizing, and optional `StringViewArray` support for faster strings. Its vectorized design reduces copies and cache misses, making both batch (files) and streaming (Kafka) pipelines simpler and faster.

## Motivation

As a row‑oriented format, Avro is optimized for encoding one record at a time, while Apache Arrow is columnar, optimized for vectorized analytics. When Avro data is decoded record‑by‑record and then materialized into Arrow arrays, systems pay for extra allocations, branches, and cache‑unfriendly memory access (exactly the overhead Arrow's design tries to avoid). One example of a challenge resulting from this can be found in [DataFusion's Avro Datasource](https://github.com/apache/datafusion/tree/main/datafusion/datasource-avro). This row to column impedance mismatch caused by decoding Avro into Arrow shows up as unnecessary work in hot paths.

Today, DataFusion exposes Avro as a first‑class data source so that users can easily read data from Avro files. Under the hood, however, DataFusion has maintained its own Avro to Arrow translation layer, a pragmatic design necessitated by the absence of a dedicated, upstream Arrow‑first Avro reader/writer. Desires to improve this has led to an open discussion about moving to an upstream `arrow-avro` implementation to reduce duplication and improve performance once available. [discussion: "Consider using upstream arrow‑avro reader"](https://github.com/apache/datafusion/issues/14097).

The cost of sticking with a row‑centric path isn't only about CPU cycles; it also complicates features like schema projection and evolution. A reader that thinks in rows must repeatedly reconstruct column buffers that Arrow prefers to build in batches, while a column‑first reader can plan a decode once, reuse builders efficiently, and emit `RecordBatch`es that flow directly into vectorized operators. In an engine like DataFusion, designed to push down projection and operate on Arrow arrays, closing this gap has clear benefits for simplicity and throughput.

Modern pipelines magnify these needs because Avro isn't just a file format, it also shows up on the wire. Kafka ecosystems commonly use [Confluent Schema Registry's wire format](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html) and many services adopt [Avro Single‑Object Encodings](https://avro.apache.org/docs/1.11.1/specification/). In both cases, decoding into Arrow batches instead of per‑row values is what lets downstream compute stay vectorized and efficient.

Within the Rust Arrow ecosystem, the `arrow-avro` effort was created specifically to address this gap by providing a vectorized Avro reader/writer that speaks Arrow natively and supports the major Avro container/framing modes in common use (Object Container Files, Single‑Object Encoding, and Confluent's wire format). Centralizing this logic upstream avoids bespoke, row‑based shims scattered across projects and sets a clearer path for evolution and maintenance. ([Arrow‑rs issue: "Add Avro Support"](https://github.com/apache/arrow-rs/issues/4886).

Development of an Arrow‑first Avro implementation upstream promises a simpler surface area for users and a more maintainable code path for contributors while opening the door to better integration for both batch and streaming clients.

## Introducing `arrow-avro`

[`arrow-avro`](https://github.com/apache/arrow-rs/tree/main/arrow-avro) is a high performance Rust crate that converts between Avro and Arrow with a column‑first, batch‑oriented design. On the read path, it decodes Avro Object Container Files (OCF), Single‑Object Encoding (SOE), and the Confluent Schema Registry wire format directly into Arrow `RecordBatch`es. Meanwhile, the write path provides formats for OCF files and SOEs as well.

The crate exposes two primary read APIs: a high-level `Reader` for OCF inputs and a low-level `Decoder` for streaming frames. For SOE and Confluent frames, a `SchemaStore` is also provided that resolves fingerprints or schema IDs to full Avro writer schemas, enabling schema evolution while keeping the decode path vectorized.

On the write side, `AvroWriter` produces OCF (including container‑level compression), while `AvroStreamWriter` produces framed Avro messages for Single‑Object or Confluent encodings, as configured via the `WriterBuilder::with_fingerprint_strategy(...)` knob.

Configuration is intentionally minimal but practical. For instance, the `ReaderBuilder` exposes knobs covering both batch file ingestion and streaming systems without forcing format‑specific code paths.

## Architecture & Technical Overview

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 20px 15px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/arrow-avro-architecture.svg"
        width="100%"
        alt="High-level `arrow-avro` architecture"
        style="background:#fff">
</div>

At a high level, [`arrow-avro`](https://arrow.apache.org/rust/arrow_avro/index.html) splits cleanly into read and write paths built around Arrow `RecordBatch`es. The read side turns Avro (OCF files or framed byte streams) into Arrow arrays in batches, while the write side takes Arrow batches and produces OCF files or streaming frames. When you build an `AvroStreamWriter`, the framing (SOE or Confluent) is part of the stream output based on the configured fingerprint strategy, no separate framing step required. The public API and module layout are intentionally small so most applications only touch a builder, a reader/decoder, and (optionally) a schema store for schema evolution while streaming.

On the [read](https://arrow.apache.org/rust/arrow_avro/reader/index.html) path, everything starts with [`ReaderBuilder`](https://arrow.apache.org/rust/arrow_avro/reader/struct.ReaderBuilder.html). From a single builder you can create a [`Reader`](https://arrow.apache.org/rust/arrow_avro/reader/struct.Reader.html) for Object Container Files (OCF) or a streaming [`Decoder`](https://arrow.apache.org/rust/arrow_avro/reader/struct.Decoder.html) for Single‑Object/Confluent frames. The `Reader` pulls OCF blocks and yields Arrow `RecordBatch`es while the `Decoder` is push‑based, i.e. you feed bytes as they arrive and then call `flush` to drain completed batches. This design lets the same decode plan serve file and streaming use cases with minimal branching.

For OCF, the `Reader` parses a header and then iterates blocks of data. The header contains a metadata map (including the embedded Avro schema and optional compression), plus a 16‑byte sync marker used to delimit blocks; after that, each block carries a row count and the encoded payload. The OCF header parsing in `arrow-avro` exposes the discovered compression codec (i.e., deflate, snappy, zstd, bzip2, xz) and the file's sync token, matching the Avro 1.11+ specification.

The OCF header and block structures are encoded with variable‑length integers that use zig‑zag encoding for signed values. `arrow-avro` implements this as a small `vlq` (variable‑length quantity) module, which is used by both header parsing and block iteration. Efficient VLQ decode is part of why the reader can stay vectorized and avoid per‑row overhead.

On the [write](https://arrow.apache.org/rust/arrow_avro/writer/index.html) path, [`WriterBuilder`](https://arrow.apache.org/rust/arrow_avro/writer/struct.WriterBuilder.html) produces either an [`AvroWriter`](https://arrow.apache.org/rust/arrow_avro/writer/type.AvroWriter.html) (OCF) or an [`AvroStreamWriter`](https://arrow.apache.org/rust/arrow_avro/writer/type.AvroStreamWriter.html) (stream). Use `with_compression(...)` for OCF block compression, and `with_fingerprint_strategy(...)` to select the streaming frame — Rabin for Single‑Object or a 32‑bit schema ID for Confluent. The stream writer adds the appropriate prefix itself so you don’t need to wrap the Avro body manually.

Schema handling is centralized in the [`schema`](https://arrow.apache.org/rust/arrow_avro/schema/index.html) module. [`AvroSchema`](https://arrow.apache.org/rust/arrow_avro/schema/struct.AvroSchema.html) wraps the Avro JSON; you can compute a fingerprint from its canonical form and store schemas in a [`SchemaStore`](https://arrow.apache.org/rust/arrow_avro/schema/struct.SchemaStore.html). At runtime, the streaming reader uses the store to resolve fingerprints or IDs to full schemas before decoding. `Fingerprint` and `FingerprintAlgorithm` capture how keys are derived (i.e., CRC‑64‑AVRO Rabin, MD5, SHA‑256, or a registry ID), and `FingerprintStrategy` configures how writers prefix each record on raw streams. This is the glue that enables Single‑Object and Confluent without baking in a specific registry client.

At the heart of `arrow-avro` is a type‑mapping `Codec` that the library uses to construct both Encoders and Decoders. The `Codec` captures, for every Avro field, how it maps to Arrow and how to encode/decode it. The read logic builds a `Codec` per *(writer, reader)* schema pair, which the decode plan later uses to vectorize parsing of Avro types straight into the right Arrow builders. The write logic uses the same `Codec` mapping to drive record encoding so Arrow arrays serialize to the correct Avro physical representation (i.e., decimals as bytes vs fixed, enum symbol handling, union branch tagging). Because the `Codec` informs union/nullable decisions in the encoder/decoder plans, the common Avro pattern `["null", T]` seemlessly maps to an Arrow optional field (validity bitmap), while general unions map to Arrow unions with an 8‑bit type‑id buffer (dense unions also carry per‑child offsets). Enabling `strict_mode` applies tighter Avro resolution rules in the `Codec` to help surface ambiguous unions early.

Under the hood, OCF block parsing, header state machines, and the VLQ routines are small, focused components, and the streaming `Decoder` maintains a cache of per‑schema record decoders keyed by fingerprint to avoid re‑planning when a stream interleaves schema versions. This keeps steady‑state decode fast even as schemas evolve.

Finally, by keeping container/framing (OCF vs. raw bytes) separate from encoding/decoding, the crate composes naturally with the rest of Arrow‑rs: you read or write Arrow `RecordBatch`es, pick OCF or raw streams as needed, and wire up fingerprints or IDs only when you're on a streaming path. The result is a compact API surface that covers both batch files and high‑throughput streams without sacrificing columnar, vectorized execution.

## Examples

### Decoding a Confluent-framed Kafka Stream

```rust
use arrow_avro::reader::ReaderBuilder;
use arrow_avro::schema::{
    SchemaStore, AvroSchema, Fingerprint, FingerprintAlgorithm, CONFLUENT_MAGIC
};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Register writer schema under Confluent id=1.
    let mut store = SchemaStore::new_with_type(FingerprintAlgorithm::Id);
    store.set(
        Fingerprint::Id(1),
        AvroSchema::new(r#"{"type":"record","name":"T","fields":[{"name":"x","type":"long"}]}"#.into()),
    )?;

    // Define reader schema to enable projection/schema evolution.
    let reader_schema = AvroSchema::new(r#"{"type":"record","name":"T","fields":[{"name":"x","type":"long"}]}"#.into());

    // Build Decoder using reader and writer schemas
    let mut decoder = ReaderBuilder::new()
        .with_reader_schema(reader_schema)
        .with_writer_schema_store(store)
        .build_decoder()?;

    // Simulate one frame: magic 0x00 + 4‑byte big‑endian schema id + Avro body (x=1 encoded as zig‑zag/VLQ).
    let mut frame = Vec::from(CONFLUENT_MAGIC); frame.extend_from_slice(&1u32.to_be_bytes()); frame.extend_from_slice(&[2]);

    // Consume from decoder
    let _consumed = decoder.decode(&frame)?;
    while let Some(batch) = decoder.flush()? {
        println!("rows={}, cols={}", batch.num_rows(), batch.num_columns());
    }
    Ok(())
}
```

The `SchemaStore` maps the incoming schema id to the correct Avro writer schema so the decoder can perform projection/evolution against your reader schema. Confluent's wire format prefixes each message with a magic byte `0x00` followed by a big‑endian 4‑byte schema id, then the Avro‑encoded record. After decoding Avro messages, the `Decoder::flush()` method yields Arrow `RecordBatch`es suitable for vectorized processing.

A more advanced example can be found [here](https://github.com/apache/arrow-rs/blob/main/arrow-avro/examples/decode_kafka_stream.rs).

### Writing a Snappy Compressed Avro OCF file

```rust
use arrow_array::{Int64Array, RecordBatch};
use arrow_schema::{Schema, Field, DataType};
use arrow_avro::writer::{Writer, WriterBuilder};
use arrow_avro::writer::format::AvroOcfFormat;
use arrow_avro::compression::CompressionCodec;
use std::{sync::Arc, fs::File, io::BufWriter};

fn main() -> Result<(), Box<dyn std::error::Error>> {
  let schema = Schema::new(vec![Field::new("id", DataType::Int64, false)]);
  let batch = RecordBatch::try_new(
    Arc::new(schema.clone()),
    vec![Arc::new(Int64Array::from(vec![1,2,3]))],
  )?;
  let file = File::create("target/example.avro")?;

  // Choose OCF block compression (e.g., None, Deflate, Snappy, Zstd)
  let mut writer: Writer<_, AvroOcfFormat> = WriterBuilder::new(schema)
      .with_compression(Some(CompressionCodec::Snappy))
      .build(BufWriter::new(file))?;
  writer.write(&batch)?;
  writer.finish()?;
  Ok(())
}
```

The example above configures an Avro Object Container File writer. It constructs a `Writer<_, AvroOcfFormat>` using `WriterBuilder::new(schema)` and wraps a `File` in a `BufWriter` for efficient I/O. The call to `.with_compression(Some(CompressionCodec::Snappy))` opts into block‑level compression for OCF. The chosen compression codec is recorded in the file header and applied to subsequent blocks written by this writer. Finally, `writer.write(&batch)?` serializes the batch as an Avro block, and `writer.finish()?` flushes and finalizes the file so that readers can open it. 

## Alternatives & Benchmarks

There's fundamentally two different approaches for bringing Avro into Arrow:
1. Row‑centric approach, typical of general Avro libraries such as `apache-avro`, deserializes one record at a time into native Rust values (i.e., `Value` or Serde types) and then builds Arrow arrays from those values.
2. Vectorized approach, what `arrow-avro` provides, decodes directly into Arrow builders/arrays and emits `RecordBatch`es, avoiding most per‑row overhead.

This section compares those styles qualitatively and with medians from the Criterion benchmark runs that produced the violin plots below.

### Read performance (1M)

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 5px 5px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/read_violin_1m.svg"
        width="100%"
        alt="1M Row Read Violin Plot"
        style="background:#fff">
</div>

### Read performance (10K)

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 5px 5px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/read_violin_10k.svg"
        width="100%"
        alt="10K Row Read Violin Plot"
        style="background:#fff">
</div>

### Write performance (1M)

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 5px 5px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/write_violin_1m.svg"
        width="100%"
        alt="1M Row Write Violin Plot"
        style="background:#fff">
</div>

### Write performance (10K)

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 5px 5px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/write_violin_10k.svg"
        width="100%"
        alt="10K Row Write Violin Plot"
        style="background:#fff">
</div>


Across datasets, the violin plots show lower medians and tighter spreads for `arrow-avro` on both read and write paths. The gap widens when per‑row work dominates (i.e., 10K‑row scenarios). At 1M rows, the distributions remain favorable to `arrow-avro`, reflecting better cache locality and fewer copies once decoding goes straight to Arrow arrays. The general behavior is consistent with `apache-avro`’s record‑by‑record iteration and `arrow-avro`’s batch‑oriented design.

The table below lists the cases we report in the figures:
* 10K vs 1M rows for multiple data shapes.
* **Read cases:**
    * `f8`: *Full schema, 8K batch size.*
      Decode all four columns with batch_size = 8192.
    * `f1`: *Full schema, 1K batch size.*
      Decode all four columns with batch_size = 1024.
    * `p8`: *Projected `{id,name}`, 8K batch size (pushdown).*
      Decode only `id` and `name` with batch_size = 8192`.
      *How projection is applied:*
        * `arrow-avro/p8`: projection via reader schema (`ReaderBuilder::with_reader_schema(...)`) so decoding is column‑pushed down in the Arrow‑first reader.
        * `apache-avro/p8`: projection via Avro reader schema (`AvroReader::with_schema(...)`) so the Avro library decodes only the projected fields.
    * `np`: *Projected `{id,name}`, no pushdown, 8K batch size.*
      Both readers decode the full record (all four columns), materialize all arrays, then project down to `{id,name}` after decode. This models systems that can’t push projection into the file/codec reader.
* **Write cases:**
    * `c` (cold): *Schema conversion each iteration.*
    * `h` (hot): *Avro JSON "hot" path.*
* The resulting Apache‑Avro vs Arrow‑Avro medians with the computed speedup.

### Benchmark Median Time Results (Apple Silicon Mac)

| Case     | apache-avro median | arrow-avro median | speedup |
|----------|-------------------:|------------------:|--------:|
| R/f8/10K |            2.60 ms |           0.24 ms |  10.83x |
| R/p8/10K |            7.91 ms |           0.24 ms |  32.95x |
| R/f1/10K |            2.65 ms |           0.25 ms |  10.60x |
| R/np/10K |            2.62 ms |           0.25 ms |  10.48x |
| R/f8/1M  |          267.21 ms |          27.91 ms |   9.57x |
| R/p8/1M  |          791.79 ms |          26.28 ms |  30.13x |
| R/f1/1M  |          262.93 ms |          28.25 ms |   9.31x |
| R/np/1M  |          268.79 ms |          27.69 ms |   9.71x |
| W/c/10K  |            4.78 ms |           0.27 ms |  17.70x |
| W/h/10K  |            0.82 ms |           0.28 ms |   2.93x |
| W/c/1M   |          485.58 ms |          36.97 ms |  13.13x |
| W/h/1M   |           83.58 ms |          36.75 ms |   2.27x |


* The code for these benchmarks is found [here](https://github.com/jecsand838/arrow-rs/tree/blog-benches/arrow-avro/benches).

## Closing

`arrow-avro` brings a purpose‑built, vectorized bridge connecting Arrow-rs and Avro that covers Object Container Files (OCF), Single‑Object Encoding, and the Confluent Schema Registry wire format. This means you can now keep your ingestion paths columnar for both batch files and streaming systems. If you're building on Arrow‑rs, the reader and writer APIs shown above are available for you to use.

This work is part of the ongoing Arrow‑rs effort to implement first class Avro support in Rust. We'd love your feedback on real‑world use-cases, workloads, and integrations. We also welcome contributions, whether that's issues, benchmarks, or PRs. To follow along or help, open an [issue on GitHub](https://github.com/apache/arrow-rs/issues) and/or track [Add Avro Support](https://github.com/apache/arrow-rs/issues/4886) in `apache/arrow-rs`.

If you have any questions about this blog post, please feel free to contact the author, [Connor Sanders](mailto:jecs838@gmail.com).