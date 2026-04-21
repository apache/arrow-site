# Combine and harmonize schemas

Combine and harmonize schemas

## Usage

``` r
unify_schemas(..., schemas = list(...))
```

## Arguments

- ...:

  [Schema](https://arrow.apache.org/docs/r/reference/Schema-class.md)s
  to unify

- schemas:

  Alternatively, a list of schemas

## Value

A `Schema` with the union of fields contained in the inputs, or `NULL`
if any of `schemas` is `NULL`

## Examples

``` r
a <- schema(b = double(), c = bool())
z <- schema(b = double(), k = utf8())
unify_schemas(a, z)
#> Schema
#> b: double
#> c: bool
#> k: string
```
