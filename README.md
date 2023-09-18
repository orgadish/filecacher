
<!-- README.md is generated from README.Rmd. Please edit that file -->

# filecacher

<!-- badges: start -->
<!-- badges: end -->

The main functions in this package are: 1. `with_cache`: Caches the
expression in a local file on disk. 1. `force_cache`: Drop-in
replacement for `with_cache` that forces reevaluation and saving into
the cache. 1. `cached_read`: A wrapper around a typical read function
that caches the result and the file list info. If the input file list
info hasn’t changed (including date modified), the cache file will be
read. This can save time if the original operation requires reading from
many files, or involves lots of processing.

See examples below.

## Installation

You can install the development version of `filecacher` like so:

``` r
# install.packages("devtools")
devtools::install_github("orgadish/filecacher")
```

## Example

``` r
EXAMPLE_DATA_FOLDER <- fs::path_package("extdata", package = "filecacher")

# Example files: iris table split by species into three files.
IRIS_FILES_BY_SPECIES <- fs::dir_ls(EXAMPLE_DATA_FOLDER, glob = "*_only.csv")
IRIS_FILES_BY_SPECIES |> fs::path_file()
#> [1] "iris_setosa_only.csv"     "iris_versicolor_only.csv"
#> [3] "iris_virginica_only.csv"


# Create a temporary directory to run these examples.
TEMP_DIR <- fs::path(EXAMPLE_DATA_FOLDER, "temp")
fs::dir_create(TEMP_DIR)


something_that_takes_a_while <- function(x) {
  Sys.sleep(0.5)
  return(x)
}

# Example standard pipeline without caching: 
#   1. Read using `readr::read_csv`.  
#   2. Clean names using `janitor::clean_names`.
#   3. Perform some custom processing that takes a while (currently using sleep as an example).
normal_pipeline <- function(files) {
  files |> 
    readr::read_csv() |>
    suppressMessages() |>
    janitor::clean_names() |>
    something_that_takes_a_while()
}

# Same pipeline, using `cached_read`:
pipeline_using_cached_read <- function(files) {
  files |> 
    filecacher::cached_read(
      label = "processed_data_cached_read",
      read_fn = normal_pipeline, 
      cache = TEMP_DIR
    )
}

# Alternate syntax, with `with_cache`. Using `with_cache` only checks that the cache file
# exists, without any information about the file list.
pipeline_using_with_cache <- function(files) {
  normal_pipeline(files) |> 
    filecacher::with_cache(
      label = "processed_data_use_caching",
      cache = TEMP_DIR
    )
}

# Time the pipelines when repeated 3 times:
system_time_elapsed_in_ms <- function(expr) {
  elapsed <- system.time(expr)['elapsed']
  round(elapsed * 1000) |>
    paste("ms")
}

tibble::tribble(
  ~iteration, ~label, ~pipeline_fn,
  1, "normal", normal_pipeline,
  1, "cached_read", pipeline_using_cached_read,
  1, "with_cache", pipeline_using_with_cache,
  2, "normal", normal_pipeline,
  2, "cached_read", pipeline_using_cached_read,
  2, "with_cache", pipeline_using_with_cache,
  3, "normal", normal_pipeline,
  3, "cached_read", pipeline_using_cached_read,
  3, "with_cache", pipeline_using_with_cache,
) |>
  
  # Clean up results for display.
  dplyr::rowwise() |>
  dplyr::mutate(
    elapsed = system_time_elapsed_in_ms(pipeline_fn(IRIS_FILES_BY_SPECIES))
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-pipeline_fn) |>
  dplyr::arrange(factor(label, levels=c("normal", "cached_read", "with_cache")), iteration)
#> DEBUG: creating new cache...
#> DEBUG: using existing cache...
#> DEBUG: creating new cache...
#> DEBUG: using existing cache...
#> DEBUG: creating new cache...
#> DEBUG: using existing cache...
#> DEBUG: creating new cache...
#> DEBUG: creating new cache...
#> DEBUG: using existing cache...
#> DEBUG: creating new cache...
#> # A tibble: 9 × 3
#>   iteration label       elapsed
#>       <dbl> <chr>       <chr>  
#> 1         1 normal      961 ms 
#> 2         2 normal      556 ms 
#> 3         3 normal      556 ms 
#> 4         1 cached_read 882 ms 
#> 5         2 cached_read 6 ms   
#> 6         3 cached_read 5 ms   
#> 7         1 with_cache  556 ms 
#> 8         2 with_cache  2 ms   
#> 9         3 with_cache  1 ms


# Delete the temporary directory created to run these examples.
fs::dir_delete(TEMP_DIR)
  
```
