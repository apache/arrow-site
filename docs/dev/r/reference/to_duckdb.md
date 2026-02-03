# Create a (virtual) DuckDB table from an Arrow object

This will do the necessary configuration to create a (virtual) table in
DuckDB that is backed by the Arrow object given. No data is copied or
modified until
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) or
[`compute()`](https://dplyr.tidyverse.org/reference/compute.html) are
called or a query is run against the table.

## Usage

``` r
to_duckdb(
  .data,
  con = arrow_duck_connection(),
  table_name = unique_arrow_tablename(),
  auto_disconnect = TRUE
)
```

## Arguments

- .data:

  the Arrow object (e.g. Dataset, Table) to use for the DuckDB table

- con:

  a DuckDB connection to use (default will create one and store it in
  `options("arrow_duck_con")`)

- table_name:

  a name to use in DuckDB for this object. The default is a unique
  string `"arrow_"` followed by numbers.

- auto_disconnect:

  should the table be automatically cleaned up when the resulting object
  is removed (and garbage collected)? Default: `TRUE`

## Value

A `tbl` of the new table in DuckDB

## Details

The result is a dbplyr-compatible object that can be used in d(b)plyr
pipelines.

If `auto_disconnect = TRUE`, the DuckDB table that is created will be
configured to be unregistered when the `tbl` object is garbage
collected. This is helpful if you don't want to have extra table objects
in DuckDB after you've finished using them.

## Examples

``` r
library(dplyr)

ds <- InMemoryDataset$create(mtcars)

ds |>
  filter(mpg < 30) |>
  group_by(cyl) |>
  to_duckdb() |>
  slice_min(disp)
#> # Source:   SQL [?? x 11]
#> # Database: DuckDB 1.4.4 [unknown@Linux 6.11.0-1018-azure:R 4.5.2/:memory:]
#> # Groups:   cyl
#>     mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1  19.7     6  145    175  3.62  2.77  15.5     0     1     5     6
#> 2  16.4     8  276.   180  3.07  4.07  17.4     0     0     3     3
#> 3  17.3     8  276.   180  3.07  3.73  17.6     0     0     3     3
#> 4  15.2     8  276.   180  3.07  3.78  18       0     0     3     3
#> 5  27.3     4   79     66  4.08  1.94  18.9     1     1     4     1
```
