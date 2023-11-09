test_that("file_cache with cache=NULL", {
  expected_dir <- here::here("cache")
  dir_already_exists <- fs::dir_exists(expected_dir)

  .cache <- file_cache()
  expect_equal(
    fs::path_abs(.cache$info()$dir),
    fs::path_abs(expected_dir)
  )

  if (!dir_already_exists) {
    expect_true(fs::dir_exists(expected_dir))
    .cache$destroy()
  }
})

test_that("file_cache with type=NULL works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf)

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=rds works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "rds")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=parquet works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "parquet")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.cache_parquet")))

  unlink(tf, recursive = TRUE)
})

test_that("file_cache with type=csv, ext_prefix=NULL works", {
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
