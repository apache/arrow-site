<div id="main" class="col-md-9" role="main">

# Table class

<div class="ref-description section level2">

A Table is a sequence of [chunked
arrays](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md).
They have a similar interface to [record
batches](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md),
but they can be composed from multiple record batches or chunked arrays.

</div>

<div class="section level2">

## S3 Methods and Usage

Tables are data-frame-like, and many methods you expect to work on a
`data.frame` are implemented for `Table`. This includes `[`, `[[`, `$`,
`names`, `dim`, `nrow`, `ncol`, `head`, and `tail`. You can also pull
the data from an Arrow table into R with `as.data.frame()`. See the
examples.

A caveat about the `$` method: because `Table` is an `R6` object, `$` is
also used to access the object's methods (see below). Methods take
precedence over the table's columns. So, `tab$Slice` would return the
"Slice" method function even if there were a column in the table called
"Slice".

</div>

<div class="section level2">

## R6 Methods

In addition to the more R-friendly S3 methods, a `Table` object has the
following R6 methods that map onto the underlying C++ methods:

-   `$column(i)`: Extract a `ChunkedArray` by integer position from the
    table

-   `$ColumnNames()`: Get all column names (called by `names(tab)`)

-   `$nbytes()`: Total number of bytes consumed by the elements of the
    table

-   `$RenameColumns(value)`: Set all column names (called by
    `names(tab) <- value`)

-   `$GetColumnByName(name)`: Extract a `ChunkedArray` by string name

-   `$field(i)`: Extract a `Field` from the table schema by integer
    position

-   `$SelectColumns(indices)`: Return new `Table` with specified
    columns, expressed as 0-based integers.

-   `$Slice(offset, length = NULL)`: Create a zero-copy view starting at
    the indicated integer offset and going for the given length, or to
    the end of the table if `NULL`, the default.

-   `$Take(i)`: return an `Table` with rows at positions given by
    integers `i`. If `i` is an Arrow `Array` or `ChunkedArray`, it will
    be coerced to an R vector before taking.

-   `$Filter(i, keep_na = TRUE)`: return an `Table` with rows at
    positions where logical vector or Arrow boolean-type
    `(Chunked)Array` `i` is `TRUE`.

-   `$SortIndices(names, descending = FALSE)`: return an `Array` of
    integer row positions that can be used to rearrange the `Table` in
    ascending or descending order by the first named column, breaking
    ties with further named columns. `descending` can be a logical
    vector of length one or of the same length as `names`.

-   `$serialize(output_stream, ...)`: Write the table to the given
    [OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md)

-   `$cast(target_schema, safe = TRUE, options = cast_options(safe))`:
    Alter the schema of the record batch.

There are also some active bindings:

-   `$num_columns`

-   `$num_rows`

-   `$schema`

-   `$metadata`: Returns the key-value metadata of the `Schema` as a
    named list. Modify or replace by assigning in
    (`tab$metadata <- new_metadata`). All list elements are coerced to
    string. See `schema()` for more information.

-   `$columns`: Returns a list of `ChunkedArray`s

</div>

</div>
