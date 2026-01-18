<div id="main" class="col-md-9" role="main">

# See available resources on a Flight server

<div class="ref-description section level2">

See available resources on a Flight server

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
list_flights(client)

flight_path_exists(client, path)
```

</div>

</div>

<div class="section level2">

## Arguments

-   client:

    `pyarrow.flight.FlightClient`, as returned by `flight_connect()`

-   path:

    string identifier under which data is stored

</div>

<div class="section level2">

## Value

`list_flights()` returns a character vector of paths.
`flight_path_exists()` returns a logical value, the equivalent of
`path %in% list_flights()`

</div>

</div>
