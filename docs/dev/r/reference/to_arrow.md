# Create an Arrow object from a DuckDB connection

This can be used in pipelines that pass data back and forth between
Arrow and DuckDB.

## Usage

``` r
to_arrow(.data)
```

## Arguments

- .data:

  the object to be converted

## Value

A `RecordBatchReader`.

## Details

Note that you can only call
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) or
[`compute()`](https://dplyr.tidyverse.org/reference/compute.html) on the
result of this function once. To work around this limitation, you should
either only call
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) as the
final step in a pipeline or call
[`as_arrow_table()`](https://arrow.apache.org/docs/r/reference/as_arrow_table.md)
on the result to materialize the entire Table in-memory.

## Examples

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
#> 1     4     23.7
#> 2     6     19.7
#> 3     8     15.1
```
