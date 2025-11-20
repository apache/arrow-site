<div id="main" class="col-md-9" role="main">

# `table` for Arrow objects

<div class="ref-description section level2">

This function tabulates the values in the array and returns a table of
counts.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
value_counts(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    `Array` or `ChunkedArray`

</div>

<div class="section level2">

## Value

A `StructArray` containing "values" (same type as `x`) and "counts"
`Int64`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
cyl_vals <- Array$create(mtcars$cyl)
counts <- value_counts(cyl_vals)
```

</div>

</div>

</div>
