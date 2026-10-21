# Canonical coverage and reader support are registered once, separately from
# raw-source availability. Only the twelve reviewed ordinary products are registered.
.canonical_release_registry <- function() {
  years <- list(rkl = c(2002L, 2006L, 2010L, 2014L, 2018L, 2022L),
                eu = c(2004L, 2009L, 2014L, 2019L, 2024L), folkomr = 2003L)
  out <- purrr::list_rbind(lapply(names(years), function(series) {
    y <- years[[series]]
    data.frame(year = y, series = series, event_kind = "ordinary",
      data_version = "data-v0.4.0", schema_version = 3L,
      auto_eligible = TRUE,
      base_url = "https://github.com/richardohrvall/swelections/releases/download/data-v0.4.0",
      manifest_file = paste0(if (series == "folkomr") "referendum" else series, y, "-manifest.json"),
      cache_key = NA_character_,
      reader = if (series == "rkl") ".canonical_source" else if (series == "eu")
        paste0(".eu", y, "_canonical") else ".canonical_referendum2003",
      stringsAsFactors = FALSE)
  }))
  functions <- c("results", "seats", "candidacies", "candidates", "elected",
                 "substitutes", "preference_votes")
  # Permission is independent of manifest contents and the activation switch.
  out$auto_functions <- lapply(seq_len(nrow(out)), function(i) {
    if (out$series[i] == "folkomr") return("results")
    if (out$series[i] == "rkl" && out$year[i] == 2002L)
      return(setdiff(functions, "candidacies"))
    if (out$series[i] == "eu" && out$year[i] == 2009L)
      return(setdiff(functions, "preference_votes"))
    if (out$series[i] == "rkl" && out$year[i] %in% c(2014L, 2018L))
      return(c(functions, "mandate_history", "members_at", "vacant_seats_at"))
    functions
  })
  i <- out$series == "rkl" & out$year == 2018L
  out$data_version[i] <- "data-v0.4.0"
  out$cache_key[i] <- "data-v0.4.0"
  out$auto_eligible[i] <- TRUE
  out
}

.canonical_release <- function(year, series = "rkl", event_kind = "ordinary") {
  entries <- .canonical_release_registry()
  # Accept the original registry shape for existing internal callers/fixtures.
  if (!"event_kind" %in% names(entries)) entries$event_kind <- "ordinary"
  entry <- entries[entries$year == year & entries$series == series &
                     entries$event_kind == event_kind, , drop = FALSE]
  if (!nrow(entry)) return(NULL)
  if (nrow(entry) != 1L) stop("Ambiguous canonical coverage registration.", call. = FALSE)
  result <- as.list(entry[1L, , drop = FALSE])
  if ("auto_functions" %in% names(entry))
    result$auto_functions <- entry$auto_functions[[1L]]
  result
}

.canonical_configured_manifest <- function(year, series = "rkl",
                                            event_kind = "ordinary") {
  paths <- getOption("swelections.canonical_manifest", NULL)
  if (is.null(paths) || is.null(names(paths))) return(paths)
  keys <- c(paste(series, event_kind, year, sep = ":"),
            paste(series, year, sep = ":"), as.character(year))
  for (key in keys) if (key %in% names(paths)) return(unname(paths[[key]]))
  NULL
}

