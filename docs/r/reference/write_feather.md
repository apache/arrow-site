# Write a Feather file (deprecated)

`write_feather()` is deprecated and will be removed in a future release.
Use
[`write_ipc_file()`](https://arrow.apache.org/docs/r/reference/write_ipc_file.md)
instead.

Column-oriented file format designed for fast reading and writing of
data frames. Feather V2 is the Arrow IPC file format. Feather V1 is a
legacy format available starting in 2016 that lacks many features, such
as the ability to store all Arrow data types, and compression support.
Feather V1 is deprecated; use
[`write_ipc_file()`](https://arrow.apache.org/docs/r/reference/write_ipc_file.md)
for new files.

## Usage

``` r
write_feather(
  x,
  sink,
  version = 2,
  chunk_size = 65536L,
  compression = c("default", "lz4", "lz4_frame", "uncompressed", "zstd"),
  compression_level = NULL
)
```

## Arguments

- x:

  `data.frame`,
  [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
  or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

- sink:

  A string file path, connection, URI, or
  [OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
  or path in a file system (`SubTreeFileSystem`)

- version:

  integer Feather file version, Version 1 or Version 2. Version 2 is the
  default.

- chunk_size:

  The number of rows that each chunk of data should have in the file.
  Use a smaller `chunk_size` when you need faster random row access.
  Default is 64K.

- compression:

  Name of compression codec to use, if any. Default is "lz4" if LZ4 is
  available in your build of the Arrow C++ library, otherwise
  "uncompressed". "zstd" is the other available codec and generally has
  better compression ratios in exchange for slower read and write
  performance. "lz4" is shorthand for the "lz4_frame" codec. See
  [`codec_is_available()`](https://arrow.apache.org/docs/r/reference/codec_is_available.md)
  for details. `TRUE` and `FALSE` can also be used in place of "default"
  and "uncompressed".

- compression_level:

  If `compression` is "zstd", you may specify an integer compression
  level. If omitted, the compression codec's default compression level
  is used.

## Value

The input `x`, invisibly. Note that if `sink` is an
[OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
the stream will be left open.

## See also

[`write_ipc_file()`](https://arrow.apache.org/docs/r/reference/write_ipc_file.md)
