<div id="main" class="col-md-9" role="main">

# Format-specific scan options

<div class="ref-description section level2">

A `FragmentScanOptions` holds options specific to a `FileFormat` and a
scan operation.

</div>

<div class="section level2">

## Factory

`FragmentScanOptions$create()` takes the following arguments:

-   `format`: A string identifier of the file format. Currently
    supported values:

    -   "parquet"

    -   "csv"/"text", aliases for the same format.

-   `...`: Additional format-specific options

    `format = "parquet"`:

    -   `use_buffered_stream`: Read files through buffered input streams
        rather than loading entire row groups at once. This may be
        enabled to reduce memory overhead. Disabled by default.

    -   `buffer_size`: Size of buffered stream, if enabled. Default is
        8KB.

    -   `pre_buffer`: Pre-buffer the raw Parquet data. This can improve
        performance on high-latency filesystems. Disabled by default.

    -   `thrift_string_size_limit`: Maximum string size allocated for
        decoding thrift strings. May need to be increased in order to
        read files with especially large headers. Default value
        100000000.

    -   `thrift_container_size_limit`: Maximum size of thrift
        containers. May need to be increased in order to read files with
        especially large headers. Default value 1000000.
        `format = "text"`: see
        [CsvConvertOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md).
        Note that options can only be specified with the Arrow C++
        library naming. Also, "block_size" from
        [CsvReadOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
        may be given.

It returns the appropriate subclass of `FragmentScanOptions` (e.g.
`CsvFragmentScanOptions`).

</div>

</div>
