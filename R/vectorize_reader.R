#' Vectorize a single-input read function to read multiple files
#'
#' @description
#'
#' The resulting vectorized read function still takes all the arguments of the
#' original function.
#'
#' Uses [purrr::list_rbind()] to bind the data frames, which generates
#' a data frame with a superset of the columns from all the files,
#' filling `NA` where data was not present.
#'
#' @param read_fn The read function to vectorize. The first argument must be the
#'   files to read.
#' @param file_path_to A string, which if provided, is the name of the column
#'   containing the file paths in the result. See 'names_to' in
#'   [purrr::list_rbind()].
#'
#' @seealso [purrr::list_rbind()]
#'
#' @return A version of `read_fn` that can read multiple paths.
#'
#' @export
#' @example inst/examples/vectorize_reader.R
vectorize_reader <- function(read_fn, file_path_to = NULL) {
  function(files, ...) {
    df_list <- purrr::map(rlang::set_names(files), read_fn, ...)

    if (is.null(file_path_to)) file_path_to <- rlang::zap()
    purrr::list_rbind(df_list, names_to = file_path_to)
  }
}
