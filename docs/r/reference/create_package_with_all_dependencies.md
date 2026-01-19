<div id="main" class="col-md-9" role="main">

# Create a source bundle that includes all thirdparty dependencies

<div class="ref-description section level2">

Create a source bundle that includes all thirdparty dependencies

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
create_package_with_all_dependencies(dest_file = NULL, source_file = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   dest_file:

    File path for the new tar.gz package. Defaults to
    `arrow_V.V.V_with_deps.tar.gz` in the current directory (`V.V.V` is
    the version)

-   source_file:

    File path for the input tar.gz package. Defaults to downloading the
    package from CRAN (or whatever you have set as the first in
    `getOption("repos")`)

</div>

<div class="section level2">

## Value

The full path to `dest_file`, invisibly

This function is used for setting up an offline build. If it's possible
to download at build time, don't use this function. Instead, let `cmake`
download the required dependencies for you. These downloaded
dependencies are only used in the build if `ARROW_DEPENDENCY_SOURCE` is
unset, `BUNDLED`, or `AUTO`.
https://arrow.apache.org/docs/developers/cpp/building.html#offline-builds

If you're using binary packages you shouldn't need to use this function.
You should download the appropriate binary from your package repository,
transfer that to the offline computer, and install that. Any OS can
create the source bundle, but it cannot be installed on Windows.
(Instead, use a standard Windows binary package.)

Note if you're using RStudio Package Manager on Linux: If you still want
to make a source bundle with this function, make sure to set the first
repo in `options("repos")` to be a mirror that contains source packages
(that is: something other than the RSPM binary mirror URLs).

<div class="section">

### Steps for an offline install with optional dependencies:

<div class="section">

#### Using a computer with internet access, pre-download the dependencies:

-   Install the `arrow` package *or* run
    `source("https://raw.githubusercontent.com/apache/arrow/main/r/R/install-arrow.R")`

-   Run `create_package_with_all_dependencies("my_arrow_pkg.tar.gz")`

-   Copy the newly created `my_arrow_pkg.tar.gz` to the computer without
    internet access

</div>

<div class="section">

#### On the computer without internet access, install the prepared package:

-   Install the `arrow` package from the copied file

    -   `install.packages("my_arrow_pkg.tar.gz", dependencies = c("Depends", "Imports", "LinkingTo"))`

    -   This installation will build from source, so `cmake` must be
        available

-   Run `arrow_info()` to check installed capabilities

</div>

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) { # \dontrun{
new_pkg <- create_package_with_all_dependencies()
# Note: this works when run in the same R session, but it's meant to be
# copied to a different computer.
install.packages(new_pkg, dependencies = c("Depends", "Imports", "LinkingTo"))
} # }
```

</div>

</div>

</div>
