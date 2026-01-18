<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow RecordBatch

<div class="ref-description section level2">

Whereas `record_batch()` constructs a
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
from one or more columns, `as_record_batch()` converts a single object
to an Arrow
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

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

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to an Arrow RecordBatch

-   ...:

    Passed to S3 methods

-   schema:

    a
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md),
    or `NULL` (the default) to infer the schema from the data in `...`.
    When providing an Arrow IPC buffer, `schema` is required.

</div>

<div class="section level2">

## Value

A
[RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

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

</div>

</div>

</div>
