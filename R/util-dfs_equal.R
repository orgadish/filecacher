#' Compare two dfs (ignoring row order) and ensure they are equal.
#'
#' @description
#' Similar to dplyr::all_equal(x, y, ignore_row_order=TRUE) which is now deprecated.
#'
#' If either argument is not a data.frame it returns FALSE, rather than
#'
#' @inheritParams base::all.equal
dfs_equal <- function(target, current) {
  if(!is.data.frame(target) || !is.data.frame(current)) return(FALSE)

  sort_df <- function(df) df[do.call(order, df), , drop=F]

  setequal(
    sort_df(target),
    sort_df(current)
  )
}
