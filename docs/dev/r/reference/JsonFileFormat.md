# JSON dataset file format

A `JsonFileFormat` is a
[FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)
subclass which holds information about how to read and parse the files
included in a JSON `Dataset`.

## Value

A `JsonFileFormat` object

## Factory

`JsonFileFormat$create()` can take options in the form of lists passed
through as `parse_options`, or `read_options` parameters.

Available `read_options` parameters:

- `use_threads`: Whether to use the global CPU thread pool. Default
  `TRUE`. If `FALSE`, JSON input must end with an empty line.

- `block_size`: Block size we request from the IO layer; also determines
  size of chunks when `use_threads` is `TRUE`.

Available `parse_options` parameters:

- `newlines_in_values`:Logical: are values allowed to contain CR (`0x0d`
  or `\r`) and LF (`0x0a` or `\n`) characters? (default `FALSE`)

## See also

[FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)

## Examples

``` r
```
