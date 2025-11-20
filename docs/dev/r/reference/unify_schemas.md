<div id="main" class="col-md-9" role="main">

# Combine and harmonize schemas

<div class="ref-description section level2">

Combine and harmonize schemas

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
unify_schemas(..., schemas = list(...))
```

</div>

</div>

<div class="section level2">

## Arguments

-   ...:

    [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)s
    to unify

-   schemas:

    Alternatively, a list of schemas

</div>

<div class="section level2">

## Value

A `Schema` with the union of fields contained in the inputs, or `NULL`
if any of `schemas` is `NULL`

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
a <- schema(b = double(), c = bool())
z <- schema(b = double(), k = utf8())
unify_schemas(a, z)
#> Schema
#> b: double
#> c: bool
#> k: string
```

</div>

</div>

</div>
