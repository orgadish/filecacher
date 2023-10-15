#' Generate cache parameters from pre-existing shorthand types.
#'
#' @param type A string describing the type of cache.
#' Must be NULL or one of 'rds', 'parquet', or 'csv'.
#' If NULL (default), uses 'rds'.
#' @param ext_prefix Whether to add "cache_" before the file extension.
#'
#' @return List of read_fn, write_fn, and extension for use with `cachem::cache_disk`.
interpret_cache_type <- function(type, ext_prefix = TRUE) {
  assertthat::assert_that(is.null(type) || assertthat::is.string(type))
  if (is.null(type)) type <- "rds"

  build_ext <- function(ext) paste0(".", if (!ext_prefix) ext else paste0("cache_", ext))

  types <- list(
    "rds" = list(
      read_fn = NULL,
      write_fn = NULL,
      extension = build_ext("rds")
    ),
    "parquet" = list(
      read_fn = arrow::read_parquet,
      write_fn = arrow::write_parquet,
      extension = build_ext("parquet")
    ),
    "csv" = list(
      read_fn = readr::read_csv,
      write_fn = readr::write_csv,
      extension = build_ext("csv")
    )
  )

  if (!type %in% names(types)) {
    valid_types <- glue::glue("'{names(types)}'") |>
      paste(collapse = ", ")
    stop(glue::glue("`type` must be NULL or one of {valid_types}, not '{type}'."))
  }

  types[[type]]
}

#' Gets or creates a cachem object for use with other functions.
#'
#' @param cache An existing cachem object or a path to an existing directory to use for caching.
#' @inheritParams interpret_cache_type
#'
#' @return Either the `cachem` object provided, or a new `cachem::cache_disk()` object.
#' @export
file_cache <- function(cache = NULL, type = NULL, ext_prefix = TRUE) {
  if (is.null(cache)) cache <- here::here()

  cache_class <- class(cache)
  if ("cachem" %in% cache_class) {
    if (cache_class[1] != "cache_disk") {
      warning(glue::glue(
        "Expected a cache of type 'cache_disk', but found '{cache_class[1]}' instead. Proceeding with this cache."
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

  stop("`cache` must be an existing cache or the path to an existing directory.")
}
