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

  # Replacement for `base::deparse1`, which is only available in R >= 4.0.0.
  deparse_1 <- function(z) paste(deparse(z), collapse = " ")

  deparse_1(x) == deparse_1(y)
}
