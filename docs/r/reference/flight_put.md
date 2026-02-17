# Send data to a Flight server

Send data to a Flight server

## Usage

``` r
flight_put(client, data, path, overwrite = TRUE, max_chunksize = NULL)
```

## Arguments

- client:

  `pyarrow.flight.FlightClient`, as returned by
  [`flight_connect()`](https://arrow.apache.org/docs/r/reference/flight_connect.md)

- data:

  `data.frame`,
  [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
  or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)
  to upload

- path:

  string identifier to store the data under

- overwrite:

  logical: if `path` exists on `client` already, should we replace it
  with the contents of `data`? Default is `TRUE`; if `FALSE` and `path`
  exists, the function will error.

- max_chunksize:

  integer: Maximum number of rows for RecordBatch chunks when a
  `data.frame` is sent. Individual chunks may be smaller depending on
  the chunk layout of individual columns.

## Value

`client`, invisibly.
