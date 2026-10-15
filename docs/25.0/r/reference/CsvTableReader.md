# Arrow CSV and JSON table reader classes

`CsvTableReader` and `JsonTableReader` wrap the Arrow C++ CSV and JSON
table readers. See their usage in
[`read_csv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
and
[`read_json_arrow()`](https://arrow.apache.org/docs/r/reference/read_json_arrow.md),
respectively.

## Factory

The `CsvTableReader$create()` and `JsonTableReader$create()` factory
methods take the following arguments:

- `file` An Arrow
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)

- `convert_options` (CSV only), `parse_options`, `read_options`: see
  [CsvReadOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)

- `...` additional parameters.

## Methods

- `$Read()`: returns an Arrow Table.
