# See available resources on a Flight server

See available resources on a Flight server

## Usage

``` r
list_flights(client)

flight_path_exists(client, path)
```

## Arguments

- client:

  `pyarrow.flight.FlightClient`, as returned by
  [`flight_connect()`](https://arrow.apache.org/docs/r/reference/flight_connect.md)

- path:

  string identifier under which data is stored

## Value

`list_flights()` returns a character vector of paths.
`flight_path_exists()` returns a logical value, the equivalent of
`path %in% list_flights()`
