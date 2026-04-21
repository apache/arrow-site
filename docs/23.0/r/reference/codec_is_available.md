# Check whether a compression codec is available

Support for compression libraries depends on the build-time settings of
the Arrow C++ library. This function lets you know which are available
for use.

## Usage

``` r
codec_is_available(type)
```

## Arguments

- type:

  A string, one of "uncompressed", "snappy", "gzip", "brotli", "zstd",
  "lz4", "lzo", or "bz2", case-insensitive.

## Value

Logical: is `type` available?

## Examples

``` r
codec_is_available("gzip")
#> [1] TRUE
```
