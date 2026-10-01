# 2022 har inga summeradePersonroster. Varje officiell niva lases for sig.
.personroster_2022_kallrader <- function(noder, geo, strikt_listtotal = TRUE) {
  partier_per_nod <- lapply(noder, function(nod) {
    rost <- nod$rostfordelning
    if (!.personrost_objekt(rost)) {
      stop("Slutlig r\u00f6stf\u00f6rdelning 2022 saknas.", call. = FALSE)
    }
    p <- rost$rosterPaverkaMandat$partiRoster
    e <- rost$rosterEjPaverkaMandat$partiRoster
    if (is.null(e) && .personrost_objekt(rost$rosterEjPaverkaMandat)) {
      e <- list()
    }
    if (!.personrost_array(p) || !.personrost_array(e)) {
      stop("Ogiltiga partirader i 2022 \u00e5rs r\u00f6stf\u00f6rdelning.",
           call. = FALSE)
    }
    c(p, e)
  })
  partier <- unlist(partier_per_nod, recursive = FALSE, use.names = FALSE)
  p_nod <- rep(seq_along(noder), lengths(partier_per_nod))
  p_kod <- vapply(partier, function(p) as_chr_na(p$partikod), "")
  p_rost <- vapply(partier, function(p) as_int_na(p$antalRoster), 0L)
  if (anyNA(p_kod) || anyNA(p_rost) || any(p_rost < 0L) ||
      anyDuplicated(paste(p_nod, p_kod))) {
    stop("Ogiltiga eller dubbla partirader 2022.", call. = FALSE)
  }
  listor_per_parti <- lapply(seq_along(partier), function(i) {
    l <- partier[[i]]$listRoster
    if (is.null(l) && p_rost[[i]] == 0L) return(list())
    if (!.personrost_array(l)) {
      stop("Ogiltig listRoster-struktur 2022.", call. = FALSE)
    }
    l
  })
  listor <- unlist(listor_per_parti, recursive = FALSE, use.names = FALSE)
  l_parti <- rep(seq_along(partier), lengths(listor_per_parti))
  l_kod <- vapply(listor, function(l) as_chr_na(l$listnummer), "")
  l_roster <- vapply(listor, function(l) as_int_na(l$antalRoster), 0L)
  l_person <- vapply(listor, function(l) as_int_na(l$antalRosterMedPersonrost), 0L)
  if (anyNA(l_kod) || anyNA(l_roster) || any(l_roster < 0L) ||
      anyNA(l_person) || any(l_person < 0L) ||
      anyDuplicated(paste(l_parti, l_kod))) {
    stop("Ogiltiga eller dubbla resultatlistor 2022.", call. = FALSE)
  }
  kort <- vapply(seq_along(listor), function(i) {
    .personroster_listnummer_2026(l_kod[[i]], p_kod[[l_parti[[i]]]])
  }, "")
  avstamda <- vapply(seq_along(partier), function(i) {
    sum(l_roster[l_parti == i]) != p_rost[[i]]
  }, logical(1))
  if (strikt_listtotal && any(avstamda)) {
    stop("Resultatlistornas r\u00f6ster st\u00e4mmer inte med partiets r\u00f6ster 2022.",
         call. = FALSE)
  }
  person_per_lista <- lapply(listor, function(l) l$personroster)
  fullstandiga <- vapply(person_per_lista, .personrost_array, logical(1))
  for (i in which(fullstandiga)) {
    poster <- person_per_lista[[i]]
    ids <- vapply(poster, function(x) as_chr_na(x$kandidatNummer), "")
    tal <- vapply(poster, function(x) as_int_na(x$antalPersonroster), 0L)
    if (anyNA(ids) || anyNA(tal) || any(tal < 0L) ||
        anyDuplicated(ids) || sum(tal) != l_person[[i]]) {
      stop("Listans personr\u00f6ster st\u00e4mmer inte med r\u00e4knaren 2022.",
           call. = FALSE)
    }
  }
  ovriga <- which(kort == "90000")
  if (length(ovriga) && any(vapply(ovriga, function(i) {
    !fullstandiga[[i]] || l_person[[i]] != 0L ||
      length(person_per_lista[[i]]) != 0L
  }, logical(1)))) {
    stop("Resultatlistan 90000 inneh\u00e5ller kandidatpersonr\u00f6ster eller \u00e4r ofullst\u00e4ndig.",
         call. = FALSE)
  }
  person_per_lista[!fullstandiga] <- rep(list(list()), sum(!fullstandiga))
  poster <- unlist(person_per_lista, recursive = FALSE, use.names = FALSE)
  r_lista <- rep(seq_along(listor), lengths(person_per_lista))
  parti <- tibble::tibble(
    party_id = seq_along(partier), node_id = p_nod,
    partikod = p_kod, antal_partiroster = p_rost,
    parti_complete = vapply(seq_along(partier), function(i) {
      all(fullstandiga[l_parti == i]) && !avstamda[[i]]
    }, logical(1))
  ) |>
    dplyr::left_join(geo, by = dplyr::join_by(node_id),
                     relationship = "many-to-one")
  lista <- tibble::tibble(
    list_id = seq_along(listor), party_id = l_parti,
    listnummer_raw = l_kod, listnummer = kort,
    antal_listroster = l_roster, list_complete = fullstandiga
  ) |>
    dplyr::left_join(parti, by = dplyr::join_by(party_id),
                     relationship = "many-to-one")
  rost <- tibble::tibble(
    list_id = r_lista,
    kandidatnummer = vapply(poster,
      function(x) as_chr_na(x$kandidatNummer), ""),
    kandidatnamn_raw = vapply(poster,
      function(x) as_chr_na(x$namn), ""),
    antal_personroster = vapply(poster,
      function(x) as_int_na(x$antalPersonroster), 0L)
  ) |>
    dplyr::left_join(lista, by = dplyr::join_by(list_id),
                     relationship = "many-to-one")
  list(parti = parti, lista = lista, roster = rost)
}

