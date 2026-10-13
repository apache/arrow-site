# DictionaryType class

`DictionaryType` is a
[FixedWidthType](https://arrow.apache.org/docs/r/reference/FixedWidthType.md)
that represents dictionary-encoded data. Dictionary encoding stores
unique values in a dictionary and uses integer-type indices to reference
them, which can be more memory-efficient for data with many repeated
values.

## R6 Methods

- `$ToString()`: Return a string representation of the dictionary type

- `$code(namespace = FALSE)`: Return R code to create this dictionary
  type

## Active bindings

- `$index_type`: The
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
  for the dictionary indices (must be an integer type, signed or
  unsigned)

- `$value_type`: The
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
  for the dictionary values

- `$name`: The name of the type.

- `$ordered`: Whether the dictionary is ordered.

## Factory

`DictionaryType$create()` takes the following arguments:

- `index_type`: A
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
  for the indices (default
  [`int32()`](https://arrow.apache.org/docs/r/reference/data-type.md))

- `value_type`: A
  [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
  for the values (default
  [`utf8()`](https://arrow.apache.org/docs/r/reference/data-type.md))

- `ordered`: Is this an ordered dictionary (default `FALSE`)?
