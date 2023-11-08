# Create a temporary directory with "mtcars.csv".
tf <- tempfile()
dir.create(tf)
mtcars_fp <- file.path(tf, "mtcars.csv")
mtcars_wo_rownames <- `rownames<-`(mtcars, NULL)  # Ignore rownames.
write.csv(mtcars_wo_rownames, mtcars_fp, row.names=FALSE)


# A function that logs when it's called.
read_csv_log <- function(fp) {
  message("Reading from file ...")
  return(vectorize_reader(read.csv)(fp))
}

# 1) First time, message is printed
mtcars_fp |>
  cached_read("mtcars", read_csv_log, cache = tf) |>
  all.equal(mtcars_wo_rownames)

# 2) Second time, no message is printed as data is pulled from cache.
mtcars_fp |>
  cached_read("mtcars", read_csv_log, cache = tf) |>
  all.equal(mtcars_wo_rownames)

# 3) If desired, reloading can be forced using `force = TRUE`.
mtcars_fp |>
  cached_read("mtcars", read_csv_log, cache = tf, force = TRUE) |>
  all.equal(mtcars_wo_rownames)


unlink(tf)
