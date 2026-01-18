<div id="main" class="col-md-9" role="main">

# Dataset file formats

<div class="ref-description section level2">

A `FileFormat` holds information about how to read and parse the files
included in a `Dataset`. There are subclasses corresponding to the
supported file formats (`ParquetFileFormat` and `IpcFileFormat`).

</div>

<div class="section level2">

## Factory

`FileFormat$create()` takes the following arguments:

-   `format`: A string identifier of the file format. Currently
    supported values:

    -   "parquet"

    -   "ipc"/"arrow"/"feather", all aliases for each other; for
        Feather, note that only version 2 files are supported

    -   "csv"/"text", aliases for the same thing (because comma is the
        default delimiter for text files

    -   "tsv", equivalent to passing `format = "text", delimiter = "\t"`

-   `...`: Additional format-specific options

    `format = "parquet"`:

    -   `dict_columns`: Names of columns which should be read as
        dictionaries.

    -   Any Parquet options from
        [FragmentScanOptions](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md).

    `format = "text"`: see
    [CsvParseOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md).
    Note that you can specify them either with the Arrow C++ library
    naming ("delimiter", "quoting", etc.) or the `readr`-style naming
    used in `read_csv_arrow()` ("delim", "quote", etc.). Not all `readr`
    options are currently supported; please file an issue if you
    encounter one that `arrow` should support. Also, the following
    options are supported. From
    [CsvReadOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md):

    -   `skip_rows`

    -   `column_names`. Note that if a
        [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
        is specified, `column_names` must match those specified in the
        schema.

    -   `autogenerate_column_names` From
        [CsvFragmentScanOptions](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md)
        (these values can be overridden at scan time):

    -   `convert_options`: a
        [CsvConvertOptions](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)

    -   `block_size`

It returns the appropriate subclass of `FileFormat` (e.g.
`ParquetFileFormat`)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
## Semi-colon delimited files
# Set up directory for examples
tf <- tempfile()
dir.create(tf)
on.exit(unlink(tf))
write.table(mtcars, file.path(tf, "file1.txt"), sep = ";", row.names = FALSE)

# Create FileFormat object
format <- FileFormat$create(format = "text", delimiter = ";")

open_dataset(tf, format = format)
#> FileSystemDataset with 1 csv file
#> 11 columns
#> mpg: double
#> cyl: int64
#> disp: double
#> hp: int64
#> drat: double
#> wt: double
#> qsec: double
#> vs: int64
#> am: int64
#> gear: int64
#> carb: int64
```

</div>

</div>

</div>
