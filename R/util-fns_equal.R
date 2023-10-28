#' Check whether two function objects have the same text definition.
#'
#' @param x First function to compare.
#' @param y Second function to compare.
#'
#' @return Logical
fns_equal <- function(x, y) {
  if (!rlang::is_function(x) || !rlang::is_function(y)) {
    stop("`x` and `y` must be functions.")
  }

  deparse(x, nlines = 1) == deparse(y, nlines = 1)
}
