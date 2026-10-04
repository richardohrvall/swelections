# 2018 års personröster finns på kandidatnivå och inom varje resultatlista.
# XML- och kandidaturkoderna för valkretsar har olika bredd; de sista två
# siffrorna i den officiella valkretskoden är kandidaturfilens delkod.
.xml2018_personomraden <- function(doc, val) {
  xml2::xml_find_all(doc, switch(val,
    RD = "./NATION/L\u00c4N/KRETS_RIKSDAG",
    RF = "./NATION/L\u00c4N/KRETS_LANDSTING",
    KF = "./KOMMUN/KRETS_KOMMUN"))
}

.xml2018_persongeo <- function(node, val, doc, niva) {
  if (niva == "personvalsomrade") {
    geoniva <- switch(val, RD = "riksdagsvalkrets",
      RF = "regionvalkrets", KF = "kommunvalkrets")
    geo <- .xml2018_geo(node, val, geoniva, doc)
    krets <- .xml2018_attr(node, "KOD")
    odelad <- val != "RD" && grepl("00$", krets)
    geo$valkretskod <- if (odelad) NA_character_ else krets
    geo$valkretsnamn <- if (odelad) NA_character_ else .xml2018_attr(node, "NAMN")
    geo$personvalsomradeskod <- if (odelad) geo$valomradeskod else krets
    geo$personvalsomradesnamn <- if (odelad) geo$valomradesnamn else
      .xml2018_attr(node, "NAMN")
    geo$geografiniva <- "personvalsomrade"
    return(geo)
  }
  geo <- .xml2018_geo(node, val, "valdistrikt", doc)
  krets <- xml2::xml_find_first(node, "ancestor::KRETS_KOMMUN[1]")
  omrades_krets <- if (val == "RF") .xml2018_attr(krets, "KRETS_LANDSTING") else
    if (val == "KF") .xml2018_attr(krets, "KOD") else NA_character_
  if (val == "RD") {
    # Alla län utom Stockholm, Skåne och Västra Götaland är en valkrets.
    # De län som är delade kräver separat officiell kodkoppling.
    lan <- geo$lankod
    if (lan %in% c("01", "12", "14")) {
      omrades_krets <- NA_character_
    } else {
      omrades_krets <- paste0(lan, lan)
    }
  }
  odelad <- val != "RD" && !is.na(omrades_krets) && grepl("00$", omrades_krets)
  geo$valkretskod <- if (odelad) NA_character_ else omrades_krets
  geo$valkretsnamn <- NA_character_
  geo$personvalsomradeskod <- if (odelad) geo$valomradeskod else omrades_krets
  geo$personvalsomradesnamn <- if (odelad) geo$valomradesnamn else NA_character_
  geo
}

