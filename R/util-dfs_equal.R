#' Compare two dfs (ignoring row order) and ensure they are equal.
#'
#' @description
#' Similar to `dplyr::all_equal(x, y, ignore_row_order=TRUE)`, which is now deprecated.
#'
#' If either argument is not a data.frame it returns FALSE, rather than
#'
#' @inheritParams base::all.equal
dfs_equal <- function(target, current) {
  if (!is.data.frame(target) || !is.data.frame(current)) {
    return(FALSE)
  }

  df_sort <- function(df) df[do.call(order, df), , drop = F]

  setequal(
    df_sort(target),
    df_sort(current)
  )
}
