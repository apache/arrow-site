# Reading and writing data files

The arrow package provides functions for reading single data files into
memory, in several common formats. By default, calling any of these
functions returns an R data frame. To return an Arrow Table, set
argument `as_data_frame = FALSE`.

- [`read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.md):
  read a file in Parquet format
- [`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md):
  read a file in the Apache Arrow IPC format (formerly called the
  Feather format)
- [`read_delim_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md):
  read a delimited text file (default delimiter is comma)
- [`read_csv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md):
  read a comma-separated values (CSV) file
- [`read_tsv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md):
  read a tab-separated values (TSV) file
- [`read_json_arrow()`](https://arrow.apache.org/docs/r/reference/read_json_arrow.md):
  read a JSON data file

For writing data to single files, the arrow package provides the
following functions, which can be used with both R data frames and Arrow
Tables:

- [`write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.md):
  write a file in Parquet format
- [`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md):
  write a file in Arrow IPC format
- [`write_csv_arrow()`](https://arrow.apache.org/docs/r/reference/write_csv_arrow.md):
  write a file in CSV format

All these functions can read and write files in the local filesystem or
to cloud storage. For more on cloud storage support in arrow, see the
[cloud storage article](https://arrow.apache.org/docs/r/articles/fs.md).

The arrow package also supports reading larger-than-memory single data
files, and reading and writing multi-file data sets. This enables
analysis and processing of larger-than-memory data, and provides the
ability to partition data into smaller chunks without loading the full
data into memory. For more information on this topic, see the [dataset
article](https://arrow.apache.org/docs/r/articles/dataset.md).

## Parquet format

[Apache Parquet](https://parquet.apache.org/) is a popular choice for
storing analytics data; it is a binary format that is optimized for
reduced file sizes and fast read performance, especially for
column-based access patterns. The simplest way to read and write Parquet
data using arrow is with the
[`read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.md)
and
[`write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.md)
functions. To illustrate this, we’ll write the `starwars` data included
in dplyr to a Parquet file, then read it back in. First load the arrow
and dplyr packages:

``` r
library(arrow, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
```

Next we’ll write the data frame to a Parquet file located at
`file_path`:

``` r
file_path <- tempfile()
write_parquet(starwars, file_path)
```

The size of a Parquet file is typically much smaller than the
corresponding CSV file would have been. This is in part due to the use
of file compression: by default, Parquet files written with the arrow
package use [Snappy compression](https://google.github.io/snappy/) but
other options such as gzip are also supported. See
[`help("write_parquet", package = "arrow")`](https://arrow.apache.org/docs/r/reference/write_parquet.md)
for more information.

Having written the Parquet file, we now can read it with
[`read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.md):

``` r
read_parquet(file_path)
```

    ## # A tibble: 87 x 14
    ##    name     height  mass hair_color skin_color eye_color birth_year sex   gender
    ##    <chr>     <int> <dbl> <chr>      <chr>      <chr>          <dbl> <chr> <chr> 
    ##  1 Luke Sk~    172    77 blond      fair       blue            19   male  mascu~
    ##  2 C-3PO       167    75 NA         gold       yellow         112   none  mascu~
    ##  3 R2-D2        96    32 NA         white, bl~ red             33   none  mascu~
    ##  4 Darth V~    202   136 none       white      yellow          41.9 male  mascu~
    ##  5 Leia Or~    150    49 brown      light      brown           19   fema~ femin~
    ##  6 Owen La~    178   120 brown, gr~ light      blue            52   male  mascu~
    ##  7 Beru Wh~    165    75 brown      light      blue            47   fema~ femin~
    ##  8 R5-D4        97    32 NA         white, red red             NA   none  mascu~
    ##  9 Biggs D~    183    84 black      light      brown           24   male  mascu~
    ## 10 Obi-Wan~    182    77 auburn, w~ fair       blue-gray       57   male  mascu~
    ## # i 77 more rows
    ## # i 5 more variables: homeworld <chr>, species <chr>, films <list<character>>,
    ## #   vehicles <list<character>>, starships <list<character>>

The default is to return a data frame or tibble. If we want an Arrow
Table instead, we would set `as_data_frame = FALSE`:

``` r
read_parquet(file_path, as_data_frame = FALSE)
```

    ## Table
    ## 87 rows x 14 columns
    ## $name <string>
    ## $height <int32>
    ## $mass <double>
    ## $hair_color <string>
    ## $skin_color <string>
    ## $eye_color <string>
    ## $birth_year <double>
    ## $sex <string>
    ## $gender <string>
    ## $homeworld <string>
    ## $species <string>
    ## $films: list<element <string>>
    ## $vehicles: list<element <string>>
    ## $starships: list<element <string>>

One useful feature of Parquet files is that they store data column-wise,
and contain metadata that allow file readers to skip to the relevant
sections of the file. That means it is possible to load only a subset of
the columns without reading the complete file. The `col_select` argument
to
[`read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.md)
supports this functionality:

``` r
read_parquet(file_path, col_select = c("name", "height", "mass"))
```

    ## # A tibble: 87 x 3
    ##    name               height  mass
    ##    <chr>               <int> <dbl>
    ##  1 Luke Skywalker        172    77
    ##  2 C-3PO                 167    75
    ##  3 R2-D2                  96    32
    ##  4 Darth Vader           202   136
    ##  5 Leia Organa           150    49
    ##  6 Owen Lars             178   120
    ##  7 Beru Whitesun Lars    165    75
    ##  8 R5-D4                  97    32
    ##  9 Biggs Darklighter     183    84
    ## 10 Obi-Wan Kenobi        182    77
    ## # i 77 more rows

Fine-grained control over the Parquet reader is possible with the
`props` argument. See
[`help("ParquetArrowReaderProperties", package = "arrow")`](https://arrow.apache.org/docs/r/reference/ParquetArrowReaderProperties.md)
for details.

R object attributes are preserved when writing data to Parquet or
Arrow/Feather files and when reading those files back into R. This
enables round-trip writing and reading of `sf::sf` objects, R data
frames with with `haven::labelled` columns, and data frame with other
custom attributes. To learn more about how metadata are handled in
arrow, the [metadata
article](https://arrow.apache.org/docs/r/articles/metadata.md).

## Arrow/Feather format

The Arrow file format was developed to provide binary columnar
serialization for data frames, to make reading and writing data frames
efficient, and to make sharing data across data analysis languages easy.
This file format is sometimes referred to as Feather because it is an
outgrowth of the original [Feather](https://github.com/wesm/feather)
project that has now been moved into the Arrow project itself. You can
find the detailed specification of version 2 of the Arrow format –
officially referred to as [the Arrow IPC file
format](https://arrow.apache.org/docs/format/Columnar.html#ipc-file-format)
– on the Arrow specification page.

The
[`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
function writes version 2 Arrow/Feather files by default, and supports
multiple kinds of file compression. Basic use is shown below:

``` r
file_path <- tempfile()
write_feather(starwars, file_path)
```

The
[`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md)
function provides a familiar interface for reading feather files:

``` r
read_feather(file_path)
```

    ## # A tibble: 87 x 14
    ##    name     height  mass hair_color skin_color eye_color birth_year sex   gender
    ##    <chr>     <int> <dbl> <chr>      <chr>      <chr>          <dbl> <chr> <chr> 
    ##  1 Luke Sk~    172    77 blond      fair       blue            19   male  mascu~
    ##  2 C-3PO       167    75 NA         gold       yellow         112   none  mascu~
    ##  3 R2-D2        96    32 NA         white, bl~ red             33   none  mascu~
    ##  4 Darth V~    202   136 none       white      yellow          41.9 male  mascu~
    ##  5 Leia Or~    150    49 brown      light      brown           19   fema~ femin~
    ##  6 Owen La~    178   120 brown, gr~ light      blue            52   male  mascu~
    ##  7 Beru Wh~    165    75 brown      light      blue            47   fema~ femin~
    ##  8 R5-D4        97    32 NA         white, red red             NA   none  mascu~
    ##  9 Biggs D~    183    84 black      light      brown           24   male  mascu~
    ## 10 Obi-Wan~    182    77 auburn, w~ fair       blue-gray       57   male  mascu~
    ## # i 77 more rows
    ## # i 5 more variables: homeworld <chr>, species <chr>, films <list<character>>,
    ## #   vehicles <list<character>>, starships <list<character>>

Like the Parquet reader, this reader supports reading a only subset of
columns, and can produce Arrow Table output:

``` r
read_feather(
  file = file_path,
  col_select = c("name", "height", "mass"),
  as_data_frame = FALSE
)
```

    ## Table
    ## 87 rows x 3 columns
    ## $name <string>
    ## $height <int32>
    ## $mass <double>

## CSV format

The read/write capabilities of the arrow package also include support
for CSV and other text-delimited files. The
[`read_csv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md),
[`read_tsv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md),
and
[`read_delim_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
functions all use the Arrow C++ CSV reader to read data files, where the
Arrow C++ options have been mapped to arguments in a way that mirrors
the conventions used in `readr::read_delim()`, with a `col_select`
argument inspired by `vroom::vroom()`.

A simple example of writing and reading a CSV file with arrow is shown
below:

``` r
file_path <- tempfile()
write_csv_arrow(mtcars, file_path)
read_csv_arrow(file_path, col_select = starts_with("d"))
```

    ## # A tibble: 32 x 2
    ##     disp  drat
    ##    <dbl> <dbl>
    ##  1  160   3.9 
    ##  2  160   3.9 
    ##  3  108   3.85
    ##  4  258   3.08
    ##  5  360   3.15
    ##  6  225   2.76
    ##  7  360   3.21
    ##  8  147.  3.69
    ##  9  141.  3.92
    ## 10  168.  3.92
    ## # i 22 more rows

In addition to the options provided by the readr-style arguments
(`delim`, `quote`, `escape_double`, `escape_backslash`, etc), you can
use the `schema` argument to specify column types: see
[`schema()`](https://arrow.apache.org/docs/r/reference/schema.md) help
for details. There is also the option of using `parse_options`,
`convert_options`, and `read_options` to exercise fine-grained control
over the arrow csv reader: see
[`help("CsvReadOptions", package = "arrow")`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
for details.

## JSON format

The arrow package supports reading (but not writing) of tabular data
from line-delimited JSON, using the
[`read_json_arrow()`](https://arrow.apache.org/docs/r/reference/read_json_arrow.md)
function. A minimal example is shown below:

``` r
file_path <- tempfile()
writeLines('
    { "hello": 3.5, "world": false, "yo": "thing" }
    { "hello": 3.25, "world": null }
    { "hello": 0.0, "world": true, "yo": null }
  ', file_path, useBytes = TRUE)
read_json_arrow(file_path)
```

    ## # A tibble: 3 x 3
    ##   hello world yo   
    ##   <dbl> <lgl> <chr>
    ## 1  3.5  FALSE thing
    ## 2  3.25 NA    NA   
    ## 3  0    TRUE  NA

## Further reading

- To learn more about cloud storage, see the [cloud storage
  article](https://arrow.apache.org/docs/r/articles/fs.md).
- To learn more about multi-file datasets, see the [datasets
  article](https://arrow.apache.org/docs/r/articles/dataset.md).
- The Apache Arrow R cookbook has chapters on [reading and writing
  single
  files](https://arrow.apache.org/cookbook/r/reading-and-writing-data---single-files.html)
  into memory and working with [multi-file
  datasets](https://arrow.apache.org/cookbook/r/reading-and-writing-data---multiple-files.html)
  stored on-disk.
