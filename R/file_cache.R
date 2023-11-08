#' Gets or creates a `cachem` object for use with other functions.
#'
#' @param cache The path to an existing directory to use for caching.
#'   If `NULL` (default) uses the current path, using [here::here()].
#'
#'   For advanced use, also accepts (and passes on) an existing
#'   `cachem` object. If so, all other parameters are ignored.
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
    cache <- here::here()
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
