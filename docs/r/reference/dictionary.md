# Create a dictionary type

Create a dictionary type

## Usage

``` r
dictionary(index_type = int32(), value_type = utf8(), ordered = FALSE)
```

## Arguments

- index_type:

  A DataType for the indices (default
  [`int32()`](https://arrow.apache.org/docs/r/reference/data-type.md))

- value_type:

  A DataType for the values (default
  [`utf8()`](https://arrow.apache.org/docs/r/reference/data-type.md))

- ordered:

  Is this an ordered dictionary (default `FALSE`)?

## Value

A
[DictionaryType](https://arrow.apache.org/docs/r/reference/DictionaryType.md)

## See also

[Other Arrow data
types](https://arrow.apache.org/docs/r/reference/data-type.md)
