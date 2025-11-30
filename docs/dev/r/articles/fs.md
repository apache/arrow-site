<div id="main" class="col-md-9" role="main">

# Using cloud storage (S3, GCS)

Working with data stored in cloud storage systems like [Amazon Simple
Storage Service](https://docs.aws.amazon.com/s3/) (S3) and [Google Cloud
Storage](https://cloud.google.com/storage/docs) (GCS) is a very common
task. Because of this, the Arrow C++ library provides a toolkit aimed to
make it as simple to work with cloud storage as it is to work with the
local filesystem.

To make this work, the Arrow C++ library contains a general-purpose
interface for file systems, and the arrow package exposes this interface
to R users. For instance, if you want to you can create a
`LocalFileSystem` object that allows you to interact with the local file
system in the usual ways: copying, moving, and deleting files, obtaining
information about files and folders, and so on (see
`help("FileSystem", package = "arrow")` for details). In general you
probably don’t need this functionality because you already have tools
for working with your local file system, but this interface becomes much
more useful in the context of remote file systems. Currently there is a
specific implementation for Amazon S3 provided by the `S3FileSystem`
class, and another one for Google Cloud Storage provided by
`GcsFileSystem`.

This article provides an overview of working with both S3 and GCS data
using the Arrow toolkit.

<div class="section level2">

## S3 and GCS support on Linux

Before you start, make sure that your arrow install has support for S3
and/or GCS enabled. For most users this will be true by default, because
the Windows and macOS binary packages hosted on CRAN include S3 and GCS
support. You can check whether support is enabled via helper functions:

<div id="cb1" class="sourceCode">

``` r
arrow_with_s3()
arrow_with_gcs()
```

</div>

If these return `TRUE` then the relevant support is enabled.

In some cases you may find that your system does not have support
enabled. The most common case for this occurs on Linux when installing
arrow from source. In this situation S3 and GCS support is not always
enabled by default, and there are additional system requirements
involved. See the [installation
article](https://arrow.apache.org/docs/r/articles/install.md) for
details on how to resolve this.

</div>

<div class="section level2">

## Connecting to cloud storage

One way of working with filesystems is to create `?FileSystem` objects.
`?S3FileSystem` objects can be created with the `s3_bucket()` function,
which automatically detects the bucket’s AWS region. Similarly,
`?GcsFileSystem` objects can be created with the `gs_bucket()` function.
The resulting `FileSystem` will consider paths relative to the bucket’s
path (so for example you don’t need to prefix the bucket path when
listing a directory).

With a `FileSystem` object, you can point to specific files in it with
the `$path()` method and pass the result to file readers and writers
(`read_parquet()`, `write_feather()`, et al.).

Often the reason users work with cloud storage in real world analysis is
to access large data sets. An example of this is discussed in the
[datasets article](https://arrow.apache.org/docs/r/articles/dataset.md),
but new users may prefer to work with a much smaller data set while
learning how the arrow cloud storage interface works. To that end, the
examples in this article rely on a multi-file Parquet dataset that
stores a copy of the `diamonds` data made available through the
[`ggplot2`](https://ggplot2.tidyverse.org/) package, documented in
`help("diamonds", package = "ggplot2")`. The cloud storage version of
this data set consists of 5 Parquet files totaling less than 1MB in
size.

The diamonds data set is hosted on both S3 and GCS, in a bucket named
`arrow-datasets`. To create an S3FileSystem object that refers to that
bucket, use the following command:

<div id="cb2" class="sourceCode">

``` r
bucket <- s3_bucket("arrow-datasets")
```

</div>

To do this for the GCS version of the data, the command is as follows:

<div id="cb3" class="sourceCode">

``` r
bucket <- gs_bucket("arrow-datasets", anonymous = TRUE)
```

</div>

Note that `anonymous = TRUE` is required for GCS if credentials have not
been configured.

Within this bucket there is a folder called `diamonds`. We can call
`bucket$ls("diamonds")` to list the files stored in this folder, or
`bucket$ls("diamonds", recursive = TRUE)` to recursively search
subfolders. Note that on GCS, you should always set `recursive = TRUE`
because directories often don’t appear in the results.

Here’s what we get when we list the files stored in the GCS bucket:

<div id="cb4" class="sourceCode">

``` r
bucket$ls("diamonds", recursive = TRUE)
```

</div>

<div id="cb5" class="sourceCode">

``` r
## [1] "diamonds/cut=Fair/part-0.parquet"     
## [2] "diamonds/cut=Good/part-0.parquet"     
## [3] "diamonds/cut=Ideal/part-0.parquet"    
## [4] "diamonds/cut=Premium/part-0.parquet"  
## [5] "diamonds/cut=Very Good/part-0.parquet"
```

</div>

There are 5 Parquet files here, one corresponding to each of the “cut”
categories in the `diamonds` data set. We can specify the path to a
specific file by calling `bucket$path()`:

<div id="cb6" class="sourceCode">

``` r
parquet_good <- bucket$path("diamonds/cut=Good/part-0.parquet")
```

</div>

We can use `read_parquet()` to read from this path directly into R:

<div id="cb7" class="sourceCode">

``` r
diamonds_good <- read_parquet(parquet_good)
diamonds_good
```

</div>

<div id="cb8" class="sourceCode">

``` r
## # A tibble: 4,906 × 9
##    carat color clarity depth table price     x     y     z
##    <dbl> <ord> <ord>   <dbl> <dbl> <int> <dbl> <dbl> <dbl>
##  1  0.23 E     VS1      56.9    65   327  4.05  4.07  2.31
##  2  0.31 J     SI2      63.3    58   335  4.34  4.35  2.75
##  3  0.3  J     SI1      64      55   339  4.25  4.28  2.73
##  4  0.3  J     SI1      63.4    54   351  4.23  4.29  2.7 
##  5  0.3  J     SI1      63.8    56   351  4.23  4.26  2.71
##  6  0.3  I     SI2      63.3    56   351  4.26  4.3   2.71
##  7  0.23 F     VS1      58.2    59   402  4.06  4.08  2.37
##  8  0.23 E     VS1      64.1    59   402  3.83  3.85  2.46
##  9  0.31 H     SI1      64      54   402  4.29  4.31  2.75
## 10  0.26 D     VS2      65.2    56   403  3.99  4.02  2.61
## # … with 4,896 more rows
## # ℹ Use `print(n = ...)` to see more rows
```

</div>

Note that this will be slower to read than if the file were local.

</div>

<div class="section level2">

## Connecting directly with a URI

In most use cases, the easiest and most natural way to connect to cloud
storage in arrow is to use the FileSystem objects returned by
`s3_bucket()` and `gs_bucket()`, especially when multiple file
operations are required. However, in some cases you may want to download
a file directly by specifying the URI. This is permitted by arrow, and
functions like `read_parquet()`, `write_feather()`, `open_dataset()` etc
will all accept URIs to cloud resources hosted on S3 or GCS. The format
of an S3 URI is as follows:

    s3://[access_key:secret_key@]bucket/path[?region=]

For GCS, the URI format looks like this:

    gs://[access_key:secret_key@]bucket/path
    gs://anonymous@bucket/path

For example, the Parquet file storing the “good cut” diamonds that we
downloaded earlier in the article is available on both S3 and CGS. The
relevant URIs are as follows:

<div id="cb11" class="sourceCode">

``` r
uri <- "s3://arrow-datasets/diamonds/cut=Good/part-0.parquet"
uri <- "gs://anonymous@arrow-datasets/diamonds/cut=Good/part-0.parquet"
```

</div>

Note that “anonymous” is required on GCS for public buckets. Regardless
of which version you use, you can pass this URI to `read_parquet()` as
if the file were stored locally:

<div id="cb12" class="sourceCode">

``` r
df <- read_parquet(uri)
```

</div>

URIs accept additional options in the query parameters (the part after
the `?`) that are passed down to configure the underlying file system.
They are separated by `&`. For example,

    s3://arrow-datasets/?endpoint_override=https%3A%2F%2Fstorage.googleapis.com&allow_bucket_creation=true

is equivalent to:

<div id="cb14" class="sourceCode">

``` r
bucket <- S3FileSystem$create(
  endpoint_override="https://storage.googleapis.com",
  allow_bucket_creation=TRUE
)
bucket$path("arrow-datasets/")
```

</div>

Both tell the `S3FileSystem` object that it should allow the creation of
new buckets and to talk to Google Storage instead of S3. The latter
works because GCS implements an S3-compatible API – see [File systems
that emulate S3](#file-systems-that-emulate-s3) below – but if you want
better support for GCS you should refer to a `GcsFileSystem` but using a
URI that starts with `gs://`.

Also note that parameters in the URI need to be [percent
encoded](https://en.wikipedia.org/wiki/Percent-encoding), which is why
`://` is written as `%3A%2F%2F`.

For S3, only the following options can be included in the URI as query
parameters are `region`, `scheme`, `endpoint_override`, `access_key`,
`secret_key`, `allow_bucket_creation`, `allow_bucket_deletion` and
`check_directory_existence_before_creation`. For GCS, the supported
parameters are `scheme`, `endpoint_override`, and `retry_limit_seconds`.

In GCS, a useful option is `retry_limit_seconds`, which sets the number
of seconds a request may spend retrying before returning an error. The
current default is 15 minutes, so in many interactive contexts it’s nice
to set a lower value:

    gs://anonymous@arrow-datasets/diamonds/?retry_limit_seconds=10

</div>

<div class="section level2">

## Authentication

<div class="section level3">

### S3 Authentication

To access private S3 buckets, you need typically need two secret
parameters: a `access_key`, which is like a user id, and `secret_key`,
which is like a token or password. There are a few options for passing
these credentials:

-   Include them in the URI, like
    `s3://access_key:secret_key@bucket-name/path/to/file`. Be sure to
    [URL-encode](https://en.wikipedia.org/wiki/Percent-encoding) your
    secrets if they contain special characters like “/” (e.g.,
    `URLencode("123/456", reserved = TRUE)`).

-   Pass them as `access_key` and `secret_key` to
    `S3FileSystem$create()` or `s3_bucket()`

-   Set them as environment variables named `AWS_ACCESS_KEY_ID` and
    `AWS_SECRET_ACCESS_KEY`, respectively.

-   Define them in a `~/.aws/credentials` file, according to the [AWS
    documentation](https://docs.aws.amazon.com/sdk-for-cpp/v1/developer-guide/credentials.html).

-   Use an
    [AccessRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
    for temporary access by passing the `role_arn` identifier to
    `S3FileSystem$create()` or `s3_bucket()`.

</div>

<div class="section level3">

### GCS Authentication

The simplest way to authenticate with GCS is to run the
[gcloud](https://cloud.google.com/sdk/docs/) command to setup
application default credentials:

    gcloud auth application-default login

To manually configure credentials, you can pass either `access_token`
and `expiration`, for using temporary tokens generated elsewhere, or
`json_credentials`, to reference a downloaded credentials file.

If you haven’t configured credentials, then to access *public* buckets,
you must pass `anonymous = TRUE` or `anonymous` as the user in a URI:

<div id="cb17" class="sourceCode">

``` r
bucket <- gs_bucket("arrow-datasets", anonymous = TRUE)
fs <- GcsFileSystem$create(anonymous = TRUE)
df <- read_parquet("gs://anonymous@arrow-datasets/diamonds/cut=Good/part-0.parquet")
```

</div>

</div>

</div>

<div class="section level2">

## Using a proxy server

If you need to use a proxy server to connect to an S3 bucket, you can
provide a URI in the form `http://user:password@host:port` to
`proxy_options`. For example, a local proxy server running on port 1316
can be used like this:

<div id="cb18" class="sourceCode">

``` r
bucket <- s3_bucket(
  bucket = "arrow-datasets", 
  proxy_options = "http://localhost:1316"
)
```

</div>

</div>

<div class="section level2">

## File systems that emulate S3

The `S3FileSystem` machinery enables you to work with any file system
that provides an S3-compatible interface. For example,
[MinIO](https://min.io/) is and object-storage server that emulates the
S3 API. If you were to run `minio server` locally with its default
settings, you could connect to it with arrow using `S3FileSystem` like
this:

<div id="cb19" class="sourceCode">

``` r
minio <- S3FileSystem$create(
  access_key = "minioadmin",
  secret_key = "minioadmin",
  scheme = "http",
  endpoint_override = "localhost:9000"
)
```

</div>

or, as a URI, it would be

    s3://minioadmin:minioadmin@?scheme=http&endpoint_override=localhost%3A9000

(Note the URL escaping of the `:` in `endpoint_override`).

Among other applications, this can be useful for testing out code
locally before running on a remote S3 bucket.

</div>

<div class="section level2">

## Disabling environment variables

As mentioned above, it is possible to make use of environment variables
to configure access. However, if you wish to pass in connection details
via a URI or alternative methods but also have existing AWS environment
variables defined, these may interfere with your session. For example,
you may see an error message like:

<div id="cb21" class="sourceCode">

``` r
Error: IOError: When resolving region for bucket 'analysis': AWS Error [code 99]: curlCode: 6, Couldn't resolve host name 
```

</div>

You can unset these environment variables using `Sys.unsetenv()`, for
example:

<div id="cb22" class="sourceCode">

``` r
Sys.unsetenv("AWS_DEFAULT_REGION")
Sys.unsetenv("AWS_S3_ENDPOINT")
```

</div>

By default, the AWS SDK tries to retrieve metadata about user
configuration, which can cause conflicts when passing in connection
details via URI (for example when accessing a MINIO bucket). To disable
the use of AWS environment variables, you can set environment variable
`AWS_EC2_METADATA_DISABLED` to `TRUE`.

<div id="cb23" class="sourceCode">

``` r
Sys.setenv(AWS_EC2_METADATA_DISABLED = TRUE)
```

</div>

</div>

<div class="section level2">

## Further reading

-   To learn more about `FileSystem` classes, including `S3FileSystem`
    and `GcsFileSystem`, see `help("FileSystem", package = "arrow")`.
-   To see a data analysis example that relies on data hosted on cloud
    storage, see the [dataset
    article](https://arrow.apache.org/docs/r/articles/dataset.md).

</div>

</div>
