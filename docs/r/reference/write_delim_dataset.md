<div id="main" class="col-md-9" role="main">

# Write a dataset into partitioned flat files.

<div class="ref-description section level2">

The `write_*_dataset()` are a family of wrappers around
[write_dataset](https://arrow.apache.org/docs/r/reference/write_dataset.md)
to allow for easy switching between functions for writing datasets.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_delim_dataset(
  dataset,
  path,
  partitioning = dplyr::group_vars(dataset),
  basename_template = "part-{i}.txt",
  hive_style = TRUE,
  existing_data_behavior = c("overwrite", "error", "delete_matching"),
  max_partitions = 1024L,
  max_open_files = 900L,
  max_rows_per_file = 0L,
  min_rows_per_group = 0L,
  max_rows_per_group = bitwShiftL(1, 20),
  col_names = TRUE,
  batch_size = 1024L,
  delim = ",",
  na = "",
  eol = "\n",
  quote = c("needed", "all", "none")
)

write_csv_dataset(
  dataset,
  path,
  partitioning = dplyr::group_vars(dataset),
  basename_template = "part-{i}.csv",
  hive_style = TRUE,
  existing_data_behavior = c("overwrite", "error", "delete_matching"),
  max_partitions = 1024L,
  max_open_files = 900L,
  max_rows_per_file = 0L,
  min_rows_per_group = 0L,
  max_rows_per_group = bitwShiftL(1, 20),
  col_names = TRUE,
  batch_size = 1024L,
  delim = ",",
  na = "",
  eol = "\n",
  quote = c("needed", "all", "none")
)

write_tsv_dataset(
  dataset,
  path,
  partitioning = dplyr::group_vars(dataset),
  basename_template = "part-{i}.tsv",
  hive_style = TRUE,
  existing_data_behavior = c("overwrite", "error", "delete_matching"),
  max_partitions = 1024L,
  max_open_files = 900L,
  max_rows_per_file = 0L,
  min_rows_per_group = 0L,
  max_rows_per_group = bitwShiftL(1, 20),
  col_names = TRUE,
  batch_size = 1024L,
  na = "",
  eol = "\n",
  quote = c("needed", "all", "none")
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   dataset:

    [Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md),
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md),
    `arrow_dplyr_query`, or `data.frame`. If an `arrow_dplyr_query`, the
    query will be evaluated and the result will be written. This means
    that you can `select()`, `filter()`, `mutate()`, etc. to transform
    the data before it is written if you need to.

-   path:

    string path, URI, or `SubTreeFileSystem` referencing a directory to
    write to (directory will be created if it does not exist)

-   partitioning:

    `Partitioning` or a character vector of columns to use as partition
    keys (to be written as path segments). Default is to use the current
    `group_by()` columns.

-   basename_template:

    string template for the names of files to be written. Must contain
    `"{i}"`, which will be replaced with an autoincremented integer to
    generate basenames of datafiles. For example, `"part-{i}.arrow"`
    will yield `"part-0.arrow", ...`. If not specified, it defaults to
    `"part-{i}.<default extension>"`.

-   hive_style:

    logical: write partition segments as Hive-style
    (`key1=value1/key2=value2/file.ext`) or as just bare values. Default
    is `TRUE`.

-   existing_data_behavior:

    The behavior to use when there is already data in the destination
    directory. Must be one of "overwrite", "error", or
    "delete_matching".

    -   "overwrite" (the default) then any new files created will
        overwrite existing files

    -   "error" then the operation will fail if the destination
        directory is not empty

    -   "delete_matching" then the writer will delete any existing
        partitions if data is going to be written to those partitions
        and will leave alone partitions which data is not written to.

-   max_partitions:

    maximum number of partitions any batch may be written into. Default
    is 1024L.

-   max_open_files:

    maximum number of files that can be left opened during a write
    operation. If greater than 0 then this will limit the maximum number
    of files that can be left open. If an attempt is made to open too
    many files then the least recently used file will be closed. If this
    setting is set too low you may end up fragmenting your data into
    many small files. The default is 900 which also allows some \# of
    files to be open by the scanner before hitting the default Linux
    limit of 1024.

-   max_rows_per_file:

    maximum number of rows per file. If greater than 0 then this will
    limit how many rows are placed in any single file. Default is 0L.

-   min_rows_per_group:

    write the row groups to the disk when this number of rows have
    accumulated. Default is 0L.

-   max_rows_per_group:

    maximum rows allowed in a single group and when this number of rows
    is exceeded, it is split and the next set of rows is written to the
    next group. This value must be set such that it is greater than
    `min_rows_per_group`. Default is 1024 \* 1024.

-   col_names:

    Whether to write an initial header line with column names.

-   batch_size:

    Maximum number of rows processed at a time. Default is 1024L.

-   delim:

    Delimiter used to separate values. Defaults to `","` for
    `write_delim_dataset()` and `write_csv_dataset()`, and `"\t` for
    `write_tsv_dataset()`. Cannot be changed for `write_tsv_dataset()`.

-   na:

    a character vector of strings to interpret as missing values. Quotes
    are not allowed in this string. The default is an empty string `""`.

-   eol:

    the end of line character to use for ending rows. The default is
    `"\n"`.

-   quote:

    How to handle fields which contain characters that need to be
    quoted.

    -   `needed` - Enclose all strings and binary values in quotes which
        need them, because their CSV rendering can contain quotes itself
        (the default)

    -   `all` - Enclose all valid values in quotes. Nulls are not
        quoted. May cause readers to interpret all values as strings if
        schema is inferred.

    -   `none` - Do not enclose any values in quotes. Prevents values
        from containing quotes ("), cell delimiters (,) or line endings
        (\\r, \\n), (following RFC4180). If values contain these
        characters, an error is caused when attempting to write.

</div>

<div class="section level2">

## Value

The input `dataset`, invisibly.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`write_dataset()`

</div>

</div>

</div>
