<div id="main" class="col-md-9" role="main">

# Write a dataset

<div class="ref-description section level2">

This function allows you to write a dataset. By writing to more
efficient binary storage formats, and by specifying relevant
partitioning, you can make it much faster to read and query.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
write_dataset(
  dataset,
  path,
  format = c("parquet", "feather", "arrow", "ipc", "csv", "tsv", "txt", "text"),
  partitioning = dplyr::group_vars(dataset),
  basename_template = paste0("part-{i}.", as.character(format)),
  hive_style = TRUE,
  existing_data_behavior = c("overwrite", "error", "delete_matching"),
  max_partitions = 1024L,
  max_open_files = 900L,
  max_rows_per_file = 0L,
  min_rows_per_group = 0L,
  max_rows_per_group = bitwShiftL(1, 20),
  create_directory = TRUE,
  ...
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

-   format:

    a string identifier of the file format. Default is to use "parquet"
    (see
    [FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md))

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

-   create_directory:

    whether to create the directories written into. Requires appropriate
    permissions on the storage backend. If set to FALSE, directories are
    assumed to be already present if writing on a classic hierarchical
    filesystem. Default is TRUE

-   ...:

    additional format-specific arguments. For available Parquet options,
    see `write_parquet()`. The available Feather options are:

    -   `use_legacy_format` logical: write data formatted so that Arrow
        libraries versions 0.14 and lower can read it. Default is
        `FALSE`. You can also enable this by setting the environment
        variable `ARROW_PRE_0_15_IPC_FORMAT=1`.

    -   `metadata_version`: A string like "V5" or the equivalent integer
        indicating the Arrow IPC MetadataVersion. Default (`NULL`) will
        use the latest version, unless the environment variable
        `ARROW_PRE_1_0_METADATA_VERSION=1`, in which case it will be V4.

    -   `codec`: A
        [Codec](https://arrow.apache.org/docs/r/reference/Codec.md)
        which will be used to compress body buffers of written files.
        Default (NULL) will not compress body buffers.

    -   `null_fallback`: character to be used in place of missing values
        (`NA` or `NULL`) when using Hive-style partitioning. See
        `hive_partition()`.

</div>

<div class="section level2">

## Value

The input `dataset`, invisibly

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# You can write datasets partitioned by the values in a column (here: "cyl").
# This creates a structure of the form cyl=X/part-Z.parquet.
one_level_tree <- tempfile()
write_dataset(mtcars, one_level_tree, partitioning = "cyl")
list.files(one_level_tree, recursive = TRUE)
#> [1] "cyl=4/part-0.parquet" "cyl=6/part-0.parquet" "cyl=8/part-0.parquet"

# You can also partition by the values in multiple columns
# (here: "cyl" and "gear").
# This creates a structure of the form cyl=X/gear=Y/part-Z.parquet.
two_levels_tree <- tempfile()
write_dataset(mtcars, two_levels_tree, partitioning = c("cyl", "gear"))
list.files(two_levels_tree, recursive = TRUE)
#> [1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
#> [3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
#> [5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
#> [7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"

# In the two previous examples we would have:
# X = {4,6,8}, the number of cylinders.
# Y = {3,4,5}, the number of forward gears.
# Z = {0,1,2}, the number of saved parts, starting from 0.

# You can obtain the same result as as the previous examples using arrow with
# a dplyr pipeline. This will be the same as two_levels_tree above, but the
# output directory will be different.
library(dplyr)
two_levels_tree_2 <- tempfile()
mtcars |>
  group_by(cyl, gear) |>
  write_dataset(two_levels_tree_2)
list.files(two_levels_tree_2, recursive = TRUE)
#> [1] "cyl=4/gear=3/part-0.parquet" "cyl=4/gear=4/part-0.parquet"
#> [3] "cyl=4/gear=5/part-0.parquet" "cyl=6/gear=3/part-0.parquet"
#> [5] "cyl=6/gear=4/part-0.parquet" "cyl=6/gear=5/part-0.parquet"
#> [7] "cyl=8/gear=3/part-0.parquet" "cyl=8/gear=5/part-0.parquet"

# And you can also turn off the Hive-style directory naming where the column
# name is included with the values by using `hive_style = FALSE`.

# Write a structure X/Y/part-Z.parquet.
two_levels_tree_no_hive <- tempfile()
mtcars |>
  group_by(cyl, gear) |>
  write_dataset(two_levels_tree_no_hive, hive_style = FALSE)
list.files(two_levels_tree_no_hive, recursive = TRUE)
#> [1] "4/3/part-0.parquet" "4/4/part-0.parquet" "4/5/part-0.parquet"
#> [4] "6/3/part-0.parquet" "6/4/part-0.parquet" "6/5/part-0.parquet"
#> [7] "8/3/part-0.parquet" "8/5/part-0.parquet"
```

</div>

</div>

</div>
