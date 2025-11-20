<div id="main" class="col-md-9" role="main">

# MemoryPool class

<div class="ref-description section level2">

MemoryPool class

</div>

<div class="section level2">

## Methods

-   `backend_name`: one of "jemalloc", "mimalloc", or "system".
    Alternative memory allocators are optionally enabled at build time.
    Windows builds generally have `mimalloc`, and most others have both
    `jemalloc` (used by default) and `mimalloc`. To change memory
    allocators at runtime, set the environment variable
    `ARROW_DEFAULT_MEMORY_POOL` to one of those strings prior to loading
    the `arrow` library.

-   `bytes_allocated`

-   `max_memory`

</div>

</div>
