<div id="main" class="col-md-9" role="main">

# List available Arrow C++ compute functions

<div class="ref-description section level2">

This function lists the names of all available Arrow C++ library compute
functions. These can be called by passing to `call_function()`, or they
can be called by name with an `arrow_` prefix inside a `dplyr` verb.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
list_compute_functions(pattern = NULL, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   pattern:

    Optional regular expression to filter the function list

-   ...:

    Additional parameters passed to `grep()`

</div>

<div class="section level2">

## Value

A character vector of available Arrow C++ function names

</div>

<div class="section level2">

## Details

The resulting list describes the capabilities of your `arrow` build.
Some functions, such as string and regular expression functions, require
optional build-time C++ dependencies. If your `arrow` package was not
compiled with those features enabled, those functions will not appear in
this list.

Some functions take options that need to be passed when calling them (in
a list called `options`). These options require custom handling in C++;
many functions already have that handling set up but not all do. If you
encounter one that needs special handling for options, please report an
issue.

Note that this list does *not* enumerate all of the R bindings for these
functions. The package includes Arrow methods for many base R functions
that can be called directly on Arrow objects, as well as some
tidyverse-flavored versions available inside `dplyr` verbs.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[acero](https://arrow.apache.org/docs/r/reference/acero.md) for R
bindings for Arrow functions

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
available_funcs <- list_compute_functions()
utf8_funcs <- list_compute_functions(pattern = "^UTF8", ignore.case = TRUE)
```

</div>

</div>

</div>
