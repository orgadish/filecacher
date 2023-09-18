#' Read files via cache of file list and contents.
#'
#' @description
#' Reads data and save to a local "cache" file for easier management and re-reading.
#'
#' By default, also saves the file info to determine whether the cache is valid, or whether the contents need to be updated because the files have been modified.
#' To skip this, or force reading from scratch, use `with_cache`, `force_cache` directly,
#' or set `skip_file_info=TRUE` or `force=TRUE`, respectively.
#'
#' If updating is called for, all the files are re-read.
#'
#' `cached_read_csv` is a convenience function using `readr::read_csv` if `readr` is installed
#' (typically through the `tidyverse`), or `utils::read.csv` otherwise.
#'
#' @param files A file or files to read with `read_fn`
#' @param read_fn A function which takes file(s) as its first parameter and reads them.
#'   To use a single-input read function such as `arrow::read_csv_arrow` with multiple files,
#'  use `vectorize_reader`, e.g. `read_fn=vectorize_reader(arrow::read_csv_arrow)`.
#' @param ... Arguments to pass to `read_fn`.
#' @param skip_file_info Whether to skip saving and/or checking the file info.
#'  Use this when even querying the filesystem (without opening files) is slow.
#' @param force Whether to force reading the files and caching the results, even if the cache file exists.
#' @inheritParams with_cache
#'
#' @seealso [vectorize_reader()] to convert a single-input read function into a multiple-input function.
#'
#' @return The result of `read_fn(files, ...)`.
#' @export
cached_read <- function(files, label, read_fn, ..., cache=NULL, type=NULL,
                        skip_file_info=FALSE, force=FALSE) {
  .cache <- file_cache(cache=cache, type=type)

  # Option 1: If skipping file info, simply call `with_cache` or `force_cache`.
  if(skip_file_info){
    cache_fn <- if(force) force_cache else with_cache
    return(
      read_fn(files, ...) |>
        cache_fn(label=label, cache=.cache, type=type)
    )
  }

  # Option 2: Caching via file info.
  file_info_label = paste0(label, "-file_info")
  cached_file_info <- .cache$get(file_info_label)  # returns <key_missing> if doesn't exist.
  new_file_info <- get_file_info(files)

  if(dfs_equal(cached_file_info, new_file_info)) {
    cache_fn <- with_cache
  } else {
    .cache$set(file_info_label, new_file_info)
    cache_fn <- force_cache
  }

  read_fn(files, ...) |>
    cache_fn(label=label, cache=.cache, type=type)

}


#' @rdname cached_read
#'
#' @param read_type Type of csv read function to use. One of
#'   'readr' (`readr::read_csv`), 'data.table' (`data.table::fread`), 'arrow' (`arrow::read_csv_arrow`),
#'   or 'base' (`utils::read.csv`). If NULL (default), picks the first in that list whose package is installed.
#'
#'   Automatically vectorizes the single-input read functions (all other than `readr::read_csv`) using `vectorize_reader`.
#'
#' @export
cached_read_csv <- function(files, label, ..., read_type=NULL, cache=NULL, type=NULL,
                            skip_file_info=FALSE, force=FALSE) {

  assertthat::assert_that(is.null(read_type) || assertthat::is.string(read_type))

  read_fn_list <- list(
    "readr"=if(is_installed("readr")) readr::read_csv,
    "data.table"=if(is_installed("data.table")) vectorize_reader(data.table::fread),
    "arrow"=if(is_installed("arrow")) vectorize_reader(arrow::read_csv_arrow),
    "base"=vectorize_reader(utils::read.csv)
  )

  if(is.null(read_type)) {
    for(fn in read_fn_list) {
      if(!is.null(fn)) {
        read_fn <- fn
        break
      }
    }
  } else if(!read_type %in% names(read_fn_list)) {
    read_fn_names <-glue::glue("'{names(read_fn_list)}'") |>
      paste(collapse=", ")
    stop(glue::glue("`read_type` must be NULL or one of {read_fn_names}, not '{read_type}'."))
  } else {
    read_fn <- read_fn_list[[read_type]]
  }

  cached_read(
    files=files,
    label=label,
    read_fn=read_fn,
    ...,
    cache = cache,
    type = type,
    skip_file_info = skip_file_info,
    force = force
  )
}
