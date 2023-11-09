# Convert iris$Species to character to simplify comparison.
iris_chr <- iris
iris_chr$Species <- as.character(iris$Species)


# `iris` data frame separated into multiple subset files.
iris_files <- system.file("extdata", package = "filecacher") |>
  list.files(pattern = "_only[.]csv$", full.names = TRUE)

try(read.csv(iris_files))
vectorize_reader(read.csv)(
  iris_files,
  stringsAsFactors = TRUE
) |>
  all.equal(iris)

try(arrow::read_csv_arrow(iris_files))
vectorize_reader(arrow::read_csv_arrow)(
  iris_files
) |>
  as.data.frame() |>
  all.equal(iris_chr)



try(data.table::fread(iris_files))
vectorize_reader(data.table::fread)(
  iris_files,
  stringsAsFactors = TRUE
) |>
  as.data.frame() |>
  all.equal(iris)

