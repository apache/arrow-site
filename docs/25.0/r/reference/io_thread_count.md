# Manage the global I/O thread pool in libarrow

Manage the global I/O thread pool in libarrow

## Usage

``` r
io_thread_count()

set_io_thread_count(num_threads)
```

## Arguments

- num_threads:

  integer: New number of threads for thread pool. At least two threads
  are recommended to support all operations in the arrow package.
