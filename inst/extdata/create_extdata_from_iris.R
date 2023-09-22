### ---- THIS FILE WAS USED TO CREATE THE EXAMPLE DATA IN THE EXTDATA FOLDER ---- ###
### It should not need re-running.

# Save the iris dataset as a single CSV and as CSVs per Species, for testing ----------------------------------------------------
write_to_extdata <- function(tbl, label) {
  extdata_folder_path <- fs::path_package("extdata", package="filecacher")
  file_path <- fs::path(paste0("iris_", label), ext="csv")

  readr::write_csv(tbl, file_path)
}

create_example_data <- function() {
  # Create a single file containing the complete data set.
  write_to_extdata(iris, "complete")

  write_subset_to_extdata <- function(subset_data) {
    species_name <- unique(subset_data$Species)
    label <- paste0(species_name, "_only")
    write_to_extdata(subset_data, label)
  }

  # Create individual files for each subset.
  dplyr::group_split(iris, Species) |>
    lapply(write_subset_to_extdata)
}

create_example_data()

