# Concatenate zero or more Arrays

Concatenates zero or more
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)
objects into a single array. This operation will make a copy of its
input; if you need the behavior of a single Array but don't need a
single object, use
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

## Usage

``` r
concat_arrays(..., type = NULL)

# S3 method for class 'Array'
c(...)
```

## Arguments

- ...:

  zero or more
  [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
  objects to concatenate

- type:

  An optional `type` describing the desired type for the final Array.

## Value

A single
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)

## Examples

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
