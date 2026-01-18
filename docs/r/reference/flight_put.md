<div id="main" class="col-md-9" role="main">

# Send data to a Flight server

<div class="ref-description section level2">

Send data to a Flight server

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
flight_put(client, data, path, overwrite = TRUE, max_chunksize = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   client:

    `pyarrow.flight.FlightClient`, as returned by `flight_connect()`

-   data:

    `data.frame`,
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
    or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
    to upload

-   path:

    string identifier to store the data under

-   overwrite:

    logical: if `path` exists on `client` already, should we replace it
    with the contents of `data`? Default is `TRUE`; if `FALSE` and
    `path` exists, the function will error.

-   max_chunksize:

    integer: Maximum number of rows for RecordBatch chunks when a
    `data.frame` is sent. Individual chunks may be smaller depending on
    the chunk layout of individual columns.

</div>

<div class="section level2">

## Value

`client`, invisibly.

</div>

</div>
