.xml2014_result_rows <- function(node, geo, root, val, register) {
  other <- .xml2018_forsta(node, "\u00d6VRIGA_GILTIGA")
  if (!inherits(other, "xml_missing") && !length(xml2::xml_children(other))) {
    child <- xml2::xml_add_child(other, "HANDSKRIVNA")
    xml2::xml_attrs(child) <- xml2::xml_attrs(other)
  }
  out <- .metadata_2014(.xml2018_partirader(node, geo, root, val, register))
  out$partibeteckning[out$ovriga_partier %in% TRUE] <- "\u00d6vriga partier"
  out
}

.xml2014_html_number <- function(x) {
  x <- trimws(gsub("\u00a0", "", x, fixed = TRUE))
  x <- gsub("%", "", x, fixed = TRUE)
  if (!nzchar(x)) return(NA_real_)
  if (!grepl("^[+-]?[0-9]+([,.][0-9]+)?$", x))
    stop("Invalid 2014 preliminary presentation number: ", x, call. = FALSE)
  as.double(sub(",", ".", x, fixed = TRUE))
}

.xml2014_collection <- function(file, node, doc, val, register) {
  html <- xml2::read_html(file, options = "NONET")
  rows <- xml2::xml_find_all(html,
    "//table[contains(@class,'sorteringsbar_tabell')]//tr")
  cells <- lapply(rows, function(r) trimws(xml2::xml_text(xml2::xml_find_all(r, "./td"))))
  cells <- cells[lengths(cells) == 8L]
  cells <- cells[vapply(cells, function(x) grepl("^[0-9]+$", x[[3]]), logical(1))]
  if (!length(cells)) stop("Missing preliminary collection results: ", file, call. = FALSE)
  # A new XML node is a read adapter for HTML, not a saved replacement source.
  synthetic <- xml2::read_xml("<VAL VALDAG='20140914' VALDAG_FGVAL='20100919'><ONSDAGSDISTRIKT/></VAL>")
  target <- xml2::xml_find_first(synthetic, "./ONSDAGSDISTRIKT")
  for (x in cells) {
    label <- x[[1]]
    current <- as.integer(.xml2014_html_number(x[[3]]))
    previous <- as.integer(.xml2014_html_number(x[[7]]))
    if (x[[2]] == "Giltiga r\u00f6ster") {
      xml2::xml_set_attr(target, "R\u00d6STER", as.character(current))
      if (!is.na(previous)) xml2::xml_set_attr(target, "R\u00d6STER_FGVAL", as.character(previous))
      next
    }
    child <- xml2::xml_add_child(target,
      if (label %in% c("BLANK", "OG")) "OGILTIGA" else
      if (label %in% c("\u00d6VR", "\u00d6VRIGA")) "\u00d6VRIGA_GILTIGA" else "GILTIGA")
    xml2::xml_set_attr(child, if (label %in% c("BLANK", "OG")) "TEXT" else "PARTI", label)
    xml2::xml_set_attr(child, "R\u00d6STER", as.character(current))
    if (!is.na(previous)) xml2::xml_set_attr(child, "R\u00d6STER_FGVAL", as.character(previous))
    for (pair in list(c("PROCENT", 4L), c("PROCENT_FGVAL", 8L), c("PROCENT_\u00c4NDRING", 6L))) {
      n <- .xml2014_html_number(x[[as.integer(pair[[2]])]])
      if (!is.na(n)) xml2::xml_set_attr(child, pair[[1]], as.character(n))
    }
  }
  valid <- .xml2018_int(target, "R\u00d6STER")
  invalid <- .xml2018_barn(target, "OGILTIGA")
  turnout <- xml2::xml_add_child(target, "VALDELTAGANDE")
  xml2::xml_set_attr(turnout, "SUMMA_R\u00d6STER", as.character(valid +
    sum(as.integer(xml2::xml_attr(invalid, "R\u00d6STER")))))
  previous <- .xml2018_int(target, "R\u00d6STER_FGVAL")
  if (!is.na(previous) && !anyNA(xml2::xml_attr(invalid, "R\u00d6STER_FGVAL")))
    xml2::xml_set_attr(turnout, "SUMMA_R\u00d6STER_FGVAL", as.character(previous +
      sum(as.integer(xml2::xml_attr(invalid, "R\u00d6STER_FGVAL")))))
  .xml2014_result_rows(target, .xml2018_geo(node, val, "valdistrikt", doc),
    synthetic, val, register)
}

