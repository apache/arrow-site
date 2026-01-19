<div id="main" class="col-md-9" role="main">

# Open a multi-file dataset

<div class="ref-description section level2">

Arrow Datasets allow you to query against data that has been split
across multiple files. This sharding of data may indicate partitioning,
which can accelerate queries that only touch some partitions (files).
Call `open_dataset()` to point to a directory of data files and return a
`Dataset`, then use `dplyr` methods to query it.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
open_dataset(
  sources,
  schema = NULL,
  partitioning = hive_partition(),
  hive_style = NA,
  unify_schemas = NULL,
  format = c("parquet", "arrow", "ipc", "feather", "csv", "tsv", "text", "json"),
  factory_options = list(),
  ...
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

-   format:

    A
    [FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)
    object, or a string identifier of the format of the files in `x`.
    This argument is ignored when `sources` is a list of `Dataset`
    objects. Currently supported values:

    -   "parquet"

    -   "ipc"/"arrow"/"feather", all aliases for each other; for
        Feather, note that only version 2 files are supported

    -   "csv"/"text", aliases for the same thing (because comma is the
        default delimiter for text files

    -   "tsv", equivalent to passing `format = "text", delimiter = "\t"`

    -   "json", for JSON format datasets Note: only newline-delimited
        JSON (aka ND-JSON) datasets are currently supported Default is
        "parquet", unless a `delimiter` is also specified, in which case
        it is assumed to be "text".

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

    additional arguments passed to `dataset_factory()` when `sources` is
    a directory path/URI or vector of file paths/URIs, otherwise
    ignored. These may include `format` to indicate the file format, or
    other format-specific options (see `read_csv_arrow()`,
    `read_parquet()` and `read_feather()` on how to specify these).

</div>

<div class="section level2">

## Value

A [Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md) R6
object. Use `dplyr` methods on it to query the data, or call
`$NewScan()` to construct a query directly.

</div>

<div class="section level2">

## Partitioning

Data is often split into multiple files and nested in subdirectories
based on the value of one or more columns in the data. It may be a
column that is commonly referenced in queries, or it may be time-based,
for some examples. Data that is divided this way is "partitioned," and
the values for those partitioning columns are encoded into the file path
segments. These path segments are effectively virtual columns in the
dataset, and because their values are known prior to reading the files
themselves, we can greatly speed up filtered queries by skipping some
files entirely.

Arrow supports reading partition information from file paths in two
forms:

-   "Hive-style", deriving from the Apache Hive project and common to
    some database systems. Partitions are encoded as "key=value" in path
    segments, such as `"year=2019/month=1/file.parquet"`. While they may
    be awkward as file names, they have the advantage of being
    self-describing.

-   "Directory" partitioning, which is Hive without the key names, like
    `"2019/01/file.parquet"`. In order to use these, we need know at
    least what names to give the virtual columns that come from the path
    segments.

The default behavior in `open_dataset()` is to inspect the file paths
contained in the provided directory, and if they look like Hive-style,
parse them as Hive. If your dataset has Hive-style partitioning in the
file paths, you do not need to provide anything in the `partitioning`
argument to `open_dataset()` to use them. If you do provide a character
vector of partition column names, they will be ignored if they match
what is detected, and if they don't match, you'll get an error. (If you
want to rename partition columns, do that using `select()` or `rename()`
after opening the dataset.). If you provide a `Schema` and the names
match what is detected, it will use the types defined by the Schema. In
the example file path above, you could provide a Schema to specify that
"month" should be `int8()` instead of the `int32()` it will be parsed as
by default.

If your file paths do not appear to be Hive-style, or if you pass
`hive_style = FALSE`, the `partitioning` argument will be used to create
Directory partitioning. A character vector of names is required to
create partitions; you may instead provide a `Schema` to map those names
to desired column types, as described above. If neither are provided, no
partitioning information will be taken from the file paths.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[datasets
article](https://arrow.apache.org/docs/r/articles/dataset.html)

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Set up directory for examples
tf <- tempfile()
dir.create(tf)

write_dataset(mtcars, tf, partitioning = "cyl")

# You can specify a directory containing the files for your dataset and
# open_dataset will scan all files in your directory.
open_dataset(tf)
#> FileSystemDataset with 3 Parquet files
#> 11 columns
#> mpg: double
#> disp: double
#> hp: double
#> drat: double
#> wt: double
#> qsec: double
#> vs: double
#> am: double
#> gear: double
#> carb: double
#> cyl: int32
#> 
#> See $metadata for additional Schema metadata

# You can also supply a vector of paths
open_dataset(c(file.path(tf, "cyl=4/part-0.parquet"), file.path(tf, "cyl=8/part-0.parquet")))
#> FileSystemDataset with 2 Parquet files
#> 10 columns
#> mpg: double
#> disp: double
#> hp: double
#> drat: double
#> wt: double
#> qsec: double
#> vs: double
#> am: double
#> gear: double
#> carb: double
#> 
#> See $metadata for additional Schema metadata

## You must specify the file format if using a format other than parquet.
tf2 <- tempfile()
dir.create(tf2)
write_dataset(mtcars, tf2, format = "ipc")
# This line will results in errors when you try to work with the data
if (FALSE) { # \dontrun{
open_dataset(tf2)
} # }
# This line will work
open_dataset(tf2, format = "ipc")
#> FileSystemDataset with 1 Feather file
#> 11 columns
#> mpg: double
#> cyl: double
#> disp: double
#> hp: double
#> drat: double
#> wt: double
#> qsec: double
#> vs: double
#> am: double
#> gear: double
#> carb: double
#> 
#> See $metadata for additional Schema metadata

## You can specify file partitioning to include it as a field in your dataset
# Create a temporary directory and write example dataset
tf3 <- tempfile()
dir.create(tf3)
write_dataset(airquality, tf3, partitioning = c("Month", "Day"), hive_style = FALSE)

# View files - you can see the partitioning means that files have been written
# to folders based on Month/Day values
tf3_files <- list.files(tf3, recursive = TRUE)

# With no partitioning specified, dataset contains all files but doesn't include
# directory names as field names
open_dataset(tf3)
#> FileSystemDataset with 153 Parquet files
#> 4 columns
#> Ozone: int32
#> Solar.R: int32
#> Wind: double
#> Temp: int32
#> 
#> See $metadata for additional Schema metadata

# Now that partitioning has been specified, your dataset contains columns for Month and Day
open_dataset(tf3, partitioning = c("Month", "Day"))
#> FileSystemDataset with 153 Parquet files
#> 6 columns
#> Ozone: int32
#> Solar.R: int32
#> Wind: double
#> Temp: int32
#> Month: int32
#> Day: int32
#> 
#> See $metadata for additional Schema metadata

# If you want to specify the data types for your fields, you can pass in a Schema
open_dataset(tf3, partitioning = schema(Month = int8(), Day = int8()))
#> FileSystemDataset with 153 Parquet files
#> 6 columns
#> Ozone: int32
#> Solar.R: int32
#> Wind: double
#> Temp: int32
#> Month: int8
#> Day: int8
#> 
#> See $metadata for additional Schema metadata
```

</div>

</div>

</div>
