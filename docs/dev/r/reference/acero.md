# Functions available in Arrow dplyr queries

The `arrow` package contains methods for 37 `dplyr` table functions,
many of which are "verbs" that do transformations to one or more tables.
The package also has mappings of 224 R functions to the corresponding
functions in the Arrow compute library. These allow you to write code
inside of `dplyr` methods that call R functions, including many in
packages like `stringr` and `lubridate`, and they will get translated to
Arrow and run on the Arrow query engine (Acero). This document lists all
of the mapped functions.

## `dplyr` verbs

Most verb functions return an `arrow_dplyr_query` object, similar in
spirit to a
[`dbplyr::tbl_lazy`](https://dbplyr.tidyverse.org/reference/tbl_lazy.html).
This means that the verbs do not eagerly evaluate the query on the data.
To run the query, call either `compute()`, which returns an `arrow`
[Table](https://arrow.apache.org/docs/r/reference/Table-class.md), or
`collect()`, which pulls the resulting Table into an R `tibble`.

- [`anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html):
  the `copy` argument is ignored

- [`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html)

- [`collapse()`](https://dplyr.tidyverse.org/reference/compute.html)

- [`collect()`](https://dplyr.tidyverse.org/reference/compute.html)

- [`compute()`](https://dplyr.tidyverse.org/reference/compute.html)

- [`count()`](https://dplyr.tidyverse.org/reference/count.html)

- [`distinct()`](https://dplyr.tidyverse.org/reference/distinct.html):
  `.keep_all = TRUE` returns a non-missing value if present, only
  returning missing values if all are missing.

- [`explain()`](https://dplyr.tidyverse.org/reference/explain.html)

- [`filter()`](https://dplyr.tidyverse.org/reference/filter.html)

- [`full_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html):
  the `copy` argument is ignored

- [`glimpse()`](https://pillar.r-lib.org/reference/glimpse.html)

- [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)

- [`group_by_drop_default()`](https://dplyr.tidyverse.org/reference/group_by_drop_default.html)

- [`group_vars()`](https://dplyr.tidyverse.org/reference/group_data.html)

- [`groups()`](https://dplyr.tidyverse.org/reference/group_data.html)

- [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html):
  the `copy` argument is ignored

- [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html):
  the `copy` argument is ignored

- [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)

- [`pull()`](https://dplyr.tidyverse.org/reference/pull.html): the
  `name` argument is not supported; returns an R vector by default but
  this behavior is deprecated and will return an Arrow
  [ChunkedArray](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
  in a future release. Provide `as_vector = TRUE/FALSE` to control this
  behavior, or set `options(arrow.pull_as_vector)` globally.

- [`relocate()`](https://dplyr.tidyverse.org/reference/relocate.html)

- [`rename()`](https://dplyr.tidyverse.org/reference/rename.html)

- [`rename_with()`](https://dplyr.tidyverse.org/reference/rename.html)

- [`right_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html):
  the `copy` argument is ignored

- [`select()`](https://dplyr.tidyverse.org/reference/select.html)

- [`semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html):
  the `copy` argument is ignored

- [`show_query()`](https://dplyr.tidyverse.org/reference/explain.html)

- [`slice_head()`](https://dplyr.tidyverse.org/reference/slice.html):
  slicing within groups not supported; Arrow datasets do not have row
  order, so head is non-deterministic; `prop` only supported on queries
  where [`nrow()`](https://rdrr.io/r/base/nrow.html) is knowable without
  evaluating

- [`slice_max()`](https://dplyr.tidyverse.org/reference/slice.html):
  slicing within groups not supported; `with_ties = TRUE` (dplyr
  default) is not supported; `prop` only supported on queries where
  [`nrow()`](https://rdrr.io/r/base/nrow.html) is knowable without
  evaluating

- [`slice_min()`](https://dplyr.tidyverse.org/reference/slice.html):
  slicing within groups not supported; `with_ties = TRUE` (dplyr
  default) is not supported; `prop` only supported on queries where
  [`nrow()`](https://rdrr.io/r/base/nrow.html) is knowable without
  evaluating

- [`slice_sample()`](https://dplyr.tidyverse.org/reference/slice.html):
  slicing within groups not supported; `replace = TRUE` and the
  `weight_by` argument not supported; `n` only supported on queries
  where [`nrow()`](https://rdrr.io/r/base/nrow.html) is knowable without
  evaluating

- [`slice_tail()`](https://dplyr.tidyverse.org/reference/slice.html):
  slicing within groups not supported; Arrow datasets do not have row
  order, so tail is non-deterministic; `prop` only supported on queries
  where [`nrow()`](https://rdrr.io/r/base/nrow.html) is knowable without
  evaluating

- [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html):
  window functions not currently supported; arguments `.drop = FALSE`
  and `.groups = "rowwise"` not supported

- [`tally()`](https://dplyr.tidyverse.org/reference/count.html)

- [`transmute()`](https://dplyr.tidyverse.org/reference/transmute.html)

- [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html)

- [`union()`](https://dplyr.tidyverse.org/reference/setops.html)

- [`union_all()`](https://dplyr.tidyverse.org/reference/setops.html)

## Function mappings

In the list below, any differences in behavior or support between Acero
and the R function are listed. If no notes follow the function name,
then you can assume that the function works in Acero just as it does in
R.

Functions can be called either as `pkg::fun()` or just `fun()`, i.e.
both `str_sub()` and
[`stringr::str_sub()`](https://stringr.tidyverse.org/reference/str_sub.html)
work.

In addition to these functions, you can call any of Arrow's 281 compute
functions directly. Arrow has many functions that don't map to an
existing R function. In other cases where there is an R function
mapping, you can still call the Arrow function directly if you don't
want the adaptations that the R mapping has that make Acero behave like
R. These functions are listed in the [C++
documentation](https://arrow.apache.org/docs/cpp/compute.html), and in
the function registry in R, they are named with an `arrow_` prefix, such
as `arrow_ascii_is_decimal`.

### arrow

- [`add_filename()`](https://arrow.apache.org/docs/r/reference/add_filename.md)

- [`cast()`](https://arrow.apache.org/docs/r/reference/cast.md)

### base

- [`!`](https://rdrr.io/r/base/Logic.html)

- [`!=`](https://rdrr.io/r/base/Comparison.html)

- [`%%`](https://rdrr.io/r/base/Arithmetic.html)

- [`%/%`](https://rdrr.io/r/base/Arithmetic.html)

- [`%in%`](https://rdrr.io/r/base/match.html)

- [`&`](https://rdrr.io/r/base/Logic.html)

- [`*`](https://rdrr.io/r/base/Arithmetic.html)

- [`+`](https://rdrr.io/r/base/Arithmetic.html)

- [`-`](https://rdrr.io/r/base/Arithmetic.html)

- [`/`](https://rdrr.io/r/base/Arithmetic.html)

- [`<`](https://rdrr.io/r/base/Comparison.html)

- [`<=`](https://rdrr.io/r/base/Comparison.html)

- [`==`](https://rdrr.io/r/base/Comparison.html)

- [`>`](https://rdrr.io/r/base/Comparison.html)

- [`>=`](https://rdrr.io/r/base/Comparison.html)

- [`ISOdate()`](https://rdrr.io/r/base/ISOdatetime.html)

- [`ISOdatetime()`](https://rdrr.io/r/base/ISOdatetime.html)

- [`^`](https://rdrr.io/r/base/Arithmetic.html)

- [`abs()`](https://rdrr.io/r/base/MathFun.html)

- [`acos()`](https://rdrr.io/r/base/Trig.html)

- [`acosh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`all()`](https://rdrr.io/r/base/all.html)

- [`any()`](https://rdrr.io/r/base/any.html)

- [`as.Date()`](https://rdrr.io/r/base/as.Date.html): Multiple
  `tryFormats` not supported in Arrow. Consider using the lubridate
  specialised parsing functions `ymd()`, `ymd()`, etc.

- [`as.character()`](https://rdrr.io/r/base/character.html)

- [`as.difftime()`](https://rdrr.io/r/base/difftime.html): only supports
  `units = "secs"` (the default)

- [`as.double()`](https://rdrr.io/r/base/double.html)

- [`as.integer()`](https://rdrr.io/r/base/integer.html)

- [`as.logical()`](https://rdrr.io/r/base/logical.html)

- [`as.numeric()`](https://rdrr.io/r/base/numeric.html)

- [`asin()`](https://rdrr.io/r/base/Trig.html)

- [`asinh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`atan()`](https://rdrr.io/r/base/Trig.html)

- [`atanh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`ceiling()`](https://rdrr.io/r/base/Round.html)

- [`cos()`](https://rdrr.io/r/base/Trig.html)

- [`cosh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`data.frame()`](https://rdrr.io/r/base/data.frame.html): `row.names`
  and `check.rows` arguments not supported; `stringsAsFactors` must be
  `FALSE`

- [`difftime()`](https://rdrr.io/r/base/difftime.html): only supports
  `units = "secs"` (the default); `tz` argument not supported

- [`endsWith()`](https://rdrr.io/r/base/startsWith.html)

- [`exp()`](https://rdrr.io/r/base/Log.html)

- [`expm1()`](https://rdrr.io/r/base/Log.html)

- [`floor()`](https://rdrr.io/r/base/Round.html)

- [`format()`](https://rdrr.io/r/base/format.html)

- [`grepl()`](https://rdrr.io/r/base/grep.html)

- [`gsub()`](https://rdrr.io/r/base/grep.html)

- [`ifelse()`](https://rdrr.io/r/base/ifelse.html)

- [`is.character()`](https://rdrr.io/r/base/character.html)

- [`is.double()`](https://rdrr.io/r/base/double.html)

- [`is.factor()`](https://rdrr.io/r/base/factor.html)

- [`is.finite()`](https://rdrr.io/r/base/is.finite.html)

- [`is.infinite()`](https://rdrr.io/r/base/is.finite.html)

- [`is.integer()`](https://rdrr.io/r/base/integer.html)

- [`is.list()`](https://rdrr.io/r/base/list.html)

- [`is.logical()`](https://rdrr.io/r/base/logical.html)

- [`is.na()`](https://rdrr.io/r/base/NA.html)

- [`is.nan()`](https://rdrr.io/r/base/is.finite.html)

- [`is.numeric()`](https://rdrr.io/r/base/numeric.html)

- [`log()`](https://rdrr.io/r/base/Log.html)

- [`log10()`](https://rdrr.io/r/base/Log.html)

- [`log1p()`](https://rdrr.io/r/base/Log.html)

- [`log2()`](https://rdrr.io/r/base/Log.html)

- [`logb()`](https://rdrr.io/r/base/Log.html)

- [`max()`](https://rdrr.io/r/base/Extremes.html)

- [`mean()`](https://rdrr.io/r/base/mean.html)

- [`min()`](https://rdrr.io/r/base/Extremes.html)

- [`nchar()`](https://rdrr.io/r/base/nchar.html): `allowNA = TRUE` and
  `keepNA = TRUE` not supported

- [`paste()`](https://rdrr.io/r/base/paste.html): the `collapse`
  argument is not yet supported

- [`paste0()`](https://rdrr.io/r/base/paste.html): the `collapse`
  argument is not yet supported

- [`pmax()`](https://rdrr.io/r/base/Extremes.html)

- [`pmin()`](https://rdrr.io/r/base/Extremes.html)

- [`prod()`](https://rdrr.io/r/base/prod.html)

- [`round()`](https://rdrr.io/r/base/Round.html)

- [`sign()`](https://rdrr.io/r/base/sign.html)

- [`sin()`](https://rdrr.io/r/base/Trig.html)

- [`sinh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`sqrt()`](https://rdrr.io/r/base/MathFun.html)

- [`startsWith()`](https://rdrr.io/r/base/startsWith.html)

- [`strftime()`](https://rdrr.io/r/base/strptime.html)

- [`strptime()`](https://rdrr.io/r/base/strptime.html): accepts a `unit`
  argument not present in the `base` function. Valid values are "s",
  "ms" (default), "us", "ns".

- [`strrep()`](https://rdrr.io/r/base/strrep.html)

- [`strsplit()`](https://rdrr.io/r/base/strsplit.html)

- [`sub()`](https://rdrr.io/r/base/grep.html)

- [`substr()`](https://rdrr.io/r/base/substr.html): `start` and `stop`
  must be length 1

- [`substring()`](https://rdrr.io/r/base/substr.html)

- [`sum()`](https://rdrr.io/r/base/sum.html)

- [`tan()`](https://rdrr.io/r/base/Trig.html)

- [`tanh()`](https://rdrr.io/r/base/Hyperbolic.html)

- [`tolower()`](https://rdrr.io/r/base/chartr.html)

- [`toupper()`](https://rdrr.io/r/base/chartr.html)

- [`trunc()`](https://rdrr.io/r/base/Round.html)

- [`|`](https://rdrr.io/r/base/Logic.html)

### bit64

- [`as.integer64()`](https://rdrr.io/pkg/bit64/man/as.integer64.character.html)

- [`is.integer64()`](https://rdrr.io/pkg/bit64/man/bit64-package.html)

### dplyr

- [`across()`](https://dplyr.tidyverse.org/reference/across.html)

- [`between()`](https://dplyr.tidyverse.org/reference/between.html)

- [`case_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html):
  `.ptype` and `.size` arguments not supported

- [`coalesce()`](https://dplyr.tidyverse.org/reference/coalesce.html)

- [`desc()`](https://dplyr.tidyverse.org/reference/desc.html)

- [`if_all()`](https://dplyr.tidyverse.org/reference/across.html)

- [`if_any()`](https://dplyr.tidyverse.org/reference/across.html)

- [`if_else()`](https://dplyr.tidyverse.org/reference/if_else.html)

- [`n()`](https://dplyr.tidyverse.org/reference/context.html)

- [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html)

### hms

- [`as_hms()`](https://hms.tidyverse.org/reference/hms.html): subsecond
  precision not supported for character input

- [`hms()`](https://hms.tidyverse.org/reference/hms.html): nanosecond
  times not supported

### lubridate

- [`am()`](https://lubridate.tidyverse.org/reference/am.html)

- [`as_date()`](https://lubridate.tidyverse.org/reference/as_date.html)

- [`as_datetime()`](https://lubridate.tidyverse.org/reference/as_date.html)

- [`ceiling_date()`](https://lubridate.tidyverse.org/reference/round_date.html)

- [`date()`](https://lubridate.tidyverse.org/reference/date.html)

- [`date_decimal()`](https://lubridate.tidyverse.org/reference/date_decimal.html)

- [`day()`](https://lubridate.tidyverse.org/reference/day.html)

- [`ddays()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`decimal_date()`](https://lubridate.tidyverse.org/reference/decimal_date.html)

- [`dhours()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dmicroseconds()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dmilliseconds()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dminutes()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dmonths()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dmy()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`dmy_h()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`dmy_hm()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`dmy_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`dnanoseconds()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dpicoseconds()`](https://lubridate.tidyverse.org/reference/duration.html):
  not supported

- [`dseconds()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dst()`](https://lubridate.tidyverse.org/reference/dst.html)

- [`dweeks()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dyears()`](https://lubridate.tidyverse.org/reference/duration.html)

- [`dym()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`epiweek()`](https://lubridate.tidyverse.org/reference/week.html)

- [`epiyear()`](https://lubridate.tidyverse.org/reference/year.html)

- [`fast_strptime()`](https://lubridate.tidyverse.org/reference/parse_date_time.html):
  non-default values of `lt` and `cutoff_2000` not supported

- [`floor_date()`](https://lubridate.tidyverse.org/reference/round_date.html)

- [`force_tz()`](https://lubridate.tidyverse.org/reference/force_tz.html):
  Timezone conversion from non-UTC timezone not supported; `roll_dst`
  values of 'error' and 'boundary' are supported for nonexistent times,
  `roll_dst` values of 'error', 'pre', and 'post' are supported for
  ambiguous times.

- [`format_ISO8601()`](https://lubridate.tidyverse.org/reference/format_ISO8601.html)

- [`hour()`](https://lubridate.tidyverse.org/reference/hour.html)

- `is.Date()`

- `is.POSIXct()`

- [`is.instant()`](https://lubridate.tidyverse.org/reference/is.instant.html)

- [`is.timepoint()`](https://lubridate.tidyverse.org/reference/is.instant.html)

- [`isoweek()`](https://lubridate.tidyverse.org/reference/week.html)

- [`isoyear()`](https://lubridate.tidyverse.org/reference/year.html)

- [`leap_year()`](https://lubridate.tidyverse.org/reference/leap_year.html)

- [`make_date()`](https://lubridate.tidyverse.org/reference/make_datetime.html)

- [`make_datetime()`](https://lubridate.tidyverse.org/reference/make_datetime.html):
  only supports UTC (default) timezone

- [`make_difftime()`](https://lubridate.tidyverse.org/reference/make_difftime.html):
  only supports `units = "secs"` (the default); providing both `num` and
  `...` is not supported

- [`mday()`](https://lubridate.tidyverse.org/reference/day.html)

- [`mdy()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`mdy_h()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`mdy_hm()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`mdy_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`minute()`](https://lubridate.tidyverse.org/reference/minute.html)

- [`month()`](https://lubridate.tidyverse.org/reference/month.html)

- [`my()`](https://lubridate.tidyverse.org/reference/ymd.html): `locale`
  argument not supported

- [`myd()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html):
  `quiet = FALSE` is not supported Available formats are H, I, j, M, S,
  U, w, W, y, Y, R, T. On Linux and OS X additionally a, A, b, B, Om, p,
  r are available.

- [`pm()`](https://lubridate.tidyverse.org/reference/am.html)

- [`qday()`](https://lubridate.tidyverse.org/reference/day.html)

- [`quarter()`](https://lubridate.tidyverse.org/reference/quarter.html)

- [`round_date()`](https://lubridate.tidyverse.org/reference/round_date.html)

- [`second()`](https://lubridate.tidyverse.org/reference/second.html)

- [`semester()`](https://lubridate.tidyverse.org/reference/quarter.html)

- [`tz()`](https://lubridate.tidyverse.org/reference/tz.html)

- [`wday()`](https://lubridate.tidyverse.org/reference/day.html)

- [`week()`](https://lubridate.tidyverse.org/reference/week.html)

- [`with_tz()`](https://lubridate.tidyverse.org/reference/with_tz.html)

- [`yday()`](https://lubridate.tidyverse.org/reference/day.html)

- [`ydm()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`ydm_h()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`ydm_hm()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`ydm_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`year()`](https://lubridate.tidyverse.org/reference/year.html)

- [`ym()`](https://lubridate.tidyverse.org/reference/ymd.html): `locale`
  argument not supported

- [`ymd()`](https://lubridate.tidyverse.org/reference/ymd.html):
  `locale` argument not supported

- [`ymd_h()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`ymd_hm()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html):
  `locale` argument not supported

- [`yq()`](https://lubridate.tidyverse.org/reference/ymd.html): `locale`
  argument not supported

### methods

- [`is()`](https://rdrr.io/r/methods/is.html)

### rlang

- [`is_character()`](https://rlang.r-lib.org/reference/type-predicates.html)

- [`is_double()`](https://rlang.r-lib.org/reference/type-predicates.html)

- [`is_integer()`](https://rlang.r-lib.org/reference/type-predicates.html)

- [`is_list()`](https://rlang.r-lib.org/reference/type-predicates.html)

- [`is_logical()`](https://rlang.r-lib.org/reference/type-predicates.html)

### stats

- [`median()`](https://rdrr.io/r/stats/median.html): approximate median
  (t-digest) is computed

- [`quantile()`](https://rdrr.io/r/stats/quantile.html): `probs` must be
  length 1; approximate quantile (t-digest) is computed

- [`sd()`](https://rdrr.io/r/stats/sd.html)

- [`var()`](https://rdrr.io/r/stats/cor.html)

### stringi

- [`stri_reverse()`](https://rdrr.io/pkg/stringi/man/stri_reverse.html)

### stringr

Pattern modifiers `coll()` and `boundary()` are not supported in any
functions.

- [`str_c()`](https://stringr.tidyverse.org/reference/str_c.html): the
  `collapse` argument is not yet supported

- [`str_count()`](https://stringr.tidyverse.org/reference/str_count.html):
  `pattern` must be a length 1 character vector

- [`str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)

- [`str_dup()`](https://stringr.tidyverse.org/reference/str_dup.html)

- [`str_ends()`](https://stringr.tidyverse.org/reference/str_starts.html)

- [`str_ilike()`](https://stringr.tidyverse.org/reference/str_like.html)

- [`str_length()`](https://stringr.tidyverse.org/reference/str_length.html)

- [`str_like()`](https://stringr.tidyverse.org/reference/str_like.html)

- [`str_pad()`](https://stringr.tidyverse.org/reference/str_pad.html)

- [`str_remove()`](https://stringr.tidyverse.org/reference/str_remove.html)

- [`str_remove_all()`](https://stringr.tidyverse.org/reference/str_remove.html)

- [`str_replace()`](https://stringr.tidyverse.org/reference/str_replace.html)

- [`str_replace_all()`](https://stringr.tidyverse.org/reference/str_replace.html)

- [`str_replace_na()`](https://stringr.tidyverse.org/reference/str_replace_na.html)

- [`str_split()`](https://stringr.tidyverse.org/reference/str_split.html):
  Case-insensitive string splitting and splitting into 0 parts not
  supported

- [`str_starts()`](https://stringr.tidyverse.org/reference/str_starts.html)

- [`str_sub()`](https://stringr.tidyverse.org/reference/str_sub.html):
  `start` and `end` must be length 1

- [`str_to_lower()`](https://stringr.tidyverse.org/reference/case.html)

- [`str_to_title()`](https://stringr.tidyverse.org/reference/case.html)

- [`str_to_upper()`](https://stringr.tidyverse.org/reference/case.html)

- [`str_trim()`](https://stringr.tidyverse.org/reference/str_trim.html)

### tibble

- [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html)

### tidyselect

- [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html)

- [`contains()`](https://tidyselect.r-lib.org/reference/starts_with.html)

- [`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)

- [`everything()`](https://tidyselect.r-lib.org/reference/everything.html)

- [`last_col()`](https://tidyselect.r-lib.org/reference/everything.html)

- [`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html)

- [`num_range()`](https://tidyselect.r-lib.org/reference/starts_with.html)

- [`one_of()`](https://tidyselect.r-lib.org/reference/one_of.html)

- [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)
