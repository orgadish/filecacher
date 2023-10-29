# Data Paths --------------------------------------------------------------

EXTDATA_FOLDER <- fs::path_package("extdata", package = "filecacher")
IRIS_COMPLETE_PATH <- fs::path(EXTDATA_FOLDER, "iris_complete.csv")
IRIS_SETOSA_PATH <- fs::path(EXTDATA_FOLDER, "iris_setosa_only.csv")
IRIS_VERSICOLOR_PATH <- fs::path(EXTDATA_FOLDER, "iris_versicolor_only.csv")
IRIS_VIRGINICA_PATH <- fs::path(EXTDATA_FOLDER, "iris_virginica_only.csv")
IRIS_PATHS_BY_SPECIES <- c(
  IRIS_SETOSA_PATH, IRIS_VERSICOLOR_PATH, IRIS_VIRGINICA_PATH
)
IRIS_PATHS <- c(IRIS_COMPLETE_PATH, IRIS_PATHS_BY_SPECIES)

# Temporary Cache Directory -----------------------------------------------
temp_dirname <- paste("temp", Sys.time()) |>
  fs::path_sanitize()
TEMP_DIR <- fs::path(EXTDATA_FOLDER, temp_dirname)
fs::dir_create(TEMP_DIR)
create_temp_cache_dir <- function() {
  cache_dir_name <- paste("temp", Sys.time(), sample.int(1e3, 1), sep = "_") |>
    fs::path_sanitize()
  cache_dir_path <- fs::path(TEMP_DIR, cache_dir_name)
  fs::dir_create(cache_dir_path)

  return(cache_dir_path)
}


# Helpers -----------------------------------------------------------------

# Silent read_csv
silent_read_csv <- function(...) suppressMessages(readr::read_csv(...))

#' A read_fn that has an expectation of being called or not.
#'
#' @param expected Whether to expect call or not.
read_csv_with_expectation <- function(expected) {
  function(...) {
    expect(expected, "Original `read_fn` was called when not expected...")
    silent_read_csv(...)
  }
}

# Expect cache files.
CACHE_LABEL <- "data"
CACHE_EXT <- "cache_rds" # Default.
to_file_info_label <- function(label) paste0(label, "-file_info")

expect_cache_file <- function(dir_path, exists,
                              ext = CACHE_EXT, file_info = FALSE) {
  label <- if (file_info) to_file_info_label(CACHE_LABEL) else CACHE_LABEL
  expected_cache_file_path <- fs::path(dir_path, label, ext = ext)
  cache_file_exists <- fs::file_exists(expected_cache_file_path)

  if (exists) {
    expect_true(cache_file_exists)
  } else {
    expect_false(cache_file_exists)
  }
}
expect_cache_file_info <- function(dir_path, exists, ext = CACHE_EXT) {
  expect_cache_file(dir_path, exists, ext, file_info = TRUE)
}

# Expect Equal DFs
expect_equal_dfs <- function(x, y) {
  xn <- names(x)
  yn <- names(y)

  expect_equal(length(xn), length(yn))
  expect_equal(xn, yn)
  expect_setequal(unname(data.frame(x)), unname(data.frame(y)))
}

# Tests -------------------------------------------------------------------

test_that("test data is set up correctly", {
  for (path in IRIS_PATHS) expect_true(fs::file_exists(path))

  expect_true(is.data.frame(silent_read_csv(IRIS_PATHS)))

  # Confirm they match when combined.
  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)
  iris_complete_by_subpaths <- silent_read_csv(IRIS_PATHS_BY_SPECIES)
  expect_equal_dfs(iris_complete, iris_complete_by_subpaths)
})

test_that("cached_read default (with file_info check) works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file(temp_cache_dir, FALSE, ext = CACHE_EXT)
  expect_cache_file_info(temp_cache_dir, FALSE, ext = CACHE_EXT)
  for (i in 1:3) {
    call_expected <- i == 1 # Expected to be run only the first time.
    res <- cached_read(
      IRIS_PATHS_BY_SPECIES,
      label = CACHE_LABEL,
      read_fn = read_csv_with_expectation(expected = i == 1),
      cache = temp_cache_dir
    )
    expect_equal_dfs(res, iris_complete)

    expect_cache_file(temp_cache_dir, TRUE, ext = CACHE_EXT)
    expect_cache_file_info(temp_cache_dir, TRUE, ext = CACHE_EXT)
  }
})

expect_skip_file_info_works <- function(cache_ext, type = NULL, ...) {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file(temp_cache_dir, FALSE, ext = cache_ext)
  expect_cache_file_info(temp_cache_dir, FALSE, ext = cache_ext)

  for (i in 1:3) {
    res <- cached_read(IRIS_PATHS_BY_SPECIES,
      label = CACHE_LABEL,
      read_fn = read_csv_with_expectation(expected = i == 1),
      cache = temp_cache_dir,
      skip_file_info = TRUE,
      type = type,
      ...
    ) |>
      # Ignore `file_path` which is added with type='csv'.
      dplyr::select(
        -dplyr::matches("file_path")
      )

    expect_equal_dfs(res, iris_complete)

    expect_cache_file(temp_cache_dir, TRUE, ext = cache_ext)
    expect_cache_file_info(temp_cache_dir, FALSE, ext = cache_ext)
  }
}

test_that("cached_read with skip_file_info and type=NULL works", {
  expect_skip_file_info_works("cache_rds")
})

test_that("cached_read with skip_file_info and type='rds' works", {
  expect_skip_file_info_works("cache_rds", type = "rds")
})

test_that("cached_read with skip_file_info and type='parquet' works", {
  expect_skip_file_info_works("cache_parquet", type = "parquet")
})

test_that("cached_read with skip_file_info and type='csv' works correctly", {
  expect_skip_file_info_works("cache_csv", type = "csv")
})


test_that("cached_read with file_info check forces if files are modified", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file(temp_cache_dir, FALSE)
  for (i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      cached_read(IRIS_PATHS_BY_SPECIES,
        label = CACHE_LABEL,
        read_fn = read_csv_with_expectation(expected = TRUE),
        cache = temp_cache_dir
      )
    )

    # Update file last modified time to force new reading.
    fs::file_touch(IRIS_PATHS_BY_SPECIES)

    expect_cache_file(temp_cache_dir, TRUE)
  }
})


# Delete Temporary Directory ----------------------------------------------

fs::dir_delete(TEMP_DIR)
