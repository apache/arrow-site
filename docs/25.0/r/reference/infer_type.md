# Infer the arrow Array type from an R object

`type()` is deprecated in favor of `infer_type()`.

## Usage

``` r
infer_type(x, ...)

type(x)
```

## Arguments

- x:

  an R object (usually a vector) to be converted to an
  [Array](https://arrow.apache.org/docs/r/reference/array-class.md) or
  [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).

- ...:

  Passed to S3 methods

## Value

An arrow [data
type](https://arrow.apache.org/docs/r/reference/data-type.md)

## Examples

``` r
infer_type(1:10)
#> Int32
#> int32
infer_type(1L:10L)
#> Int32
#> int32
infer_type(c(1, 1.5, 2))
#> Float64
#> double
infer_type(c("A", "B", "C"))
#> Utf8
#> string
infer_type(mtcars)
#> StructType
#> struct<mpg: double, cyl: double, disp: double, hp: double, drat: double, wt: double, qsec: double, vs: double, am: double, gear: double, carb: double>
infer_type(Sys.Date())
#> Date32
#> date32[day]
infer_type(as.POSIXlt(Sys.Date()))
#> VctrsExtensionType
#> POSIXlt of length 0
infer_type(vctrs::new_vctr(1:5, class = "my_custom_vctr_class"))
#> VctrsExtensionType
#> <my_custom_vctr_class[0]>
```
