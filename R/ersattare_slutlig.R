# Officiella ersattarrelationer lases direkt ur slutliga mandatfiler.
.ersattare_slutlig_komplett <- function(raw, ar) {
  if (!identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle),
                 "slutlig")) return(FALSE)
  omrade <- raw$valomrade
  if (!.personrost_heltal(omrade$antalValdistriktRaknade) ||
      !.personrost_heltal(omrade$antalValdistriktSomSkaRaknas) ||
      omrade$antalValdistriktRaknade != omrade$antalValdistriktSomSkaRaknas) {
    return(FALSE)
  }
  if (ar == 2026L && !isTRUE(.valda_available_2026(raw))) return(FALSE)
  niva <- .valda_kallval_2026(raw)$niva
  noder <- if (identical(niva, "valkrets")) omrade$valkretsLista else list(omrade)
  if (!length(noder)) return(FALSE)
  all(vapply(noder, function(nod) {
    if (!.personrost_heltal(nod$antalValdistriktRaknade) ||
        !.personrost_heltal(nod$antalValdistriktSomSkaRaknas) ||
        nod$antalValdistriktRaknade != nod$antalValdistriktSomSkaRaknas ||
        !.personrost_objekt(nod$valda) ||
        !.personrost_array(nod$valda$partiLedamoterLista) ||
        !length(nod$valda$partiLedamoterLista)) return(FALSE)
    all(vapply(nod$valda$partiLedamoterLista, function(parti) {
      if (!.personrost_array(parti$ledamoter)) return(FALSE)
      all(vapply(parti$ledamoter, function(ledamot) {
        if (identical(as_chr_na(ledamot$kandidatnummer), "0")) return(TRUE)
        .personrost_array(ledamot$ersattareList)
      }, logical(1)))
    }, logical(1)))
  }, logical(1)))
}

.ersattare_fran_raw <- function(raw, ar) {
  if (ar == 2022L) raw <- .normalisera_resultat_2022(raw)
  if (!.ersattare_slutlig_komplett(raw, ar)) {
    stop("Slutlig ers\u00e4ttarrelation saknas eller \u00e4r inte verifierbart f\u00e4rdig.",
         call. = FALSE)
  }
  out <- parse_valda_ersattare_2026(raw)$ersattare |>
    dplyr::filter(.data$ledamot_kandidatnummer != "0",
                  .data$ersattare_kandidatnummer != "0",
                  !is.na(.data$ledamot_kandidatnummer),
                  !is.na(.data$ersattare_kandidatnummer),
                  .data$ledamot_namn != "Kunde inte utses",
                  .data$ersattare_namn != "Kunde inte utses") |>
    dplyr::mutate(valar = as.integer(ar), .after = valtillfalle)
  nyckel <- c("valar", "valtyp", "geografiniva", "valomradeskod",
             "valkretskod", "partikod", "ledamot_kandidatnummer",
             "ersattare_kandidatnummer", "ersattarordning")
  if (anyDuplicated(out[nyckel])) {
    stop("Dubbla officiella ers\u00e4ttarrelationer i slutresultatet.",
         call. = FALSE)
  }
  out
}

.ersattare_validera_kandidater <- function(ersattare_data, kandidaturdata) {
  if (!nrow(ersattare_data)) return(invisible(NULL))
  kandidater <- kandidaturdata |>
    dplyr::filter(giltig %in% TRUE) |>
    dplyr::distinct(kandidatnummer, valtyp, partikod)
  for (kolumn in c("ledamot_kandidatnummer", "ersattare_kandidatnummer")) {
    relationer <- ersattare_data |>
      dplyr::transmute(kandidatnummer = .data[[kolumn]], valtyp, partikod) |>
      dplyr::distinct()
    if (nrow(dplyr::anti_join(relationer, kandidater,
        by = dplyr::join_by(kandidatnummer, valtyp, partikod)))) {
      stop("Officiell ers\u00e4ttarrelation saknar giltig kandidatur: ", kolumn,
           ".", call. = FALSE)
    }
  }
  invisible(NULL)
}

.ersattare_ett_ar <- function(ar, val, source, data_dir, update, archive,
                              progress) {
  source <- .select_public_source(source, ar, "ersattare", data_dir,
                                  update, archive)
  if (source %in% c("canonical", "canonical_auto"))
    return(.canonical_2018_source("ersattare", val,
      auto_selected = identical(source, "canonical_auto")))
  if (ar == 2018L) {
    out <- .xml2018_valda_ersattare(val, source, data_dir, update,
      archive, progress)$ersattare
    kd <- kandidaturer(ar = ar, val = val, source = source,
      data_dir = data_dir, update = update, archive = archive)
    .ersattare_validera_kandidater(out, kd)
    out <- dplyr::mutate(out, valar = 2018L, .after = valtillfalle)
    nyckel <- c("valar", "valtyp", "geografiniva", "valomradeskod",
      "valkretskod", "partikod", "ledamot_kandidatnummer",
      "ersattare_kandidatnummer", "ersattarordning")
    if (anyDuplicated(out[nyckel])) {
      stop("Dubbla officiella ers\u00e4ttarrelationer i 2018 \u00e5rs slutresultat.",
           call. = FALSE)
    }
    return(.kort_kommunnamn_2026(out) |>
      dplyr::select(dplyr::all_of(c(
        "valtillfalle", "valar", "valtyp", "partikod", "partiforkortning",
        "partibeteckning", "partifarg", "ledamot_kandidatnummer",
        "ledamot_namn", "ersattare_kandidatnummer", "ersattare_namn",
        "ersattarordning", "ersattargrupp", "valgrund_id", "valgrund_text",
        "geografiniva", "valomradeskod", "valomradesnamn", "valkretskod",
        "valkretsnamn", "valklass", "rakningstillfalle", "valdatum",
        "valdatum_fg", "test"))))
  }
  index <- .read_resultatindex(ar, source, data_dir, update, archive)
  paths <- .slutliga_mandat_paths(index, val, "ersattare")
  kandidaturdata <- kandidaturer(
    ar = ar, val = val, source = source, data_dir = data_dir,
    update = update, archive = archive
  )
  out <- purrr::map2(paths$path, paths$valtyp, function(path, valtyp) {
    file <- .resultat_file(ar, path, source, data_dir, update, archive)
    raw <- read_raw_json_zip_2026(file, type = "mandatfordelning")
    if (!identical(as_chr_na(raw$valtyp), valtyp)) {
      stop(path, ": fel valtyp i slutlig mandatfil.", call. = FALSE)
    }
    .ersattare_fran_raw(raw, ar)
  }, .progress = progress) |> purrr::list_rbind()
  .ersattare_validera_kandidater(out, kandidaturdata)
  out |>
    .kort_kommunnamn_2026() |>
    dplyr::select(dplyr::all_of(c(
      "valtillfalle", "valar", "valtyp", "partikod", "partiforkortning",
      "partibeteckning", "partifarg", "ledamot_kandidatnummer",
      "ledamot_namn", "ersattare_kandidatnummer", "ersattare_namn",
      "ersattarordning", "ersattargrupp", "valgrund_id", "valgrund_text",
      "geografiniva", "valomradeskod", "valomradesnamn", "valkretskod",
      "valkretsnamn", "valklass", "rakningstillfalle", "valdatum",
      "valdatum_fg", "test"
    )))
}
