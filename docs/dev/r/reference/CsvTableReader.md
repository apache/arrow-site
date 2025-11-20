<div id="main" class="col-md-9" role="main">

# Arrow CSV and JSON table reader classes

<div class="ref-description section level2">

`CsvTableReader` and `JsonTableReader` wrap the Arrow C++ CSV and JSON
table readers. See their usage in `read_csv_arrow()` and
`read_json_arrow()`, respectively.

</div>

<div class="section level2">

## Factory

The `CsvTableReader$create()` and `JsonTableReader$create()` factory
methods take the following arguments:

-   `file` An Arrow
    [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)

-   `convert_options` (CSV only), `parse_options`, `read_options`: see
    [CsvReadOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)

-   `...` additional parameters.

</div>

<div class="section level2">

## Methods

-   `$Read()`: returns an Arrow Table.

</div>

</div>
