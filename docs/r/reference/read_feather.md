<div id="main" class="col-md-9" role="main">

# Read a Feather file (an Arrow IPC file)

<div class="ref-description section level2">

Feather provides binary columnar serialization for data frames. It is
designed to make reading and writing data frames efficient, and to make
sharing data across data analysis languages easy. `read_feather()` can
read both the Feather Version 1 (V1), a legacy version available
starting in 2016, and the Version 2 (V2), which is the Apache Arrow IPC
file format. `read_ipc_file()` is an alias of `read_feather()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
read_feather(file, col_select = NULL, as_data_frame = TRUE, mmap = TRUE)

read_ipc_file(file, col_select = NULL, as_data_frame = TRUE, mmap = TRUE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   file:

    A character file name or URI, connection, `raw` vector, an Arrow
    input stream, or a `FileSystem` with path (`SubTreeFileSystem`). If
    a file name or URI, an Arrow
    [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
    will be opened and closed when finished. If an input stream is
    provided, it will be left open.

-   col_select:

    A character vector of column names to keep, as in the "select"
    argument to `data.table::fread()`, or a [tidy selection
    specification](https://tidyselect.r-lib.org/reference/eval_select.html)
    of columns, as used in `dplyr::select()`.

-   as_data_frame:

    Should the function return a `tibble` (default) or an Arrow
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)?

-   mmap:

    Logical: whether to memory-map the file (default `TRUE`)

</div>

<div class="section level2">

## Value

A `tibble` if `as_data_frame` is `TRUE` (the default), or an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
otherwise

</div>

<div class="section level2">

## See also

<div class="dont-index">

[FeatherReader](https://arrow.apache.org/docs/r/reference/FeatherReader.md)
and
[RecordBatchReader](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
for lower-level access to reading Arrow IPC data.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# We recommend the ".arrow" extension for Arrow IPC files (Feather V2).
tf <- tempfile(fileext = ".arrow")
on.exit(unlink(tf))
write_feather(mtcars, tf)
df <- read_feather(tf)
dim(df)
#> [1] 32 11
# Can select columns
df <- read_feather(tf, col_select = starts_with("d"))
```

</div>

</div>

</div>
