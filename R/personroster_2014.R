# Only election-time XML is used here; membership snapshots are never inputs.
.xml2014_relations <- function(sources, val, progress = FALSE) {
  parsed <- lapply(val, function(v) {
    register <- .xml2014_register_all(sources, v)
    files <- .xml2014_members(sources, v, if (v == "KF") "kommun" else "riket", mandat = TRUE)
    purrr::map(files, function(f) {
      doc <- .xml2014_file(f, v)
      .xml2018_valda_ersattare_fil(doc, v, register)
    }, .progress = progress)
  }) |> unlist(recursive = FALSE)
  list(valda = .metadata_2014(purrr::map(parsed, "valda") |> purrr::list_rbind()),
    ersattare = .metadata_2014(purrr::map(parsed, "ersattare") |> purrr::list_rbind()))
}

.xml2014_person_read <- function(sources, val, niva, kd, progress = FALSE) {
  if (niva == "valdistrikt" && "RD" %in% val)
    attr(kd, "rd_entydiga") <- .xml2018_rd_entydiga(kd)
  parsed <- lapply(val, function(v) {
    register <- .xml2014_register_all(sources, v)
    files <- .xml2014_members(sources, v,
      if (niva == "personvalsomrade" && v != "KF") "riket" else "kommun")
    purrr::map2(files, seq_along(files), function(f, i) {
      doc <- .xml2014_consolidate_person(.xml2014_file(f, v))
      reg <- register
      if (niva == "valdistrikt")
        .xml2018_person_distrikt_fil(doc, v, reg, kd, i) else
        .xml2018_person_fil(doc, v, niva, reg, kd, i)
    }, .progress = progress)
  }) |> unlist(recursive = FALSE)
  stats::setNames(lapply(c("geo", "parti", "lista", "roster", "listroster"),
    function(n) purrr::map(parsed, n) |> purrr::list_rbind()),
    c("geo", "parti", "lista", "roster", "listroster"))
}

# This is internal population evidence, not fabricated public candidacies.
# Public candidacies retain the unsupported validity attribute as NA.
.xml2014_population <- function(kd, areas, relations) {
  key <- c("valtyp", "partikod", "kandidatnummer")
  observed <- dplyr::select(areas$roster,
    dplyr::all_of(c(key, "valomradeskod", "personvalsomradeskod"))) |>
    dplyr::left_join(areas$geo, by = c("valtyp", "valomradeskod", "personvalsomradeskod"),
      relationship = "many-to-one")
  elected <- relations$valda
  substitutes <- relations$ersattare |>
    dplyr::rename(kandidatnummer = "ersattare_kandidatnummer")
  evidence <- dplyr::bind_rows(observed, elected, substitutes) |>
    dplyr::distinct(dplyr::across(dplyr::all_of(c(key, "valomradeskod", "valkretskod"))),
      .keep_all = TRUE) |>
    dplyr::anti_join(kd, by = key)
  extra <- kd[rep(NA_integer_, nrow(evidence)), , drop = FALSE]
  for (n in intersect(names(evidence), names(extra))) extra[[n]] <- evidence[[n]]
  parties <- unique(kd[c("valtyp", "partikod", "partiforkortning", "partibeteckning")])
  one <- function(x) {
    x <- unique(x[!is.na(x)])
    if (length(x) == 1L) x else NA_character_
  }
  parties <- parties |>
    dplyr::summarise(partiforkortning = one(.data$partiforkortning),
      partibeteckning = one(.data$partibeteckning),
      .by = c("valtyp", "partikod"))
  party_index <- match(paste(extra$valtyp, extra$partikod),
    paste(parties$valtyp, parties$partikod))
  extra$partiforkortning <- dplyr::coalesce(extra$partiforkortning, parties$partiforkortning[party_index])
  extra$partibeteckning <- dplyr::coalesce(extra$partibeteckning, parties$partibeteckning[party_index])
  extra$valtillfalle <- rep("Val_2014", nrow(extra))
  extra$valar <- rep(2014L, nrow(extra))
  extra$valkretskod <- ifelse(is.na(evidence$valkretskod), "00",
    substring(evidence$valkretskod, nchar(evidence$valkretskod) - 1L))
  extra$namn <- rep(NA_character_, nrow(extra))
  out <- dplyr::bind_rows(kd, extra)
  out$giltig <- rep(TRUE, nrow(out))
  attr(out, "result_only_keys") <- unique(evidence[key])
  out
}

