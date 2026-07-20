# Create a Chunked Array

Create a Chunked Array

## Usage

``` r
chunked_array(..., type = NULL)
```

## Arguments

- ...:

  R objects to coerce into a ChunkedArray. They must be of the same
  type.

- type:

  An optional [data
  type](https://arrow.apache.org/docs/r/reference/data-type.md). If
  omitted, the type will be inferred from the data.

## See also

[ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)

## Examples

``` r
# Pass items into chunked_array as separate objects to create chunks
class_scores <- chunked_array(c(87, 88, 89), c(94, 93, 92), c(71, 72, 73))

# If you pass a list into chunked_array, you get a list of length 1
list_scores <- chunked_array(list(c(9.9, 9.6, 9.5), c(8.2, 8.3, 8.4), c(10.0, 9.9, 9.8)))

# When constructing a ChunkedArray, the first chunk is used to infer type.
infer_type(chunked_array(c(1, 2, 3), c(5L, 6L, 7L)))
#> Float64
#> double

# Concatenating chunked arrays returns a new chunked array containing all chunks
a <- chunked_array(c(1, 2), 3)
b <- chunked_array(c(4, 5), 6)
c(a, b)
#> ChunkedArray
#> <double>
#> [
#>   [
#>     1,
#>     2
#>   ],
#>   [
#>     3
#>   ],
#>   [
#>     4,
#>     5
#>   ],
#>   [
#>     6
#>   ]
#> ]
```
