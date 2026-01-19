<div id="main" class="col-md-9" role="main">

# Write CSV file to disk

<div class="ref-description section level2">

Write CSV file to disk

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_csv_arrow(
  x,
  sink,
  file = NULL,
  include_header = TRUE,
  col_names = NULL,
  batch_size = 1024L,
  na = "",
  write_options = NULL,
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    `data.frame`,
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
    or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

-   sink:

    A string file path, connection, URI, or
    [OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
    or path in a file system (`SubTreeFileSystem`)

-   file:

    file name. Specify this or `sink`, not both.

-   include_header:

    Whether to write an initial header line with column names

-   col_names:

    identical to `include_header`. Specify this or `include_headers`,
    not both.

-   batch_size:

    Maximum number of rows processed at a time. Default is 1024.

-   na:

    value to write for NA values. Must not contain quote marks. Default
    is `""`.

-   write_options:

    see [CSV write
    options](https://arrow.apache.org/docs/r/reference/csv_write_options.md)

-   ...:

    additional parameters

</div>

<div class="section level2">

## Value

The input `x`, invisibly. Note that if `sink` is an
[OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
the stream will be left open.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))
write_csv_arrow(mtcars, tf)
```

</div>

</div>

</div>
