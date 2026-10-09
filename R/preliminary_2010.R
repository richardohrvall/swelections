# Preserved preliminary HTML is a reporting snapshot, never final-count input.
.xml2010_collection <- function(file, node, doc, val, register) {
  html <- xml2::read_html(file, options = "NONET")
  cells <- lapply(xml2::xml_find_all(html,
    "//table[contains(@class,'sorteringsbar_tabell')]//tr"), function(r)
    trimws(xml2::xml_text(xml2::xml_find_all(r, "./td"))))
  cells <- cells[lengths(cells) == 8L]
  if (!length(cells) || sum(vapply(cells, function(x) x[[2]] == "Giltiga r\u00f6ster", FALSE)) != 1L)
    stop("Missing 2010 preliminary result table: ", file, call. = FALSE)
  synthetic <- xml2::read_xml("<VAL VALDAG='20100919' VALDAG_FGVAL='20060917'><ONSDAGSDISTRIKT/></VAL>")
  target <- xml2::xml_find_first(synthetic, "./ONSDAGSDISTRIKT")
  set_number <- function(node, field, value) {
    n <- .xml2014_html_number(value)
    if (!is.na(n)) xml2::xml_set_attr(node, field, as.character(n))
  }
  for (x in cells) {
    if (x[[2]] == "Giltiga r\u00f6ster") {
      set_number(target, "R\u00d6STER", x[[3]])
      set_number(target, "R\u00d6STER_FGVAL", x[[7]])
    } else {
      label <- x[[1]]
      child <- xml2::xml_add_child(target, if (label %in% c("BLANK", "OG")) "OGILTIGA" else
        if (label %in% c("\u00d6VR", "\u00d6VRIGA")) "\u00d6VRIGA_GILTIGA" else "GILTIGA")
      xml2::xml_set_attr(child, if (label %in% c("BLANK", "OG")) "TEXT" else "PARTI", label)
      for (pair in list(c("R\u00d6STER", 3L), c("R\u00d6STER_FGVAL", 7L),
        c("PROCENT", 4L), c("PROCENT_FGVAL", 8L), c("PROCENT_\u00c4NDRING", 6L)))
        set_number(child, pair[[1]], x[[as.integer(pair[[2]])]])
    }
  }
  out <- .xml2014_result_rows(target, .xml2018_geo(node, val, "valdistrikt", doc),
    synthetic, val, register, 2010L)
  # The presentation can report a change even when its comparison count is
  # blank. Preserve the explicit change; never turn a blank change into zero.
  for (cell in cells) {
    label <- cell[[1]]
    if (label %in% c("BLANK", "OG") || cell[[2]] == "Giltiga r\u00f6ster") next
    hit <- if (label %in% c("\u00d6VR", "\u00d6VRIGA")) out$ovriga_partier %in% TRUE else
      out$partiforkortning %in% label
    out$diff_antal_roster[hit] <- as.integer(.xml2014_html_number(cell[[5]]))
  }
  # Only fully known components can establish a district total.
  out <- .xml2014_known_vote_totals(out)
  out$raknat <- !is.na(out$giltiga_roster)
  out
}

