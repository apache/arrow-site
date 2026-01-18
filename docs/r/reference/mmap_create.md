<div id="main" class="col-md-9" role="main">

# Create a new read/write memory mapped file of a given size

<div class="ref-description section level2">

Create a new read/write memory mapped file of a given size

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
mmap_create(path, size)
```

</div>

</div>

<div class="section level2">

## Arguments

-   path:

    file path

-   size:

    size in bytes

</div>

<div class="section level2">

## Value

a
[arrow::io::MemoryMappedFile](https://arrow.apache.org/docs/r/reference/InputStream.md)

</div>

</div>
