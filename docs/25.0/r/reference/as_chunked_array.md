# Convert an object to an Arrow ChunkedArray

Whereas
[`chunked_array()`](https://arrow.apache.org/docs/r/reference/chunked_array.md)
constructs a
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
from zero or more
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)s or R
vectors, `as_chunked_array()` converts a single object to a
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

## Usage

``` r
as_chunked_array(x, ..., type = NULL)

# S3 method for class 'ChunkedArray'
as_chunked_array(x, ..., type = NULL)

# S3 method for class 'Array'
as_chunked_array(x, ..., type = NULL)
```

## Arguments

- x:

  An object to convert to an Arrow Chunked Array

- ...:

  Passed to S3 methods

- type:

  A [type](https://arrow.apache.org/docs/r/reference/data-type.md) for
  the final Array. A value of `NULL` will default to the type guessed by
  [`infer_type()`](https://arrow.apache.org/docs/r/reference/infer_type.md).

## Value

A
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

## Examples

``` r
as_chunked_array(1:5)
#> ChunkedArray
#> <int32>
#> [
#>   [
#>     1,
#>     2,
#>     3,
#>     4,
#>     5
#>   ]
#> ]
```
