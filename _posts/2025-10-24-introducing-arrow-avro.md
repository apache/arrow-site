---
layout: post
title: "Announcing arrow-avro in Arrow Rust"
description: "A new native Rust vectorized reader/writer for Avro to Arrow, with OCF, Single‑Object, and Confluent wire format support."
date: "2025-10-24 00:00:00"
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

`arrow-avro` is a Rust crate that reads and writes [Apache Avro](https://avro.apache.org/) data directly as Arrow `RecordBatch`es. It supports [Avro Object Container Files](https://avro.apache.org/docs/1.11.1/specification/#object-container-files) (OCF), [Single‑Object Encoding](https://avro.apache.org/docs/1.11.1/specification/#single-object-encoding) (SOE), the [Confluent Schema Registry wire format](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#wire-format), and the [Apicurio Registry wire format](https://www.apicur.io/registry/docs/apicurio-registry/1.3.3.Final/getting-started/assembly-using-kafka-client-serdes.html#registry-serdes-types-avro-registry), with projection/evolution, tunable batch sizing, and optional `StringViewArray` support for faster strings. Its vectorized design reduces copies and cache misses, making both batch and streaming pipelines simpler and faster.

## Motivation

Apache Avro’s row‑oriented design is effective for encoding one record at a time, while Apache Arrow’s columnar layout is optimized for vectorized analytics. A major challenge lies in converting between these formats without reintroducing row‑wise overhead. Decoding Avro a row at a time and then building Arrow arrays incurs extra allocations and cache‑unfriendly access (the very costs Arrow is designed to avoid). In the real world, this overhead commonly shows up in analytical hot paths. For instance, [DataFusion’s Avro datasource](https://github.com/apache/datafusion/tree/main/datafusion/datasource-avro) currently ships with its own row‑centric Avro‑to‑Arrow layer. This implementation has led to an open issue for [using an upstream arrow-avro reader](https://github.com/apache/datafusion/issues/14097) to simplify the code and speed up scans. Additionally, DataFusion has another open issue for [supporting Avro format writes](https://github.com/apache/datafusion/issues/7679#issuecomment-3412302891) that is predicated on the development of an upstream `arrow-avro` writer.

### Why not use the existing `apache-avro` crate?

Rust already has a mature, general‑purpose Avro crate, [apache-avro](https://crates.io/crates/apache-avro). It reads and writes Avro records as Avro value types and provides Object Container File readers and writers. What it does not do is decode directly into Arrow arrays, so any Arrow integration must materialize rows and then build columns.

What’s needed is a complementary approach that decodes column‑by‑column straight into Arrow builders and emits `RecordBatch`es. This would enable projection pushdown while keeping execution vectorized end to end. For projects such as [Apache DataFusion](https://datafusion.apache.org/), access to a mature, upstream Arrow‑native reader and writer would help simplify the code path and reduce duplication.

Modern pipelines heighten this need because [Avro is also used on the wire](https://www.confluent.io/blog/avro-kafka-data/), not just in files. Kafka ecosystems commonly use Confluent’s Schema Registry framing, and many services adopt the Avro Single‑Object Encoding format. An approach that enables decoding straight into Arrow batches (rather than through per‑row values) would let downstream compute remain vectorized at streaming rates.

### Why this matters

Apache Avro is a first‑class format across stream processors and cloud services:
- Confluent Schema Registry supports [Avro across multiple languages and tooling](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/serdes-avro.html).
- Apache Flink exposes an [`avro-confluent` format for Kafka](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/connectors/table/formats/avro-confluent/).
- AWS Lambda [(June 2025) added native handling for Avro‑formatted Kafka events](https://aws.amazon.com/about-aws/whats-new/2025/06/aws-lambda-native-support-avro-protobuf-kafka-events/) with Glue and Confluent Schema Registry integrations.
- Azure Event Hubs provides a [Schema Registry with Avro support](https://learn.microsoft.com/en-us/azure/event-hubs/schema-registry-overview) for Kafka‑compatible clients.

In short: Arrow users encounter Avro both on disk (OCF) and on the wire (SOE). An Arrow‑first, vectorized reader/writer for OCF, SOE, and Confluent framing removes a pervasive bottleneck and keeps pipelines columnar end‑to‑end.

## Introducing `arrow-avro`

[`arrow-avro`](https://github.com/apache/arrow-rs/tree/main/arrow-avro) is a high-performance Rust crate that converts between Avro and Arrow with a column‑first, batch‑oriented design. On the read side, it decodes Avro Object Container Files (OCF), Single‑Object Encoding (SOE), and the Confluent Schema Registry wire format directly into Arrow `RecordBatch`es. Meanwhile, the write path provides formats for encoding to OCF and SOE as well.

The crate exposes two primary read APIs: a high-level `Reader` for OCF inputs and a low-level `Decoder` for streaming SOE frames. For SOE and Confluent/Apicurio frames, a `SchemaStore` is provided that resolves fingerprints or schema IDs to full Avro writer schemas, enabling schema evolution while keeping the decode path vectorized.

On the write side, `AvroWriter` produces OCF (including container‑level compression), while `AvroStreamWriter` produces framed Avro messages for Single‑Object or Confluent/Apicurio encodings, as configured via the `WriterBuilder::with_fingerprint_strategy(...)` knob.

Configuration is intentionally minimal but practical. For instance, the `ReaderBuilder` exposes knobs covering both batch file ingestion and streaming systems without forcing format‑specific code paths.

### How this mirrors Parquet in Arrow‑rs

If you have used Parquet with Arrow‑rs, you already know the pattern. The `parquet` crate exposes an [parquet::arrow module](https://docs.rs/parquet/latest/parquet/arrow/index.html) that reads and writes Arrow `RecordBatch`es directly. Most users reach for `ParquetRecordBatchReaderBuilder` when reading and `ArrowWriter` when writing. You choose columns up front, set a batch size, and the reader gives you Arrow batches that flow straight into vectorized operators. This is the widely adopted "format crate + Arrow‑native bridge" approach in Rust.

`arrow‑avro` brings that same bridge to Avro. You get a single `ReaderBuilder` that can produce a `Reader` for OCF, or a streaming `Decoder` for on‑the‑wire frames. Both return Arrow `RecordBatch`es, which means engines can keep projection and filtering close to the reader and avoid building rows only to reassemble them back into columns later. For evolving streams, a small `SchemaStore` resolves fingerprints or ids before decoding, so the batches that come out are already shaped for vectorized execution.

The reason this pattern matters is straightforward. Arrow’s columnar format is designed for vectorized work and good cache locality. When a format reader produces Arrow batches directly, copies and branchy per‑row work are minimized, keeping downstream operators fast. That is the same story that made `parquet::arrow` popular in Rust, and it is what `arrow‑avro` now enables for Avro.


## Architecture & Technical Overview

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; padding: 20px 15px;">
<img src="{{ site.baseurl }}/img/introducing-arrow-avro/arrow-avro-architecture.svg"
        width="100%"
        alt="High-level `arrow-avro` architecture"
        style="background:#fff">
</div>

At a high level, [arrow-avro](https://arrow.apache.org/rust/arrow_avro/index.html) splits cleanly into read and write paths built around Arrow `RecordBatch`es. The read side turns Avro (OCF files or framed byte streams) into batched Arrow arrays, while the write side takes Arrow batches and produces OCF files or streaming frames. When using an `AvroStreamWriter`, the framing (SOE or Confluent) is part of the stream output based on the configured fingerprint strategy; thus no separate framing work is required. The public API and module layout are intentionally small, so most applications only touch a builder, a reader/decoder, and (optionally) a schema store for schema evolution.

On the [read](https://arrow.apache.org/rust/arrow_avro/reader/index.html) path, everything starts with the [ReaderBuilder](https://arrow.apache.org/rust/arrow_avro/reader/struct.ReaderBuilder.html). A single builder can create a [Reader](https://arrow.apache.org/rust/arrow_avro/reader/struct.Reader.html) for Object Container Files (OCF) or a streaming [Decoder](https://arrow.apache.org/rust/arrow_avro/reader/struct.Decoder.html) for SOE/Confluent/Apicurio frames. The `Reader` pulls OCF blocks and yields Arrow `RecordBatch`es while the `Decoder` is push‑based, i.e., bytes are fed in as they arrive and then drained as completed batches once `flush` is called. Both use the same schema‑driven decoding logic (per‑column decoders with projection/union/nullability handling), so file and streaming inputs produce batches using fewer per‑row allocations and minimal branching/redundancy. Additionally, the streaming `Decoder` maintains a cache of per‑schema record decoders keyed by fingerprint to avoid re‑planning when a stream interleaves schema versions. This keeps steady‑state decode fast even as schemas evolve.

When reading an OCF, the `Reader` parses a header and then iterates on blocks of encoded data. The header contains a metadata map with the embedded Avro schema and optional compression (i.e., `deflate`, `snappy`, `zstd`, `bzip2`, `xz`), plus a 16‑byte sync marker used to delimit blocks. Each subsequent OCF block then carries a row count and the encoded payload. The parsed OCF header and block structures are also encoded with variable‑length integers that use zig‑zag encoding for signed values. `arrow-avro` implements a small `vlq` (variable‑length quantity) module, which is used during both header parsing and block iteration. Efficient `vlq` decode is part of why the `Reader` and `Decoder` can stay vectorized and avoid unnecessary per‑row overhead.

On the [write](https://arrow.apache.org/rust/arrow_avro/writer/index.html) path, the [WriterBuilder](https://arrow.apache.org/rust/arrow_avro/writer/struct.WriterBuilder.html) produces either an [AvroWriter](https://arrow.apache.org/rust/arrow_avro/writer/type.AvroWriter.html) (OCF) or an [AvroStreamWriter](https://arrow.apache.org/rust/arrow_avro/writer/type.AvroStreamWriter.html) (SOE/Message). The `with_compression(...)` knob is used for OCF block compression while `with_fingerprint_strategy(...)` selects the streaming frame, i.e., Rabin for SOE, a 32‑bit schema ID for Confluent, or a 64-bit schema ID for Apicurio. The `AvroStreamWriter` also adds the appropriate prefix automatically while encoding, thus eliminating the need for potentially expensive post-processes to wrap the outputted Avro SOEs.

Schema handling is centralized in the [schema](https://arrow.apache.org/rust/arrow_avro/schema/index.html) module. [AvroSchema](https://arrow.apache.org/rust/arrow_avro/schema/struct.AvroSchema.html) wraps a valid Avro Schema JSON string, supports computing a `Fingerprint`, and can be loaded into a [SchemaStore](https://arrow.apache.org/rust/arrow_avro/schema/struct.SchemaStore.html) as a writer schema. At runtime, the `Reader`/`Decoder` can use a `SchemaStore` to resolve fingerprints before decoding, enabling [schema resolution](https://avro.apache.org/docs/1.11.1/specification/#schema-resolution). The `FingerprintAlgorithm` captures how fingerprints are derived (i.e., CRC‑64‑AVRO Rabin, MD5, SHA‑256, or a registry ID), and `FingerprintStrategy` configures how the `Writer` prefixes each record while encoding SOE streams. This schema module is the glue that enables SOE and Confluent/Apicurio support without coupling to a specific registry client.

At the heart of `arrow-avro` is a type‑mapping `Codec` that the library uses to construct both encoders and decoders. The `Codec` captures, for every Avro field, how it maps to Arrow and how it should be encoded or decoded. The `Reader` logic builds a `Codec` per *(writer, reader)* schema pair, which the decoder later uses to vectorize parsing of Avro values directly into the correct Arrow builders. The `Writer` logic uses the same `Codec` mappings to drive pre-computed record encoding plans which enable fast serialization of Arrow arrays to the correct Avro physical representation (i.e., decimals as bytes vs fixed, enum symbol handling, union branch tagging, etc.). Because the `Codec` informs union and nullable decisions in both the encoder and decoder, the common Avro pattern `["null", T]` seamlessly maps to and from an Arrow optional field, while Avro unions map to Arrow unions using an 8‑bit type‑id with minimal overhead. Meanwhile, enabling `strict_mode` applies tighter Avro resolution rules in the `Codec` to help surface ambiguous unions early.

Finally, by keeping container and stream framing (OCF vs. SOE) separate from encoding and decoding, the crate composes naturally with the rest of Arrow‑rs: you read or write Arrow `RecordBatch`es, pick OCF or SOE streams as needed, and wire up fingerprints only when you're on a streaming path. This results in a compact API surface that covers both batch files and high‑throughput streams without sacrificing columnar, vectorized execution.

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

The `SchemaStore` maps the incoming schema id to the correct Avro writer schema so the decoder can perform projection/evolution against the reader schema. Confluent's wire format prefixes each message with a magic byte `0x00` followed by a big‑endian 4‑byte schema id. After decoding Avro messages, the `Decoder::flush()` method yields Arrow `RecordBatch`es suitable for vectorized processing.

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

The example above configures an Avro OCF `Writer`. It constructs a `Writer<_, AvroOcfFormat>` using `WriterBuilder::new(schema)` and wraps a `File` in a `BufWriter` for efficient I/O. The call to `.with_compression(Some(CompressionCodec::Snappy))` enables block‑level snappy compression. Finally, `writer.write(&batch)?` serializes the batch as an Avro encoded block, and `writer.finish()?` flushes and finalizes the outputted file.

## Alternatives & Benchmarks

There are fundamentally two different approaches for bringing Avro into Arrow:
1. Row‑centric approach, typical of general Avro libraries such as `apache-avro`, deserializes one record at a time into native Rust values (i.e., `Value` or Serde types) and then builds Arrow arrays from those values.
2. Vectorized approach, what `arrow-avro` provides, decodes directly into Arrow builders/arrays and emits `RecordBatch`es, avoiding most per‑row overhead.

This section compares the performance of both approaches using these [Criterion benchmarks](https://github.com/jecsand838/arrow-rs/tree/blog-benches/arrow-avro/benches).

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


Across benchmarks, the violin plots show lower medians and tighter spreads for `arrow-avro` on both read and write paths. The gap widens when per‑row work dominates (i.e., 10K‑row scenarios). At 1M rows, the distributions remain favorable to `arrow-avro`, reflecting better cache locality and fewer copies once decoding goes straight to Arrow arrays. The general behavior is consistent with `apache-avro`'s record‑by‑record iteration and `arrow-avro`'s batch‑oriented design.

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
      Both readers decode the full record (all four columns), materialize all arrays, then project down to `{id,name}` after decode. This models systems that can't push projection into the file/codec reader.
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

## Closing

`arrow-avro` brings a purpose‑built, vectorized bridge connecting Arrow-rs and Avro that covers Object Container Files (OCF), Single‑Object Encodings (SOE), and the Confluent/Apicurio Schema Registry wire formats. This means you can now keep your ingestion paths columnar for both batch files and streaming systems. The reader and writer APIs shown above are now available for you to use with the v57.0.0 release of `arrow-rs`.

This work is part of the ongoing Arrow‑rs effort to implement first-class Avro support in Rust. We'd love your feedback on real‑world use-cases, workloads, and integrations. We also welcome contributions, whether that's issues, benchmarks, or PRs. To follow along or help, open an [issue on GitHub](https://github.com/apache/arrow-rs/issues) and/or track [Add Avro Support](https://github.com/apache/arrow-rs/issues/4886) in `apache/arrow-rs`.

### Acknowledgments

Special thanks to:
* [tustvold](https://github.com/tustvold) for laying an incredible zero-copy foundation.
* [nathaniel-d-ef](https://github.com/nathaniel-d-ef) and [ElastiFlow](https://github.com/elastiflow) for their numerous and invaluable project-wide contributions.
* [veronica-m-ef](https://github.com/veronica-m-ef) for making Impala support related contributions to the `Reader`.
* [Supermetal](https://github.com/Supermetal-Inc) for contributions related to Apicurio registry and Run-end Encoding type support.
* [kumarlokesh](https://github.com/kumarlokesh) for contributing `Utf8View` support.
* [alamb](https://github.com/alamb), [scovich](https://github.com/scovich), [mbrobbel](https://github.com/mbrobbel), and [klion26](https://github.com/klion26) for their thoughtful reviews, detailed feedback, and support throughout the development of `arrow-avro`.

If you have any questions about this blog post, please feel free to contact the author, [Connor Sanders](mailto:jecs838@gmail.com).