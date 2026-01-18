<div id="main" class="col-md-9" role="main">

# Write Arrow IPC stream format

<div class="ref-description section level2">

Apache Arrow defines two formats for [serializing data for interprocess
communication
(IPC)](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc):
a "stream" format and a "file" format, known as Feather.
`write_ipc_stream()` and `write_feather()` write those formats,
respectively.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_ipc_stream(x, sink, ...)
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

-   ...:

    extra parameters passed to `write_feather()`.

</div>

<div class="section level2">

## Value

`x`, invisibly.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`write_feather()` for writing IPC files. `write_to_raw()` to serialize
data to a buffer.
[RecordBatchWriter](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
for a lower-level interface.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))
write_ipc_stream(mtcars, tf)
```

</div>

</div>

</div>
