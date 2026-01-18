<div id="main" class="col-md-9" role="main">

# Buffer class

<div class="ref-description section level2">

A Buffer is an object containing a pointer to a piece of contiguous
memory with a particular size.

</div>

<div class="section level2">

## Factory

`buffer()` lets you create an `arrow::Buffer` from an R object

</div>

<div class="section level2">

## Methods

-   `$is_mutable` : is this buffer mutable?

-   `$ZeroPadding()` : zero bytes in padding, i.e. bytes between size
    and capacity

-   `$size` : size in memory, in bytes

-   `$capacity`: possible capacity, in bytes

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
my_buffer <- buffer(c(1, 2, 3, 4))
my_buffer$is_mutable
#> [1] TRUE
my_buffer$ZeroPadding()
my_buffer$size
#> [1] 32
my_buffer$capacity
#> [1] 32
```

</div>

</div>

</div>
