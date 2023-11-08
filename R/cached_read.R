#' Read files via cache of file list and contents
#'
#' @description
#' Reads data and save to a local file for easier management and re-reading.
#'
#' By default, also saves the file info to determine whether the cache
#' is valid, or whether the contents need to be updated because the files
#' have been modified. To skip this, or force reading from scratch, set
#' `skip_file_info=TRUE` or `force=TRUE`, respectively.
#'
#' If updating is called for, all the files are re-read.
#'
#' `cached_read_csv()` is a convenience function using a csv read function
#'   based on `read_type`.
#'
#' @param files A file or files to read with `read_fn`.
#' @param read_fn A function which takes file(s) as its first parameter and
#'   reads them. To use a single-input read function such as
#'   `arrow::read_csv_arrow()` with multiple files, use [vectorize_reader()],
#'   e.g. `read_fn = vectorize_reader(arrow::read_csv_arrow)`.
#' @param skip_file_info Whether to skip saving and/or checking the file info.
#'  Use this when just querying the file system (without opening files) is slow.
#' @inheritParams with_cache
#'
#' @seealso [vectorize_reader()] to convert a single-input read function into a
#'   multiple-input function.
#'
#' @return The result of `read_fn(files)`.
#' @export
#' @example inst/examples/cached_read.R
cached_read <- function(files, label, read_fn,
                        cache = NULL, type = NULL, force = FALSE,
                        skip_file_info = FALSE) {
  .cache <- file_cache(cache = cache, type = type)

  read_with_cache <- function() {
    with_cache(
      read_fn(files),
      label = label, cache = .cache, type = type, force = force
    )
  }

  # Option 1: If skipping file info, simply call `with_cache`.
  if (skip_file_info) {
    return(read_with_cache())
  }

  # Option 2: Caching via file info.
  file_info_label <- paste0(label, "-file_info")
  cached_file_info <- .cache$get(file_info_label)
  # cached_file_info = <key_missing> if doesn't exist.
  new_file_info <- get_file_info(files)

  if (!dfs_equal(cached_file_info, new_file_info)) {
    .cache$set(file_info_label, new_file_info)
  }

  read_with_cache()
}


#' @rdname cached_read
#'
#' @inheritParams get_csv_read_fn
#'
#' @export
cached_read_csv <- function(files, label, read_type = NULL,
                            cache = NULL, type = NULL,
                            skip_file_info = FALSE, force = FALSE) {
  cached_read(
    files = files,
    label = label,
    read_fn = get_csv_read_fn(read_type),
    cache = cache,
    type = type,
    skip_file_info = skip_file_info,
    force = force
  )
}
