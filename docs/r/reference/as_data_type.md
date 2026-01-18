<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow DataType

<div class="ref-description section level2">

Convert an object to an Arrow DataType

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
as_data_type(x, ...)

# S3 method for class 'DataType'
as_data_type(x, ...)

# S3 method for class 'Field'
as_data_type(x, ...)

# S3 method for class 'Schema'
as_data_type(x, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to an Arrow
    [DataType](https://arrow.apache.org/docs/r/reference/data-type.md)

-   ...:

    Passed to S3 methods.

</div>

<div class="section level2">

## Value

A [DataType](https://arrow.apache.org/docs/r/reference/data-type.md)
object.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
as_data_type(int32())
#> Int32
#> int32
```

</div>

</div>

</div>