.personroster_2022_geografi <- function(mandat_raw, rost_raw = NULL) {
  omraden <- .personvalsomraden_mandat_2026(mandat_raw)
  indelad <- all(!is.na(omraden$valkretskod))
  if (is.null(rost_raw)) {
    geo <- omraden |>
      dplyr::mutate(node_id = dplyr::row_number(),
        valtyp = as_chr_na(mandat_raw$valtyp),
        ovriga_complete = vapply(.data$.personval_nod, function(nod) {
          o <- nod$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier
          .personrost_objekt(o) && .personrost_heltal(o$antalRoster)
        }, logical(1)), .before = 1) |>
      dplyr::select(-personval_available, -.personval_nod)
    return(list(noder = omraden$.personval_nod, geo = geo,
                omraden = omraden, indelad = indelad))
  }
  noder <- rost_raw$valdistrikt
  if (!.personrost_array(noder) || !length(noder) ||
      length(noder) != mandat_raw$valomrade$antalValdistriktSomSkaRaknas) {
    stop("Slutlig distriktsfil 2022 saknas eller har fel antal distrikt.",
         call. = FALSE)
  }
  geo <- tibble::tibble(
    node_id = seq_along(noder),
    valtyp = as_chr_na(mandat_raw$valtyp),
    valomradeskod = vapply(noder, function(x) as_chr_na(x$valomradeskod), ""),
    personvalsomradeskod = if (indelad) vapply(noder,
      function(x) as_chr_na(x$kretskod), "") else
      rep(omraden$valomradeskod[[1]], length(noder)),
    valdistriktskod = vapply(noder, function(x) as_chr_na(x$valdistriktskod), ""),
    valdistriktsnamn = vapply(noder, function(x) as_chr_na(x$namn), ""),
    valdistriktstyp = vapply(noder, function(x) as_chr_na(x$valdistriktstyp), ""),
    kommunkod = vapply(noder, function(x) as_chr_na(x$kommunkod), ""),
    lankod = vapply(noder, function(x) as_chr_na(x$lankod), "")
  ) |>
    dplyr::left_join(dplyr::select(omraden, personvalsomradeskod,
      personvalsomradesnamn, valkretskod, valkretsnamn,
      valomradesnamn), by = dplyr::join_by(personvalsomradeskod),
      relationship = "many-to-one") |>
    dplyr::mutate(geografiniva = "valdistrikt")
  if (anyNA(geo[c("valomradeskod", "personvalsomradeskod",
                  "valdistriktskod", "kommunkod")]) ||
      any(geo$valomradeskod != omraden$valomradeskod[[1]]) ||
      anyDuplicated(geo[c("valomradeskod", "kommunkod",
                          "valdistriktskod", "valdistriktstyp")]) ||
      anyNA(geo$personvalsomradesnamn)) {
    stop("Distriktets officiella geografi st\u00e4mmer inte med mandatfilen.",
         call. = FALSE)
  }
  list(noder = noder, geo = geo, omraden = omraden, indelad = indelad)
}

