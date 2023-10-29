test_that("fns_equal works", {
  expect_true(fns_equal(read.csv, read.csv))
  expect_false(fns_equal(read.csv, write.csv))

  # Error on non-function
  expect_error(fns_equal(read.csv, 3))
})
