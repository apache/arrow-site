<div id="main" class="col-md-9" role="main">

# Report information on the package's capabilities

<div class="ref-description section level2">

This function summarizes a number of build-time configurations and
run-time settings for the Arrow package. It may be useful for
diagnostics.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
arrow_info()

arrow_available()

arrow_with_acero()

arrow_with_dataset()

arrow_with_substrait()

arrow_with_parquet()

arrow_with_s3()

arrow_with_gcs()

arrow_with_json()
```

</div>

</div>

<div class="section level2">

## Value

`arrow_info()` returns a list including version information, boolean
"capabilities", and statistics from Arrow's memory allocator, and also
Arrow's run-time information. The `_available()` functions return a
logical value whether or not the C++ library was built with support for
them.

</div>

<div class="section level2">

## See also

<div class="dont-index">

If any capabilities are `FALSE`, see the [install
guide](https://arrow.apache.org/docs/r/articles/install.html) for
guidance on reinstalling the package.

</div>

</div>

</div>
