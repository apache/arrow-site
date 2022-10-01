---
layout: post
title: Arrow and Parquet Part 3: Arbitrary Nesting with Lists of Structs and Structs of Lists
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

This is the third of a three part series exploring how projects such as [Rust Apache Arrow](https://github.com/apache/arrow-rs) support conversion between [Apache Arrow](https://arrow.apache.org/) for in memory processing and [Apache Parquet](https://parquet.apache.org/) for efficient storage. This post covers how to combine the `Struct` and `List` types described in the previous posts for arbitrary nesting.


[Apache Arrow](https://arrow.apache.org/) is an open, language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations. [Apache Parquet](https://parquet.apache.org/) is an open, column-oriented data file format designed for very efficient data encoding and retrieval.


# Structs with Lists


```json
{                     <-- First record
  “a”: [1],           <-- top-level field a containing list of integers
  “b”: [              <-- top-level field b containing list of structures
    {                 <-- list element of b containing two field b1 and b2
      “b1”: 1         <-- b1 is always provided (not null)
    },
    {
      “b1”: 1,
      “b2”: [         <-- b2 contains list of integers
        3, 4          <-- list elements of b.b2 always provided (not null)
      ]
    }
  ]
}
{
  “b”: [              <-- b is always provided (not null)
    {
      “b1”: 2
    },
  ]
}
{
  “a”: [null, null],  <-- list elements of a are nullable
  “b”: [null]         <-- list elements of b are nullable
}
```

Documents of this format could be stored in this arrow schema

```text
Field(name: “a”, nullable: true, datatype: List(
  Field(name: “element”, nullable: true, datatype: Int32),
)
Field(name: “b”), nullable: false, datatype: List(
  Field(name: “element”, nullable: true, datatype: Struct[
    Field(name: “b2”, nullable: false, datatype: Int32),
    Field(name: “c2”, nullable: true, datatype: List(
      Field(name: “element”, nullable: false, datatype: Int32)
    ))
  ])
))
```

Documents of this format could be stored in this parquet schema

```text
message schema {
  optional group a (LIST) {
    repeated group list {
      optional int32 element;
    }
  }
  required group b (LIST) {
    repeated group list {
      optional group element {
        required int32 c1;
        optional group c2 (LIST) {
          repeated group list {
            required int32 element;
          }
        }
      }
    }
  }
}
```

As explained previously, Arrow chooses to represent this in a hierarchical fashion. To achieve this it stores a list of monotonically increasing integers called offsets in the parent ListArray, and stores all the values that appear in the lists in a single child array. Each consecutive pair of elements in this offset array identifies a slice of the child array for that array index.

```text
a: ListArray
  Offsets: [0, 1, 1, 3]
  Validity: [true, false, true]
  Children:
    element: PrimitiveArray
      Buffer[0]: [1, ARBITRARY, ARBITRARY]
      Validity: [true, false, false]
b: ListArray
  Offsets: [0, 2, 3, 4]
  Children:
    element: StructArray
      Validity: [true, true, true, false]
      Children:
        c1: PrimitiveArray
          Buffer[0]: [1, 1, 2, ARBITRARY]
        c2: ListArray
          Offsets: [0, 0, 2, 2, 2]
          Validity: [false, true, false, ARBITRARY]
          Children:
            element: PrimitiveArray
              Buffer[0]: [3, 4]
```

In order to encode lists, Parquet stores an integer repetition level in addition to a definition level. A repetition level identifies where in the hierarchy of repeated fields the current value is to be inserted. A value of 0 would imply a new list in the top-most repeated field, a value of 1 a new element within the top-most repeated field, a value of 2 a new element within the second top-most repeated field, and so on.

Each repeated field also has a corresponding definition level, however, in this case rather than indicating a null value, they indicate an empty array.

```text
a:
  Data Page:
    Repetition Levels: encode([0, 0, 0, 1])
    Definition Levels: encode([3, 0, 2, 2])
    Values: encode([1])
b.c1:
  Data Page:
    Repetition Levels: encode([0, 1, 0, 0])
    Definition Levels: encode([2, 2, 2, 1])
    Values: encode([1, 1, 2])
b.c2
  Data Page:
    Repetition Levels: encode([0, 1, 2, 0, 0])
    Definition Levels: encode([2, 3, 3, 2, 1])
    Values: encode([3, 4])
```

## Additional Complications

This series of posts has necessarily glossed over a number of details that further complicate matters:

* A `ListArray` may contain a non-empty offset range that is masked by a validity mask
* Reading a given number of rows from a nullable field requires reading the definition levels and determining the number of values to read based on the number of nulls present
* Reading a given number of rows from a repeated field requires reading the repetition levels and detecting a new row based on a repetition level of 0
* A parquet file may contain multiple row groups, each containing multiple column chunks
* A column chunk may contain multiple pages, and there is no relationship between pages across columns
* Parquet has alternative schema for representing lists with varying degrees of nullability
* And more…

## Summary
As we have shown, whilst both parquet and arrow are billed as columnar formats supporting nested data, the way they represent this differs quite significantly and conversion between the two is fairly complex.

Fortunately, with the Rust [parquet](https://crates.io/crates/parquet) implementation, reading and writing nested data either into Arrow or other formats is as simple as reading unnested data, with all the complex record shredding handled automatically for you. With this and other exciting features, such as out of the box support for [reading asynchronously](https://docs.rs/parquet/22.0.0/parquet/arrow/async_reader/index.html) from [object storage](https://docs.rs/object_store/0.5.0/object_store/), and advanced row filter pushdown, blog post to follow, it is the fastest and most feature complete Rust parquet implementation. We look forward to seeing what you build with it!
