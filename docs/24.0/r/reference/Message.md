# Message class

`Message` holds an Arrow IPC message, which includes metadata and an
optional message body.

## R6 Methods

- `$Equals(other)`: Check if this `Message` is equal to another
  `Message`

- `$body_length()`: Return the length of the message body in bytes

- `$Verify()`: Check if the `Message` metadata is valid Flatbuffer
  format

## Active bindings

- `$type`: The message type

- `$metadata`: The message metadata

- `$body`: The message body as a
  [Buffer](https://arrow.apache.org/docs/r/reference/Buffer-class.md)
