<div id="main" class="col-md-9" role="main">

# Package index

<div class="section level2">

## Read datasets

<div class="section-desc">

Open multi-file datasets as Arrow Dataset objects.

</div>

</div>

<div class="section level2">

-   `open_dataset()` : Open a multi-file dataset
-   `open_delim_dataset()` `open_csv_dataset()` `open_tsv_dataset()` :
    Open a multi-file dataset of CSV or other delimiter-separated format
-   `csv_read_options()` : CSV Reading Options
-   `csv_parse_options()` : CSV Parsing Options
-   `csv_convert_options()` : CSV Convert Options

</div>

<div class="section level2">

## Write datasets

<div class="section-desc">

Write multi-file datasets to disk.

</div>

</div>

<div class="section level2">

-   `write_dataset()` : Write a dataset
-   `write_delim_dataset()` `write_csv_dataset()` `write_tsv_dataset()`
    : Write a dataset into partitioned flat files.
-   `csv_write_options()` : CSV Writing Options

</div>

<div class="section level2">

## Read files

<div class="section-desc">

Read files in a variety of formats in as tibbles or Arrow Tables.

</div>

</div>

<div class="section level2">

-   `read_delim_arrow()` `read_csv_arrow()` `read_csv2_arrow()`
    `read_tsv_arrow()` : Read a CSV or other delimited file with Arrow
-   `read_parquet()` : Read a Parquet file
-   `read_feather()` `read_ipc_file()` : Read a Feather file (an Arrow
    IPC file)
-   `read_ipc_stream()` : Read Arrow IPC stream format
-   `read_json_arrow()` : Read a JSON file

</div>

<div class="section level2">

## Write files

<div class="section-desc">

Write to files in a variety of formats.

</div>

</div>

<div class="section level2">

-   `write_csv_arrow()` : Write CSV file to disk
-   `write_parquet()` : Write Parquet file to disk
-   `write_feather()` `write_ipc_file()` : Write a Feather file (an
    Arrow IPC file)
-   `write_ipc_stream()` : Write Arrow IPC stream format
-   `write_to_raw()` : Write Arrow data to a raw vector

</div>

<div class="section level2">

## Creating Arrow data containers

<div class="section-desc">

Classes and functions for creating Arrow data containers.

</div>

</div>

<div class="section level2">

-   `scalar()` : Create an Arrow Scalar
-   `arrow_array()` : Create an Arrow Array
-   `chunked_array()` : Create a Chunked Array
-   `record_batch()` : Create a RecordBatch
-   `arrow_table()` : Create an Arrow Table
-   `buffer()` : Create a Buffer
-   `vctrs_extension_array()` `vctrs_extension_type()` : Extension type
    for generic typed vectors

</div>

<div class="section level2">

## Working with Arrow data containers

<div class="section-desc">

Functions for converting R objects to Arrow data containers and
combining Arrow data containers.

</div>

</div>

<div class="section level2">

-   `as_arrow_array()` : Convert an object to an Arrow Array
-   `as_chunked_array()` : Convert an object to an Arrow ChunkedArray
-   `as_record_batch()` : Convert an object to an Arrow RecordBatch
-   `as_arrow_table()` : Convert an object to an Arrow Table
-   `concat_arrays()` `c(<Array>)` : Concatenate zero or more Arrays
-   `concat_tables()` : Concatenate one or more Tables

</div>

<div class="section level2">

## Arrow data types

</div>

<div class="section level2">

-   `int8()` `int16()` `int32()` `int64()` `uint8()` `uint16()`
    `uint32()` `uint64()` `float16()` `halffloat()` `float32()`
    `float()` `float64()` `boolean()` `bool()` `utf8()` `large_utf8()`
    `binary()` `large_binary()` `fixed_size_binary()` `string()`
    `date32()` `date64()` `time32()` `time64()` `duration()` `null()`
    `timestamp()` `decimal()` `decimal32()` `decimal64()` `decimal128()`
    `decimal256()` `struct()` `list_of()` `large_list_of()`
    `fixed_size_list_of()` `map_of()` : Create Arrow data types
