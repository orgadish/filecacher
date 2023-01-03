
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
example_data_folder <- fs::path_package("extdata", package = "cachedread")

iris_files_by_species <- example_data_folder |>
  fs::dir_ls(glob = "*_only.csv")

# Create a temporary directory to run these examples.
temp_dir <- fs::path(example_data_folder, "temp")
fs::dir_create(temp_dir)

# Use janitor::clean_names if it exists.
clean_names <- if (requireNamespace("janitor", quietly = TRUE)) janitor::clean_names else \(x) x

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
    clean_names() |>
    something_that_takes_a_while()
}

# Same pipeline, using `cached_read`:
pipeline_with_cached_read <- function(files) {
  cachedread::cached_read(
    files, 
    read_fn = normal_pipeline, 
    label = "processed_data_cached_read",
    check = "exists",
    cache_dir = temp_dir
  )
}

# Alternate syntax, with `use_caching`
pipeline_with_use_caching <- function(files) {
  cachedread::use_caching(
    normal_pipeline(files), 
    label = "processed_data_use_caching",
    cache_dir = temp_dir
  )
}

# Time the pipelines when repeated 3 times:
lapply(
  1:3, 
  \(x) bench::mark(
    normal = normal_pipeline(iris_files_by_species),
    cached_read = pipeline_with_cached_read(iris_files_by_species),
    use_caching = pipeline_with_use_caching(iris_files_by_species),
    iterations = 1, 
    check = FALSE, 
    filter_gc = FALSE
  )
) |>
    dplyr::bind_rows(.id = "iteration")
#> # A tibble: 9 × 7
#>   iteration expression       min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr>  <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         normal      553.18ms 553.18ms      1.81    7.76MB      0  
#> 2 1         cached_read  23.34ms  23.34ms     42.8    13.82MB     42.8
#> 3 1         use_caching   3.76ms   3.76ms    266.    222.21KB      0  
#> 4 2         normal      553.38ms 553.38ms      1.81  185.98KB      0  
#> 5 2         cached_read   3.69ms   3.69ms    271.      9.28KB      0  
#> 6 2         use_caching   3.54ms   3.54ms    283.      9.28KB      0  
#> 7 3         normal      554.14ms 554.14ms      1.80  185.98KB      0  
#> 8 3         cached_read   4.09ms   4.09ms    245.      9.28KB      0  
#> 9 3         use_caching   3.98ms   3.98ms    251.      9.28KB      0

# Delete the temporary directory created to run these examples.
fs::dir_delete(temp_dir)
```
