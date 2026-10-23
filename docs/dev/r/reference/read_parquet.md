# Read a Parquet file

'[Parquet](https://parquet.apache.org/)' is a columnar storage file
format. This function enables you to read Parquet files into R.

## Usage

``` r
read_parquet(
  file,
  col_select = NULL,
  as_data_frame = TRUE,
  props = ParquetArrowReaderProperties$create(),
  mmap = TRUE,
  ...
)
```

## Arguments

- file:

  A character file name or URI, connection, `raw` vector, an Arrow input
  stream, or a `FileSystem` with path (`SubTreeFileSystem`). If a file
  name or URI, an Arrow
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
  will be opened and closed when finished. If an input stream is
  provided, it will be left open.

- col_select:

  A character vector of column names to keep, as in the "select"
  argument to `data.table::fread()`, or a [tidy selection
  specification](https://tidyselect.r-lib.org/reference/eval_select.html)
  of columns, as used in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).

- as_data_frame:

  Should the function return a `tibble` (default) or an Arrow
  [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)?

- props:

  [ParquetArrowReaderProperties](https://arrow.apache.org/docs/r/reference/ParquetArrowReaderProperties.md)

- mmap:

  Use TRUE to use memory mapping where possible

- ...:

  Additional arguments passed to `ParquetFileReader$create()`

## Value

A `tibble` if `as_data_frame` is `TRUE` (the default), or an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
otherwise.

## Examples

``` r
tf <- tempfile()
on.exit(unlink(tf))
write_parquet(mtcars, tf)
df <- read_parquet(tf, col_select = starts_with("d"))
head(df)
#> # A tibble: 6 x 2
#>    disp  drat
#>   <dbl> <dbl>
#> 1   160  3.9 
#> 2   160  3.9 
#> 3   108  3.85
#> 4   258  3.08
#> 5   360  3.15
#> 6   225  2.76
```
