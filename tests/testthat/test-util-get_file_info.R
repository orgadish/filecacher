test_that("get_file_info works", {
  iris_complete_path <- system.file("extdata", package = "filecacher") |>
    file.path("iris_complete.csv") |>
    as.character()

  iris_complete_info <- get_file_info(iris_complete_path)

  expect_equal(
    iris_complete_info$path, iris_complete_path
  )
  expect_equal(
    iris_complete_info$size,
    as.character(file.info(iris_complete_path)$size)
  )

  # Only check `mtime` up to milliseconds:
  #   xxxx-xx-xx xx:xx:xx.xxx
  expect_equal(
    iris_complete_info$mtime |>
      substr(1, 23),
    file.info(iris_complete_path)$mtime |>
      as.character() |>
      substr(1, 23)
  )
})
