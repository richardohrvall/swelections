# IDs identify selected XML source observations, not people across lists/elections.
.xml2002_public_parties <- function(out) {
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  out
}

.xml2002_preference_rows <- function(nodes, doc, file, val, geo, info,
                                   party_votes, list = NULL) {
  out <- .xml2006_preference_rows(nodes, doc, file, val, geo, info, party_votes, list)
  if (is.null(out)) return(NULL)
  out$kandidatnummer <- sub("^2006:", "2002:", out$kandidatnummer)
  out$namn[] <- NA_character_
  .xml2002_metadata(out)
}

.xml2002_relations <- function(sources, val, progress = FALSE) {
  values <- if (is.null(val)) c("RD", "RF", "KF") else val
  parsed <- lapply(values, function(v) {
    purrr::map(.xml2002_files(sources, v, v == "KF"), function(file) {
      doc <- .xml2002_appointment_slots(.xml2002_read(sources, file, v), v)
      register <- .xml2002_register(doc, v, sources = sources)
      .xml2018_valda_ersattare_fil(doc, v, register)
    }, .progress = progress)
  }) |> unlist(recursive = FALSE)
  list(valda = .xml2002_metadata(purrr::map(parsed, "valda") |> purrr::list_rbind()),
    ersattare = .xml2002_metadata(purrr::map(parsed, "ersattare") |> purrr::list_rbind()))
}

