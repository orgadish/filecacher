#' Cache via a file
#'
#' @description
#' If the cache exists, the object is retrieved from the cache.
#' Otherwise, it is evaluated and stored for subsequent retrieval.
#'
#' Use `force=TRUE` to ensure the object is evaluated and stored
#' anew in the cache.
#'
#' The object evaluated must be compatible with the cache type.
#' For example, a cache type of 'csv' or 'parquet' requires a
#' `data.frame` or similar type.
#'
#' @param x The object to store in the cache. Must be compatible
#'   with the cache type.
#' @param label A string to use as the name of the file to cache.
#' @param force If `TRUE`, forces evaluation even if the cache exists.
#' @inheritParams file_cache
#'
#' @return The value of `x`.
#' @export
with_cache <- function(x, label, cache = NULL, type = NULL, force = FALSE) {
  .cache <- file_cache(cache, type)
  vctrs::vec_assert(label, character(), size = 1)

  if (!force && .cache$exists(label)) {
    return(.cache$get(label))
  } else {
    out <- x # Call separately from $set to report errors correctly.
    tryCatch(
      .cache$set(label, out),
      error = \(e) {
        stop(glue::glue(
          "{e} Check if the cache type ('{type}') is compatible ",
          "with the data being stored."
        ))
      }
    )
    return(out)
  }
}
