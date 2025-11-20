<div id="main" class="col-md-9" role="main">

# Functions available in Arrow dplyr queries

<div class="ref-description section level2">

The `arrow` package contains methods for 37 `dplyr` table functions,
many of which are "verbs" that do transformations to one or more tables.
The package also has mappings of 223 R functions to the corresponding
functions in the Arrow compute library. These allow you to write code
inside of `dplyr` methods that call R functions, including many in
packages like `stringr` and `lubridate`, and they will get translated to
Arrow and run on the Arrow query engine (Acero). This document lists all
of the mapped functions.

</div>

<div class="section level2">

## `dplyr` verbs

Most verb functions return an `arrow_dplyr_query` object, similar in
spirit to a `dbplyr::tbl_lazy`. This means that the verbs do not eagerly
evaluate the query on the data. To run the query, call either
`compute()`, which returns an `arrow`
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md), or
`collect()`, which pulls the resulting Table into an R `tibble`.

-   `anti_join()`: the `copy` argument is ignored

-   `arrange()`

-   `collapse()`

-   `collect()`

-   `compute()`

-   `count()`

-   `distinct()`: `.keep_all = TRUE` returns a non-missing value if
    present, only returning missing values if all are missing.

-   `explain()`

-   `filter()`

-   `full_join()`: the `copy` argument is ignored

-   `glimpse()`

-   `group_by()`

-   `group_by_drop_default()`

-   `group_vars()`

-   `groups()`

-   `inner_join()`: the `copy` argument is ignored

-   `left_join()`: the `copy` argument is ignored

-   `mutate()`