-   `dictionary()` : Create a dictionary type
-   `new_extension_type()` `new_extension_array()`
    `register_extension_type()` `reregister_extension_type()`
    `unregister_extension_type()` : Extension types
-   `vctrs_extension_array()` `vctrs_extension_type()` : Extension type
    for generic typed vectors
-   `as_data_type()` : Convert an object to an Arrow DataType
-   `infer_type()` `type()` : Infer the arrow Array type from an R
    object

</div>

<div class="section level2">

## Fields and schemas

</div>

<div class="section level2">

-   `field()` : Create a Field
-   `schema()` : Create a schema or extract one from an object.
-   `unify_schemas()` : Combine and harmonize schemas
-   `as_schema()` : Convert an object to an Arrow Schema
-   `infer_schema()` : Extract a schema from an object
-   `read_schema()` : Read a Schema from a stream

</div>

<div class="section level2">

## Computation

<div class="section-desc">

Functionality for computing values on Arrow data objects.

</div>

</div>

<div class="section level2">

-   `acero` `arrow-functions` `arrow-verbs` `arrow-dplyr` : Functions
    available in Arrow dplyr queries

-   `call_function()` : Call an Arrow compute function

-   `match_arrow()` `is_in()` : Value matching for Arrow objects

-   `value_counts()` :

    `table` for Arrow objects

-   `list_compute_functions()` : List available Arrow C++ compute
    functions

-   `register_scalar_function()` : Register user-defined functions

-   `show_exec_plan()` : Show the details of an Arrow Execution Plan

</div>

<div class="section level2">

## DuckDB

<div class="section-desc">

Pass data to and from DuckDB

</div>

</div>

<div class="section level2">

-   `to_arrow()` : Create an Arrow object from a DuckDB connection
-   `to_duckdb()` : Create a (virtual) DuckDB table from an Arrow object

</div>

<div class="section level2">

## File systems

<div class="section-desc">

Functions for working with files on S3 and GCS

</div>

</div>

<div class="section level2">

-   `s3_bucket()` : Connect to an AWS S3 bucket
-   `gs_bucket()` : Connect to a Google Cloud Storage (GCS) bucket
-   `copy_files()` : Copy files between FileSystems

</div>

<div class="section level2">

## Flight

</div>

<div class="section level2">

-   `load_flight_server()` : Load a Python Flight server
-   `flight_connect()` : Connect to a Flight server
-   `flight_disconnect()` : Explicitly close a Flight client
-   `flight_get()` : Get data from a Flight server
-   `flight_put()` : Send data to a Flight server
-   `list_flights()` `flight_path_exists()` : See available resources on
    a Flight server

</div>

<div class="section level2">

## Arrow Configuration

</div>

<div class="section level2">

-   `arrow_info()` `arrow_available()` `arrow_with_acero()`
    `arrow_with_dataset()` `arrow_with_substrait()`
    `arrow_with_parquet()` `arrow_with_s3()` `arrow_with_gcs()`
    `arrow_with_json()` : Report information on the package's
    capabilities
-   `cpu_count()` `set_cpu_count()` : Manage the global CPU thread pool
    in libarrow
-   `io_thread_count()` `set_io_thread_count()` : Manage the global I/O
    thread pool in libarrow
-   `install_arrow()` : Install or upgrade the Arrow library
-   `install_pyarrow()` : Install pyarrow for use with reticulate
-   `create_package_with_all_dependencies()` : Create a source bundle
    that includes all thirdparty dependencies

</div>

<div class="section level2">

## Input/Output

</div>

<div class="section level2">

-   `InputStream` `RandomAccessFile` `MemoryMappedFile` `ReadableFile`
    `BufferReader` : InputStream classes
-   `read_message()` : Read a Message from a stream
-   `mmap_open()` : Open a memory mapped file
-   `mmap_create()` : Create a new read/write memory mapped file of a
    given size
