EXTDATA_FOLDER <- fs::path_package("extdata", package="cachedread")
IRIS_COMPLETE_PATH <- fs::path(EXTDATA_FOLDER, "iris_complete.csv")
IRIS_SETOSA_PATH <- fs::path(EXTDATA_FOLDER, "iris_setosa_only.csv")
IRIS_VERSICOLOR_PATH <- fs::path(EXTDATA_FOLDER, "iris_versicolor_only.csv")
IRIS_VIRGINICA_PATH <- fs::path(EXTDATA_FOLDER, "iris_virginica_only.csv")
IRIS_PATHS_BY_SPECIES <- c(IRIS_SETOSA_PATH, IRIS_VERSICOLOR_PATH, IRIS_VIRGINICA_PATH)
IRIS_PATHS <- c(IRIS_COMPLETE_PATH, IRIS_PATHS_BY_SPECIES)

silent_read_csv <- function(...) suppressMessages(readr::read_csv(...))

# Temporary cache_dir
TEMP_DIR <- fs::path(EXTDATA_FOLDER, paste("temp", Sys.time()))
fs::dir_create(TEMP_DIR)
create_temp_cache_dir <- function() {
  cache_dir_path <- fs::path(TEMP_DIR, paste("temp", Sys.time(), sample.int(1e3, 1), sep="_"))
  fs::dir_create(cache_dir_path)

  return(cache_dir_path)
}

# Expected cache_file path.
CACHE_LABEL <- "data"
expect_cache_file_exists <- function(dir_path, exists) {
  expected_cache_file_path <- fs::path(dir_path, CACHE_LABEL, ext = "cache_arrow")
  cache_file_exists <- fs::file_exists(expected_cache_file_path)

  if(exists) expect_true(cache_file_exists)
  else expect_false(cache_file_exists)
}

expect_equal_dfs <- function(x, y, ignore_row_order=TRUE, ...) {
  expect_true(
    dplyr::all_equal(x, y, ignore_row_order = ignore_row_order, ...) |>
      isTRUE()
  )
}

test_that("test data is set up correctly", {
  for(path in IRIS_PATHS) expect_true(fs::file_exists(path))

  expect_true(silent_read_csv(IRIS_PATHS) |> tibble::is_tibble())

  # Confirm they match when combined.
  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)
  iris_complete_by_subpaths <- silent_read_csv(IRIS_PATHS_BY_SPECIES)
  expect_equal_dfs(iris_complete, iris_complete_by_subpaths)

})

test_that("cached_read works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- silent_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file_exists(temp_cache_dir, FALSE)
  for(i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      cached_read(IRIS_PATHS_BY_SPECIES,
                  silent_read_csv,
                  label = CACHE_LABEL,
                  cache_dir = temp_cache_dir)
    )

    expect_cache_file_exists(temp_cache_dir, TRUE)
  }
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

  expect_cache_file_exists(temp_cache_dir, FALSE)
  for(i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      silent_read_csv(IRIS_PATHS_BY_SPECIES) |>
        use_caching(label = CACHE_LABEL,
                    cache_dir = temp_cache_dir)
    )

    expect_cache_file_exists(temp_cache_dir, TRUE)
  }

})

# Delete temp dir.
fs::dir_delete(TEMP_DIR)
