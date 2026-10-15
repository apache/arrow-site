# ParquetArrowReaderProperties class

This class holds settings to control how a Parquet file is read by
[ParquetFileReader](https://arrow.apache.org/docs/r/reference/ParquetFileReader.md).

## Factory

The `ParquetArrowReaderProperties$create()` factory method instantiates
the object and takes the following arguments:

- `use_threads` Logical: whether to use multithreading (default `TRUE`)

## Methods

- `$read_dictionary(column_index)`

- `$set_read_dictionary(column_index, read_dict)`

- `$use_threads(use_threads)`
