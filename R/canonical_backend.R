# The canonical collection is a separate, versioned source. It is not a local
# copy of Valmyndigheten's raw files.
.canonical_sha256 <- function(path) {
  if (!file.exists(path)) stop("Kanonisk fil saknas: ", path, call. = FALSE)
  if (!exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    stop("SHA256 verification requires tools::sha256sum().",
         call. = FALSE)
  }
  tolower(unname(tools::sha256sum(path)))
}

.canonical_manifest <- function(path) {
  if (!file.exists(path)) stop("Kanoniskt manifest saknas.", call. = FALSE)
  manifest <- jsonlite::read_json(path, simplifyVector = TRUE)
  required <- c("data_version", "schema_version", "valserie", "valar",
                "assets", "sources")
  if (!all(required %in% names(manifest)) ||
      !is.data.frame(manifest$assets) ||
      !all(c("asset", "file", "bytes", "sha256") %in% names(manifest$assets))) {
    stop("Ogiltigt kanoniskt manifest.", call. = FALSE)
  }
  if (length(manifest$data_version) != 1L ||
      !grepl("^data-v[0-9]+\\.[0-9]+\\.[0-9]+$", manifest$data_version) ||
      !as.integer(manifest$schema_version) %in% c(1L, 2L) ||
      anyDuplicated(manifest$assets$asset) ||
      anyDuplicated(manifest$assets$file) ||
      any(!grepl("^[a-z0-9][a-z0-9_.-]*$", manifest$assets$asset)) ||
      any(!grepl("^[a-z0-9][a-z0-9_.-]*\\.(rds|parquet)$",
                 manifest$assets$file)) ||
      any(is.na(manifest$assets$bytes) | manifest$assets$bytes < 0) ||
      any(!grepl("^[a-f0-9]{64}$", manifest$assets$sha256))) {
    stop("Ogiltiga kanoniska assetnycklar eller checksummor.", call. = FALSE)
  }
  if (identical(manifest$format, "parquet") &&
      (any(tools::file_ext(manifest$assets$file) != "parquet") ||
       !is.data.frame(manifest$tables) ||
       !all(c("asset", "table", "columns") %in% names(manifest$tables)) ||
       any(!manifest$tables$asset %in% manifest$assets$asset) ||
       anyDuplicated(manifest$tables[c("asset", "table")]) ||
       anyNA(manifest$tables$columns) ||
       any(!nzchar(manifest$tables$columns)))) {
    stop("Ogiltigt Parquet-manifest.", call. = FALSE)
  }
  manifest
}

.canonical_asset <- function(manifest, asset, cache_dir = NULL, url = NULL) {
  if (length(asset) != 1L || is.na(asset) || !is.character(asset))
    stop("Ange exakt ett kanoniskt asset.", call. = FALSE)
  entry <- manifest$assets[manifest$assets$asset == asset, , drop = FALSE]
  if (nrow(entry) != 1L) stop("Unknown canonical asset: ", asset, call. = FALSE)
  if (is.null(cache_dir)) cache_dir <- tools::R_user_dir("swelections", "cache")
  root <- file.path(cache_dir, manifest$data_version, asset,
                    substr(entry$sha256, 1L, 16L))
  path <- file.path(root, entry$file)
  valid <- function(file) file.exists(file) &&
    identical(as.numeric(file.info(file)$size), as.numeric(entry$bytes)) &&
    identical(.canonical_sha256(file), entry$sha256)
  if (file.exists(path) && !valid(path)) unlink(path)
  if (!file.exists(path)) {
    if (is.null(url)) stop("Kanoniskt asset saknas i cache: ", asset,
                           call. = FALSE)
    if (length(url) != 1L || !is.character(url) || is.na(url))
      stop("Invalid URL for canonical asset.", call. = FALSE)
    dir.create(root, recursive = TRUE, showWarnings = FALSE)
    tmp <- tempfile(tmpdir = root,
                    fileext = paste0(".", tools::file_ext(entry$file)))
    on.exit(unlink(tmp), add = TRUE)
    if (grepl("^file://", url)) {
      source_path <- utils::URLdecode(sub("^file://", "", url))
      if (.Platform$OS.type == "windows") source_path <- sub("^/([A-Za-z]:)", "\\1", source_path)
      if (!file.copy(source_path, tmp, overwrite = TRUE))
        stop("Could not read local canonical asset.", call. = FALSE)
    } else {
      .download_file(url, tmp, expected_bytes = entry$bytes)
    }
    if (!valid(tmp)) stop("Incorrect SHA256 or size for canonical asset: ",
                          asset, call. = FALSE)
    if (!file.rename(tmp, path)) stop("Could not cache canonical asset.",
                                      call. = FALSE)
  }
  if (tools::file_ext(path) == "parquet") {
    if (!requireNamespace("nanoparquet", quietly = TRUE)) {
      stop("Reading canonical Parquet assets requires optional package nanoparquet.",
           call. = FALSE)
    }
    return(tibble::as_tibble(nanoparquet::read_parquet(path)))
  }
  readRDS(path)
}

