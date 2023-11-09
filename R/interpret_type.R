#' Get the CSV read/write function
#'
#' @description
#' Read functions are vectorized.
#'
#' @param type Type of csv read/write functions to get.
#'   If `NULL`, returns the first installed.
#'
#' @return List of read/write functions.
get_csv_fns <- function(type = NULL) {
  if (!is.null(type)) vctrs::vec_assert(type, character(), size = 1)

  rw_fns <- list(
    "readr" = if (rlang::is_installed("readr")) {
      list(
        read = \(f) readr::read_csv(f, id = "file_path"),
        write = readr::write_csv
      )
    },
    "arrow" = if (rlang::is_installed("arrow")) {
      list(
        read = vectorize_reader(arrow::read_csv_arrow, "file_path"),
        write = arrow::write_csv_arrow
      )
    },
    "data.table" = if (rlang::is_installed("data.table")) {
      list(
        read = vectorize_reader(data.table::fread, "file_path"),
        write = data.table::fwrite
      )
    },
    "base" = list(
      read = vectorize_reader(utils::read.csv, "file_path"),
      write = utils::write.csv
    )
  )

  if (is.null(type)) {
    installed_fns <- rw_fns[!is.null(rw_fns)]
    fn_list <- installed_fns[[1]]
  } else if (type %in% names(rw_fns)) {
    fn_list <- rw_fns[[type]]
  } else {
    collapsed_names <- glue::glue_collapse(
      glue::glue("'{names(rw_fns)}'"),
      sep = ", ", last = ", or "
    )
    stop(glue::glue(
      "`type` must be NULL or one of {collapsed_names}, not '{type}'."
    ))
  }

  fn_list
}


#' Get the first CSV Read function installed
#'
#' @param read_type Type of csv read function to use. One of:
#'   * "readr": `readr::read_csv()`
#'   * "arrow": `vectorize_reader(arrow::read_csv_arrow)()`
#'   * "data.table": `vectorize_reader(data.table::fread)()`
#'   * "base": `vectorize_reader(utils::read.csv)()`
#'   * `NULL` (default): uses the first installed.
#'
#' @return Function that reads multiple paths to CSVs.
get_csv_read_fn <- function(read_type = NULL) {
  if (!is.null(read_type)) vctrs::vec_assert(read_type, character(), size = 1)

  get_csv_fns(read_type)$read
}


#' Generate cache parameters from preexisting shorthand types.
#'
#' @param type A string describing the type of cache.
#'   Must be `NULL` or one of 'rds', 'parquet', or 'csv'.
#'   If `NULL` (default), uses 'rds'.
#' @param ext_prefix The prefix to use with the file extension,
#'   e.g. "cache_csv", instead of "csv".
#'
#' @return List of `read_fn`, `write_fn`, and `extension` for use with
#'   [cachem::cache_disk()].
interpret_cache_type <- function(type, ext_prefix = "cache_") {
  if (is.null(type)) {
    type <- "rds"
  } else {
    vctrs::vec_assert(type, character(), size = 1)
  }

  arrow_is_installed <- rlang::is_installed("arrow")
  if (type == "parquet" && !arrow_is_installed) {
    stop("The `arrow` package must be installed to use `type='parquet'`.")
  }


  build_ext <- function(ext) {
    paste0(".", ext_prefix, ext)
  }

  csv_fn_list <- get_csv_fns()

  types <- list(
    "rds" = list(
      read_fn = NULL,
      write_fn = NULL,
      extension = build_ext("rds")
    ),
    "parquet" = if (arrow_is_installed) {
      list(
        read_fn = arrow::read_parquet,
        write_fn = arrow::write_parquet,
        extension = build_ext("parquet")
      )
    },
    "csv" = list(
      read_fn = csv_fn_list$read,
      write_fn = csv_fn_list$write,
      extension = build_ext("csv")
    )
  )

  if (!type %in% names(types)) {
    collapsed_names <- glue::glue_collapse(
      glue::glue("'{names(types)}'"),
      sep = ", ", last = ", or "
    )
    stop(glue::glue(
      "`type` must be NULL or one of {collapsed_names}, not '{type}'."
    ))
  }

  types[[type]]
}
