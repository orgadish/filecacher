#' Extract File Information to Indicate if Contents Are Modified.
#'
#' @description
#' Uses `file.info()` to get `size` and `mtime`.
#'
#' @param path A character vector of one or more paths.
#'
get_file_info <- function(path) {
  all_file_info <- file.info(path, extra_cols = FALSE)
  all_file_info$path <- path

  # Only keep headings from `file.info()` that are expected to stay the same
  # if the contents aren't modified. For example, last access time (`atime`)
  # should be ignored, but modified time (`mtime`) should be kept.
  cols_to_keep <- c("path", "size", "mtime")
  subset_file_info <- all_file_info[, cols_to_keep]

  # Convert all columns to character to avoid issue with time zone parsing.
  for (colname in cols_to_keep) {
    subset_file_info[[colname]] <- as.character(subset_file_info[[colname]])
  }

  return(subset_file_info)
}
