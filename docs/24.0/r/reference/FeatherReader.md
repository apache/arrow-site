# FeatherReader class

This class enables you to interact with Feather files. Create one to
connect to a file or other InputStream, and call `Read()` on it to make
an
[`arrow::Table`](https://arrow.apache.org/docs/r/reference/Table-class.md).
See its usage in
[`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md).

## Factory

The `FeatherReader$create()` factory method instantiates the object and
takes the following argument:

- `file` an Arrow file connection object inheriting from
  `RandomAccessFile`.

## Methods

- `$Read(columns)`: Returns a `Table` of the selected columns, a vector
  of integer indices

- `$column_names`: Active binding, returns the column names in the
  Feather file

- `$schema`: Active binding, returns the schema of the Feather file

- `$version`: Active binding, returns `1` or `2`, according to the
  Feather file version
