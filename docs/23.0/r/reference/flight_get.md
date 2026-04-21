# Get data from a Flight server

Get data from a Flight server

## Usage

``` r
flight_get(client, path)
```

## Arguments

- client:

  `pyarrow.flight.FlightClient`, as returned by
  [`flight_connect()`](https://arrow.apache.org/docs/r/reference/flight_connect.md)

- path:

  string identifier under which data is stored

## Value

A [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
