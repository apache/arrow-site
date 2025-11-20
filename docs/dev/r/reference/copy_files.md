<div id="main" class="col-md-9" role="main">

# Copy files between FileSystems

<div class="ref-description section level2">

Copy files between FileSystems

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
copy_files(from, to, chunk_size = 1024L * 1024L)
```

</div>

</div>

<div class="section level2">

## Arguments

-   from:

    A string path to a local directory or file, a URI, or a
    `SubTreeFileSystem`. Files will be copied recursively from this
    path.

-   to:

    A string path to a local directory or file, a URI, or a
    `SubTreeFileSystem`. Directories will be created as necessary

-   chunk_size:

    The maximum size of block to read before flushing to the destination
    file. A larger chunk_size will use more memory while copying but may
    help accommodate high latency FileSystems.

</div>

<div class="section level2">

## Value

Nothing: called for side effects in the file system

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) {
# Copy an S3 bucket's files to a local directory:
copy_files("s3://your-bucket-name", "local-directory")
# Using a FileSystem object
copy_files(s3_bucket("your-bucket-name"), "local-directory")
# Or go the other way, from local to S3
copy_files("local-directory", s3_bucket("your-bucket-name"))
}
```

</div>

</div>

</div>
