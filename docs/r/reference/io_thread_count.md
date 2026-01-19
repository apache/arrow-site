<div id="main" class="col-md-9" role="main">

# Manage the global I/O thread pool in libarrow

<div class="ref-description section level2">

Manage the global I/O thread pool in libarrow

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
io_thread_count()

set_io_thread_count(num_threads)
```

</div>

</div>

<div class="section level2">

## Arguments

-   num_threads:

    integer: New number of threads for thread pool. At least two threads
    are recommended to support all operations in the arrow package.

</div>

</div>
