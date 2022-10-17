---
layout: post
title: "Arrow and Parquet Part 3: Arbitrary Nesting with Lists of Structs and Structs of Lists"
date: "2022-10-17 00:00:00"
author: "tustvold and alamb"
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

## Introduction

This is the third of a three part series exploring how projects such as [Rust Apache Arrow](https://github.com/apache/arrow-rs) support conversion between [Apache Arrow](https://arrow.apache.org/) for in memory processing and [Apache Parquet](https://parquet.apache.org/) for efficient storage. [Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.


[Arrow and Parquet Part 1: Primitive Types and Nullability](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/) covered the basics of primitive types.  [Arrow and Parquet Part 2: Nested and Hierarchical Data using Structs and Lists](https://arrow.apache.org/blog/2022/10/08/arrow-parquet-encoding-part-2/) covered the `Struct` and `List` types. This post builds on this foundation to show how both formats combine these to support arbitrary nesting.

Some libraries, such as Rust [parquet](https://crates.io/crates/parquet) implementation, offer complete support for such combinations, and users of those libraries do not need to worry about these details except to satisfy their own curiosity. Other libraries may not handle some corner cases and this post gives some flavor of why it is so complicated to do so.


# Structs with Lists
Consider the following three json documents

```python
{                     # <-- First record
  "a": [1],           # <-- top-level field a containing list of integers
  "b": [              # <-- top-level field b containing list of structures
    {                 # <-- list element of b containing two field b1 and b2
      "b1": 1         # <-- b1 is always provided (non nullable)
    },
    {
      "b1": 1,
      "b2": [         # <-- b2 contains list of integers
        3, 4          # <-- list elements of b.b2 always provided (non nullable)
      ]
    }
  ]
}
```

```python
{
  "b": [              # <-- b is always provided (non nullable)
    {
      "b1": 2
    },
  ]
}
```

```python
{
  "a": [null, null],  # <-- list elements of a are nullable
  "b": [null]         # <-- list elements of b are nullable
}
```

Documents of this format could be stored in this Arrow schema

```python
Field(name: "a", nullable: true, datatype: List(
  Field(name: "element", nullable: true, datatype: Int32),
)
Field(name: "b"), nullable: false, datatype: List(
  Field(name: "element", nullable: true, datatype: Struct[
    Field(name: "b1", nullable: false, datatype: Int32),
    Field(name: "b2", nullable: true, datatype: List(
      Field(name: "element", nullable: false, datatype: Int32)
    ))
  ])
))
```


As explained previously, Arrow chooses to represent this in a hierarchical fashion. `StructArray`s are stored as child arrays that contain each field of the struct.  `ListArray`s are stored as lists of monotonically increasing integers called offsets, with values stored in a single child array. Each consecutive pair of elements in the offset array identifies a slice of the child array for that array index.

The Arrow encoding of the example would be:


```text
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                     ┌──────────────────┐
│ ┌─────┐   ┌─────┐  │ ┌─────┐   ┌─────┐│ │
  │  1  │   │  0  │  │ │  1  │   │  1  ││
│ ├─────┤   ├─────┤  │ ├─────┤   ├─────┤│ │
  │  0  │   │  1  │  │ │  0  │   │ ??  ││
│ ├─────┤   ├─────┤  │ ├─────┤   ├─────┤│ │
  │  1  │   │  1  │  │ │  0  │   │ ??  ││
│ └─────┘   ├─────┤  │ └─────┘   └─────┘│ │
            │  3  │  │ Validity   Values│
│ Validity  └─────┘  │                  │ │
                     │ child[0]         │
│ "a"       Offsets  │ PrimitiveArray   │ │
  ListArray          └──────────────────┘
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
           ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │
│                    ┌──────────┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  ┌─────┐  │ ┌─────┐ │ ┌─────┐  │   ┌─────┐ ┌─────┐ ┌──────────┐ │ │ │
│ │  0  │    │  1  │ │ │  1  │  │ │ │  0  │ │  0  │ │ ┌─────┐  │
  ├─────┤  │ ├─────┤ │ ├─────┤  │   ├─────┤ ├─────┤ │ │  3  │  │ │ │ │
│ │  2  │    │  1  │ │ │  1  │  │ │ │  1  │ │  0  │ │ ├─────┤  │
  ├─────┤  │ ├─────┤ │ ├─────┤  │   ├─────┤ ├─────┤ │ │  4  │  │ │ │ │
│ │  3  │    │  1  │ │ │  2  │  │ │ │  0  │ │  2  │ │ └─────┘  │
  ├─────┤  │ ├─────┤ │ ├─────┤  │   ├─────┤ ├─────┤ │          │ │ │ │
│ │  4  │    │  0  │ │ │ ??  │  │ │ │ ??  │ │  2  │ │  Values  │
  └─────┘  │ └─────┘ │ └─────┘  │   └─────┘ ├─────┤ │          │ │ │ │
│                    │          │ │         │  2  │ │          │
  Offsets  │ Validity│ Values   │           └─────┘ │          │ │ │ │
│                    │          │ │Validity         │ child[0] │
           │         │ "b1"     │           Offsets │ Primitive│ │ │ │
│                    │ Primitive│ │ "b2"            │ Array    │
           │         │ Array    │   ListArray       └──────────┘ │ │ │
│                    └──────────┘ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
           │ "element"                                             │ │
│            StructArray
  "b"      └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │
│ ListArray
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

Documents of this format could be stored in this Parquet schema

```python
message schema {
  optional group a (LIST) {
    repeated group list {
      optional int32 element;
    }
  }
  required group b (LIST) {
    repeated group list {
      optional group element {
        required int32 b1;
        optional group b2 (LIST) {
          repeated group list {
            required int32 element;
          }
        }
      }
    }
  }
}
```

As explained in our previous posts, Parquet uses repetition levels and definition levels to encode nested structures and nullability.

Definition and repetition levels is a non trivial topic. For more detail, you can read the [Google Dremel Paper](https://research.google/pubs/pub36632/) which offers an academic description of the algorithm. You can also explore this [gist](https://gist.github.com/alamb/acd653c49e318ff70672b61325ba3443) to see Rust [parquet](https://crates.io/crates/parquet) code which generates the example below.

The Parquet encoding of the example would be:

```text
┌───────────────────────────────┐ ┌────────────────────────────────┐
│ ┌─────┐    ┌─────┐    ┌─────┐ │ │  ┌─────┐    ┌─────┐    ┌─────┐ │
│ │  3  │    │  0  │    │  1  │ │ │  │  2  │    │  0  │    │  1  │ │
│ ├─────┤    ├─────┤    └─────┘ │ │  ├─────┤    ├─────┤    ├─────┤ │
│ │  0  │    │  0  │            │ │  │  2  │    │  1  │    │  1  │ │
│ ├─────┤    ├─────┤      Data  │ │  ├─────┤    ├─────┤    ├─────┤ │
│ │  2  │    │  0  │            │ │  │  2  │    │  0  │    │  2  │ │
│ ├─────┤    ├─────┤            │ │  ├─────┤    ├─────┤    └─────┘ │
│ │  2  │    │  1  │            │ │  │  1  │    │  0  │            │
│ └─────┘    └─────┘            │ │  └─────┘    └─────┘     Data   │
│                               │ │                                │
│Definition Repetition          │ │ Definition Repetition          │
│  Levels     Levels            │ │   Levels     Levels            │
│                               │ │                                │
│ "a"                           │ │  "b.b1"                        │
└───────────────────────────────┘ └────────────────────────────────┘

┌───────────────────────────────┐
│  ┌─────┐    ┌─────┐    ┌─────┐│
│  │  2  │    │  0  │    │  3  ││
│  ├─────┤    ├─────┤    ├─────┤│
│  │  4  │    │  1  │    │  4  ││
│  ├─────┤    ├─────┤    └─────┘│
│  │  4  │    │  2  │           │
│  ├─────┤    ├─────┤           │
│  │  2  │    │  0  │           │
│  ├─────┤    ├─────┤     Data  │
│  │  1  │    │  0  │           │
│  └─────┘    └─────┘           │
│Definition  Repetition         │
│  Levels      Levels           │
│                               │
│  "b.b2"                       │
└───────────────────────────────┘
```

## Additional Complications

This series of posts has necessarily glossed over a number of details that further complicate actual implementations:

* A `ListArray` may contain a non-empty offset range that is masked by a validity mask
* Reading a given number of rows from a nullable field requires reading the definition levels and determining the number of values to read based on the number of nulls present
* Reading a given number of rows from a repeated field requires reading the repetition levels and detecting a new row based on a repetition level of 0
* A Parquet file may contain multiple row groups, each containing multiple column chunks
* A column chunk may contain multiple pages, and there is no relationship between pages across columns
* Parquet has alternative schema for representing lists with varying degrees of nullability
* And more…

## Summary
Both Parquet and Arrow are columnar formats and support nested structs and lists, however, the way they represent such nesting differs significantly and conversion between the two formats is complex.

Fortunately, with the Rust [parquet](https://crates.io/crates/parquet) implementation, reading and writing nested data in Arrow, in Parquet or converting between the two is as simple as reading unnested data. The library handles all the complex record shredding and reconstruction automatically. With this and other exciting features, such as support for [reading asynchronously](https://docs.rs/parquet/22.0.0/parquet/arrow/async_reader/index.html) from [object storage](https://docs.rs/object_store), it is the fastest and most feature complete Rust parquet implementation available. We look forward to seeing what you build with it!