.xml2018_person_parti <- function(node, geo, val, register) {
  info <- .xml2018_parti(.xml2018_attr(node, "PARTI"), val,
    geo$valomradeskod, register, node)
  listor <- xml2::xml_find_all(node, "./VALSEDEL|./PARTISEDEL")
  l_nummer <- xml2::xml_attr(listor, "LISTNUMMER")
  l_roster <- as.integer(xml2::xml_attr(listor, "R\u00d6STER"))
  l_person <- as.integer(xml2::xml_attr(listor, "PERSONKRYSS"))
  partisdel <- xml2::xml_name(listor) == "PARTISEDEL"
  l_person[partisdel & is.na(l_person)] <- 0L
  if (anyNA(l_nummer) || anyNA(l_roster) || anyNA(l_person) ||
      any(l_roster < 0L | l_person < 0L | l_person > l_roster) ||
      anyDuplicated(l_nummer)) {
    stop("Ogiltiga eller dubbla resultatlistor i 2018-XML.", call. = FALSE)
  }
  p_roster <- .xml2018_int(node, "R\u00d6STER")
  p_person <- .xml2018_int(node, "PERSONKRYSS")
  if (is.na(p_person) && length(listor) && all(l_person == 0L))
    p_person <- 0L
  if (is.na(p_person) && identical(p_roster, 0L) && !length(listor))
    p_person <- 0L
  if (is.na(p_roster) || is.na(p_person) || p_roster < 0L || p_person < 0L ||
      (length(listor) && (sum(l_roster) != p_roster ||
                          sum(l_person) != p_person))) {
    stop("Partiets listsummeringar st\u00e4mmer inte i 2018-XML.", call. = FALSE)
  }
  direct <- xml2::xml_find_all(node, "./PERSONVAL")
  d_id <- xml2::xml_attr(direct, "KANDNR")
  d_roster <- as.integer(xml2::xml_attr(direct, "PERSONKRYSS"))
  if (anyNA(d_id) || anyNA(d_roster) || any(d_roster < 0L) ||
      anyDuplicated(d_id) || sum(d_roster) != p_person) {
    stop("Partiets kandidatpersonr\u00f6ster st\u00e4mmer inte i 2018-XML.",
         call. = FALSE)
  }
  l_ids <- lapply(listor, function(l) xml2::xml_attr(
    xml2::xml_find_all(l, "./PERSONVAL"), "KANDNR"))
  l_tal <- lapply(listor, function(l) as.integer(xml2::xml_attr(
    xml2::xml_find_all(l, "./PERSONVAL"), "PERSONKRYSS")))
  for (j in seq_along(listor)) {
    if (anyNA(l_ids[[j]]) || anyNA(l_tal[[j]]) ||
        any(l_tal[[j]] < 0L) || anyDuplicated(l_ids[[j]]) ||
        sum(l_tal[[j]]) != l_person[[j]]) {
      stop("Listans kandidatpersonr\u00f6ster st\u00e4mmer inte i 2018-XML.",
           call. = FALSE)
    }
    if (grepl("-90000$", l_nummer[[j]]) &&
        (l_person[[j]] != 0L || length(l_ids[[j]]))) {
      stop("Kandidatpersonr\u00f6ster i 2018 \u00e5rs generella 90000-lista.",
           call. = FALSE)
    }
  }
  if (length(listor) && length(unlist(l_ids))) {
    listsumma <- tapply(unlist(l_tal), unlist(l_ids), sum)
    if (!identical(sort(names(listsumma)), sort(d_id)) ||
        any(as.integer(listsumma[d_id]) != d_roster)) {
      stop("Listvisa och summerade personr\u00f6ster skiljer sig i 2018-XML.",
           call. = FALSE)
    }
  }
  bas <- tibble::tibble(valtyp = val, valomradeskod = geo$valomradeskod,
    personvalsomradeskod = geo$personvalsomradeskod,
    partikod = info$partikod)
  parti <- dplyr::mutate(bas, antal_partiroster = p_roster,
    parti_complete = length(listor) > 0L || p_roster == 0L)
  lista <- if (!length(listor)) NULL else dplyr::mutate(
    bas[rep(1L, length(listor)), , drop = FALSE],
    listnummer = vapply(l_nummer, .personroster_listnummer_2026,
      "", partikod = info$partikod),
    antal_listroster = l_roster, list_complete = TRUE)
  roster <- if (!length(direct)) NULL else dplyr::mutate(
    bas[rep(1L, length(direct)), , drop = FALSE],
    kandidatnummer = d_id, antal_personroster = d_roster,
    kvalificerad_personval = ifelse(
      xml2::xml_attr(direct, "\u00d6VER_SP\u00c4RR") == "J", TRUE, FALSE))
  listroster <- if (!length(unlist(l_ids))) NULL else dplyr::mutate(
    bas[rep(1L, length(unlist(l_ids))), , drop = FALSE],
    listnummer = rep(if (is.null(lista)) character() else lista$listnummer,
      lengths(l_ids)),
    kandidatnummer = unlist(l_ids, use.names = FALSE),
    antal_personroster = as.integer(unlist(l_tal, use.names = FALSE)))
  list(parti = parti, lista = lista, roster = roster,
       listroster = listroster)
}

.xml2018_rd_krets_fran_listor <- function(doc, kandidaturdata) {
  kommun <- .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD")
  listor <- xml2::xml_find_all(doc,
    ".//VALDISTRIKT/GILTIGA/VALSEDEL|.//ONSDAGSDISTRIKT/GILTIGA/VALSEDEL|.//VALDISTRIKT/\u00d6VRIGA_GILTIGA/GILTIGA/VALSEDEL|.//ONSDAGSDISTRIKT/\u00d6VRIGA_GILTIGA/GILTIGA/VALSEDEL")
  raw <- tibble::tibble(
    raw = xml2::xml_attr(listor, "LISTNUMMER"),
    roster = as.integer(xml2::xml_attr(listor, "R\u00d6STER"))) |>
    dplyr::filter(!is.na(.data$raw), !is.na(.data$roster),
                  .data$roster >= 0L)
  entydiga <- attr(kandidaturdata, "rd_entydiga", exact = TRUE)
  if (is.null(entydiga)) entydiga <- .xml2018_rd_entydiga(kandidaturdata)
  score <- dplyr::inner_join(raw, entydiga, by = dplyr::join_by(raw),
    relationship = "many-to-one") |>
    dplyr::summarise(roster = sum(.data$roster),
                     .by = "valkretskod") |>
    dplyr::arrange(dplyr::desc(.data$roster))
  if (!nrow(score)) {
    stop("Riksdagsvalkrets kan inte kopplas via officiella listnummer f\u00f6r kommun ",
         kommun, ".", call. = FALSE)
  }
  if (nrow(score) > 1L && score$roster[[1]] == score$roster[[2]]) {
    stop("Riksdagsvalkrets kan inte best\u00e4mmas entydigt f\u00f6r kommun ",
         kommun, " utifr\u00e5n officiella listnummer.", call. = FALSE)
  }
  score$valkretskod[[1]]
}

