<div id="main" class="col-md-9" role="main">

# DataType class

<div class="ref-description section level2">

DataType class

</div>

<div class="section level2">

## R6 Methods

-   `$ToString()`: String representation of the DataType

-   `$Equals(other)`: Is the DataType equal to `other`

-   `$fields()`: The children fields associated with this type

-   `$code(namespace)`: Produces an R call of the data type. Use
    `namespace=TRUE` to call with `arrow::`.

There are also some active bindings:

-   `$id`: integer Arrow type id.

-   `$name`: string Arrow type name.

-   `$num_fields`: number of child fields.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`infer_type()`

`data-type`

</div>

</div>

</div>
