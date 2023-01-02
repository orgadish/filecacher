
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cachedread

<!-- badges: start -->
<!-- badges: end -->

The main function in this package is `cached_read`. It is a wrapper for
a standard read function, which saves the output into a local file. If
the input files haven’t changed, the next time the read is performed,
the cached file will be read. This can save time if the original
operation requires reading from many files, or involves lots of
processing.

See examples below.

## Installation

You can install the development version of `cachedread` like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

``` r
example_data_folder <- fs::path_package("extdata", package="cachedread")

iris_files_by_species <- fs::dir_ls(example_data_folder, glob="*only.csv", recurse=T)

# Create a temporary directory to run these examples.
temp_dir <- fs::path(example_data_folder, "temp")
fs::dir_create(temp_dir)

# Use janitor::clean_names if it exists.
clean_names <- if(requireNamespace("janitor", quietly=TRUE)) janitor::clean_names else \(x) x
something_that_takes_a_while <- function(x) { 
  Sys.sleep(1) 
  return(x)
}

# Example standard pipeline without caching:
#   1. Read using `readr::read_csv`.
#   2. Clean names using `janitor::clean_names`.
#   3. Perform some custom processing that takes a while (currently using sleep as an example).
normal_pipeline <- function(files) {
    readr::read_csv(files) |>
    suppressMessages() |>
    clean_names() |>
    something_that_takes_a_while()
}

# Same pipeline with caching:
pipeline_with_cached_read <- function(files) {
  cachedread::cached_read(
    files,
    read_fn = normal_pipeline,
    label="processed_data_cached_read",
    cache_dir=temp_dir
  )
}

# Alternate syntax, with `use_caching`
pipeline_with_use_caching <- function(files) {
  cachedread::use_caching(
    normal_pipeline(files),
    label="processed_data_use_caching",
    cache_dir=temp_dir
  )
}

time_repeated_calls <- function(fn_call, iterations = 3) {
  lapply(
    1:iterations,
    \(x) bench::mark(pipeline = fn_call(), iterations = 1, check= FALSE)
  ) |>
    dplyr::bind_rows(.id="iteration")
}

time_repeated_calls(\() normal_pipeline(iris_files_by_species))
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.

#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline      1.05s    1.05s     0.950    7.76MB    0    
#> 2 2         pipeline      1.06s    1.06s     0.947  185.83KB    0.947
#> 3 3         pipeline      1.08s    1.08s     0.924  185.84KB    0.924
time_repeated_calls(\() pipeline_with_cached_read(iris_files_by_species))
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.

#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline      1.15s    1.15s     0.873    17.4MB    0    
#> 2 2         pipeline      1.13s    1.13s     0.886   364.2KB    0.886
#> 3 3         pipeline      1.12s    1.12s     0.894   364.2KB    0.894
time_repeated_calls(\() pipeline_with_use_caching(iris_files_by_species))
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline     5.46ms   5.46ms      183.  217.38KB        0
#> 2 2         pipeline     4.18ms   4.18ms      239.    9.28KB        0
#> 3 3         pipeline     6.91ms   6.91ms      145.    9.28KB        0

# Delete the temporary directory created to run these examples.
fs::dir_delete(temp_dir)
```
