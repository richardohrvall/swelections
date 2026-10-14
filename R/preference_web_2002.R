# Preserved Valmyndigheten HTML fills only missing RD district preference sources.
# Source row/rank is not a candidate ID, person ID or ballot position.
.rd2002_web_manifest <- function(sources) {
  path <- file.path(sources$root, "district-preference-web", "manifest.json")
  if (!file.exists(path) || .canonical_sha256(path) !=
      "9cfdc50260198a04d325131090b2e2512df72cc6fe92b724768f43057b7a0801")
    stop("Missing or changed 2002 RD district preference web manifest.", call. = FALSE)
  p <- jsonlite::read_json(path, simplifyVector = TRUE)
  if (nrow(p) != 312L || anyDuplicated(p$url) ||
      !setequal(p$municipality, c("1380", "1381", "1384")) ||
      !setequal(p$view, c("", "-totalt", "-lista")))
    stop("Incomplete 2002 RD district preference web snapshot.", call. = FALSE)
  for (i in seq_len(nrow(p))) {
    expected <- paste0("https://historik.val.se/val/val_02/slutresultat/13R/",
      p$municipality[i], "/", p$district[i], p$view[i], ".html")
    if (!identical(p$url[i], expected) ||
        !identical(p$file[i], paste0("district-preference-web/", basename(p$file[i]))))
      stop("Unexpected 2002 preference web source path.", call. = FALSE)
    f <- file.path(sources$root, p$file[i])
    if (!file.exists(f) || file.info(f)$size != p$bytes[i] ||
        unname(tools::md5sum(f)) != p$md5[i] || .canonical_sha256(f) != p$sha256[i])
      stop("Missing or changed 2002 preference source: ", p$url[i], call. = FALSE)
  }
  p
}
.rd2002_web_table <- function(doc, key) {
  a <- xml2::xml_find_all(doc, paste0(".//a[@name='", key, "']"))
  if (length(a) != 1L) stop("Missing/duplicate preference table: ", key, call. = FALSE)
  table <- xml2::xml_find_first(a, "following-sibling::table[1]")
  cells <- lapply(xml2::xml_find_all(table, "./tr|./tbody/tr"), function(tr)
    trimws(xml2::xml_text(xml2::xml_find_all(tr, "./td"))))
  cells <- Filter(function(x) length(x) == 5L && grepl("^[0-9]+$", x[2]) &&
    grepl("^[0-9]+$", x[3]), cells)
  nodes <- xml2::read_xml("<ROWS/>")
  for (x in cells) xml2::xml_add_child(nodes, "PERSONVAL", NAMN = x[1],
    ORDNING = x[2], PERSONKRYSS = x[3])
  # Deliberately no KANDIDAT attribute: HTML Nr is source rank, not position.
  xml2::xml_find_all(nodes, "./PERSONVAL")
}
.rd2002_web_controls <- function(doc) {
  out <- lapply(xml2::xml_find_all(doc, ".//a[starts-with(@name,'personval-')]"), function(a) {
    party <- sub("^personval-", "", xml2::xml_attr(a, "name"))
    table <- xml2::xml_find_first(a, "ancestor::table[1]")
    rows <- lapply(xml2::xml_find_all(table, "./tr|./tbody/tr"), function(tr)
      trimws(xml2::xml_text(xml2::xml_find_all(tr, "./td"))))
    rows <- Filter(function(x) length(x) == 5L &&
      grepl("^(Totalt|[0-9]{4}-[0-9]{5})$", x[1]), rows)
    purrr::map(rows, function(x) tibble::tibble(party = party,
      key = paste0(party, "-", if (x[1] == "Totalt") "totalt" else x[1]),
      list = if (x[1] == "Totalt") NA_character_ else x[1],
      votes = as.integer(x[2]), preference = suppressWarnings(as.integer(x[3])))) |>
      purrr::list_rbind()
  }) |> purrr::list_rbind()
  if (anyDuplicated(out$key) || anyNA(out$votes) || any(out$votes < 0L))
    stop("Invalid district preference controls.", call. = FALSE)
  out
}
.rd2002_preference_web <- function(sources, municipalities, per_lista) {
  p <- .rd2002_web_manifest(sources)
  national <- .xml2002_read(sources, "slutresultat_00R.xml", "RD")
  register <- .xml2002_register(national, "RD", sources = sources)
  out <- lapply(municipalities, function(m) {
    doc <- .xml2002_read(sources, paste0("slutresultat_", m, "K.xml"), "KF")
    ordinary <- xml2::xml_find_all(doc, "./KOMMUN/KRETS_KOMMUN/VALDISTRIKT")
    postal <- paste0("R-", m, "-15")
    expected <- c(xml2::xml_attr(ordinary, "KOD"), postal)
    part <- p[p$municipality == m, ]
    if (nrow(part) != 3L * length(expected) ||
        anyDuplicated(part[c("district", "view")]) || !setequal(part$district, expected))
      stop("Incomplete 2002 web district geography: ", m, call. = FALSE)
    purrr::map(sort(expected), function(code) {
      records <- part[part$district == code, ]
      read <- function(view) xml2::read_html(file.path(sources$root, records$file[records$view == view]))
      main <- read(""); totals <- read("-totalt"); lists <- read("-lista")
      control <- .rd2002_web_controls(main)
      if (!setequal(control$party, c("M", "C", "FP", "KD", "S", "V", "MP")))
        stop("Unexpected 2002 web preference-party coverage.", call. = FALSE)
      node <- ordinary[xml2::xml_attr(ordinary, "KOD") == code]
      if (code == postal) {
        node <- xml2::xml_add_child(xml2::xml_find_first(doc, "./KOMMUN"), "ONSDAGSDISTRIKT",
          KOD = paste0(m, "9800"), NAMN = "I vallokal ej r\u00e4knade r\u00f6ster")
      } else if (length(node) != 1L) stop("Ambiguous district geography.", call. = FALSE)
      geo <- .xml2002_geography(sources, node, "RD", "valdistrikt", doc)
      geo$area_code <- geo$valkretskod; geo$area_name <- geo$valkretsnamn
      purrr::map(seq_len(nrow(control)), function(i) {
        c <- control[i, ]; is_list <- !is.na(c$list)
        html <- if (is_list) lists else totals
        anchors <- xml2::xml_attr(xml2::xml_find_all(html, ".//a[@name]"), "name")
        nodes <- if (c$key %in% anchors) .rd2002_web_table(html, c$key) else xml2::xml_find_all(html, "./NO_ROWS")
        count <- sum(as.double(xml2::xml_attr(nodes, "PERSONKRYSS")))
        if ((!is.na(c$preference) && count != c$preference) ||
            (is.na(c$preference) && length(nodes)))
          stop("2002 web preference records disagree with their source total: ", code, "; ", c$key, call. = FALSE)
        if (is_list != per_lista || !length(nodes)) return(NULL)
        info <- .xml2018_parti(c$party, "RD", geo$valomradeskod, register)
        denominator <- control$votes[control$party == c$party & is.na(control$list)]
        list <- if (is_list) xml2::read_xml("<VALSEDEL/>") else NULL
        if (is_list) xml2::xml_attrs(list) <- stats::setNames(c(c$list, as.character(c$votes)), c("LISTNUMMER", "R\u00d6STER"))
        url <- records$url[records$view == if (is_list) "-lista" else "-totalt"]
        .xml2002_preference_rows(nodes, doc, paste0(url, "#", c$key), "RD", geo, info, denominator, list)
      }) |> purrr::list_rbind()
    }) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  # Counts are checked independently again by the build validator.
  out
}
