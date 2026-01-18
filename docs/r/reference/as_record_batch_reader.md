<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow RecordBatchReader

<div class="ref-description section level2">

Convert an object to an Arrow RecordBatchReader

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

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

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to a
    [RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)

-   ...:

    Passed to S3 methods

-   schema:

    The `schema()` that must match the schema returned by each call to
    `x` when `x` is a function.

</div>

<div class="section level2">

## Value

A
[RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

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

</div>

</div>

</div>