.canonical_manifest_path <- function(year, series = "rkl",
                                     event_kind = "ordinary", auto_selected = FALSE) {
  entry <- .canonical_release(year, series, event_kind)
  if (is.null(entry)) stop("No canonical reader registered for ", series, "/", year,
                           "/", event_kind, ".", call. = FALSE)
  path <- .canonical_configured_manifest(year, series, event_kind)
  if (!is.null(path)) {
    if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path))
      stop("Configure a valid canonical manifest for ", series, "/", year, ".", call. = FALSE)
    manifest <- .canonical_manifest(path)
    # A single configured manifest can belong to another requested family/year.
    if (auto_selected && is.null(names(getOption("swelections.canonical_manifest", NULL))) &&
        (manifest$valserie != series || as.integer(manifest$valar) != year))
      path <- NULL
  }
  if (is.null(path)) {
    if (is.null(entry$base_url) || is.na(entry$base_url) || !nzchar(entry$base_url))
      stop(series, " ", year, " canonical data require a configured local build manifest.", call. = FALSE)
    path <- .canonical_release_manifest(entry)
  }
  manifest <- .canonical_manifest(path)
  if (!identical(manifest$valserie, series) ||
      !identical(as.integer(manifest$valar), as.integer(year)) ||
      !identical(as.integer(manifest$schema_version), as.integer(entry$schema_version)) ||
      !identical(manifest$format, "parquet") ||
      (!is.null(manifest$event_kind) && manifest$event_kind != event_kind))
    stop("Canonical manifest does not match the requested election family/year/event/schema.", call. = FALSE)
  path
}

.canonical_surface <- function(surface) {
  map <- c(results = "valresultat", seats = "mandat", candidacies = "kandidaturer",
    candidates = "kandidater", elected = "valda", substitutes = "ersattare",
    preference_votes = "personroster", mandate_history = "mandathistorik",
    members_at = "ledamoter_vid", vacant_seats_at = "tomma_stolar_vid")
  if (surface %in% names(map)) unname(map[[surface]]) else surface
}

# Missing or empty permission lists fail closed; manifests never grant permission.
.canonical_auto_function_allowed <- function(entry, surface) {
  approved <- entry$auto_functions
  if (!is.character(approved) || !length(approved) || anyNA(approved)) return(FALSE)
  .canonical_surface(surface) %in% vapply(approved, .canonical_surface, character(1))
}

# Use manifest layouts to check the requested view, not just the election year.
# Detailed dependency, key and checksum validation remains in the same readers.
.canonical_view_covered <- function(manifest, surface, val = NULL, niva = NULL,
                                    rakning = "slutlig", include_results = TRUE) {
  surface <- .canonical_surface(surface)
  series <- manifest$valserie; year <- as.integer(manifest$valar)
  prefix <- paste0(if (series == "folkomr") "referendum" else series, year, "-")
  has <- function(asset, level = NULL) {
    if (!asset %in% manifest$assets$asset) return(FALSE)
    is.null(level) || all(.canonical_storage_key(level) %in% manifest$tables$table[manifest$tables$asset == asset])
  }
  if (surface %in% c("mandathistorik", "ledamoter_vid", "tomma_stolar_vid"))
    return(series == "rkl" && has(paste0(prefix, "mandate-history"), "intervals"))
  english <- c(valresultat = "results", mandat = "seats", kandidaturer = "candidacies",
    kandidater = "candidates", valda = "elected", ersattare = "substitutes",
    personroster = "preference_votes")[[surface]]
  if (is.null(english)) return(FALSE)
  if (series == "folkomr") return(surface == "valresultat" && rakning == "slutlig" &&
    has(paste0(prefix, "results-final"), niva))
  if (series == "eu") {
    if (surface %in% c("valresultat", "mandat"))
      return(has(paste0(prefix, english, "-", if (rakning == "slutlig") "final" else "preliminary"),
                 if (is.null(niva)) "riket" else niva))
    if (surface == "personroster") {
      short <- c(personvalsomrade = "area", riket = "national", lan = "county",
        kommun = "municipality", kommunvalkrets = "municipal-constituency", valdistrikt = "district")
      if (length(niva) != 1L || !niva %in% names(short)) return(FALSE)
      return(has(paste0(prefix, "preference-base-", short[[niva]])))
    }
    if (surface == "kandidater" && !include_results) english <- "candidate-base"
    return(has(paste0(prefix, english)))
  }
  values <- if (is.null(val)) c("RD", "RF", "KF") else val
  if (surface == "valresultat") {
    if (year == 2018L && rakning != "slutlig") return(FALSE)
    assets <- paste0(prefix, "results-", if (year == 2018L) "" else paste0(rakning, "-"), tolower(values))
    return(all(vapply(assets, has, logical(1), level = niva)))
  }
  if (surface == "mandat") {
    if (year == 2018L && rakning != "slutlig") return(FALSE)
    return(has(paste0(prefix, "seats", if (year == 2018L) "" else paste0("-", rakning)), values))
  }
  if (surface == "personroster") {
    if (length(niva) != 1L || !niva %in% c("personvalsomrade", "valdistrikt")) return(FALSE)
    assets <- paste0(prefix, "preference-votes-", if (niva == "valdistrikt") "district-" else "area-", tolower(values))
    return(all(vapply(assets, has, logical(1))))
  }
  has(paste0(prefix, english))
}

