# This are simple re-implementations of fs functions to remove dependency on fs.

# See fs::dir_ls().
fs_dir_ls_ <- function(path = ".", glob = NULL, ...) {
  pattern <- if (!is.null(glob)) utils::glob2rx(glob)
  list.files(path, pattern = pattern, full.names = TRUE, ...)
}

# Changes a file access and modification time to the current time.
# See fs::file_touch().
fs_file_touch_ <- function(path) {
  if (!all(file.exists(path))) {
    stop("`fs_file_touch_` can only be used on existing paths.")
  }

  tf <- tempfile()
  dir.create(tf)

  temp_path <- file.path(tf, basename(path))
  file.copy(path, temp_path)
  file.copy(temp_path, path, overwrite = TRUE)

  unlink(tf, recursive = TRUE)
}

# See fs::is_file()
fs_is_file_ <- function(path) {
  !file.info(path)$isdir
}
