# Handle a range of possible input sources

Handle a range of possible input sources

## Usage

``` r
make_readable_file(file, mmap = TRUE, random_access = TRUE)
```

## Arguments

- file:

  A character file name, `raw` vector, or an Arrow input stream

- mmap:

  Logical: whether to memory-map the file (default `TRUE`)

- random_access:

  Logical: whether the result must be a RandomAccessFile

## Value

An `InputStream` or a subclass of one.
