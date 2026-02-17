# Create a Field

Create a Field

## Usage

``` r
field(name, type, metadata, nullable = TRUE)
```

## Arguments

- name:

  field name

- type:

  logical type, instance of
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)

- metadata:

  currently ignored

- nullable:

  TRUE if field is nullable

## See also

[Field](https://arrow.apache.org/docs/r/reference/Field-class.md)

## Examples

``` r
field("x", int32())
#> Field
#> x: int32
```