.xml2010_preliminary_metadata <- function(x, sources, val, niva) {
  snapshots <- list.dirs(file.path(sources$root, "valresultat"), recursive = FALSE)
  snapshot <- snapshots[grepl("^preliminary-collection-preservation-", basename(snapshots))]
  if (length(snapshot) != 1L) stop("Ambiguous 2010 preliminary snapshot.", call. = FALSE)
  entries <- jsonlite::fromJSON(file.path(snapshot, "source-manifest.json"))$sources
  # Earlier preserved aggregate pages supplement the same presentation.
  older <- snapshots[grepl("^preliminary-presentation-", basename(snapshots))]
  entries$directory <- snapshot
  for (dir in older) {
    extra <- jsonlite::fromJSON(file.path(dir, "source-manifest.json"))$sources
    extra <- extra[!extra$url %in% entries$url, ]; extra$directory <- dir
    entries <- dplyr::bind_rows(entries, extra)
  }
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  prefix <- paste0("/val/val2010/prelresultat/", letter, "/")
  paths <- switch(niva, riket = rep("rike/index.html", nrow(x)),
    lan = paste0("lan/", x$lankod, "/index.html"), region = paste0("lan/", x$lankod, "/index.html"),
    kommun = paste0("kommun/", substr(x$kommunkod, 1L, 2L), "/", substr(x$kommunkod, 3L, 4L), "/index.html"),
    kommunvalkrets = paste0("kvalkrets/", substr(x$kommunkod, 1L, 2L), "/", substr(x$kommunkod, 3L, 4L), "/", substr(x$kommunvalkretskod, 5L, 6L), "/index.html"),
    riksdagsvalkrets = paste0("rvalkrets/", substr(x$valkretskod, 3L, 4L), "/index.html"),
    regionvalkrets = paste0("lvalkrets/", substr(x$valkretskod, 1L, 2L), "/", substr(x$valkretskod, 3L, 4L), "/index.html"))
  for (path in unique(paths)) {
    hit <- which(paths == path)
    index <- which(endsWith(entries$url, paste0(prefix, path)))
    if (!length(index)) next
    if (length(index) != 1L) stop("Duplicate preliminary aggregate source.", call. = FALSE)
    file <- file.path(entries$directory[[index]], entries$file[[index]])
    if (!identical(unname(tools::md5sum(file)), entries$md5[[index]])) stop("Changed preliminary source: ", file, call. = FALSE)
    doc <- xml2::read_html(file, options = "NONET")
    rows <- lapply(xml2::xml_find_all(doc, "//table[contains(@class,'sorteringsbar_tabell')]//tr"), function(r)
      trimws(xml2::xml_text(xml2::xml_find_all(r, "./td"))))
    for (r in rows[lengths(rows) == 8L]) {
      fields <- if (r[[2]] == "Giltiga r\u00f6ster") c("giltiga_roster", "giltiga_roster_fg") else
        if (r[[1]] == "VDT") c("totalt_antal_roster", "totalt_antal_roster_fg") else
        if (r[[2]] == "Antal r\u00f6stber\u00e4ttigade") c("antal_rostberattigade", "antal_rostberattigade_fg") else
        if (r[[1]] == "BLANK") c("blanka_roster", "blanka_roster_fg") else
        if (r[[1]] == "OG") c("ovriga_ogiltiga", "ovriga_ogiltiga_fg") else NULL
      if (is.null(fields)) next
      for (j in seq_along(fields)) {
        n <- as.integer(.xml2014_html_number(r[[c(3L, 7L)[[j]]]]))
        if (j == 1L && !is.na(n) && fields[[j]] != "antal_rostberattigade" &&
            any(x[[fields[[j]]]][hit] != n, na.rm = TRUE))
          stop("2010 reported aggregate disagrees with presentation: ", path, call. = FALSE)
        x[[fields[[j]]]][hit] <- n
      }
    }
    # RF/KF national pages use a wide overview table rather than 8-cell rows.
    for (r in rows[lengths(rows) == 25L]) if (r[[1]] == "Sverige") {
      for (pair in list(c("blanka_roster", 21L), c("ovriga_ogiltiga", 23L), c("totalt_antal_roster", 25L))) {
        n <- as.integer(.xml2014_html_number(r[[as.integer(pair[[2]])]]))
        if (!is.na(n) && any(x[[pair[[1]]]][hit] != n, na.rm = TRUE)) stop("2010 national preliminary total differs.", call. = FALSE)
        x[[pair[[1]]]][hit] <- n
      }
    }
  }
  for (suffix in c("", "_fg")) {
    x[[paste0("ogiltiga_roster", suffix)]] <- x[[paste0("blanka_roster", suffix)]] + x[[paste0("ovriga_ogiltiga", suffix)]]
    computed <- x[[paste0("giltiga_roster", suffix)]] + x[[paste0("ogiltiga_roster", suffix)]]
    known <- !is.na(computed)
    x[[paste0("totalt_antal_roster", suffix)]][known] <- computed[known]
  }
  x
}
# Party abbreviations can differ between election-night and final sources.
# Resolve only source-declared designations within the same official area.
.xml2010_preliminary_register <- function(register, doc, val) {
  municipal <- .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD")
  area <- if (val == "RD") "00" else if (val == "RF") substr(municipal, 1L, 2L) else municipal
  parties <- xml2::xml_find_all(doc, "./PARTI")
  extra <- tibble::tibble(valtyp = val, valomradeskod = area,
    partiforkortning = xml2::xml_attr(parties, "F\u00d6RKORTNING"),
    partibeteckning = xml2::xml_attr(parties, "BETECKNING"))
  scoped <- unique(register$data[register$data$valtyp == val &
    register$data$valomradeskod == area, c("partibeteckning", "partikod")])
  scoped <- scoped[!duplicated(scoped$partibeteckning) & !duplicated(scoped$partibeteckning, fromLast = TRUE), ]
  extra$partikod <- scoped$partikod[match(extra$partibeteckning, scoped$partibeteckning)]
  .xml2018_reg_index(unique(dplyr::bind_rows(register$data, extra[!is.na(extra$partikod), ])))
}
