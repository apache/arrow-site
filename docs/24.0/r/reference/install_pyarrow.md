# Install pyarrow for use with reticulate

`pyarrow` is the Python package for Apache Arrow. This function helps
with installing it for use with `reticulate`.

## Usage

``` r
install_pyarrow(envname = NULL, nightly = FALSE, ...)
```

## Arguments

- envname:

  The name or full path of the Python environment to install into. This
  can be a virtualenv or conda environment created by `reticulate`. See
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

- nightly:

  logical: Should we install a development version of the package?
  Default is to use the official release version.

- ...:

  additional arguments passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).
