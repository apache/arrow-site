# MessageReader class

`MessageReader` reads `Message` objects from an input stream.

## R6 Methods

- `$ReadNextMessage()`: Read the next `Message` from the stream. Returns
  `NULL` if there are no more messages.

## Factory

`MessageReader$create()` takes the following argument:

- `stream`: An
  [InputStream](https://arrow.apache.org/docs/r/reference/InputStream.md)
  or object coercible to one (e.g., a raw vector)
