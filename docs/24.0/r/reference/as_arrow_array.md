# Convert an object to an Arrow Array

The `as_arrow_array()` function is identical to `Array$create()` except
that it is an S3 generic, which allows methods to be defined in other
packages to convert objects to
[Array](https://arrow.apache.org/docs/r/reference/array-class.md).
`Array$create()` is slightly faster because it tries to convert in C++
before falling back on `as_arrow_array()`.

## Usage

``` r
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'Array'
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'Scalar'
as_arrow_array(x, ..., type = NULL)

# S3 method for class 'ChunkedArray'
as_arrow_array(x, ..., type = NULL)
```

## Arguments

- x:

  An object to convert to an Arrow Array

- ...:

  Passed to S3 methods

- type:

  A [type](https://arrow.apache.org/docs/r/reference/data-type.md) for
  the final Array. A value of `NULL` will default to the type guessed by
  [`infer_type()`](https://arrow.apache.org/docs/r/reference/infer_type.md).

## Value

An [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
with type `type`.

## Examples

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
