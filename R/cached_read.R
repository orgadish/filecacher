#' Read data and save to a local "cache" file.
#'
#' @description
#' Read data and save to a local "cache" file for easier management and re-reading.
#'
#' If no cache file already exists, performs the desired read operation and writes the results to a cache file. Optionally, also saves a cache file containing the latest file update info.
#' If the cache file exists, it is read instead. By default it also tracks for file updating so that the file(s) are
#'  re-read from scratch if they have changed.
#'
#' The type of cache file used depends on the `cache_type` parameter and the packages installed.
#' We recommend installing the `arrow` package, which allows use writing and reading into an Arrow IPC format.
#'
#' @details
#'
#' ## `cached_read`
#'
#' This the most flexible version. By default (`check = "file_info"`), it checks whether
#' the original files have been modified (using `fs::file_info`) and therefore whether the results should be
#' re-read from the original files or from the cache file.
#'
#' When reading from a slow file system, even getting the file information can be slow; in this case, we
#' recommend `check = "exists"` to only check whether the cache exists.
#'
#' e.g.
#'
#'     cached_read(some_files, arrow::read_feather)
#'
#' to read from a set of arrow feather files.
#'
#'
#' ## `cached_read_csv`
#'
#' This is like `cached_read` but uses the first read csv function available between `arrow`,
#' `readr`, `data.table`, or base R `utils`.
#'
#' ## `use_caching`
#'
#' Unlike `cached_read`, this can be piped at the end of an existing data pipeline, making it easy
#' to integrate temporarily, if desired. However, because it does not have direct access to the file
#' list, it cannot use `check = "file_info"`.
#'
#' e.g.
#'
#'     readr::read_csv(some_files) |>
#'       janitor::clean_names() |>
#'       dplyr::summarize(...) |>
#'       use_caching()
#'
#' @param files A vector of path(s) to file(s). This will be passed as the first argument to `read_fn`.
#' @param read_fn A function that can read `files` into a data frame.
#' This can be one of three options:
#'
#'  1. Standard function object, e.g. `readr::read_csv`
#'
#'  2. An anonymous function that takes `files`, e.g.
#'      - `\(files) readr::read_csv(files, skip = 2) |> janitor::clean_names()`
#'
#'  To use multiple files with a function that only takes a single file, use `lapply` and `dplyr::bind_rows` or `purrr::map` and `purr::list_rbind`, e.g.
#'
#'      \(files) lapply(files, data.table::fread) |> dplyr::bind_rows()
#'      \(files) purrr::map(files, data.table::fread) |> purrr::list_rbind()
#'
#' @param cache_type The type of file to use for caching.
#' This can be one of two options:
#'
#'  1. One of the following strings:
#'      - "arrow" to use `arrow::<read|write>_feather`,
#'      - "data.table" to use `data.table::f<read|write>`,
#'      - "csv" to use the first available of `arrow::<read|write>_csv`, `readr`, `data.table`, or base R `utils`.
#'  2. NULL:
#'      - (Default) Uses "arrow" if installed, otherwise "csv".
#'      - Uses `write_cache_fn`, `read_cache_fn`, and `cache_ext` if provided.
#' @param label The label to give the cached file,
#'  e.g. generating a file with the path 'my_data.cache_arrow'.
#' @param cache_dir Path to the folder that will contain the cache file.
#'    If NULL (default), uses the common path among the inputs, as determined by `fs::path_common`.
#' @param check Determines when to re-read from the original sources. This can be one of the following options:
#'
#'   1. (default) "file_info": Stores file metadata and re-reads if there have been any changes.
#'
#'   2. "exists": Checks whether the cache file exists in the `cache_dir` with the indicated label.
#'
#'   3. "force": Does not do any checking and simply re-builds the cache file.
#' @param write_cache_fn,read_cache_fn Functions used to write and read the cache file. To use this option,
#'  `cache_type` must be NULL, both functions must be provided, and `cache_ext` cannot be null..
#' @param cache_ext The extension to use on the cache file if `write_cache_fn` and `read_cache_fn` are provided.
#'
#' @return A `tibble`. Results are coerced to a tibble regardless of read_fn or cache_type to ensure uniformity and predictability of output type.
#' @export
#'
#' @examples
#' \dontrun{
#'
#'
#' # Standard read method
#' res <- some_files |>
#'   readr::read_csv() |>
#'   janitor::clean_names()
#'
#' # With caching there's now a single file that can be re-read more quickly in the future.
#' res <- some_files |>
#'   cached_read(
#'     \(file) readr::read_csv(file)
#'       |> janitor::clean_names()
#'   )
#'
#' res <- some_files |>
#'   readr::read_csv() |>
#'   janitor::clean_names() |>
#'   use_caching()
#'
#' }
cached_read <- function(files,
                        read_fn,
                        label,
                        cache_type = NULL,
                        cache_dir = NULL,
                        check = "file_info",
                        write_cache_fn = NULL,
                        read_cache_fn = NULL,
                        cache_ext = NULL
                        ) {
  # `cache_dir` argument
  if (is.null(cache_dir)) {
    cache_dir <- fs::path_common(files)
  }

  # `check` argument
  validate_check_arg(check)

  # `cache_type`, `_cache_fn` arguments
  cache_type_list <- get_cache_type_list(cache_type = cache_type, write_cache_fn = write_cache_fn, read_cache_fn = read_cache_fn, cache_ext = cache_ext)
  write_cache_fn <- cache_type_list$write
  read_cache_fn <- cache_type_list$read
  cache_file_ext <- cache_type_list$ext

  cache_file_path <- fs::path(cache_dir, label, ext = cache_file_ext)
  file_info_path <- fs::path(cache_dir, label, ext = paste0(cache_file_ext, "_info"))

  # If using `check='exists'`:
  if(check == "exists" && fs::file_exists(cache_file_path)) {
    out <- read_cache_fn(cache_file_path)

    # Coerce to tibble and return.
    return(tibble::as_tibble(out))
  }

  # If using `check='file_info'`:
  else if(check == "file_info" && fs::file_exists(cache_file_path) && fs::file_exists(file_info_path)) {
    expected_file_info <- get_file_info(files)
    previous_file_info <- read_cache_fn(file_info_path)
    if(dfs_equal(previous_file_info, expected_file_info)) {
      out <- read_cache_fn(cache_file_path)

      # Coerce to tibble and return.
      return(tibble::as_tibble(out))
    }
  }

  # In all other cases, force read from scratch.

  # Perform the original read, and store the result in a cache file.
  out <- read_fn(files)
  write_cache_fn(out, cache_file_path)

  # If `check='file_info'`, also save the file_info.
  if(check == "file_info") {
    files_info <- get_file_info(files)
    write_cache_fn(files_info, file_info_path)
  }

  # Coerce to tibble and return.
  return(tibble::as_tibble(out))

}