.xml2018_rd_entydiga <- function(kandidaturdata) {
  kandidaturdata |>
    dplyr::filter(.data$valtyp == "RD", .data$giltig %in% TRUE,
                  .data$valsedelsstatus == "S",
                  !is.na(.data$listnummer), !is.na(.data$valkretskod)) |>
    dplyr::select(dplyr::all_of(c("partikod", "listnummer",
      "valkretskod"))) |>
    dplyr::distinct() |>
    dplyr::mutate(raw = paste(.data$partikod, .data$listnummer, sep = "-")) |>
    dplyr::mutate(n = dplyr::n_distinct(.data$valkretskod), .by = "raw") |>
    dplyr::filter(.data$n == 1L) |>
    dplyr::select(dplyr::all_of(c("raw", "valkretskod"))) |>
    dplyr::distinct()
}

.xml2018_person_fil <- function(doc, val, niva, register,
                                kandidaturdata = NULL, file_id = 1L) {
  noder <- if (niva == "personvalsomrade")
    .xml2018_personomraden(doc, val) else
    .xml2018_noder(doc, "valdistrikt", val)
  rd_krets <- if (niva == "valdistrikt" && val == "RD")
    .xml2018_rd_krets_fran_listor(doc, kandidaturdata) else NULL
  geos <- list()
  partier <- list()
  listor <- list()
  roster <- list()
  listroster <- list()
  for (i in seq_along(noder)) {
    node <- noder[[i]]
    geo <- .xml2018_persongeo(node, val, doc, niva)
    geo$valtyp <- val
    if (!is.null(rd_krets)) {
      geo$personvalsomradeskod <- paste0(geo$lankod, rd_krets)
      geo$valkretskod <- geo$personvalsomradeskod
    }
    geo$node_id <- as.integer((file_id - 1L) * 10000L + i)
    geos[[i]] <- tibble::as_tibble(geo)
    ps <- xml2::xml_find_all(node, "./GILTIGA|./\u00d6VRIGA_GILTIGA/GILTIGA")
    for (p in ps) {
      item <- .xml2018_person_parti(p, geo, val, register)
      item$parti$node_id <- geo$node_id
      partier[[length(partier) + 1L]] <- item$parti
      if (!is.null(item$lista)) {
        item$lista$node_id <- geo$node_id
        listor[[length(listor) + 1L]] <- item$lista
      }
      if (!is.null(item$roster)) {
        item$roster$node_id <- geo$node_id
        roster[[length(roster) + 1L]] <- item$roster
      }
      if (!is.null(item$listroster)) {
        item$listroster$node_id <- geo$node_id
        listroster[[length(listroster) + 1L]] <- item$listroster
      }
    }
  }
  list(geo = purrr::list_rbind(geos), parti = purrr::list_rbind(partier),
       lista = purrr::list_rbind(listor), roster = purrr::list_rbind(roster),
       listroster = purrr::list_rbind(listroster))
}

