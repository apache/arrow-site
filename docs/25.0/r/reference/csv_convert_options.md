# CSV Convert Options

CSV Convert Options

## Usage

``` r
csv_convert_options(
  check_utf8 = TRUE,
  null_values = c("", "NA"),
  true_values = c("T", "true", "TRUE"),
  false_values = c("F", "false", "FALSE"),
  strings_can_be_null = FALSE,
  col_types = NULL,
  auto_dict_encode = FALSE,
  auto_dict_max_cardinality = 50L,
  include_columns = character(),
  include_missing_columns = FALSE,
  timestamp_parsers = NULL,
  decimal_point = "."
)
```

## Arguments

- check_utf8:

  Logical: check UTF8 validity of string columns?

- null_values:

  Character vector of recognized spellings for null values. Analogous to
  the `na.strings` argument to
  [`read.csv()`](https://rdrr.io/r/utils/read.table.html) or `na` in
  `readr::read_csv()`.

- true_values:

  Character vector of recognized spellings for `TRUE` values

- false_values:

  Character vector of recognized spellings for `FALSE` values

- strings_can_be_null:

  Logical: can string / binary columns have null values? Similar to the
  `quoted_na` argument to `readr::read_csv()`

- col_types:

  A `Schema` or `NULL` to infer types

- auto_dict_encode:

  Logical: Whether to try to automatically dictionary-encode string /
  binary data (think `stringsAsFactors`). This setting is ignored for
  non-inferred columns (those in `col_types`).

- auto_dict_max_cardinality:

  If `auto_dict_encode`, string/binary columns are dictionary-encoded up
  to this number of unique values (default 50), after which it switches
  to regular encoding.

- include_columns:

  If non-empty, indicates the names of columns from the CSV file that
  should be actually read and converted (in the vector's order).

- include_missing_columns:

  Logical: if `include_columns` is provided, should columns named in it
  but not found in the data be included as a column of type
  [`null()`](https://arrow.apache.org/docs/r/reference/data-type.md)?
  The default (`FALSE`) means that the reader will instead raise an
  error.

- timestamp_parsers:

  User-defined timestamp parsers. If more than one parser is specified,
  the CSV conversion logic will try parsing values starting from the
  beginning of this vector. Possible values are (a) `NULL`, the default,
  which uses the ISO-8601 parser; (b) a character vector of
  [strptime](https://rdrr.io/r/base/strptime.html) parse strings; or (c)
  a list of
  [TimestampParser](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  objects.

- decimal_point:

  Character to use for decimal point in floating point numbers.

## Examples

``` r
tf <- tempfile()
on.exit(unlink(tf))
writeLines("x\n1\nNULL\n2\nNA", tf)
read_csv_arrow(tf, convert_options = csv_convert_options(null_values = c("", "NA", "NULL")))
#> # A tibble: 4 x 1
#>       x
#>   <int>
#> 1     1
#> 2    NA
#> 3     2
#> 4    NA
open_csv_dataset(tf, convert_options = csv_convert_options(null_values = c("", "NA", "NULL")))
#> FileSystemDataset with 1 csv file
#> 1 columns
#> x: int64
```
