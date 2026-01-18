<div id="main" class="col-md-9" role="main">

# FileSystem classes

<div class="ref-description section level2">

`FileSystem` is an abstract file system API, `LocalFileSystem` is an
implementation accessing files on the local machine. `SubTreeFileSystem`
is an implementation that delegates to another implementation after
prepending a fixed base path

</div>

<div class="section level2">

## Factory

`LocalFileSystem$create()` returns the object and takes no arguments.

`SubTreeFileSystem$create()` takes the following arguments:

-   `base_path`, a string path

-   `base_fs`, a `FileSystem` object

`S3FileSystem$create()` optionally takes arguments:

-   `anonymous`: logical, default `FALSE`. If true, will not attempt to
    look up credentials using standard AWS configuration methods.

-   `access_key`, `secret_key`: authentication credentials. If one is
    provided, the other must be as well. If both are provided, they will
    override any AWS configuration set at the environment level.

-   `session_token`: optional string for authentication along with
    `access_key` and `secret_key`

-   `role_arn`: string AWS ARN of an AccessRole. If provided instead of
    `access_key` and `secret_key`, temporary credentials will be fetched
    by assuming this role.

-   `session_name`: optional string identifier for the assumed role
    session.

-   `external_id`: optional unique string identifier that might be
    required when you assume a role in another account.

-   `load_frequency`: integer, frequency (in seconds) with which
    temporary credentials from an assumed role session will be
    refreshed. Default is 900 (i.e. 15 minutes)

-   `region`: AWS region to connect to. If omitted, the AWS library will
    provide a sensible default based on client configuration, falling
    back to "us-east-1" if no other alternatives are found.

-   `endpoint_override`: If non-empty, override region with a connect
    string such as "localhost:9000". This is useful for connecting to
    file systems that emulate S3.

-   `scheme`: S3 connection transport (default "https")

-   `proxy_options`: optional string, URI of a proxy to use when
    connecting to S3

-   `background_writes`: logical, whether `OutputStream` writes will be
    issued in the background, without blocking (default `TRUE`)

-   `allow_bucket_creation`: logical, if TRUE, the filesystem will
    create buckets if `$CreateDir()` is called on the bucket level
    (default `FALSE`).

-   `allow_bucket_deletion`: logical, if TRUE, the filesystem will
    delete buckets if`$DeleteDir()` is called on the bucket level
    (default `FALSE`).

-   `check_directory_existence_before_creation`: logical, check if
    directory already exists or not before creation. Helpful for cloud
    storage operations where object mutation operations are rate limited
    or existing directories are read-only. (default `FALSE`).

-   `request_timeout`: Socket read time on Windows and macOS in seconds.
    If negative, the AWS SDK default (typically 3 seconds).

-   `connect_timeout`: Socket connection timeout in seconds. If
    negative, AWS SDK default is used (typically 1 second).

`GcsFileSystem$create()` optionally takes arguments:

-   `anonymous`: logical, default `FALSE`. If true, will not attempt to
    look up credentials using standard GCS configuration methods.

-   `access_token`: optional string for authentication. Should be
    provided along with `expiration`

-   `expiration`: `POSIXct`. optional datetime representing point at
    which `access_token` will expire.

-   `json_credentials`: optional string for authentication. Either a
    string containing JSON credentials or a path to their location on
    the filesystem. If a path to credentials is given, the file should
    be UTF-8 encoded.

-   `endpoint_override`: if non-empty, will connect to provided host
    name / port, such as "localhost:9001", instead of default GCS ones.
    This is primarily useful for testing purposes.

-   `scheme`: connection transport (default "https")

-   `default_bucket_location`: the default location (or "region") to
    create new buckets in.

-   `retry_limit_seconds`: the maximum amount of time to spend retrying
    if the filesystem encounters errors. Default is 15 seconds.

-   `default_metadata`: default metadata to write in new objects.

-   `project_id`: the project to use for creating buckets.

</div>

