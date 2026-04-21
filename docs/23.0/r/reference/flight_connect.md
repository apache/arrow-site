# Connect to a Flight server

Connect to a Flight server

## Usage

``` r
flight_connect(host = "localhost", port, scheme = "grpc+tcp")
```

## Arguments

- host:

  string hostname to connect to

- port:

  integer port to connect on

- scheme:

  URL scheme, default is "grpc+tcp"

## Value

A `pyarrow.flight.FlightClient`.
