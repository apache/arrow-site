<div id="main" class="col-md-9" role="main">

# Arrow expressions

<div class="ref-description section level2">

`Expression`s are used to define filter logic for passing to a
[Dataset](https://arrow.apache.org/docs/r/reference/Dataset.md)
[Scanner](https://arrow.apache.org/docs/r/reference/Scanner.md).

`Expression$scalar(x)` constructs an `Expression` which always evaluates
to the provided scalar (length-1) R value.

`Expression$field_ref(name)` is used to construct an `Expression` which
evaluates to the named column in the `Dataset` against which it is
evaluated.

`Expression$create(function_name, ..., options)` builds a function-call
`Expression` containing one or more `Expression`s. Anything in `...`
that is not already an expression will be wrapped in
`Expression$scalar()`.

`Expression$op(FUN, ...)` is for logical and arithmetic operators.
Scalar inputs in `...` will be attempted to be cast to the common type
of the `Expression`s in the call so that the types of the columns in the
`Dataset` are preserved and not unnecessarily upcast, which may be
expensive.

</div>

</div>
