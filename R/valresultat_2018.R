.valresultat_niva_2018 <- function(val, niva) {
  matris <- list(
    RD = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riksdagsvalkrets", "riket"),
    RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets", "region", "riket"),
    KF = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riket")
  )
  if (!niva %in% matris[[val]]) {
    stop("Niv\u00e5n ", niva, " st\u00f6ds inte f\u00f6r ", val,
         " \u00e5r 2018: motsvarande officiell XML-nod saknas.", call. = FALSE)
  }
  invisible(TRUE)
}

.xml2018_tal <- function(x) {
  if (is.na(x)) return(NA_integer_)
  if (!grepl("^[+-]?[0-9]+$", x)) stop("Ogiltigt r\u00f6stetal i 2018-XML.", call. = FALSE)
  as.integer(x)
}

.xml2018_partirader <- function(node, geo, root, val, register) {
  direkta <- .xml2018_barn(node, "GILTIGA")
  ovriga <- .xml2018_forsta(node, "\u00d6VRIGA_GILTIGA")
  detaljer <- .xml2018_barn(ovriga, "GILTIGA")
  handskrivna <- .xml2018_barn(ovriga, "HANDSKRIVNA")
  partier <- c(direkta, detaljer, handskrivna)
  if (!length(partier)) return(.valresultat_schema())
  out <- .valresultat_schema()[rep(NA_integer_, length(partier)), , drop = FALSE]
  out$valtillfalle <- "Val_2018"
  out$rakningstillfalle <- "slutlig"
  out$valtyp <- val
  out$valdatum <- .xml2018_valdag(root, "VALDAG")
  out$valdatum_fg <- .xml2018_valdag(root, "VALDAG_FGVAL")
  out$senaste_uppdateringstid <- .xml2018_attr(root, "TID_RAPPORT")
  out$antal_valdistrikt_raknade <- .xml2018_int(root, "KLARA_VALDISTRIKT")
  out$antal_valdistrikt_som_ska_raknas <- .xml2018_int(root, "ALLA_VALDISTRIKT")
  out$antal_valdistrikt_raknade_omrade <- .xml2018_int(node, "KLARA_VALDISTRIKT")
  out$antal_valdistrikt_som_ska_raknas_omrade <- .xml2018_int(node, "ALLA_VALDISTRIKT")
  out$rapporteringstid <- .xml2018_attr(node, "TID_RAPPORT")
  valdeltagande <- .xml2018_forsta(node, "VALDELTAGANDE")
  out$antal_rostberattigade <- .xml2018_int(valdeltagande, "R\u00d6STBER\u00c4TTIGADE")
  out$antal_rostberattigade_raknade <-
    .xml2018_int(valdeltagande, "R\u00d6STBER\u00c4TTIGADE_KLARA_VALDISTRIKT")
  out$antal_rostberattigade_fg <-
    .xml2018_int(valdeltagande, "R\u00d6STBER\u00c4TTIGADE_KLARA_VALDISTRIKT_FGVAL")
  out$giltiga_roster <- .xml2018_int(node, "R\u00d6STER")
  out$giltiga_roster_fg <- .xml2018_int(node, "R\u00d6STER_FGVAL")
  out$totalt_antal_roster <- .xml2018_int(valdeltagande, "SUMMA_R\u00d6STER")
  out$totalt_antal_roster_fg <- .xml2018_int(valdeltagande, "SUMMA_R\u00d6STER_FGVAL")
  out$valdel <- .xml2018_dbl(valdeltagande, "PROCENT")
  out$valdel_fg <- .xml2018_dbl(valdeltagande, "PROCENT_FGVAL")
  out$diff_valdel <- .xml2018_dbl(valdeltagande, "PROCENT_\u00c4NDRING")
  ogiltiga <- .xml2018_barn(node, "OGILTIGA")
  og <- function(typ, falt) {
    hit <- ogiltiga[xml2::xml_attr(ogiltiga, "TEXT") == typ]
    if (length(hit) != 1L) return(NA_integer_)
    .xml2018_int(hit[[1]], falt)
  }
  out$roster_ej_anmalt_deltagande <- og("OGEJ", "R\u00d6STER")
  out$blanka_roster <- og("BLANK", "R\u00d6STER")
  out$ovriga_ogiltiga <- og("OG", "R\u00d6STER")
  out$roster_ej_anmalt_deltagande_fg <- og("OGEJ", "R\u00d6STER_FGVAL")
  out$blanka_roster_fg <- og("BLANK", "R\u00d6STER_FGVAL")
  out$ovriga_ogiltiga_fg <- og("OG", "R\u00d6STER_FGVAL")
  if (!is.na(out$totalt_antal_roster[[1]]) && !is.na(out$giltiga_roster[[1]])) {
    out$ogiltiga_roster <- out$totalt_antal_roster - out$giltiga_roster
  }
  if (!is.na(out$totalt_antal_roster_fg[[1]]) && !is.na(out$giltiga_roster_fg[[1]])) {
    out$ogiltiga_roster_fg <- out$totalt_antal_roster_fg - out$giltiga_roster_fg
  }
  indelning <- .xml2018_attr(node, "INDELNING")
  out$status_jamforelse <- if (!is.na(indelning) &&
                                  indelning %in% c("Modifierad", "Ny")) {
    paste("ej j\u00e4mf\u00f6rbar:", indelning)
  } else indelning
  for (namn in intersect(names(geo), names(out))) out[[namn]] <- geo[[namn]]
  for (i in seq_along(partier)) {
    parti <- partier[[i]]
    hand <- i > length(direkta) + length(detaljer)
    out$ovriga_partier[[i]] <- hand
    if (hand) {
      out$partibeteckning[[i]] <- "Handskrivna r\u00f6ster"
    } else {
      info <- .xml2018_parti(.xml2018_attr(parti, "PARTI"), val,
                              geo$valomradeskod, register, parti, node)
      out$partikod[[i]] <- info$partikod
      out$partibeteckning[[i]] <- info$partibeteckning
      out$partiforkortning[[i]] <- info$partiforkortning
    }
    out$antal_roster[[i]] <- .xml2018_int(parti, "R\u00d6STER")
    out$andel_roster[[i]] <- .xml2018_dbl(parti, "PROCENT")
    out$antal_roster_fg[[i]] <- .xml2018_int(parti, "R\u00d6STER_FGVAL")
    out$andel_roster_fg[[i]] <- .xml2018_dbl(parti, "PROCENT_FGVAL")
    out$diff_antal_roster[[i]] <- if (!is.na(out$antal_roster[[i]]) &&
                                      !is.na(out$antal_roster_fg[[i]]))
      out$antal_roster[[i]] - out$antal_roster_fg[[i]] else NA_integer_
    out$diff_andel_roster[[i]] <- .xml2018_dbl(parti, "PROCENT_\u00c4NDRING")
  }
  if (!anyNA(out$antal_roster) && !is.na(out$giltiga_roster[[1]]) &&
      sum(as.double(out$antal_roster)) != out$giltiga_roster[[1]]) {
    stop("Partir\u00f6sterna i 2018-XML st\u00e4mmer inte med giltiga r\u00f6ster.", call. = FALSE)
  }
  out
}

