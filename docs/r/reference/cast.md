<div id="main" class="col-md-9" role="main">

# Change the type of an array or column

<div class="ref-description section level2">

This is a wrapper around the `$cast()` method that many Arrow objects
have. It is more convenient to call inside `dplyr` pipelines than the
method.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
cast(x, to, safe = TRUE, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    an `Array`, `Table`, `Expression`, or similar Arrow data object.

-   to:

    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
    to cast to; for
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
    and
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
    it should be a
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md).

-   safe:

    logical: only allow the type conversion if no data is lost
    (truncation, overflow, etc.). Default is `TRUE`.

-   ...:

    specific `CastOptions` to set

</div>

<div class="section level2">

## Value

An [Expression](https://arrow.apache.org/docs/r/reference/Expression.md)

</div>

<div class="section level2">

## See also

<div class="dont-index">

`data-type` for a list of
[DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
to be used with `to`.

[Arrow C++ CastOptions
documentation](https://arrow.apache.org/docs/cpp/api/compute.html?highlight=castoptions#arrow%3A%3Acompute%3A%3ACastOptions)
\# nolint for the list of supported CastOptions.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) { # \dontrun{
mtcars |>
  arrow_table() |>
  mutate(cyl = cast(cyl, string()))
} # }
```

</div>

</div>

</div>
