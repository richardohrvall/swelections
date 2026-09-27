.xml2018_mandat_noder <- function(doc, val, niva) {
  xpath <- switch(niva,
    riket = "./NATION",
    riksdagsvalkrets = "./NATION/L\u00c4N/KRETS_RIKSDAG",
    region = "./NATION/L\u00c4N",
    regionvalkrets = "./NATION/L\u00c4N/KRETS_LANDSTING",
    kommun = "./KOMMUN",
    kommunvalkrets = "./KOMMUN/KRETS_KOMMUN"
  )
  noder <- xml2::xml_find_all(doc, xpath)
  if (niva == "kommunvalkrets") {
    noder <- noder[!grepl("00$", xml2::xml_attr(noder, "KOD"))]
  }
  noder
}

.xml2018_valda_for_parti <- function(node, parti, val) {
  valda <- xml2::xml_find_all(parti, "./GRUPP_VALDA/VALD")
  if (length(valda) || .xml2018_int(parti, "MANDAT") == 0L) return(valda)
  xpath <- switch(val,
    RD = ".//KRETS_RIKSDAG/GILTIGA",
    RF = ".//KRETS_LANDSTING/GILTIGA",
    KF = ".//KRETS_KOMMUN/GILTIGA"
  )
  under <- xml2::xml_find_all(node, xpath)
  under <- under[xml2::xml_attr(under, "PARTI") == .xml2018_attr(parti, "PARTI")]
  xml2::xml_find_all(under, "./GRUPP_VALDA/VALD", flatten = TRUE)
}

.xml2018_tomma_stolar <- function(node, parti, val, mandat) {
  if (is.na(mandat)) return(NA_integer_)
  if (mandat == 0L) return(0L)
  valda <- .xml2018_valda_for_parti(node, parti, val)
  if (!length(valda)) return(NA_integer_)
  id <- xml2::xml_attr(valda, "KANDNR")
  namn <- xml2::xml_attr(valda, "NAMN")
  markor <- (is.na(id) | !nzchar(id)) & namn == "Kunde inte utses"
  if (anyNA(markor) || any((is.na(id) | !nzchar(id)) & !markor)) {
    stop("Ok\u00e4nd platsmark\u00f6r i 2018 \u00e5rs valda-struktur.", call. = FALSE)
  }
  antal_valda <- length(unique(id[!markor]))
  if (antal_valda + sum(markor) != mandat) return(NA_integer_)
  as.integer(sum(markor))
}

