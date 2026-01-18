<div id="main" class="col-md-9" role="main">

# Load a Python Flight server

<div class="ref-description section level2">

Load a Python Flight server

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
load_flight_server(name, path = system.file(package = "arrow"))
```

</div>

</div>

<div class="section level2">

## Arguments

-   name:

    string Python module name

-   path:

    file system path where the Python module is found. Default is to
    look in the `inst/` directory for included modules.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) {
load_flight_server("demo_flight_server")
}
```

</div>

</div>

</div>
