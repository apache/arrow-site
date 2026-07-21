# Connect to an Azure Blob Storage container

`az_conainer` is a convenience function to create an `AzureFileSystem`
object that provides a file system interface for blob storage containers
in an Azure Storage Account.

## Usage

``` r
az_container(container_path, ...)
```

## Arguments

- container_path:

  string Container name or path.

- ...:

  Additional connection options, passed to `AzureFileSystem$create()`.

## Value

A `SubTreeFileSystem` containing an `AzureFileSystem` and the
container's relative path. Note that this function's success does not
guarantee that you are authorized to access the container's contents.

## Examples

``` r
if (FALSE) {
container_fs <- az_container(
  container_path = "arrow-datasets",
  account_name = azurite_account_name,
  account_key = azurite_account_key,
  blob_storage_authority = azurite_blob_storage_authority,
  blob_storage_scheme = azurite_blob_storage_scheme
)
}
```
