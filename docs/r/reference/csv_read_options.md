<div id="main" class="col-md-9" role="main">

# CSV Reading Options

<div class="ref-description section level2">

CSV Reading Options

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
csv_read_options(
  use_threads = option_use_threads(),
  block_size = 1048576L,
  skip_rows = 0L,
  column_names = character(0),
  autogenerate_column_names = FALSE,
  encoding = "UTF-8",
  skip_rows_after_names = 0L
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   use_threads:

    Whether to use the global CPU thread pool

-   block_size:

    Block size we request from the IO layer; also determines the size of
    chunks when use_threads is `TRUE`.

-   skip_rows:

    Number of lines to skip before reading data (default 0).

-   column_names:

    Character vector to supply column names. If length-0 (the default),
    the first non-skipped row will be parsed to generate column names,
    unless `autogenerate_column_names` is `TRUE`.

-   autogenerate_column_names:

    Logical: generate column names instead of using the first
    non-skipped row (the default)? If `TRUE`, column names will be "f0",
    "f1", ..., "fN".

-   encoding:

    The file encoding. (default `"UTF-8"`)

-   skip_rows_after_names:

    Number of lines to skip after the column names (default 0). This
    number can be larger than the number of rows in one block, and empty
    rows are counted. The order of application is as follows: -
    `skip_rows` is applied (if non-zero); - column names are read
    (unless `column_names` is set); - `skip_rows_after_names` is applied
    (if non-zero).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))
writeLines("my file has a non-data header\nx\n1\n2", tf)
read_csv_arrow(tf, read_options = csv_read_options(skip_rows = 1))
#> # A tibble: 2 x 1
#>       x
#>   <int>
#> 1     1
#> 2     2
open_csv_dataset(tf, read_options = csv_read_options(skip_rows = 1))
#> FileSystemDataset with 1 csv file
#> 1 columns
#> x: int64
```

</div>

</div>

</div>
