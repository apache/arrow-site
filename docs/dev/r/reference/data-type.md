<div id="main" class="col-md-9" role="main">

# Create Arrow data types

<div class="ref-description section level2">

These functions create type objects corresponding to Arrow types. Use
them when defining a `schema()` or as inputs to other types, like
`struct`. Most of these functions don't take arguments, but a few do.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
int8()

int16()

int32()

int64()

uint8()

uint16()

uint32()

uint64()

float16()

halffloat()

float32()

float()

float64()

boolean()

bool()

utf8()

large_utf8()

binary()

large_binary()

fixed_size_binary(byte_width)

string()

date32()

date64()

time32(unit = c("ms", "s"))

time64(unit = c("ns", "us"))

duration(unit = c("s", "ms", "us", "ns"))

null()

timestamp(unit = c("s", "ms", "us", "ns"), timezone = "")

decimal(precision, scale)

decimal32(precision, scale)

decimal64(precision, scale)

decimal128(precision, scale)

decimal256(precision, scale)

struct(...)

list_of(type)

large_list_of(type)

fixed_size_list_of(type, list_size)

map_of(key_type, item_type, .keys_sorted = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   byte_width:

    byte width for `FixedSizeBinary` type.

-   unit:

    For time/timestamp types, the time unit. `time32()` can take either
    "s" or "ms", while `time64()` can be "us" or "ns". `timestamp()` can
    take any of those four values.

-   timezone:

    For `timestamp()`, an optional time zone string.

-   precision:

    For `decimal()`, `decimal128()`, and `decimal256()` the number of
    significant digits the arrow `decimal` type can represent. The
    maximum precision for `decimal128()` is 38 significant digits, while
    for `decimal256()` it is 76 digits. `decimal()` will use it to
    choose which type of decimal to return.

-   scale:

    For `decimal()`, `decimal128()`, and `decimal256()` the number of
    digits after the decimal point. It can be negative.

-   ...:

    For `struct()`, a named list of types to define the struct columns

-   type:

    For `list_of()`, a data type to make a list-of-type

-   list_size:

    list size for `FixedSizeList` type.

-   key_type, item_type:

    For `MapType`, the key and item types.

-   .keys_sorted:

    Use `TRUE` to assert that keys of a `MapType` are sorted.

</div>

<div class="section level2">

## Value

An Arrow type object inheriting from
[DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md).

</div>

<div class="section level2">

## Details

A few functions have aliases:

-   `utf8()` and `string()`

-   `float16()` and `halffloat()`

-   `float32()` and `float()`

-   `bool()` and `boolean()`

-   When called inside an `arrow` function, such as `schema()` or
    `cast()`, `double()` also is supported as a way of creating a
    `float64()`

`date32()` creates a datetime type with a "day" unit, like the R `Date`
class. `date64()` has a "ms" unit.

`uint32` (32 bit unsigned integer), `uint64` (64 bit unsigned integer),
and `int64` (64-bit signed integer) types may contain values that exceed
the range of R's `integer` type (32-bit signed integer). When these
arrow objects are translated to R objects, `uint32` and `uint64` are
converted to `double` ("numeric") and `int64` is converted to
`bit64::integer64`. For `int64` types, this conversion can be disabled
(so that `int64` always yields a `bit64::integer64` object) by setting
`options(arrow.int64_downcast = FALSE)`.

`decimal128()` creates a `Decimal128Type`. Arrow decimals are
fixed-point decimal numbers encoded as a scalar integer. The `precision`
is the number of significant digits that the decimal type can represent;
the `scale` is the number of digits after the decimal point. For
example, the number 1234.567 has a precision of 7 and a scale of 3. Note
that `scale` can be negative.

As an example, `decimal128(7, 3)` can exactly represent the numbers
1234.567 and -1234.567 (encoded internally as the 128-bit integers
1234567 and -1234567, respectively), but neither 12345.67 nor 123.4567.

`decimal128(5, -3)` can exactly represent the number 12345000 (encoded
internally as the 128-bit integer 12345), but neither 123450000 nor
1234500. The `scale` can be thought of as an argument that controls
rounding. When negative, `scale` causes the number to be expressed using
scientific notation and power of 10.

`decimal256()` creates a `Decimal256Type`, which allows for higher
maximum precision. For most use cases, the maximum precision offered by
`Decimal128Type` is sufficient, and it will result in a more compact and
more efficient encoding.

`decimal()` creates either a `Decimal128Type` or a `Decimal256Type`
depending on the value for `precision`. If `precision` is greater than
38 a `Decimal256Type` is returned, otherwise a `Decimal128Type`.

Use `decimal128()` or `decimal256()` as the names are more informative
than `decimal()`.

</div>

<div class="section level2">

## See also

<div class="dont-index">

`dictionary()` for creating a dictionary (factor-like) type.

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
bool()
#> Boolean
#> bool
struct(a = int32(), b = double())
#> StructType
#> struct<a: int32, b: double>
timestamp("ms", timezone = "CEST")
#> Timestamp
#> timestamp[ms, tz=CEST]
time64("ns")
#> Time64
#> time64[ns]

# Use the cast method to change the type of data contained in Arrow objects.
# Please check the documentation of each data object class for details.
my_scalar <- Scalar$create(0L, type = int64()) # int64
my_scalar$cast(timestamp("ns")) # timestamp[ns]
#> Scalar
#> 1970-01-01 00:00:00.000000000

my_array <- Array$create(0L, type = int64()) # int64
my_array$cast(timestamp("s", timezone = "UTC")) # timestamp[s, tz=UTC]
#> Array
#> <timestamp[s, tz=UTC]>
#> [
#>   1970-01-01 00:00:00Z
#> ]

my_chunked_array <- chunked_array(0L, 1L) # int32
my_chunked_array$cast(date32()) # date32[day]
#> ChunkedArray
#> <date32[day]>
#> [
#>   [
#>     1970-01-01
#>   ],
#>   [
#>     1970-01-02
#>   ]
#> ]

# You can also use `cast()` in an Arrow dplyr query.
if (requireNamespace("dplyr", quietly = TRUE)) {
  library(dplyr, warn.conflicts = FALSE)
  arrow_table(mtcars) |>
    transmute(
      col1 = cast(cyl, string()),
      col2 = cast(cyl, int8())
    ) |>
    compute()
}
#> Table
#> 32 rows x 2 columns
#> $col1 <string>
#> $col2 <int8>
#> 
#> See $metadata for additional Schema metadata
```

</div>

</div>

</div>
