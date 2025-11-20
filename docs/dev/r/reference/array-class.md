<div id="main" class="col-md-9" role="main">

# Array Classes

<div class="ref-description section level2">

An `Array` is an immutable data array with some logical type and some
length. Most logical types are contained in the base `Array` class;
there are also subclasses for `DictionaryArray`, `ListArray`, and
`StructArray`.

</div>

<div class="section level2">

## Factory

The `Array$create()` factory method instantiates an `Array` and takes
the following arguments:

-   `x`: an R vector, list, or `data.frame`

-   `type`: an optional [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    `x`. If omitted, the type will be inferred from the data.

`Array$create()` will return the appropriate subclass of `Array`, such
as `DictionaryArray` when given an R factor.

To compose a `DictionaryArray` directly, call
`DictionaryArray$create()`, which takes two arguments:

-   `x`: an R vector or `Array` of integers for the dictionary indices

-   `dict`: an R vector or `Array` of dictionary values (like R factor
    levels but not limited to strings only)

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

    a <- Array$create(x)
    length(a)

    print(a)
    a == a

</div>

</div>

<div class="section level2">

## Methods

-   `$IsNull(i)`: Return true if value at index is null. Does not
    boundscheck

-   `$IsValid(i)`: Return true if value at index is valid. Does not
    boundscheck

-   `$length()`: Size in the number of elements this array contains

-   `$nbytes()`: Total number of bytes consumed by the elements of the
    array

-   `$offset`: A relative position into another array's data, to enable
    zero-copy slicing

-   `$null_count`: The number of null entries in the array

-   `$type`: logical type of data

-   `$type_id()`: type id

-   `$Equals(other)` : is this array equal to `other`

-   `$ApproxEquals(other)` :

-   `$Diff(other)` : return a string expressing the difference between
    two arrays

-   `$data()`: return the underlying
    [ArrayData](https://arrow.apache.org/docs/r/reference/ArrayData.md)

-   `$as_vector()`: convert to an R vector

-   `$ToString()`: string representation of the array

-   `$Slice(offset, length = NULL)`: Construct a zero-copy slice of the
    array with the indicated offset and length. If length is `NULL`, the
    slice goes until the end of the array.

-   `$Take(i)`: return an `Array` with values at positions given by
    integers (R vector or Array Array) `i`.

-   `$Filter(i, keep_na = TRUE)`: return an `Array` with values at
    positions where logical vector (or Arrow boolean Array) `i` is
    `TRUE`.

-   `$SortIndices(descending = FALSE)`: return an `Array` of integer
    positions that can be used to rearrange the `Array` in ascending or
    descending order

-   `$RangeEquals(other, start_idx, end_idx, other_start_idx)` :

-   `$cast(target_type, safe = TRUE, options = cast_options(safe))`:
    Alter the data in the array to change its type.

-   `$View(type)`: Construct a zero-copy view of this array with the
    given type.

-   `$Validate()` : Perform any validation checks to determine obvious
    inconsistencies within the array's internal data. This can be an
    expensive check, potentially `O(length)`

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
my_array <- Array$create(1:10)
my_array$type
#> Int32
#> int32
my_array$cast(int8())
#> Array
#> <int8>
#> [
#>   1,
#>   2,
#>   3,
#>   4,
#>   5,
#>   6,
#>   7,
#>   8,
#>   9,
#>   10
#> ]

# Check if value is null; zero-indexed
na_array <- Array$create(c(1:5, NA))
na_array$IsNull(0)
#> [1] FALSE
na_array$IsNull(5)
#> [1] TRUE
na_array$IsValid(5)
#> [1] FALSE
na_array$null_count
#> [1] 1

# zero-copy slicing; the offset of the new Array will be the same as the index passed to $Slice
new_array <- na_array$Slice(5)
new_array$offset
#> [1] 5

# Compare 2 arrays
na_array2 <- na_array
na_array2 == na_array # element-wise comparison
#> Array
#> <bool>
#> [
#>   true,
#>   true,
#>   true,
#>   true,
#>   true,
#>   null
#> ]
na_array2$Equals(na_array) # overall comparison
#> [1] TRUE
```

</div>

</div>

</div>
