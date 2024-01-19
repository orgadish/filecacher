# Temp Test Directory ---------------------------------------------------------
tf <- withr::local_tempfile()
dir.create(tf)

# Copy Data to Temp Data Directory --------------------------------------------
temp_data_folder <- tempfile("data", tmpdir = tf)
dir.create(temp_data_folder)

copy_and_get_path <- function(file = NULL, glob = NULL) {
  extdata_path <- system.file("extdata", package = "filecacher")
  if (!is.null(file)) {
    path <- file.path(extdata_path, file)
  } else if (!is.null(glob)) {
    path <- fs_dir_ls_(extdata_path, glob)
  } else {
    stop("Must use either file or glob!")
  }

  new_path <- file.path(temp_data_folder, basename(path))
  file.copy(path, new_path)

  # Ensure the new file can be written to.
  Sys.chmod(new_path, 420)

  new_path
}

IRIS_COMPLETE_PATH <- copy_and_get_path("iris_complete.csv")
IRIS_PATHS_BY_SPECIES <- copy_and_get_path(glob = "*only.csv")


# Temporary Cache Directory -----------------------------------------------

create_temp_cache_dir <- function() {
  cache_dir_path <- tempfile("cache", tmpdir = tf)
  dir.create(cache_dir_path)
  return(cache_dir_path)
}


# Helpers -----------------------------------------------------------------

vectorized_read_csv <- function(...) {
  vectorize_reader(read.csv)(...)
}

#' A read_fn that has an expectation of being called or not.
#'
#' @param expected Whether to expect call or not.
read_csv_with_expectation <- function(expected) {
  function(...) {
    expect(expected, "Original `read_fn` was called when not expected...")
    vectorized_read_csv(...)
  }
}

# Expect cache files.
CACHE_LABEL <- "data"
CACHE_EXT <- "cache_rds" # Default.
to_file_info_label <- function(label) paste0(label, "-file_info")

expect_cache_file <- function(dir_path, exists,
                              ext = CACHE_EXT, file_info = FALSE) {
  label <- if (file_info) to_file_info_label(CACHE_LABEL) else CACHE_LABEL
  expected_cache_file_path <- file.path(dir_path, paste0(label, ".", ext))
  cache_file_exists <- file.exists(expected_cache_file_path)

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
  all_iris_paths <- c(IRIS_COMPLETE_PATH, IRIS_PATHS_BY_SPECIES)
  for (path in all_iris_paths) expect_true(file.exists(path))

  expect_true(is.data.frame(vectorized_read_csv(all_iris_paths)))

  # Confirm they match when combined.
  iris_complete <- vectorized_read_csv(IRIS_COMPLETE_PATH)
  iris_complete_by_subpaths <- vectorized_read_csv(IRIS_PATHS_BY_SPECIES)
  expect_equal_dfs(iris_complete, iris_complete_by_subpaths)
})

test_that("cached_read default (with file_info check) works correctly", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- vectorized_read_csv(IRIS_COMPLETE_PATH)

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

expect_skip_file_info_works <- function(cache_ext, type = NULL) {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- vectorized_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file(temp_cache_dir, FALSE, ext = cache_ext)
  expect_cache_file_info(temp_cache_dir, FALSE, ext = cache_ext)

  for (i in 1:3) {
    res <- cached_read(
      IRIS_PATHS_BY_SPECIES,
      label = CACHE_LABEL,
      read_fn = read_csv_with_expectation(expected = i == 1),
      cache = temp_cache_dir,
      skip_file_info = TRUE,
      type = type,
    )

    if ("file_path" %in% names(res)) {
      res$file_path <- NULL
    }

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
  skip_if_not_installed("arrow")

  expect_skip_file_info_works("cache_parquet", type = "parquet")
})

test_that("cached_read with skip_file_info and type='csv' works correctly", {
  suppressMessages(
    expect_skip_file_info_works("cache_csv", type = "csv")
  )
})


test_that("cached_read with file_info check forces if files are modified", {
  temp_cache_dir <- create_temp_cache_dir()

  iris_complete <- vectorized_read_csv(IRIS_COMPLETE_PATH)

  expect_cache_file(temp_cache_dir, FALSE)
  for (i in 1:3) {
    expect_equal_dfs(
      iris_complete,
      cached_read(
        IRIS_PATHS_BY_SPECIES,
        label = CACHE_LABEL,
        read_fn = read_csv_with_expectation(expected = TRUE),
        cache = temp_cache_dir
      )
    )

    # Update file last modified time to force new reading.
    fs_file_touch_(IRIS_PATHS_BY_SPECIES)

    expect_cache_file(temp_cache_dir, TRUE)
  }
})
