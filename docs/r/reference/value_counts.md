# `table` for Arrow objects

This function tabulates the values in the array and returns a table of
counts.

## Usage

``` r
value_counts(x)
```

## Arguments

- x:

  `Array` or `ChunkedArray`

## Value

A `StructArray` containing "values" (same type as `x`) and "counts"
`Int64`.

## Examples

``` r
cyl_vals <- Array$create(mtcars$cyl)
counts <- value_counts(cyl_vals)
```
