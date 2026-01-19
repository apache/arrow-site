<div id="main" class="col-md-9" role="main">

# Create an Arrow Array

<div class="ref-description section level2">

Create an Arrow Array

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
arrow_array(x, type = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An R object representable as an Arrow array, e.g. a vector, list, or
    `data.frame`.

-   type:

    An optional [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    `x`. If omitted, the type will be inferred from the data.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
my_array <- arrow_array(1:10)

# Compare 2 arrays
na_array <- arrow_array(c(1:5, NA))
na_array2 <- na_array
na_array2 == na_array # element-wise comparison
#> Array
#> <bool>
#> [
#>   true,
#>   true,
#>   true,
#>   true,
#>   true,
#>   null
#> ]
```

</div>

</div>

</div>
