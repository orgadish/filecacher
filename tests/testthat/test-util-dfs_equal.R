test_that("dfs_equal works", {
  x <- data.frame(x = 1:3)
  x_reordered <- data.frame(x = 3:1)
  x_renamed <- data.frame(y = 1:3)
  x_subset <- data.frame(x = c(2, 2, 3))

  # Ignores row order
  expect_true(dfs_equal(x, x_reordered))

  # False with different name
  expect_false(dfs_equal(x, x_renamed))

  # False with different name
  expect_false(dfs_equal(x, subset))
})
