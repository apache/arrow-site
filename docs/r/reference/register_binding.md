<div id="main" class="col-md-9" role="main">

# Register compute bindings

<div class="ref-description section level2">

`register_binding()` is used to populate a list of functions that
operate on (and return) Expressions. These are the basis for the `.data`
mask inside dplyr methods.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
register_binding(fun_name, fun, notes = character(0))
```

</div>

</div>

<div class="section level2">

## Arguments

-   fun_name:

    A string containing a function name in the form `"function"` or
    `"package::function"`.

-   fun:

    A function, or `NULL` to un-register a previous function. This
    function must accept `Expression` objects as arguments and return
    `Expression` objects instead of regular R objects.

-   notes:

    string for the docs: note any limitations or differences in behavior
    between the Arrow version and the R function.

</div>

<div class="section level2">

## Value

The previously registered binding or `NULL` if no previously registered
function existed.

</div>

<div class="section level2">

## Writing bindings

-   `Expression$create()` will wrap any non-Expression inputs as Scalar
    Expressions. If you want to try to coerce scalar inputs to match the
    type of the Expression(s) in the arguments, call
    `cast_scalars_to_common_type(args)` on the args. For example,
    `Expression$create("add", args = list(int16_field, 1))` would result
    in a `float64` type output because `1` is a `double` in R. To
    prevent casting all of the data in `int16_field` to float and to
    preserve it as int16, do
    `Expression$create("add", args = cast_scalars_to_common_type(list(int16_field, 1)))`

-   Inside your function, you can call any other binding with
    `call_binding()`.

</div>

</div>
