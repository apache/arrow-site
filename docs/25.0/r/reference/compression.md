# Compressed stream classes

`CompressedInputStream` and `CompressedOutputStream` allow you to apply
a compression
[Codec](https://arrow.apache.org/docs/r/reference/Codec.md) to an input
or output stream.

## Factory

The `CompressedInputStream$create()` and
`CompressedOutputStream$create()` factory methods instantiate the object
and take the following arguments:

- `stream` An
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
  or
  [OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
  respectively

- `codec` A `Codec`, either a
  [Codec](https://arrow.apache.org/docs/r/reference/Codec.md) instance
  or a string

- `compression_level` compression level for when the `codec` argument is
  given as a string

## Methods

Methods are inherited from
[InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
and
[OutputStream](https://arrow.apache.org/docs/r/reference/OutputStream.md),
respectively
