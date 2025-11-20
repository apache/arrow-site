<div id="main" class="col-md-9" role="main">

# Scan the contents of a dataset

<div class="ref-description section level2">

A `Scanner` iterates over a
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md)'s
fragments and returns data according to given row filtering and column
projection. A `ScannerBuilder` can help create one.

</div>

<div class="section level2">

## Factory

`Scanner$create()` wraps the `ScannerBuilder` interface to make a
`Scanner`. It takes the following arguments:

-   `dataset`: A `Dataset` or `arrow_dplyr_query` object, as returned by
    the `dplyr` methods on `Dataset`.

-   `projection`: A character vector of column names to select columns
    or a named list of expressions

-   `filter`: A `Expression` to filter the scanned rows by, or `TRUE`
    (default) to keep all rows.

-   `use_threads`: logical: should scanning use multithreading? Default
    `TRUE`

-   `...`: Additional arguments, currently ignored

</div>

<div class="section level2">

## Methods

`ScannerBuilder` has the following methods:

-   `$Project(cols)`: Indicate that the scan should only return columns
    given by `cols`, a character vector of column names or a named list
    of
    [Expression](https://arrow.apache.org/docs/r/reference/Expression.md).

-   `$Filter(expr)`: Filter rows by an
    [Expression](https://arrow.apache.org/docs/r/reference/Expression.md).

-   `$UseThreads(threads)`: logical: should the scan use multithreading?
    The method's default input is `TRUE`, but you must call the method
    to enable multithreading because the scanner default is `FALSE`.

-   `$BatchSize(batch_size)`: integer: Maximum row count of scanned
    record batches, default is 32K. If scanned record batches are
    overflowing memory then this method can be called to reduce their
    size.

-   `$schema`: Active binding, returns the
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)
    of the Dataset

-   `$Finish()`: Returns a `Scanner`

`Scanner` currently has a single method, `$ToTable()`, which evaluates
the query and returns an Arrow
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Set up directory for examples
tf <- tempfile()
dir.create(tf)
on.exit(unlink(tf))

write_dataset(mtcars, tf, partitioning="cyl")

ds <- open_dataset(tf)

scan_builder <- ds$NewScan()
scan_builder$Filter(Expression$field_ref("hp") > 100)
#> ScannerBuilder
scan_builder$Project(list(hp_times_ten = 10 * Expression$field_ref("hp")))
#> ScannerBuilder

# Once configured, call $Finish()
scanner <- scan_builder$Finish()

# Can get results as a table
as.data.frame(scanner$ToTable())
#>    hp_times_ten
#> 1          1130
#> 2          1090
#> 3          1100
#> 4          1100
#> 5          1100
#> 6          1050
#> 7          1230
#> 8          1230
#> 9          1750
#> 10         1750
#> 11         2450
#> 12         1800
#> 13         1800
#> 14         1800
#> 15         2050
#> 16         2150
#> 17         2300
#> 18         1500
#> 19         1500
#> 20         2450
#> 21         1750
#> 22         2640
#> 23         3350

# Or as a RecordBatchReader
scanner$ToRecordBatchReader()
#> RecordBatchReader
#> 1 columns
#> hp_times_ten: double
#> 
#> See $metadata for additional Schema metadata
```

</div>

</div>

</div>
