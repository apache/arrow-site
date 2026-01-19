<div id="main" class="col-md-9" role="main">

# Create an Arrow Scalar

<div class="ref-description section level2">

Create an Arrow Scalar

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
scalar(x, type = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    An R vector, list, or `data.frame`

-   type:

    An optional [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    `x`. If omitted, the type will be inferred from the data.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
scalar(pi)
#> Scalar
#> 3.141592653589793
scalar(404)
#> Scalar
#> 404
# If you pass a vector into scalar(), you get a list containing your items
scalar(c(1, 2, 3))
#> Scalar
#> list<item: double>[1, 2, 3]

scalar(9) == scalar(10)
#> Scalar
#> false
```

</div>

</div>

</div>
