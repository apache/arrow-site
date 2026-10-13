# Field class

[`field()`](https://arrow.apache.org/docs/r/reference/Field.md) lets you
create an `arrow::Field` that maps a
[DataType](https://arrow.apache.org/docs/r/reference/data-type.md) to a
column name. Fields are contained in
[Schemas](https://arrow.apache.org/docs/r/reference/Schema-class.md).

## Methods

- `f$ToString()`: convert to a string

- `f$Equals(other, check_metadata = FALSE)`: test for equality. More
  naturally called as `f == other`

- `f$WithMetadata(metadata)`: returns a new `Field` with the key-value
  `metadata` set. Note that all list elements in `metadata` will be
  coerced to `character`.

- `f$RemoveMetadata()`: returns a new `Field` without metadata.

## Active bindings

- `$HasMetadata`: logical: does this `Field` have extra metadata?

- `$metadata`: returns the key-value metadata as a named list, or `NULL`
  if no metadata is set.
