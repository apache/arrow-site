# Buffer class

A Buffer is an object containing a pointer to a piece of contiguous
memory with a particular size.

## Factory

[`buffer()`](https://arrow.apache.org/docs/r/reference/buffer.md) lets
you create an `arrow::Buffer` from an R object

## Methods

- `$is_mutable` : is this buffer mutable?

- `$ZeroPadding()` : zero bytes in padding, i.e. bytes between size and
  capacity

- `$size` : size in memory, in bytes

- `$capacity`: possible capacity, in bytes

## Examples

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
