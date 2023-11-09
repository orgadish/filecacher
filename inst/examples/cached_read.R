# Create a temporary directory for the cache.
tf <- tempfile()
dir.create(tf)

# A function that logs when it's called.
read_csv_log <- function(files) {
  message("Reading from file ...")
  return(vectorize_reader(read.csv)(files, stringsAsFactors = TRUE))
}

# `iris` data frame separated into multiple subset files.
iris_files <- system.file("extdata", package = "filecacher") |>
  list.files(pattern = "_only[.]csv$", full.names = TRUE)

# 1) First time, the message is shown.
iris_files |>
  cached_read("mtcars", read_csv_log, cache = tf) |>
  all.equal(iris)

# 2) Second time, no message is shown since the data is pulled from cache.
iris_files |>
  cached_read("mtcars", read_csv_log, cache = tf) |>
  all.equal(iris)

# 3) If desired, reloading can be forced using `force = TRUE`.
iris_files |>
  cached_read("mtcars", read_csv_log, cache = tf, force = TRUE) |>
  all.equal(iris)


unlink(tf, recursive = TRUE)
