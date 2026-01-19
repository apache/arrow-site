<div id="main" class="col-md-9" role="main">

# file selector

<div class="ref-description section level2">

file selector

</div>

<div class="section level2">

## Factory

The `$create()` factory method instantiates a `FileSelector` given the 3
fields described below.

</div>

<div class="section level2">

## Fields

-   `base_dir`: The directory in which to select files. If the path
    exists but doesn't point to a directory, this should be an error.

-   `allow_not_found`: The behavior if `base_dir` doesn't exist in the
    filesystem. If `FALSE`, an error is returned. If `TRUE`, an empty
    selection is returned

-   `recursive`: Whether to recurse into subdirectories.

</div>

</div>
