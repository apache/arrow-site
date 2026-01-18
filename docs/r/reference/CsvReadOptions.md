<div id="main" class="col-md-9" role="main">

# File reader options

<div class="ref-description section level2">

`CsvReadOptions`, `CsvParseOptions`, `CsvConvertOptions`,
`JsonReadOptions`, `JsonParseOptions`, and `TimestampParser` are
containers for various file reading options. See their usage in
`read_csv_arrow()` and `read_json_arrow()`, respectively.

</div>

<div class="section level2">

## Factory

The `CsvReadOptions$create()` and `JsonReadOptions$create()` factory
methods take the following arguments:

-   `use_threads` Whether to use the global CPU thread pool

-   `block_size` Block size we request from the IO layer; also
    determines the size of chunks when use_threads is `TRUE`. NB: if
    `FALSE`, JSON input must end with an empty line.

`CsvReadOptions$create()` further accepts these additional arguments:

-   `skip_rows` Number of lines to skip before reading data (default 0).

-   `column_names` Character vector to supply column names. If length-0
    (the default), the first non-skipped row will be parsed to generate
    column names, unless `autogenerate_column_names` is `TRUE`.

-   `autogenerate_column_names` Logical: generate column names instead
    of using the first non-skipped row (the default)? If `TRUE`, column
    names will be "f0", "f1", ..., "fN".

-   `encoding` The file encoding. (default `"UTF-8"`)

-   `skip_rows_after_names` Number of lines to skip after the column
    names (default 0). This number can be larger than the number of rows
    in one block, and empty rows are counted. The order of application
    is as follows:

    -   `skip_rows` is applied (if non-zero);

    -   column names are read (unless `column_names` is set);

    -   `skip_rows_after_names` is applied (if non-zero).

`CsvParseOptions$create()` takes the following arguments:

-   `delimiter` Field delimiting character (default `","`)

-   `quoting` Logical: are strings quoted? (default `TRUE`)

-   `quote_char` Quoting character, if `quoting` is `TRUE` (default
    `'"'`)

-   `double_quote` Logical: are quotes inside values double-quoted?
    (default `TRUE`)

-   `escaping` Logical: whether escaping is used (default `FALSE`)

-   `escape_char` Escaping character, if `escaping` is `TRUE` (default
    `"\\"`)

-   `newlines_in_values` Logical: are values allowed to contain CR
    (`0x0d`) and LF (`0x0a`) characters? (default `FALSE`)

-   `ignore_empty_lines` Logical: should empty lines be ignored
    (default) or generate a row of missing values (if `FALSE`)?

`JsonParseOptions$create()` accepts only the `newlines_in_values`
argument.

`CsvConvertOptions$create()` takes the following arguments:

-   `check_utf8` Logical: check UTF8 validity of string columns?
    (default `TRUE`)

-   `null_values` character vector of recognized spellings for null
    values. Analogous to the `na.strings` argument to `read.csv()` or
    `na` in `readr::read_csv()`.

-   `strings_can_be_null` Logical: can string / binary columns have null
    values? Similar to the `quoted_na` argument to `readr::read_csv()`.
    (default `FALSE`)

-   `true_values` character vector of recognized spellings for `TRUE`
    values

-   `false_values` character vector of recognized spellings for `FALSE`
    values

-   `col_types` A `Schema` or `NULL` to infer types

-   `auto_dict_encode` Logical: Whether to try to automatically
    dictionary-encode string / binary data (think `stringsAsFactors`).
    Default `FALSE`. This setting is ignored for non-inferred columns
    (those in `col_types`).

-   `auto_dict_max_cardinality` If `auto_dict_encode`, string/binary
    columns are dictionary-encoded up to this number of unique values
    (default 50), after which it switches to regular encoding.

-   `include_columns` If non-empty, indicates the names of columns from
    the CSV file that should be actually read and converted (in the
    vector's order).

-   `include_missing_columns` Logical: if `include_columns` is provided,
    should columns named in it but not found in the data be included as
    a column of type `null()`? The default (`FALSE`) means that the
    reader will instead raise an error.

-   `timestamp_parsers` User-defined timestamp parsers. If more than one
    parser is specified, the CSV conversion logic will try parsing
    values starting from the beginning of this vector. Possible values
    are (a) `NULL`, the default, which uses the ISO-8601 parser; (b) a
    character vector of [strptime](https://rdrr.io/r/base/strptime.html)
    parse strings; or (c) a list of TimestampParser objects.

-   `decimal_point` Character to use for decimal point in floating point
    numbers. Default: "."

`TimestampParser$create()` takes an optional `format` string argument.
See `strptime()` for example syntax. The default is to use an ISO-8601
format parser.

The `CsvWriteOptions$create()` factory method takes the following
arguments:

-   `include_header` Whether to write an initial header line with column
    names

-   `batch_size` Maximum number of rows processed at a time. Default is
    1024.

-   `null_string` The string to be written for null values. Must not
    contain quotation marks. Default is an empty string (`""`).

-   `eol` The end of line character to use for ending rows.

-   `delimiter` Field delimiter

-   `quoting_style` Quoting style: "Needed" (Only enclose values in
    quotes which need them, because their CSV rendering can contain
    quotes itself (e.g. strings or binary values)), "AllValid" (Enclose
    all valid values in quotes), or "None" (Do not enclose any values in
    quotes).

</div>

<div class="section level2">

## Active bindings

-   `column_names`: from `CsvReadOptions`

</div>

</div>
