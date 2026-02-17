# Report information on the package's capabilities

This function summarizes a number of build-time configurations and
run-time settings for the Arrow package. It may be useful for
diagnostics.

## Usage

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

## Value

`arrow_info()` returns a list including version information, boolean
"capabilities", and statistics from Arrow's memory allocator, and also
Arrow's run-time information. The `_available()` functions return a
logical value whether or not the C++ library was built with support for
them.

## See also

If any capabilities are `FALSE`, see the [install
guide](https://arrow.apache.org/docs/r/articles/install.html) for
guidance on reinstalling the package.
