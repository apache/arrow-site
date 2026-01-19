<div id="main" class="col-md-9" role="main">

# Write a Feather file (an Arrow IPC file)

<div class="ref-description section level2">

Feather provides binary columnar serialization for data frames. It is
designed to make reading and writing data frames efficient, and to make
sharing data across data analysis languages easy. `write_feather()` can
write both the Feather Version 1 (V1), a legacy version available
starting in 2016, and the Version 2 (V2), which is the Apache Arrow IPC
file format. The default version is V2. V1 files are distinct from Arrow
IPC files and lack many features, such as the ability to store all Arrow
data tyeps, and compression support. `write_ipc_file()` can only write
V2 files.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_feather(
  x,
  sink,
  version = 2,
  chunk_size = 65536L,
  compression = c("default", "lz4", "lz4_frame", "uncompressed", "zstd"),
  compression_level = NULL
)

write_ipc_file(
  x,
  sink,
  chunk_size = 65536L,
  compression = c("default", "lz4", "lz4_frame", "uncompressed", "zstd"),
  compression_level = NULL
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

-   version:

    integer Feather file version, Version 1 or Version 2. Version 2 is
    the default.

-   chunk_size:

    For V2 files, the number of rows that each chunk of data should have
    in the file. Use a smaller `chunk_size` when you need faster random
    row access. Default is 64K. This option is not supported for V1.

-   compression:

    Name of compression codec to use, if any. Default is "lz4" if LZ4 is
    available in your build of the Arrow C++ library, otherwise
    "uncompressed". "zstd" is the other available codec and generally
    has better compression ratios in exchange for slower read and write
    performance. "lz4" is shorthand for the "lz4_frame" codec. See
    `codec_is_available()` for details. `TRUE` and `FALSE` can also be
    used in place of "default" and "uncompressed". This option is not
    supported for V1.

-   compression_level:

    If `compression` is "zstd", you may specify an integer compression
    level. If omitted, the compression codec's default compression level
    is used.

</div>

<div class="section level2">

## Value

The input `x`, invisibly. Note that if `sink` is an
[OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
the stream will be left open.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[RecordBatchWriter](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
for lower-level access to writing Arrow IPC data.

[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md) for
information about schemas and metadata handling.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# We recommend the ".arrow" extension for Arrow IPC files (Feather V2).
tf1 <- tempfile(fileext = ".feather")
tf2 <- tempfile(fileext = ".arrow")
tf3 <- tempfile(fileext = ".arrow")
on.exit({
  unlink(tf1)
  unlink(tf2)
  unlink(tf3)
})
write_feather(mtcars, tf1, version = 1)
write_feather(mtcars, tf2)
write_ipc_file(mtcars, tf3)
```

</div>

</div>

</div>
