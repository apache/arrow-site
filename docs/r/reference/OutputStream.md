<div id="main" class="col-md-9" role="main">

# OutputStream classes

<div class="ref-description section level2">

`FileOutputStream` is for writing to a file; `BufferOutputStream` writes
to a buffer; You can create one and pass it to any of the table writers,
for example.

</div>

<div class="section level2">

## Factory

The `$create()` factory methods instantiate the `OutputStream` object
and take the following arguments, depending on the subclass:

-   `path` For `FileOutputStream`, a character file name

-   `initial_capacity` For `BufferOutputStream`, the size in bytes of
    the buffer.

</div>

<div class="section level2">

## Methods

-   `$tell()`: return the position in the stream

-   `$close()`: close the stream

-   `$write(x)`: send `x` to the stream

-   `$capacity()`: for `BufferOutputStream`

-   `$finish()`: for `BufferOutputStream`

-   `$GetExtentBytesWritten()`: for `MockOutputStream`, report how many
    bytes were sent.

</div>

</div>
