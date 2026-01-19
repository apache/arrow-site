<div id="main" class="col-md-9" role="main">

# Connect to a Flight server

<div class="ref-description section level2">

Connect to a Flight server

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
flight_connect(host = "localhost", port, scheme = "grpc+tcp")
```

</div>

</div>

<div class="section level2">

## Arguments

-   host:

    string hostname to connect to

-   port:

    integer port to connect on

-   scheme:

    URL scheme, default is "grpc+tcp"

</div>

<div class="section level2">

## Value

A `pyarrow.flight.FlightClient`.

</div>

</div>
