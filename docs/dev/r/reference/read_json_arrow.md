# Read a JSON file

Wrapper around
[JsonTableReader](https://arrow.apache.org/docs/r/reference/CsvTableReader.md)
to read a newline-delimited JSON (ndjson) file into a data frame or
Arrow Table.

## Usage

``` r
read_json_arrow(
  file,
  col_select = NULL,
  as_data_frame = TRUE,
  schema = NULL,
  ...
)
```

## Arguments

- file:

  A character file name or URI, connection, literal data (either a
  single string or a [raw](https://rdrr.io/r/base/raw.html) vector), an
  Arrow input stream, or a `FileSystem` with path (`SubTreeFileSystem`).

  If a file name, a memory-mapped Arrow
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
  will be opened and closed when finished; compression will be detected
  from the file extension and handled automatically. If an input stream
  is provided, it will be left open.

  To be recognised as literal data, the input must be wrapped with
  [`I()`](https://rdrr.io/r/base/AsIs.html).

- col_select:

  A character vector of column names to keep, as in the "select"
  argument to `data.table::fread()`, or a [tidy selection
  specification](https://tidyselect.r-lib.org/reference/eval_select.html)
  of columns, as used in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).

- as_data_frame:

  Should the function return a `tibble` (default) or an Arrow
  [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)?

- schema:

  [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
  that describes the table.

- ...:

  Additional options passed to `JsonTableReader$create()`

## Value

A `tibble`, or a Table if `as_data_frame = FALSE`.

## Details

If passed a path, will detect and handle compression from the file
extension (e.g. `.json.gz`).

If `schema` is not provided, Arrow data types are inferred from the
data:

- JSON null values convert to the
  [`null()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  type, but can fall back to any other type.

- JSON booleans convert to
  [`boolean()`](https://arrow.apache.org/docs/r/reference/data-type.md).

- JSON numbers convert to
  [`int64()`](https://arrow.apache.org/docs/r/reference/data-type.md),
  falling back to
  [`float64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  if a non-integer is encountered.

- JSON strings of the kind "YYYY-MM-DD" and "YYYY-MM-DD hh:mm:ss"
  convert to
  [`timestamp(unit = "s")`](https://arrow.apache.org/docs/r/reference/data-type.md),
  falling back to
  [`utf8()`](https://arrow.apache.org/docs/r/reference/data-type.md) if
  a conversion error occurs.

- JSON arrays convert to a
  [`list_of()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  type, and inference proceeds recursively on the JSON arrays' values.

- Nested JSON objects convert to a
  [`struct()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  type, and inference proceeds recursively on the JSON objects' values.

When `as_data_frame = TRUE`, Arrow types are further converted to R
types.

## Examples

``` r
tf <- tempfile()
on.exit(unlink(tf))
writeLines('
    { "hello": 3.5, "world": false, "yo": "thing" }
    { "hello": 3.25, "world": null }
    { "hello": 0.0, "world": true, "yo": null }
  ', tf, useBytes = TRUE)

read_json_arrow(tf)
#> # A tibble: 3 x 3
#>   hello world yo   
#>   <dbl> <lgl> <chr>
#> 1  3.5  FALSE thing
#> 2  3.25 NA    NA   
#> 3  0    TRUE  NA   

# Read directly from strings with `I()`
read_json_arrow(I(c('{"x": 1, "y": 2}', '{"x": 3, "y": 4}')))
#> # A tibble: 2 x 2
#>       x     y
#>   <int> <int>
#> 1     1     2
#> 2     3     4
```
