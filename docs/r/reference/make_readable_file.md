<div id="main" class="col-md-9" role="main">

# Handle a range of possible input sources

<div class="ref-description section level2">

Handle a range of possible input sources

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
make_readable_file(file, mmap = TRUE, random_access = TRUE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   file:

    A character file name, `raw` vector, or an Arrow input stream

-   mmap:

    Logical: whether to memory-map the file (default `TRUE`)

-   random_access:

    Logical: whether the result must be a RandomAccessFile

</div>

<div class="section level2">

## Value

An `InputStream` or a subclass of one.

</div>

</div>
