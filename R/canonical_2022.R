# 2022 remains opt-in until a reviewed release is published and registered.
# The manifest may be a single path, or named paths for multi-year requests.
.canonical_source <- function(ar, surface, val = NULL, niva = NULL,
                               per_lista = FALSE, komplettera_nollor = FALSE,
                               resultat = TRUE, auto_selected = FALSE,
                               rakning = "slutlig") {
  configured <- getOption("swelections.canonical_manifest", NULL)
  if (!is.null(names(configured)) && as.character(ar) %in% names(configured)) {
    configured <- unname(configured[[as.character(ar)]])
  }
  if (ar == 2014L) return(.canonical_2014_source(configured, surface, val,
    niva, per_lista, komplettera_nollor, resultat, rakning))
  if (ar == 2018L) {
    old <- options(swelections.canonical_manifest = configured)
    on.exit(options(old), add = TRUE)
    return(.canonical_2018_source(surface, val, niva, per_lista,
      komplettera_nollor, resultat, auto_selected))
  }
  if (ar != 2022L || !is.character(configured) || length(configured) != 1L ||
      !file.exists(configured)) {
    stop("2022 canonical data require a configured local build manifest; ",
         "no 2022 canonical release has been published.", call. = FALSE)
  }
  manifest <- .canonical_manifest(configured)
  if (!identical(as.integer(manifest$valar), 2022L) ||
      !identical(manifest$valserie, "rkl") ||
      !identical(as.integer(manifest$schema_version), 2L) ||
      !identical(manifest$format, "parquet")) {
    stop("Expected RKL 2022 English Parquet schema version 2.", call. = FALSE)
  }
  dir <- getOption("swelections.canonical_assets_dir", dirname(configured))
  base <- getOption("swelections.canonical_base_url", NULL)
  urls <- stats::setNames(lapply(manifest$assets$file, function(file) {
    local <- file.path(dir, file)
    if (file.exists(local)) {
      paste0("file:///", gsub("\\\\", "/", normalizePath(local)))
    } else if (!is.null(base)) paste0(sub("/+$", "", base), "/", file)
    else NULL
  }), manifest$assets$asset)
  fetch <- function(asset) .canonical_asset(manifest, asset,
    getOption("swelections.canonical_cache_dir", NULL), urls[[asset]])
  .canonical_public_2022(manifest, fetch, surface, val, niva, per_lista,
                         komplettera_nollor, resultat, rakning)
}

.canonical_public_2022 <- function(manifest, fetch, surface, val, niva,
                                   per_lista, komplettera_nollor, resultat,
                                   rakning) {
  if (surface == "valresultat") {
    asset <- paste0("rkl2022-results-", rakning, "-", tolower(val))
    return(.canonical_table(manifest, fetch(asset), asset, niva))
  }
  if (surface == "mandat") {
    asset <- paste0("rkl2022-seats-", rakning)
    x <- fetch(asset)
    values <- if (is.null(val)) c("RD", "RF", "KF") else val
    out <- purrr::list_rbind(lapply(values, function(v)
      .canonical_table(manifest, x, asset, v)))
    if (!is.null(niva)) out <- dplyr::filter(out, .data$geografiniva %in% niva)
    return(out)
  }
  if (surface %in% c("kandidaturer", "kandidater", "valda", "ersattare")) {
    english <- c(kandidaturer = "candidacies", kandidater = "candidates",
                 valda = "elected", ersattare = "substitutes")[[surface]]
    out <- .canonical_names_sv(fetch(paste0("rkl2022-", english)))
    if (!is.null(val)) out <- dplyr::filter(out, .data$valtyp %in% val)
    if (surface %in% c("valda", "ersattare") && !is.null(val))
      out <- purrr::list_rbind(lapply(val, function(v)
        dplyr::filter(out, .data$valtyp == v)))
    if (surface %in% c("kandidater", "valda") &&
        (!is.null(val) || !isTRUE(resultat))) {
      kd <- .canonical_names_sv(fetch("rkl2022-candidacies"))
      if (!is.null(val)) kd <- dplyr::filter(kd, .data$valtyp %in% val)
      stored <- .canonical_names_sv(fetch("rkl2022-candidates"))
      base <- .canonical_candidate_base_2022(kd, stored)
      if (surface == "kandidater" && !isTRUE(resultat)) return(base)
      key <- c("kandidatnummer", "valtyp", "partikod")
      index <- match(do.call(paste, c(out[key], sep = "\r")),
                     do.call(paste, c(base[key], sep = "\r")))
      if (anyNA(index) || anyDuplicated(index))
        stop("Canonical candidate keys disagree.", call. = FALSE)
      fields <- if (surface == "kandidater") names(base) else
        intersect(c("antal_valtyper", "flera_valtyper"), names(out))
      for (field in fields) out[[field]] <- base[[field]][index]
    }
    return(out)
  }
  if (surface != "personroster") stop("Unknown canonical surface.", call. = FALSE)
  short <- if (niva == "valdistrikt") "district" else "area"
  if (niva == "personvalsomrade" || !isTRUE(komplettera_nollor)) {
    asset <- paste0("rkl2022-preference-votes-", short, "-", tolower(val))
    view <- paste(isTRUE(per_lista), isTRUE(komplettera_nollor), sep = "__")
    return(.canonical_table(manifest, fetch(asset), asset, view, ".person_view"))
  }
  .canonical_person_2022(manifest, fetch, val, niva, per_lista, komplettera_nollor)
}

