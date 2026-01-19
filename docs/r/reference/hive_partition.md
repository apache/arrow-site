<div id="main" class="col-md-9" role="main">

# Construct Hive partitioning

<div class="ref-description section level2">

Hive partitioning embeds field names and values in path segments, such
as "/year=2019/month=2/data.parquet".

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
hive_partition(..., null_fallback = NULL, segment_encoding = "uri")
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    named list of [data
    types](https://arrow.apache.org/docs/r/reference/data-type.md),
    passed to `schema()`

-   null_fallback:

    character to be used in place of missing values (`NA` or `NULL`) in
    partition columns. Default is `"__HIVE_DEFAULT_PARTITION__"`, which
    is what Hive uses.

-   segment_encoding:

    Decode partition segments after splitting paths. Default is `"uri"`
    (URI-decode segments). May also be `"none"` (leave as-is).

</div>

<div class="section level2">

## Value

A
[HivePartitioning](https://arrow.apache.org/docs/r/reference/Partitioning.md),
or a `HivePartitioningFactory` if calling `hive_partition()` with no
arguments.

</div>

<div class="section level2">

## Details

Because fields are named in the path segments, order of fields passed to
`hive_partition()` does not matter.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
hive_partition(year = int16(), month = int8())
#> HivePartitioning
```

</div>

</div>

</div>
