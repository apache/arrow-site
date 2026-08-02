# Read an Arrow IPC file

The Arrow IPC file format provides binary columnar serialization for
data frames. It is designed to make reading and writing data frames
efficient, and to make sharing data across data analysis languages easy.

## Usage

``` r
read_ipc_file(file, col_select = NULL, as_data_frame = TRUE, mmap = TRUE)
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

- mmap:

  Logical: whether to memory-map the file (default `TRUE`)

## Value

A `tibble` if `as_data_frame` is `TRUE` (the default), or an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
otherwise

## Details

This function can also read the legacy Feather V1 format.

## See also

[FeatherReader](https://arrow.apache.org/docs/r/reference/FeatherReader.md)
and
[RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
for lower-level access to reading Arrow IPC data.

## Examples

``` r
tf <- tempfile(fileext = ".arrow")
on.exit(unlink(tf))
write_ipc_file(mtcars, tf)
df <- read_ipc_file(tf)
dim(df)
#> [1] 32 11
# Can select columns
df <- read_ipc_file(tf, col_select = starts_with("d"))
```
