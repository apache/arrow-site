# Convert an object to an Arrow Table

Whereas
[`arrow_table()`](https://arrow.apache.org/docs/r/reference/table.md)
constructs a table from one or more columns, `as_arrow_table()` converts
a single object to an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md).

## Usage

``` r
as_arrow_table(x, ..., schema = NULL)

# Default S3 method
as_arrow_table(x, ...)

# S3 method for class 'Table'
as_arrow_table(x, ..., schema = NULL)

# S3 method for class 'RecordBatch'
as_arrow_table(x, ..., schema = NULL)

# S3 method for class 'data.frame'
as_arrow_table(x, ..., schema = NULL)

# S3 method for class 'RecordBatchReader'
as_arrow_table(x, ...)

# S3 method for class 'Dataset'
as_arrow_table(x, ...)

# S3 method for class 'arrow_dplyr_query'
as_arrow_table(x, ...)

# S3 method for class 'Schema'
as_arrow_table(x, ...)
```

## Arguments

- x:

  An object to convert to an Arrow Table

- ...:

  Passed to S3 methods

- schema:

  a [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md),
  or `NULL` (the default) to infer the schema from the data in `...`.
  When providing an Arrow IPC buffer, `schema` is required.

## Value

A [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

## Examples

``` r
# use as_arrow_table() for a single object
as_arrow_table(data.frame(col1 = 1, col2 = "two"))
#> Table
#> 1 rows x 2 columns
#> $col1 <double>
#> $col2 <string>
#> 
#> See $metadata for additional Schema metadata

# use arrow_table() to create from columns
arrow_table(col1 = 1, col2 = "two")
#> Table
#> 1 rows x 2 columns
#> $col1 <double>
#> $col2 <string>
```
