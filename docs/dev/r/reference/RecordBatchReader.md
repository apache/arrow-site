<div id="main" class="col-md-9" role="main">

# RecordBatchReader classes

<div class="ref-description section level2">

Apache Arrow defines two formats for [serializing data for interprocess
communication
(IPC)](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc):
a "stream" format and a "file" format, known as Feather.
`RecordBatchStreamReader` and `RecordBatchFileReader` are interfaces for
accessing record batches from input sources in those formats,
respectively.

For guidance on how to use these classes, see the examples section.

</div>

<div class="section level2">

## Factory

The `RecordBatchFileReader$create()` and
`RecordBatchStreamReader$create()` factory methods instantiate the
object and take a single argument, named according to the class:

-   `file` A character file name, raw vector, or Arrow file connection
    object (e.g.
    [RandomAccessFile](https://arrow.apache.org/docs/r/reference/InputStream.md)).

-   `stream` A raw vector,
    [Buffer](https://arrow.apache.org/docs/r/reference/Buffer-class.md),
    or
    [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md).

</div>

<div class="section level2">

## Methods

-   `$read_next_batch()`: Returns a `RecordBatch`, iterating through the
    Reader. If there are no further batches in the Reader, it returns
    `NULL`.

-   `$schema`: Returns a
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
    (active binding)

-   `$batches()`: Returns a list of `RecordBatch`es

-   `$read_table()`: Collects the reader's `RecordBatch`es into a
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

-   `$get_batch(i)`: For `RecordBatchFileReader`, return a particular
    batch by an integer index.

-   `$num_record_batches()`: For `RecordBatchFileReader`, see how many
    batches are in the file.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`read_ipc_stream()` and `read_feather()` provide a much simpler
interface for reading data from these formats and are sufficient for
many use cases.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))

batch <- record_batch(chickwts)

# This opens a connection to the file in Arrow
file_obj <- FileOutputStream$create(tf)
# Pass that to a RecordBatchWriter to write data conforming to a schema
writer <- RecordBatchFileWriter$create(file_obj, batch$schema)
writer$write(batch)
# You may write additional batches to the stream, provided that they have
# the same schema.
# Call "close" on the writer to indicate end-of-file/stream
writer$close()
# Then, close the connection--closing the IPC message does not close the file
file_obj$close()

# Now, we have a file we can read from. Same pattern: open file connection,
# then pass it to a RecordBatchReader
read_file_obj <- ReadableFile$create(tf)
reader <- RecordBatchFileReader$create(read_file_obj)
# RecordBatchFileReader knows how many batches it has (StreamReader does not)
reader$num_record_batches
#> [1] 1
# We could consume the Reader by calling $read_next_batch() until all are,
# consumed, or we can call $read_table() to pull them all into a Table
tab <- reader$read_table()
# Call as.data.frame to turn that Table into an R data.frame
df <- as.data.frame(tab)
# This should be the same data we sent
all.equal(df, chickwts, check.attributes = FALSE)
#> [1] TRUE
# Unlike the Writers, we don't have to close RecordBatchReaders,
# but we do still need to close the file connection
read_file_obj$close()
```

</div>

</div>

</div>
