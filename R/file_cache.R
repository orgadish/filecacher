#' Generate cache parameters from pre-existing shorthand types.
#'
#' @param type A string describing the type of cache.
#' Must be NULL or one of 'rds', 'parquet', or 'csv'.
#' If NULL (default), uses 'rds'.
#'
#' @return List of read_fn, write_fn, and extension for use with `cachem::cache_disk`.
interpret_cache_type <- function(type) {
  assertthat::assert_that(is.null(type) || assertthat::is.string(type))
  if(is.null(type)) type <- "rds"

  types <- list(
    "rds" = list(
      read_fn=NULL,
      write_fn=NULL,
      extension = ".cache_rds"
    ),
    "parquet" = list(
      read_fn=arrow::read_parquet,
      write_fn=arrow::write_parquet,
      extension=".cache_parquet"
    ),
    "csv" = list(
      read_fn=readr::read_csv,
      write_fn=readr::write_csv,
      extension=".cache_csv"
    )
  )

  if(!type %in% names(types)) {
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
#' @return Either the cachem object provided, or a new `cachem::cache_disk` object.
#' @export
file_cache <- function(cache=NULL, type=NULL) {
  if(is.null(cache)) cache <- here::here()

  arg_class <- class(cache)
  if("cachem" %in% arg_class) {
    cache_arg_type <- class(cache)[1]
    if(cache_arg_type != "cache_disk") {
      warning(glue::glue(
        "Expected a cache of type 'cache_disk', but found '{cache_arg_type}' instead. Proceeding with this cache."
      ))
    }
    return(cache)
  }

  if(is.character(cache) && dir.exists(cache)) {
    cache_type <- interpret_cache_type(type)
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
