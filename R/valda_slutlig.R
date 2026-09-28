# Valda hämtas endast från officiella slutliga mandatfiler.
.slutliga_mandat_paths <- function(index, val, funktion) {
  purrr::map_dfr(val, function(valtyp) {
    kod <- switch(valtyp, RD = "00", RF = "[0-9]{2}", KF = "[0-9]{4}")
    suffix <- paste0("/.*_", kod, "_", valtyp, "\\.zip$")
    slutliga <- index$path[stringr::str_detect(
      index$path, paste0("^s/", tolower(valtyp), suffix))]
    preliminara <- index$path[stringr::str_detect(
      index$path, paste0("^p/", tolower(valtyp), suffix))]
    filkod <- function(path) sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", path)
    if (!length(slutliga)) {
      stop("Slutlig resultatk\u00e4lla saknas f\u00f6r ", valtyp,
           ". `", funktion, "()` kan inte byggas fr\u00e5n prelimin\u00e4r r\u00e4kning.",
           call. = FALSE)
    }
    slutkoder <- filkod(slutliga)
    omraden <- filkod(preliminara)
    if (anyDuplicated(slutkoder) || anyDuplicated(omraden)) {
      stop("Dubbla resultatfiler f\u00f6r ", valtyp, " i index.", call. = FALSE)
    }
    saknade <- setdiff(omraden, slutkoder)
    if (length(saknade)) {
      stop("Slutlig resultatk\u00e4lla saknas f\u00f6r ", valtyp, " i valomr\u00e5de ",
           paste(saknade, collapse = ", "),
           ". `", funktion, "()` anv\u00e4nder inte prelimin\u00e4r r\u00e4kning.",
           call. = FALSE)
    }
    tibble::tibble(valtyp = valtyp, path = slutliga)
  })
}

.valda_slutliga_paths <- function(index, val) {
  .slutliga_mandat_paths(index, val, "valda")
}

.valda_validera_nycklar <- function(valda_data, kandidater_bas) {
  nyckel <- c("kandidatnummer", "valtyp", "partikod")
  if (anyDuplicated(valda_data[nyckel])) {
    stop("Samma person f\u00f6rekommer flera g\u00e5nger i slutlig invaldsrelation.",
         call. = FALSE)
  }
  if (nrow(dplyr::anti_join(valda_data, kandidater_bas,
      by = dplyr::join_by(kandidatnummer, valtyp, partikod)))) {
    stop("Slutlig vald person saknar giltig kandidatur.", call. = FALSE)
  }
}

.valda_ett_ar <- function(ar, val, source, data_dir, update, archive,
                          progress) {
  if (ar == 2018L) {
    kandidaturdata <- kandidaturer(ar = ar, val = val, source = source,
      data_dir = data_dir, update = update, archive = archive)
    bas <- .kandidater_bas(kandidaturdata, ar)
    valda_data <- .xml2018_valda_ersattare(val, source, data_dir,
      update, archive, progress)$valda
    .valda_validera_nycklar(valda_data, bas)
    return(.xml2018_valda_public(valda_data, bas, kandidaturdata,
      source, data_dir, update, archive, progress))
  }
  index <- .read_resultatindex(ar, source, data_dir, update, archive)
  paths <- .valda_slutliga_paths(index, val)
  kandidaturdata <- kandidaturer(
    ar = ar, val = val, source = source, data_dir = data_dir,
    update = update, archive = archive
  )
  kandidater_bas <- .kandidater_bas(kandidaturdata, ar)
  out <- purrr::map2(paths$path, paths$valtyp, function(path, valtyp) {
    file <- .resultat_file(ar, path, source, data_dir, update, archive)
    raw <- read_raw_json_zip_2026(file, type = "mandatfordelning")
    if (!identical(as_chr_na(raw$valtyp), valtyp) ||
        !identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle),
                   "slutlig")) {
      stop(path, ": r\u00e5metadata st\u00e4mmer inte med slutligt ", valtyp,
           "-resultat.", call. = FALSE)
    }
    bas <- dplyr::filter(kandidater_bas, .data$valtyp == .env$valtyp)
    kd <- dplyr::filter(kandidaturdata, .data$valtyp == .env$valtyp)
    if (ar == 2022L) {
      .valda_fran_raw_2022(raw, kd, bas)
    } else {
      .valda_fran_raw_2026(raw, kd, bas)
    }
  }, .progress = progress) |> purrr::list_rbind()
  if (anyDuplicated(out[c("kandidatnummer", "valtyp", "partikod")])) {
    stop("Samma person valdes i flera slutliga resultatfiler.", call. = FALSE)
  }
  .valda_invaldsvalkrets_2026(out) |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
}

.valda_fran_raw_2022 <- function(raw, kandidaturdata, kandidater_bas) {
  normaliserad <- .normalisera_resultat_2022(raw)
  area <- normaliserad$valomrade
  noder <- if (length(area$valkretsLista)) area$valkretsLista else list(area)
  if (!.personrost_heltal(area$antalValdistriktRaknade) ||
      !.personrost_heltal(area$antalValdistriktSomSkaRaknas) ||
      area$antalValdistriktRaknade != area$antalValdistriktSomSkaRaknas ||
      !all(vapply(noder, function(nod) {
        .personrost_objekt(nod$valda) &&
          .personrost_array(nod$valda$partiLedamoterLista)
      }, logical(1)))) {
    stop("Slutlig invaldsrelation 2022 saknas eller \u00e4r inte verifierbart f\u00e4rdig.",
         call. = FALSE)
  }
  valda_data <- parse_valda_ersattare_2026(normaliserad)$valda |>
    dplyr::filter(kandidatnummer != "0")
  .valda_validera_nycklar(valda_data, kandidater_bas)
  bas <- dplyr::semi_join(kandidater_bas, valda_data,
    by = dplyr::join_by(kandidatnummer, valtyp, partikod))
  kd <- dplyr::semi_join(kandidaturdata, valda_data,
    by = dplyr::join_by(kandidatnummer, valtyp, partikod))
  parsed <- .kandidatresultat_raw_2022(raw, kd)
  .add_kandidatresultat_fran_parsade_2026(
    bas, kd, as_chr_na(normaliserad$valtyp), list(parsed)
  ) |> dplyr::filter(invald %in% TRUE)
}
