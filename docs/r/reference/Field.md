<div id="main" class="col-md-9" role="main">

# Create a Field

<div class="ref-description section level2">

Create a Field

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
field(name, type, metadata, nullable = TRUE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   name:

    field name

-   type:

    logical type, instance of
    [DataType](https://arrow.apache.org/docs/r/reference/DataType-class.md)

-   metadata:

    currently ignored

-   nullable:

    TRUE if field is nullable

</div>

<div class="section level2">

## See also

<div class="dont-index">

[Field](https://arrow.apache.org/docs/r/reference/Field-class.md)

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
field("x", int32())
#> Field
#> x: int32
```

</div>

</div>

</div>