.xml2018_person_las <- function(val, niva, kandidaturdata, source, data_dir,
                               update, archive, progress) {
  zip <- .kalla_2018("resultat", source, data_dir, update, archive)
  register <- .xml2018_partiregister(.kalla_2018("partier", source,
    data_dir, update, archive))
  if (niva == "valdistrikt" && "RD" %in% val) {
    attr(kandidaturdata, "rd_entydiga") <-
      .xml2018_rd_entydiga(kandidaturdata)
  }
  filer <- purrr::map(val, function(valtyp) {
    members <- .xml2018_members(zip, valtyp,
      if (niva == "personvalsomrade" && valtyp != "KF") "riket" else "kommun")
    purrr::map2(members, seq_along(members), function(member, file_id) {
      doc <- .xml2018_fil(zip, member, valtyp)
      if (niva == "valdistrikt") {
        .xml2018_person_distrikt_fil(doc, valtyp, register,
          kandidaturdata, file_id)
      } else {
        .xml2018_person_fil(doc, valtyp, niva, register, kandidaturdata,
          file_id = file_id)
      }
    }, .progress = progress)
  }) |> unlist(recursive = FALSE)
  list(geo = purrr::map(filer, "geo") |> purrr::list_rbind(),
       parti = purrr::map(filer, "parti") |> purrr::list_rbind(),
       lista = purrr::map(filer, "lista") |> purrr::list_rbind(),
       roster = purrr::map(filer, "roster") |> purrr::list_rbind(),
       listroster = purrr::map(filer, "listroster") |> purrr::list_rbind())
}

.xml2018_person_population <- function(kd, geo) {
  index <- geo |>
    dplyr::mutate(.kretskort = ifelse(is.na(.data$valkretskod), "00",
      substring(.data$valkretskod, nchar(.data$valkretskod) - 1L))) |>
    dplyr::select(dplyr::all_of(c("valtyp", "valomradeskod",
      ".kretskort", "personvalsomradeskod"))) |>
    dplyr::distinct()
  if (anyDuplicated(index[c("valtyp", "valomradeskod", ".kretskort")])) {
    stop("2018 \u00e5rs personvalsomr\u00e5den har tvetydig valkretskoppling.",
         call. = FALSE)
  }
  pop <- kd |>
    dplyr::filter(.data$giltig %in% TRUE) |>
    dplyr::mutate(.kretskort = .data$valkretskod) |>
    dplyr::left_join(index, by = dplyr::join_by(valtyp, valomradeskod,
      .kretskort), relationship = "many-to-one")
  if (anyNA(pop$personvalsomradeskod)) {
    stop("Giltig kandidatur 2018 saknar entydigt personvalsomr\u00e5de.",
         call. = FALSE)
  }
  list(kandidat = pop |>
    dplyr::select(dplyr::all_of(c("valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod", "kandidatnummer"))) |>
    dplyr::distinct(),
    lista = pop |>
      dplyr::filter(!is.na(.data$listnummer), .data$listnummer != "90000") |>
      dplyr::select(dplyr::all_of(c("valtyp", "valomradeskod",
        "personvalsomradeskod", "partikod", "listnummer",
        "kandidatnummer"))) |>
      dplyr::distinct())
}

.xml2018_person_validera_raw <- function(raw, kd) {
  giltiga <- kd |>
    dplyr::filter(.data$giltig %in% TRUE) |>
    dplyr::select(dplyr::all_of(c("valtyp", "partikod",
      "kandidatnummer"))) |>
    dplyr::distinct()
  # XML kan innehålla identifierade namn som tillkommit under räkningen och
  # därför saknas helt i kandidaturfilen. Alla råposter och listsummeringar har
  # redan validerats före denna filtrering. Utan giltig kandidatur publiceras
  # ingen kandidatrad; rösterna får inte tilldelas en annan kandidat.
  giltiga
}

