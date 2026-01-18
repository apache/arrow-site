<div id="main" class="col-md-9" role="main">

# Create a dictionary type

<div class="ref-description section level2">

Create a dictionary type

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
dictionary(index_type = int32(), value_type = utf8(), ordered = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   index_type:

    A DataType for the indices (default `int32()`)

-   value_type:

    A DataType for the values (default `utf8()`)

-   ordered:

    Is this an ordered dictionary (default `FALSE`)?

</div>

<div class="section level2">

## Value

A
[DictionaryType](https://arrow.apache.org/docs/r/reference/DictionaryType.md)

</div>

<div class="section level2">

## See also

<div class="dont-index">

[Other Arrow data
types](https://arrow.apache.org/docs/r/reference/data-type.md)

</div>

</div>

</div>