<div class="section level2">

## Methods

-   `path(x)`: Create a `SubTreeFileSystem` from the current
    `FileSystem` rooted at the specified path `x`.

-   `cd(x)`: Create a `SubTreeFileSystem` from the current `FileSystem`
    rooted at the specified path `x`.

-   `ls(path, ...)`: List files or objects at the given path or from the
    root of the `FileSystem` if `path` is not provided. Additional
    arguments passed to `FileSelector$create`, see
    [FileSelector](https://arrow.apache.org/docs/r/reference/FileSelector.md).

-   `$GetFileInfo(x)`: `x` may be a
    [FileSelector](https://arrow.apache.org/docs/r/reference/FileSelector.md)
    or a character vector of paths. Returns a list of
    [FileInfo](https://arrow.apache.org/docs/r/reference/FileInfo.md)

-   `$CreateDir(path, recursive = TRUE)`: Create a directory and
    subdirectories.

-   `$DeleteDir(path)`: Delete a directory and its contents,
    recursively.

-   `$DeleteDirContents(path)`: Delete a directory's contents,
    recursively. Like `$DeleteDir()`, but doesn't delete the directory
    itself. Passing an empty path (`""`) will wipe the entire filesystem
    tree.

-   `$DeleteFile(path)` : Delete a file.

-   `$DeleteFiles(paths)` : Delete many files. The default
    implementation issues individual delete operations in sequence.

-   `$Move(src, dest)`: Move / rename a file or directory. If the
    destination exists: if it is a non-empty directory, an error is
    returned otherwise, if it has the same type as the source, it is
    replaced otherwise, behavior is unspecified
    (implementation-dependent).

-   `$CopyFile(src, dest)`: Copy a file. If the destination exists and
    is a directory, an error is returned. Otherwise, it is replaced.

-   `$OpenInputStream(path)`: Open an [input
    stream](https://arrow.apache.org/docs/r/reference/InputStream.md)
    for sequential reading.

-   `$OpenInputFile(path)`: Open an [input
    file](https://arrow.apache.org/docs/r/reference/InputStream.md) for
    random access reading.

-   `$OpenOutputStream(path)`: Open an [output
    stream](https://arrow.apache.org/docs/r/reference/OutputStream.md)
    for sequential writing.

-   `$OpenAppendStream(path)`: Open an [output
    stream](https://arrow.apache.org/docs/r/reference/OutputStream.md)
    for appending.

</div>

<div class="section level2">

## Active bindings

-   `$type_name`: string filesystem type name, such as "local", "s3",
    etc.

-   `$region`: string AWS region, for `S3FileSystem` and
    `SubTreeFileSystem` containing a `S3FileSystem`

-   `$base_fs`: for `SubTreeFileSystem`, the `FileSystem` it contains

-   `$base_path`: for `SubTreeFileSystem`, the path in `$base_fs` which
    is considered root in this `SubTreeFileSystem`.

-   `$options`: for `GcsFileSystem`, the options used to create the
    `GcsFileSystem` instance as a `list`

</div>

<div class="section level2">

## Notes

On S3FileSystem, `$CreateDir()` on a top-level directory creates a new
bucket. When S3FileSystem creates new buckets (assuming
allow_bucket_creation is TRUE), it does not pass any non-default
settings. In AWS S3, the bucket and all objects will be not publicly
visible, and will have no bucket policies and no resource tags. To have
more control over how buckets are created, use a different API to create
them.

On S3FileSystem, output is only produced for fatal errors or when
printing return values. For troubleshooting, the log level can be set
using the environment variable `ARROW_S3_LOG_LEVEL` (e.g.,
`Sys.setenv("ARROW_S3_LOG_LEVEL"="DEBUG")`). The log level must be set
prior to running any code that interacts with S3. Possible values
include 'FATAL' (the default), 'ERROR', 'WARN', 'INFO', 'DEBUG'
(recommended), 'TRACE', and 'OFF'.

</div>

</div>