.xml2018_mandatrader <- function(node, doc, root, val, niva, register) {
  geo <- .xml2018_geo(node, val, niva, doc)
  partier <- xml2::xml_find_all(node, "./GILTIGA|./\u00d6VRIGA_GILTIGA/GILTIGA")
  # En partirad utan mandatfält hör till röstfördelningen, inte mandatlistan.
  partier <- partier[!is.na(xml2::xml_attr(partier, "MANDAT"))]
  if (!length(partier)) return(dplyr::mutate(.mandat_schema_2026(),
                                             antal_tomma_stolar = integer()))
  out <- .mandat_schema_2026()[rep(NA_integer_, length(partier)), , drop = FALSE]
  out$valtillfalle <- "Val_2018"
  out$rakningstillfalle <- "slutlig"
  out$valtyp <- val
  out$valdatum <- .xml2018_valdag(root, "VALDAG")
  out$valdatum_fg <- .xml2018_valdag(root, "VALDAG_FGVAL")
  out$senaste_uppdateringstid <- .xml2018_attr(root, "TID_RAPPORT")
  out$rapporteringstid <- .xml2018_attr(node, "TID_RAPPORT")
  out$antal_valdistrikt_raknade <- .xml2018_int(node, "KLARA_VALDISTRIKT")
  out$antal_valdistrikt_som_ska_raknas <- .xml2018_int(node, "ALLA_VALDISTRIKT")
  out$geografiniva <- niva
  out$valomradeskod <- geo$valomradeskod
  out$valomradesnamn <- geo$valomradesnamn
  out$valkretskod <- if (niva %in% c("riksdagsvalkrets", "regionvalkrets", "kommunvalkrets"))
    .xml2018_attr(node, "KOD") else NA_character_
  out$valkretsnamn <- if (niva %in% c("riksdagsvalkrets", "regionvalkrets", "kommunvalkrets"))
    .xml2018_attr(node, "NAMN") else NA_character_
  raw_total <- .xml2018_int(node, if (niva %in% c("riket", "region", "kommun"))
    "MANDAT_VALOMR\u00c5DE" else "MANDAT_VALKRETS")
  valkrets_med_utjamning <- niva %in%
    c("riksdagsvalkrets", "regionvalkrets", "kommunvalkrets")
  total <- if (valkrets_med_utjamning) NA_integer_ else raw_total
  out$antal_tomma_stolar <- rep(NA_integer_, nrow(out))
  for (i in seq_along(partier)) {
    parti <- partier[[i]]
    info <- .xml2018_parti(.xml2018_attr(parti, "PARTI"), val,
                            geo$valomradeskod, register, parti, node)
    out$partikod[[i]] <- info$partikod
    out$partibeteckning[[i]] <- info$partibeteckning
    out$partiforkortning[[i]] <- info$partiforkortning
    out$antal_mandat[[i]] <- .xml2018_int(parti, "MANDAT")
    utjamning <- .xml2018_int(parti, "VARAV_UTJ\u00c4MNING")
    if (val == "KF" && is.na(utjamning)) utjamning <- 0L
    out$antal_utjamningsmandat[[i]] <- utjamning
    if (!is.na(utjamning)) {
      out$antal_fasta_mandat[[i]] <- out$antal_mandat[[i]] - utjamning
    }
    out$antal_mandat_fg[[i]] <- .xml2018_int(parti, "MANDAT_FGVAL")
    out$diff_antal_mandat[[i]] <- .xml2018_int(parti, "MANDAT_\u00c4NDRING")
    out$antal_tomma_stolar[[i]] <-
      .xml2018_tomma_stolar(node, parti, val, out$antal_mandat[[i]])
  }
  if (valkrets_med_utjamning && !anyNA(out$antal_mandat)) {
    total <- as.integer(sum(as.double(out$antal_mandat)))
    out$totalt_antal_fasta_mandat <- raw_total
  }
  out$totalt_antal_mandat <- total
  if (!is.na(total) && !anyNA(out$antal_mandat) &&
      sum(as.double(out$antal_mandat)) != total) {
    stop("2018 \u00e5rs aktuella partimandat st\u00e4mmer inte med omr\u00e5destotalen.", call. = FALSE)
  }
  if (!anyNA(out$antal_fasta_mandat)) {
    if (valkrets_med_utjamning &&
        sum(as.double(out$antal_fasta_mandat)) != raw_total) {
      stop("2018 \u00e5rs fasta valkretsmandat st\u00e4mmer inte med partimandaten.", call. = FALSE)
    }
    out$totalt_antal_fasta_mandat <- sum(out$antal_fasta_mandat)
  }
  if (!anyNA(out$antal_utjamningsmandat)) {
    out$totalt_antal_utjamningsmandat <- sum(out$antal_utjamningsmandat)
  }
  out
}

.mandat_2018 <- function(val, par, source, data_dir, update, archive, progress) {
  file <- .kalla_2018("resultat", source, data_dir, update, archive)
  registerfil <- .kalla_2018("partier", source, data_dir, update, archive)
  register <- .xml2018_partiregister(registerfil)
  zip <- .lokal_zip_2018(file)
  if (!identical(zip, file)) on.exit(unlink(zip), add = TRUE)
  out <- purrr::map(seq_len(nrow(par)), function(i) {
    valt <- par$valtyp[[i]]
    niva <- par$geografiniva[[i]]
    members <- .xml2018_members(zip, valt, niva, mandat = TRUE)
    purrr::map(members, function(member) {
      doc <- .xml2018_fil(zip, member, valt)
      root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
      noder <- .xml2018_mandat_noder(doc, valt, niva)
      purrr::map(noder, .xml2018_mandatrader, doc = doc, root = root,
                 val = valt, niva = niva, register = register) |>
        purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  out <- dplyr::bind_rows(dplyr::mutate(.mandat_schema_2026(),
                                        antal_tomma_stolar = integer()), out)
  out <- .kort_kommunnamn_2026(out)
  out <- .mandat_public_2026(out, 2018L)
  nyckel <- c("valtillfalle", "valtyp", "rakningstillfalle", "geografiniva",
              "valomradeskod", "valkretskod", "partikod")
  if (nrow(out) && (anyNA(out[setdiff(nyckel, "valkretskod")]) ||
                    anyDuplicated(out[nyckel]))) {
    stop("2018 \u00e5rs mandatresultat har saknad eller dubblerad nyckel.", call. = FALSE)
  }
  out
}
