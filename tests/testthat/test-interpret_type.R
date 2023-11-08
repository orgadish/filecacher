test_that("interpret_cache_type raises expected error", {
  expect_error(
    interpret_cache_type("wrong"),
    regexp = paste0(
      "`type` must be NULL or one of 'rds', 'parquet', or 'csv', ",
      "not 'wrong'."
    )
  )
})

test_that("interpret_cache_type NULL matches rds", {
  expect_equal(interpret_cache_type(NULL), interpret_cache_type("rds"))
})

test_that("interpret_cache_type extension works", {
  expect_equal(interpret_cache_type("rds")$extension, ".cache_rds")
  expect_equal(interpret_cache_type("parquet")$extension, ".cache_parquet")
  expect_equal(interpret_cache_type("csv")$extension, ".cache_csv")

  expect_equal(
    interpret_cache_type("rds", ext_prefix = NULL)$extension,
    ".rds"
  )
  expect_equal(
    interpret_cache_type("parquet", ext_prefix = "")$extension,
    ".parquet"
  )
  expect_equal(
    interpret_cache_type("csv", ext_prefix = character())$extension,
    ".csv"
  )
})

expect_fns_equal <- function(x, y) {
  expect_true(fns_equal(x, y))
}

test_that("interpret_cache_type read/write works", {
  expect_equal(interpret_cache_type("rds")$read, NULL)
  expect_equal(interpret_cache_type("rds")$write, NULL)
  expect_fns_equal(interpret_cache_type("parquet")$read, arrow::read_parquet)
  expect_fns_equal(interpret_cache_type("parquet")$write, arrow::write_parquet)
  expect_fns_equal(interpret_cache_type("csv")$read, get_csv_fns()$read)
  expect_fns_equal(interpret_cache_type("csv")$write, get_csv_fns()$write)
})