.xml2014_bundle <- function(sources, val, progress = FALSE) {
  if (is.null(val)) val <- c("RD", "RF", "KF")
  kd <- .read_candidacies_2014(sources, val)
  relations <- .xml2014_relations(sources, val, progress)
  areas <- .xml2014_person_read(sources, val, "personvalsomrade", kd, progress)
  population <- .xml2014_population(kd, areas, relations)
  list(kd = kd, population = population, areas = areas, relations = relations)
}

.personroster_2014 <- function(sources, val, niva, per_lista,
                              komplettera_nollor, progress, bundle = NULL) {
  if (is.null(bundle)) bundle <- .xml2014_bundle(sources, val, progress)
  raw <- if (niva == "personvalsomrade") bundle$areas else
    .xml2014_person_read(sources, val, niva, bundle$population, progress)
  out <- .metadata_2014(.xml2018_person_public(raw, bundle$areas,
    bundle$population, niva, per_lista, komplettera_nollor)) |>
    dplyr::arrange(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
      dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
  attr(out, "result_only_keys") <- NULL
  out[] <- lapply(out, unname)
  out
}

.kandidater_2014 <- function(sources, val, resultat, progress, bundle = NULL) {
  if (is.null(bundle)) bundle <- .xml2014_bundle(sources, val, progress)
  bas <- .kandidater_bas(bundle$population, 2014L)
  extra <- dplyr::semi_join(bas, attr(bundle$population, "result_only_keys"),
    by = c("valtyp", "partikod", "kandidatnummer"))
  hit <- paste(bas$valtyp, bas$partikod, bas$kandidatnummer) %in%
    paste(extra$valtyp, extra$partikod, extra$kandidatnummer)
  for (n in intersect(c("antal_listor", "flera_listor", "antal_valkretsar",
    "flera_valkretsar", "antal_valomraden", "flera_valomraden"), names(bas)))
    bas[[n]][hit] <- NA
  if (!resultat) return(bas)
  areas <- .personroster_2014(sources, val, "personvalsomrade", FALSE, FALSE,
    progress, bundle)
  status <- unique(bundle$population[c("valtyp", "valomradeskod", "valomradesnamn")]) |>
    dplyr::mutate(valda_available = TRUE, personval_available = TRUE)
  personval <- areas |>
    dplyr::filter(.data$kvalificerad_personval %in% TRUE) |>
    dplyr::select(dplyr::all_of(c("kandidatnummer", "valtyp", "partikod",
      "valomradeskod", "valkretskod"))) |> dplyr::distinct()
  parsed <- list(list(status = status,
    personrostomraden = areas[c("kandidatnummer", "valtyp", "partikod", "antal_personroster")],
    personval = personval, valda = bundle$relations$valda))
  .add_kandidatresultat_fran_parsade_2026(bas, bundle$population,
    unique(bundle$population$valtyp), parsed)
}

.valda_2014 <- function(sources, val, progress) {
  bundle <- .xml2014_bundle(sources, val, progress)
  out <- .kandidater_2014(sources, val, TRUE, progress, bundle) |>
    dplyr::filter(.data$invald %in% TRUE) |>
    .valda_invaldsvalkrets_2026() |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
  # Municipal abbreviations belong to the elected area's XML party, not the
  # national ballot register used for candidate enrichment.
  elected <- bundle$relations$valda
  index <- match(paste(out$valtyp, out$partikod, out$kandidatnummer,
                       out$invald_valomradeskod),
                 paste(elected$valtyp, elected$partikod,
                       elected$kandidatnummer, elected$valomradeskod))
  municipal <- which(out$valtyp == "KF")
  out$partiforkortning[municipal] <- dplyr::coalesce(
    elected$partiforkortning[index[municipal]], out$partiforkortning[municipal])
  out
}

.ersattare_2014 <- function(sources, val, progress) {
  out <- .xml2014_relations(sources, val, progress)$ersattare
  key <- c("valar", "valtyp", "valomradeskod", "valkretskod", "partikod",
    "ledamot_kandidatnummer", "ersattare_kandidatnummer", "ersattarordning")
  if (anyDuplicated(out[key])) stop("Duplicate 2014 substitute relation.", call. = FALSE)
  .kort_kommunnamn_2026(out)
}
