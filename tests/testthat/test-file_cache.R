test_that("file_cache with cache=NULL", {
  expected_dir <- fs::path_abs(here::here("cache"))
  dir_exists_before_test <- fs::dir_exists(expected_dir)

  .cache <- file_cache()
  expect_equal(
    fs::path_abs(.cache$info()$dir),
    expected_dir
  )

  expect_true(fs::dir_exists(expected_dir))

  if (!dir_exists_before_test) {
    .cache$destroy()
  }
})

test_that("file_cache with type=NULL", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf)

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=rds", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "rds")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=parquet", {
  skip_if_not_installed("arrow")

  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "parquet")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.cache_parquet")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=csv, ext_prefix=NULL", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "csv", ext_prefix = "")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.csv")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache passes existing cache object", {
  cd <- cachem::cache_disk()
  expect_identical(file_cache(cd), cd)

  cm <- cachem::cache_mem()
  expect_identical(file_cache(cm), cm)
})