# Recover the materialized candidacy summaries in original source-key order.
# Only the cross-election count depends on the requested election subset.
.canonical_candidate_base_2022 <- function(kd, stored) {
  valid <- dplyr::filter(kd, .data$giltig %in% TRUE)
  if (!nrow(valid)) stop("No valid canonical candidacies.", call. = FALSE)
  fields <- names(.kandidater_bas(valid[1L, , drop = FALSE], 2022L))
  key <- c("kandidatnummer", "valtyp", "partikod")
  keys <- dplyr::distinct(valid, dplyr::across(dplyr::all_of(key)))
  encode <- function(x) do.call(paste, c(x[key], sep = "\r"))
  index <- match(encode(keys), encode(stored))
  if (anyNA(index) || anyDuplicated(index))
    stop("Canonical candidate keys disagree.", call. = FALSE)
  out <- stored[index, fields, drop = FALSE]
  types <- dplyr::distinct(valid, .data$kandidatnummer, .data$valtyp) |>
    dplyr::count(.data$kandidatnummer, name = "antal_valtyper")
  out$antal_valtyper <- types$antal_valtyper[match(out$kandidatnummer, types$kandidatnummer)]
  out$flera_valtyper <- out$antal_valtyper > 1L
  out
}

.canonical_person_2022 <- function(manifest, fetch, val, niva, per_lista,
                                   komplettera_nollor) {
  short <- if (niva == "valdistrikt") "district" else "area"
  asset <- paste0("rkl2022-preference-votes-base-", short, "-", tolower(val))
  x <- fetch(asset)
  components <- manifest$tables$table[manifest$tables$asset == asset]
  parts <- stats::setNames(lapply(components, function(component)
    .canonical_table(manifest, x, asset, component, ".component")), components)
  kd <- dplyr::filter(.canonical_names_sv(fetch("rkl2022-candidacies")),
                       .data$valtyp == val)
  # Presentation only needs key/name/party identity, already materialized in
  # the candidate asset. No candidate result or population is inferred here.
  bas <- dplyr::filter(.canonical_names_sv(fetch("rkl2022-candidates")),
                        .data$valtyp == val)
  partitioned <- lapply(parts, function(data) split(data, data$.source_area))
  key <- c("valtyp", "partikod", "kandidatnummer")
  all_global <- dplyr::distinct(kd, dplyr::across(dplyr::all_of(key)))
  valid_global <- dplyr::distinct(dplyr::filter(kd, .data$giltig %in% TRUE),
                                  dplyr::across(dplyr::all_of(key)))
  out <- lapply(unique(parts$metadata$.source_area), function(area) {
    get <- function(component) {
      data <- partitioned[[component]][[area]]
      if (is.null(data)) data <- parts[[component]][0L, , drop = FALSE]
      data$.source_area <- NULL
      data
    }
    metadata <- get("metadata")
    raw <- as.list(metadata[1L, ])
    pop <- stats::setNames(lapply(c("kandidat", "lista", "alla"),
      function(p) get(paste0("population_", p))), c("kandidat", "lista", "alla"))
    pop$alla_globalt <- all_global
    pop$giltiga_globalt <- valid_global
    kallor <- stats::setNames(lapply(c("parti", "lista", "roster"), get),
                              c("parti", "lista", "roster"))
    .personroster_2022_public(raw,
      list(geo = get("geo"), omraden = get("omraden")), pop, kallor, bas,
      niva, per_lista, komplettera_nollor, officiella = get("officiella"))
  })
  purrr::list_rbind(out) |>
    dplyr::arrange(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
      dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
}
