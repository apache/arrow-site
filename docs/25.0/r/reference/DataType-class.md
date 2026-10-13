# DataType class

DataType class

## R6 Methods

- `$ToString()`: String representation of the DataType

- `$Equals(other)`: Is the DataType equal to `other`

- `$fields()`: The children fields associated with this type

- `$code(namespace)`: Produces an R call of the data type. Use
  `namespace=TRUE` to call with `arrow::`.

There are also some active bindings:

- `$id`: integer Arrow type id.

- `$name`: string Arrow type name.

- `$num_fields`: number of child fields.

## See also

[`infer_type()`](https://arrow.apache.org/docs/r/reference/infer_type.md)

[`data-type`](https://arrow.apache.org/docs/r/reference/data-type.md)
