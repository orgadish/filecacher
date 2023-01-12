
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
# install.packages("devtools")
devtools::install_github("orgadish/cachedread")
```

## Example

``` r
example_data_folder <- fs::path_package("extdata", package = "cachedread")

IRIS_FILES_BY_SPECIES <- example_data_folder |>
  fs::dir_ls(glob = "*_only.csv")

# Create a temporary directory to run these examples.
TEMP_DIR <- fs::path(example_data_folder, "temp")
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
  readr::read_csv(files) |>
    suppressMessages() |>
    janitor::clean_names() |>
    something_that_takes_a_while()

}

# Same pipeline, using `cached_read`:
pipeline_with_cached_read <- function(files) {
  cachedread::cached_read(
    files, 
    read_fn = normal_pipeline, 
    label = "processed_data_cached_read",
    check = "exists",
    cache_dir = TEMP_DIR
  )

}

# Alternate syntax, with `use_caching`
pipeline_with_use_caching <- function(files) {
  cachedread::use_caching(
    normal_pipeline(files), 
    label = "processed_data_use_caching",
    cache_dir = TEMP_DIR
  )

}

# Time the pipelines when repeated 3 times:
get_elapsed_time_for_pipelines <- function() {
  system_time_elapsed_in_ms <- function(expr) {
    elapsed <- system.time(expr)['elapsed']
    round(elapsed * 1000) |>
      paste("ms")
  }
  
  tidyr::crossing(
    iteration=1:3, 
    tibble::tibble(
      label = c("normal", "cached_read", "use_caching") |> forcats::fct_inorder(),
      pipeline_fn = list(normal_pipeline, pipeline_with_cached_read, pipeline_with_use_caching)
    )
  ) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      elapsed = system_time_elapsed_in_ms(pipeline_fn(IRIS_FILES_BY_SPECIES))
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-pipeline_fn) |>
    dplyr::arrange(label, iteration)
}

get_elapsed_time_for_pipelines()
#> # A tibble: 9 × 3
#>   iteration label       elapsed
#>       <int> <fct>       <chr>  
#> 1         1 normal      938 ms 
#> 2         2 normal      553 ms 
#> 3         3 normal      548 ms 
#> 4         1 cached_read 890 ms 
#> 5         2 cached_read 21 ms  
#> 6         3 cached_read 5 ms   
#> 7         1 use_caching 543 ms 
#> 8         2 use_caching 5 ms   
#> 9         3 use_caching 4 ms

# Delete the temporary directory created to run these examples.
fs::dir_delete(TEMP_DIR)
  
```