.canonical_require_reader <- function() {
  if (!requireNamespace("nanoparquet", quietly = TRUE))
    stop("Canonical data require package 'nanoparquet'; install it or explicitly select a supported raw source.", call. = FALSE)
}

.select_public_source <- function(source, year, surface, data_dir = NULL,
                                  update = FALSE, archive = FALSE,
                                  include_results = TRUE, series = "rkl",
                                  event_kind = "ordinary", val = NULL, niva = NULL,
                                  rakning = "slutlig") {
  if (source != "auto" || update || archive || isTRUE(getOption("swelections.internal_raw_request", FALSE))) return(source)
  entry <- .canonical_release(year, series, event_kind)
  if (is.null(entry) || !isTRUE(entry$auto_eligible) ||
      !.canonical_auto_function_allowed(entry, surface)) return("auto")
  path <- .canonical_manifest_path(year, series, event_kind, auto_selected = TRUE)
  manifest <- .canonical_manifest(path)
  if (!.canonical_view_covered(manifest, surface, val, niva, rakning, include_results))
    return("auto")
  .canonical_require_reader()
  "canonical_auto"
}

.canonical_release_manifest <- function(release, missing_ok = FALSE) {
  cache <- getOption("swelections.canonical_cache_dir",
                     tools::R_user_dir("swelections", "cache"))
  key <- release$cache_key
  if (is.null(key) || is.na(key)) key <- file.path(release$series,
    if (is.null(release$event_kind)) "ordinary" else release$event_kind, release$year, release$data_version)
  path <- file.path(cache, key, "manifest.json")
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
  if (file.exists(path)) stop("Cached canonical manifest is invalid; inspect the cache before retrying.", call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  filename <- release$manifest_file
  if (is.null(filename)) filename <- "manifest.json"
  url <- paste0(sub("/+$", "", release$base_url), "/", filename)
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


# Resolve assets independently of their transport. All readers retain the same
# checksum-verified cache; no raw source is used to repair canonical failures.
.canonical_fetcher <- function(manifest, path) {
  registration <- .canonical_release(as.integer(manifest$valar), manifest$valserie)
  directory <- getOption("swelections.canonical_assets_dir", dirname(path))
  base <- getOption("swelections.canonical_base_url", NULL)
  if (is.null(base) && !is.null(registration$base_url) &&
      !is.na(registration$base_url)) base <- registration$base_url
  function(asset) {
    entry <- manifest$assets[manifest$assets$asset == asset, , drop = FALSE]
    if (nrow(entry) != 1L) stop("Unknown canonical asset: ", asset, call. = FALSE)
    local <- file.path(directory, entry$file)
    url <- if (file.exists(local)) paste0("file:///",
      gsub("\\\\", "/", normalizePath(local))) else if (!is.null(base))
        paste0(sub("/+$", "", base), "/", entry$file) else NULL
    .canonical_asset(manifest, asset,
      getOption("swelections.canonical_cache_dir", NULL), url)
  }
}
