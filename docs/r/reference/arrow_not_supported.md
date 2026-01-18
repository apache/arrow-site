<div id="main" class="col-md-9" role="main">

# Helpers to raise classed errors

<div class="ref-description section level2">

`arrow_not_supported()` and `validation_error()` raise classed errors
that allow us to distinguish between things that are not supported in
Arrow and things that are just invalid input. Additional wrapping in
`arrow_eval()` and `try_arrow_dplyr()` provide more context and
suggestions. Importantly, if `arrow_not_supported` is raised, then
retrying the same code in regular dplyr in R may work. But if
`validation_error` is raised, then we shouldn't recommend retrying with
regular dplyr because it will fail there too.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
arrow_not_supported(
  msg,
  .actual_msg = paste(msg, "not supported in Arrow"),
  ...
)

validation_error(msg, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   msg:

    The message to show. `arrow_not_supported()` will append "not
    supported in Arrow" to this message.

-   .actual_msg:

    If you don't want to append "not supported in Arrow" to the message,
    you can provide the full message here.

-   ...:

    Additional arguments to pass to `rlang::abort()`. Useful arguments
    include `call` to provide the call or expression that caused the
    error, and `body` to provide additional context about the error.

</div>

<div class="section level2">

## Details

Use these in function bindings and in the dplyr methods. Inside of
function bindings, you don't need to provide the `call` argument, as it
will be automatically filled in with the expression that caused the
error in `arrow_eval()`. In dplyr methods, you should provide the `call`
argument; `rlang::caller_call()` often is correct, but you may need to
experiment to find how far up the call stack you need to look.

You may provide additional information in the `body` argument, a named
character vector. Use `i` for additional information about the error and
`>` to indicate potential solutions or workarounds that don't require
pulling the data into R. If you have an `arrow_not_supported()` error
with a `>` suggestion, when the error is ultimately raised by
`try_error_dplyr()`, `Call collect() first to pull data into R` won't be
the only suggestion.

You can still use `match.arg()` and `assert_that()` for simple input
validation inside of the function bindings. `arrow_eval()` will catch
their errors and re-raise them as `validation_error`.

</div>

</div>
