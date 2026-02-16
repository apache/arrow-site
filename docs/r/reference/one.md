# Get one value from each group

Returns one arbitrary value from the input for each group. The function
is biased towards non-null values: if there is at least one non-null
value for a certain group, that value is returned, and only if all the
values are null for the group will the function return null.

## Usage

``` r
one(...)
```

## Arguments

- ...:

  Unquoted column name to pull values from.

## Examples

``` r
if (FALSE) { # \dontrun{
mtcars |>
  arrow_table() |>
  group_by(cyl) |>
  summarize(x = one(disp))
} # }
```
