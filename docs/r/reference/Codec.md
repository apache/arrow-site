<div id="main" class="col-md-9" role="main">

# Compression Codec class

<div class="ref-description section level2">

Codecs allow you to create [compressed input and output
streams](https://arrow.apache.org/docs/r/reference/compression.md).

</div>

<div class="section level2">

## Factory

The `Codec$create()` factory method takes the following arguments:

-   `type`: string name of the compression method. Possible values are
    "uncompressed", "snappy", "gzip", "brotli", "zstd", "lz4", "lzo", or
    "bz2". `type` may be upper- or lower-cased. Not all methods may be
    available; support depends on build-time flags for the C++ library.
    See `codec_is_available()`. Most builds support at least "snappy"
    and "gzip". All support "uncompressed".

-   `compression_level`: compression level, the default value (`NA`)
    uses the default compression level for the selected compression
    `type`.

</div>

</div>
