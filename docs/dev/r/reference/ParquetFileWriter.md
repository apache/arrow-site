<div id="main" class="col-md-9" role="main">

# ParquetFileWriter class

<div class="ref-description section level2">

This class enables you to interact with Parquet files.

</div>

<div class="section level2">

## Factory

The `ParquetFileWriter$create()` factory method instantiates the object
and takes the following arguments:

-   `schema` A
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)

-   `sink` An
    [arrow::io::OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md)

-   `properties` An instance of
    [ParquetWriterProperties](https://arrow.apache.org/docs/r/reference/ParquetWriterProperties.md)

-   `arrow_properties` An instance of `ParquetArrowWriterProperties`

</div>

<div class="section level2">

## Methods

-   `WriteTable` Write a
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md) to
    `sink`

-   `WriteBatch` Write a
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
    to `sink`

-   `Close` Close the writer. Note: does not close the `sink`.
    [arrow::io::OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md)
    has its own `close()` method.

</div>

</div>
