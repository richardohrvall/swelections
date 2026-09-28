# Vektoriserad läsning av de många distriktsnoderna i 2018 års XML.
.xml2018_group_sum <- function(group, tal, n) {
  out <- numeric(n)
  if (length(group)) {
    sums <- rowsum(as.double(tal), group, reorder = FALSE)
    out[as.integer(rownames(sums))] <- sums[, 1L]
  }
  out
}

.xml2018_person_distrikt_fil <- function(doc, val, register,
                                         kandidaturdata, file_id) {
  noder <- .xml2018_noder(doc, "valdistrikt", val)
  rd_krets <- if (val == "RD")
    .xml2018_rd_krets_fran_listor(doc, kandidaturdata) else NULL
  geos <- lapply(seq_along(noder), function(i) {
    geo <- .xml2018_persongeo(noder[[i]], val, doc, "valdistrikt")
    geo$valtyp <- val
    geo$node_id <- as.integer((file_id - 1L) * 10000L + i)
    if (!is.null(rd_krets)) {
      geo$personvalsomradeskod <- paste0(geo$lankod, rd_krets)
      geo$valkretskod <- geo$personvalsomradeskod
    }
    tibble::as_tibble(geo)
  }) |> purrr::list_rbind()
  nodpath <- xml2::xml_path(noder)
  nodid <- geos$node_id
  ps <- xml2::xml_find_all(noder,
    "./GILTIGA|./\u00d6VRIGA_GILTIGA/GILTIGA", flatten = TRUE)
  ppath <- xml2::xml_path(ps)
  pnode <- match(xml2::xml_path(xml2::xml_find_first(ps,
    "ancestor::VALDISTRIKT[1]|ancestor::ONSDAGSDISTRIKT[1]")), nodpath)
  if (anyNA(pnode)) stop("Partirad saknar valdistrikt 2018.", call. = FALSE)
  p_list <- xml2::xml_find_first(ps, "./VALSEDEL|./PARTISEDEL")
  firstlist <- xml2::xml_attr(p_list, "LISTNUMMER")
  pkod <- ifelse(!is.na(firstlist) & grepl("^[0-9]{4}-", firstlist),
                 substr(firstlist, 1L, 4L), NA_character_)
  for (i in which(is.na(pkod))) {
    info <- .xml2018_parti(.xml2018_attr(ps[[i]], "PARTI"), val,
      geos$valomradeskod[[pnode[[i]]]], register, ps[[i]])
    pkod[[i]] <- info$partikod
  }
  p_rost <- as.integer(xml2::xml_attr(ps, "R\u00d6STER"))
  p_person <- as.integer(xml2::xml_attr(ps, "PERSONKRYSS"))
  if (anyNA(p_rost) || any(p_rost < 0L))
    stop("Ogiltiga partir\u00f6ster i 2018 \u00e5rs distrikt.", call. = FALSE)
  if (anyDuplicated(paste(nodid[pnode], pkod)))
    stop("Dubbla partirader i 2018 \u00e5rs distrikt.", call. = FALSE)
  lnodes <- xml2::xml_find_all(ps, "./VALSEDEL|./PARTISEDEL",
                               flatten = TRUE)
  lparti <- match(xml2::xml_path(xml2::xml_find_first(lnodes, "..")), ppath)
  lraw <- xml2::xml_attr(lnodes, "LISTNUMMER")
  l_rost <- as.integer(xml2::xml_attr(lnodes, "R\u00d6STER"))
  l_person <- as.integer(xml2::xml_attr(lnodes, "PERSONKRYSS"))
  partisdel <- xml2::xml_name(lnodes) == "PARTISEDEL"
  l_person[partisdel & is.na(l_person)] <- 0L
  if (anyNA(lparti) || anyNA(lraw) ||
      anyNA(l_rost) || anyNA(l_person) ||
      any(l_rost < 0L | l_person < 0L | l_person > l_rost) ||
      any(!startsWith(lraw, paste0(pkod[lparti], "-"))) ||
      anyDuplicated(paste(lparti, lraw))) {
    stop("Ogiltiga resultatlistor i 2018 \u00e5rs distrikt.", call. = FALSE)
  }
  lsum <- .xml2018_group_sum(lparti, l_rost, length(ps))
  lpsum <- .xml2018_group_sum(lparti, l_person, length(ps))
  ln <- tabulate(lparti, nbins = length(ps))
  if (any((ln > 0L & lsum != p_rost) | (ln == 0L & p_rost != 0L))) {
    stop("Listornas r\u00f6ster st\u00e4mmer inte med distriktets partirad 2018.",
         call. = FALSE)
  }
  p_person[is.na(p_person) & lpsum == 0L] <- 0L
  if (anyNA(p_person) || any(p_person != lpsum)) {
    stop("Listornas personr\u00f6ster st\u00e4mmer inte med partiraden 2018.",
         call. = FALSE)
  }
  vnodes <- xml2::xml_find_all(ps, "./PERSONVAL", flatten = TRUE)
  vparti <- match(xml2::xml_path(xml2::xml_find_first(vnodes, "..")), ppath)
  vid <- xml2::xml_attr(vnodes, "KANDNR")
  vtal <- as.integer(xml2::xml_attr(vnodes, "PERSONKRYSS"))
  if (anyNA(vparti) || anyNA(vid) || anyNA(vtal) || any(vtal < 0L) ||
      anyDuplicated(paste(vparti, vid)) ||
      any(.xml2018_group_sum(vparti, vtal, length(ps)) != p_person)) {
    stop("Distriktets kandidatpersonr\u00f6ster st\u00e4mmer inte 2018.",
         call. = FALSE)
  }
  lvnodes <- xml2::xml_find_all(lnodes, "./PERSONVAL", flatten = TRUE)
  lvlista <- match(xml2::xml_path(xml2::xml_find_first(lvnodes, "..")),
                   xml2::xml_path(lnodes))
  lvid <- xml2::xml_attr(lvnodes, "KANDNR")
  lvtal <- as.integer(xml2::xml_attr(lvnodes, "PERSONKRYSS"))
  generell <- grepl("-90000$", lraw)
  if (any(generell & l_person != 0L) ||
      any(generell[lvlista[!is.na(lvlista)]])) {
    stop("Kandidatpersonr\u00f6ster i 2018 \u00e5rs generella 90000-lista.",
         call. = FALSE)
  }
  if (anyNA(lvlista) || anyNA(lvid) || anyNA(lvtal) || any(lvtal < 0L) ||
      anyDuplicated(paste(lvlista, lvid)) ||
      any(.xml2018_group_sum(lvlista, lvtal, length(lnodes)) !=
            l_person) || any(partisdel[lvlista])) {
    stop("Listans kandidatpersonr\u00f6ster st\u00e4mmer inte 2018.",
         call. = FALSE)
  }
  listsummering <- tibble::tibble(
    parti_id = lparti[lvlista], kandidatnummer = lvid,
    listtal = lvtal) |>
    dplyr::summarise(listtal = sum(.data$listtal),
      .by = c("parti_id", "kandidatnummer"))
  direktsummering <- tibble::tibble(
    parti_id = vparti, kandidatnummer = vid, direkttal = vtal)
  avstamning <- dplyr::full_join(listsummering, direktsummering,
    by = dplyr::join_by(parti_id, kandidatnummer),
    relationship = "one-to-one")
  if (any(dplyr::coalesce(avstamning$listtal, 0L) !=
          dplyr::coalesce(avstamning$direkttal, 0L))) {
    stop("Listvisa och summerade kandidatpersonr\u00f6ster skiljer sig i 2018-distrikt.",
         call. = FALSE)
  }
  parti <- tibble::tibble(node_id = nodid[pnode], valtyp = val,
    valomradeskod = geos$valomradeskod[pnode],
    personvalsomradeskod = geos$personvalsomradeskod[pnode],
    partikod = pkod, antal_partiroster = p_rost,
    parti_complete = TRUE)
  lista <- tibble::tibble(node_id = parti$node_id[lparti], valtyp = val,
    valomradeskod = parti$valomradeskod[lparti],
    personvalsomradeskod = parti$personvalsomradeskod[lparti],
    partikod = pkod[lparti],
    listnummer = substring(lraw, 6L), antal_listroster = l_rost,
    list_complete = TRUE)
  roster <- tibble::tibble(node_id = parti$node_id[vparti], valtyp = val,
    valomradeskod = parti$valomradeskod[vparti],
    personvalsomradeskod = parti$personvalsomradeskod[vparti],
    partikod = pkod[vparti], kandidatnummer = vid,
    antal_personroster = vtal,
    kvalificerad_personval = NA)
  listroster <- tibble::tibble(node_id = lista$node_id[lvlista], valtyp = val,
    valomradeskod = lista$valomradeskod[lvlista],
    personvalsomradeskod = lista$personvalsomradeskod[lvlista],
    partikod = lista$partikod[lvlista],
    listnummer = lista$listnummer[lvlista],
    kandidatnummer = lvid, antal_personroster = lvtal)
  list(geo = geos, parti = parti, lista = lista,
       roster = roster, listroster = listroster)
}
