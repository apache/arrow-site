# Call an Arrow compute function

This function provides a lower-level API for calling Arrow functions by
their string function name. You won't use it directly for most
applications. Many Arrow compute functions are mapped to R methods, and
in a `dplyr` evaluation context, [all Arrow
functions](https://arrow.apache.org/docs/r/reference/list_compute_functions.md)
are callable with an `arrow_` prefix.

## Usage

``` r
call_function(
  function_name,
  ...,
  args = list(...),
  options = empty_named_list()
)
```

## Arguments

- function_name:

  string Arrow compute function name

- ...:

  Function arguments, which may include `Array`, `ChunkedArray`,
  `Scalar`, `RecordBatch`, or `Table`.

- args:

  list arguments as an alternative to specifying in `...`

- options:

  named list of C++ function options.

## Value

An `Array`, `ChunkedArray`, `Scalar`, `RecordBatch`, or `Table`,
whatever the compute function results in.

## Details

When passing indices in `...`, `args`, or `options`, express them as
0-based integers (consistent with C++).

## See also

[Arrow C++
documentation](https://arrow.apache.org/docs/cpp/compute.html) for the
functions and their respective options.

## Examples

``` r
a <- Array$create(c(1L, 2L, 3L, NA, 5L))
s <- Scalar$create(4L)
call_function("coalesce", a, s)
#> Array
#> <int32>
#> [
#>   1,
#>   2,
#>   3,
#>   4,
#>   5
#> ]

a <- Array$create(rnorm(10000))
call_function("quantile", a, options = list(q = seq(0, 1, 0.25)))
#> Array
#> <double>
#> [
#>   -3.3041822296584606,
#>   -0.6772029597996343,
#>   0.0014695935200537034,
#>   0.6759598650974947,
#>   3.5889486327287328
#> ]
```
