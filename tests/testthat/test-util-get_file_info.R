test_that("get_file_info works", {
  iris_complete_path <- fs::path_package("extdata", package = "filecacher") |>
    fs::path("iris_complete.csv") |>
    as.character()

  iris_complete_info <- get_file_info(iris_complete_path)

  expect_equal(
    iris_complete_info$path, iris_complete_path
  )
  expect_equal(
    iris_complete_info$size,
    as.character(as.numeric(fs::file_size(iris_complete_path)))
  )
  expect_equal(
    iris_complete_info$mtime,
    as.character(fs::file_info(iris_complete_path)$modification_time)
  )
})
