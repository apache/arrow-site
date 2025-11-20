<div id="main" class="col-md-9" role="main">

# CSV Writing Options

<div class="ref-description section level2">

CSV Writing Options

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
csv_write_options(
  include_header = TRUE,
  batch_size = 1024L,
  null_string = "",
  delimiter = ",",
  eol = "\n",
  quoting_style = c("Needed", "AllValid", "None")
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   include_header:

    Whether to write an initial header line with column names

-   batch_size:

    Maximum number of rows processed at a time.

-   null_string:

    The string to be written for null values. Must not contain quotation
    marks.

-   delimiter:

    Field delimiter

-   eol:

    The end of line character to use for ending rows

-   quoting_style:

    How to handle quotes. "Needed" (Only enclose values in quotes which
    need them, because their CSV rendering can contain quotes itself
    (e.g. strings or binary values)), "AllValid" (Enclose all valid
    values in quotes), or "None" (Do not enclose any values in quotes).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))
write_csv_arrow(airquality, tf, write_options = csv_write_options(null_string = "-99"))
```

</div>

</div>

</div>
