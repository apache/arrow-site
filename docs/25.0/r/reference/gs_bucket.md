# Connect to a Google Cloud Storage (GCS) bucket

`gs_bucket()` is a convenience function to create an `GcsFileSystem`
object that holds onto its relative path

## Usage

``` r
gs_bucket(bucket, ...)
```

## Arguments

- bucket:

  string GCS bucket name or path

- ...:

  Additional connection options, passed to `GcsFileSystem$create()`

## Value

A `SubTreeFileSystem` containing an `GcsFileSystem` and the bucket's
relative path. Note that this function's success does not guarantee that
you are authorized to access the bucket's contents.

## Examples

``` r
if (FALSE) {
bucket <- gs_bucket("arrow-datasets")
}
```
