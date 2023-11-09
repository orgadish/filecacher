#' Gets or creates a `cachem` object for use with other functions.
#'
#' @param cache The path to an existing directory to use for caching.
#'
#'   If `NULL` (default) uses a folder called "cache" in the current
#'   path, using [here::here()]. The folder is created if it does not
#'   already exist.
#'
#'   **Advanced:** if an existing `cachem` object is provided, all other
#'   parameters are ignored and the object is passed on as is. This
#'   functionality is primarily used internally or for testing.
#' @inheritParams interpret_cache_type
#'
#' @return A [cachem::cache_disk()] object.
#' @export
#'
#' @seealso [cachem::cache_disk()]
#'
#' @example inst/examples/cache.R
file_cache <- function(cache = NULL, type = NULL, ext_prefix = "cache_") {
  if (inherits(cache, "cachem")) {
    return(cache)
  }

  if (is.null(cache)) {
    cache <- here::here("cache")
    if (!dir.exists(cache)) dir.create(cache)
  } else if (!is.character(cache) || !dir.exists(cache)) {
    stop(
      "`cache` must be an existing cache or the path to an existing directory."
    )
  }

  cache_type <- interpret_cache_type(type, ext_prefix = ext_prefix)
  cachem::cache_disk(
    dir = cache,
    max_size = Inf,
    read_fn = cache_type$read_fn,
    write_fn = cache_type$write_fn,
    extension = cache_type$extension
  )
}