.canonical_table <- function(manifest, data, asset, table,
                             discriminator = ".table") {
  entry <- manifest$tables[manifest$tables$asset == asset &
                             manifest$tables$table == table, , drop = FALSE]
  if (nrow(entry) != 1L) stop("Kanonisk tabell saknas: ", asset, "/", table,
                             call. = FALSE)
  columns <- strsplit(entry$columns[[1L]], ",", fixed = TRUE)[[1L]]
  out <- data[data[[discriminator]] == table, columns, drop = FALSE]
  out <- tibble::as_tibble(out)
  if (identical(as.integer(manifest$schema_version), 2L))
    out <- .canonical_names_sv(out)
  out
}

.canonical_2018_source <- function(surface, val = NULL, niva = NULL,
                                   per_lista = FALSE,
                                   komplettera_nollor = FALSE,
                                   resultat = TRUE, auto_selected = FALSE) {
  release <- .canonical_release(2018L)
  path <- if (auto_selected) .canonical_release_manifest(release) else
    getOption("swelections.canonical_manifest", NULL)
  if (is.null(path)) path <- .canonical_release_manifest(release)
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop("Configure a valid canonical manifest or use the published release.",
         call. = FALSE)
  manifest <- .canonical_manifest(path)
  if (!identical(as.integer(manifest$schema_version), 2L) ||
      !identical(manifest$format, "parquet")) {
    stop("The canonical source requires the English Parquet schema (version 2).",
         call. = FALSE)
  }
  assets_dir <- if (auto_selected) dirname(path) else
    getOption("swelections.canonical_assets_dir", dirname(path))
  base_url <- if (auto_selected) release$base_url else
    getOption("swelections.canonical_base_url", release$base_url)
  urls <- stats::setNames(lapply(manifest$assets$file, function(file) {
    local <- file.path(assets_dir, file)
    if (file.exists(local)) {
      paste0("file:///", gsub("\\\\", "/", normalizePath(local)))
    } else if (!is.null(base_url)) {
      paste0(sub("/+$", "", base_url), "/", file)
    } else NULL
  }), manifest$assets$asset)
  .canonical_public_2018(manifest, surface, val, niva, per_lista,
                         komplettera_nollor, resultat,
                         getOption("swelections.canonical_cache_dir", NULL), urls)
}

.canonical_person_base <- function(manifest, fetch, val, level) {
  short <- if (level == "personvalsomrade") "area" else "district"
  asset <- paste0("rkl2018-preference-votes-base-", short, "-", tolower(val))
  x <- fetch(asset)
  components <- c("geo", "parti", "lista", "roster", "listroster")
  out <- lapply(components, function(component)
    .canonical_table(manifest, x, asset, component, ".component"))
  names(out) <- components
  if (identical(level, "personvalsomrade")) {
    for (component in c("lista", "listroster"))
      names(out[[component]]$listnummer) <- paste(
        out[[component]]$partikod, out[[component]]$listnummer, sep = "-")
  }
  out
}

