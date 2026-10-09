# An explicitly configured, unpublished 2014 product. No auto-release entry.
.canonical_2014_source <- function(path, surface, val, niva, per_lista,
                                   komplettera_nollor, resultat, rakning, ar = 2014L) {
  prefix <- paste0("rkl", ar, "-")
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop(ar, " canonical data require a configured local build manifest.", call. = FALSE)
  manifest <- .canonical_manifest(path)
  if (!identical(as.integer(manifest$valar), as.integer(ar)) ||
      !identical(as.integer(manifest$schema_version), 2L) ||
      !identical(manifest$format, "parquet") || !identical(manifest$valserie, "rkl"))
    stop("Expected RKL ", ar, " English Parquet schema version 2.", call. = FALSE)
  directory <- getOption("swelections.canonical_assets_dir", dirname(path))
  fetch <- function(asset) {
    entry <- manifest$assets[manifest$assets$asset == asset, ]
    if (nrow(entry) != 1L) stop("Missing ", ar, " asset: ", asset, call. = FALSE)
    file <- normalizePath(file.path(directory, entry$file), winslash = "/", mustWork = TRUE)
    .canonical_asset(manifest, asset, getOption("swelections.canonical_cache_dir", NULL),
      paste0("file:///", file))
  }
  values <- if (is.null(val)) c("RD", "RF", "KF") else val
  if (surface == "valresultat") {
    asset <- paste0(paste0(prefix, "results-"), rakning, "-", tolower(val))
    return(.canonical_table(manifest, fetch(asset), asset, niva))
  }
  if (surface == "mandat") {
    if (rakning != "slutlig") stop(ar, " seats require final election XML.", call. = FALSE)
    asset <- paste0(prefix, "seats-slutlig")
    x <- fetch(asset)
    out <- purrr::list_rbind(lapply(values, function(v)
      .canonical_table(manifest, x, asset, v)))
    if (!is.null(niva)) out <- dplyr::filter(out, .data$geografiniva %in% niva)
    return(out)
  }
  population <- function() dplyr::filter(
    .canonical_names_sv(fetch(paste0(prefix, "candidate-population"))), .data$valtyp %in% values)
  if (surface == "personroster") {
    short <- if (niva == "valdistrikt") "district" else "area"
    asset <- paste0(paste0(prefix, "preference-votes-"), short, "-", tolower(val))
    if (niva != "valdistrikt" || !komplettera_nollor)
      return(.canonical_table(manifest, fetch(asset), asset,
        paste(per_lista, komplettera_nollor, sep = "__"), ".person_view"))
    read_base <- function(short) {
      asset <- paste0(paste0(prefix, "preference-votes-base-"), short, "-", tolower(val))
      x <- fetch(asset)
      components <- manifest$tables$table[manifest$tables$asset == asset]
      stats::setNames(lapply(components, function(component)
        .canonical_table(manifest, x, asset, component, ".component")), components)
    }
    return(.metadata_2014(.xml2018_person_public(read_base("district"),
      read_base("area"), population(), niva, per_lista, komplettera_nollor), ar) |>
      dplyr::arrange(.data$valtyp, .data$valomradeskod, .data$personvalsomradeskod,
        .data$partikod, .data$kandidatnummer,
        dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer")))))
  }
  english <- c(kandidaturer = "candidacies", kandidater = "candidates",
    valda = "elected", ersattare = "substitutes")[[surface]]
  if (is.null(english)) stop("Unknown 2014 canonical surface.", call. = FALSE)
  out <- .canonical_names_sv(fetch(paste0(prefix, english)))
  out <- dplyr::filter(out, .data$valtyp %in% values)
  if (surface %in% c("kandidaturer", "ersattare"))
    out <- purrr::list_rbind(lapply(values, function(v)
      dplyr::filter(out, .data$valtyp == v)))
  if (surface %in% c("kandidater", "valda")) {
    pop <- population()
    types <- unique(pop[c("kandidatnummer", "valtyp")]) |>
      dplyr::count(.data$kandidatnummer, name = "antal_valtyper")
    out$antal_valtyper <- types$antal_valtyper[match(out$kandidatnummer, types$kandidatnummer)]
    out$flera_valtyper <- out$antal_valtyper > 1L
    # Match the raw union's first-occurrence order: ballot candidates, observed
    # area candidates, then elected/substitute-only candidates. Sorting whole
    # election blocks would move result-only candidates ahead of ballot rows.
    key <- c("valtyp", "partikod", "kandidatnummer")
    ordered <- function(x) purrr::list_rbind(lapply(values, function(v)
      dplyr::filter(x, .data$valtyp == v)))[key]
    keys <- ordered(.canonical_names_sv(fetch(paste0(prefix, "candidacies"))))
    for (v in values) {
      asset <- paste0(paste0(prefix, "preference-votes-base-area-"), tolower(v))
      observed <- .canonical_table(manifest, fetch(asset), asset, "roster", ".component")
      keys <- dplyr::bind_rows(keys, observed[key])
    }
    keys <- dplyr::bind_rows(keys,
      ordered(.canonical_names_sv(fetch(paste0(prefix, "elected")))),
      ordered(dplyr::rename(.canonical_names_sv(fetch(paste0(prefix, "substitutes"))),
        kandidatnummer = "ersattare_kandidatnummer"))) |>
      dplyr::distinct()
    encode <- function(x) do.call(paste, c(x[key], sep = "\r"))
    out <- out[order(match(encode(out), encode(keys))), , drop = FALSE]
    if (!resultat && surface == "kandidater") {
      fields <- names(.kandidater_bas(pop[1L, ], ar))
      out <- out[fields]
    }
  }
  out
}
