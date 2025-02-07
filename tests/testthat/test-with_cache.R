test_that("with_cache works", {
  tf <- withr::local_tempfile()
  dir.create(tf)
  cache <- cachem::cache_disk(tf)

  run_with_cache <- function(force = FALSE) {
    with_cache(
      x = "TEST",
      label = "test",
      cache = cache,
      force = force
    )
  }

  run_with_cache()
  expect_equal(cache$get("test"), "TEST")

  cache$set("test", "CHANGED")
  expect_equal(cache$get("test"), "CHANGED")
  expect_equal(run_with_cache(), "CHANGED")
  expect_equal(run_with_cache(force = TRUE), "TEST")
})

test_that("with_cache returns output when caching fails", {
  tf <- withr::local_tempfile()
  dir.create(tf)

  # An object that cannot be saved as CSV
  obj <- list(list(list(x=3), y=2), z=1)

  expect_warning(obj2 <- with_cache(obj, "obj", cache=tf, type="csv"))

  expect_equal(obj, obj2)
})
