<div id="main" class="col-md-9" role="main">

# Define Partitioning for a Dataset

<div class="ref-description section level2">

Pass a `Partitioning` object to a
[FileSystemDatasetFactory](https://arrow.apache.org/docs/r/reference/Dataset.md)'s
`$create()` method to indicate how the file's paths should be
interpreted to define partitioning.

`DirectoryPartitioning` describes how to interpret raw path segments, in
order. For example, `schema(year = int16(), month = int8())` would
define partitions for file paths like "2019/01/file.parquet",
"2019/02/file.parquet", etc. In this scheme `NULL` values will be
skipped. In the previous example: when writing a dataset if the month
was `NA` (or `NULL`), the files would be placed in "2019/file.parquet".
When reading, the rows in "2019/file.parquet" would return an `NA` for
the month column. An error will be raised if an outer directory is
`NULL` and an inner directory is not.

`HivePartitioning` is for Hive-style partitioning, which embeds field
names and values in path segments, such as
"/year=2019/month=2/data.parquet". Because fields are named in the path
segments, order does not matter. This partitioning scheme allows `NULL`
values. They will be replaced by a configurable `null_fallback` which
defaults to the string `"__HIVE_DEFAULT_PARTITION__"` when writing. When
reading, the `null_fallback` string will be replaced with `NA`s as
appropriate.

`PartitioningFactory` subclasses instruct the `DatasetFactory` to detect
partition features from the file paths.

</div>

<div class="section level2">

## Factory

Both `DirectoryPartitioning$create()` and `HivePartitioning$create()`
methods take a
[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md) as a
single input argument. The helper function `hive_partition(...)` is
shorthand for `HivePartitioning$create(schema(...))`.

With `DirectoryPartitioningFactory$create()`, you can provide just the
names of the path segments (in our example, `c("year", "month")`), and
the `DatasetFactory` will infer the data types for those partition
variables. `HivePartitioningFactory$create()` takes no arguments: both
variable names and their types can be inferred from the file paths.
`hive_partition()` with no arguments returns a
`HivePartitioningFactory`.

</div>

</div>
