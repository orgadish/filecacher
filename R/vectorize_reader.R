#' Vectorize a single-input read function to read multiple files at once.
#'
#' @description
#' Uses `dplyr::bind_rows` to bind the data frames, if installed. If not, uses `base::rbind`.
#' Note that these behave slightly differently:
#'   - `base::rbind` requires the data frames to have the same columns.
#'   - `dplyr::bind_rows` generates a data frame with all the columns, filling NA where data was not present.
#'
#'
#' @param read_fn The read function to vectorize.
#' @param bind_fn The function used to bind the results together.
#'  If NULL (default) uses `dplyr::bind_rows`, if installed, or `rbind`.
#' @param ... Arguments to `bind_fn`. For example, `dplyr::bind_rows` has a useful `.id` argument.
#'
#' @seealso [dplyr::bind_rows()]
#'
#' @return A single data.frame or data.frame-like object.
#'
#' @export
#' @examples
#' \dontrun{
#'
#' paths <- list.files(DIR, full.names=TRUE, pattern="[.]csv$")
#'
#' paths |>
#'   vectorize_reader(read.csv)()
#'
#' paths |>
#'   vectorize_reader(arrow::read_csv_arrow)()
#'
#' paths |>
#'   vectorize_reader(data.table::fread)()
#'
#' }
vectorize_reader <- function(read_fn, bind_fn=NULL, ...) {
  if(is.null(bind_fn)) {
    bind_fn <- if(is_installed("dplyr")) dplyr::bind_rows else \(x) do.call(rbind, x)
  }

  function(files, ...) {
    df_list <- lapply(files, read_fn, ...)
    return(bind_fn(df_list, ...))
  }
}
