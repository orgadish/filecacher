test_that("file_cache with cache=NULL", {
  # Skip this test on CRAN since it involves editing the local file system.
  skip_on_cran()

  expected_default_cache_dir <- here::here("cache")

  # If the default directory already exists, skip this test to leave the
  # directory untouched.
  skip_if(dir.exists(expected_default_cache_dir))

  # Ensure the directory is deleted at the end.
  withr::defer(
    unlink(expected_default_cache_dir, recursive = TRUE),
    teardown_env()
  )

  .cache <- file_cache()
  expect_equal(
    normalizePath(.cache$info()$dir),
    normalizePath(expected_default_cache_dir)
  )

  # Ensure the directory was created
  expect_true(dir.exists(expected_default_cache_dir))
})

test_that("file_cache with type=NULL", {
  tf <- withr::local_tempfile()
  dir.create(tf)
  cache <- file_cache(tf)

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs_is_file_(file.path(tf, "test.cache_rds")))
})

test_that("file_cache with type=rds", {
  tf <- withr::local_tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "rds")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs_is_file_(file.path(tf, "test.cache_rds")))
})

test_that("file_cache with type=parquet", {
  skip_if_not_installed("arrow")

  tf <- withr::local_tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "parquet")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs_is_file_(file.path(tf, "test.cache_parquet")))
})

test_that("file_cache with type=csv, ext_prefix=NULL", {
  tf <- withr::local_tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "csv", ext_prefix = "")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs_is_file_(file.path(tf, "test.csv")))
})

test_that("file_cache passes existing cache object", {
  cd <- cachem::cache_disk()
  expect_identical(file_cache(cd), cd)

  cm <- cachem::cache_mem()
  expect_identical(file_cache(cm), cm)
})