.xml2018_person_public <- function(raw, omraden, kd, niva, per_lista,
                                   komplettera_nollor) {
  giltiga <- .xml2018_person_validera_raw(raw, kd)
  bas <- .kandidater_bas(kd, 2018L) |>
    dplyr::select(dplyr::all_of(c("kandidatnummer", "valtyp", "partikod",
      "namn", "partiforkortning", "partibeteckning")))
  pop <- .xml2018_person_population(kd, omraden$geo)
  nyckel <- c("valtyp", "valomradeskod", "personvalsomradeskod",
              "partikod", "kandidatnummer")
  listnyckel <- c("valtyp", "valomradeskod", "personvalsomradeskod",
                  "partikod", "listnummer")
  partykey <- c("node_id", "valtyp", "valomradeskod",
                "personvalsomradeskod", "partikod")
  rawroster <- dplyr::semi_join(raw$roster, giltiga,
    by = dplyr::join_by(valtyp, partikod, kandidatnummer))
  rawlist <- dplyr::semi_join(raw$listroster, giltiga,
    by = dplyr::join_by(valtyp, partikod, kandidatnummer)) |>
    dplyr::filter(.data$listnummer != "90000")
  area_roster <- dplyr::semi_join(omraden$roster, giltiga,
    by = dplyr::join_by(valtyp, partikod, kandidatnummer))
  if (niva == "personvalsomrade" && !per_lista) {
    population <- dplyr::bind_rows(pop$kandidat,
      dplyr::select(rawroster, dplyr::all_of(nyckel))) |>
      dplyr::distinct()
    out <- population |>
      dplyr::left_join(dplyr::select(rawroster,
        dplyr::all_of(c(nyckel, "antal_personroster"))),
        by = nyckel, relationship = "one-to-one") |>
      dplyr::left_join(dplyr::select(raw$parti,
        -dplyr::any_of("node_id")),
        by = setdiff(partykey, "node_id"), relationship = "many-to-one") |>
      dplyr::mutate(antal_personroster = dplyr::case_when(
        !is.na(.data$antal_personroster) ~ .data$antal_personroster,
        .data$parti_complete %in% TRUE ~ 0L,
        .default = NA_integer_))
  } else if (per_lista) {
    out <- rawlist |>
      dplyr::left_join(raw$lista,
        by = c(partykey, "listnummer"), relationship = "many-to-one")
    if (komplettera_nollor) {
      nollor <- raw$lista |>
        dplyr::filter(.data$listnummer != "90000",
                      .data$list_complete %in% TRUE) |>
        dplyr::inner_join(pop$lista, by = listnyckel,
          relationship = "many-to-many") |>
        dplyr::anti_join(out, by = c(partykey, "listnummer",
                                      "kandidatnummer")) |>
        dplyr::mutate(antal_personroster = 0L)
      out <- dplyr::bind_rows(out, nollor)
    }
    out <- out |>
      dplyr::left_join(dplyr::select(raw$parti,
        dplyr::all_of(c(partykey, "antal_partiroster"))),
        by = partykey, relationship = "many-to-one")
  } else {
    out <- rawroster
    if (komplettera_nollor) {
      nollor <- raw$lista |>
        dplyr::filter(.data$listnummer != "90000",
                      .data$list_complete %in% TRUE) |>
        dplyr::inner_join(pop$lista, by = listnyckel,
          relationship = "many-to-many") |>
        dplyr::distinct(dplyr::across(dplyr::all_of(c(partykey,
          "kandidatnummer")))) |>
        dplyr::anti_join(out, by = c(partykey, "kandidatnummer")) |>
        dplyr::mutate(antal_personroster = 0L,
                      kvalificerad_personval = NA)
      out <- dplyr::bind_rows(out, nollor)
    }
    out <- out |>
      dplyr::left_join(dplyr::select(raw$parti,
        dplyr::all_of(c(partykey, "antal_partiroster"))),
        by = partykey, relationship = "many-to-one")
  }
  if (niva == "personvalsomrade") {
    out <- dplyr::left_join(out,
      dplyr::select(raw$geo, -dplyr::any_of("node_id")),
      by = c("valtyp", "valomradeskod", "personvalsomradeskod"),
      relationship = "many-to-one", suffix = c("", "_geo"))
  } else {
    out <- dplyr::left_join(out, raw$geo,
      by = c("node_id", "valtyp", "valomradeskod",
             "personvalsomradeskod"), relationship = "many-to-one",
      suffix = c("", "_geo")) |>
      dplyr::left_join(dplyr::select(omraden$geo,
        dplyr::all_of(c("valtyp", "valomradeskod",
          "personvalsomradeskod", "personvalsomradesnamn",
          "valkretsnamn"))),
        by = c("valtyp", "valomradeskod", "personvalsomradeskod"),
        relationship = "many-to-one", suffix = c("", "_omrade"))
    out$personvalsomradesnamn <- out$personvalsomradesnamn_omrade
    out$valkretsnamn <- out$valkretsnamn_omrade
  }
  kval <- area_roster |>
    dplyr::select(dplyr::all_of(nyckel),
                  dplyr::all_of("kvalificerad_personval")) |>
    dplyr::distinct()
  out <- out |>
    dplyr::left_join(kval, by = nyckel,
      relationship = "many-to-one", suffix = c("", "_officiell")) |>
    dplyr::left_join(bas, by = dplyr::join_by(kandidatnummer, valtyp,
      partikod), relationship = "many-to-one")
  if ("kvalificerad_personval_officiell" %in% names(out)) {
    out$kvalificerad_personval <- out$kvalificerad_personval_officiell
  }
  area_parti <- dplyr::select(omraden$parti,
    dplyr::all_of(c("valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod", "parti_complete")))
  area_status <- dplyr::left_join(dplyr::select(out,
    dplyr::all_of(nyckel)), area_parti,
    by = setdiff(nyckel, "kandidatnummer"),
    relationship = "many-to-one")$parti_complete
  out$kvalificerad_personval <- dplyr::case_when(
    out$kvalificerad_personval %in% TRUE ~ TRUE,
    area_status %in% TRUE ~ FALSE,
    .default = NA)
  out$valtillfalle <- "Val_2018"
  out$valar <- 2018L
  out$rakningstillfalle <- "slutlig"
  out$valdatum <- "2018-09-09"
  out$test <- FALSE
  out$namn <- NA_character_
  if (niva == "valdistrikt") {
    out$kommunnamn <- kommunnamn_2026$kommunnamn[
      match(out$kommunkod, kommunnamn_2026$kommunkod)]
  }
  out <- .kort_kommunnamn_2026(out)
  out <- .kort_kommunnamn_2026(out,
    kodkolumn = "personvalsomradeskod",
    namnkolumn = "personvalsomradesnamn",
    rader = out$valtyp == "KF" & is.na(out$valkretskod))
  out$andel_personroster <- dplyr::if_else(
    !is.na(out$antal_personroster) & !is.na(out$antal_partiroster) &
      out$antal_partiroster > 0L,
    out$antal_personroster / out$antal_partiroster, NA_real_)
  if (per_lista) out$andel_personroster_lista <- dplyr::if_else(
    !is.na(out$antal_personroster) & !is.na(out$antal_listroster) &
      out$antal_listroster > 0L,
    out$antal_personroster / out$antal_listroster, NA_real_)
  kolumner <- c("valtillfalle", "valar", "valtyp", "kandidatnummer",
    "namn", "partikod", if (per_lista) "listnummer",
    "partiforkortning", "partibeteckning", "geografiniva",
    if (niva == "valdistrikt") c("valdistriktskod", "valdistriktsnamn",
      "valdistriktstyp", "kommunkod", "kommunnamn", "lankod", "lannamn"),
    "personvalsomradeskod", "personvalsomradesnamn", "valomradeskod",
    "valomradesnamn", "valkretskod", "valkretsnamn",
    "antal_personroster", "antal_partiroster", "andel_personroster",
    if (per_lista) c("antal_listroster", "andel_personroster_lista"),
    "kvalificerad_personval", "rakningstillfalle", "valdatum", "test")
  out <- dplyr::select(out, dplyr::all_of(kolumner))
  key <- c("valar", "valtyp", "valomradeskod", "personvalsomradeskod",
    "partikod", "kandidatnummer",
    if (niva == "valdistrikt") c("kommunkod", "valdistriktskod",
      "valdistriktstyp"), if (per_lista) "listnummer")
  if (anyDuplicated(out[key])) {
    stop("Dubbla personr\u00f6stnycklar i 2018 \u00e5rs resultat.", call. = FALSE)
  }
  out
}

