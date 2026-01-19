<div id="main" class="col-md-9" role="main">

# Arrow scalars

<div class="ref-description section level2">

A `Scalar` holds a single value of an Arrow type.

</div>

<div class="section level2">

## Factory

The `Scalar$create()` factory method instantiates a `Scalar` and takes
the following arguments:

-   `x`: an R vector, list, or `data.frame`

-   `type`: an optional [data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) for
    `x`. If omitted, the type will be inferred from the data.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

    a <- Scalar$create(x)
    length(a)

    print(a)
    a == a

</div>

</div>

<div class="section level2">

## Methods

-   `$ToString()`: convert to a string

-   `$as_vector()`: convert to an R vector

-   `$as_array()`: convert to an Arrow `Array`

-   `$Equals(other)`: is this Scalar equal to `other`

-   `$ApproxEquals(other)`: is this Scalar approximately equal to
    `other`

-   `$is_valid`: is this Scalar valid

-   `$null_count`: number of invalid values - 1 or 0

-   `$type`: Scalar type

-   `$cast(target_type, safe = TRUE, options = cast_options(safe))`:
    cast value to a different type

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
Scalar$create(pi)
#> Scalar
#> 3.141592653589793
Scalar$create(404)
#> Scalar
#> 404
# If you pass a vector into Scalar$create, you get a list containing your items
Scalar$create(c(1, 2, 3))
#> Scalar
#> list<item: double>[1, 2, 3]

# Comparisons
my_scalar <- Scalar$create(99)
my_scalar$ApproxEquals(Scalar$create(99.00001)) # FALSE
#> [1] FALSE
my_scalar$ApproxEquals(Scalar$create(99.000009)) # TRUE
#> [1] TRUE
my_scalar$Equals(Scalar$create(99.000009)) # FALSE
#> [1] FALSE
my_scalar$Equals(Scalar$create(99L)) # FALSE (types don't match)
#> [1] FALSE

my_scalar$ToString()
#> [1] "99"
```

</div>

</div>

</div>
