<div id="main" class="col-md-9" role="main">

# Extension types

<div class="ref-description section level2">

Extension arrays are wrappers around regular Arrow
[Array](https://arrow.apache.org/docs/r/reference/array-class.md)
objects that provide some customized behaviour and/or storage. A common
use-case for extension types is to define a customized conversion
between an an Arrow
[Array](https://arrow.apache.org/docs/r/reference/array-class.md) and an
R object when the default conversion is slow or loses metadata important
to the interpretation of values in the array. For most types, the
built-in [vctrs extension
type](https://arrow.apache.org/docs/r/reference/vctrs_extension_array.md)
is probably sufficient.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
new_extension_type(
  storage_type,
  extension_name,
  extension_metadata = raw(),
  type_class = ExtensionType
)

new_extension_array(storage_array, extension_type)

register_extension_type(extension_type)

reregister_extension_type(extension_type)

unregister_extension_type(extension_name)
```

</div>

</div>

<div class="section level2">

## Arguments

-   storage_type:

    The [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) of the
    underlying storage array.

-   extension_name:

    The extension name. This should be namespaced using "dot" syntax
    (i.e., "some_package.some_type"). The namespace "arrow" is reserved
    for extension types defined by the Apache Arrow libraries.

-   extension_metadata:

    A `raw()` or `character()` vector containing the serialized version
    of the type. Character vectors must be length 1 and are converted to
    UTF-8 before converting to `raw()`.

-   type_class:

    An [R6::R6Class](https://r6.r-lib.org/reference/R6Class.html) whose
    `$new()` class method will be used to construct a new instance of
    the type.

-   storage_array:

    An [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
    object of the underlying storage.

-   extension_type:

    An
    [ExtensionType](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
    instance.

</div>

<div class="section level2">

## Value

-   `new_extension_type()` returns an
    [ExtensionType](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
    instance according to the `type_class` specified.

-   `new_extension_array()` returns an
    [ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
    whose `$type` corresponds to `extension_type`.

-   `register_extension_type()`, `unregister_extension_type()` and
    `reregister_extension_type()` return `NULL`, invisibly.

</div>

<div class="section level2">

## Details

These functions create, register, and unregister
[ExtensionType](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
and
[ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
objects. To use an extension type you will have to:

-   Define an [R6::R6Class](https://r6.r-lib.org/reference/R6Class.html)
    that inherits from
    [ExtensionType](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
    and reimplement one or more methods (e.g.,
    `deserialize_instance()`).

-   Make a type constructor function (e.g., `my_extension_type()`) that
    calls `new_extension_type()` to create an R6 instance that can be
    used as a [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md)
    elsewhere in the package.

-   Make an array constructor function (e.g., `my_extension_array()`)
    that calls `new_extension_array()` to create an
    [Array](https://arrow.apache.org/docs/r/reference/array-class.md)
    instance of your extension type.

-   Register a dummy instance of your extension type created using you
    constructor function using `register_extension_type()`.

If defining an extension type in an R package, you will probably want to
use `reregister_extension_type()` in that package's `.onLoad()` hook
since your package will probably get reloaded in the same R session
during its development and `register_extension_type()` will error if
called twice for the same `extension_name`. For an example of an
extension type that uses most of these features, see
`vctrs_extension_type()`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Create the R6 type whose methods control how Array objects are
# converted to R objects, how equality between types is computed,
# and how types are printed.
QuantizedType <- R6::R6Class(
  "QuantizedType",
  inherit = ExtensionType,
  public = list(
    # methods to access the custom metadata fields
    center = function() private$.center,
    scale = function() private$.scale,

    # called when an Array of this type is converted to an R vector
    as_vector = function(extension_array) {
      if (inherits(extension_array, "ExtensionArray")) {
        unquantized_arrow <-
          (extension_array$storage()$cast(float64()) / private$.scale) +
          private$.center

        as.vector(unquantized_arrow)
      } else {
        super$as_vector(extension_array)
      }
    },

    # populate the custom metadata fields from the serialized metadata
    deserialize_instance = function() {
      vals <- as.numeric(strsplit(self$extension_metadata_utf8(), ";")[[1]])
      private$.center <- vals[1]
      private$.scale <- vals[2]
    }
  ),
  private = list(
    .center = NULL,
    .scale = NULL
  )
)

# Create a helper type constructor that calls new_extension_type()
quantized <- function(center = 0, scale = 1, storage_type = int32()) {
  new_extension_type(
    storage_type = storage_type,
    extension_name = "arrow.example.quantized",
    extension_metadata = paste(center, scale, sep = ";"),
    type_class = QuantizedType
  )
}

# Create a helper array constructor that calls new_extension_array()
quantized_array <- function(x, center = 0, scale = 1,
                            storage_type = int32()) {
  type <- quantized(center, scale, storage_type)
  new_extension_array(
    Array$create((x - center) * scale, type = storage_type),
    type
  )
}

# Register the extension type so that Arrow knows what to do when
# it encounters this extension type
reregister_extension_type(quantized())

# Create Array objects and use them!
(vals <- runif(5, min = 19, max = 21))
#> [1] 19.07557 19.97832 19.76972 19.27137 20.76730

(array <- quantized_array(
  vals,
  center = 20,
  scale = 2^15 - 1,
  storage_type = int16()
)
)
#> ExtensionArray
#> <QuantizedType <20;32767>>
#> [
#>   -30290,
#>   -710,
#>   -7545,
#>   -23874,
#>   25142
#> ]

array$type$center()
#> [1] 20
array$type$scale()
#> [1] 32767

as.vector(array)
#> [1] 19.07559 19.97833 19.76974 19.27140 20.76730
```

</div>

</div>

</div>
