# FileSystem entry info

FileSystem entry info

## Methods

- `base_name()` : The file base name (component after the last directory
  separator).

- `extension()` : The file extension

## Active bindings

- `$type`: The file type

- `$path`: The full file path in the filesystem

- `$size`: The size in bytes, if available. Only regular files are
  guaranteed to have a size.

- `$mtime`: The time of last modification, if available.
