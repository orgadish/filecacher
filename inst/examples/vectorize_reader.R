# Create multiple temporary paths to read.
tf <- tempfile()
dir.create(tf)

write.csv(mtcars, file.path(tf, "mtcars1.csv"))
write.csv(mtcars, file.path(tf, "mtcars2.csv"))
multiple_paths <- list.files(tf, full.names = TRUE)

try(read.csv(multiple_paths))
vectorize_reader(read.csv)(
  multiple_paths, header = FALSE
) |> dim()

try(arrow::read_csv_arrow(multiple_paths))
vectorize_reader(arrow::read_csv_arrow)(
  multiple_paths, col_names = FALSE
) |> dim()

try(data.table::fread(multiple_paths))
vectorize_reader(data.table::fread)(
  multiple_paths, header = FALSE
) |> dim()

unlink(tf)
