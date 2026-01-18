<div id="main" class="col-md-9" role="main">

# Register user-defined functions

<div class="ref-description section level2">

These functions support calling R code from query engine execution
(i.e., a `dplyr::mutate()` or `dplyr::filter()` on a
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md) or
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md)). Use
`register_scalar_function()` attach Arrow input and output types to an R
function and make it available for use in the dplyr interface and/or
`call_function()`. Scalar functions are currently the only type of
user-defined function supported. In Arrow, scalar functions must be
stateless and return output with the same shape (i.e., the same number
of rows) as the input.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
register_scalar_function(name, fun, in_type, out_type, auto_convert = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   name:

    The function name to be used in the dplyr bindings

-   fun:

    An R function or rlang-style lambda expression. The function will be
    called with a first argument `context` which is a `list()` with
    elements `batch_size` (the expected length of the output) and
    `output_type` (the required
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
    of the output) that may be used to ensure that the output has the
    correct type and length. Subsequent arguments are passed by position
    as specified by `in_types`. If `auto_convert` is `TRUE`, subsequent
    arguments are converted to R vectors before being passed to `fun`
    and the output is automatically constructed with the expected output
    type via `as_arrow_array()`.

-   in_type:

    A
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
    of the input type or a `schema()` for functions with more than one
    argument. This signature will be used to determine if this function
    is appropriate for a given set of arguments. If this function is
    appropriate for more than one signature, pass a `list()` of the
    above.

-   out_type:

    A
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
    of the output type or a function accepting a single argument
    (`types`), which is a `list()` of
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)s.
    If a function it must return a
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md).

-   auto_convert:

    Use `TRUE` to convert inputs before passing to `fun` and construct
    an Array of the correct type from the output. Use this option to
    write functions of R objects as opposed to functions of Arrow R6
    objects.

</div>

<div class="section level2">

## Value

`NULL`, invisibly

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) { # arrow_with_dataset() && identical(Sys.getenv("NOT_CRAN"), "true")
library(dplyr, warn.conflicts = FALSE)

some_model <- lm(mpg ~ disp + cyl, data = mtcars)
register_scalar_function(
  "mtcars_predict_mpg",
  function(context, disp, cyl) {
    predict(some_model, newdata = data.frame(disp, cyl))
  },
  in_type = schema(disp = float64(), cyl = float64()),
  out_type = float64(),
  auto_convert = TRUE
)

as_arrow_table(mtcars) |>
  transmute(mpg, mpg_predicted = mtcars_predict_mpg(disp, cyl)) |>
  collect() |>
  head()
}
```

</div>

</div>

</div>
