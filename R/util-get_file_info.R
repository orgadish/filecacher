#' Get information from fs::file_info that is expected to stay the same if the contents aren't modified.
#'
#' @description For example, excludes access_time, which changes even if the contents are the same.
#'
#' @inheritParams fs::file_info
get_file_info <- function(path) {
  all_file_info <- fs::file_info(path, follow=TRUE)

  # Only keep headings from file_info expected to stay the same if the contents aren't modified.
  cols_to_keep <- c("path", "type", "size", "modification_time", "birth_time")
  subset_file_info <- all_file_info[, cols_to_keep]

  # Convert all columns to character to avoid issue with time zone parsing.
  for(colname in cols_to_keep) {
    subset_file_info[[colname]] <- as.character(subset_file_info[[colname]])
  }

  return(subset_file_info)
}