.personroster_2002 <- function(sources, val, niva, per_lista,
                              komplettera_nollor, progress = FALSE) {
  if (!niva %in% c("personvalsomrade", "valdistrikt"))
    stop("2002 supports source preference-vote areas/districts, not person-linked broader aggregation.", call. = FALSE)
  values <- if (is.null(val)) c("RD", "RF", "KF") else val
  out <- lapply(values, function(v) {
    coverage <- if (v == "RD" && niva == "valdistrikt") .rd2002_result_coverage(sources) else NULL
    files <- if (is.null(coverage)) .xml2002_files(sources, v, niva == "valdistrikt" || v == "KF") else coverage$files
    parsed <- purrr::map(files, function(file) {
      doc <- .xml2002_read(sources, file, v)
      register <- .xml2002_register(doc, v, sources = sources)
      areas <- if (niva == "valdistrikt") .xml2002_nodes(doc, niva, v) else .xml2018_personomraden(doc, v)
      purrr::map(areas, function(area) {
        geo <- .xml2002_geography(sources, area, v, if (niva == "valdistrikt") niva else
          c(RD = "riksdagsvalkrets", RF = "regionvalkrets", KF = "kommunvalkrets")[[v]], doc)
        geo$area_code <- .xml2018_attr(area, "KOD")
        geo$area_name <- .xml2018_attr(area, "NAMN")
        if (niva == "valdistrikt") {
          parent <- if (v == "KF") xml2::xml_find_first(area, "ancestor::KRETS_KOMMUN[1]") else NULL
          geo$area_code <- if (v == "KF") .xml2018_attr(parent, "KOD") else
            if (v == "RF") geo$source_preference_area_code else geo$valkretskod
          geo$area_name <- if (v == "KF") .xml2018_attr(parent, "NAMN") else geo$valkretsnamn
        }
        if (v != "RD" && !is.na(geo$area_code) && endsWith(geo$area_code, "00")) {
          geo$area_code <- geo$valomradeskod
          geo$area_name <- geo$valomradesnamn
          geo$valkretskod <- NA_character_
          geo$valkretsnamn <- NA_character_
        }
        if (v == "KF") {
          geo$valkretskod <- geo$kommunvalkretskod
          geo$valkretsnamn <- geo$kommunvalkretsnamn
        }
        # Only direct area/district candidate records; nested list rows are another view.
        purrr::map(xml2::xml_find_all(area, "./GILTIGA"), function(party) {
          observed <- xml2::xml_find_all(party, if (per_lista) "./VALSEDEL/PERSONVAL" else "./PERSONVAL")
          if (!length(observed)) return(NULL)
          info <- if (.xml2018_attr(party, "PARTI") == "\u00d6VR")
            list(partikod = NA_character_, partiforkortning = "\u00d6VR", partibeteckning = "\u00d6vriga partier") else
            .xml2018_parti(.xml2018_attr(party, "PARTI"), v, geo$valomradeskod, register, party, area)
          votes <- .xml2018_int(party, "R\u00d6STER")
          if (!per_lista) return(.xml2002_preference_rows(xml2::xml_find_all(party, "./PERSONVAL"), doc, file, v, geo, info, votes))
          purrr::map(xml2::xml_find_all(party, "./VALSEDEL"), function(list) {
            nodes <- xml2::xml_find_all(list, "./PERSONVAL")
            counts <- as.integer(xml2::xml_attr(nodes, "PERSONKRYSS"))
            total <- .xml2018_int(list, "PERSONKRYSS")
            if (anyNA(counts) || (!is.na(total) && sum(as.double(counts)) != total))
              stop("2002 list person-vote records disagree with their source total: ", file,
                "; area ", geo$area_code, "; list ", .xml2018_attr(list, "LISTNUMMER"),
                "; reported ", total, "; observed ", sum(as.double(counts)), call. = FALSE)
            .xml2002_preference_rows(nodes, doc, file, v, geo, info, votes, list)
          }) |> purrr::list_rbind()
        }) |> purrr::list_rbind()
      }) |> purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
    if (!is.null(coverage) && length(coverage$missing)) parsed <- dplyr::bind_rows(parsed,
      .rd2002_preference_web(sources, coverage$missing, per_lista))
    parsed
  }) |> purrr::list_rbind()
  # No complete ballot/person population exists: preserve explicit zeros only.
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  out <- .kort_kommunnamn_2026(out)
  key <- intersect(c("valtyp", "kandidatnummer", "partikod", "personvalsomradeskod", "valdistriktskod", "listnummer"), names(out))
  if (anyDuplicated(out[key])) stop("Duplicate 2002 source preference-vote observation.", call. = FALSE)
  out
}

.xml2002_population <- function(sources, val, progress = FALSE) {
  pref <- .personroster_2002(sources, val, "personvalsomrade", FALSE, FALSE, progress)
  rel <- .xml2002_relations(sources, val, progress)
  evidence <- dplyr::bind_rows(pref, rel$valda,
    dplyr::rename(rel$ersattare, kandidatnummer = "ersattare_kandidatnummer", namn = "ersattare_namn")) |>
    dplyr::distinct(.data$valtyp, .data$partikod, .data$kandidatnummer, .keep_all = TRUE)
  raw <- .xml2006_candidacy_raw(nrow(evidence))
  for (field in intersect(names(raw), names(evidence))) raw[[field]] <- as.character(evidence[[field]])
  raw$namn[] <- NA_character_
  extra <- .xml2002_metadata(parse_kandidaturer_2026(raw, 2002L))
  list(population = extra, pref = pref, relations = rel)
}
.kandidater_2002 <- function(sources, val, resultat, progress = FALSE, bundle = NULL) {
  if (is.null(bundle)) bundle <- .xml2002_population(sources, val, progress)
  population <- bundle$population
  # Internal inclusion evidence is not a fabricated public validity attribute.
  population$giltig <- rep(TRUE, nrow(population))
  bas <- .kandidater_bas(population, 2002L)
  index <- match(bas$kandidatnummer, population$kandidatnummer)
  bas$namn <- population$namn[index]
  for (field in intersect(c("antal_kandidaturer", "antal_listor", "flera_listor", "antal_valomraden", "flera_valomraden", "antal_valkretsar"), names(bas))) bas[[field]][] <- NA
  # Counting distinct people/parties/elections is unsupported for these IDs.
  for (field in intersect(c("antal_partier", "flera_partier", "antal_valtyper", "flera_valtyper"), names(bas))) bas[[field]][] <- NA
  if (!resultat) return(.xml2002_public_parties(bas))
  status <- unique(population[c("valtyp", "valomradeskod", "valomradesnamn")])
  status$valda_available <- rep(FALSE, nrow(status))
  status$personval_available <- rep(FALSE, nrow(status))
  pref <- bundle$pref
  qualified <- unique(pref[pref$kvalificerad_personval %in% TRUE,
    c("kandidatnummer", "valtyp", "partikod", "valomradeskod", "valkretskod")])
  out <- .add_kandidatresultat_fran_parsade_2026(bas, population,
    unique(population$valtyp), list(list(status = status,
      personrostomraden = pref[c("kandidatnummer", "valtyp", "partikod", "antal_personroster")],
      personval = qualified, valda = bundle$relations$valda)))
  index <- match(out$kandidatnummer, pref$kandidatnummer)
  observed <- !is.na(index)
  out$kvalificerad_personval[observed] <- pref$kvalificerad_personval[index[observed]]
  .xml2002_public_parties(out)
}

.valda_2002 <- function(sources, val, progress = FALSE) {
  bundle <- .xml2002_population(sources, val, progress)
  .kandidater_2002(sources, val, TRUE, progress, bundle) |>
    dplyr::filter(.data$invald %in% TRUE) |>
    .valda_invaldsvalkrets_2026() |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
}

.ersattare_2002 <- function(sources, val, progress = FALSE) {
  out <- .xml2002_relations(sources, val, progress)$ersattare
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  .kort_kommunnamn_2026(out)
}
