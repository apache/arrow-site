<div id="main" class="col-md-9" role="main">

# Value matching for Arrow objects

<div class="ref-description section level2">

`base::match()` and `base::%in%` are not generics, so we can't just
define Arrow methods for them. These functions expose the analogous
functions in the Arrow C++ library.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
match_arrow(x, table, ...)

is_in(x, table, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    `Scalar`, `Array` or `ChunkedArray`

-   table:

    `Scalar`, Array`, `ChunkedArray\`, or R vector lookup table.

-   ...:

    additional arguments, ignored

</div>

<div class="section level2">

## Value

`match_arrow()` returns an `int32`-type Arrow object of the same length
and type as `x` with the (0-based) indexes into `table`. `is_in()`
returns a `boolean`-type Arrow object of the same length and type as `x`
with values indicating per element of `x` it it is present in `table`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# note that the returned value is 0-indexed
cars_tbl <- arrow_table(name = rownames(mtcars), mtcars)
match_arrow(Scalar$create("Mazda RX4 Wag"), cars_tbl$name)
#> Scalar
#> 1

is_in(Array$create("Mazda RX4 Wag"), cars_tbl$name)
#> Array
#> <bool>
#> [
#>   true
#> ]

# Although there are multiple matches, you are returned the index of the first
# match, as with the base R equivalent
match(4, mtcars$cyl) # 1-indexed
#> [1] 3
match_arrow(Scalar$create(4), cars_tbl$cyl) # 0-indexed
#> Scalar
#> 2

# If `x` contains multiple values, you are returned the indices of the first
# match for each value.
match(c(4, 6, 8), mtcars$cyl)
#> [1] 3 1 5
match_arrow(Array$create(c(4, 6, 8)), cars_tbl$cyl)
#> Array
#> <int32>
#> [
#>   2,
#>   0,
#>   4
#> ]

# Return type matches type of `x`
is_in(c(4, 6, 8), mtcars$cyl) # returns vector
#> Array
#> <bool>
#> [
#>   true,
#>   true,
#>   true
#> ]
is_in(Scalar$create(4), mtcars$cyl) # returns Scalar
#> Scalar
#> true
is_in(Array$create(c(4, 6, 8)), cars_tbl$cyl) # returns Array
#> Array
#> <bool>
#> [
#>   true,
#>   true,
#>   true
#> ]
is_in(ChunkedArray$create(c(4, 6), 8), cars_tbl$cyl) # returns ChunkedArray
#> ChunkedArray
#> <bool>
#> [
#>   [
#>     true,
#>     true,
#>     true
#>   ]
#> ]
```

</div>

</div>

</div>
