# Connect to an AWS S3 bucket

`s3_bucket()` is a convenience function to create an `S3FileSystem`
object that automatically detects the bucket's AWS region and holding
onto the its relative path.

## Usage

``` r
s3_bucket(bucket, ...)
```

## Arguments

- bucket:

  string S3 bucket name or path

- ...:

  Additional connection options, passed to `S3FileSystem$create()`

## Value

A `SubTreeFileSystem` containing an `S3FileSystem` and the bucket's
relative path. Note that this function's success does not guarantee that
you are authorized to access the bucket's contents.

## Details

By default, `s3_bucket` and other
[`S3FileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
functions only produce output for fatal errors or when printing their
return values. When troubleshooting problems, it may be useful to
increase the log level. See the Notes section in
[`S3FileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
for more information or see Examples below.

## Examples

``` r
if (FALSE) {
bucket <- s3_bucket("arrow-datasets")
}
if (FALSE) {
# Turn on debug logging. The following line of code should be run in a fresh
# R session prior to any calls to `s3_bucket()` (or other S3 functions)
Sys.setenv("ARROW_S3_LOG_LEVEL" = "DEBUG")
bucket <- s3_bucket("arrow-datasets")
}
```
