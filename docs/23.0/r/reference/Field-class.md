# Field class

[`field()`](https://arrow.apache.org/docs/r/reference/Field.md) lets you
create an `arrow::Field` that maps a
[DataType](https://arrow.apache.org/docs/r/reference/data-type.md) to a
column name. Fields are contained in
[Schemas](https://arrow.apache.org/docs/r/reference/Schema-class.md).

## Methods

- `f$ToString()`: convert to a string

- `f$Equals(other)`: test for equality. More naturally called as
  `f == other`
