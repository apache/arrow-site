# Convert an object to an Arrow Schema

Convert an object to an Arrow Schema

## Usage

``` r
as_schema(x, ...)

# S3 method for class 'Schema'
as_schema(x, ...)

# S3 method for class 'StructType'
as_schema(x, ...)
```

## Arguments

- x:

  An object to convert to a
  [`schema()`](https://arrow.apache.org/docs/r/reference/schema.md)

- ...:

  Passed to S3 methods.

## Value

A [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
object.

## Examples

``` r
as_schema(schema(col1 = int32()))
#> Schema
#> col1: int32
```