.personroster_2022_population <- function(kandidaturer, indelad,
                                          alla_kandidaturer = kandidaturer) {
  giltiga <- kandidaturer |>
    dplyr::filter(.data$giltig %in% TRUE) |>
    dplyr::mutate(personvalsomradeskod = if (indelad) .data$valkretskod else
      .data$valomradeskod)
  kandidat <- giltiga |>
    dplyr::distinct(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer)
  lista <- giltiga |>
    dplyr::filter(!is.na(.data$listnummer), .data$listnummer != "90000") |>
    dplyr::distinct(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$listnummer,
      .data$kandidatnummer)
  alla <- kandidaturer |>
    dplyr::mutate(personvalsomradeskod = if (indelad) .data$valkretskod else
      .data$valomradeskod) |>
    dplyr::distinct(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer)
  global_nyckel <- c("valtyp", "partikod", "kandidatnummer")
  list(kandidat = kandidat, lista = lista, alla = alla,
       giltiga_globalt = dplyr::distinct(dplyr::filter(alla_kandidaturer,
         .data$giltig %in% TRUE), dplyr::across(dplyr::all_of(global_nyckel))),
       alla_globalt = dplyr::distinct(alla_kandidaturer,
         dplyr::across(dplyr::all_of(global_nyckel))))
}

.personroster_2022_kontrollera_poster <- function(roster, population) {
  if (!nrow(roster)) return(invisible(NULL))
  okanda <- dplyr::anti_join(roster, population$alla_globalt,
    by = dplyr::join_by(valtyp, partikod, kandidatnummer))
  if (nrow(okanda) &&
      any(is.na(okanda$kandidatnamn_raw) |
          okanda$kandidatnamn_raw != "[Ej valbar]")) {
    stop("Officiell personr\u00f6stpost 2022 saknar kandidatur i omr\u00e5det.",
         call. = FALSE)
  }
  invisible(NULL)
}

.personroster_2022_observerade <- function(population, roster) {
  extra <- roster |>
    dplyr::semi_join(population$giltiga_globalt,
      by = dplyr::join_by(valtyp, partikod, kandidatnummer)) |>
    dplyr::distinct(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer)
  population$kandidat <- dplyr::bind_rows(population$kandidat, extra) |>
    dplyr::distinct()
  population
}

