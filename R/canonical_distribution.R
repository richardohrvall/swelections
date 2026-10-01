# Published canonical coverage is an explicit policy, independent of age.
.canonical_release_registry <- function() {
  data.frame(
    year = 2018L, series = "rkl", data_version = "data-v0.1.0",
    schema_version = 2L, auto_eligible = TRUE,
    base_url = paste0("https://github.com/richardohrvall/swelections/",
                      "releases/download/data-v0.1.0"),
    stringsAsFactors = FALSE
  )
}

.canonical_release <- function(year) {
  entries <- .canonical_release_registry()
  match <- entries[entries$year == year, , drop = FALSE]
  if (nrow(match) != 1L) return(NULL)
  as.list(match[1L, , drop = FALSE])
}

.canonical_release_manifest <- function(release, missing_ok = FALSE) {
  cache <- getOption("swelections.canonical_cache_dir",
                     tools::R_user_dir("swelections", "cache"))
  path <- file.path(cache, release$data_version, "manifest.json")
  valid <- function(file) {
    if (!file.exists(file)) return(FALSE)
    manifest <- tryCatch(.canonical_manifest(file), error = function(e) NULL)
    !is.null(manifest) &&
      identical(manifest$data_version, release$data_version) &&
      identical(as.integer(manifest$schema_version), release$schema_version) &&
      identical(manifest$valserie, release$series) &&
      identical(as.integer(manifest$valar), release$year) &&
      identical(manifest$format, "parquet")
  }
  if (valid(path)) return(path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  url <- paste0(release$base_url, "/manifest.json")
  downloaded <- tryCatch({
    if (grepl("^file://", url)) {
      source_path <- utils::URLdecode(sub("^file://", "", url))
      if (.Platform$OS.type == "windows")
        source_path <- sub("^/([A-Za-z]:)", "\\1", source_path)
      file.copy(source_path, tmp, overwrite = TRUE)
    } else {
      .download_file(url, tmp)
      TRUE
    }
  }, error = function(e) e)
  if (inherits(downloaded, "error")) {
    if (missing_ok) return(NULL)
    stop(conditionMessage(downloaded), call. = FALSE)
  }
  if (!downloaded || !valid(tmp)) {
    if (missing_ok) return(NULL)
    stop("Published canonical manifest is unavailable or invalid: ", url,
         call. = FALSE)
  }
  if (!file.copy(tmp, path, overwrite = TRUE)) {
    stop("Could not cache canonical manifest.", call. = FALSE)
  }
  path
}

.canonical_raw_files_2018 <- function(surface, include_results = TRUE) {
  if (!surface %in% c("valresultat", "mandat", "kandidaturer",
                      "kandidater", "valda", "ersattare", "personroster"))
    stop("Unknown canonical auto surface: ", surface, call. = FALSE)
  if (surface == "kandidaturer" ||
      (surface == "kandidater" && !include_results)) {
    return("kandidater/kandidaturer.skv")
  }
  files <- c("valresultat/slutresultat.zip",
             "valresultat/deltagande_partier.skv")
  if (surface %in% c("kandidater", "valda", "ersattare", "personroster")) {
    files <- c(files, "kandidater/kandidaturer.skv")
  }
  files
}

.canonical_local_raw_available <- function(year, surface, data_dir,
                                            include_results = TRUE) {
  if (year != 2018L)
    stop("Define the local raw-file requirements before enabling canonical auto ",
         "for year ", year, ".", call. = FALSE)
  root <- val_data_dir(data_dir)
  if (is.null(root)) return(FALSE)
  files <- file.path(root, "2018",
                     .canonical_raw_files_2018(surface, include_results))
  all(file.exists(files) & !is.na(file.info(files)$size) &
        file.info(files)$size > 0)
}

.select_public_source <- function(source, year, surface, data_dir = NULL,
                                  update = FALSE, archive = FALSE,
                                  include_results = TRUE) {
  if (source != "auto" || update || archive) return(source)
  release <- .canonical_release(year)
  if (is.null(release) || !isTRUE(release$auto_eligible)) return("auto")
  if (.canonical_local_raw_available(year, surface, data_dir, include_results))
    return("local")
  if (!requireNamespace("nanoparquet", quietly = TRUE)) return("remote")
  if (!is.null(.canonical_release_manifest(release, missing_ok = TRUE))) {
    return("canonical_auto")
  }
  "remote"
}
