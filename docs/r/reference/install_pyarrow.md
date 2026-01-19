<div id="main" class="col-md-9" role="main">

# Install pyarrow for use with reticulate

<div class="ref-description section level2">

`pyarrow` is the Python package for Apache Arrow. This function helps
with installing it for use with `reticulate`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
install_pyarrow(envname = NULL, nightly = FALSE, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   envname:

    The name or full path of the Python environment to install into.
    This can be a virtualenv or conda environment created by
    `reticulate`. See `reticulate::py_install()`.

-   nightly:

    logical: Should we install a development version of the package?
    Default is to use the official release version.

-   ...:

    additional arguments passed to `reticulate::py_install()`.

</div>

</div>
