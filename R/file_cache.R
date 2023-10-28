#' Gets or creates a `cachem` object for use with other functions.
#'
#' @param cache An existing `cachem` object or a path to an existing directory
#'   to use for caching.
#' @inheritParams interpret_cache_type
#'
#' @return Either the `cachem` object provided, or a new [cachem::cache_disk()]
#'   object.
#' @export
#'
#' @seealso [cachem::cache_disk()]
file_cache <- function(cache = NULL, type = NULL, ext_prefix = TRUE) {
  if (is.null(cache)) cache <- here::here()

  cache_class <- class(cache)
  if ("cachem" %in% cache_class) {
    if (cache_class[1] != "cache_disk") {
      warning(glue::glue(
        "Expected a cache of type 'cache_disk', but found '{cache_class[1]}' ",
        "instead. Proceeding with this cache."
      ))
    }
    return(cache)
  }

  if (is.character(cache) && dir.exists(cache)) {
    cache_type <- interpret_cache_type(type, ext_prefix = ext_prefix)
    return(
      cachem::cache_disk(
        dir = cache,
        max_size = Inf,
        read_fn = cache_type$read_fn,
        write_fn = cache_type$write_fn,
        extension = cache_type$extension
      )
    )
  }

  stop(
    "`cache` must be an existing cache or the path to an existing directory."
  )
}
