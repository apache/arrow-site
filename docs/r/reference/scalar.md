# Create an Arrow Scalar

Create an Arrow Scalar

## Usage

``` r
scalar(x, type = NULL)
```

## Arguments

- x:

  An R vector, list, or `data.frame`

- type:

  An optional [data
  type](https://arrow.apache.org/docs/r/reference/data-type.md) for `x`.
  If omitted, the type will be inferred from the data.

## Examples

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
