# Convert an object to an Arrow RecordBatch

Whereas
[`record_batch()`](https://arrow.apache.org/docs/r/reference/record_batch.md)
constructs a
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
from one or more columns, `as_record_batch()` converts a single object
to an Arrow
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md).

## Usage

``` r
as_record_batch(x, ..., schema = NULL)

# S3 method for class 'RecordBatch'
as_record_batch(x, ..., schema = NULL)

# S3 method for class 'Table'
as_record_batch(x, ..., schema = NULL)

# S3 method for class 'arrow_dplyr_query'
as_record_batch(x, ...)

# S3 method for class 'data.frame'
as_record_batch(x, ..., schema = NULL)
```

## Arguments

- x:

  An object to convert to an Arrow RecordBatch

- ...:

  Passed to S3 methods

- schema:

  a [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md),
  or `NULL` (the default) to infer the schema from the data in `...`.
  When providing an Arrow IPC buffer, `schema` is required.

## Value

A
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)

## Examples

``` r
# use as_record_batch() for a single object
as_record_batch(data.frame(col1 = 1, col2 = "two"))
#> RecordBatch
#> 1 rows x 2 columns
#> $col1 <double>
#> $col2 <string>
#> 
#> See $metadata for additional Schema metadata

# use record_batch() to create from columns
record_batch(col1 = 1, col2 = "two")
#> RecordBatch
#> 1 rows x 2 columns
#> $col1 <double>
#> $col2 <string>
```
