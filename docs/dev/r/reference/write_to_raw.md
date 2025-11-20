<div id="main" class="col-md-9" role="main">

# Write Arrow data to a raw vector

<div class="ref-description section level2">

`write_ipc_stream()` and `write_feather()` write data to a sink and
return the data (`data.frame`, `RecordBatch`, or `Table`) they were
given. This function wraps those so that you can serialize data to a
buffer and access that buffer as a `raw` vector in R.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_to_raw(x, format = c("stream", "file"))
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    `data.frame`,
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
    or [Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

-   format:

    one of `c("stream", "file")`, indicating the IPC format to use

</div>

<div class="section level2">

## Value

A `raw` vector containing the bytes of the IPC serialized data.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# The default format is "stream"
mtcars_raw <- write_to_raw(mtcars)
```

</div>

</div>

</div>
