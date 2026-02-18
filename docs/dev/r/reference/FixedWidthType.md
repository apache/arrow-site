# FixedWidthType class

`FixedWidthType` is a base class for data types with a fixed width in
bits. This includes all integer types, floating-point types, `Boolean`,
`FixedSizeBinary`, temporal types (dates, times, timestamps, durations),
and decimal types.

## R6 Methods

`FixedWidthType` inherits from
[DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md),
so it has the same methods.

## Active bindings

- `$bit_width`: The width of the type in bits
