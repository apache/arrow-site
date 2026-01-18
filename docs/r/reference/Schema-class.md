<div id="main" class="col-md-9" role="main">

# Schema class

<div class="ref-description section level2">

A `Schema` is an Arrow object containing
[Field](https://arrow.apache.org/docs/r/reference/Field-class.md)s,
which map names to Arrow [data
types](https://arrow.apache.org/docs/r/reference/data-type.md). Create a
`Schema` when you want to convert an R `data.frame` to Arrow but don't
want to rely on the default mapping of R types to Arrow types, such as
when you want to choose a specific numeric precision, or when creating a
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md) and you
want to ensure a specific schema rather than inferring it from the
various files.

Many Arrow objects, including
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md) and
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md), have a
`$schema` method (active binding) that lets you access their schema.

</div>

<div class="section level2">

## Methods

-   `$ToString()`: convert to a string

-   `$field(i)`: returns the field at index `i` (0-based)

-   `$GetFieldByName(x)`: returns the field with name `x`

-   `$WithMetadata(metadata)`: returns a new `Schema` with the key-value
    `metadata` set. Note that all list elements in `metadata` will be
    coerced to `character`.

-   `$code(namespace)`: returns the R code needed to generate this
    schema. Use `namespace=TRUE` to call with `arrow::`.

</div>

<div class="section level2">

## Active bindings

-   `$names`: returns the field names (called in `names(Schema)`)

-   `$num_fields`: returns the number of fields (called in
    `length(Schema)`)

-   `$fields`: returns the list of `Field`s in the `Schema`, suitable
    for iterating over

-   `$HasMetadata`: logical: does this `Schema` have extra metadata?

-   `$metadata`: returns the key-value metadata as a named list. Modify
    or replace by assigning in (`sch$metadata <- new_metadata`). All
    list elements are coerced to string.

</div>

<div class="section level2">

## R Metadata

When converting a data.frame to an Arrow Table or RecordBatch,
attributes from the `data.frame` are saved alongside tables so that the
object can be reconstructed faithfully in R (e.g. with
`as.data.frame()`). This metadata can be both at the top-level of the
`data.frame` (e.g. `attributes(df)`) or at the column (e.g.
`attributes(df$col_a)`) or for list columns only: element level (e.g.
`attributes(df[1, "col_a"])`). For example, this allows for storing
`haven` columns in a table and being able to faithfully re-create them
when pulled back into R. This metadata is separate from the schema
(column names and types) which is compatible with other Arrow clients.
The R metadata is only read by R and is ignored by other clients (e.g.
Pandas has its own custom metadata). This metadata is stored in
`$metadata$r`.

Since Schema metadata keys and values must be strings, this metadata is
saved by serializing R's attribute list structure to a string. If the
serialized metadata exceeds 100Kb in size, by default it is compressed
starting in version 3.0.0. To disable this compression (e.g. for tables
that are compatible with Arrow versions before 3.0.0 and include large
amounts of metadata), set the option `arrow.compress_metadata` to
`FALSE`. Files with compressed metadata are readable by older versions
of arrow, but the metadata is dropped.

</div>

</div>
