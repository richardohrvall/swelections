.resultatsamling_2026 <- function() {
  getOption(
    "swelections.resultatsamling_2026",
    getOption("valresultat.resultatsamling_2026", "val2026")
  )
}


.read_resultatindex_2026 <- function(
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE
) {
  .read_resultatindex(2026, match.arg(source), data_dir, update, archive)
}


.resultat_paths_2026 <- function(index, val) {
  out <- purrr::map_dfr(
    val,
    \(valtyp) {

      pattern <- dplyr::recode_values(
        valtyp,
        "RD" ~ "^s/rd/.*_00_RD\\.zip$",
        "RF" ~ "^s/rf/.*_[0-9]{2}_RF\\.zip$",
        "KF" ~ "^s/kf/.*_[0-9]{4}_KF\\.zip$"
      )

      index |>
        dplyr::filter(stringr::str_detect(path, pattern)) |>
        dplyr::transmute(
          valtyp = valtyp,
          path
        )
    }
  )
  saknas <- setdiff(val, unique(out$valtyp))
  if (length(saknas)) {
    stop("Hittade ingen slutlig resultatfil f\u00f6r: ",
         paste(saknas, collapse = ", "), ".", call. = FALSE)
  }
  filkod <- sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", out$path)
  if (anyDuplicated(paste(out$valtyp, filkod))) {
    stop("Dubbla resultatfiler f\u00f6r samma filidentitet.", call. = FALSE)
  }
  out
}


.resultat_file_2026 <- function(
    path,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE
) {
  .resultat_file(2026, path, match.arg(source), data_dir, update, archive)
}


.valda_nodstatus_2026 <- function(raw, obj) {
  if (!"valda" %in% names(obj) || is.null(obj$valda)) return(FALSE)
  if (!identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), "slutlig") ||
      !.personrost_heltal(obj$antalValdistriktRaknade) ||
      !.personrost_heltal(obj$antalValdistriktSomSkaRaknas) ||
      obj$antalValdistriktRaknade != obj$antalValdistriktSomSkaRaknas ||
      !.personrost_objekt(obj$valda) ||
      !.personrost_array(obj$valda$partiLedamoterLista) ||
      !.personrost_objekt(obj$mandatfordelning) ||
      !.personrost_array(obj$mandatfordelning$partiLista)) return(NA)
  mandat <- obj$mandatfordelning$partiLista
  valda <- obj$valda$partiLedamoterLista
  if (!all(vapply(mandat, function(p) .personrost_objekt(p) &&
      .personrost_id(p$partikod) && .personrost_heltal(p$antalMandat), logical(1))) ||
      !all(vapply(valda, function(p) .personrost_objekt(p) &&
      .personrost_id(p$partikod) && .personrost_array(p$ledamoter) &&
      .personrost_heltal(p$antalTommaStolar), logical(1)))) return(NA)
  mkod <- vapply(mandat, function(p) p$partikod, "")
  vkod <- vapply(valda, function(p) p$partikod, "")
  if (anyDuplicated(mkod) || anyDuplicated(vkod)) return(NA)
  for (p in valda) {
    ids <- vapply(p$ledamoter, function(x) as_chr_na(x$kandidatnummer), "")
    if (any(!nzchar(ids)) || anyDuplicated(ids)) return(NA)
    m <- mandat[[match(p$partikod, mkod)]]
    if (is.null(m) || length(p$ledamoter) + p$antalTommaStolar != m$antalMandat) return(NA)
  }
  positiva <- mkod[vapply(mandat, function(p) p$antalMandat > 0, logical(1))]
  if (!setequal(vkod, positiva)) return(NA)
  TRUE
}

.valda_kallval_2026 <- function(raw) {
  omrade <- raw$valomrade
  valkretsar <- omrade$valkretsLista
  if (.personrost_array(valkretsar) && length(valkretsar)) {
    states <- vapply(valkretsar, function(vk) .valda_nodstatus_2026(raw, vk), logical(1))
    if (all(states %in% FALSE)) {
      area <- .valda_nodstatus_2026(raw, omrade)
      return(list(niva = "valomrade", available = area))
    }
    return(list(niva = "valkrets", available = .personrost_status(states)))
  }
  list(niva = "valomrade", available = .valda_nodstatus_2026(raw, omrade))
}

.valda_available_2026 <- function(raw) {
  .valda_kallval_2026(raw)$available
}


