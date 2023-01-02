
# Save the iris dataset as a single CSV and as CSVs per Species, for testing ----------------------------------------------------
interactive()
write_to_extdata <- function(tbl, label) {
  readr::write_csv(
    tbl,
    fs::path(
      fs::path_package("extdata", package="cachedread"),
      glue::glue("iris_{label}"), ext="csv"
    )
  )
}

iris |>
  write_to_extdata("complete")

dplyr::group_split(iris_tbl, Species) |>
  lapply(\(tbl) write_to_extdata(tbl, glue::glue("{unique(tbl$Species)}_only")))

