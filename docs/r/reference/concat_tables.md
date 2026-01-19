<div id="main" class="col-md-9" role="main">

# Concatenate one or more Tables

<div class="ref-description section level2">

Concatenate one or more
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
objects into a single table. This operation does not copy array data,
but instead creates new chunked arrays for each column that point at
existing array data.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
concat_tables(..., unify_schemas = TRUE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    One or more
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md) or
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
    objects. RecordBatch objects will be automatically converted to
    Tables.

-   unify_schemas:

    If TRUE, the schemas of the tables will be first unified with fields
    of the same name being merged, then each table will be promoted to
    the unified schema before being concatenated. Otherwise, all tables
    should have the same schema.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tbl <- arrow_table(name = rownames(mtcars), mtcars)
prius <- arrow_table(name = "Prius", mpg = 58, cyl = 4, disp = 1.8)
combined <- concat_tables(tbl, prius)
tail(combined)$to_data_frame()
#> # A tibble: 6 x 12
#>   name           mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>   <chr>        <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 Lotus Europa  30.4     4  95.1   113  3.77  1.51  16.9     1     1     5     2
#> 2 Ford Panter~  15.8     8 351     264  4.22  3.17  14.5     0     1     5     4
#> 3 Ferrari Dino  19.7     6 145     175  3.62  2.77  15.5     0     1     5     6
#> 4 Maserati Bo~  15       8 301     335  3.54  3.57  14.6     0     1     5     8
#> 5 Volvo 142E    21.4     4 121     109  4.11  2.78  18.6     1     1     4     2
#> 6 Prius         58       4   1.8    NA NA    NA     NA      NA    NA    NA    NA

# Can also pass RecordBatch objects
batch <- record_batch(name = "Volt", mpg = 53, cyl = 4, disp = 1.5)
combined2 <- concat_tables(tbl, batch)
```

</div>

</div>

</div>
