# Independent HTML/XML source reconstruction; final XML is geography ONLY.
# Rscript development/validate_preliminary_2010_preserved.R [ROOT SNAPSHOT REPORT]
source("development/source_tools.R")
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else ".local-data/rkl/2010/valresultat"
snap <- if (length(args) >= 2L) args[[2]] else file.path(root, "preliminary-collection-preservation-20261009")
out <- if (length(args) >= 3L) args[[3]] else ".local-data/r-only-preliminary2010-source-validation.json"
expected <- audit_json(file.path(snap, "expected-sources.json"))
old <- file.path(root, "preliminary-presentation-20261008")
old_rows <- audit_json(file.path(old, "source-manifest.json"))$sources
old_sources <- setNames(old_rows, vapply(old_rows, `[[`, "", "url"))
for (r in old_rows) if (r$role == "municipal_constituency") {
  parts <- stringr::str_match(r$url, "/([RLK])/kvalkrets/([0-9]{2})/([0-9]{2})/([0-9]{2})/")
  if (!is.na(parts[[1]])) expected <- c(expected, list(list(relative = r$file,
    url = r$url, role = r$role, election = parts[[2]], code = paste0(parts[[3]], parts[[4]], parts[[5]]))))
}
records <- lapply(readLines(file.path(snap, "retrieval.jsonl"), encoding = "UTF-8"),
  function(x) jsonlite::fromJSON(x, simplifyVector = FALSE))
