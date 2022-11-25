---
layout: post
title: "Fast and Memory Efficient Multi-Column Sorts in Apache Arrow Rust, Part 2"
date: "2022-11-07 00:00:00"
author: "tustvold and alamb"
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

## Introduction

In [Part 1]({% post_url 2022-11-07-multi-column-sorts-in-arrow-rust-part-1 %}) of this post, we described the problem of Multi-Column Sorting and the challenges of implementing it efficiently. This second post explains how the new [row format](https://docs.rs/arrow/27.0.0/arrow/row/index.html) in the [Rust implementation](https://github.com/apache/arrow-rs) of [Apache Arrow](https://arrow.apache.org/) works and is constructed.


## Row Format

The row format is a variable length byte sequence created by concatenating the encoded form of each column. The encoding for each column depends on its datatype (and sort options).

```
   ┌─────┐   ┌─────┐   ┌─────┐
   │     │   │     │   │     │
   ├─────┤ ┌ ┼─────┼ ─ ┼─────┼ ┐              ┏━━━━━━━━━━━━━┓
   │     │   │     │   │     │  ─────────────▶┃             ┃
   ├─────┤ └ ┼─────┼ ─ ┼─────┼ ┘              ┗━━━━━━━━━━━━━┛
   │     │   │     │   │     │
   └─────┘   └─────┘   └─────┘
               ...
   ┌─────┐ ┌ ┬─────┬ ─ ┬─────┬ ┐              ┏━━━━━━━━┓
   │     │   │     │   │     │  ─────────────▶┃        ┃
   └─────┘ └ ┴─────┴ ─ ┴─────┴ ┘              ┗━━━━━━━━┛
   Customer    State    Orders
    UInt64      Utf8     F64

          Input Arrays                          Row Format
           (Columns)
```

The encoding is carefully designed in such a way that escaping is unnecessary: it is never ambiguous as to whether a byte is part of a sentinel (e.g. null) or a value.

### Unsigned Integers

To encode a non-null unsigned integer, the byte `0x01` is written, followed by the integer’s bytes starting with the most significant, i.e. big endian. A null is encoded as a `0x00` byte, followed by the encoded bytes of the integer’s zero value

```
              ┌──┬──┬──┬──┐      ┌──┬──┬──┬──┬──┐
   3          │03│00│00│00│      │01│00│00│00│03│
              └──┴──┴──┴──┘      └──┴──┴──┴──┴──┘
              ┌──┬──┬──┬──┐      ┌──┬──┬──┬──┬──┐
  258         │02│01│00│00│      │01│00│00│01│02│
              └──┴──┴──┴──┘      └──┴──┴──┴──┴──┘
              ┌──┬──┬──┬──┐      ┌──┬──┬──┬──┬──┐
 23423        │7F│5B│00│00│      │01│00│00│5B│7F│
              └──┴──┴──┴──┘      └──┴──┴──┴──┴──┘
              ┌──┬──┬──┬──┐      ┌──┬──┬──┬──┬──┐
 NULL         │??│??│??│??│      │00│00│00│00│00│
              └──┴──┴──┴──┘      └──┴──┴──┴──┴──┘

             32-bit (4 bytes)        Row Format
 Value        Little Endian
```

### Signed Integers

In Rust and most modern computer architectures, signed integers are encoded using [two's complement](https://en.wikipedia.org/wiki/Two%27s_complement), where a number is negated by flipping all the bits, and adding 1. Therefore, flipping the top-most bit and treating the result as an unsigned integer preserves the order. This unsigned integer can then be encoded using the same encoding for unsigned integers described in the previous section. For example

```
       ┌──┬──┬──┬──┐       ┌──┬──┬──┬──┐       ┌──┬──┬──┬──┬──┐
    5  │05│00│00│00│       │05│00│00│80│       │01│80│00│00│05│
       └──┴──┴──┴──┘       └──┴──┴──┴──┘       └──┴──┴──┴──┴──┘
       ┌──┬──┬──┬──┐       ┌──┬──┬──┬──┐       ┌──┬──┬──┬──┬──┐
   -5  │FB│FF│FF│FF│       │FB│FF│FF│7F│       │01│7F│FF│FF│FB│
       └──┴──┴──┴──┘       └──┴──┴──┴──┘       └──┴──┴──┴──┴──┘

 Value  32-bit (4 bytes)    High bit flipped      Row Format
         Little Endian
```

### Floating Point

Floating point values can be ordered according to the [IEEE 754 totalOrder predicate](https://en.wikipedia.org/wiki/IEEE_754#Total-ordering_predicate) (implemented in Rust by [f32::total_cmp](https://doc.rust-lang.org/std/primitive.f32.html#method.total_cmp)). This ordering interprets the bytes of the floating point value as the correspondingly sized, signed, little-endian integer, flipping all the bits except the sign bit in the case of negatives.

Floating point values are therefore encoded to row format by converting them to the appropriate sized signed integer representation, and then using the same encoding for signed integers described in the previous section.

### Byte Arrays (Including Strings)

Unlike primitive types above, byte arrays are variable length. For short strings, such as `state` in our example above, it is possible to pad all values to the length of the longest one with some fixed value such as `0x00` and produce a fixed length row. This is the approach described in the DuckDB blog for encoding `c_birth_country`.

However, often values in string columns differ substantially in length or the maximum length is not known at the start of execution, making it inadvisable and/or impractical to pad the strings to a fixed length. The Rust Arrow row format therefore uses a variable length encoding.

We need an encoding that unambiguously terminates the end of the byte array. This not only permits recovering the original value from the row format, but ensures that bytes of a longer byte array are not compared against bytes from a different column when compared against a row containing a shorter byte array.

A null byte array is encoded as a single `0x00` byte. Similarly, an empty byte array is encoded as a single `0x01` byte.

To encode a non-null, non-empty array, first a single `0x02` byte  is written. Then the array is written in 32-byte blocks, with each complete block followed by a `0xFF` byte as a continuation token. The final block is padded to 32-bytes with `0x00`, and is then followed by the unpadded length of this final block as a single byte in place of a continuation token

Note the following example encodings use a block size of 4 bytes, as opposed to 32 bytes for brevity

```
                      ┌───┬───┬───┬───┬───┬───┐
 "MEEP"               │02 │'M'│'E'│'E'│'P'│04 │
                      └───┴───┴───┴───┴───┴───┘

                      ┌───┐
 ""                   │01 |
                      └───┘

 NULL                 ┌───┐
                      │00 │
                      └───┘

"Defenestration"      ┌───┬───┬───┬───┬───┬───┐
                      │02 │'D'│'e'│'f'│'e'│FF │
                      └───┼───┼───┼───┼───┼───┤
                          │'n'│'e'│'s'│'t'│FF │
                          ├───┼───┼───┼───┼───┤
                          │'r'│'a'│'t'│'r'│FF │
                          ├───┼───┼───┼───┼───┤
                          │'a'│'t'│'i'│'o'│FF │
                          ├───┼───┼───┼───┼───┤
                          │'n'│00 │00 │00 │01 │
                          └───┴───┴───┴───┴───┘
```

This approach is loosely inspired by [COBS encoding](https://en.wikipedia.org/wiki/Consistent_Overhead_Byte_Stuffing), and chosen over more traditional [byte stuffing](https://en.wikipedia.org/wiki/High-Level_Data_Link_Control#Asynchronous_framing) as it is more amenable to vectorization, in particular hardware with AVX-256 can copy a 32-byte block in a single instruction.

### Dictionary Arrays
Dictionary Encoded Data (called [categorical](https://pandas.pydata.org/docs/user_guide/categorical.html) in pandas) is increasingly important because they can store and process low cardinality data very efficiently.

A simple approach to encoding dictionary arrays would be to encode the logical values directly using the encodings for primitive values described previously. However, this would lose the benefits of dictionary encoding to reduce memory and CPU consumption.

To further complicate matters, the [Arrow implementation of Dictionary encoding](https://arrow.apache.org/docs/format/Columnar.html#dictionary-encoded-layout) is quite general, and we can make no assumptions about the contents of the dictionaries. In particular, we cannot assume that the dictionary values are sorted, nor that the same dictionary is used for all arrays within a column

The following example shows how a string column might be encoded in two arrays using two different dictionaries. The dictionary keys `0`, `1`, and `2` in the first batch correspond to different values than the same keys in the second dictionary.

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  ┌───────────┐ ┌─────┐    │
│ │"Fabulous" │ │  0  │
  ├───────────┤ ├─────┤    │
│ │   "Bar"   │ │  2  │
  ├───────────┤ ├─────┤    │       ┌───────────┐
│ │  "Soup"   │ │  2  │            │"Fabulous" │
  └───────────┘ ├─────┤    │       ├───────────┤
│               │  0  │            │  "Soup"   │
                ├─────┤    │       ├───────────┤
│               │  1  │            │  "Soup"   │
                └─────┘    │       ├───────────┤
│                                  │"Fabulous" │
                 Values    │       ├───────────┤
│ Dictionary   (indexes in         │   "Bar"   │
               dictionary) │       ├───────────┤
│                                  │   "ZZ"    │
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘       ├───────────┤
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │   "Bar"   │
                           │       ├───────────┤
│ ┌───────────┐ ┌─────┐            │   "ZZ"    │
  │"Fabulous" │ │  1  │    │       ├───────────┤
│ ├───────────┤ ├─────┤            │"Fabulous" │
  │   "ZZ"    │ │  2  │    │       └───────────┘
│ ├───────────┤ ├─────┤
  │   "Bar"   │ │  1  │    │
│ └───────────┘ ├─────┤
                │  0  │    │      Logical column
│               └─────┘               values
                Values     │
│  Dictionary (indexes in
              dictionary)  │
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

The key observation which allows us to efficiently create a row format for this kind of data is that given a byte array, a new byte array can always be created which comes before or after it in the sort order by adding an additional byte.

Therefore we can incrementally build an order-preserving mapping from dictionary values to variable length byte arrays, without needing to know all possible dictionary values beforehand, instead introducing mappings for new dictionary values as we encounter them.

```
┌──────────┐                 ┌─────┐
│  "Bar"   │ ───────────────▶│ 01  │
└──────────┘                 └─────┘
┌──────────┐                 ┌─────┬─────┐
│"Fabulous"│ ───────────────▶│ 01  │ 02  │
└──────────┘                 └─────┴─────┘
┌──────────┐                 ┌─────┐
│  "Soup"  │ ───────────────▶│ 05  │
└──────────┘                 └─────┘
┌──────────┐                 ┌─────┐
│   "ZZ"   │ ───────────────▶│ 07  │
└──────────┘                 └─────┘

    Example Order Preserving Mapping
```

The details of the data structure used to generate this mapping are beyond the scope of this blog post, but may be the topic of a future post. You can find [the code here](https://github.com/apache/arrow-rs/blob/07024f6a16b870fda81cba5779b8817b20386ebf/arrow/src/row/interner.rs).

The data structure also ensures that no values contain `0x00` and therefore we can encode the arrays directly using `0x00` as an end-delimiter.

A null value is encoded as a single `0x00` byte, and a non-null value encoded as a single `0x01` byte, followed by the `0x00` terminated byte array determined by the order preserving mapping

```
                          ┌─────┬─────┬─────┬─────┐
   "Fabulous"             │ 01  │ 03  │ 05  │ 00  │
                          └─────┴─────┴─────┴─────┘

                          ┌─────┬─────┬─────┐
   "ZZ"                   │ 01  │ 07  │ 00  │
                          └─────┴─────┴─────┘

                          ┌─────┐
    NULL                  │ 00  │
                          └─────┘

     Input                  Row Format
```

### Sort Options

One detail we have so far ignored over is how to support ascending and descending sorts (e.g. `ASC` or `DESC` in SQL). The Arrow Rust row format supports these options by simply inverting the bytes of the encoded representation, except the initial byte used for nullability encoding, on a per column basis.

Similarly, supporting SQL compatible sorting also requires a format that can specify the order of `NULL`s (before or after all non `NULL` values). The row format supports this option by optionally encoding nulls as `0xFF` instead of `0x00` on a per column basis.

## Conclusion

Hopefully these two articles have given you a flavor of what is possible with a comparable row format and how it works. Feel free to check out the [docs](https://docs.rs/arrow/27.0.0/arrow/row/index.html) for instructions on getting started, and report any issues on our [bugtracker](https://github.com/apache/arrow-rs/issues).

Using this format for lexicographic sorting is more than [3x](https://github.com/apache/arrow-rs/pull/2929) faster than the comparator based approach, with the benefits especially pronounced for strings, dictionaries and sorts with large numbers of columns.

We have also already used it to more than [double](https://github.com/apache/arrow-datafusion/pull/3386) the performance of sort preserving merge in the [DataFusion project](https://arrow.apache.org/datafusion/), and expect similar or greater performance uplift as we apply it to sort, grouping, join, and window function operators as well.

As always, the [Arrow community](https://github.com/apache/arrow-rs#arrow-rust-community) very much looks forward to seeing what you build with it!
