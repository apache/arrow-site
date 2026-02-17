# Convert an object to an Arrow RecordBatchReader

Convert an object to an Arrow RecordBatchReader

## Usage

``` r
as_record_batch_reader(x, ...)

# S3 method for class 'RecordBatchReader'
as_record_batch_reader(x, ...)

# S3 method for class 'Table'
as_record_batch_reader(x, ...)

# S3 method for class 'RecordBatch'
as_record_batch_reader(x, ...)

# S3 method for class 'data.frame'
as_record_batch_reader(x, ...)

# S3 method for class 'Dataset'
as_record_batch_reader(x, ...)

# S3 method for class '`function`'
as_record_batch_reader(x, ..., schema)

# S3 method for class 'arrow_dplyr_query'
as_record_batch_reader(x, ...)

# S3 method for class 'Scanner'
as_record_batch_reader(x, ...)
```

## Arguments

- x:

  An object to convert to a
  [RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)

- ...:

  Passed to S3 methods

- schema:

  The [`schema()`](https://arrow.apache.org/docs/r/reference/schema.md)
  that must match the schema returned by each call to `x` when `x` is a
  function.

## Value

A
[RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)

## Examples

``` r
reader <- as_record_batch_reader(data.frame(col1 = 1, col2 = "two"))
reader$read_next_batch()
#> RecordBatch
#> 1 rows x 2 columns
#> $col1 <double>
#> $col2 <string>
#> 
#> See $metadata for additional Schema metadata
```
