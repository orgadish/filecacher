# Data Paths --------------------------------------------------------------

EXTDATA_FOLDER <- fs::path_package("extdata", package="cachedread")
IRIS_COMPLETE_PATH <- fs::path(EXTDATA_FOLDER, "iris_complete.csv")
IRIS_SETOSA_PATH <- fs::path(EXTDATA_FOLDER, "iris_setosa_only.csv")
IRIS_VERSICOLOR_PATH <- fs::path(EXTDATA_FOLDER, "iris_versicolor_only.csv")
IRIS_VIRGINICA_PATH <- fs::path(EXTDATA_FOLDER, "iris_virginica_only.csv")
IRIS_PATHS_BY_SPECIES <- c(IRIS_SETOSA_PATH, IRIS_VERSICOLOR_PATH, IRIS_VIRGINICA_PATH)
IRIS_PATHS <- c(IRIS_COMPLETE_PATH, IRIS_PATHS_BY_SPECIES)

# Temporary Cache Directory -----------------------------------------------
temp_dirname <- paste("temp", Sys.time()) |>
  fs::path_sanitize()
TEMP_DIR <- fs::path(EXTDATA_FOLDER, temp_dirname)
fs::dir_create(TEMP_DIR)
create_temp_cache_dir <- function() {
  cache_dir_name <- paste("temp", Sys.time(), sample.int(1e3, 1), sep="_") |>
    fs::path_sanitize()
  cache_dir_path <- fs::path(TEMP_DIR, cache_dir_name)
  fs::dir_create(cache_dir_path)

  return(cache_dir_path)
}


# Helpers -----------------------------------------------------------------

# Silent read_csv
silent_read_csv <- function(...) suppressMessages(readr::read_csv(...))

# Silent read_csv + slow process
original_read_csv_with_expectation <- function(expected, ...) {
  expect(expected, "Original `read_fn` was called when not expected...")

  silent_read_csv(...)
}

# Expect cache files.
CACHE_LABEL <- "data"
expect_cache_file_exists <- function(dir_path, exists, ext="cache_arrow") {
  expected_cache_file_path <- fs::path(dir_path, CACHE_LABEL, ext = ext)
  cache_file_exists <- fs::file_exists(expected_cache_file_path)

  if(exists) expect_true(cache_file_exists)
  else expect_false(cache_file_exists)
}

# Expect Equal DFs
expect_equal_dfs <- function(x, y) {
  expect_true(dfs_equal(x, y))
}


# Tests -------------------------------------------------------------------

test_that("test data is set up correctly", {
  for(path in IRIS_PATHS) expect_true(fs::file_exists(path))

  expect_true(silent_read_csv(IRIS_PATHS) |> tibble::is_tibble())

  # Confirm they match when combined.
  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)
  iris_complete_by_subpaths <- silent_read_csv(IRIS_PATHS_BY_SPECIES)
  expect_equal_dfs(iris_complete, iris_complete_by_subpaths)

})

test_that("cached_read with check='file_info' works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  CACHE_EXT = "cache_arrow"
  CACHE_INFO_EXT = paste0(CACHE_EXT, "_info")

  expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_EXT)
  expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_INFO_EXT)
  for(i in 1:3) {
    original_call_expected <- i == 1
    res <- cached_read(IRIS_PATHS_BY_SPECIES,
                       \(f) original_read_csv_with_expectation(expected = original_call_expected, f),
                       label = CACHE_LABEL,
                       cache_dir = temp_cache_dir)
    expect_equal_dfs(res, iris_complete)
    # file_info_path <- fs::path(temp_cache_dir, CACHE_LABEL, ext = CACHE_INFO_EXT)
    # fs::file_copy(
    #   file_info_path,
    #   fs::path(EXTDATA_FOLDER, glue::glue("{CACHE_LABEL}_{i}"), ext = CACHE_INFO_EXT)
    # )

    expect_cache_file_exists(temp_cache_dir, TRUE, ext=CACHE_EXT)
    expect_cache_file_exists(temp_cache_dir, TRUE, ext=CACHE_INFO_EXT)
  }
})

expect_check_exists_functions_correctly <- function(cache_ext, ...) {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  CACHE_INFO_EXT = paste0(cache_ext, "_info")

  expect_cache_file_exists(temp_cache_dir, FALSE, ext=cache_ext)
  expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_INFO_EXT)

  for(i in 1:3) {
    original_call_expected <- i == 1
    res <- cached_read(IRIS_PATHS_BY_SPECIES,
                       \(f) original_read_csv_with_expectation(expected = original_call_expected, f),
                       label = CACHE_LABEL,
                       check = "exists",
                       cache_dir = temp_cache_dir,
                       ...)

    expect_equal_dfs(res, iris_complete)

    expect_cache_file_exists(temp_cache_dir, TRUE, ext=cache_ext)
    expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_INFO_EXT)
  }
}

test_that("cached_read with check='exists' works correctly", {
  expect_check_exists_functions_correctly("cache_arrow")
})

test_that("cached_read with check='exists' and type='data.table' works correctly", {
  expect_check_exists_functions_correctly("cache_csv", cache_type = "data.table")
})

test_that("cached_read with check='exists' and type='csv' works correctly", {
  expect_check_exists_functions_correctly("cache_csv", cache_type = "csv")
})

test_that("cached_read_csv works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file_exists(temp_cache_dir, FALSE)
  for(i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      suppressMessages(cached_read_csv(IRIS_PATHS_BY_SPECIES,
                                       label = CACHE_LABEL,
                                       cache_dir = temp_cache_dir))
    )

    expect_cache_file_exists(temp_cache_dir, TRUE)
  }
})


test_that("use_caching works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)


  CACHE_EXT = "cache_arrow"
  CACHE_INFO_EXT = paste0(CACHE_EXT, "_info")

  expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_EXT)
  expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_INFO_EXT)
  for(i in 1:3) {
    original_call_expected <- i == 1
    res <- original_read_csv_with_expectation(expected = original_call_expected,
                                              IRIS_PATHS_BY_SPECIES) |>
      use_caching(label = CACHE_LABEL,
                  cache_dir=temp_cache_dir)

    expect_equal_dfs(res, iris_complete)
    expect_cache_file_exists(temp_cache_dir, TRUE, ext=CACHE_EXT)
    expect_cache_file_exists(temp_cache_dir, FALSE, ext=CACHE_INFO_EXT)
  }

})

test_that("cached_read with check='file_info' forces if files are modified", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file_exists(temp_cache_dir, FALSE)
  for(i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      cached_read(IRIS_PATHS_BY_SPECIES,
                  \(f) original_read_csv_with_expectation(expected = TRUE, f),
                  label = CACHE_LABEL,
                  check = "file_info",
                  cache_dir = temp_cache_dir)
    )

    # Update file last modified time to force new reading.
    fs::file_touch(IRIS_PATHS_BY_SPECIES)

    expect_cache_file_exists(temp_cache_dir, TRUE)
  }
})


# Delete Temporary Directory ----------------------------------------------

fs::dir_delete(TEMP_DIR)
