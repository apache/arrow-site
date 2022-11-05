---
layout: post
title: "Arrow and Parquet Part 2: Nested and Hierarchical Data using Structs and Lists"
date: "2022-10-08 00:00:00"
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

This is the second, in a three part series exploring how projects such as [Rust Apache Arrow](https://github.com/apache/arrow-rs) support conversion between [Apache Arrow](https://arrow.apache.org/) and [Apache Parquet](https://parquet.apache.org/). The [first post](https://arrow.apache.org/blog/2022/10/05/arrow-parquet-encoding-part-1/) covered the basics of data storage and validity encoding, and this post will cover the more complex `Struct` and `List` types.

[Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.


## Struct / Group Columns

Both Parquet and Arrow have the concept of a *struct* column, which is a column containing one or more other columns in named fields and is analogous to a JSON object.

For example, consider the following three JSON documents

```python
{              # <-- First record
  "a": 1,      # <-- the top level fields are a, b, c, and d
  "b": {       # <-- b is always provided (not nullable)
    "b1": 1,   # <-- b1 and b2 are "nested" fields of "b"
    "b2": 3    # <-- b2 is always provided (not nullable)
   },
 "d": {
   "d1":  1    # <-- d1 is a "nested" field of "d"
  }
}
```
```python
{              # <-- Second record
  "a": 2,
  "b": {
    "b2": 4    # <-- note "b1" is NULL in this record
  },
  "c": {       # <-- note "c" was NULL in the first record
    "c1": 6        but when "c" is provided, c1 is also
  },               always provided (not nullable)
  "d": {
    "d1": 2,
    "d2": 1
  }
}
```
```python
{              # <-- Third record
  "b": {
    "b1": 5,
    "b2": 6
  },
  "c": {
    "c1": 7
  }
}
```
Documents of this format could be stored in an Arrow `StructArray` with this schema

```python
Field(name: "a", nullable: true, datatype: Int32)
Field(name: "b", nullable: false, datatype: Struct[
  Field(name: "b1", nullable: true, datatype: Int32),
  Field(name: "b2", nullable: false, datatype: Int32)
])
Field(name: "c"), nullable: true, datatype: Struct[
  Field(name: "c1", nullable: false, datatype: Int32)
])
Field(name: "d"), nullable: true, datatype: Struct[
  Field(name: "d1", nullable: false, datatype: Int32)
  Field(name: "d2", nullable: true, datatype: Int32)
])
```


Arrow represents each `StructArray` hierarchically using a parent child relationship, with separate validity masks on each of the individual nullable arrays

```text
  ┌───────────────────┐        ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  │                   │           ┌─────────────────┐ ┌────────────┐
  │ ┌─────┐   ┌─────┐ │        │  │┌─────┐   ┌─────┐│ │  ┌─────┐   │ │
  │ │  1  │   │  1  │ │           ││  1  │   │  1  ││ │  │  3  │   │
  │ ├─────┤   ├─────┤ │        │  │├─────┤   ├─────┤│ │  ├─────┤   │ │
  │ │  1  │   │  2  │ │           ││  0  │   │ ??  ││ │  │  4  │   │
  │ ├─────┤   ├─────┤ │        │  │├─────┤   ├─────┤│ │  ├─────┤   │ │
  │ │  0  │   │ ??  │ │           ││  1  │   │  5  ││ │  │  6  │   │
  │ └─────┘   └─────┘ │        │  │└─────┘   └─────┘│ │  └─────┘   │ │
  │ Validity   Values │           │Validity   Values│ │   Values   │
  │                   │        │  │                 │ │            │ │
  │ "a"               │           │"b.b1"           │ │  "b.b2"    │
  │ PrimitiveArray    │        │  │PrimitiveArray   │ │  Primitive │ │
  └───────────────────┘           │                 │ │  Array     │
                               │  └─────────────────┘ └────────────┘ │
                                    "b"
                               │    StructArray                      │
                                ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
            ┌───────────┐                ┌──────────┐┌─────────────────┐ │
│  ┌─────┐  │ ┌─────┐   │ │ │  ┌─────┐   │┌─────┐   ││ ┌─────┐  ┌─────┐│
   │  0  │  │ │ ??  │   │      │  1  │   ││  1  │   ││ │  0  │  │ ??  ││ │
│  ├─────┤  │ ├─────┤   │ │ │  ├─────┤   │├─────┤   ││ ├─────┤  ├─────┤│
   │  1  │  │ │  6  │   │      │  1  │   ││  2  │   ││ │  1  │  │  1  ││ │
│  ├─────┤  │ ├─────┤   │ │ │  ├─────┤   │├─────┤   ││ ├─────┤  ├─────┤│
   │  1  │  │ │  7  │   │      │  0  │   ││ ??  │   ││ │ ??  │  │ ??  ││ │
│  └─────┘  │ └─────┘   │ │ │  └─────┘   │└─────┘   ││ └─────┘  └─────┘│
   Validity │  Values   │      Validity  │ Values   ││ Validity  Values│ │
│           │           │ │ │            │          ││                 │
            │ "c.c1"    │                │"d.d1"    ││ "d.d2"          │ │
│           │ Primitive │ │ │            │Primitive ││ PrimitiveArray  │
            │ Array     │                │Array     ││                 │ │
│           └───────────┘ │ │            └──────────┘└─────────────────┘
    "c"                         "d"                                      │
│   StructArray           │ │   StructArray
  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
 ```

More technical detail is available in the [StructArray format specification](https://arrow.apache.org/docs/format/Columnar.html#struct-layout).

### Definition Levels
Unlike Arrow, Parquet does not encode validity in a structured fashion, instead only storing definition levels for each of the primitive columns, i.e. those that don't contain other columns. The definition level of a given element is the depth in the schema at which it is fully defined.

For example consider the case of `d.d2`, which contains two nullable levels `d` and `d2`.

A definition level of `0` would imply a null at the level of `d`:

```python
{
}
```

A definition level of `1` would imply a null at the level of `d.d2`

```python
{
  "d": { }
}
```

A definition level of `2` would imply a defined value for `d.d2`:

```python
{
  "d": { "d2": .. }
}
```


Going back to the three JSON documents above, they could be stored in Parquet with this schema

```python
message schema {
  optional int32 a;
  required group b {
    optional int32 b1;
    required int32 b2;
  }
  optional group c {
    required int32 c1;
  }
  optional group d {
    required int32 d1;
    optional int32 d2;
  }
}
```

The Parquet encoding of the example would be:

```text
 ┌────────────────────────┐  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
 │  ┌─────┐     ┌─────┐   │    ┌──────────────────────┐ ┌───────────┐ │
 │  │  1  │     │  1  │   │  │ │  ┌─────┐    ┌─────┐  │ │  ┌─────┐  │
 │  ├─────┤     ├─────┤   │    │  │  1  │    │  1  │  │ │  │  3  │  │ │
 │  │  1  │     │  2  │   │  │ │  ├─────┤    ├─────┤  │ │  ├─────┤  │
 │  ├─────┤     └─────┘   │    │  │  0  │    │  5  │  │ │  │  4  │  │ │
 │  │  0  │               │  │ │  ├─────┤    └─────┘  │ │  ├─────┤  │
 │  └─────┘               │    │  │  1  │             │ │  │  6  │  │ │
 │                        │  │ │  └─────┘             │ │  └─────┘  │
 │  Definition    Data    │    │                      │ │           │ │
 │    Levels              │  │ │  Definition   Data   │ │   Data    │
 │                        │    │    Levels            │ │           │ │
 │  "a"                   │  │ │                      │ │           │
 └────────────────────────┘    │  "b.b1"              │ │  "b.b2"   │ │
                             │ └──────────────────────┘ └───────────┘
                                  "b"                                 │
                             └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─


┌ ─ ─ ─ ─ ─ ── ─ ─ ─ ─ ─   ┌ ─ ─ ─ ─ ── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  ┌────────────────────┐ │   ┌────────────────────┐ ┌──────────────────┐ │
│ │  ┌─────┐   ┌─────┐ │   │ │  ┌─────┐   ┌─────┐ │ │ ┌─────┐  ┌─────┐ │
  │  │  0  │   │  6  │ │ │   │  │  1  │   │  1  │ │ │ │  1  │  │  1  │ │ │
│ │  ├─────┤   ├─────┤ │   │ │  ├─────┤   ├─────┤ │ │ ├─────┤  └─────┘ │
  │  │  1  │   │  7  │ │ │   │  │  1  │   │  2  │ │ │ │  2  │          │ │
│ │  ├─────┤   └─────┘ │   │ │  ├─────┤   └─────┘ │ │ ├─────┤          │
  │  │  1  │           │ │   │  │  0  │           │ │ │  0  │          │ │
│ │  └─────┘           │   │ │  └─────┘           │ │ └─────┘          │
  │                    │ │   │                    │ │                  │ │
│ │  Definition  Data  │   │ │  Definition  Data  │ │ Definition Data  │
  │    Levels          │ │   │    Levels          │ │   Levels         │ │
│ │                    │   │ │                    │ │                  │
  │  "c.1"             │ │   │  "d.1"             │ │  "d.d2"          │ │
│ └────────────────────┘   │ └────────────────────┘ └──────────────────┘
     "c"                 │      "d"                                      │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
 ```

## List / Repeated Columns

Closing out support for nested types are *lists*, which contain a variable number of other values. For example, the following four documents each have a (nullable) field `a` containing a list of integers

```python
{                     # <-- First record
  "a": [1],           # <-- top-level field a containing list of integers
}
```
```python
{                     # <-- "a" is not provided (is null)
}
```
```python
{                     # <-- "a" is non-null but empty
  "a": []
}
```
```python
{
  "a": [null, 2],     # <-- "a" has a null and non-null elements
}
```

Documents of this format could be stored in this Arrow schema

```python
Field(name: "a", nullable: true, datatype: List(
  Field(name: "element", nullable: true, datatype: Int32),
)
```

As before, Arrow chooses to represent this in a hierarchical fashion as a `ListArray`. A `ListArray` contains a list of monotonically increasing integers called *offsets*, a validity mask if the list is nullable, and a child array containing the list elements. Each consecutive pair of elements in the offset array identifies a slice of the child array for that index in the ListArray

For example, a list with offsets `[0, 2, 3, 3]` contains 3 pairs of offsets, `(0,2)`, `(2,3)`, and `(3,3)`, and therefore represents a `ListArray` of length 3 with the following values:

```python
0: [child[0], child[1]]
1: []
2: [child[2]]
```

For the example above with 4 JSON documents, this would be encoded in Arrow as


```text
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                          ┌──────────────────┐ │
│    ┌─────┐   ┌─────┐    │ ┌─────┐   ┌─────┐│
     │  1  │   │  0  │    │ │  1  │   │  1  ││ │
│    ├─────┤   ├─────┤    │ ├─────┤   ├─────┤│
     │  0  │   │  1  │    │ │  0  │   │ ??  ││ │
│    ├─────┤   ├─────┤    │ ├─────┤   ├─────┤│
     │  1  │   │  1  │    │ │  1  │   │  2  ││ │
│    ├─────┤   ├─────┤    │ └─────┘   └─────┘│
     │  1  │   │  1  │    │ Validity   Values│ │
│    └─────┘   ├─────┤    │                  │
               │  3  │    │ child[0]         │ │
│    Validity  └─────┘    │ PrimitiveArray   │
                          │                  │ │
│              Offsets    └──────────────────┘
     "a"                                       │
│    ListArray
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

More technical detail is available in the [ListArray format specification](https://arrow.apache.org/docs/format/Columnar.html#variable-size-list-layout).


### Parquet Repetition Levels

The example above with 4 JSON documents can be stored in this Parquet schema

```python
message schema {
  optional group a (LIST) {
    repeated group list {
      optional int32 element;
    }
  }
}
```

In order to encode lists, Parquet stores an integer *repetition level* in addition to a definition level. A repetition level identifies where in the hierarchy of repeated fields the current value is to be inserted. A value of `0` means a new list in the top-most repeated list, a value of `1` means a new element within the top-most repeated list, a value of `2` means a new element within the second top-most repeated list, and so on.

A consequence of this encoding is that the number of zeros in the `repetition` levels is the total number of rows in the column, and the first level in a column must be 0.

Each repeated field also has a corresponding definition level, however, in this case rather than indicating a null value, they indicate an empty array.

The example above would therefore be encoded as


```text
┌─────────────────────────────────────┐
│  ┌─────┐      ┌─────┐               │
│  │  3  │      │  0  │               │
│  ├─────┤      ├─────┤               │
│  │  0  │      │  0  │               │
│  ├─────┤      ├─────┤      ┌─────┐  │
│  │  1  │      │  0  │      │  1  │  │
│  ├─────┤      ├─────┤      ├─────┤  │
│  │  2  │      │  0  │      │  2  │  │
│  ├─────┤      ├─────┤      └─────┘  │
│  │  3  │      │  1  │               │
│  └─────┘      └─────┘               │
│                                     │
│ Definition  Repetition      Values  │
│   Levels      Levels                │
│  "a"                                │
│                                     │
└─────────────────────────────────────┘
```



## Next up: Arbitrary Nesting: Lists of Structs and Structs of Lists

In our [final blog post](https://arrow.apache.org/blog/2022/10/17/arrow-parquet-encoding-part-3/), we explain how Parquet and Arrow combine these concepts to support arbitrary nesting of potentially nullable data structures.

If you want to store and process structured types, you will be pleased to hear that the Rust [parquet](https://crates.io/crates/parquet) implementation fully supports reading and writing directly into Arrow, as simply as any other type. All the complex record shredding and reconstruction is handled automatically. With this and other exciting features such as  [reading asynchronously](https://docs.rs/parquet/22.0.0/parquet/arrow/async_reader/index.html) from [object storage](https://docs.rs/object_store/0.5.0/object_store/), and advanced row filter pushdown, it is the fastest and most feature complete Rust parquet implementation. We look forward to seeing what you build with it!
