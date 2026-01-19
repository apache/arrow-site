<div id="main" class="col-md-9" role="main">

# Create an Arrow Table

<div class="ref-description section level2">

Create an Arrow Table

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
arrow_table(..., schema = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    A `data.frame` or a named set of Arrays or vectors. If given a
    mixture of data.frames and named vectors, the inputs will be
    autospliced together (see examples). Alternatively, you can provide
    a single Arrow IPC `InputStream`, `Message`, `Buffer`, or R `raw`
    object containing a `Buffer`.

-   schema:

    a
    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md),
    or `NULL` (the default) to infer the schema from the data in `...`.
    When providing an Arrow IPC buffer, `schema` is required.

</div>

<div class="section level2">

## See also

<div class="dont-index">

[Table](https://arrow.apache.org/docs/r/reference/Table-class.md)

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tbl <- arrow_table(name = rownames(mtcars), mtcars)
dim(tbl)
#> [1] 32 12
dim(head(tbl))
#> [1]  6 12
names(tbl)
#>  [1] "name" "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"  
#> [11] "gear" "carb"
tbl$mpg
#> ChunkedArray
#> <double>
#> [
#>   [
#>     21,
#>     21,
#>     22.8,
#>     21.4,
#>     18.7,
#>     18.1,
#>     14.3,
#>     24.4,
#>     22.8,
#>     19.2,
#>     ...
#>     15.2,
#>     13.3,
#>     19.2,
#>     27.3,
#>     26,
#>     30.4,
#>     15.8,
#>     19.7,
#>     15,
#>     21.4
#>   ]
#> ]
tbl[["cyl"]]
#> ChunkedArray
#> <double>
#> [
#>   [
#>     6,
#>     6,
#>     4,
#>     6,
#>     8,
#>     6,
#>     8,
#>     4,
#>     4,
#>     6,
#>     ...
#>     8,
#>     8,
#>     8,
#>     4,
#>     4,
#>     4,
#>     8,
#>     6,
#>     8,
#>     4
#>   ]
#> ]
as.data.frame(tbl[4:8, c("gear", "hp", "wt")])
#>   gear  hp    wt
#> 1    3 110 3.215
#> 2    3 175 3.440
#> 3    3 105 3.460
#> 4    3 245 3.570
#> 5    4  62 3.190
```

</div>

</div>

</div>