.parse_kandidatresultat_fil_2026 <- function(
    path,
    valtyp,
    kandidaturer,
    kandidater,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    personroster_niva = "personvalsomrade",
    personroster_per_lista = FALSE,
    personroster_komplettera_nollor = FALSE
) {

  source <- match.arg(source)

  file <- .resultat_file_2026(
    path = path,
    source = source,
    data_dir = data_dir,
    update = update,
    archive = archive
  )

  rost_raw <- read_raw_json_zip_2026(
    file,
    type = "rostfordelning"
  )

  mandat_raw <- read_raw_json_zip_2026(
    file,
    type = "mandatfordelning"
  )

  personval <- parse_personval_2026(mandat_raw)
  valda_data <- parse_valda_ersattare_2026(mandat_raw)

  valomradeskod <- as_chr_na(mandat_raw$valomrade$kod)
  valomradesnamn <- as_chr_na(mandat_raw$valomrade$namn)

  personrostomraden <- if (personroster_niva == "personvalsomrade" &&
                           !personroster_per_lista) {
    .personrostomraden_2026(
      kandidaturer = kandidaturer, kandidater = kandidater,
      rost_raw = rost_raw, mandat_raw = mandat_raw
    )
  } else NULL
  personroster_utokad <- if (personroster_niva == "personvalsomrade" &&
                           !personroster_per_lista) NULL else {
    .personroster_utokad_2026(
      kandidaturer, kandidater, rost_raw, mandat_raw,
      personroster_niva, personroster_per_lista,
      personroster_komplettera_nollor
    )
  }

  list(
    status = tibble::tibble(
      valtyp = valtyp,
      valomradeskod = valomradeskod,
      valomradesnamn = valomradesnamn,
      valda_available = .valda_available_2026(mandat_raw),
      personval_available = attr(personval, "personval_available", exact = TRUE)
    ),
    personrostomraden = personrostomraden,
    personroster_utokad = personroster_utokad,
    personval = personval,
    valda = valda_data$valda
  )
}


.las_kandidatresultat_filer_2026 <- function(
    kandidaturer,
    kandidater,
    val,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive(),
    personroster_niva = "personvalsomrade",
    personroster_per_lista = FALSE,
    personroster_komplettera_nollor = FALSE
) {
  source <- match.arg(source)
  index <- .read_resultatindex_2026(
    source = source,
    data_dir = data_dir,
    update = update,
    archive = archive
  )
  paths <- .resultat_paths_2026(index = index, val = val)
  if (nrow(paths) == 0) {
    stop("Hittade inga slutliga resultatfiler f\u00f6r vald valtyp.", call. = FALSE)
  }
  purrr::map2(
    paths$path,
    paths$valtyp,
    \(path, valtyp) .parse_kandidatresultat_fil_2026(
      path = path,
      valtyp = valtyp,
      kandidaturer = kandidaturer,
      kandidater = kandidater,
      source = source,
      data_dir = data_dir,
      update = update,
      archive = archive,
      personroster_niva = personroster_niva,
      personroster_per_lista = personroster_per_lista,
      personroster_komplettera_nollor = personroster_komplettera_nollor
    ),
    .progress = progress
  )
}


.add_kandidatresultat_2026 <- function(
    kandidater,
    kandidaturer,
    val,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive()
) {

  source <- match.arg(source)

  parsed <- .las_kandidatresultat_filer_2026(
    kandidaturer = kandidaturer,
    kandidater = kandidater,
    val = val,
    source = source,
    data_dir = data_dir,
    update = update,
    archive = archive,
    progress = progress
  )

  .add_kandidatresultat_fran_parsade_2026(
    kandidater, kandidaturer, val, parsed
  )
}

