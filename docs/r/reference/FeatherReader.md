<div id="main" class="col-md-9" role="main">

# FeatherReader class

<div class="ref-description section level2">

This class enables you to interact with Feather files. Create one to
connect to a file or other InputStream, and call `Read()` on it to make
an `arrow::Table`. See its usage in `read_feather()`.

</div>

<div class="section level2">

## Factory

The `FeatherReader$create()` factory method instantiates the object and
takes the following argument:

-   `file` an Arrow file connection object inheriting from
    `RandomAccessFile`.

</div>

<div class="section level2">

## Methods

-   `$Read(columns)`: Returns a `Table` of the selected columns, a
    vector of integer indices

-   `$column_names`: Active binding, returns the column names in the
    Feather file

-   `$schema`: Active binding, returns the schema of the Feather file

-   `$version`: Active binding, returns `1` or `2`, according to the
    Feather file version

</div>

</div>
