# Download to a temporary sibling so failed attempts cannot expose partial data.
.download_file <- function(url, destfile, expected_bytes = NULL,
                           attempts = 3L, timeout = 180L,
                           .download = utils::download.file,
                           .sleep = Sys.sleep) {
  if (file.exists(destfile))
    stop("Download destination already exists: ", destfile, call. = FALSE)
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  old_timeout <- getOption("timeout")
  options(timeout = timeout)
  on.exit(options(timeout = old_timeout), add = TRUE)

  for (attempt in seq_len(attempts)) {
    tmp <- tempfile(tmpdir = dirname(destfile), fileext = ".download")
    warnings <- character()
    result <- tryCatch(
      withCallingHandlers(
        .download(url, tmp, mode = "wb", quiet = TRUE),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    bytes <- if (file.exists(tmp)) file.info(tmp)$size else NA_real_
    complete <- !inherits(result, "error") && identical(result, 0L) &&
      !is.na(bytes) && bytes > 0 &&
      (is.null(expected_bytes) || identical(as.numeric(bytes),
                                            as.numeric(expected_bytes)))
    if (complete) {
      if (!file.rename(tmp, destfile)) {
        unlink(tmp)
        stop("Could not save downloaded file: ", destfile, call. = FALSE)
      }
      return(invisible(destfile))
    }
    unlink(tmp)
    reason <- c(warnings,
                if (inherits(result, "error")) conditionMessage(result),
                if (!inherits(result, "error") && !identical(result, 0L))
                  paste0("download.file returned status ", result),
                if (is.na(bytes) || bytes == 0) "empty or missing download",
                if (!is.null(expected_bytes) && !is.na(bytes) &&
                    bytes > 0 && bytes != expected_bytes)
                  paste0("incomplete download: ", bytes, " of ",
                         expected_bytes, " bytes"))
    reason <- unique(reason)
    detail <- paste(reason, collapse = "; ")
    status <- regmatches(detail, regexpr("HTTP[^0-9]*4[0-9]{2}", detail,
                                      ignore.case = TRUE))
    permanent <- length(status) && nzchar(status) &&
      !grepl("(408|429)$", status)
    if (permanent || attempt == attempts)
      stop("Could not download ", url, " (attempt ", attempt, "/",
           attempts, "): ", detail, call. = FALSE)
    .sleep(attempt)
  }
}
