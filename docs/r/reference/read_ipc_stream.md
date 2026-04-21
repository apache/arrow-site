# Read Arrow IPC stream format

Apache Arrow defines two formats for [serializing data for interprocess
communication
(IPC)](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc):
a "stream" format and a "file" format, known as Feather.
`read_ipc_stream()` and
[`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md)
read those formats, respectively.

## Usage

``` r
read_ipc_stream(file, as_data_frame = TRUE, ...)
```

## Arguments

- file:

  A character file name or URI, connection, `raw` vector, an Arrow input
  stream, or a `FileSystem` with path (`SubTreeFileSystem`). If a file
  name or URI, an Arrow
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
  will be opened and closed when finished. If an input stream is
  provided, it will be left open.

- as_data_frame:

  Should the function return a `tibble` (default) or an Arrow
  [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)?

- ...:

  extra parameters passed to
  [`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md).

## Value

A `tibble` if `as_data_frame` is `TRUE` (the default), or an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
otherwise

## Untrusted data

If reading from an untrusted source, you can validate the data by
reading with `as_data_frame = FALSE` and calling `$ValidateFull()` on
the Table before processing.

## See also

[`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
for writing IPC files.
[RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
for a lower-level interface.
