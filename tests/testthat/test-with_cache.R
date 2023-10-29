test_that("with_cache works", {
  tf <- tempfile()
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

  unlink(tf)
})
