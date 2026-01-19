<div id="main" class="col-md-9" role="main">

# Check whether a compression codec is available

<div class="ref-description section level2">

Support for compression libraries depends on the build-time settings of
the Arrow C++ library. This function lets you know which are available
for use.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
codec_is_available(type)
```

</div>

</div>

<div class="section level2">

## Arguments

-   type:

    A string, one of "uncompressed", "snappy", "gzip", "brotli", "zstd",
    "lz4", "lzo", or "bz2", case-insensitive.

</div>

<div class="section level2">

## Value

Logical: is `type` available?

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
codec_is_available("gzip")
#> [1] TRUE
```

</div>

</div>

</div>
