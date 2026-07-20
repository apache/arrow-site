# MemoryPool class

MemoryPool class

## Methods

- `backend_name`: one of "jemalloc", "mimalloc", or "system".
  Alternative memory allocators are optionally enabled at build time.
  Windows builds generally have `mimalloc`, and most others have both
  `jemalloc` (used by default) and `mimalloc`. To change memory
  allocators at runtime, set the environment variable
  `ARROW_DEFAULT_MEMORY_POOL` to one of those strings prior to loading
  the `arrow` library.

- `bytes_allocated`

- `max_memory`
