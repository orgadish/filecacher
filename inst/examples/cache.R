# Create a temporary directory for the cache.
tf <- tempfile()
dir.create(tf)

# A dummy function that logs when it's called.
get_df <- function() {
  message("Getting df ...")
  return(mtcars)
}

# Use the resulting object in `with_cache()`.
# 1) The first time, the message is printed.
# 2) The second time, the object is pulled from the cache, with no message.
all.equal(with_cache(get_df(), "df", cache = tf), mtcars)
all.equal(with_cache(get_df(), "df", cache = tf), mtcars)

# `with_cache` is designed to be compatible with piping.
get_df() |>
  with_cache("df", cache = tf) |>
  all.equal(mtcars)


# Advanced: If desired, the `cachem` object methods can be used directly.
cache <- file_cache(tf)
cache$get("df") |> # Get objects previously cached using `with_cache`.
  all.equal(mtcars)
cache$set("df2", mtcars) # Set objects using `$set`.
cache$get("df2") |>
  all.equal(mtcars)

unlink(tf, recursive = TRUE)
