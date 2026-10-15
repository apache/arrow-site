# Add the data filename as a column

This function only exists inside `arrow` `dplyr` queries, and it only is
valid when querying on a `FileSystemDataset`, such as one created by
[`open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.md).
Use it inside `mutate()` to add a column holding the path of the file
each row was read from.

## Usage

``` r
add_filename()
```

## Value

A `FieldRef`
[`Expression`](https://arrow.apache.org/docs/r/reference/Expression.md)
that refers to the filename augmented column.

## Details

The filename column can be used in later `select()`, `arrange()` and
`group_by()` steps of the same query. However, it can't be used in
[`filter()`](https://rdrr.io/r/stats/filter.html), and some functions
(such as [`substr()`](https://rdrr.io/r/base/substr.html)) are not
supported on it. In these cases, call
[`compute()`](https://dplyr.tidyverse.org/reference/compute.html) or
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) first.
`add_filename()` must also be called before any aggregation or join. See
Examples.

## See also

[`open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.md)

## Examples

``` r
if (FALSE) { # \dontrun{
open_dataset("nyc-taxi") |>
  mutate(file = add_filename()) |>
  collect()

# Simple expressions on the new column work in a later mutate(), for
# example to recover a partition value from the path
open_dataset("nyc-taxi/year=2015") |>
  mutate(file = add_filename()) |>
  mutate(year_from_path = sub(".*year=([0-9]{4}).*", "\\1", file)) |>
  collect()

# To filter() on the new column, or use functions such as substr() that
# need to know its type, call compute() or collect() first
open_dataset("nyc-taxi") |>
  mutate(file = add_filename()) |>
  compute() |>
  filter(endsWith(file, "part-0.parquet")) |>
  mutate(file_start = substr(file, 1, 10)) |>
  collect()
} # }
```