#' @rdname cached_read
#'
#' @param expr Expression that generates a tibble, typically reading from files.
#'
#' @export
use_caching <- function(expr,
                        label,
                        cache_type = NULL,
                        cache_dir = NULL,
                        check = "exists",
                        write_cache_fn = NULL,
                        read_cache_fn = NULL,
                        cache_ext = NULL
                        ) {
  # `cache_dir` argument
  if(is.null(cache_dir)) stop("`use_caching` cannot have `cache_dir=NULL`.")

  # `check` argument
  validate_check_arg(check)
  if(check == "file_info") stop("`use_caching` can only be used with check='exists' or 'force'.")

  # `cache_type`, `_cache_fn` arguments
  cache_type_list <- get_cache_type_list(cache_type = cache_type, write_cache_fn = write_cache_fn, read_cache_fn = read_cache_fn, cache_ext = cache_ext)
  write_cache_fn <- cache_type_list$write
  read_cache_fn <- cache_type_list$read
  cache_file_ext <- cache_type_list$ext

  # Path to cache file.
  cache_file_path <- fs::path(cache_dir, label, ext = cache_file_ext)

  # If using `check='exists'`:
  if(check == "exists" && fs::file_exists(cache_file_path)) {
    out <- read_cache_fn(cache_file_path)

    # Coerce to tibble and return.
    return(tibble::as_tibble(out))
  }

  # In all other cases, force read from scratch.

  # Perform the original read, and store the result in a cache file.
  out <- expr
  write_cache_fn(out, cache_file_path)

  # Coerce to tibble and return.
  return(tibble::as_tibble(out))

}


# File Info Helpers -------------------------------------------------------

#' Get information from fs::file_info that is expected to stay the same if the contents aren't modified.
#'
#' @description For example, excludes access_time, which changes even if the contents are the same.
#'
#' @inheritParams fs::file_info
get_file_info <- function(path) {
  fs::file_info(path, follow=TRUE) |>

    # Only keep headings from file_info expected to stay the same if the contents aren't modified.
    dplyr::select("path", "type", "size", "modification_time", "birth_time") |>

    # Convert all columns to character to avoid issue with time zone parsing.
    dplyr::mutate(
      dplyr::across(dplyr::everything(), as.character)
    )
}

#' Compare two dfs (ignoring row order) and ensure they are equal.
#'
#' @description
#' Similar to dplyr::all_equal(x, y, ignore_row_order=TRUE) which is now deprecated.
#'
#' @inheritParams base::all.equal
dfs_equal <- function(target, current) {
  sort_df <- \(df) df |>
    tibble::as_tibble() |>
    dplyr::arrange(dplyr::across(dplyr::everything()))

  isTRUE(all.equal(
    sort_df(target),
    sort_df(current),
    check.attributes = FALSE  # Both are tibbles.
  ))
}


# Argument Parsing Helpers -----------------------------------------------------------------


