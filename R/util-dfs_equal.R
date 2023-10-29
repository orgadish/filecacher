#' Compare two data frames (ignoring row order) and ensure they are equal.
#'
#' @description
#' Similar to `dplyr::all_equal(x, y, ignore_row_order=TRUE)`,
#' which is now deprecated.
#'
#' If either argument is not a data.frame it returns `FALSE`,
#' rather than raise an error.
#'
#' @inheritParams base::all.equal
dfs_equal <- function(target, current) {
  if (!is.data.frame(target) || !is.data.frame(current)) {
    return(FALSE)
  }

  df_sort <- function(df) df[do.call(order, df), , drop = FALSE]

  target_df <- df_sort(target)
  current_df <- df_sort(current)

  target_names <- names(target_df)
  current_names <- names(current_df)

  (
    length(target_names) == length(current_names) &&
      all(target_names == current_names) &&
      setequal(target_df, current_df)
  )
}
