test_that("file_cache with type=NULL works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf)

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf)
})

test_that("file_cache with type=rds works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "rds")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf)
})

test_that("file_cache with type=parquet works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "parquet")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.cache_parquet")))

  unlink(tf)
})

test_that("file_cache with type=csv, ext_prefix=NULL works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "csv", ext_prefix = "")

  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.csv")))

  unlink(tf)
})

test_that("file_cache with cache_mem does not error", {
  expect_no_error({
    mem_cache <- file_cache(cache = cachem::cache_mem())
  })
  expect_true(inherits(mem_cache, "cache_mem"))
})
