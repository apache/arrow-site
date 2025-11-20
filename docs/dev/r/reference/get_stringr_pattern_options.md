<div id="main" class="col-md-9" role="main">

# Get `stringr` pattern options

<div class="ref-description section level2">

This function assigns definitions for the `stringr` pattern modifier
functions (`fixed()`, `regex()`, etc.) inside itself, and uses them to
evaluate the quoted expression `pattern`, returning a list that is used
to control pattern matching behavior in internal `arrow` functions.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
get_stringr_pattern_options(pattern)
```

</div>

</div>

<div class="section level2">

## Arguments

-   pattern:

    Unevaluated expression containing a call to a `stringr` pattern
    modifier function

</div>

<div class="section level2">

## Value

List containing elements `pattern`, `fixed`, and `ignore_case`

</div>

</div>
