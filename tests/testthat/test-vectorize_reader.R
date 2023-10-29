test_that("vectorize_reader works", {
  extdata_directory <- fs::path_package("extdata", package = "filecacher")
  iris_complete_path <- fs::path(extdata_directory, "iris_complete.csv")
  iris_only_paths <- fs::dir_ls(extdata_directory, glob = "*only.csv")

  iris_complete <- read.csv(iris_complete_path)
  iris_from_subsets <- vectorize_reader(read.csv)(iris_only_paths)

  expect_equal(
    names(iris_complete),
    names(iris_from_subsets)
  )

  expect_setequal(
    unname(iris_complete),
    unname(iris_from_subsets)
  )
})
