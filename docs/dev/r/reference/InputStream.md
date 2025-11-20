<div id="main" class="col-md-9" role="main">

# InputStream classes

<div class="ref-description section level2">

`RandomAccessFile` inherits from `InputStream` and is a base class for:
`ReadableFile` for reading from a file; `MemoryMappedFile` for the same
but with memory mapping; and `BufferReader` for reading from a buffer.
Use these with the various table readers.

</div>

<div class="section level2">

## Factory

The `$create()` factory methods instantiate the `InputStream` object and
take the following arguments, depending on the subclass:

-   `path` For `ReadableFile`, a character file name

-   `x` For `BufferReader`, a
    [Buffer](https://arrow.apache.org/docs/r/reference/Buffer-class.md)
    or an object that can be made into a buffer via `buffer()`.

To instantiate a `MemoryMappedFile`, call `mmap_open()`.

</div>

<div class="section level2">

## Methods

-   `$GetSize()`:

-   `$supports_zero_copy()`: Logical

-   `$seek(position)`: go to that position in the stream

-   `$tell()`: return the position in the stream

-   `$close()`: close the stream

-   `$Read(nbytes)`: read data from the stream, either a specified
    `nbytes` or all, if `nbytes` is not provided

-   `$ReadAt(position, nbytes)`: similar to
    `$seek(position)$Read(nbytes)`

-   `$Resize(size)`: for a `MemoryMappedFile` that is writeable

</div>

</div>