success <- records[vapply(records, function(x) identical(x$status, 200L) && isTRUE(x$valid_result_page), TRUE)]
sources <- setNames(success, vapply(success, `[[`, "", "relative"))
for (key in names(sources)) {
  r <- sources[[key]]; file <- file.path(snap, key)
  audit_pin(file, r$bytes, r$md5, r$sha256)
  if (r$role == "collection_district") {
    stopifnot(r$final_url == r$url, grepl("/prelresultat/", r$final_url, fixed = TRUE))
    headings <- xml2::xml_text(xml2::xml_find_all(xml2::read_html(file, options = "NONET"), "//h1|//h2|//h3"))
    stopifnot(any(grepl("preliminär", tolower(headings), fixed = TRUE)))
  }
}
common <- c("M", "C", "FP", "KD", "S", "V", "MP", "SD")
presentation <- function(file) {
  doc <- xml2::read_html(file, options = "NONET"); votes <- audit_counter(); known <- FALSE
  for (cells in audit_rows(doc)) {
    if (length(cells) != 8L) next
    n <- audit_number(cells[[3]]); if (is.na(n)) next
    label <- cells[[1]]; description <- cells[[2]]
    if (description == "Giltiga röster") { votes[["VALID"]] <- n; known <- TRUE } else
      if (label %in% c("BLANK", "OG", "VDT")) votes[[label]] <- n else
      if (description == "Antal röstberättigade") votes[["ELIGIBLE"]] <- n else
      if (nzchar(label)) votes[[if (label %in% c("ÖVR", "ÖVRIGA")) "ÖVR" else label]] <- n
  }
  if (known) {
    stopifnot(sum(votes[setdiff(names(votes), c("VALID", "BLANK", "OG", "VDT", "ELIGIBLE"))]) == votes[["VALID"]])
    total <- votes[["VALID"]] + audit_get(votes, "BLANK") + audit_get(votes, "OG")
    if ("VDT" %in% names(votes)) stopifnot(votes[["VDT"]] == total)
    votes[["VDT"]] <- total
  }
  list(doc = doc, votes = votes, known = known)
}
xml_votes <- function(node) {
  out <- audit_counter()
  for (child in xml2::xml_children(node)) {
    tag <- xml2::xml_name(child)
    if (tag == "GILTIGA") out <- audit_add(out, xml2::xml_attr(child, "PARTI"), as.integer(xml2::xml_attr(child, "RÖSTER")))
    if (tag == "ÖVRIGA_GILTIGA") out <- audit_add(out, "ÖVR", as.integer(xml2::xml_attr(child, "RÖSTER")))
    if (tag == "OGILTIGA") out <- audit_add(out, xml2::xml_attr(child, "TEXT"), as.integer(xml2::xml_attr(child, "RÖSTER")))
    if (tag == "VALDELTAGANDE") {
      out <- audit_add(out, "VDT", audit_number(xml2::xml_attr(child, "SUMMA_RÖSTER")))
      out <- audit_add(out, "ELIGIBLE", audit_number(xml2::xml_attr(child, "RÖSTBERÄTTIGADE")))
    }
  }
  valid <- audit_number(xml2::xml_attr(node, "RÖSTER")); if (!is.na(valid)) out[["VALID"]] <- valid
  out
}
coarse <- function(x) {
  out <- audit_counter()
  for (key in names(x)) out <- audit_add(out,
    if (key %in% c(common, "VALID", "BLANK", "OG", "VDT", "ELIGIBLE")) key else "ÖVR", x[[key]])
  out
}
overview <- function(doc) {
  for (tr in xml2::xml_find_all(doc, "//table[contains(@class,'sorteringsbar_tabell')]//tr")) {
    values <- trimws(xml2::xml_text(xml2::xml_find_all(tr, "./td|./th")))
    if (length(values) == 25L && values[[1]] == "Sverige") {
      keys <- c(common, "ÖVR", "BLANK", "OG", "VDT")
      numbers <- vapply(values[seq(3L, 25L, 2L)], audit_number, 0L)
      numbers[is.na(numbers)] <- 0L; out <- setNames(as.numeric(numbers), keys)
      out[["VALID"]] <- sum(out[c(common, "ÖVR")]); return(out)
    }
  }
  NULL
}
report <- list(); final <- file.path(root, "slutresultat.zip"); night <- file.path(root, "valnatt.zip")
for (v in c("R", "L", "K")) {
  wanted <- expected[vapply(expected, function(x) x$role == "collection_district" && x$election == v, TRUE)]
  stopifnot(length(wanted) == if (v == "L") 392L else 395L,
    !anyDuplicated(vapply(wanted, `[[`, "", "code")))
  missing <- wanted[!vapply(wanted, function(x) x$relative %in% names(sources), TRUE)]
  ordinary <- collection <- audit_counter(); units <- new.env(parent = emptyenv())
  districts <- character(); unavailable <- comparisons <- differences <- list(); rd_geo <- list()
  national <- audit_xml(final, paste0("slutresultat_00", v, ".xml"))
  if (v == "R") for (area in xml2::xml_find_all(national, ".//KRETS_RIKSDAG"))
    for (municipality in xml2::xml_find_all(area, "./KOMMUN")) rd_geo[[xml2::xml_attr(municipality, "KOD")]] <- xml2::xml_attr(area, "KOD")
  add_units <- function(scopes, counts) {
    for (scope in scopes) {
      key <- paste(scope, collapse = "/")
      units[[key]] <- audit_sum(if (exists(key, units, inherits = FALSE)) units[[key]] else audit_counter(), counts)
    }
  }
  for (member in utils::unzip(night, list = TRUE)$Name) {
    if (!grepl(paste0("^valnatt_[0-9]{4}", v, "[.]xml$"), member)) next
    municipality <- substr(member, 9, 12); doc <- audit_xml(night, member)
    geography <- audit_xml(final, sub("valnatt_", "slutresultat_", member, fixed = TRUE))
    for (parent in xml2::xml_find_all(doc, "./KOMMUN/KRETS_KOMMUN")) {
      code <- xml2::xml_attr(parent, "KOD")
      parents <- xml2::xml_find_all(geography, "./KOMMUN/KRETS_KOMMUN")
      p <- parents[xml2::xml_attr(parents, "KOD") == code]; stopifnot(length(p) == 1L)
      rf <- xml2::xml_attr(p, "KRETS_LANDSTING")
      for (node in xml2::xml_find_all(parent, "./VALDISTRIKT")) {
        key <- xml2::xml_attr(node, "KOD"); stopifnot(!key %in% districts); districts <- c(districts, key)
        counts <- xml_votes(node); ordinary <- audit_sum(ordinary, counts)
        scopes <- list(c("national", "00"), c("municipality", municipality), c("municipal_constituency", code))
        if (v == "R") scopes <- c(scopes, list(c("constituency", rd_geo[[municipality]])))
        if (v == "L") scopes <- c(scopes, list(c("region", substr(municipality, 1, 2)), c("regional_constituency", rf)))
        add_units(scopes, counts)
      }
    }
  }
  for (e in wanted) {
    if (!e$relative %in% names(sources)) next
    p <- presentation(file.path(snap, e$relative)); key <- paste0(e$municipality, "00", e$municipal_constituency)
    stopifnot(!key %in% districts); districts <- c(districts, key)
    if (!p$known) unavailable <- c(unavailable, list(e))
    collection <- audit_sum(collection, p$votes)
    scopes <- list(c("national", "00"), c("municipality", e$municipality),
      c("municipal_constituency", paste0(e$municipality, e$municipal_constituency)))
    if (v == "R") scopes <- c(scopes, list(c("constituency", rd_geo[[e$municipality]])))
    if (v == "L") {
      geo <- audit_xml(final, e$geography_source); parents <- xml2::xml_find_all(geo, "./KOMMUN/KRETS_KOMMUN")
      parent <- parents[xml2::xml_attr(parents, "KOD") == paste0(e$municipality, e$municipal_constituency)]
      scopes <- c(scopes, list(c("region", substr(e$municipality, 1, 2)), c("regional_constituency", xml2::xml_attr(parent, "KRETS_LANDSTING"))))
    }
    add_units(scopes, p$votes)
  }
  if (!length(missing)) for (e in expected) {
    if (e$election != v) next
    file <- file.path(snap, e$relative)
    if (!e$relative %in% names(sources)) {
      old_entry <- old_sources[[e$url]]
      if (!is.null(old_entry)) {
        file <- file.path(old, old_entry$file); audit_pin(file, old_entry$bytes, old_entry$md5, old_entry$sha256)
      } else if (v == "R" && e$role == "municipality") {
        constituency <- rd_geo[[e$code]]
        areas <- xml2::xml_find_all(national, ".//KRETS_RIKSDAG")
        nodes <- xml2::xml_find_all(areas[xml2::xml_attr(areas, "KOD") == constituency], "./KOMMUN")
        if (length(nodes) != 1L || xml2::xml_attr(nodes, "KOD") != e$code) next
        relative <- paste0("R/rvalkrets/", substr(constituency, 3, nchar(constituency)), "/index.html")
        if (!relative %in% names(sources)) next
        file <- file.path(snap, relative)
      } else next
    }
    key <- paste(e$role, e$code, sep = "/"); if (!exists(key, units, inherits = FALSE)) next
    p <- presentation(file); actual <- units[[key]]
    if (e$role == "national") {
      text <- gsub("[[:space:]]+", " ", xml2::xml_text(p$doc))
      state <- stringr::str_match(text,
        "(?:Samtliga\\s+([0-9]+)|([0-9]+)\\s+av\\s+([0-9]+))\\s+valdistrikt\\s+räknade")
      if (!is.na(state[[1]])) {
        counted <- as.integer(if (!is.na(state[[2]])) state[[2]] else state[[3]])
        total <- as.integer(if (!is.na(state[[2]])) state[[2]] else state[[4]])
        stopifnot(total == length(districts), counted == length(districts) - length(unavailable))
      }
    }
    if (!p$known && e$role == "national") { p$votes <- overview(p$doc); p$known <- !is.null(p$votes) }
    if (!p$known) next
    if (e$role == "national" && v %in% c("L", "K")) actual <- coarse(actual)
    keys <- setdiff(names(p$votes), "ELIGIBLE")
    delta <- vapply(keys, function(k) audit_get(actual, k) - p$votes[[k]], 0)
    comparisons <- c(comparisons, list(list(role = e$role, code = e$code, fields = length(keys),
      published = as.list(p$votes), reconstructed = setNames(lapply(keys, function(k) audit_get(actual, k)), keys), source = file)))
    if (any(delta != 0)) differences <- c(differences, list(list(role = e$role, code = e$code,
      delta = as.list(delta[delta != 0]), source = file)))
  }
  report[[v]] <- list(expected_collections = length(wanted), retrieved_collections = length(wanted) - length(missing),
    missing_pages = missing, unreported_pages = unavailable, ordinary_districts = length(districts) - length(wanted) + length(missing),
    reported_districts = length(districts) - length(unavailable), ordinary = as.list(ordinary), collection = as.list(collection),
    combined = as.list(audit_sum(ordinary, collection)), comparison_count = length(comparisons), comparisons = comparisons, differences = differences)
  stopifnot(!length(missing), !length(differences), length(unavailable) == if (v == "R") 0L else 9L)
  cat("PASS independent preliminary", v, length(comparisons), "comparisons\n")
}
for (v in names(report)) for (i in seq_along(report[[v]]$comparisons)) {
  report[[v]]$comparisons[[i]]$source <- gsub("\\", "/", report[[v]]$comparisons[[i]]$source, fixed = TRUE)
}
reference <- file.path(snap, "validation.json")
if (file.exists(reference)) {
  old_report <- audit_json(reference)
  for (v in names(old_report)) for (i in seq_along(old_report[[v]]$comparisons))
    old_report[[v]]$comparisons[[i]]$source <- gsub("\\", "/", old_report[[v]]$comparisons[[i]]$source, fixed = TRUE)
  stopifnot(audit_json_equal(report, old_report))
}
audit_write(report, out)
cat("PASS full preserved source report; raw archive untouched\n")
