# Convert an object to an Arrow DataType

Convert an object to an Arrow DataType

## Usage

``` r
as_data_type(x, ...)

# S3 method for class 'DataType'
as_data_type(x, ...)

# S3 method for class 'Field'
as_data_type(x, ...)

# S3 method for class 'Schema'
as_data_type(x, ...)
```

## Arguments

- x:

  An object to convert to an Arrow
  [DataType](https://arrow.apache.org/docs/r/reference/data-type.md)

- ...:

  Passed to S3 methods.

## Value

A [DataType](https://arrow.apache.org/docs/r/reference/data-type.md)
object.

## Examples

``` r
as_data_type(int32())
#> Int32
#> int32
```
