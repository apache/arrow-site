<div id="main" class="col-md-9" role="main">

# Get one value from each group

<div class="ref-description section level2">

Returns one arbitrary value from the input for each group. The function
is biased towards non-null values: if there is at least one non-null
value for a certain group, that value is returned, and only if all the
values are null for the group will the function return null.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
one(...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    Unquoted column name to pull values from.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) { # \dontrun{
mtcars |>
  arrow_table() |>
  group_by(cyl) |>
  summarize(x = one(disp))
} # }
```

</div>

</div>

</div>
