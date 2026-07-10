# Write Arrow data to a raw vector

[`write_ipc_stream()`](https://arrow.apache.org/docs/r/reference/write_ipc_stream.md)
and
[`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
write data to a sink and return the data (`data.frame`, `RecordBatch`,
or `Table`) they were given. This function wraps those so that you can
serialize data to a buffer and access that buffer as a `raw` vector in
R.

## Usage

``` r
write_to_raw(x, format = c("stream", "file"))
```

## Arguments

- x:

  `data.frame`,
  [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
  or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

- format:

  one of `c("stream", "file")`, indicating the IPC format to use

## Value

A `raw` vector containing the bytes of the IPC serialized data.

## Examples

``` r
# The default format is "stream"
mtcars_raw <- write_to_raw(mtcars)
```