-   `OutputStream` `FileOutputStream` `BufferOutputStream` :
    OutputStream classes
-   `Message` : Message class
-   `MessageReader` : MessageReader class
-   `compression` `CompressedOutputStream` `CompressedInputStream` :
    Compressed stream classes
-   `Codec` : Compression Codec class
-   `codec_is_available()` : Check whether a compression codec is
    available

</div>

<div class="section level2">

## File read/writer interface

</div>

<div class="section level2">

-   `ParquetFileReader` : ParquetFileReader class
-   `ParquetReaderProperties` : ParquetReaderProperties class
-   `ParquetArrowReaderProperties` : ParquetArrowReaderProperties class
-   `ParquetFileWriter` : ParquetFileWriter class
-   `ParquetWriterProperties` : ParquetWriterProperties class
-   `FeatherReader` : FeatherReader class
-   `CsvTableReader` `JsonTableReader` : Arrow CSV and JSON table reader
    classes
-   `CsvReadOptions` `CsvWriteOptions` `CsvParseOptions`
    `TimestampParser` `CsvConvertOptions` `JsonReadOptions`
    `JsonParseOptions` : File reader options
-   `RecordBatchReader` `RecordBatchStreamReader`
    `RecordBatchFileReader` : RecordBatchReader classes
-   `RecordBatchWriter` `RecordBatchStreamWriter`
    `RecordBatchFileWriter` : RecordBatchWriter classes
-   `as_record_batch_reader()` : Convert an object to an Arrow
    RecordBatchReader

</div>

<div class="section level2">

## Low-level C++ wrappers

<div class="section-desc">

Low-level R6 class representations of Arrow C++ objects intended for
advanced users.

</div>

</div>

<div class="section level2">

-   `Buffer` : Buffer class
-   `Scalar` : Arrow scalars
-   `Array` `DictionaryArray` `StructArray` `ListArray` `LargeListArray`
    `FixedSizeListArray` `MapArray` : Array Classes
-   `ChunkedArray` : ChunkedArray class
-   `RecordBatch` : RecordBatch class
-   `Schema` : Schema class
-   `Field` : Field class
-   `Table` : Table class
-   `DataType` : DataType class
-   `ArrayData` : ArrayData class
-   `DictionaryType` : class DictionaryType
-   `FixedWidthType` : FixedWidthType class
-   `ExtensionType` : ExtensionType class
-   `ExtensionArray` : ExtensionArray class

</div>

<div class="section level2">

## Dataset and Filesystem R6 classes and helper functions

<div class="section-desc">

R6 classes and helper functions useful for when working with multi-file
datases in Arrow.

</div>

</div>

<div class="section level2">

-   `Dataset` `FileSystemDataset` `UnionDataset` `InMemoryDataset`
    `DatasetFactory` `FileSystemDatasetFactory` : Multi-file datasets
-   `dataset_factory()` : Create a DatasetFactory
-   `Partitioning` `DirectoryPartitioning` `HivePartitioning`
    `DirectoryPartitioningFactory` `HivePartitioningFactory` : Define
    Partitioning for a Dataset
-   `Expression` : Arrow expressions
-   `Scanner` `ScannerBuilder` : Scan the contents of a dataset
-   `FileFormat` `ParquetFileFormat` `IpcFileFormat` : Dataset file
    formats
-   `CsvFileFormat` : CSV dataset file format
-   `JsonFileFormat` : JSON dataset file format
-   `FileWriteOptions` : Format-specific write options
-   `FragmentScanOptions` `CsvFragmentScanOptions`
    `ParquetFragmentScanOptions` `JsonFragmentScanOptions` :
    Format-specific scan options
-   `hive_partition()` : Construct Hive partitioning
-   `map_batches()` : Apply a function to a stream of RecordBatches
-   `FileSystem` `LocalFileSystem` `S3FileSystem` `GcsFileSystem`
    `SubTreeFileSystem` : FileSystem classes
-   `FileInfo` : FileSystem entry info
-   `FileSelector` : file selector

</div>

</div>
