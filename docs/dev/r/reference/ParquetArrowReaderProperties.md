<div id="main" class="col-md-9" role="main">

# ParquetArrowReaderProperties class

<div class="ref-description section level2">

This class holds settings to control how a Parquet file is read by
[ParquetFileReader](https://arrow.apache.org/docs/r/reference/ParquetFileReader.md).

</div>

<div class="section level2">

## Factory

The `ParquetArrowReaderProperties$create()` factory method instantiates
the object and takes the following arguments:

-   `use_threads` Logical: whether to use multithreading (default
    `TRUE`)

</div>

<div class="section level2">

## Methods

-   `$read_dictionary(column_index)`

-   `$set_read_dictionary(column_index, read_dict)`

-   `$use_threads(use_threads)`

</div>

</div>
