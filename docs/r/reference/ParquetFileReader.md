<div id="main" class="col-md-9" role="main">

# ParquetFileReader class

<div class="ref-description section level2">

This class enables you to interact with Parquet files.

</div>

<div class="section level2">

## Factory

The `ParquetFileReader$create()` factory method instantiates the object
and takes the following arguments:

-   `file` A character file name, raw vector, or Arrow file connection
    object (e.g. `RandomAccessFile`).

-   `props` Optional
    [ParquetArrowReaderProperties](https://arrow.apache.org/docs/r/reference/ParquetArrowReaderProperties.md)

-   `mmap` Logical: whether to memory-map the file (default `TRUE`)

-   `reader_props` Optional
    [ParquetReaderProperties](https://arrow.apache.org/docs/r/reference/ParquetReaderProperties.md)

-   `...` Additional arguments, currently ignored

</div>

<div class="section level2">

## Methods

-   `$ReadTable(column_indices)`: get an `arrow::Table` from the file.
    The optional `column_indices=` argument is a 0-based integer vector
    indicating which columns to retain.

-   `$ReadRowGroup(i, column_indices)`: get an `arrow::Table` by reading
    the `i`th row group (0-based). The optional `column_indices=`
    argument is a 0-based integer vector indicating which columns to
    retain.

-   `$ReadRowGroups(row_groups, column_indices)`: get an `arrow::Table`
    by reading several row groups (0-based integers). The optional
    `column_indices=` argument is a 0-based integer vector indicating
    which columns to retain.

-   `$GetSchema()`: get the `arrow::Schema` of the data in the file

-   `$ReadColumn(i)`: read the `i`th column (0-based) as a
    [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

</div>

<div class="section level2">

## Active bindings

-   `$num_rows`: number of rows.

-   `$num_columns`: number of columns.

-   `$num_row_groups`: number of row groups.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
f <- system.file("v0.7.1.parquet", package = "arrow")
pq <- ParquetFileReader$create(f)
pq$GetSchema()
#> Schema
#> carat: double
#> cut: string
#> color: string
#> clarity: string
#> depth: double
#> table: double
#> price: int64
#> x: double
#> y: double
#> z: double
#> __index_level_0__: int64
#> 
#> See $metadata for additional Schema metadata
if (codec_is_available("snappy")) {
  # This file has compressed data columns
  tab <- pq$ReadTable()
  tab$schema
}
#> Schema
#> carat: double
#> cut: string
#> color: string
#> clarity: string
#> depth: double
#> table: double
#> price: int64
#> x: double
#> y: double
#> z: double
#> __index_level_0__: int64
#> 
#> See $metadata for additional Schema metadata
```

</div>

</div>

</div>
