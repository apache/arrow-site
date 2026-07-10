# ExtensionArray class

ExtensionArray class

## Methods

The `ExtensionArray` class inherits from `Array`, but also provides
access to the underlying storage of the extension.

- `$storage()`: Returns the underlying
  [Array](https://arrow.apache.org/docs/r/reference/array-class.md) used
  to store values.

The `ExtensionArray` is not intended to be subclassed for extension
types.
