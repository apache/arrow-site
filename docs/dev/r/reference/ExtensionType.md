<div id="main" class="col-md-9" role="main">

# ExtensionType class

<div class="ref-description section level2">

ExtensionType class

</div>

<div class="section level2">

## Methods

The `ExtensionType` class inherits from `DataType`, but also defines
extra methods specific to extension types:

-   `$storage_type()`: Returns the underlying
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)
    used to store values.

-   `$storage_id()`: Returns the
    [Type](https://arrow.apache.org/docs/r/reference/enums.md)
    identifier corresponding to the `$storage_type()`.

-   `$extension_name()`: Returns the extension name.

-   `$extension_metadata()`: Returns the serialized version of the
    extension metadata as a `raw()` vector.

-   `$extension_metadata_utf8()`: Returns the serialized version of the
    extension metadata as a UTF-8 encoded string.

-   `$WrapArray(array)`: Wraps a storage
    [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
    into an
    [ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
    with this extension type.

In addition, subclasses may override the following methods to customize
the behaviour of extension classes.

-   `$deserialize_instance()`: This method is called when a new
    ExtensionType is initialized and is responsible for parsing and
    validating the serialized extension_metadata (a `raw()` vector) such
    that its contents can be inspected by fields and/or methods of the
    R6 ExtensionType subclass. Implementations must also check the
    `storage_type` to make sure it is compatible with the extension
    type.

-   `$as_vector(extension_array)`: Convert an
    [Array](https://arrow.apache.org/docs/r/reference/array-class.md) or
    [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
    to an R vector. This method is called by `as.vector()` on
    [ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
    objects, when a
    [RecordBatch](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
    containing an
    [ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
    is converted to a `data.frame()`, or when a
    [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
    (e.g., a column in a
    [Table](https://arrow.apache.org/docs/r/reference/Table-class.md))
    is converted to an R vector. The default method returns the
    converted storage array.

-   `$ToString()` Return a string representation that will be printed to
    the console when this type or an Array of this type is printed.

</div>

</div>