.valresultat_2018 <- function(val, niva, source, data_dir, update, archive, progress) {
  .valresultat_niva_2018(val, niva)
  file <- .kalla_2018("resultat", source, data_dir, update, archive)
  registerfil <- .kalla_2018("partier", source, data_dir, update, archive)
  register <- .xml2018_partiregister(registerfil)
  zip <- .lokal_zip_2018(file)
  if (!identical(zip, file)) on.exit(unlink(zip), add = TRUE)
  if (val == "KF" && niva %in% c("lan", "riket")) {
    register <- .xml2018_reg_fran_listor(zip, val, register)
  }
  members <- .xml2018_members(zip, val, niva)
  parsed <- purrr::map(members, function(member) {
    doc <- .xml2018_fil(zip, member, val)
    root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
    noder <- .xml2018_noder(doc, niva, val)
    if (!length(noder)) return(.valresultat_schema())
    purrr::map(noder, function(node) {
      geo <- .xml2018_geo(node, val, niva, doc)
      .xml2018_partirader(node, geo, root, val, register)
    }) |> purrr::list_rbind()
  }, .progress = progress) |> purrr::list_rbind()
  if (niva == "valdistrikt") parsed$raknat <- rep(TRUE, nrow(parsed))
  parsed <- .komplettera_kommunnamn_2026(parsed, parsed$kommunnamn)
  parsed <- .valresultat_public_andelar_2026(parsed)
  parsed$valar <- rep(2018L, nrow(parsed))
  out <- parsed[.valresultat_public_columns_2026(niva)]
  .valresultat_check_key(out, niva)
  out
}