.add_kandidatresultat_fran_parsade_2026 <- function(
    kandidater, kandidaturer, val, parsed
) {

  status <- parsed |>
    purrr::map("status") |>
    purrr::list_rbind()

  personrostomraden <- parsed |>
    purrr::map("personrostomraden") |>
    purrr::list_rbind()

  personroster <- .personrosttotaler_fran_omraden_2026(
    personrostomraden
  )

  personval <- parsed |>
    purrr::map("personval") |>
    purrr::list_rbind()

  valda <- parsed |>
    purrr::map("valda") |>
    purrr::list_rbind()

  kandidatomraden <- kandidaturer |>
    dplyr::filter(
      giltig %in% TRUE,
      valtyp %in% val
    ) |>
    dplyr::distinct(
      kandidatnummer,
      valtyp,
      partikod,
      valomradeskod
    ) |>
    dplyr::left_join(
      status,
      by = dplyr::join_by(
        valtyp,
        valomradeskod
      )
    ) |>
    dplyr::summarise(
      valda_available = .personrost_status(valda_available),
      personval_available = .personrost_status(personval_available),
      .by = c(
        kandidatnummer,
        valtyp,
        partikod
      )
    )

  if (nrow(personval) > 0) {
    personval_summary <- personval |>
      dplyr::mutate(
        .personvalsomrade = paste(
          valomradeskod,
          valkretskod,
          sep = "/"
        )
      ) |>
      dplyr::summarise(
        kvalificerad_personval_found = TRUE,
        antal_personvalsomraden =
          dplyr::n_distinct(.personvalsomrade),
        .by = c(
          kandidatnummer,
          valtyp,
          partikod
        )
      )
  } else {
    personval_summary <- tibble::tibble(
      kandidatnummer = character(),
      valtyp = character(),
      partikod = character(),
      kvalificerad_personval_found = logical(),
      antal_personvalsomraden = integer()
    )
  }

  if (nrow(valda) > 0) {

    dubbla_inval <- valda |>
      dplyr::count(
        kandidatnummer,
        valtyp,
        partikod,
        name = "n"
      ) |>
      dplyr::filter(n > 1)

    if (nrow(dubbla_inval) > 0) {
      stop(
        "Minst en kandidat \u00e4r vald mer \u00e4n en g\u00e5ng inom samma valtyp och parti. ",
        "Det kr\u00e4ver en mer detaljerad kandidatmodell.",
        call. = FALSE
      )
    }

    valda_summary <- valda |>
      dplyr::transmute(
        kandidatnummer,
        valtyp,
        partikod,
        invald_found = TRUE,
        invald_valomradeskod = valomradeskod,
        invald_valomradesnamn = valomradesnamn,
        invald_valkretskod = valkretskod,
        invald_valkretsnamn = valkretsnamn,
        invalsordning,
        valgrund_id,
        valgrund_text,
        ersattargrupp
      )
  } else {
    valda_summary <- tibble::tibble(
      kandidatnummer = character(),
      valtyp = character(),
      partikod = character(),
      invald_found = logical(),
      invald_valomradeskod = character(),
      invald_valomradesnamn = character(),
      invald_valkretskod = character(),
      invald_valkretsnamn = character(),
      invalsordning = integer(),
      valgrund_id = character(),
      valgrund_text = character(),
      ersattargrupp = character()
    )
  }

  kandidater |>
    dplyr::left_join(
      kandidatomraden,
      by = dplyr::join_by(
        kandidatnummer,
        valtyp,
        partikod
      )
    ) |>
    dplyr::left_join(
      personroster,
      by = dplyr::join_by(
        kandidatnummer,
        valtyp,
        partikod
      )
    ) |>
    dplyr::left_join(
      personval_summary,
      by = dplyr::join_by(
        kandidatnummer,
        valtyp,
        partikod
      )
    ) |>
    dplyr::left_join(
      valda_summary,
      by = dplyr::join_by(
        kandidatnummer,
        valtyp,
        partikod
      )
    ) |>
    dplyr::mutate(
      kvalificerad_personval = dplyr::case_when(
        kvalificerad_personval_found %in% TRUE ~ TRUE,
        personval_available %in% TRUE ~ FALSE,
        .default = NA
      ),
      antal_personvalsomraden = dplyr::case_when(
        kvalificerad_personval_found %in% TRUE ~
          antal_personvalsomraden,
        personval_available %in% TRUE ~ 0L,
        .default = NA_integer_
      ),
      invald = dplyr::case_when(
        invald_found %in% TRUE ~ TRUE,
        valda_available %in% TRUE ~ FALSE,
        .default = NA
      )
    ) |>
    dplyr::select(
      -valda_available,
      -personval_available,
      -kvalificerad_personval_found,
      -invald_found
    ) |>
    dplyr::relocate(
      dplyr::all_of(c(
        "antal_personroster_totalt",
        "kvalificerad_personval",
        "antal_personvalsomraden",
        "invald",
        "invald_valomradeskod",
        "invald_valomradesnamn",
        "invald_valkretskod",
        "invald_valkretsnamn",
        "invalsordning",
        "valgrund_id",
        "valgrund_text",
        "ersattargrupp"
      )),
      .after = dplyr::any_of("namn")
    ) |>
    .kort_kommunnamn_2026(
      kodkolumn = "invald_valomradeskod",
      namnkolumn = "invald_valomradesnamn"
    )
}
