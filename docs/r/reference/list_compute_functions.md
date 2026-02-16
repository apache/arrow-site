# List available Arrow C++ compute functions

This function lists the names of all available Arrow C++ library compute
functions. These can be called by passing to
[`call_function()`](https://arrow.apache.org/docs/r/reference/call_function.md),
or they can be called by name with an `arrow_` prefix inside a `dplyr`
verb.

## Usage

``` r
list_compute_functions(pattern = NULL, ...)
```

## Arguments

- pattern:

  Optional regular expression to filter the function list

- ...:

  Additional parameters passed to
  [`grep()`](https://rdrr.io/r/base/grep.html)

## Value

A character vector of available Arrow C++ function names

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

## See also

[acero](https://arrow.apache.org/docs/r/reference/acero.md) for R
bindings for Arrow functions

## Examples

``` r
available_funcs <- list_compute_functions()
utf8_funcs <- list_compute_functions(pattern = "^UTF8", ignore.case = TRUE)
```