#' Validates the `check` argument for `cached_read`.
#'
#' @inheritParams cached_read
validate_check_arg <- function(check) {
  if(length(check) > 1) stop("Multiple values were provided to `check`.")

  VALID_CHECK_VALUES <- c("file_info", "exists", "force")
  VALID_CHECK_NAMES <- glue::glue_collapse(glue::glue("'{VALID_CHECK_VALUES}'"), sep=", ", last=", or ")
  if(!check %in% VALID_CHECK_VALUES) {
    stop(glue::glue("`check` must be one of {VALID_CHECK_NAMES}: you provided '{check}'."))
  }
}

#' Validates the `cache_type` and `_cache_fn` arguments for `cached_read` and returns a list containing:
#'  `write`: The write function.
#'  `read`: The read function.
#'  `ext`: The extension to use for the cache file.
#'
#' @inheritParams cached_read
get_cache_type_list <- function(cache_type, write_cache_fn, read_cache_fn, cache_ext) {

  manual_params_exists <- sapply(list(write_cache_fn, read_cache_fn, cache_ext), Negate(is.null))
  any_manual_param_exists <- any(manual_params_exists)
  all_manual_params_exist <- any_manual_param_exists && all(manual_params_exists)

  cache_type_exists <- !is.null(cache_type)

  if(cache_type_exists) {
    if(!any_manual_param_exists) return(parse_cache_type(cache_type))
    else stop("Must provide either `cache_type` or the `_cache_fn` and `cache_ext` arguments, but not both.")
  }

  if(any_manual_param_exists && !all_manual_params_exist) stop("Must provide all of `write_cache_fn`, `read_cache_fn`, and `cache_ext` if not using `cache_type`.")

  if(all_manual_params_exist) {
    return(list(write=write_cache_fn, read=read_cache_fn, ext=cache_ext))
  }

  return(parse_cache_type(cache_type))
}


#' Parses the `cache_type` arguments for `cached_read` and returns a list containing:
#'  `write`: The write function.
#'  `read`: The read function.
#'  `ext`: The extension to use for the cache file.
#'
#' @inheritParams cached_read
parse_cache_type <- function(cache_type) {

  # Validate
  VALID_CACHE_TYPE_STR_VALUES <- c("arrow", "data.table", "csv")
  VALID_CACHE_TYPE_STR_NAMES <- glue::glue_collapse(glue::glue("'{VALID_CACHE_TYPE_STR_VALUES}'"), sep=", ")
  if(!is.null(cache_type) &&
     (length(cache_type) != 1 || !cache_type %in% VALID_CACHE_TYPE_STR_VALUES)
  ) {
    stop(glue::glue("`cache_type` must be {VALID_CACHE_TYPE_STR_NAMES}, or NULL."))
  }

  # Parse
  arrow_cache_list <- if(requireNamespace("arrow", quietly = TRUE)) list(write=arrow::write_feather, read=arrow::read_feather, ext="cache_arrow")
  arrow_csv_cache_list <- if(requireNamespace("arrow", quietly = TRUE)) list(write=arrow::write_csv_arrow, read=arrow::read_csv_arrow, ext="cache_csv")
  readr_csv_cache_list <- if(requireNamespace("readr", quietly = TRUE)) list(write=readr::write_csv, read=readr::read_csv, ext="cache_csv")
  datatable_csv_cache_list <- if(requireNamespace("data.table", quietly = TRUE)) list(write=data.table::fwrite, read=data.table::fread, ext="cache_csv")
  base_csv_cache_list <- list(write=utils::write.csv, read=utils::read.csv, ext="cache_csv")

  if(is.null(cache_type)) {
    # arrow -> readr -> utils
    resolution_order <- list(
      arrow=arrow_cache_list,
      readr=readr_csv_cache_list,
      data.table=datatable_csv_cache_list,
      utils=base_csv_cache_list
    )
    for(res_name in names(resolution_order)){
      cache_list <- resolution_order[[res_name]]
      if(!is.null(cache_list)) {
        return(cache_list)
      }
    }
  }

  else if(cache_type == "arrow") {
    if(is.null(arrow_cache_list)) stop("Cannot use `cache_type='arrow'` if the `arrow` package is not installed.")
    return(arrow_cache_list)
  }

  else if(cache_type == "data.table") {
    if(is.null(datatable_csv_cache_list)) stop("Cannot use `cache_type='data.table'` if the `data.table` package is not installed.")
    return(datatable_csv_cache_list)
  }

  else if(cache_type == "csv") {
    # arrow_csv -> readr -> data.table -> utils
    resolution_order <- list(
      arrow=arrow_csv_cache_list,
      readr=readr_csv_cache_list,
      data.table=datatable_csv_cache_list,
      utils=base_csv_cache_list
    )
    for(res_name in names(resolution_order)){
      cache_list <- resolution_order[[res_name]]
      if(!is.null(cache_list)) {
        return(cache_list)
      }
    }
  }

  stop(glue::glue("Failed to parse `cache_type` ('{cache_type}') correctly."))
}

