# Create a Field

Create a Field

## Usage

``` r
field(name, type, metadata = NULL, nullable = TRUE)
```

## Arguments

- name:

  field name

- type:

  logical type, instance of
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)

- metadata:

  a named character vector or list to attach as field metadata. All
  values will be coerced to `character`.

- nullable:

  TRUE if field is nullable

## See also

[Field](https://arrow.apache.org/docs/r/reference/Field-class.md)

## Examples

``` r
field("x", int32())
#> Field
#> x: int32
field("x", int32(), metadata = list(key = "value"))
#> Field
#> x: int32
```