.canonical_public_2018 <- function(manifest, surface, val = NULL, niva = NULL,
                                   per_lista = FALSE,
                                   komplettera_nollor = FALSE,
                                   resultat = TRUE, cache_dir = NULL,
                                   urls = list()) {
  if (!identical(manifest$valserie, "rkl") ||
      !identical(as.integer(manifest$valar), 2018L)) {
    stop("Canonical collection is not RKL 2018.", call. = FALSE)
  }
  fetch <- function(asset) .canonical_asset(manifest, asset, cache_dir,
                                              urls[[asset]])
  if (identical(surface, "valresultat")) {
    if (length(val) != 1L || length(niva) != 1L)
      stop("Specify election type and level for valresultat.", call. = FALSE)
    asset <- paste0("rkl2018-results-", tolower(val))
    return(.canonical_table(manifest, fetch(asset), asset, niva))
  }
  if (identical(surface, "mandat")) {
    asset <- "rkl2018-seats"
    data <- fetch(asset)
    values <- if (is.null(val)) c("RD", "RF", "KF") else val
    if (!all(values %in% c("RD", "RF", "KF"))) stop("Valtyp saknas.", call. = FALSE)
    out <- purrr::list_rbind(lapply(values, function(v)
      .canonical_table(manifest, data, asset, v)))
    if (!is.null(niva)) out <- dplyr::filter(out, .data$geografiniva %in% niva)
    return(out)
  }
  if (surface %in% c("kandidaturer", "kandidater", "valda", "ersattare")) {
    asset <- c(kandidaturer = "candidacies", kandidater = "candidates",
               valda = "elected", ersattare = "substitutes")[[surface]]
    out <- .canonical_names_sv(fetch(paste0("rkl2018-", asset)))
    if (!is.null(val)) out <- dplyr::filter(out, .data$valtyp %in% val)
    if (surface == "kandidater" && (!isTRUE(resultat) || !is.null(val))) {
      kd <- .canonical_names_sv(fetch("rkl2018-candidacies"))
      if (!is.null(val)) kd <- dplyr::filter(kd, .data$valtyp %in% val)
      base <- .kandidater_bas(kd, 2018L)
      if (!isTRUE(resultat)) return(base)
      key <- c("kandidatnummer", "valtyp", "partikod")
      index <- match(do.call(paste, c(out[key], sep = "\r")),
                     do.call(paste, c(base[key], sep = "\r")))
      if (anyNA(index) || anyDuplicated(index))
        stop("Canonical candidate keys disagree.", call. = FALSE)
      for (field in names(base)) out[[field]] <- base[[field]][index]
    }
    if (surface == "valda" && !is.null(val) &&
        all(c("antal_valtyper", "flera_valtyper") %in% names(out))) {
      kd <- dplyr::filter(.canonical_names_sv(fetch("rkl2018-candidacies")),
                          .data$valtyp %in% val)
      base <- .kandidater_bas(kd, 2018L)
      key <- c("kandidatnummer", "valtyp", "partikod")
      index <- match(do.call(paste, c(out[key], sep = "\r")),
                     do.call(paste, c(base[key], sep = "\r")))
      if (anyNA(index)) stop("Canonical elected candidate keys disagree.",
                             call. = FALSE)
      out$antal_valtyper <- base$antal_valtyper[index]
      out$flera_valtyper <- base$flera_valtyper[index]
    }
    return(out)
  }
  if (!identical(surface, "personroster"))
    stop("Unknown canonical surface: ", surface, call. = FALSE)
  if (length(val) != 1L || !val %in% c("RD", "RF", "KF") ||
      length(niva) != 1L || !niva %in% c("personvalsomrade", "valdistrikt")) {
    stop("Specify one election type and person-vote level.", call. = FALSE)
  }
  kd <- .canonical_names_sv(fetch("rkl2018-candidacies")) |>
    dplyr::filter(.data$valtyp == val)
  short <- if (niva == "personvalsomrade") "area" else "district"
  if (niva == "personvalsomrade" || !isTRUE(komplettera_nollor)) {
    asset <- paste0("rkl2018-preference-votes-", short, "-", tolower(val))
    table <- paste(isTRUE(per_lista), isTRUE(komplettera_nollor), sep = "__")
    out <- .canonical_table(manifest, fetch(asset), asset, table,
                            ".person_view")
    # The XML parser leaves an R-only lookup name on this vector. Parquet
    # stores the values; reconstruct the attribute for exact raw equivalence.
    if (identical(niva, "personvalsomrade") && "listnummer" %in% names(out))
      names(out$listnummer) <- paste(out$partikod, out$listnummer, sep = "-")
    return(out)
  }
  area <- .canonical_person_base(manifest, fetch, val, "personvalsomrade")
  raw <- .canonical_person_base(manifest, fetch, val, "valdistrikt")
  .xml2018_person_public(raw, area, kd, niva, per_lista,
                         komplettera_nollor) |>
    dplyr::arrange(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
      dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
}
