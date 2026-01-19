<div id="main" class="col-md-9" role="main">

# Connect to a Google Cloud Storage (GCS) bucket

<div class="ref-description section level2">

`gs_bucket()` is a convenience function to create an `GcsFileSystem`
object that holds onto its relative path

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
gs_bucket(bucket, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   bucket:

    string GCS bucket name or path

-   ...:

    Additional connection options, passed to `GcsFileSystem$create()`

</div>

<div class="section level2">

## Value

A `SubTreeFileSystem` containing an `GcsFileSystem` and the bucket's
relative path. Note that this function's success does not guarantee that
you are authorized to access the bucket's contents.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (FALSE) {
bucket <- gs_bucket("arrow-datasets")
}
```

</div>

</div>

</div>
