
# Save the iris dataset as a single CSV and as CSVs per Species, for testing ----------------------------------------------------
write_to_extdata <- function(tbl, label) {
  readr::write_csv(
    tbl,
    fs::path(
      fs::path_package("extdata", package="cachedread"),
      glue::glue("iris_{label}"), ext="csv"
    )
  )
}

create_example_data <- function() {
  iris |>
    write_to_extdata("complete")

  dplyr::group_split(iris, Species) |>
    lapply(\(tbl) write_to_extdata(tbl, glue::glue("{unique(tbl$Species)}_only")))
}

create_example_data()

