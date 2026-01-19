<div id="main" class="col-md-9" role="main">

# Create a DatasetFactory

<div class="ref-description section level2">

A [Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md) can
constructed using one or more
[DatasetFactory](https://arrow.apache.org/docs/r/reference/Dataset.md)s.
This function helps you construct a `DatasetFactory` that you can pass
to `open_dataset()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
dataset_factory(
  x,
  filesystem = NULL,
  format = c("parquet", "arrow", "ipc", "feather", "csv", "tsv", "text", "json"),
  partitioning = NULL,
  hive_style = NA,
  factory_options = list(),
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    A string path to a directory containing data files, a vector of one
    one or more string paths to data files, or a list of
    `DatasetFactory` objects whose datasets should be combined. If this
    argument is specified it will be used to construct a
    `UnionDatasetFactory` and other arguments will be ignored.

-   filesystem:

    A
    [FileSystem](https://arrow.apache.org/docs/r/reference/FileSystem.md)
    object; if omitted, the `FileSystem` will be detected from `x`

-   format:

    A
    [FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)
    object, or a string identifier of the format of the files in `x`.
    Currently supported values:

    -   "parquet"

    -   "ipc"/"arrow"/"feather", all aliases for each other; for
        Feather, note that only version 2 files are supported

    -   "csv"/"text", aliases for the same thing (because comma is the
        default delimiter for text files

    -   "tsv", equivalent to passing `format = "text", delimiter = "\t"`

    Default is "parquet", unless a `delimiter` is also specified, in
    which case it is assumed to be "text".

-   partitioning:

    One of

    -   A `Schema`, in which case the file paths relative to `sources`
        will be parsed, and path segments will be matched with the
        schema fields. For example,
        `schema(year = int16(), month = int8())` would create partitions
        for file paths like "2019/01/file.parquet",
        "2019/02/file.parquet", etc.

    -   A character vector that defines the field names corresponding to
        those path segments (that is, you're providing the names that
        would correspond to a `Schema` but the types will be
        autodetected)

    -   A `HivePartitioning` or `HivePartitioningFactory`, as returned
        by `hive_partition()` which parses explicit or autodetected
        fields from Hive-style path segments

    -   `NULL` for no partitioning

-   hive_style:

    Logical: if `partitioning` is a character vector or a `Schema`,
    should it be interpreted as specifying Hive-style partitioning?
    Default is `NA`, which means to inspect the file paths for
    Hive-style partitioning and behave accordingly.

-   factory_options:

    list of optional FileSystemFactoryOptions:

    -   `partition_base_dir`: string path segment prefix to ignore when
        discovering partition information with DirectoryPartitioning.
        Not meaningful (ignored with a warning) for HivePartitioning,
        nor is it valid when providing a vector of file paths.

    -   `exclude_invalid_files`: logical: should files that are not
        valid data files be excluded? Default is `FALSE` because
        checking all files up front incurs I/O and thus will be slower,
        especially on remote filesystems. If false and there are invalid
        files, there will be an error at scan time. This is the only
        FileSystemFactoryOption that is valid for both when providing a
        directory path in which to discover files and when providing a
        vector of file paths.

    -   `selector_ignore_prefixes`: character vector of file prefixes to
        ignore when discovering files in a directory. If invalid files
        can be excluded by a common filename prefix this way, you can
        avoid the I/O cost of `exclude_invalid_files`. Not valid when
        providing a vector of file paths (but if you're providing the
        file list, you can filter invalid files yourself).

-   ...:

    Additional format-specific options, passed to `FileFormat$create()`.
    For CSV options, note that you can specify them either with the
    Arrow C++ library naming ("delimiter", "quoting", etc.) or the
    `readr`-style naming used in `read_csv_arrow()` ("delim", "quote",
    etc.). Not all `readr` options are currently supported; please file
    an issue if you encounter one that `arrow` should support.

</div>

<div class="section level2">

## Value

A `DatasetFactory` object. Pass this to `open_dataset()`, in a list
potentially with other `DatasetFactory` objects, to create a `Dataset`.

</div>

<div class="section level2">

## Details

If you would only have a single `DatasetFactory` (for example, you have
a single directory containing Parquet files), you can call
`open_dataset()` directly. Use `dataset_factory()` when you want to
combine different directories, file systems, or file formats.

</div>

</div>
