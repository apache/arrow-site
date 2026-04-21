# ArrayData class

The `ArrayData` class allows you to get and inspect the data inside an
[`arrow::Array`](https://arrow.apache.org/docs/r/reference/array-class.md).

## Usage

    data <- Array$create(x)$data()

    data$type
    data$length
    data$null_count
    data$offset
    data$buffers

## Methods

...
