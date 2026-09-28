# 2018 års slutresultat läses från XML, utan beroende av namngivna snapshots.
.xml2018_valda_ersattare_fil <- function(doc, val, register) {
  root <- xml2::xml_root(doc)
  omraden <- if (val == "KF") xml2::xml_find_all(doc, "./KOMMUN/KRETS_KOMMUN") else
    xml2::xml_find_all(doc, if (val == "RD")
      "./NATION/L\u00c4N/KRETS_RIKSDAG" else "./NATION/L\u00c4N/KRETS_LANDSTING")
  valda <- list()
  ersattare <- list()
  for (omrade in omraden) {
    geo <- .xml2018_geo(omrade, val, if (val == "RD") "riksdagsvalkrets" else
      if (val == "RF") "regionvalkrets" else "kommunvalkrets", doc)
    kretskod <- .xml2018_attr(omrade, "KOD")
    kretsnamn <- .xml2018_attr(omrade, "NAMN")
    if (val %in% c("RF", "KF") && grepl("00$", kretskod)) {
      kretskod <- NA_character_
      kretsnamn <- NA_character_
    }
    for (parti in xml2::xml_find_all(omrade,
        "./GILTIGA[GRUPP_VALDA]|./\u00d6VRIGA_GILTIGA/GILTIGA[GRUPP_VALDA]")) {
      info <- .xml2018_parti(.xml2018_attr(parti, "PARTI"), val,
        geo$valomradeskod, register, parti, omrade)
      for (grupp in xml2::xml_find_all(parti, "./GRUPP_VALDA")) {
        ledamoter <- xml2::xml_find_all(grupp, "./VALD")
        supp <- xml2::xml_find_all(grupp, "./ERS\u00c4TTARE")
        gruppnummer <- .xml2018_attr(grupp, "ORDNING")
        ids <- xml2::xml_attr(ledamoter, "KANDNR")
        namn <- xml2::xml_attr(ledamoter, "NAMN")
        platshallare <- is.na(ids) | !nzchar(ids)
        if (any(platshallare & (is.na(namn) | namn != "Kunde inte utses"))) {
          stop("Ok\u00e4nd platsmark\u00f6r i 2018 \u00e5rs invaldsrelation.",
               call. = FALSE)
        }
        if (all(platshallare)) next
        ids <- ids[!platshallare]
        ledamoter <- ledamoter[!platshallare]
        gemensamt <- tibble::tibble(
            valtillfalle = "Val_2018", valklass = NA_character_,
            rakningstillfalle = "slutlig", valtyp = val,
            valdatum = .xml2018_valdag(root, "VALDAG"),
            valdatum_fg = .xml2018_valdag(root, "VALDAG_FGVAL"),
            test = FALSE,
            geografiniva = if (is.na(kretskod))
              if (val == "KF") "kommun" else "region" else
              if (val == "RD") "riksdagsvalkrets" else
              if (val == "RF") "regionvalkrets" else "kommunvalkrets",
            valomradeskod = geo$valomradeskod,
            valomradesnamn = geo$valomradesnamn,
            valkretskod = kretskod, valkretsnamn = kretsnamn,
            partibeteckning = info$partibeteckning,
            partiforkortning = info$partiforkortning,
            partikod = info$partikod, partifarg = NA_character_)
        valda[[length(valda) + 1L]] <- dplyr::mutate(
            gemensamt[rep(1L, length(ids)), , drop = FALSE],
            kandidatnummer = ids, namn = NA_character_,
            invalsordning = as.integer(xml2::xml_attr(ledamoter, "ORDNING")),
            valgrund_id = xml2::xml_attr(ledamoter, "GRUND"),
            valgrund_text = NA_character_, ersattargrupp = gruppnummer)
        if (length(supp)) {
          led_index <- rep(seq_along(ids), each = length(supp))
          ers_index <- rep(seq_along(supp), times = length(ids))
          ersattare[[length(ersattare) + 1L]] <- dplyr::mutate(
            gemensamt[rep(1L, length(led_index)), , drop = FALSE],
            ledamot_kandidatnummer = ids[led_index],
            ledamot_namn = NA_character_,
            ersattargrupp = gruppnummer,
            ersattare_kandidatnummer =
              xml2::xml_attr(supp, "KANDNR")[ers_index],
            ersattare_namn = NA_character_,
            ersattarordning = as.integer(
              xml2::xml_attr(supp, "ORDNING")[ers_index]),
            valgrund_id = NA_character_, valgrund_text = NA_character_)
        }
      }
    }
  }
  list(valda = purrr::list_rbind(valda),
       ersattare = purrr::list_rbind(ersattare))
}