.personroster_2022_omrade <- function(kallor, population, geo,
                                     per_lista, komplettera_nollor) {
  nyckel <- c("valtyp", "valomradeskod", "personvalsomradeskod",
              "partikod", "kandidatnummer")
  listnyckel <- c("valtyp", "valomradeskod", "personvalsomradeskod",
                  "partikod", "listnummer")
  partier <- kallor$parti |>
    dplyr::select(dplyr::all_of(c("valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod", "antal_partiroster",
      "parti_complete")))
  listor <- kallor$lista |>
    dplyr::filter(.data$listnummer != "90000")
  roster <- dplyr::semi_join(kallor$roster, population$kandidat,
    by = nyckel)
  if (!per_lista) {
    summerat <- roster |>
      dplyr::summarise(antal_personroster_observerat = as.integer(
        sum(.data$antal_personroster)), .by = dplyr::all_of(nyckel))
    out <- population$kandidat |>
      dplyr::left_join(geo, by = dplyr::join_by(valtyp, valomradeskod,
        personvalsomradeskod), relationship = "many-to-one") |>
      dplyr::left_join(partier, by = c("valtyp", "valomradeskod",
        "personvalsomradeskod", "partikod"), relationship = "many-to-one") |>
      dplyr::left_join(summerat, by = nyckel, relationship = "one-to-one") |>
      dplyr::mutate(antal_personroster = dplyr::case_when(
        .data$parti_complete %in% TRUE &
          !is.na(.data$antal_personroster_observerat) ~
          .data$antal_personroster_observerat,
        .data$parti_complete %in% TRUE ~ 0L,
        is.na(.data$parti_complete) & .data$ovriga_complete %in% TRUE ~ 0L,
        .default = NA_integer_
      ))
    return(out)
  }
  out <- roster
  if (!komplettera_nollor) return(out)
  listmeta <- listor |>
    dplyr::select(dplyr::all_of(c(listnyckel, "antal_listroster",
      "list_complete", "antal_partiroster"))) |>
    dplyr::distinct()
  nollor <- population$lista |>
    dplyr::anti_join(out, by = c(listnyckel, "kandidatnummer")) |>
    dplyr::left_join(listmeta, by = listnyckel, relationship = "many-to-one") |>
    dplyr::left_join(partier, by = c("valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod"), relationship = "many-to-one",
      suffix = c("", "_parti")) |>
    dplyr::left_join(geo, by = dplyr::join_by(valtyp, valomradeskod,
      personvalsomradeskod), relationship = "many-to-one") |>
    dplyr::filter(.data$list_complete %in% TRUE |
      (is.na(.data$list_complete) &
         (.data$parti_complete %in% TRUE |
          .data$ovriga_complete %in% TRUE))) |>
    dplyr::mutate(
      antal_personroster = 0L,
      antal_listroster = dplyr::coalesce(.data$antal_listroster, 0L),
      antal_partiroster = dplyr::coalesce(.data$antal_partiroster,
                                         .data$antal_partiroster_parti)
    )
  dplyr::bind_rows(out, nollor)
}

.personroster_2022_distrikt <- function(kallor, population, per_lista,
                                       komplettera_nollor) {
  listnyckel <- c("valtyp", "valomradeskod", "personvalsomradeskod",
                  "partikod", "listnummer")
  nyckel <- c("node_id", "valtyp", "valomradeskod",
              "personvalsomradeskod", "partikod", "kandidatnummer")
  listor <- dplyr::filter(kallor$lista, .data$listnummer != "90000")
  roster <- dplyr::semi_join(kallor$roster, population$kandidat,
    by = dplyr::join_by(valtyp, valomradeskod, personvalsomradeskod,
                        partikod, kandidatnummer))
  if (per_lista) {
    if (!komplettera_nollor) return(roster)
    nollor <- listor |>
      dplyr::inner_join(population$lista, by = listnyckel,
                        relationship = "many-to-many") |>
      dplyr::anti_join(roster, by = c(listnyckel, "node_id",
                                     "kandidatnummer")) |>
      dplyr::filter(.data$list_complete %in% TRUE) |>
      dplyr::mutate(antal_personroster = 0L)
    return(dplyr::bind_rows(roster, nollor))
  }
  summerat <- roster |>
    dplyr::summarise(antal_personroster = as.integer(
      sum(.data$antal_personroster)), .by = dplyr::all_of(nyckel))
  geo <- kallor$parti |>
    dplyr::select(dplyr::all_of(c("node_id", "valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod", "antal_partiroster",
      "parti_complete",
      "valdistriktskod", "valdistriktsnamn", "valdistriktstyp",
      "kommunkod", "lankod", "valomradesnamn", "personvalsomradesnamn",
      "valkretskod", "valkretsnamn", "geografiniva")))
  out <- dplyr::left_join(summerat, geo,
    by = c("node_id", "valtyp", "valomradeskod",
           "personvalsomradeskod", "partikod"), relationship = "many-to-one") |>
    dplyr::mutate(antal_personroster = dplyr::if_else(
      .data$parti_complete %in% TRUE, .data$antal_personroster,
      NA_integer_))
  if (!komplettera_nollor) return(out)
  nollor <- listor |>
    dplyr::inner_join(population$lista, by = listnyckel,
                      relationship = "many-to-many") |>
    dplyr::summarise(alla_listor_kompletta =
      all(.data$list_complete %in% TRUE & .data$parti_complete %in% TRUE),
      .by = dplyr::all_of(nyckel)) |>
    dplyr::filter(.data$alla_listor_kompletta) |>
    dplyr::anti_join(out, by = nyckel) |>
    dplyr::left_join(geo, by = c("node_id", "valtyp", "valomradeskod",
      "personvalsomradeskod", "partikod"), relationship = "many-to-one") |>
    dplyr::mutate(antal_personroster = 0L)
  dplyr::bind_rows(out, nollor)
}

