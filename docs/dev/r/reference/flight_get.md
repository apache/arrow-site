<div id="main" class="col-md-9" role="main">

# Get data from a Flight server

<div class="ref-description section level2">

Get data from a Flight server

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
flight_get(client, path)
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

A [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

</div>

</div>
