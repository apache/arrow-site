# Apply a function to a stream of RecordBatches

As an alternative to calling
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) on a
`Dataset` query, you can use this function to access the stream of
`RecordBatch`es in the `Dataset`. This lets you do more complex
operations in R that operate on chunks of data without having to hold
the entire Dataset in memory at once. You can include `map_batches()` in
a dplyr pipeline and do additional dplyr methods on the stream of data
in Arrow after it.

## Usage

``` r
map_batches(X, FUN, ..., .schema = NULL, .lazy = TRUE, .data.frame = NULL)
```

## Arguments

- X:

  A `Dataset` or `arrow_dplyr_query` object, as returned by the `dplyr`
  methods on `Dataset`.

- FUN:

  A function or `purrr`-style lambda expression to apply to each batch.
  It must return a RecordBatch or something coercible to one via
  \`as_record_batch()'.

- ...:

  Additional arguments passed to `FUN`

- .schema:

  An optional
  [`schema()`](https://arrow.apache.org/docs/r/reference/schema.md). If
  NULL, the schema will be inferred from the first batch.

- .lazy:

  Use `TRUE` to evaluate `FUN` lazily as batches are read from the
  result; use `FALSE` to evaluate `FUN` on all batches before returning
  the reader.

- .data.frame:

  Deprecated argument, ignored

## Value

An `arrow_dplyr_query`.

## Details

This is experimental and not recommended for production use. It is also
single-threaded and runs in R not C++, so it won't be as fast as core
Arrow methods.
