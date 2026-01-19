<div id="main" class="col-md-9" role="main">

# ParquetWriterProperties class

<div class="ref-description section level2">

This class holds settings to control how a Parquet file is read by
[ParquetFileWriter](https://arrow.apache.org/docs/r/reference/ParquetFileWriter.md).

</div>

<div class="section level2">

## Details

The parameters `compression`, `compression_level`, `use_dictionary` and
write_statistics\` support various patterns:

-   The default `NULL` leaves the parameter unspecified, and the C++
    library uses an appropriate default for each column (defaults listed
    above)

-   A single, unnamed, value (e.g. a single string for `compression`)
    applies to all columns

-   An unnamed vector, of the same size as the number of columns, to
    specify a value for each column, in positional order

-   A named vector, to specify the value for the named columns, the
    default value for the setting is used when not supplied

Unlike the high-level
[write_parquet](https://arrow.apache.org/docs/r/reference/write_parquet.md),
`ParquetWriterProperties` arguments use the C++ defaults. Currently this
means "uncompressed" rather than "snappy" for the `compression`
argument.

</div>

<div class="section level2">

## Factory

The `ParquetWriterProperties$create()` factory method instantiates the
object and takes the following arguments:

-   `table`: table to write (required)

-   `version`: Parquet version, "1.0" or "2.0". Default "1.0"

-   `compression`: Compression type, algorithm `"uncompressed"`

-   `compression_level`: Compression level; meaning depends on
    compression algorithm

-   `use_dictionary`: Specify if we should use dictionary encoding.
    Default `TRUE`

-   `write_statistics`: Specify if we should write statistics. Default
    `TRUE`

-   `data_page_size`: Set a target threshold for the approximate encoded
    size of data pages within a column chunk (in bytes). Default 1 MiB.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[write_parquet](https://arrow.apache.org/docs/r/reference/write_parquet.md)

[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md) for
information about schemas and metadata handling.

</div>

</div>

</div>
