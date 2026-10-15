# Package index

## Read datasets

Open multi-file datasets as Arrow Dataset objects.

- [`open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.md)
  : Open a multi-file dataset
- [`open_delim_dataset()`](https://arrow.apache.org/docs/r/reference/open_delim_dataset.md)
  [`open_csv_dataset()`](https://arrow.apache.org/docs/r/reference/open_delim_dataset.md)
  [`open_tsv_dataset()`](https://arrow.apache.org/docs/r/reference/open_delim_dataset.md)
  : Open a multi-file dataset of CSV or other delimiter-separated format
- [`csv_read_options()`](https://arrow.apache.org/docs/r/reference/csv_read_options.md)
  : CSV Reading Options
- [`csv_parse_options()`](https://arrow.apache.org/docs/r/reference/csv_parse_options.md)
  : CSV Parsing Options
- [`csv_convert_options()`](https://arrow.apache.org/docs/r/reference/csv_convert_options.md)
  : CSV Convert Options

## Write datasets

Write multi-file datasets to disk.

- [`write_dataset()`](https://arrow.apache.org/docs/r/reference/write_dataset.md)
  : Write a dataset
- [`write_delim_dataset()`](https://arrow.apache.org/docs/r/reference/write_delim_dataset.md)
  [`write_csv_dataset()`](https://arrow.apache.org/docs/r/reference/write_delim_dataset.md)
  [`write_tsv_dataset()`](https://arrow.apache.org/docs/r/reference/write_delim_dataset.md)
  : Write a dataset into partitioned flat files.
- [`csv_write_options()`](https://arrow.apache.org/docs/r/reference/csv_write_options.md)
  : CSV Writing Options

## Read files

Read files in a variety of formats in as tibbles or Arrow Tables.

- [`read_delim_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
  [`read_csv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
  [`read_csv2_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
  [`read_tsv_arrow()`](https://arrow.apache.org/docs/r/reference/read_delim_arrow.md)
  : Read a CSV or other delimited file with Arrow
- [`read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.md)
  : Read a Parquet file
- [`read_feather()`](https://arrow.apache.org/docs/r/reference/read_feather.md)
  [`read_ipc_file()`](https://arrow.apache.org/docs/r/reference/read_feather.md)
  : Read a Feather file (an Arrow IPC file)
- [`read_ipc_stream()`](https://arrow.apache.org/docs/r/reference/read_ipc_stream.md)
  : Read Arrow IPC stream format
- [`read_json_arrow()`](https://arrow.apache.org/docs/r/reference/read_json_arrow.md)
  : Read a JSON file

## Write files

Write to files in a variety of formats.

- [`write_csv_arrow()`](https://arrow.apache.org/docs/r/reference/write_csv_arrow.md)
  : Write CSV file to disk
- [`write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.md)
  : Write Parquet file to disk
- [`write_feather()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
  [`write_ipc_file()`](https://arrow.apache.org/docs/r/reference/write_feather.md)
  : Write a Feather file (an Arrow IPC file)
- [`write_ipc_stream()`](https://arrow.apache.org/docs/r/reference/write_ipc_stream.md)
  : Write Arrow IPC stream format
- [`write_to_raw()`](https://arrow.apache.org/docs/r/reference/write_to_raw.md)
  : Write Arrow data to a raw vector

## Creating Arrow data containers

Classes and functions for creating Arrow data containers.

- [`scalar()`](https://arrow.apache.org/docs/r/reference/scalar.md) :
  Create an Arrow Scalar
- [`arrow_array()`](https://arrow.apache.org/docs/r/reference/arrow_array.md)
  : Create an Arrow Array
- [`chunked_array()`](https://arrow.apache.org/docs/r/reference/chunked_array.md)
  : Create a Chunked Array
- [`record_batch()`](https://arrow.apache.org/docs/r/reference/record_batch.md)
  : Create a RecordBatch
- [`arrow_table()`](https://arrow.apache.org/docs/r/reference/table.md)
  : Create an Arrow Table
- [`buffer()`](https://arrow.apache.org/docs/r/reference/buffer.md) :
  Create a Buffer
- [`vctrs_extension_array()`](https://arrow.apache.org/docs/r/reference/vctrs_extension_array.md)
  [`vctrs_extension_type()`](https://arrow.apache.org/docs/r/reference/vctrs_extension_array.md)
  : Extension type for generic typed vectors

## Working with Arrow data containers

Functions for converting R objects to Arrow data containers and
combining Arrow data containers.

- [`as_arrow_array()`](https://arrow.apache.org/docs/r/reference/as_arrow_array.md)
  : Convert an object to an Arrow Array
- [`as_chunked_array()`](https://arrow.apache.org/docs/r/reference/as_chunked_array.md)
  : Convert an object to an Arrow ChunkedArray
- [`as_record_batch()`](https://arrow.apache.org/docs/r/reference/as_record_batch.md)
  : Convert an object to an Arrow RecordBatch
- [`as_arrow_table()`](https://arrow.apache.org/docs/r/reference/as_arrow_table.md)
  : Convert an object to an Arrow Table
- [`concat_arrays()`](https://arrow.apache.org/docs/r/reference/concat_arrays.md)
  [`c(`*`<Array>`*`)`](https://arrow.apache.org/docs/r/reference/concat_arrays.md)
  : Concatenate zero or more Arrays
- [`concat_tables()`](https://arrow.apache.org/docs/r/reference/concat_tables.md)
  : Concatenate one or more Tables

## Arrow data types

- [`int8()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`int16()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`int32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`int64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`uint8()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`uint16()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`uint32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`uint64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`float16()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`halffloat()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`float32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`float()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`float64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`boolean()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`bool()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`utf8()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`large_utf8()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`binary()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`large_binary()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`fixed_size_binary()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`string()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`date32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`date64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`time32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`time64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`duration()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`null()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`timestamp()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`decimal()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`decimal32()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`decimal64()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`decimal128()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`decimal256()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`struct()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`list_of()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`large_list_of()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`fixed_size_list_of()`](https://arrow.apache.org/docs/r/reference/data-type.md)
  [`map_of()`](https://arrow.apache.org/docs/r/reference/data-type.md) :
  Create Arrow data types
- [`dictionary()`](https://arrow.apache.org/docs/r/reference/dictionary.md)
  : Create a dictionary type
- [`new_extension_type()`](https://arrow.apache.org/docs/r/reference/new_extension_type.md)
  [`new_extension_array()`](https://arrow.apache.org/docs/r/reference/new_extension_type.md)
  [`register_extension_type()`](https://arrow.apache.org/docs/r/reference/new_extension_type.md)
  [`reregister_extension_type()`](https://arrow.apache.org/docs/r/reference/new_extension_type.md)
  [`unregister_extension_type()`](https://arrow.apache.org/docs/r/reference/new_extension_type.md)
  : Extension types
- [`vctrs_extension_array()`](https://arrow.apache.org/docs/r/reference/vctrs_extension_array.md)
  [`vctrs_extension_type()`](https://arrow.apache.org/docs/r/reference/vctrs_extension_array.md)
  : Extension type for generic typed vectors
- [`as_data_type()`](https://arrow.apache.org/docs/r/reference/as_data_type.md)
  : Convert an object to an Arrow DataType
- [`infer_type()`](https://arrow.apache.org/docs/r/reference/infer_type.md)
  [`type()`](https://arrow.apache.org/docs/r/reference/infer_type.md) :
  Infer the arrow Array type from an R object

## Fields and schemas

- [`field()`](https://arrow.apache.org/docs/r/reference/Field.md) :
  Create a Field
- [`schema()`](https://arrow.apache.org/docs/r/reference/schema.md) :
  Create a schema or extract one from an object.
- [`unify_schemas()`](https://arrow.apache.org/docs/r/reference/unify_schemas.md)
  : Combine and harmonize schemas
- [`as_schema()`](https://arrow.apache.org/docs/r/reference/as_schema.md)
  : Convert an object to an Arrow Schema
- [`infer_schema()`](https://arrow.apache.org/docs/r/reference/infer_schema.md)
  : Extract a schema from an object
- [`read_schema()`](https://arrow.apache.org/docs/r/reference/read_schema.md)
  : Read a Schema from a stream

## Computation

Functionality for computing values on Arrow data objects.

- [`acero`](https://arrow.apache.org/docs/r/reference/acero.md)
  [`arrow-functions`](https://arrow.apache.org/docs/r/reference/acero.md)
  [`arrow-verbs`](https://arrow.apache.org/docs/r/reference/acero.md)
  [`arrow-dplyr`](https://arrow.apache.org/docs/r/reference/acero.md) :
  Functions available in Arrow dplyr queries

- [`call_function()`](https://arrow.apache.org/docs/r/reference/call_function.md)
  : Call an Arrow compute function

- [`match_arrow()`](https://arrow.apache.org/docs/r/reference/match_arrow.md)
  [`is_in()`](https://arrow.apache.org/docs/r/reference/match_arrow.md)
  : Value matching for Arrow objects

- [`value_counts()`](https://arrow.apache.org/docs/r/reference/value_counts.md)
  :

  `table` for Arrow objects

- [`list_compute_functions()`](https://arrow.apache.org/docs/r/reference/list_compute_functions.md)
  : List available Arrow C++ compute functions

- [`register_scalar_function()`](https://arrow.apache.org/docs/r/reference/register_scalar_function.md)
  : Register user-defined functions

- [`show_exec_plan()`](https://arrow.apache.org/docs/r/reference/show_exec_plan.md)
  : Show the details of an Arrow Execution Plan

## DuckDB

Pass data to and from DuckDB

- [`to_arrow()`](https://arrow.apache.org/docs/r/reference/to_arrow.md)
  : Create an Arrow object from a DuckDB connection
- [`to_duckdb()`](https://arrow.apache.org/docs/r/reference/to_duckdb.md)
  : Create a (virtual) DuckDB table from an Arrow object

## File systems

Functions for working with files on S3 and GCS

- [`s3_bucket()`](https://arrow.apache.org/docs/r/reference/s3_bucket.md)
  : Connect to an AWS S3 bucket
- [`gs_bucket()`](https://arrow.apache.org/docs/r/reference/gs_bucket.md)
  : Connect to a Google Cloud Storage (GCS) bucket
- [`copy_files()`](https://arrow.apache.org/docs/r/reference/copy_files.md)
  : Copy files between FileSystems

## Flight

- [`load_flight_server()`](https://arrow.apache.org/docs/r/reference/load_flight_server.md)
  : Load a Python Flight server
- [`flight_connect()`](https://arrow.apache.org/docs/r/reference/flight_connect.md)
  : Connect to a Flight server
- [`flight_disconnect()`](https://arrow.apache.org/docs/r/reference/flight_disconnect.md)
  : Explicitly close a Flight client
- [`flight_get()`](https://arrow.apache.org/docs/r/reference/flight_get.md)
  : Get data from a Flight server
- [`flight_put()`](https://arrow.apache.org/docs/r/reference/flight_put.md)
  : Send data to a Flight server
- [`list_flights()`](https://arrow.apache.org/docs/r/reference/list_flights.md)
  [`flight_path_exists()`](https://arrow.apache.org/docs/r/reference/list_flights.md)
  : See available resources on a Flight server

## Arrow Configuration

- [`arrow_info()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_available()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_acero()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_dataset()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_substrait()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_parquet()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_s3()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_gcs()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  [`arrow_with_json()`](https://arrow.apache.org/docs/r/reference/arrow_info.md)
  : Report information on the package's capabilities
- [`cpu_count()`](https://arrow.apache.org/docs/r/reference/cpu_count.md)
  [`set_cpu_count()`](https://arrow.apache.org/docs/r/reference/cpu_count.md)
  : Manage the global CPU thread pool in libarrow
- [`io_thread_count()`](https://arrow.apache.org/docs/r/reference/io_thread_count.md)
  [`set_io_thread_count()`](https://arrow.apache.org/docs/r/reference/io_thread_count.md)
  : Manage the global I/O thread pool in libarrow
- [`install_arrow()`](https://arrow.apache.org/docs/r/reference/install_arrow.md)
  : Install or upgrade the Arrow library
- [`install_pyarrow()`](https://arrow.apache.org/docs/r/reference/install_pyarrow.md)
  : Install pyarrow for use with reticulate
- [`create_package_with_all_dependencies()`](https://arrow.apache.org/docs/r/reference/create_package_with_all_dependencies.md)
  : Create a source bundle that includes all thirdparty dependencies

## Input/Output

- [`InputStream`](https://arrow.apache.org/docs/r/reference/InputStream.md)
  [`RandomAccessFile`](https://arrow.apache.org/docs/r/reference/InputStream.md)
  [`MemoryMappedFile`](https://arrow.apache.org/docs/r/reference/InputStream.md)
  [`ReadableFile`](https://arrow.apache.org/docs/r/reference/InputStream.md)
  [`BufferReader`](https://arrow.apache.org/docs/r/reference/InputStream.md)
  : InputStream classes
- [`read_message()`](https://arrow.apache.org/docs/r/reference/read_message.md)
  : Read a Message from a stream
- [`mmap_open()`](https://arrow.apache.org/docs/r/reference/mmap_open.md)
  : Open a memory mapped file
- [`mmap_create()`](https://arrow.apache.org/docs/r/reference/mmap_create.md)
  : Create a new read/write memory mapped file of a given size
- [`OutputStream`](https://arrow.apache.org/docs/r/reference/OutputStream.md)
  [`FileOutputStream`](https://arrow.apache.org/docs/r/reference/OutputStream.md)
  [`BufferOutputStream`](https://arrow.apache.org/docs/r/reference/OutputStream.md)
  : OutputStream classes
- [`Message`](https://arrow.apache.org/docs/r/reference/Message.md) :
  Message class
- [`MessageReader`](https://arrow.apache.org/docs/r/reference/MessageReader.md)
  : MessageReader class
- [`compression`](https://arrow.apache.org/docs/r/reference/compression.md)
  [`CompressedOutputStream`](https://arrow.apache.org/docs/r/reference/compression.md)
  [`CompressedInputStream`](https://arrow.apache.org/docs/r/reference/compression.md)
  : Compressed stream classes
- [`Codec`](https://arrow.apache.org/docs/r/reference/Codec.md) :
  Compression Codec class
- [`codec_is_available()`](https://arrow.apache.org/docs/r/reference/codec_is_available.md)
  : Check whether a compression codec is available

## File read/writer interface

- [`ParquetFileReader`](https://arrow.apache.org/docs/r/reference/ParquetFileReader.md)
  : ParquetFileReader class
- [`ParquetReaderProperties`](https://arrow.apache.org/docs/r/reference/ParquetReaderProperties.md)
  : ParquetReaderProperties class
- [`ParquetArrowReaderProperties`](https://arrow.apache.org/docs/r/reference/ParquetArrowReaderProperties.md)
  : ParquetArrowReaderProperties class
- [`ParquetFileWriter`](https://arrow.apache.org/docs/r/reference/ParquetFileWriter.md)
  : ParquetFileWriter class
- [`ParquetWriterProperties`](https://arrow.apache.org/docs/r/reference/ParquetWriterProperties.md)
  : ParquetWriterProperties class
- [`FeatherReader`](https://arrow.apache.org/docs/r/reference/FeatherReader.md)
  : FeatherReader class
- [`CsvTableReader`](https://arrow.apache.org/docs/r/reference/CsvTableReader.md)
  [`JsonTableReader`](https://arrow.apache.org/docs/r/reference/CsvTableReader.md)
  : Arrow CSV and JSON table reader classes
- [`CsvReadOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`CsvWriteOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`CsvParseOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`TimestampParser`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`CsvConvertOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`JsonReadOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  [`JsonParseOptions`](https://arrow.apache.org/docs/r/reference/CsvReadOptions.md)
  : File reader options
- [`RecordBatchReader`](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
  [`RecordBatchStreamReader`](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
  [`RecordBatchFileReader`](https://arrow.apache.org/docs/r/reference/RecordBatchReader.md)
  : RecordBatchReader classes
- [`RecordBatchWriter`](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
  [`RecordBatchStreamWriter`](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
  [`RecordBatchFileWriter`](https://arrow.apache.org/docs/r/reference/RecordBatchWriter.md)
  : RecordBatchWriter classes
- [`as_record_batch_reader()`](https://arrow.apache.org/docs/r/reference/as_record_batch_reader.md)
  : Convert an object to an Arrow RecordBatchReader

## Low-level C++ wrappers

Low-level R6 class representations of Arrow C++ objects intended for
advanced users.

- [`Buffer`](https://arrow.apache.org/docs/r/reference/Buffer-class.md)
  : Buffer class
- [`Scalar`](https://arrow.apache.org/docs/r/reference/Scalar-class.md)
  : Arrow scalars
- [`Array`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`DictionaryArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`StructArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`ListArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`LargeListArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`FixedSizeListArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  [`MapArray`](https://arrow.apache.org/docs/r/reference/array-class.md)
  : Array Classes
- [`ChunkedArray`](https://arrow.apache.org/docs/r/reference/ChunkedArray-class.md)
  : ChunkedArray class
- [`RecordBatch`](https://arrow.apache.org/docs/r/reference/RecordBatch-class.md)
  : RecordBatch class
- [`Schema`](https://arrow.apache.org/docs/r/reference/Schema-class.md)
  : Schema class
- [`Field`](https://arrow.apache.org/docs/r/reference/Field-class.md) :
  Field class
- [`Table`](https://arrow.apache.org/docs/r/reference/Table-class.md) :
  Table class
- [`DataType`](https://arrow.apache.org/docs/r/reference/DataType-class.md)
  : DataType class
- [`ArrayData`](https://arrow.apache.org/docs/r/reference/ArrayData.md)
  : ArrayData class
- [`DictionaryType`](https://arrow.apache.org/docs/r/reference/DictionaryType.md)
  : DictionaryType class
- [`FixedWidthType`](https://arrow.apache.org/docs/r/reference/FixedWidthType.md)
  : FixedWidthType class
- [`ExtensionType`](https://arrow.apache.org/docs/r/reference/ExtensionType.md)
  : ExtensionType class
- [`ExtensionArray`](https://arrow.apache.org/docs/r/reference/ExtensionArray.md)
  : ExtensionArray class

## Dataset and Filesystem R6 classes and helper functions

R6 classes and helper functions useful for when working with multi-file
datases in Arrow.

- [`Dataset`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  [`FileSystemDataset`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  [`UnionDataset`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  [`InMemoryDataset`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  [`DatasetFactory`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  [`FileSystemDatasetFactory`](https://arrow.apache.org/docs/r/reference/Dataset.md)
  : Multi-file datasets
- [`dataset_factory()`](https://arrow.apache.org/docs/r/reference/dataset_factory.md)
  : Create a DatasetFactory
- [`Partitioning`](https://arrow.apache.org/docs/r/reference/Partitioning.md)
  [`DirectoryPartitioning`](https://arrow.apache.org/docs/r/reference/Partitioning.md)
  [`HivePartitioning`](https://arrow.apache.org/docs/r/reference/Partitioning.md)
  [`DirectoryPartitioningFactory`](https://arrow.apache.org/docs/r/reference/Partitioning.md)
  [`HivePartitioningFactory`](https://arrow.apache.org/docs/r/reference/Partitioning.md)
  : Define Partitioning for a Dataset
- [`Expression`](https://arrow.apache.org/docs/r/reference/Expression.md)
  : Arrow expressions
- [`Scanner`](https://arrow.apache.org/docs/r/reference/Scanner.md)
  [`ScannerBuilder`](https://arrow.apache.org/docs/r/reference/Scanner.md)
  : Scan the contents of a dataset
- [`FileFormat`](https://arrow.apache.org/docs/r/reference/FileFormat.md)
  [`ParquetFileFormat`](https://arrow.apache.org/docs/r/reference/FileFormat.md)
  [`IpcFileFormat`](https://arrow.apache.org/docs/r/reference/FileFormat.md)
  : Dataset file formats
- [`CsvFileFormat`](https://arrow.apache.org/docs/r/reference/CsvFileFormat.md)
  : CSV dataset file format
- [`JsonFileFormat`](https://arrow.apache.org/docs/r/reference/JsonFileFormat.md)
  : JSON dataset file format
- [`FileWriteOptions`](https://arrow.apache.org/docs/r/reference/FileWriteOptions.md)
  : Format-specific write options
- [`FragmentScanOptions`](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md)
  [`CsvFragmentScanOptions`](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md)
  [`ParquetFragmentScanOptions`](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md)
  [`JsonFragmentScanOptions`](https://arrow.apache.org/docs/r/reference/FragmentScanOptions.md)
  : Format-specific scan options
- [`hive_partition()`](https://arrow.apache.org/docs/r/reference/hive_partition.md)
  : Construct Hive partitioning
- [`map_batches()`](https://arrow.apache.org/docs/r/reference/map_batches.md)
  : Apply a function to a stream of RecordBatches
- [`FileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
  [`LocalFileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
  [`S3FileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
  [`GcsFileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
  [`SubTreeFileSystem`](https://arrow.apache.org/docs/r/reference/FileSystem.md)
  : FileSystem classes
- [`FileInfo`](https://arrow.apache.org/docs/r/reference/FileInfo.md) :
  FileSystem entry info
- [`FileSelector`](https://arrow.apache.org/docs/r/reference/FileSelector.md)
  : file selector
