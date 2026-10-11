# Unpublished 2006 prototype; no automatic canonical eligibility or release.
.canonical_2006_source <- function(path, surface, val, niva, per_lista,
                                   komplettera_nollor, resultat, rakning) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop("2006 canonical data require a configured local build manifest.", call. = FALSE)
  manifest <- .canonical_manifest(path)
  if (!identical(as.integer(manifest$valar), 2006L) ||
      !identical(as.integer(manifest$schema_version), 2L) ||
      !identical(manifest$format, "parquet") || !identical(manifest$valserie, "rkl"))
    stop("Expected RKL 2006 English Parquet schema version 2.", call. = FALSE)
  directory <- getOption("swelections.canonical_assets_dir", dirname(path))
  fetch <- function(asset) {
    entry <- manifest$assets[manifest$assets$asset == asset, ]
    if (nrow(entry) != 1L) stop("Missing 2006 asset: ", asset, call. = FALSE)
    file <- normalizePath(file.path(directory, entry$file), winslash = "/", mustWork = TRUE)
    .canonical_asset(manifest, asset, getOption("swelections.canonical_cache_dir", NULL), paste0("file:///", file))
  }
  values <- if (is.null(val)) c("RD", "RF", "KF") else val
  if (surface == "valresultat") {
    if (rakning != "slutlig") stop("2006 has no complete preliminary collection source.", call. = FALSE)
    asset <- paste0("rkl2006-results-slutlig-", tolower(val))
    return(.canonical_table(manifest, fetch(asset), asset, niva))
  }
  if (surface == "mandat") {
    if (rakning != "slutlig") stop("2006 seats require final election XML.", call. = FALSE)
    asset <- "rkl2006-seats-slutlig"
    out <- purrr::list_rbind(lapply(values, function(v)
      .canonical_table(manifest, fetch(asset), asset, v)))
    if (!is.null(niva)) out <- out[out$geografiniva %in% niva, ]
    return(out)
  }
  if (surface == "personroster") {
    if (!niva %in% c("personvalsomrade", "valdistrikt")) stop("Unsupported 2006 preference-vote level.", call. = FALSE)
    out <- purrr::list_rbind(lapply(values, function(v) {
      asset <- paste0("rkl2006-preference-votes-", if (niva == "valdistrikt") "district-" else "area-", tolower(v))
      .canonical_table(manifest, fetch(asset), asset, as.character(per_lista), ".person_view")
    }))
    return(out)
  }
  english <- c(kandidaturer = "candidacies", kandidater = "candidates",
    valda = "elected", ersattare = "substitutes")[[surface]]
  if (is.null(english)) stop("Unknown 2006 canonical surface.", call. = FALSE)
  out <- .canonical_names_sv(fetch(paste0("rkl2006-", english)))
  out <- purrr::list_rbind(lapply(values, function(v) out[out$valtyp == v, ]))
  if (surface == "kandidater" && !resultat) {
    # The base has its own typed column contract; do not fabricate a base by
    # filtering public candidacies, which exclude result-only observations.
    asset <- "rkl2006-candidate-base"
    base <- .canonical_names_sv(fetch(asset))
    out <- purrr::list_rbind(lapply(values, function(v) base[base$valtyp == v, ]))
  }
  out
}