.valresultat_preliminary_2014 <- function(sources, val, niva, progress,
                                        internal = FALSE) {
  .valresultat_niva_2018(val, niva)
  snapshot <- list.dirs(file.path(sources$root, "valresultat"), recursive = FALSE,
    full.names = TRUE)
  snapshot <- snapshot[grepl("preliminary-presentation-", basename(snapshot))]
  if (length(snapshot) != 1L) stop("An unambiguous 2014 preliminary presentation snapshot is required.", call. = FALSE)
  manifest <- jsonlite::fromJSON(file.path(snapshot, "source-manifest.json"))$sources
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  selected <- manifest[manifest$role == "collection_district" &
    grepl(paste0("/prelresultat/", letter, "/"), manifest$url, fixed = TRUE), ]
  expected <- if (val == "RF") 387L else 390L
  if (nrow(selected) != expected) stop("Incomplete 2014 collection source inventory.", call. = FALSE)
  collection_key <- sub(".*/onsdagsdistrikt/([0-9]{2})/([0-9]{2})/([0-9]{2})/.*", "\\1\\2\\3", selected$url)
  if (anyDuplicated(collection_key)) stop("Duplicate preliminary collection source.", call. = FALSE)
  register <- .xml2014_register_all(sources, val)
  kd <- if (val == "RD") .read_candidacies_2014(sources, val) else NULL
  if (!is.null(kd)) {
    kd$giltig <- TRUE
    attr(kd, "rd_entydiga") <- .xml2018_rd_entydiga(kd)
  }
  areas <- if (val %in% c("RD", "RF")) {
    nation <- .xml2014_file(.xml2014_members(sources, val, "riket")[[1]], val)
    .xml2018_noder(nation, if (val == "RD") "riksdagsvalkrets" else "regionvalkrets", val)
  } else NULL
  files <- .xml2014_members(sources, val, "valdistrikt", night = TRUE)
  out <- purrr::map(files, function(f) {
    night <- .xml2014_file(f, val, night = TRUE)
    final <- .xml2014_file(file.path(sources$final, sub("^valnatt_", "slutresultat_", basename(f))), val)
    root <- xml2::xml_find_first(night, "./KOMMUN")
    rd <- if (val == "RD") .xml2018_rd_krets_fran_listor(final, kd) else NULL
    ordinary <- xml2::xml_find_all(night, "./KOMMUN/KRETS_KOMMUN/VALDISTRIKT")
    rows <- lapply(ordinary, function(node)
      .xml2014_result_rows(node, .xml2018_geo(node, val, "valdistrikt", night), root, val, register))
    collection <- xml2::xml_find_all(final, "./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT")
    rows <- c(rows, lapply(collection, function(node) {
      code <- .xml2018_attr(node, "KOD")
      hit <- match(gsub("[^0-9]", "", code), collection_key)
      if (is.na(hit)) stop("Missing preliminary collection source: ", code, call. = FALSE)
      file <- file.path(snapshot, gsub("\\", "/", selected$file[[hit]], fixed = TRUE))
      if (!identical(unname(tools::md5sum(file)), selected$md5[[hit]]))
        stop("Changed preliminary source: ", file, call. = FALSE)
      .xml2014_collection(file, node, final, val, register)
    }))
    rows <- purrr::list_rbind(rows)
    if (!is.null(rd)) {
      rows$valkretskod <- paste0(rows$lankod, rd)
      # Official area names, not names reconstructed from a county label.
      rows$valkretsnamn <- xml2::xml_attr(areas, "NAMN")[match(rows$valkretskod, xml2::xml_attr(areas, "KOD"))]
    }
    if (val == "RF") {
      nodes <- c(ordinary, collection)
      codes <- vapply(nodes, function(node) .xml2018_attr(
        xml2::xml_find_first(node, "ancestor::KRETS_KOMMUN[1]"), "KRETS_LANDSTING"), "")
      geo <- tibble::tibble(valdistriktskod = vapply(nodes, .xml2018_attr, "", namn = "KOD"),
        valkretskod = codes)
      rows$valkretskod <- geo$valkretskod[match(rows$valdistriktskod, geo$valdistriktskod)]
      rows$valkretsnamn <- xml2::xml_attr(areas, "NAMN")[match(rows$valkretskod, xml2::xml_attr(areas, "KOD"))]
    }
    rows
  }, .progress = progress) |> purrr::list_rbind()
  out$rakningstillfalle <- rep("preliminar", nrow(out))
  out$raknat <- rep(TRUE, nrow(out))
  .valresultat_check_key(out, "valdistrikt")
  if (internal) return(out)
  if (niva != "valdistrikt") {
    out <- .xml2014_aggregate_results(out, val, niva)
    out <- .xml2014_preliminary_metadata(out, sources, val, niva)
  }
  out <- .komplettera_kommunnamn_2026(out, out$kommunnamn)
  out <- .valresultat_public_andelar_2026(out)
  out[.valresultat_public_columns_2026(niva)]
}

