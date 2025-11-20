<div id="main" class="col-md-9" role="main">

# Install or upgrade the Arrow library

<div class="ref-description section level2">

Use this function to install the latest release of `arrow`, to switch to
or from a nightly development version, or on Linux to try reinstalling
with all necessary C++ dependencies.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
install_arrow(
  nightly = FALSE,
  binary = Sys.getenv("LIBARROW_BINARY", TRUE),
  use_system = Sys.getenv("ARROW_USE_PKG_CONFIG", FALSE),
  minimal = Sys.getenv("LIBARROW_MINIMAL", FALSE),
  verbose = Sys.getenv("ARROW_R_DEV", FALSE),
  repos = getOption("repos"),
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   nightly:

    logical: Should we install a development version of the package, or
    should we install from CRAN (the default).

-   binary:

    On Linux, value to set for the environment variable
    `LIBARROW_BINARY`, which governs how C++ binaries are used, if at
    all. The default value, `TRUE`, tells the installation script to
    detect the Linux distribution and version and find an appropriate
    C++ library. `FALSE` would tell the script not to retrieve a binary
    and instead build Arrow C++ from source. Other valid values are
    strings corresponding to a Linux distribution-version, to override
    the value that would be detected. See the [install
    guide](https://arrow.apache.org/docs/r/articles/install.html) for
    further details.

-   use_system:

    logical: Should we use `pkg-config` to look for Arrow system
    packages? Default is `FALSE`. If `TRUE`, source installation may be
    faster, but there is a risk of version mismatch. This sets the
    `ARROW_USE_PKG_CONFIG` environment variable.

-   minimal:

    logical: If building from source, should we build without optional
    dependencies (compression libraries, for example)? Default is
    `FALSE`. This sets the `LIBARROW_MINIMAL` environment variable.

-   verbose:

    logical: Print more debugging output when installing? Default is
    `FALSE`. This sets the `ARROW_R_DEV` environment variable.

-   repos:

    character vector of base URLs of the repositories to install from
    (passed to `install.packages()`)

-   ...:

    Additional arguments passed to `install.packages()`

</div>

<div class="section level2">

## Details

Note that, unlike packages like `tensorflow`, `blogdown`, and others
that require external dependencies, you do not need to run
`install_arrow()` after a successful `arrow` installation.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`arrow_info()` to see if the package was configured with necessary C++
dependencies. [install
guide](https://arrow.apache.org/docs/r/articles/install.html) for more
ways to tune installation on Linux.

</div>

</div>

</div>
