
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
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline      1.06s    1.06s     0.940    7.75MB    0.940
#> 2 2         pipeline      1.05s    1.05s     0.954  185.83KB    0.954
#> 3 3         pipeline      1.05s    1.05s     0.954  186.39KB    0
time_repeated_calls(\() pipeline_with_cached_read(iris_files_by_species))
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> Warning: Some expressions had a GC in every iteration; so filtering is disabled.
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline      1.11s    1.11s     0.903    17.4MB    0    
#> 2 2         pipeline       1.1s     1.1s     0.910   364.2KB    0.910
#> 3 3         pipeline      1.09s    1.09s     0.921   364.4KB    0.921
time_repeated_calls(\() pipeline_with_use_caching(iris_files_by_species))
#> Rows: 150 Columns: 5
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (1): Species
#> dbl (4): Sepal.Length, Sepal.Width, Petal.Length, Petal.Width
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 3 × 7
#>   iteration expression      min   median `itr/sec` mem_alloc `gc/sec`
#>   <chr>     <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
#> 1 1         pipeline     3.26ms   3.26ms      307.  217.38KB        0
#> 2 2         pipeline     3.03ms   3.03ms      330.    9.28KB        0
#> 3 3         pipeline     3.54ms   3.54ms      282.    9.28KB        0

# Delete the temporary directory created to run these examples.
fs::dir_delete(temp_dir)
```
