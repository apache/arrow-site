<div id="main" class="col-md-9" role="main">

# Convert an object to an Arrow ChunkedArray

<div class="ref-description section level2">

Whereas `chunked_array()` constructs a
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
from zero or more
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)s or R
vectors, `as_chunked_array()` converts a single object to a
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
as_chunked_array(x, ..., type = NULL)

# S3 method for class 'ChunkedArray'
as_chunked_array(x, ..., type = NULL)

# S3 method for class 'Array'
as_chunked_array(x, ..., type = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An object to convert to an Arrow Chunked Array

-   ...:

    Passed to S3 methods

-   type:

    A [type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    the final Array. A value of `NULL` will default to the type guessed
    by `infer_type()`.

</div>

<div class="section level2">

## Value

A
[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

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

</div>

</div>

</div>
