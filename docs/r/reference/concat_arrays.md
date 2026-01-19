<div id="main" class="col-md-9" role="main">

# Concatenate zero or more Arrays

<div class="ref-description section level2">

Concatenates zero or more
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)
objects into a single array. This operation will make a copy of its
input; if you need the behavior of a single Array but don't need a
single object, use
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
concat_arrays(..., type = NULL)

# S3 method for class 'Array'
c(...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    zero or more
    [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
    objects to concatenate

-   type:

    An optional `type` describing the desired type for the final Array.

</div>

<div class="section level2">

## Value

A single
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
concat_arrays(Array$create(1:3), Array$create(4:5))
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
