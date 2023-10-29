test_that("file_cache with type=NULL works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf)

  # class = "cache_disk"
  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf)

})

test_that("file_cache with type=rds works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type="rds")

  # class = "cache_disk"
  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", 3)
  expect_true(fs::is_file(fs::path(tf, "test.cache_rds")))

  unlink(tf)

})

test_that("file_cache with type=parquet works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type="parquet")

  # class = "cache_disk"
  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.cache_parquet")))

  unlink(tf)

})

test_that("file_cache with type=csv, ext_prefix=FALSE works", {
  tf <- tempfile()
  dir.create(tf)
  cache <- file_cache(tf, type = "csv", ext_prefix = FALSE)

  # class = "cache_disk"
  expect_true(inherits(cache, "cache_disk"))

  cache$set("test", data.frame(x = 1:3))
  expect_true(fs::is_file(fs::path(tf, "test.csv")))

  unlink(tf)
})

test_that("file_cache warns if not cache_disk", {
  expect_warning(file_cache(cache = cachem::cache_mem()))
})
