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

  # Only check `mtime` up to milliseconds:
  #   xxxx-xx-xx xx:xx:xx.xxx
  expect_equal(
    iris_complete_info$mtime |> substr(1, 23),
    as.character(fs::file_info(iris_complete_path)$modification_time) |>
      substr(1, 23)
  )
})