.personroster_ett_ar_2018 <- function(ar, val, source, data_dir, update,
                                      archive, progress, niva, per_lista,
                                      komplettera_nollor) {
  kd <- kandidaturer(detaljniva = "full", ar = 2018L, val = val, source = source,
    data_dir = data_dir, update = update, archive = archive)
  omraden <- .xml2018_person_las(val, "personvalsomrade", kd, source,
    data_dir, update, archive, progress)
  raw <- if (niva == "personvalsomrade") omraden else
    .xml2018_person_las(val, "valdistrikt", kd, source, data_dir,
      update, archive, progress)
  if (niva == "valdistrikt") {
    key <- c("valtyp", "valomradeskod", "personvalsomradeskod",
             "partikod", "kandidatnummer")
    dist <- raw$roster |>
      dplyr::summarise(distrikt = sum(.data$antal_personroster),
        .by = dplyr::all_of(key))
    area <- omraden$roster |>
      dplyr::select(dplyr::all_of(key),
                    omrade = "antal_personroster")
    kontroll <- dplyr::full_join(area, dist, by = key,
      relationship = "one-to-one")
    if (any(dplyr::coalesce(kontroll$omrade, 0L) !=
            dplyr::coalesce(kontroll$distrikt, 0L))) {
      stop("2018 \u00e5rs personr\u00f6ster st\u00e4mmer inte mellan personvalsomr\u00e5de och valdistrikt.",
           call. = FALSE)
    }
  }
  .xml2018_person_public(raw, omraden, kd, niva, per_lista,
                         komplettera_nollor) |>
    dplyr::arrange(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod,
      .data$kandidatnummer,
      dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
}
