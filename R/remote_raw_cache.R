# Only downloaded raw bytes persist. The index snapshot is request-local.
.remote_raw_state <- new.env(parent = emptyenv())
.remote_raw_state$context <- NULL

.remote_raw_begin <- function() {
  if (is.environment(.remote_raw_state$context)) return(function() invisible(NULL))
  .remote_raw_state$context <- new.env(parent = emptyenv())
  function() { .remote_raw_state$context <- NULL; invisible(NULL) }
}

.remote_raw_url <- function(url) {
  match <- regexec(
    "^https://resultat[.]val[.]se/resultatfiler/([A-Za-z0-9_-]+)/([^?#]+)$", url)
  parts <- regmatches(url, match)[[1]]
  if (!length(parts)) return(NULL)
  path <- parts[[3]]
  if (grepl("(^|/)[.]{1,2}(/|$)|\\\\|^/", path))
    stop("Unsafe remote raw-file path.", call. = FALSE)
  list(base = paste0("https://resultat.val.se/resultatfiler/", parts[[2]]),
       collection = parts[[2]], path = path)
}

.remote_raw_index <- function(spec, download) {
  context <- .remote_raw_state$context
  if (is.environment(context) && exists(spec$base, context, inherits = FALSE))
    return(get(spec$base, context, inherits = FALSE))
  file <- tempfile(fileext = ".md5")
  on.exit(unlink(file), add = TRUE)
  download(paste0(spec$base, "/index.md5"), file)
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines) || any(!grepl("^[[:xdigit:]]{32}[[:blank:]]+[.]/.+$", lines)))
    stop("Cannot verify current remote index.md5: malformed or empty index.",
         call. = FALSE)
  index <- parse_index_2026(lines)
  if (nrow(index) != length(lines) || anyDuplicated(index$path) ||
      any(grepl("(^|/)[.]{1,2}(/|$)|\\\\|^/|[?#]", index$path)))
    stop("Cannot verify current remote index.md5: invalid file keys.", call. = FALSE)
  result <- list(index = index, bytes = readBin(file, "raw", n = file.info(file)$size))
  if (is.environment(context)) assign(spec$base, result, context)
  result
}

.remote_raw_valid <- function(file, md5, expected_bytes = NULL) {
  size <- file.info(file)$size
  isTRUE(!is.na(size) && size > 0 &&
    (is.null(expected_bytes) || size == expected_bytes) &&
    identical(tolower(unname(suppressWarnings(tools::md5sum(file)))), md5))
}

.remote_raw_download <- function(spec, destfile, expected_bytes, download) {
  if (file.exists(destfile))
    stop("Download destination already exists: ", destfile, call. = FALSE)
  current <- .remote_raw_index(spec, download)
  if (spec$path == "index.md5") {
    if (!is.null(expected_bytes) && length(current$bytes) != expected_bytes)
      stop("Current remote index size does not match expected bytes.", call. = FALSE)
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    writeBin(current$bytes, destfile)
    return(invisible(destfile))
  }
  row <- match(spec$path, current$index$path)
  if (is.na(row))
    stop("Remote file is not listed in the current index.md5: ", spec$path,
         call. = FALSE)
  md5 <- current$index$md5[[row]]
  root <- getOption("swelections.remote_cache_dir",
                    file.path(tools::R_user_dir("swelections", "cache"), "remote-raw"))
  .check_data_dir(root)
  # Content-addressed files need no mutable checksum sidecars or parsed cache.
  cached <- file.path(root, "v1", spec$collection, md5, basename(spec$path))
  if (!.remote_raw_valid(cached, md5, expected_bytes)) {
    dir.create(dirname(cached), recursive = TRUE, showWarnings = FALSE)
    tmp <- tempfile(tmpdir = dirname(cached), fileext = ".raw")
    on.exit(unlink(tmp), add = TRUE)
    download(paste0(spec$base, "/", spec$path), tmp, expected_bytes)
    if (!.remote_raw_valid(tmp, md5, expected_bytes))
      stop("Remote raw-file checksum does not match current index.md5: ",
           spec$path, ". Retry with a fresh index.", call. = FALSE)
    if (!.remote_raw_valid(cached, md5, expected_bytes)) {
      if (file.exists(cached)) unlink(cached)
      if (!file.rename(tmp, cached) &&
          !.remote_raw_valid(cached, md5, expected_bytes))
        stop("Could not publish verified remote raw-file cache entry.", call. = FALSE)
    }
  }
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(cached, destfile, overwrite = FALSE))
    stop("Could not read verified remote raw-file cache entry.", call. = FALSE)
  # Detect concurrent damage while copying as well as on cache lookup.
  if (!.remote_raw_valid(destfile, md5, expected_bytes)) {
    unlink(destfile)
    stop("Remote raw-file cache copy failed checksum verification.", call. = FALSE)
  }
  invisible(destfile)
}
