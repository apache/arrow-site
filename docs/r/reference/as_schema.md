<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow Schema

<div class="ref-description section level2">

Convert an object to an Arrow Schema

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
as_schema(x, ...)

# S3 method for class 'Schema'
as_schema(x, ...)

# S3 method for class 'StructType'
as_schema(x, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to a `schema()`

-   ...:

    Passed to S3 methods.

</div>

<div class="section level2">

## Value

A [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
object.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
as_schema(schema(col1 = int32()))
#> Schema
#> col1: int32
```

</div>

</div>

</div>
