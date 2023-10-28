# -- THIS FILE WAS USED TO CREATE THE EXAMPLE DATA IN THE EXTDATA FOLDER -- #
### It should not need re-running.

# Save the iris dataset as a single CSV and as CSVs per Species, for testing.
write_to_extdata <- function(tbl, label) {
  file_path <- fs::path(
    fs::path_package("extdata", package = "filecacher"),
    paste0("iris_", label),
    ext = "csv"
  )

  readr::write_csv(tbl, file_path)
}

#' Writes example data CSVs to extdata
#'
#' @importFrom rlang .data
create_example_data <- function() {
  # Create a single file containing the complete data set.
  write_to_extdata(iris, "complete")

  write_subset_to_extdata <- function(subset_data) {
    species_name <- unique(subset_data$Species)
    label <- paste0(species_name, "_only")
    write_to_extdata(subset_data, label)
  }

  # Create individual files for each subset.
  purrr::walk(
    dplyr::group_split(iris, .data$Species),
    write_subset_to_extdata
  )
}

create_example_data()
