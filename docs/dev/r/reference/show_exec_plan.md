<div id="main" class="col-md-9" role="main">

# Show the details of an Arrow Execution Plan

<div class="ref-description section level2">

This is a function which gives more details about the logical query plan
that will be executed when evaluating an `arrow_dplyr_query` object. It
calls the C++ `ExecPlan` object's print method. Functionally, it is
similar to `dplyr::explain()`. This function is used as the
`dplyr::explain()` and `dplyr::show_query()` methods.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
show_exec_plan(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    an `arrow_dplyr_query` to print the `ExecPlan` for.

</div>

<div class="section level2">

## Value

`x`, invisibly.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
library(dplyr)
mtcars |>
  arrow_table() |>
  filter(mpg > 20) |>
  mutate(x = gear / carb) |>
  show_exec_plan()
#> ExecPlan with 4 nodes:
#> 3:SinkNode{}
#>   2:ProjectNode{projection=[mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb, "x": divide(cast(gear, {to_type=double, allow_int_overflow=false, allow_time_truncate=false, allow_time_overflow=false, allow_decimal_truncate=false, allow_float_truncate=false, allow_invalid_utf8=false}), cast(carb, {to_type=double, allow_int_overflow=false, allow_time_truncate=false, allow_time_overflow=false, allow_decimal_truncate=false, allow_float_truncate=false, allow_invalid_utf8=false}))]}
#>     1:FilterNode{filter=(mpg > 20)}
#>       0:TableSourceNode{}
```

</div>

</div>

</div>
