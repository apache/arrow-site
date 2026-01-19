<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow Array

<div class="ref-description section level2">

The `as_arrow_array()` function is identical to `Array$create()` except
that it is an S3 generic, which allows methods to be defined in other
packages to convert objects to
[Array](https://arrow.apache.org/docs/r/reference/array-class.md).
`Array$create()` is slightly faster because it tries to convert in C++
before falling back on `as_arrow_array()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'Array'
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'Scalar'
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'ChunkedArray'
as_arrow_array(x, ..., type = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to an Arrow Array

-   ...:

    Passed to S3 methods

-   type:

    A [type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    the final Array. A value of `NULL` will default to the type guessed
    by `infer_type()`.

</div>

<div class="section level2">

## Value

An [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
with type `type`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
as_arrow_array(1:5)
#> Array
#> <int32>
#> [
#>   1,
#>   2,
#>   3,
#>   4,
#>   5
#> ]
```

</div>

</div>

</div>
