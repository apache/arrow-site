# Read a Feather file (deprecated)

`read_feather()` is deprecated and will be removed in a future release.
Use
[`read_ipc_file()`](https://arrow.apache.org/docs/r/reference/read_ipc_file.md)
instead.

`read_feather()` can read both the Feather V1 format (a legacy format
which is also being deprecated) and the Feather V2 format (which is the
Arrow IPC format).
[`read_ipc_file()`](https://arrow.apache.org/docs/r/reference/read_ipc_file.md)
can also read both formats.

## Usage

``` r
read_feather(file, col_select = NULL, as_data_frame = TRUE, mmap = TRUE)
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

## See also

[`read_ipc_file()`](https://arrow.apache.org/docs/r/reference/read_ipc_file.md)
