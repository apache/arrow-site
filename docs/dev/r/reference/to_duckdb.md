<div id="main" class="col-md-9" role="main">

# Create a (virtual) DuckDB table from an Arrow object

<div class="ref-description section level2">

This will do the necessary configuration to create a (virtual) table in
DuckDB that is backed by the Arrow object given. No data is copied or
modified until `collect()` or `compute()` are called or a query is run
against the table.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
to_duckdb(
  .data,
  con = arrow_duck_connection(),
  table_name = unique_arrow_tablename(),
  auto_disconnect = TRUE
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   .data:

    the Arrow object (e.g. Dataset, Table) to use for the DuckDB table

-   con:

    a DuckDB connection to use (default will create one and store it in
    `options("arrow_duck_con")`)

-   table_name:

    a name to use in DuckDB for this object. The default is a unique
    string `"arrow_"` followed by numbers.

-   auto_disconnect:

    should the table be automatically cleaned up when the resulting
    object is removed (and garbage collected)? Default: `TRUE`

</div>

<div class="section level2">

## Value

A `tbl` of the new table in DuckDB

</div>

<div class="section level2">

## Details

The result is a dbplyr-compatible object that can be used in d(b)plyr
pipelines.

If `auto_disconnect = TRUE`, the DuckDB table that is created will be
configured to be unregistered when the `tbl` object is garbage
collected. This is helpful if you don't want to have extra table objects
in DuckDB after you've finished using them.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
library(dplyr)

ds <- InMemoryDataset$create(mtcars)

ds |>
  filter(mpg < 30) |>
  group_by(cyl) |>
  to_duckdb() |>
  slice_min(disp)
#> # Source:   SQL [?? x 11]
#> # Database: DuckDB 1.4.2 [unknown@Linux 6.11.0-1018-azure:R 4.5.2/:memory:]
#> # Groups:   cyl
#>     mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1  19.7     6  145    175  3.62  2.77  15.5     0     1     5     6
#> 2  27.3     4   79     66  4.08  1.94  18.9     1     1     4     1
#> 3  16.4     8  276.   180  3.07  4.07  17.4     0     0     3     3
#> 4  17.3     8  276.   180  3.07  3.73  17.6     0     0     3     3
#> 5  15.2     8  276.   180  3.07  3.78  18       0     0     3     3
```

</div>

</div>

</div>