.xml2014_aggregate_results <- function(x, val, niva) {
  geography <- switch(niva, riket = character(), lan = c("lankod", "lannamn"),
    region = c("lankod", "lannamn"), kommun = c("kommunkod", "kommunnamn", "lankod", "lannamn"),
    kommunvalkrets = c("kommunkod", "kommunnamn", "lankod", "lannamn", "kommunvalkretskod", "kommunvalkretsnamn"),
    riksdagsvalkrets = c("valkretskod", "valkretsnamn"),
    regionvalkrets = c("lankod", "lannamn", "valkretskod", "valkretsnamn"))
  if (niva == "kommunvalkrets") x <- x[!is.na(x$kommunvalkretskod), ]
  key <- c(geography, "partikod", "partiforkortning", "partibeteckning", "ovriga_partier")
  totals <- c("giltiga_roster", "giltiga_roster_fg", "totalt_antal_roster",
    "totalt_antal_roster_fg", "blanka_roster", "blanka_roster_fg", "ovriga_ogiltiga",
    "ovriga_ogiltiga_fg", "ogiltiga_roster", "ogiltiga_roster_fg", "antal_rostberattigade",
    "antal_rostberattigade_fg", "antal_rostberattigade_raknade")
  complete_sum <- function(v) if (anyNA(v)) NA_integer_ else as.integer(sum(as.double(v)))
  party <- x |> dplyr::summarise(dplyr::across(dplyr::all_of(c("antal_roster", "antal_roster_fg")), complete_sum),
    .by = dplyr::all_of(key))
  context <- x |> dplyr::distinct(dplyr::across(dplyr::all_of(c(geography, "valdistriktskod", totals)))) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(totals), complete_sum), .by = dplyr::all_of(geography))
  out <- .valresultat_schema()[rep(NA_integer_, nrow(party)), , drop = FALSE]
  for (n in names(party)) out[[n]] <- party[[n]]
  context_index <- if (!length(geography)) rep(1L, nrow(out)) else
    match(do.call(paste, out[geography]), do.call(paste, context[geography]))
  for (n in totals) out[[n]] <- context[[n]][context_index]
  # An uppsamlingsdistrikt collects late votes from the existing electorate;
  # it does not introduce an additional population of eligible voters.
  electorate <- x |>
    dplyr::filter(!.data$valdistriktstyp %in% "uppsamlingsdistrikt") |>
    dplyr::distinct(dplyr::across(dplyr::all_of(c(geography, "valdistriktskod",
      "antal_rostberattigade", "raknat")))) |>
    dplyr::summarise(antal_rostberattigade = complete_sum(.data$antal_rostberattigade),
      alla_raknade = all(.data$raknat %in% TRUE), .by = dplyr::all_of(geography))
  electorate_index <- if (!length(geography)) rep(1L, nrow(out)) else
    match(do.call(paste, out[geography]), do.call(paste, electorate[geography]))
  out$antal_rostberattigade <- electorate$antal_rostberattigade[electorate_index]
  known <- electorate$alla_raknade[electorate_index] %in% TRUE
  out$antal_rostberattigade_raknade[known] <- out$antal_rostberattigade[known]
  out <- .metadata_2014(out)
  out$rakningstillfalle <- rep("preliminar", nrow(out))
  out$valtyp <- rep(val, nrow(out))
  out$geografiniva <- rep(niva, nrow(out))
  if (val == "RD") { out$valomradeskod <- rep("00", nrow(out)); out$valomradesnamn <- rep("Sverige", nrow(out)) }
  if (val == "RF" && niva != "riket") { out$valomradeskod <- out$lankod; out$valomradesnamn <- out$lannamn }
  if (val == "KF" && niva %in% c("kommun", "kommunvalkrets")) { out$valomradeskod <- out$kommunkod; out$valomradesnamn <- out$kommunnamn }
  out$diff_antal_roster <- out$antal_roster - out$antal_roster_fg
  out
}

