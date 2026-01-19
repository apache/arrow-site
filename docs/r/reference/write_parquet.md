<div id="main" class="col-md-9" role="main">

# Write Parquet file to disk

<div class="ref-description section level2">

[Parquet](https://parquet.apache.org/) is a columnar storage file
format. This function enables you to write Parquet files from R.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_parquet(
  x,
  sink,
  chunk_size = NULL,
  version = "2.4",
  compression = default_parquet_compression(),
  compression_level = NULL,
  use_dictionary = NULL,
  write_statistics = NULL,
  data_page_size = NULL,
  use_deprecated_int96_timestamps = FALSE,
  coerce_timestamps = NULL,
  allow_truncated_timestamps = FALSE
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

-   chunk_size:

    how many rows of data to write to disk at once. This directly
    corresponds to how many rows will be in each row group in parquet.
    If `NULL`, a best guess will be made for optimal size (based on the
    number of columns and number of rows), though if the data has fewer
    than 250 million cells (rows x cols), then the total number of rows
    is used.

-   version:

    parquet version: "1.0", "2.4" (default), "2.6", or "latest"
    (currently equivalent to 2.6). Numeric values are coerced to
    character.

-   compression:

    compression algorithm. Default "snappy". See details.

-   compression_level:

    compression level. Meaning depends on compression algorithm

-   use_dictionary:

    logical: use dictionary encoding? Default `TRUE`

-   write_statistics:

    logical: include statistics? Default `TRUE`

-   data_page_size:

    Set a target threshold for the approximate encoded size of data
    pages within a column chunk (in bytes). Default 1 MiB.

-   use_deprecated_int96_timestamps:

    logical: write timestamps to INT96 Parquet format, which has been
    deprecated? Default `FALSE`.

-   coerce_timestamps:

    Cast timestamps a particular resolution. Can be `NULL`, "ms" or
    "us". Default `NULL` (no casting)

-   allow_truncated_timestamps:

    logical: Allow loss of data when coercing timestamps to a particular
    resolution. E.g. if microsecond or nanosecond data is lost when
    coercing to "ms", do not raise an exception. Default `FALSE`.

</div>

<div class="section level2">

## Value

the input `x` invisibly.

</div>

<div class="section level2">

## Details

Due to features of the format, Parquet files cannot be appended to. If
you want to use the Parquet format but also want the ability to extend
your dataset, you can write to additional Parquet files and then treat
the whole directory of files as a
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md) you can
query. See the [dataset
article](https://arrow.apache.org/docs/r/articles/dataset.html) for
examples of this.

The parameters `compression`, `compression_level`, `use_dictionary` and
`write_statistics` support various patterns:

-   The default `NULL` leaves the parameter unspecified, and the C++
    library uses an appropriate default for each column (defaults listed
    above)

-   A single, unnamed, value (e.g. a single string for `compression`)
    applies to all columns

-   An unnamed vector, of the same size as the number of columns, to
    specify a value for each column, in positional order

-   A named vector, to specify the value for the named columns, the
    default value for the setting is used when not supplied

The `compression` argument can be any of the following
(case-insensitive): "uncompressed", "snappy", "gzip", "brotli", "zstd",
"lz4", "lzo" or "bz2". Only "uncompressed" is guaranteed to be
available, but "snappy" and "gzip" are almost always included. See
`codec_is_available()`. The default "snappy" is used if available,
otherwise "uncompressed". To disable compression, set
`compression = "uncompressed"`. Note that "uncompressed" columns may
still have dictionary encoding.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[ParquetFileWriter](https://arrow.apache.org/docs/r/reference/ParquetFileWriter.md)
for a lower-level interface to Parquet writing.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf1 <- tempfile(fileext = ".parquet")
write_parquet(data.frame(x = 1:5), tf1)

# using compression
if (codec_is_available("gzip")) {
  tf2 <- tempfile(fileext = ".gz.parquet")
  write_parquet(data.frame(x = 1:5), tf2, compression = "gzip", compression_level = 5)
}
```

</div>

</div>

</div>