.xml2018_valda_ersattare <- function(val, source, data_dir, update,
                                    archive, progress) {
  zip <- .kalla_2018("resultat", source, data_dir, update, archive)
  register <- .xml2018_partiregister(.kalla_2018("partier", source,
    data_dir, update, archive))
  purrr::map(val, function(valtyp) {
    members <- .xml2018_members(zip, valtyp,
      if (valtyp == "KF") "kommun" else "riket", mandat = TRUE)
    purrr::map(members, function(member) {
      .xml2018_valda_ersattare_fil(.xml2018_fil(zip, member, valtyp),
                                   valtyp, register)
    }, .progress = progress)
  }) |> unlist(recursive = FALSE) |>
    (function(x) list(
      valda = purrr::map(x, "valda") |> purrr::list_rbind(),
      ersattare = purrr::map(x, "ersattare") |> purrr::list_rbind()
    ))()
}

.xml2018_kandidatresultat <- function(bas, kd, valda_data, source, data_dir,
                                     update, archive, progress) {
  val <- unique(bas$valtyp)
  omraden <- .personroster_ett_ar_2018(2018L, val, source, data_dir,
    update, archive, progress, "personvalsomrade", FALSE, FALSE)
  status <- kd |>
    dplyr::filter(.data$valtyp %in% val) |>
    dplyr::select(dplyr::all_of(c("valtyp", "valomradeskod",
      "valomradesnamn"))) |>
    dplyr::distinct() |>
    dplyr::mutate(valda_available = TRUE, personval_available = TRUE)
  personval <- omraden |>
    dplyr::filter(.data$kvalificerad_personval %in% TRUE) |>
    dplyr::select(dplyr::all_of(c("kandidatnummer", "valtyp",
      "partikod", "valomradeskod", "valkretskod"))) |>
    dplyr::distinct()
  parsed <- list(list(status = status,
    personrostomraden = dplyr::select(omraden,
      dplyr::all_of(c("kandidatnummer", "valtyp", "partikod",
        "antal_personroster"))),
    personval = personval, valda = valda_data))
  .add_kandidatresultat_fran_parsade_2026(bas, kd, val, parsed)
}

.add_kandidatresultat_2018 <- function(kandidater, kandidaturer, val, source,
                                       data_dir, update, archive, progress) {
  valda_data <- .xml2018_valda_ersattare(val, source, data_dir,
    update, archive, progress)$valda
  .valda_validera_nycklar(valda_data, kandidater)
  .xml2018_kandidatresultat(kandidater, kandidaturer, valda_data,
    source, data_dir, update, archive, progress)
}

.xml2018_valda_public <- function(valda_data, bas, kd, source, data_dir,
                                  update, archive, progress) {
  valda_bas <- dplyr::semi_join(bas, valda_data,
    by = dplyr::join_by(kandidatnummer, valtyp, partikod))
  out <- .xml2018_kandidatresultat(valda_bas, kd, valda_data,
    source, data_dir, update, archive, progress) |>
    dplyr::filter(.data$invald %in% TRUE)
  .valda_invaldsvalkrets_2026(out) |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
}