.personroster_2022_fil <- function(ar, path, valtyp, kandidaturdata,
                                   kandidater_bas, source, data_dir, update,
                                   archive, niva, per_lista,
                                   komplettera_nollor) {
  file <- .resultat_file(ar, path, source, data_dir, update, archive)
  if (niva == "valdistrikt" && grepl("^https?://", file)) {
    lokal_zip <- tempfile(fileext = ".zip")
    on.exit(unlink(lokal_zip), add = TRUE)
    .download_file(file, lokal_zip)
    file <- lokal_zip
  }
  raw <- read_raw_json_zip_2026(file, type = "mandatfordelning")
  if (!identical(as_chr_na(raw$valtyp), valtyp) ||
      !identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle),
                 "slutlig")) {
    stop(path, ": r\u00e5metadata st\u00e4mmer inte med slutligt ", valtyp,
         "-resultat.", call. = FALSE)
  }
  raw <- .normalisera_resultat_2022(raw)
  omrades_kod <- as_chr_na(raw$valomrade$kod)
  if (!.personrost_heltal(raw$valomrade$antalValdistriktRaknade) ||
      !.personrost_heltal(raw$valomrade$antalValdistriktSomSkaRaknas) ||
      raw$valomrade$antalValdistriktRaknade !=
        raw$valomrade$antalValdistriktSomSkaRaknas) {
    stop("Slutligt personr\u00f6stomr\u00e5de 2022 \u00e4r inte f\u00e4rdigr\u00e4knat.", call. = FALSE)
  }
  rost_raw <- if (niva == "valdistrikt") {
    read_raw_json_zip_2026(file, type = "rostfordelning")
  } else NULL
  geo <- .personroster_2022_geografi(raw, rost_raw)
  kd <- dplyr::filter(kandidaturdata, .data$valtyp == .env$valtyp,
                      .data$valomradeskod == .env$omrades_kod)
  pop <- .personroster_2022_population(kd, geo$indelad,
    kandidaturdata)
  kallor <- .personroster_2022_kallrader(geo$noder, geo$geo,
    strikt_listtotal = niva == "personvalsomrade")
  .personroster_2022_kontrollera_poster(kallor$roster, pop)
  pop <- .personroster_2022_observerade(pop, kallor$roster)
  if (niva == "personvalsomrade") {
    out <- .personroster_2022_omrade(kallor, pop, geo$geo,
      per_lista, komplettera_nollor)
  } else {
    out <- .personroster_2022_distrikt(kallor, pop,
      per_lista, komplettera_nollor)
  }
  if (!nrow(out)) return(out)
  officiella <- .personval_officiella_2026(geo$omraden)
  if (nrow(dplyr::anti_join(officiella, pop$alla_globalt,
      by = dplyr::join_by(partikod, kandidatnummer)))) {
    stop("Officiell personvalskandidat saknar giltig kandidatur.",
         call. = FALSE)
  }
  if (niva == "personvalsomrade" && !per_lista && nrow(officiella)) {
    kontroll <- dplyr::inner_join(out, officiella,
      by = dplyr::join_by(personvalsomradeskod, partikod,
                          kandidatnummer), relationship = "many-to-one")
    if (any(!is.na(kontroll$antal_personroster) &
            kontroll$antal_personroster !=
              kontroll$antal_personroster_officiellt)) {
      stop("Officiella personvalsr\u00f6ster st\u00e4mmer inte med omr\u00e5dets listor.",
           call. = FALSE)
    }
    out <- dplyr::left_join(out,
      dplyr::select(officiella, dplyr::all_of(c(
        "personvalsomradeskod", "partikod", "kandidatnummer",
        "antal_personroster_officiellt"))),
      by = dplyr::join_by(personvalsomradeskod, partikod,
                          kandidatnummer), relationship = "many-to-one")
    out$antal_personroster <- dplyr::coalesce(
      out$antal_personroster_officiellt, out$antal_personroster)
  }
  out <- out |>
    dplyr::left_join(dplyr::distinct(officiella,
      .data$personvalsomradeskod, .data$partikod,
      .data$kandidatnummer) |>
      dplyr::mutate(.officiell = TRUE),
      by = dplyr::join_by(personvalsomradeskod, partikod,
                          kandidatnummer), relationship = "many-to-one") |>
    dplyr::left_join(dplyr::select(kandidater_bas,
      dplyr::all_of(c("kandidatnummer", "valtyp", "partikod", "namn",
                      "partiforkortning", "partibeteckning"))),
      by = dplyr::join_by(kandidatnummer, valtyp, partikod),
      relationship = "many-to-one")
  out$kvalificerad_personval <- dplyr::case_when(
    out$.officiell %in% TRUE ~ TRUE,
    geo$omraden$personval_available[
      match(out$personvalsomradeskod,
            geo$omraden$personvalsomradeskod)] %in% TRUE ~ FALSE,
    .default = NA)
  out$valtillfalle <- as_chr_na(raw$valtillfalle)
  out$valar <- 2022L
  out$rakningstillfalle <- "slutlig"
  out$valdatum <- as_chr_na(raw$valdatum)
  out$test <- as_lgl_na(raw$test)
  if (niva == "valdistrikt") {
    out$kommunnamn <- kommunnamn_2026$kommunnamn[
      match(out$kommunkod, kommunnamn_2026$kommunkod)]
    out$lannamn <- .valresultat_lannamn_2026(out$lankod)
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
  if (per_lista) {
    out$andel_personroster_lista <- dplyr::if_else(
      !is.na(out$antal_personroster) & !is.na(out$antal_listroster) &
        out$antal_listroster > 0L,
      out$antal_personroster / out$antal_listroster, NA_real_)
  }
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
  nyckel <- c("valar", "valtyp", "valomradeskod", "personvalsomradeskod",
    "partikod", "kandidatnummer",
    if (niva == "valdistrikt") c("kommunkod", "valdistriktskod",
                                   "valdistriktstyp"),
    if (per_lista) "listnummer")
  if (anyDuplicated(out[nyckel])) {
    stop("Dubbla personr\u00f6stnycklar i resultatet.", call. = FALSE)
  }
  out
}

.personroster_ett_ar_2022 <- function(ar, val, source, data_dir, update,
                                     archive, progress, niva, per_lista,
                                     komplettera_nollor) {
  index <- .read_resultatindex(ar, source, data_dir, update, archive)
  paths <- .slutliga_mandat_paths(index, val, "personroster")
  kd <- kandidaturer(ar = ar, val = val, source = source,
    data_dir = data_dir, update = update, archive = archive)
  bas <- .kandidater_bas(kd, ar)
  purrr::map2(paths$path, paths$valtyp, function(path, valtyp) {
    .personroster_2022_fil(ar, path, valtyp, kd, bas, source, data_dir,
      update, archive, niva, per_lista, komplettera_nollor)
  }, .progress = progress) |>
    purrr::list_rbind() |>
    dplyr::arrange(.data$valtyp, .data$valomradeskod,
      .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
      dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
}
