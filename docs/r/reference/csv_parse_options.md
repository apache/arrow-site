<div id="main" class="col-md-9" role="main">

# CSV Parsing Options

<div class="ref-description section level2">

CSV Parsing Options

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
csv_parse_options(
  delimiter = ",",
  quoting = TRUE,
  quote_char = "\"",
  double_quote = TRUE,
  escaping = FALSE,
  escape_char = "\\",
  newlines_in_values = FALSE,
  ignore_empty_lines = TRUE
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   delimiter:

    Field delimiting character

-   quoting:

    Logical: are strings quoted?

-   quote_char:

    Quoting character, if `quoting` is `TRUE`

-   double_quote:

    Logical: are quotes inside values double-quoted?

-   escaping:

    Logical: whether escaping is used

-   escape_char:

    Escaping character, if `escaping` is `TRUE`

-   newlines_in_values:

    Logical: are values allowed to contain CR (`0x0d`) and LF (`0x0a`)
    characters?

-   ignore_empty_lines:

    Logical: should empty lines be ignored (default) or generate a row
    of missing values (if `FALSE`)?

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tf <- tempfile()
on.exit(unlink(tf))
writeLines("x\n1\n\n2", tf)
read_csv_arrow(tf, parse_options = csv_parse_options(ignore_empty_lines = FALSE))
#> # A tibble: 3 x 1
#>       x
#>   <int>
#> 1     1
#> 2    NA
#> 3     2
open_csv_dataset(tf, parse_options = csv_parse_options(ignore_empty_lines = FALSE))
#> FileSystemDataset with 1 csv file
#> 1 columns
#> x: int64
```

</div>

</div>

</div>
