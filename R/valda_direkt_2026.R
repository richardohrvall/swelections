# En snabb resultatväg för kompletta slutliga mandatfiler.
.valda_mandat_komplett_2026 <- function(raw, omraden) {
  omrade <- raw$valomrade
  if (!identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle),
                 "slutlig") ||
      !isTRUE(.valda_available_2026(raw)) ||
      !.personrost_heltal(omrade$antalValdistriktRaknade) ||
      !.personrost_heltal(omrade$antalValdistriktSomSkaRaknas) ||
      omrade$antalValdistriktRaknade != omrade$antalValdistriktSomSkaRaknas ||
      !all(omraden$personval_available %in% TRUE)) return(FALSE)

  for (nod in omraden$.personval_nod) {
    roster <- nod$rostfordelning$rosterPaverkaMandat
    partier <- roster$partiRoster
    ovriga <- roster$rosterOvrigaPartier$antalRoster
    if (!.personrost_objekt(roster) || !.personrost_array(partier) ||
        !.personrost_heltal(roster$antalRoster) ||
        (!is.null(ovriga) && (!.personrost_heltal(ovriga) || ovriga != 0L)) ||
        !.personrost_heltal(nod$antalValdistriktRaknade) ||
        !.personrost_heltal(nod$antalValdistriktSomSkaRaknas) ||
        nod$antalValdistriktRaknade != nod$antalValdistriktSomSkaRaknas) {
      return(FALSE)
    }
    koder <- vapply(partier, function(p) as_chr_na(p$partikod), "")
    if (anyNA(koder) || anyDuplicated(koder) ||
        !all(vapply(partier, function(p) {
          .personrost_heltal(p$antalRoster) && .personrost_array(p$listRoster)
        }, logical(1)))) return(FALSE)
    if (sum(vapply(partier, function(p) p$antalRoster, 0L)) !=
        roster$antalRoster) return(FALSE)

    for (parti in partier) {
      komplett <- .personroster_validera_listor_2026(parti)
      if (!all(komplett %in% TRUE)) return(FALSE)
      summerade <- parti$summeradePersonroster
      if (is.null(summerade)) {
        med_personrost <- vapply(parti$listRoster,
          function(l) l$antalRosterMedPersonrost, 0L)
        if (any(med_personrost != 0L)) return(FALSE)
      } else if (is.null(.personrost_rader(summerade, "kandidatnummer"))) {
        return(FALSE)
      }
    }
  }
  TRUE
}

.valda_invaldsvalkrets_2026 <- function(out) {
  if (!all(c("valtyp", "valkretskod", "valkretsnamn",
             "invald_valkretskod", "invald_valkretsnamn") %in% names(out))) {
    return(out)
  }
  out$valkretskod <- out$invald_valkretskod
  out$valkretsnamn <- out$invald_valkretsnamn
  out
}

.valda_direkt_2026 <- function(source, data_dir, update, archive) {
  kandidaturdata <- kandidaturer(
    ar = 2026, val = "RD", source = source, data_dir = data_dir,
    update = update, archive = archive
  )
  kandidater_bas <- .kandidater_bas(kandidaturdata, 2026L)
  index <- .read_resultatindex_2026(source, data_dir, update, archive)
  paths <- .resultat_paths_2026(index, "RD")
  if (nrow(paths) != 1L) return(NULL)
  file <- .resultat_file_2026(paths$path[[1]], source, data_dir,
                              update, archive)
  mandat_raw <- read_raw_json_zip_2026(file, type = "mandatfordelning")
  if (!identical(as_chr_na(mandat_raw$valtyp), "RD")) return(NULL)
  .valda_fran_raw_2026(mandat_raw, kandidaturdata, kandidater_bas)
}

.valda_fran_raw_2026 <- function(mandat_raw, kandidaturdata,
                                 kandidater_bas) {
  omraden <- .personvalsomraden_mandat_2026(mandat_raw)
  if (!.valda_mandat_komplett_2026(mandat_raw, omraden)) {
    stop("Slutlig invaldsrelation 2026 saknas eller \u00e4r inte verifierbart f\u00e4rdig.",
         call. = FALSE)
  }

  valda_data <- parse_valda_ersattare_2026(mandat_raw)$valda
  .valda_validera_nycklar(valda_data, kandidater_bas)
  valda_bas <- dplyr::semi_join(
    kandidater_bas, valda_data,
    by = dplyr::join_by(kandidatnummer, valtyp, partikod)
  )

  summerade <- .personroster_summerade_omrade_2026(omraden)
  indelad <- any(!is.na(omraden$valkretskod))
  population <- kandidaturdata |>
    dplyr::filter(giltig %in% TRUE) |>
    dplyr::semi_join(valda_data,
      by = dplyr::join_by(kandidatnummer, valtyp, partikod)) |>
    dplyr::distinct(kandidatnummer, valtyp, partikod,
                    valomradeskod, valkretskod) |>
    dplyr::mutate(personvalsomradeskod = if (indelad) valkretskod else
      valomradeskod)
  partier <- .personval_partiroster_2026(omraden)
  if (nrow(dplyr::anti_join(
      population, partier,
      by = dplyr::join_by(personvalsomradeskod, partikod)))) {
    stop("Slutligt personr\u00f6stunderlag saknar relevant partirad.", call. = FALSE)
  }
  personrostomraden <- population |>
    dplyr::left_join(summerade,
      by = dplyr::join_by(kandidatnummer, partikod, personvalsomradeskod),
      relationship = "many-to-one") |>
    dplyr::mutate(antal_personroster =
      dplyr::coalesce(antal_personroster_omrade, 0L)) |>
    dplyr::select(kandidatnummer, valtyp, partikod, antal_personroster)

  personval <- parse_personval_2026(mandat_raw)
  parsed <- list(list(
    status = tibble::tibble(
      valtyp = as_chr_na(mandat_raw$valtyp),
      valomradeskod = as_chr_na(mandat_raw$valomrade$kod),
      valda_available = TRUE, personval_available = TRUE
    ),
    personrostomraden = personrostomraden,
    personval = personval,
    valda = valda_data
  ))
  .add_kandidatresultat_fran_parsade_2026(
    valda_bas, kandidaturdata, as_chr_na(mandat_raw$valtyp), parsed
  ) |>
    dplyr::filter(invald %in% TRUE)
}
