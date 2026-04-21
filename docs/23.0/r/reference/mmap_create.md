# Create a new read/write memory mapped file of a given size

Create a new read/write memory mapped file of a given size

## Usage

``` r
mmap_create(path, size)
```

## Arguments

- path:

  file path

- size:

  size in bytes

## Value

a
[arrow::io::MemoryMappedFile](https://arrow.apache.org/docs/r/reference/InputStream.md)
