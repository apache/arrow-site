<div id="main" class="col-md-9" role="main">

# Create a schema or extract one from an object.

<div class="ref-description section level2">

Create a schema or extract one from an object.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
schema(...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    [fields](https://arrow.apache.org/docs/r/reference/Field.md), field
    name/[data
    type](https://arrow.apache.org/docs/r/reference/data-type.md) pairs
    (or a list of), or object from which to extract a schema

</div>

<div class="section level2">

## See also

<div class="dont-index">

[Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md) for
detailed documentation of the Schema R6 object

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Create schema using pairs of field names and data types
schema(a = int32(), b = float64())
#> Schema
#> a: int32
#> b: double

# Create a schema using a list of pairs of field names and data types
schema(list(a = int8(), b = string()))
#> Schema
#> a: int8
#> b: string

# Create schema using fields
schema(
  field("b", double()),
  field("c", bool(), nullable = FALSE),
  field("d", string())
)
#> Schema
#> b: double
#> c: bool not null
#> d: string

# Extract schemas from objects
df <- data.frame(col1 = 2:4, col2 = c(0.1, 0.3, 0.5))
tab1 <- arrow_table(df)
schema(tab1)
#> Schema
#> col1: int32
#> col2: double
#> 
#> See $metadata for additional Schema metadata
tab2 <- arrow_table(df, schema = schema(col1 = int8(), col2 = float32()))
schema(tab2)
#> Schema
#> col1: int8
#> col2: float
#> 
#> See $metadata for additional Schema metadata
```

</div>

</div>

</div>
