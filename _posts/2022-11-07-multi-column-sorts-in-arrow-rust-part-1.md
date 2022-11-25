---
layout: post
title: "Fast and Memory Efficient Multi-Column Sorts in Apache Arrow Rust, Part 1"
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

Sorting is one of the most fundamental operations in modern databases and other analytic systems, underpinning important operators such as aggregates, joins, window functions, merge, and more. By some estimates, more than half of the execution time in data processing systems is spent sorting. Optimizing sorts is therefore vital to improving query performance and overall system efficiency.

Sorting is also one of the most well studied topics in computer science. The classic survey paper for databases is [Implementing Sorting in Database Systems](https://dl.acm.org/doi/10.1145/1132960.1132964) by Goetz Graefe which provides a thorough academic treatment and is still very applicable today. However, it may not be obvious how to apply the wisdom and advanced techniques described in that paper to modern systems. In addition, the excellent [DuckDB blog on sorting](https://duckdb.org/2021/08/27/external-sorting.html) highlights many sorting techniques, and mentions a comparable row format, but it does not explain how to efficiently sort variable length strings or dictionary encoded data.

In this series we explain in detail the new [row format](https://docs.rs/arrow/27.0.0/arrow/row/index.html) in the [Rust implementation](https://github.com/apache/arrow-rs) of [Apache Arrow](https://arrow.apache.org/), and how we used to make sorting more than [3x](https://github.com/apache/arrow-rs/pull/2929) faster than an alternate comparator based approach. The benefits are especially pronounced for strings, dictionary encoded data, and sorts with large numbers of columns.


## Multicolumn / Lexicographical Sort Problem

Most languages have native, optimized operations to sort a single column (array) of data, which are specialized based on the type of data being sorted. The reason that sorting is typically more challenging in analytic systems is that:

1. They must support multiple columns of data
2. The column types are not knowable at compile time, and thus the compiler can not typically generate optimized code

Multicolumn sorting is also referred to as lexicographical sorting in some libraries.

For example, given sales data for various customers and their state of residence, a user might want to find the lowest 10 orders for each state.

```text
Customer | State | Orders
—--------+-------+-------
12345    |  MA   |  10.12
532432   |  MA   |  8.44
12345    |  CA   |  3.25
56232    |  WA   |  6.00
23442    |  WA   |  132.50
7844     |  CA   |  9.33
852353   |  MA   |  1.30
```

One way to do so is to order the data first by `State` and then by `Orders`:
```text
Customer | State | Orders
—--------+-------+-------
12345    |  CA   |  3.25
7844     |  CA   |  9.33
852353   |  MA   |  1.30
532432   |  MA   |  8.44
12345    |  MA   |  10.12
56232    |  WA   |  6.00
23442    |  WA   |  132.50
```

(Note: While there are specialized ways for computing this particular query other than fully sorting the entire input (e.g. "TopK"), they typically need the same multi-column comparison operation described below. Thus while we will use the simplified example in this series, it applies much more broadly)

## Basic Implementation

Let us take the example of a basic sort kernel which takes a set of columns as input, and returns a list of indices identifying a sorted order.

```python
> lexsort_to_indices([
    ["MA", "MA", "CA", "WA", "WA", "CA", "MA"]
  ])

[2, 5, 0, 1, 6, 3, 4]

> lexsort_to_indices([
    ["MA", "MA", "CA", "WA", "WA",   "CA", "MA"],
    [10.10, 8.44, 3.25, 6.00, 132.50, 9.33, 1.30]
  ])

[2, 5, 6, 1, 0, 3, 4]
```

This function returns a list of indices instead of sorting the columns directly because it:
1. Avoids expensive copying data during the sorting process
2. Allows deferring copying of values until the latest possible moment
3. Can be used to reorder additional columns that weren’t part of the sort key


A straightforward implementation of lexsort_to_indices uses a comparator function,

```text
   row
  index
        ┌─────┐   ┌─────┐   ┌─────┐     compare(left_index, right_index)
      0 │     │   │     │   │     │
       ┌├─────┤─ ─├─────┤─ ─├─────┤┐                   │             │
        │     │   │     │   │     │ ◀──────────────────┘             │
       └├─────┤─ ─├─────┤─ ─├─────┤┘                                 │
        │     │   │     │   │     │Comparator function compares one  │
        ├─────┤   ├─────┤   ├─────┤ multi-column row with another.   │
        │     │   │     │   │     │                                  │
        ├─────┤   ├─────┤   ├─────┤ The data types of the columns    │
        │     │   │     │   │     │  and the sort options are not    │
        └─────┘   └─────┘   └─────┘  known at compile time, only     │
                    ...                        runtime               │
                                                                     │
       ┌┌─────┐─ ─┌─────┐─ ─┌─────┐┐                                 │
        │     │   │     │   │     │ ◀────────────────────────────────┘
       └├─────┤─ ─├─────┤─ ─├─────┤┘
        │     │   │     │   │     │
        ├─────┤   ├─────┤   ├─────┤
    N-1 │     │   │     │   │     │
        └─────┘   └─────┘   └─────┘
        Customer    State    Orders
         UInt64      Utf8     F64
```


The comparator function compares each row a column at a time, based on the column types

```text
                         ┌────────────────────────────────┐
                         │                                │
                         ▼                                │
                     ┌ ─ ─ ─ ┐ ┌ ─ ─ ─ ┐                  │
                                                          │
            ┌─────┐  │┌─────┐│ │┌─────┐│                  │
left_index  │     │   │     │   │     │                   │
            └─────┘  │└─────┘│ │└─────┘│   Step 1: Compare State
                                                    (UInt64)
                     │       │ │       │

                     │       │ │       │
            ┌─────┐   ┌─────┐   ┌─────┐
 right_index│     │  ││     ││ ││     ││
            └─────┘   └─────┘   └─────┘    Step 2: If State values equal
                     │       │ │       │   compare Orders (F64)
            Customer   State     Orders                     │
             UInt64  │  Utf8 │ │  F64  │                    │
                      ─ ─ ─ ─   ─ ─ ─ ─                     │
                                    ▲                       │
                                    │                       │
                                    └───────────────────────┘
```

Pseudocode for this operation might look something like

```python
# Takes a list of columns and returns the lexicographically
# sorted order as a list of indices
def lexsort_to_indices(columns):
  comparator = build_comparator(columns)

  # Construct a list of integers from 0 to the number of rows
  # and sort it according to the comparator
  [0..columns.num_rows()].sort_by(comparator)

# Build a function that given indexes (left_idx, right_idx)
# returns the comparison of the sort keys at the left
# and right indices respectively
def build_comparator(columns):
  def comparator(left_idx, right_idx):
    for column in columns:
      # call a compare function which performs
      # dynamic dispatch on type of left and right columns
      ordering = compare(column, left_idx,right_idx)
      if ordering != Equal {
        return ordering
      }
    # All values equal
    Equal
  # Return comparator function
  comparator

  # compares the values in a single column at left_idx and right_idx
  def compare(column, left_idx, right_idx):
    # Choose comparison based on type of column ("dynamic dispatch")
    if column.type == Int:
     cmp(column[left_idx].as_int(), column[right_idx].as_int())
    elif column.type == Float:
     cmp(column[left_idx].as_float(), column[right_idx].as_float())
    ...
```

Greater detail is beyond the scope of this post, but in general the more predictable the behavior of a block of code, the better its performance will be. In the case of this pseudocode,  there is clear room for improvement:

1. `comparator` performs a large number of unpredictable conditional branches, where the path execution takes depends on the data values
2. `comparator` and `compare` use dynamic dispatch, which not only adds further conditional branches, but also function call overhead
3. `comparator` performs a large number of reads of memory at unpredictable locations

You can find the complete implementation of multi-column comparator construction in arrow-rs in [sort.rs](https://github.com/apache/arrow-rs/blob/f629a2ebe08033e7b78585d82e98c50a4439e7a2/arrow/src/compute/kernels/sort.rs#L905-L1036) and [ord.rs](https://github.com/apache/arrow-rs/blob/f629a2e/arrow/src/array/ord.rs#L178-L313).


# Normalized Keys / Byte Array Comparisons

Now imagine we had a way to represent each logical row of data as a sequence of bytes, and that byte-wise comparison of that sequence yielded the same result as comparing the actual column values using the code above. Such a representation would require no switching on column types, and the kernel would become

```python
def lexsort_to_indices(columns):
  rows = convert_to_rows(columns)
  [0..columns.num_rows()].sort_by(lambda l, r: cmp(rows[l], rows[r]))
```

While this approach does require converting to/from the byte array representation, it has some major advantages:

* Rows can be compared by comparing bytes in memory, which modern computer hardware excels at with the extremely well optimized [memcmp](https://www.man7.org/linux/man-pages/man3/memcmp.3.html)
* Memory accesses are largely predictable
* There is no dynamic dispatch overhead
* Extends straightforwardly to more sophisticated sorting strategies such as
    * Distribution-based sorting techniques such as radix sort
    * Parallel merge sort
    * External sort
    * ...

You can find more information on how to leverage such representation in the "Binary String Comparison" section of the [DuckDB blog post](https://duckdb.org/2021/08/27/external-sorting.html) on the topic as well as [Graefe’s paper](https://dl.acm.org/doi/10.1145/1132960.1132964). However, we found it wasn’t immediately obvious how to apply this technique to variable length string or dictionary encoded data, which we will explain in the next post in this series.


## Next up: Row Format

This post has introduced the concept and challenges of multi column sorting, and shown why a comparable byte array representation, such as the [row format](https://docs.rs/arrow/27.0.0/arrow/row/index.html) introduced to the [Rust implementation](https://github.com/apache/arrow-rs) of [Apache Arrow](https://arrow.apache.org/), is such a compelling primitive.

In [the next post]({% post_url 2022-11-07-multi-column-sorts-in-arrow-rust-part-2 %}) we explain how this encoding works, but if you just want to use it, check out the [docs](https://docs.rs/arrow/27.0.0/arrow/row/index.html) for getting started, and report any issues on our [bugtracker](https://github.com/apache/arrow-rs/issues). As always, the [Arrow community](https://github.com/apache/arrow-rs#arrow-rust-community) very much looks forward to seeing what you build with it!
