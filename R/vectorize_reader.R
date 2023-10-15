#' Vectorize a single-input read function to read multiple files
#'
#' @description
#' The resulting vectorized read function still takes all the arguments of the
#' original function.
#'
#' Uses `purrr::list_rbind()` to bind the data frames. Unlike `base::rbind()`,
#' `purrr::list_rbind()` generates a data frame with a supserset of the columns
#' from all the files, filling `NA` where data was not present.
#'
#'
#' @param read_fn The read function to vectorize. The first argument must be the files to read.
#' @param file_path A string, which if provided, is the name of the column containing
#'   containing the file paths in the result.
#'
#' @seealso [purrr::list_rbind()]
#'
#' @return A version of `read_fn` that can read multiple paths.
#'
#' @export
#' @examples
#' \dontrun{
#'
#' paths <- list.files(DIR, full.names = TRUE, pattern = "[.]csv$")
#'
#' vectorize_reader(read.csv)(paths, sep = ";")
#'
#' vectorize_reader(arrow::read_csv_arrow)(paths, col_names = FALSE)
#'
#' vectorize_reader(data.table::fread)(paths)
#' }
vectorize_reader <- function(read_fn, file_path = NULL) {
  function(files, ...) {
    df_list <- lapply(stats::setNames(nm = files), read_fn, ...)
    if(is.null(file_path)) {
      return(purrr::list_rbind(df_list))
    } else {
      return(purrr::list_rbind(df_list, names_to = file_path))
    }
  }
}