# Collection districts have no electorate of their own. Consequently their
# absent denominators must not erase explicit higher-level presentation data.
# Read only metadata here: party counts still come from the verified district
# construction, and current totals must agree with the independent presentation.
.xml2014_preliminary_metadata <- function(x, sources, val, niva) {
  snapshot <- list.dirs(file.path(sources$root, "valresultat"), recursive = FALSE)
  snapshot <- snapshot[grepl("preliminary-presentation-", basename(snapshot))]
  if (length(snapshot) != 1L) stop("Ambiguous 2014 preliminary snapshot.", call. = FALSE)
  entries <- jsonlite::fromJSON(file.path(snapshot, "source-manifest.json"))$sources
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  prefix <- paste0("/val/val2014/prelresultat/", letter, "/")
  entries <- entries[grepl(prefix, entries$url, fixed = TRUE), ]
  path <- switch(niva,
    riket = rep("rike/index.html", nrow(x)),
    lan = paste0("lan/", x$lankod, "/index.html"),
    region = paste0("lan/", x$lankod, "/index.html"),
    kommun = paste0("kommun/", substr(x$kommunkod, 1L, 2L), "/",
      substr(x$kommunkod, 3L, 4L), "/index.html"),
    kommunvalkrets = paste0("kvalkrets/", substr(x$kommunkod, 1L, 2L), "/",
      substr(x$kommunkod, 3L, 4L), "/", substr(x$kommunvalkretskod, 5L, 6L), "/index.html"),
    riksdagsvalkrets = paste0("rvalkrets/", substr(x$valkretskod, 3L, 4L), "/index.html"),
    regionvalkrets = paste0("lvalkrets/", substr(x$valkretskod, 1L, 2L), "/",
      substr(x$valkretskod, 3L, 4L), "/index.html"))
  for (p in unique(path)) {
    index <- which(endsWith(entries$url, paste0(prefix, p)))
    if (!length(index)) next
    if (length(index) != 1L) stop("Duplicate preliminary metadata source: ", p, call. = FALSE)
    file <- file.path(snapshot, gsub("\\", "/", entries$file[[index]], fixed = TRUE))
    if (!identical(unname(tools::md5sum(file)), entries$md5[[index]]))
      stop("Changed preliminary metadata source: ", file, call. = FALSE)
    html <- xml2::read_html(file, options = "NONET")
    rows <- lapply(xml2::xml_find_all(html,
      "//table[contains(@class,'sorteringsbar_tabell')]//tr"), function(r)
      trimws(xml2::xml_text(xml2::xml_find_all(r, "./td"))))
    rows <- rows[lengths(rows) == 8L]
    hit <- which(path == p)
    for (r in rows) {
      fields <- if (r[[1]] == "VDT") c("totalt_antal_roster", "totalt_antal_roster_fg") else
        if (r[[2]] == "Antal r\u00f6stber\u00e4ttigade") c("antal_rostberattigade", "antal_rostberattigade_fg") else
          if (r[[2]] == "Giltiga r\u00f6ster") c("giltiga_roster", "giltiga_roster_fg") else NULL
      if (is.null(fields)) next
      numbers <- vapply(r[c(3L, 7L)], function(z) as.integer(.xml2014_html_number(z)), 0L)
      if (fields[[1]] %in% c("totalt_antal_roster", "giltiga_roster") && !is.na(numbers[[1]]) &&
          any(x[[fields[[1]]]][hit] != numbers[[1]], na.rm = TRUE))
        stop("Preliminary aggregate disagrees with official presentation: ", p, call. = FALSE)
      for (j in seq_along(fields)) {
        missing <- hit[is.na(x[[fields[[j]]]][hit])]
        x[[fields[[j]]]][missing] <- numbers[[j]]
      }
      if (fields[[1]] == "antal_rostberattigade" && !is.na(numbers[[1]])) {
        # This adapter is restricted to the complete, hash-pinned preliminary
        # snapshot; all ordinary and collection results have been included.
        x$antal_rostberattigade_raknade[hit] <- numbers[[1]]
      }
    }
  }
  x
}