-   `pull()`: the `name` argument is not supported; returns an R vector
    by default but this behavior is deprecated and will return an Arrow
    [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
    in a future release. Provide `as_vector = TRUE/FALSE` to control
    this behavior, or set `options(arrow.pull_as_vector)` globally.

-   `relocate()`

-   `rename()`

-   `rename_with()`

-   `right_join()`: the `copy` argument is ignored

-   `select()`

-   `semi_join()`: the `copy` argument is ignored

-   `show_query()`

-   `slice_head()`: slicing within groups not supported; Arrow datasets
    do not have row order, so head is non-deterministic; `prop` only
    supported on queries where `nrow()` is knowable without evaluating

-   `slice_max()`: slicing within groups not supported;
    `with_ties = TRUE` (dplyr default) is not supported; `prop` only
    supported on queries where `nrow()` is knowable without evaluating

-   `slice_min()`: slicing within groups not supported;
    `with_ties = TRUE` (dplyr default) is not supported; `prop` only
    supported on queries where `nrow()` is knowable without evaluating

-   `slice_sample()`: slicing within groups not supported;
    `replace = TRUE` and the `weight_by` argument not supported; `n`
    only supported on queries where `nrow()` is knowable without
    evaluating

-   `slice_tail()`: slicing within groups not supported; Arrow datasets
    do not have row order, so tail is non-deterministic; `prop` only
    supported on queries where `nrow()` is knowable without evaluating

-   `summarise()`: window functions not currently supported; arguments
    `.drop = FALSE` and `.groups = "rowwise"` not supported

-   `tally()`

-   `transmute()`

-   `ungroup()`

-   `union()`

-   `union_all()`

</div>

<div class="section level2">

## Function mappings

In the list below, any differences in behavior or support between Acero
and the R function are listed. If no notes follow the function name,
then you can assume that the function works in Acero just as it does in
R.

Functions can be called either as `pkg::fun()` or just `fun()`, i.e.
both `str_sub()` and `stringr::str_sub()` work.

In addition to these functions, you can call any of Arrow's 281 compute
functions directly. Arrow has many functions that don't map to an
existing R function. In other cases where there is an R function
mapping, you can still call the Arrow function directly if you don't
want the adaptations that the R mapping has that make Acero behave like
R. These functions are listed in the [C++
documentation](https://arrow.apache.org/docs/cpp/compute.html), and in
the function registry in R, they are named with an `arrow_` prefix, such
as `arrow_ascii_is_decimal`.

<div class="section">

### arrow

-   `add_filename()`

-   `cast()`

</div>

<div class="section">

### base

-   `!`

-   `!=`

-   `%%`

-   `%/%`

-   `%in%`

-   `&`

-   `*`

-   `+`

-   `-`

-   `/`

-   `<`

-   `<=`

-   `==`

-   `>`

-   `>=`

-   `ISOdate()`

-   `ISOdatetime()`

-   `^`

-   `abs()`

-   `acos()`

-   `acosh()`

-   `all()`

-   `any()`

-   `as.Date()`: Multiple `tryFormats` not supported in Arrow. Consider
    using the lubridate specialised parsing functions `ymd()`, `ymd()`,
    etc.

-   `as.character()`

-   `as.difftime()`: only supports `units = "secs"` (the default)

-   `as.double()`

-   `as.integer()`

-   `as.logical()`

-   `as.numeric()`

-   `asin()`

-   `asinh()`

-   `atan()`

-   `atanh()`

-   `ceiling()`

-   `cos()`

-   `cosh()`

-   `data.frame()`: `row.names` and `check.rows` arguments not
    supported; `stringsAsFactors` must be `FALSE`

-   `difftime()`: only supports `units = "secs"` (the default); `tz`
    argument not supported

-   `endsWith()`

-   `exp()`

-   `expm1()`

-   `floor()`

-   `format()`

-   `grepl()`

-   `gsub()`

-   `ifelse()`

-   `is.character()`

-   `is.double()`

-   `is.factor()`

-   `is.finite()`

-   `is.infinite()`

-   `is.integer()`

-   `is.list()`

-   `is.logical()`

-   `is.na()`

-   `is.nan()`

-   `is.numeric()`

-   `log()`

-   `log10()`

-   `log1p()`

-   `log2()`

-   `logb()`

-   `max()`

-   `mean()`

-   `min()`

-   `nchar()`: `allowNA = TRUE` and `keepNA = TRUE` not supported

-   `paste()`: the `collapse` argument is not yet supported

-   `paste0()`: the `collapse` argument is not yet supported

-   `pmax()`

-   `pmin()`

-   `prod()`

-   `round()`

-   `sign()`

-   `sin()`

-   `sinh()`

-   `sqrt()`

-   `startsWith()`

-   `strftime()`

-   `strptime()`: accepts a `unit` argument not present in the `base`
    function. Valid values are "s", "ms" (default), "us", "ns".

-   `strrep()`

-   `strsplit()`

-   `sub()`

-   `substr()`: `start` and `stop` must be length 1

-   `substring()`

-   `sum()`

-   `tan()`

-   `tanh()`

-   `tolower()`

-   `toupper()`

-   `trunc()`

-   `|`

</div>

<div class="section">

### bit64

-   `as.integer64()`

-   `is.integer64()`

</div>

<div class="section">

### dplyr

-   `across()`

-   `between()`

-   `case_when()`: `.ptype` and `.size` arguments not supported

-   `coalesce()`

-   `desc()`

-   `if_all()`

-   `if_any()`

-   `if_else()`

-   `n()`

-   `n_distinct()`

</div>

<div class="section">

### hms

-   `as_hms()`: subsecond precision not supported for character input

-   `hms()`: nanosecond times not supported

</div>

<div class="section">

### lubridate

-   `am()`

-   `as_date()`

-   `as_datetime()`

-   `ceiling_date()`

-   `date()`

-   `date_decimal()`

-   `day()`

-   `ddays()`

-   `decimal_date()`

-   `dhours()`

-   `dmicroseconds()`

-   `dmilliseconds()`

-   `dminutes()`

-   `dmonths()`

-   `dmy()`: `locale` argument not supported

-   `dmy_h()`: `locale` argument not supported

-   `dmy_hm()`: `locale` argument not supported

-   `dmy_hms()`: `locale` argument not supported

-   `dnanoseconds()`

-   `dpicoseconds()`: not supported

-   `dseconds()`

-   `dst()`

-   `dweeks()`

-   `dyears()`

-   `dym()`: `locale` argument not supported

-   `epiweek()`

-   `epiyear()`

-   `fast_strptime()`: non-default values of `lt` and `cutoff_2000` not
    supported

-   `floor_date()`

-   `force_tz()`: Timezone conversion from non-UTC timezone not
    supported; `roll_dst` values of 'error' and 'boundary' are supported
    for nonexistent times, `roll_dst` values of 'error', 'pre', and
    'post' are supported for ambiguous times.

-   `format_ISO8601()`

-   `hour()`

-   `is.Date()`

-   `is.POSIXct()`

-   `is.instant()`

-   `is.timepoint()`

-   `isoweek()`

-   `isoyear()`

-   `leap_year()`

-   `make_date()`

-   `make_datetime()`: only supports UTC (default) timezone

-   `make_difftime()`: only supports `units = "secs"` (the default);
    providing both `num` and `...` is not supported

-   `mday()`

-   `mdy()`: `locale` argument not supported

-   `mdy_h()`: `locale` argument not supported

-   `mdy_hm()`: `locale` argument not supported

-   `mdy_hms()`: `locale` argument not supported

-   `minute()`

-   `month()`

-   `my()`: `locale` argument not supported

-   `myd()`: `locale` argument not supported

-   `parse_date_time()`: `quiet = FALSE` is not supported Available
    formats are H, I, j, M, S, U, w, W, y, Y, R, T. On Linux and OS X
    additionally a, A, b, B, Om, p, r are available.

-   `pm()`

-   `qday()`

-   `quarter()`

-   `round_date()`

-   `second()`

-   `semester()`

-   `tz()`

-   `wday()`

-   `week()`

-   `with_tz()`

-   `yday()`

-   `ydm()`: `locale` argument not supported

-   `ydm_h()`: `locale` argument not supported

-   `ydm_hm()`: `locale` argument not supported

-   `ydm_hms()`: `locale` argument not supported

-   `year()`

-   `ym()`: `locale` argument not supported

-   `ymd()`: `locale` argument not supported

-   `ymd_h()`: `locale` argument not supported

-   `ymd_hm()`: `locale` argument not supported

-   `ymd_hms()`: `locale` argument not supported

-   `yq()`: `locale` argument not supported

</div>

<div class="section">

### methods

-   `is()`

</div>

<div class="section">

### rlang

-   `is_character()`

-   `is_double()`

-   `is_integer()`

-   `is_list()`

-   `is_logical()`

</div>

<div class="section">

### stats

-   `median()`: approximate median (t-digest) is computed

-   `quantile()`: `probs` must be length 1; approximate quantile
    (t-digest) is computed

-   `sd()`

-   `var()`

</div>

<div class="section">

### stringi

-   `stri_reverse()`

</div>

<div class="section">

### stringr

Pattern modifiers `coll()` and `boundary()` are not supported in any
functions.

-   `str_c()`: the `collapse` argument is not yet supported

-   `str_count()`: `pattern` must be a length 1 character vector

-   `str_detect()`

-   `str_dup()`

-   `str_ends()`

-   `str_length()`

-   `str_like()`

-   `str_pad()`

-   `str_remove()`

-   `str_remove_all()`

-   `str_replace()`

-   `str_replace_all()`

-   `str_replace_na()`

-   `str_split()`: Case-insensitive string splitting and splitting into
    0 parts not supported

-   `str_starts()`

-   `str_sub()`: `start` and `end` must be length 1

-   `str_to_lower()`

-   `str_to_title()`

-   `str_to_upper()`

-   `str_trim()`

</div>

<div class="section">

### tibble

-   `tibble()`

</div>

<div class="section">

### tidyselect

-   `all_of()`

-   `contains()`

-   `ends_with()`

-   `everything()`

-   `last_col()`

-   `matches()`

-   `num_range()`

-   `one_of()`

-   `starts_with()`

</div>

</div>

</div>
