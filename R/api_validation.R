.check_ar_2026 <- function(ar, funktion) {
  if (!is.numeric(ar) || is.logical(ar) || length(ar) != 1L ||
      is.na(ar) || !is.finite(ar) || ar != 2026) {
    stop("`", funktion, "()` st\u00f6der endast val\u00e5ret 2026.", call. = FALSE)
  }
  invisible(as.integer(ar))
}

.check_flag <- function(x, namn) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", namn, "` ska vara TRUE eller FALSE.", call. = FALSE)
  }
  invisible(x)
}

.check_text <- function(x, namn, flera = FALSE) {
  ok_langd <- if (flera) length(x) >= 1L else length(x) == 1L
  if (!is.character(x) || !ok_langd || anyNA(x) || any(!nzchar(x))) {
    suffix <- if (flera) "ett eller flera icke-tomma textv\u00e4rden" else "exakt ett icke-tomt textv\u00e4rde"
    stop("`", namn, "` ska vara ", suffix, ".", call. = FALSE)
  }
  invisible(x)
}

.check_data_dir <- function(data_dir) {
  if (!is.null(data_dir)) .check_text(data_dir, "data_dir")
  invisible(data_dir)
}

.check_public_args <- function(ar, funktion, source, data_dir, update, archive,
                               progress = NULL, valar_resolved = FALSE) {
  if (!valar_resolved) .check_ar_2026(ar, funktion)
  .check_data_dir(data_dir)
  .check_flag(update, "update")
  .check_flag(archive, "archive")
  if (!is.null(progress)) .check_flag(progress, "progress")
  source <- match.arg(source, c("auto", "local", "remote", "canonical"))
  if (identical(source, "canonical") &&
      (!is.null(data_dir) || update || archive)) {
    stop("`source = 'canonical'` uses canonical manifest/cache options; ",
         "do not combine it with `data_dir`, `update` or `archive`.",
         call. = FALSE)
  }
  .check_source_update(source, update)
  source
}

.check_canonical_years <- function(source, years) {
  if (identical(source, "canonical") && any(!years %in% c(2014L, 2018L, 2022L))) {
    stop("`source = 'canonical'` supports 2018 and configured 2014/2022 builds.", call. = FALSE)
  }
  invisible(years)
}
