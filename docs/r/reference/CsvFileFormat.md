<div id="main" class="col-md-9" role="main">

# CSV dataset file format

<div class="ref-description section level2">

A `CSVFileFormat` is a
[FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)
subclass which holds information about how to read and parse the files
included in a CSV `Dataset`.

</div>

<div class="section level2">

## Value

A `CsvFileFormat` object

</div>

<div class="section level2">

## Factory

`CSVFileFormat$create()` can take options in the form of lists passed
through as `parse_options`, `read_options`, or `convert_options`
parameters. Alternatively, readr-style options can be passed through
individually. While it is possible to pass in `CSVReadOptions`,
`CSVConvertOptions`, and `CSVParseOptions` objects, this is not
recommended as options set in these objects are not validated for
compatibility.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[FileFormat](https://arrow.apache.org/docs/r/reference/FileFormat.md)

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Set up directory for examples
tf <- tempfile()
dir.create(tf)
on.exit(unlink(tf))
df <- data.frame(x = c("1", "2", "NULL"))
write.table(df, file.path(tf, "file1.txt"), sep = ",", row.names = FALSE)

# Create CsvFileFormat object with Arrow-style null_values option
format <- CsvFileFormat$create(convert_options = list(null_values = c("", "NA", "NULL")))
open_dataset(tf, format = format)
#> FileSystemDataset with 1 csv file
#> 1 columns
#> x: int64

# Use readr-style options
format <- CsvFileFormat$create(na = c("", "NA", "NULL"))
open_dataset(tf, format = format)
#> FileSystemDataset with 1 csv file
#> 1 columns
#> x: int64
```

</div>

</div>

</div>
