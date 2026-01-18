<div id="main" class="col-md-9" role="main">

# RecordBatch class

<div class="ref-description section level2">

A record batch is a collection of equal-length arrays matching a
particular
[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md). It
is a table-like data structure that is semantically a sequence of
[fields](https://arrow.apache.org/docs/r/reference/Field-class.md), each
a contiguous Arrow
[Array](https://arrow.apache.org/docs/r/reference/array-class.md).

</div>

<div class="section level2">

## S3 Methods and Usage

Record batches are data-frame-like, and many methods you expect to work
on a `data.frame` are implemented for `RecordBatch`. This includes `[`,
`[[`, `$`, `names`, `dim`, `nrow`, `ncol`, `head`, and `tail`. You can
also pull the data from an Arrow record batch into R with
`as.data.frame()`. See the examples.

A caveat about the `$` method: because `RecordBatch` is an `R6` object,
`$` is also used to access the object's methods (see below). Methods
take precedence over the table's columns. So, `batch$Slice` would return
the "Slice" method function even if there were a column in the table
called "Slice".

</div>

<div class="section level2">

## R6 Methods

In addition to the more R-friendly S3 methods, a `RecordBatch` object
has the following R6 methods that map onto the underlying C++ methods:

-   `$Equals(other)`: Returns `TRUE` if the `other` record batch is
    equal

-   `$column(i)`: Extract an `Array` by integer position from the batch

-   `$column_name(i)`: Get a column's name by integer position

-   `$names()`: Get all column names (called by `names(batch)`)

-   `$nbytes()`: Total number of bytes consumed by the elements of the
    record batch

-   `$RenameColumns(value)`: Set all column names (called by
    `names(batch) <- value`)

-   `$GetColumnByName(name)`: Extract an `Array` by string name

-   `$RemoveColumn(i)`: Drops a column from the batch by integer
    position

-   `$SelectColumns(indices)`: Return a new record batch with a
    selection of columns, expressed as 0-based integers.

-   `$Slice(offset, length = NULL)`: Create a zero-copy view starting at
    the indicated integer offset and going for the given length, or to
    the end of the table if `NULL`, the default.

-   `$Take(i)`: return an `RecordBatch` with rows at positions given by
    integers (R vector or Array Array) `i`.

-   `$Filter(i, keep_na = TRUE)`: return an `RecordBatch` with rows at
    positions where logical vector (or Arrow boolean Array) `i` is
    `TRUE`.

-   `$SortIndices(names, descending = FALSE)`: return an `Array` of
    integer row positions that can be used to rearrange the
    `RecordBatch` in ascending or descending order by the first named
    column, breaking ties with further named columns. `descending` can
    be a logical vector of length one or of the same length as `names`.

-   `$serialize()`: Returns a raw vector suitable for interprocess
    communication

-   `$cast(target_schema, safe = TRUE, options = cast_options(safe))`:
    Alter the schema of the record batch.

There are also some active bindings

-   `$num_columns`

-   `$num_rows`

-   `$schema`

-   `$metadata`: Returns the key-value metadata of the `Schema` as a
    named list. Modify or replace by assigning in
    (`batch$metadata <- new_metadata`). All list elements are coerced to
    string. See `schema()` for more information.

-   `$columns`: Returns a list of `Array`s

</div>

</div>
