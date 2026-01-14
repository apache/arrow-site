<div id="main" class="col-md-9" role="main">

# Create an Arrow object from a DuckDB connection

<div class="ref-description section level2">

This can be used in pipelines that pass data back and forth between
Arrow and DuckDB.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
to_arrow(.data)
```

</div>

</div>

<div class="section level2">

## Arguments

-   .data:

    the object to be converted

</div>

<div class="section level2">

## Value

A `RecordBatchReader`.

</div>

<div class="section level2">

## Details

Note that you can only call `collect()` or `compute()` on the result of
this function once. To work around this limitation, you should either
only call `collect()` as the final step in a pipeline or call
`as_arrow_table()` on the result to materialize the entire Table
in-memory.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
library(dplyr)

ds <- InMemoryDataset$create(mtcars)

ds |>
  filter(mpg < 30) |>
  to_duckdb() |>
  group_by(cyl) |>
  summarize(mean_mpg = mean(mpg, na.rm = TRUE)) |>
  to_arrow() |>
  collect()
#> # A tibble: 3 x 2
#>     cyl mean_mpg
#>   <dbl>    <dbl>
#> 1     6     19.7
#> 2     8     15.1
#> 3     4     23.7
```

</div>

</div>

</div>
