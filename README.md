
<!-- README.md is generated from README.Rmd. Please edit that file -->

# filecacher

<!-- badges: start -->
<!-- badges: end -->

The main functions in this package are:

1.  `with_cache`: Caches the expression in a local file on disk.
2.  `force_cache`: Drop-in replacement for `with_cache` that forces
    reevaluation and saving into the cache.
3.  `cached_read`: A wrapper around a typical read function that caches
    the result and the file list info. If the input file list info
    hasn’t changed (including date modified), the cache file will be
    read. This can save time if the original operation requires reading
    from many files, or involves lots of processing.

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
fs::path_file(IRIS_FILES_BY_SPECIES)
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
#   1. Read using a vectorized `read.csv`.
#   2. Perform some custom processing that takes a while (currently using sleep as an example).
normal_pipeline <- function(files, ...) {
  files |> 
    filecacher::vectorize_reader(read.csv)() |> 
    suppressMessages() |>
    something_that_takes_a_while()
}

# Same pipeline, using `cached_read` which caches the contents and the file info for checking later:
pipeline_using_cached_read <- function(files, cache_dir) {
  files |> 
    filecacher::cached_read(
      label = "processed_data_using_cached_read",
      read_fn = normal_pipeline, 
      cache = cache_dir,
      type = "parquet"
    )
}

# Alternate syntax, with `with_cache`. Using `with_cache` only checks that the cache file
# exists, without any information about the file list.
pipeline_using_with_cache <- function(files, cache_dir) {
  normal_pipeline(files) |> 
    filecacher::with_cache(
      label = "processed_data_using_with_cache",
      cache = cache_dir,
      type = "parquet"
    )
}

# Time each pipeline when repeated 3 times:
time_pipeline <- function(pipeline_fn) {
  function_name <- as.character(match.call()[2])
  print(function_name)
  
  # Create a temporary directory for the cache.
  cache_dir <- fs::path(TEMP_DIR, paste0("temp_", function_name))
  fs::dir_create(cache_dir)
  
  gc()
  
  for(i in 1:3) {
    print(system.time(pipeline_fn(IRIS_FILES_BY_SPECIES, cache_dir)))
  }
}

time_pipeline(normal_pipeline)
#> [1] "normal_pipeline"
#>    user  system elapsed 
#>   0.199   0.021   0.725 
#>    user  system elapsed 
#>   0.003   0.001   0.507 
#>    user  system elapsed 
#>   0.003   0.001   0.505
time_pipeline(pipeline_using_cached_read)
#> [1] "pipeline_using_cached_read"
#>    user  system elapsed 
#>   0.418   0.036   0.966 
#>    user  system elapsed 
#>   0.031   0.003   0.031 
#>    user  system elapsed 
#>   0.011   0.001   0.010
time_pipeline(pipeline_using_with_cache)
#> [1] "pipeline_using_with_cache"
#>    user  system elapsed 
#>   0.009   0.002   0.516 
#>    user  system elapsed 
#>   0.005   0.000   0.005 
#>    user  system elapsed 
#>   0.006   0.000   0.006


# Delete the temporary directory created to run these examples.
fs::dir_delete(TEMP_DIR)
  
```
