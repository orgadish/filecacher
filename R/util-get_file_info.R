#' Get information from file.info that is expected to stay the same if the contents aren't modified.
#'
#' @param path A character vector of one or more paths.
#'
#' @description For example, excludes access_time, which changes even if the contents are the same.
#'
get_file_info <- function(path) {
  all_file_info <- file.info(path, extra_cols = FALSE)
  all_file_info$path <- path

  # Only keep headings from file.info expected to stay the same if the contents aren't modified.
  # For example, last access time (atime) should be ignored, but modified time (mtime) should be kept.
  cols_to_keep <- c("path", "isdir", "size", "mtime")
  subset_file_info <- all_file_info[, cols_to_keep]

  # Convert all columns to character to avoid issue with time zone parsing.
  for(colname in cols_to_keep) {
    subset_file_info[[colname]] <- as.character(subset_file_info[[colname]])
  }

  return(subset_file_info)
}
