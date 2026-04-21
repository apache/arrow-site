# Load a Python Flight server

Load a Python Flight server

## Usage

``` r
load_flight_server(name, path = system.file(package = "arrow"))
```

## Arguments

- name:

  string Python module name

- path:

  file system path where the Python module is found. Default is to look
  in the `inst/` directory for included modules.

## Examples

``` r
if (FALSE) {
load_flight_server("demo_flight_server")
}
```
