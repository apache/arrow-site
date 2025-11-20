<div id="main" class="col-md-9" role="main">

# Extension type for generic typed vectors

<div class="ref-description section level2">

Most common R vector types are converted automatically to a suitable
Arrow [data
type](https://arrow.apache.org/docs/r/reference/data-type.md) without
the need for an extension type. For vector types whose conversion is not
suitably handled by default, you can create a `vctrs_extension_array()`,
which passes `vctrs::vec_data()` to `Array$create()` and calls
`vctrs::vec_restore()` when the
[Array](https://arrow.apache.org/docs/r/reference/array-class.md) is
converted back into an R vector.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
vctrs_extension_array(x, ptype = vctrs::vec_ptype(x), storage_type = NULL)

vctrs_extension_type(x, storage_type = infer_type(vctrs::vec_data(x)))
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    A vctr (i.e., `vctrs::vec_is()` returns `TRUE`).

-   ptype:

    A `vctrs::vec_ptype()`, which is usually a zero-length version of
    the object with the appropriate attributes set. This value will be
    serialized using `serialize()`, so it should not refer to any R
    object that can't be saved/reloaded.

-   storage_type:

    The [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) of the
    underlying storage array.

</div>

<div class="section level2">

## Value

-   `vctrs_extension_array()` returns an
    [ExtensionArray](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
    instance with a `vctrs_extension_type()`.

-   `vctrs_extension_type()` returns an
    [ExtensionType](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
    instance for the extension name "arrow.r.vctrs".

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
(array <- vctrs_extension_array(as.POSIXlt("2022-01-02 03:45", tz = "UTC")))
#> ExtensionArray
#> <POSIXlt of length 0>
#> -- is_valid: all not null
#> -- child 0 type: double
#>   [
#>     0
#>   ]
#> -- child 1 type: int32
#>   [
#>     45
#>   ]
#> -- child 2 type: int32
#>   [
#>     3
#>   ]
#> -- child 3 type: int32
#>   [
#>     2
#>   ]
#> -- child 4 type: int32
#>   [
#>     0
#>   ]
#> -- child 5 type: int32
#>   [
#>     122
#>   ]
#> -- child 6 type: int32
#>   [
#>     0
#>   ]
#> -- child 7 type: int32
#>   [
#>     1
#>   ]
#> -- child 8 type: int32
#>   [
#>     0
#>   ]
#> -- child 9 type: string
#>   [
#>     "UTC"
#>   ]
#> -- child 10 type: int32
#>   [
#>     0
#>   ]
array$type
#> VctrsExtensionType
#> POSIXlt of length 0
as.vector(array)
#> [1] "2022-01-02 03:45:00 UTC"

temp_feather <- tempfile()
write_feather(arrow_table(col = array), temp_feather)
read_feather(temp_feather)
#> # A tibble: 1 x 1
#>   col                
#>   <dttm>             
#> 1 2022-01-02 03:45:00
unlink(temp_feather)
```

</div>

</div>

</div>
