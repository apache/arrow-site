<div id="main" class="col-md-9" role="main">

# Open a multi-file dataset of CSV or other delimiter-separated format

<div class="ref-description section level2">

A wrapper around
[open_dataset](https://arrow.apache.org/docs/r/reference/open_dataset.md)
which explicitly includes parameters mirroring `read_csv_arrow()`,
`read_delim_arrow()`, and `read_tsv_arrow()` to allow for easy switching
between functions for opening single files and functions for opening
datasets.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
open_delim_dataset(
  sources,
  schema = NULL,
  partitioning = hive_partition(),
  hive_style = NA,
  unify_schemas = NULL,
  factory_options = list(),
  delim = ",",
  quote = "\"",
  escape_double = TRUE,
  escape_backslash = FALSE,
  col_names = TRUE,
  col_types = NULL,
  na = c("", "NA"),
  skip_empty_rows = TRUE,
  skip = 0L,
  convert_options = NULL,
  read_options = NULL,
  timestamp_parsers = NULL,
  quoted_na = TRUE,
  parse_options = NULL
)

open_csv_dataset(
  sources,
  schema = NULL,
  partitioning = hive_partition(),
  hive_style = NA,
  unify_schemas = NULL,
  factory_options = list(),
  quote = "\"",
  escape_double = TRUE,
  escape_backslash = FALSE,
  col_names = TRUE,
  col_types = NULL,
  na = c("", "NA"),
  skip_empty_rows = TRUE,
  skip = 0L,
  convert_options = NULL,
  read_options = NULL,
  timestamp_parsers = NULL,
  quoted_na = TRUE,
  parse_options = NULL
)

open_tsv_dataset(
  sources,
  schema = NULL,
  partitioning = hive_partition(),
  hive_style = NA,
  unify_schemas = NULL,
  factory_options = list(),
  quote = "\"",
  escape_double = TRUE,
  escape_backslash = FALSE,
  col_names = TRUE,
  col_types = NULL,
  na = c("", "NA"),
  skip_empty_rows = TRUE,
  skip = 0L,
  convert_options = NULL,
  read_options = NULL,
  timestamp_parsers = NULL,
  quoted_na = TRUE,
  parse_options = NULL
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   sources:

    One of:

    -   a string path or URI to a directory containing data files

    -   a
        [FileSystem](https://arrow.apache.org/docs/r/reference/FileSystem.md)
        that references a directory containing data files (such as what
        is returned by `s3_bucket()`)

    -   a string path or URI to a single file

    -   a character vector of paths or URIs to individual data files

    -   a list of `Dataset` objects as created by this function

    -   a list of `DatasetFactory` objects as created by
        `dataset_factory()`.

    When `sources` is a vector of file URIs, they must all use the same
    protocol and point to files located in the same file system and
    having the same format.

-   schema:

    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
    for the `Dataset`. If `NULL` (the default), the schema will be
    inferred from the data sources.

-   partitioning:

    When `sources` is a directory path/URI, one of:

    -   a `Schema`, in which case the file paths relative to `sources`
        will be parsed, and path segments will be matched with the
        schema fields.

    -   a character vector that defines the field names corresponding to
        those path segments (that is, you're providing the names that
        would correspond to a `Schema` but the types will be
        autodetected)

    -   a `Partitioning` or `PartitioningFactory`, such as returned by
        `hive_partition()`

    -   `NULL` for no partitioning

    The default is to autodetect Hive-style partitions unless
    `hive_style = FALSE`. See the "Partitioning" section for details.
    When `sources` is not a directory path/URI, `partitioning` is
    ignored.

-   hive_style:

    Logical: should `partitioning` be interpreted as Hive-style? Default
    is `NA`, which means to inspect the file paths for Hive-style
    partitioning and behave accordingly.

-   unify_schemas:

    logical: should all data fragments (files, `Dataset`s) be scanned in
    order to create a unified schema from them? If `FALSE`, only the
    first fragment will be inspected for its schema. Use this fast path
    when you know and trust that all fragments have an identical schema.
    The default is `FALSE` when creating a dataset from a directory
    path/URI or vector of file paths/URIs (because there may be many
    files and scanning may be slow) but `TRUE` when `sources` is a list
    of `Dataset`s (because there should be few `Dataset`s in the list
    and their `Schema`s are already in memory).

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

-   delim:

    Single character used to separate fields within a record.

-   quote:

    Single character used to quote strings.

-   escape_double:

    Does the file escape quotes by doubling them? i.e. If this option is
    `TRUE`, the value `""""` represents a single quote, `\"`.

-   escape_backslash:

    Does the file use backslashes to escape special characters? This is
    more general than `escape_double` as backslashes can be used to
    escape the delimiter character, the quote character, or to add
    special characters like `\\n`.

-   col_names:

    If `TRUE`, the first row of the input will be used as the column
    names and will not be included in the data frame. If `FALSE`, column
    names will be generated by Arrow, starting with "f0", "f1", ...,
    "fN". Alternatively, you can specify a character vector of column
    names.

-   col_types:

    A compact string representation of the column types, an Arrow
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md),
    or `NULL` (the default) to infer types from the data.

-   na:

    A character vector of strings to interpret as missing values.

-   skip_empty_rows:

    Should blank rows be ignored altogether? If `TRUE`, blank rows will
    not be represented at all. If `FALSE`, they will be filled with
    missings.

-   skip:

    Number of lines to skip before reading data.

-   convert_options:

    see [CSV conversion
    options](https://arrow.apache.org/docs/r/reference/csv_convert_options.md)

-   read_options:

    see [CSV reading
    options](https://arrow.apache.org/docs/r/reference/csv_read_options.md)

-   timestamp_parsers:

    User-defined timestamp parsers. If more than one parser is
    specified, the CSV conversion logic will try parsing values starting
    from the beginning of this vector. Possible values are:

    -   `NULL`: the default, which uses the ISO-8601 parser

    -   a character vector of
        [strptime](https://rdrr.io/r/base/strptime.html) parse strings

    -   a list of
        [TimestampParser](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
        objects

-   quoted_na:

    Should missing values inside quotes be treated as missing values
    (the default) or strings. (Note that this is different from the the
    Arrow C++ default for the corresponding convert option,
    `strings_can_be_null`.)

-   parse_options:

    see [CSV parsing
    options](https://arrow.apache.org/docs/r/reference/csv_parse_options.md).
    If given, this overrides any parsing options provided in other
    arguments (e.g. `delim`, `quote`, etc.).

</div>

<div class="section level2">

## Options currently supported by `read_delim_arrow()` which are not supported here

-   `file` (instead, please specify files in `sources`)

-   `col_select` (instead, subset columns after dataset creation)

-   `as_data_frame` (instead, convert to data frame after dataset
    creation)

-   `parse_options`

</div>

<div class="section level2">

## See also

<div class="dont-index">

`open_dataset()`

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Set up directory for examples
tf <- tempfile()
dir.create(tf)

df <- data.frame(x = c("1", "2", "NULL"))
file_path <- file.path(tf, "file1.txt")
write.table(df, file_path, sep = ",", row.names = FALSE)

# Use readr-style params identically in both `read_csv_dataset()` and `open_csv_dataset()`
read_csv_arrow(file_path, na = c("", "NA", "NULL"), col_names = "y", skip = 1)
#> # A tibble: 3 x 1
#>       y
#>   <int>
#> 1     1
#> 2     2
#> 3    NA
open_csv_dataset(file_path, na = c("", "NA", "NULL"), col_names = "y", skip = 1)
#> FileSystemDataset with 1 csv file
#> 1 columns
#> y: int64

# Use `col_types` to specify a schema, partial schema, or compact representation
tf2 <- tempfile()
write_csv_dataset(cars, tf2)

open_csv_dataset(tf2, col_types = schema(speed = int32(), dist = int32()))
#> FileSystemDataset with 1 csv file
#> 2 columns
#> speed: int32
#> dist: int32
open_csv_dataset(tf2, col_types = schema(speed = int32()))
#> FileSystemDataset with 1 csv file
#> 2 columns
#> speed: int32
#> dist: int64
open_csv_dataset(tf2, col_types = "ii", col_names = c("speed", "dist"), skip = 1)
#> FileSystemDataset with 1 csv file
#> 2 columns
#> speed: int32
#> dist: int32
```

</div>

</div>

</div>
