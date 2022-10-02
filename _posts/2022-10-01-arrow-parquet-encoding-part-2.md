---
layout: post
title: Arrow and Parquet Part 2: Nested and Hierarchal Data using Structs and Lists
date: "2022-10-01 00:00:00"
author: tustvold, alamb
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

This is the second, in a three part series exploring how projects such as [Rust Apache Arrow](https://github.com/apache/arrow-rs) support conversion between [Apache Arrow](https://arrow.apache.org/) for in memory processing and [Apache Parquet](https://parquet.apache.org/) for efficient storage. This post covers `Struct` and `List` types.


[Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.


## Struct / Group Columns

Both Parquet and Arrow have the concept of a struct column, this is a column that contains one or more other columns.

For example consider the following three JSON documents

```json
{              <-- First record
  “a”: 1,      <-- the top level fields are a, b, c, and d
  “b”: {
    “b1”: 1,   <-- b1 and b2 are “nested” fields of “b”
    “b2”: 3    <-- b2 is always provided (not null)
   },
 “d”: {
   “d1”:  1    <-- d1 is a “nested” field of “d”
  }
}
```
```json
{              <-- Second record
  “a”: 2,
  “b”: {
    “b2”: 4    <-- note “b1” is NULL in this record
  },
  “c”: {       <-- note “c” was NULL in the first record
    “c1”: 6        but when “c” is provided, c1 is also always provided
  },
  “d”: {
    “d1”: 2,
    “d2”: 1
  }
}
```
```json
{              <-- Third record
  “b”: {
    “b1”: 5,
    “b2”: 6
  },
  “c”: {
    “c1”: 7
  }
}
```
Documents of this format could be stored in this arrow schema

```text
Field(name: “a”, nullable: true, datatype: Int32)
Field(name: “b”, nullable: false, datatype: Struct[
  Field(name: “b1”, nullable: true, datatype: Int32),
  Field(name: “b2”, nullable: false, datatype: Int32)
])
Field(name: “c”), nullable: true, datatype: Struct[
  Field(name: “c1”, nullable: false, datatype: Int32)
])
Field(name: “d”), nullable: true, datatype: Struct[
  Field(name: “d1”, nullable: false, datatype: Int32)
  Field(name: “d2”, nullable: true, datatype: Int32)
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

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
             ┌───────────┐                  ┌──────────┐┌──────────────────┐ │
│   ┌─────┐  │ ┌─────┐   │  │ │   ┌─────┐   │┌─────┐   ││ ┌─────┐   ┌─────┐│
    │  0  │  │ │ ??  │   │        │  1  │   ││  1  │   ││ │  0  │   │ ??  ││ │
│   ├─────┤  │ ├─────┤   │  │ │   ├─────┤   │├─────┤   ││ ├─────┤   ├─────┤│
    │  1  │  │ │  6  │   │        │  1  │   ││  2  │   ││ │  1  │   │  1  ││ │
│   ├─────┤  │ ├─────┤   │  │ │   ├─────┤   │├─────┤   ││ ├─────┤   ├─────┤│
    │  1  │  │ │  7  │   │        │  0  │   ││ ??  │   ││ │ ??  │   │ ??  ││ │
│   └─────┘  │ └─────┘   │  │ │   └─────┘   │└─────┘   ││ └─────┘   └─────┘│
    Validity │  Values   │        Validity  │ Values   ││ Validity   Values│ │
│            │           │  │ │             │          ││                  │
             │ "c.c1"    │                  │"d.d1"    ││ "d.d2"           │ │
│            │ Primitive │  │ │             │Primitive ││ PrimitiveArray   │
             │ Array     │                  │Array     ││                  │ │
│            └───────────┘  │ │             └──────────┘└──────────────────┘
     "c"                           "d"                                       │
│    StructArray            │ │    StructArray
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
 ```

### Definition Levels
Unlike Arrow, Parquet does not encode validity in a structured fashion, instead only storing definition levels for each of the primitive columns, i.e. those that aren’t groups. The definition level of a given element, is the depth in the schema at which it is fully defined.

For example consider the case of d.d2, which contains two nullable levels d and d2.

A definition level of 0 would imply a null at the level of d:

```json
{
}
```

A definition level of 1 would imply a null at the level of d.d2

```json
{
  d: { .. }
}
```

A definition level of 2 would imply a defined value for d.d2:

```json
{
  d: { d2: .. }
}
```


Goin back to the JSON documents above, this format could be stored in this parquet schema

```text
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

Thus the parquet encoding of the example would be:

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


┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  ┌──────────────────────┐ │   ┌──────────────────────┐ ┌──────────────────────┐  │
│ │  ┌─────┐    ┌─────┐  │   │ │  ┌─────┐    ┌─────┐  │ │ ┌─────┐     ┌─────┐  │
  │  │  0  │    │  6  │  │ │   │  │  1  │    │  1  │  │ │ │  1  │     │  1  │  │  │
│ │  ├─────┤    ├─────┤  │   │ │  ├─────┤    ├─────┤  │ │ ├─────┤     └─────┘  │
  │  │  1  │    │  7  │  │ │   │  │  1  │    │  2  │  │ │ │  2  │              │  │
│ │  ├─────┤    └─────┘  │   │ │  ├─────┤    └─────┘  │ │ ├─────┤              │
  │  │  1  │             │ │   │  │  0  │             │ │ │  0  │              │  │
│ │  └─────┘             │   │ │  └─────┘             │ │ └─────┘              │
  │                      │ │   │                      │ │                      │  │
│ │  Definition   Data   │   │ │  Definition   Data   │ │ Definition   Data    │
  │    Levels            │ │   │    Levels            │ │   Levels             │  │
│ │                      │   │ │                      │ │                      │
  │  "c.1"               │ │   │  "d.1"               │ │  "d.d2"              │  │
│ └──────────────────────┘   │ └──────────────────────┘ └──────────────────────┘
     "c"                   │      "d"                                             │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ```

## List / Repeated Columns

Closing out support for nested types is columns containing a variable number of values. For example,

```json
{                     <-- First record
  “a”: [1],           <-- top-level field a containing list of integers
}
```
```json
{                     <-- “a” is not provided (is null)
}
```
```json
{                     <-- “a” is non-null but empty
  "a": []
}
```
```json
{
  “a”: [null, 2],  <-- list elements of a are nullable
}
```

Documents of this format could be stored in this Arrow schema

```text
Field(name: “a”, nullable: true, datatype: List(
  Field(name: “element”, nullable: true, datatype: Int32),
)
```

Documents of this format could be stored in this parquet schema

```text
message schema {
  optional group a (LIST) {
    repeated group list {
      optional int32 element;
    }
  }
}
```

As before, Arrow chooses to represent this in a hierarchical fashion with a list of monotonically increasing integers called *offsets* in the parent `ListArray`, and stores all the values that appear in the lists in a single child array. Each consecutive pair of elements in this offset array identifies a slice of the child array for that array index.

For example, the list of offsets `[0, 2, 3, 3]` contains 3 pairs of offsets, `(0,2)`, `(1,3)`, and `(3,3)`, and is therefore a ListArray of length 3 with the following values:

```text
0: [child[0], child[1]]
1: []
2: [child[2]]
```

For the example above with 4 JSON documents, this would be encoded in arrow as


```text
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                          ┌──────────────────┐ │
│    ┌─────┐   ┌─────┐    │ ┌─────┐   ┌─────┐│
     │  1  │   │  0  │    │ │  1  │   │  1  ││ │
│    ├─────┤   ├─────┤    │ ├─────┤   ├─────┤│
     │  0  │   │  1  │    │ │  1  │   │  2  ││ │
│    ├─────┤   ├─────┤    │ ├─────┤   ├─────┤│
     │  1  │   │  1  │    │ │  0  │   │ ??  ││ │
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

### Repetition Levels

In order to encode lists, Parquet stores an integer *repetition level* in addition to a definition level. A repetition level identifies where in the hierarchy of repeated fields the current value is to be inserted. A value of 0 would imply a new list in the top-most repeated field, a value of 1 a new element within the top-most repeated field, a value of 2 a new element within the second top-most repeated field, and so on.

Each repeated field also has a corresponding definition level, however, in this case rather than indicating a null value, they indicate an empty array.



```text
┌────────────────────────────────────────┐
│  ┌─────┐       ┌─────┐                 │
│  │  1  │       │  3  │                 │
│  ├─────┤       ├─────┤                 │
│  │  0  │       │  0  │                 │
│  ├─────┤       ├─────┤        ┌─────┐  │
│  │  1  │       │  2  │        │  1  │  │
│  ├─────┤       ├─────┤        ├─────┤  │
│  │  0  │       │  2  │        │  2  │  │
│  └─────┘       └─────┘        └─────┘  │
│  Definition   Repetition       Data    │
│    Levels       Levels                 │
│    "a"                                 │
└────────────────────────────────────────┘
```




## Next up: Arbitrary Nesting: Lists of Structs and Structs of Lists

In our next blog post <!-- When published, add link here --> we will explain how Parquet and Arrow combine these concepts to support arbitrary nesting of potentially nullable data structures.
