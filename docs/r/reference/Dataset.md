<div id="main" class="col-md-9" role="main">

# Multi-file datasets

<div class="ref-description section level2">

Arrow Datasets allow you to query against data that has been split
across multiple files. This sharding of data may indicate partitioning,
which can accelerate queries that only touch some partitions (files).

A `Dataset` contains one or more `Fragments`, such as files, of
potentially differing type and partitioning.

For `Dataset$create()`, see `open_dataset()`, which is an alias for it.

`DatasetFactory` is used to provide finer control over the creation of
`Dataset`s.

</div>

<div class="section level2">

## Factory

`DatasetFactory` is used to create a `Dataset`, inspect the
[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md) of
the fragments contained in it, and declare a partitioning.
`FileSystemDatasetFactory` is a subclass of `DatasetFactory` for
discovering files in the local file system, the only currently supported
file system.

For the `DatasetFactory$create()` factory method, see
`dataset_factory()`, an alias for it. A `DatasetFactory` has:

-   `$Inspect(unify_schemas)`: If `unify_schemas` is `TRUE`, all
    fragments will be scanned and a unified
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
    will be created from them; if `FALSE` (default), only the first
    fragment will be inspected for its schema. Use this fast path when
    you know and trust that all fragments have an identical schema.

-   `$Finish(schema, unify_schemas)`: Returns a `Dataset`. If `schema`
    is provided, it will be used for the `Dataset`; if omitted, a
    `Schema` will be created from inspecting the fragments (files) in
    the dataset, following `unify_schemas` as described above.

`FileSystemDatasetFactory$create()` is a lower-level factory method and
takes the following arguments:

-   `filesystem`: A
    [FileSystem](https://arrow.apache.org/docs/r/reference/FileSystem.md)

-   `selector`: Either a
    [FileSelector](https://arrow.apache.org/docs/r/reference/FileSelector.md)
    or `NULL`

-   `paths`: Either a character vector of file paths or `NULL`

-   `format`: A
    [FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)

-   `partitioning`: Either `Partitioning`, `PartitioningFactory`, or
    `NULL`

</div>

<div class="section level2">

## Methods

A `Dataset` has the following methods:

-   `$NewScan()`: Returns a
    [ScannerBuilder](https://arrow.apache.org/docs/r/reference/Scanner.md)
    for building a query

-   `$WithSchema()`: Returns a new Dataset with the specified schema.
    This method currently supports only adding, removing, or reordering
    fields in the schema: you cannot alter or cast the field types.

-   `$schema`: Active binding that returns the
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
    of the Dataset; you may also replace the dataset's schema by using
    `ds$schema <- new_schema`.

`FileSystemDataset` has the following methods:

-   `$files`: Active binding, returns the files of the
    `FileSystemDataset`

-   `$format`: Active binding, returns the
    [FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)
    of the `FileSystemDataset`

`UnionDataset` has the following methods:

-   `$children`: Active binding, returns all child `Dataset`s.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`open_dataset()` for a simple interface to creating a `Dataset`

</div>

</div>

</div>
