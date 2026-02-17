# Get `stringr` pattern options

This function assigns definitions for the `stringr` pattern modifier
functions (`fixed()`, `regex()`, etc.) inside itself, and uses them to
evaluate the quoted expression `pattern`, returning a list that is used
to control pattern matching behavior in internal `arrow` functions.

## Usage

``` r
get_stringr_pattern_options(pattern)
```

## Arguments

- pattern:

  Unevaluated expression containing a call to a `stringr` pattern
  modifier function

## Value

List containing elements `pattern`, `fixed`, and `ignore_case`
