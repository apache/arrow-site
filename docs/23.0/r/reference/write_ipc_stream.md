# Write Arrow IPC stream format

Apache Arrow defines two formats for [serializing data for interprocess
communication
(IPC)](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc):
a "stream" format and a "file" format, known as Feather.
`write_ipc_stream()` and
[`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
write those formats, respectively.

## Usage

``` r
write_ipc_stream(x, sink, ...)
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

- ...:

  extra parameters passed to
  [`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md).

## Value

`x`, invisibly.

## See also

[`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
for writing IPC files.
[`write_to_raw()`](https://arrow.apache.org/docs/r/reference/write_to_raw.md)
to serialize data to a buffer.
[RecordBatchWriter](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
for a lower-level interface.

## Examples

``` r
tf <- tempfile()
on.exit(unlink(tf))
write_ipc_stream(mtcars, tf)
```
