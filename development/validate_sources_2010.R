# Independent source parsing; no production reader/normaliser calls.
# Rscript development/validate_sources_2010.R [RAW_ROOT OUTPUT_JSON REPORT_JSON]
source("development/source_tools.R")
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else ".local-data/rkl/2010"
output <- if (length(args) >= 2L) args[[2]] else ".local-data/2010-independent-outputs.json"
target <- if (length(args) >= 3L) args[[3]] else ".local-data/2010-source-validation-r.json"
outputs <- audit_json(output); inventory <- audit_json("development/2010_SOURCE_INVENTORY.json")
for (entry in inventory) {
  relative <- sub("^\\.local-data/rkl/2010/", "", entry$file)
  stopifnot(!identical(relative, entry$file))
  audit_pin(file.path(root, relative), entry$bytes, entry$md5, entry$sha256)
}
zip <- file.path(root, "valresultat", "slutresultat.zip")
catalog <- utils::unzip(zip, list = TRUE)$Name
report <- list(); excel_report <- list()
for (v in c("RD", "RF", "KF")) {
  letter <- c(RD = "R", RF = "L", KF = "K")[[v]]
  elected <- substitutes <- list(); districts <- new.env(parent = emptyenv())
  area_votes <- new.env(parent = emptyenv()); unfilled <- 0L; fixed <- areas <- list()
  for (member in catalog[endsWith(catalog, paste0(letter, ".xml"))]) {
    doc <- audit_xml(zip, member)
    municipal <- grepl(paste0("^slutresultat_[0-9]{4}", letter, "[.]xml$"), member)
    if (municipal) for (d in xml2::xml_find_all(doc, ".//VALDISTRIKT|.//ONSDAGSDISTRIKT")) {
      code <- xml2::xml_attr(d, "KOD")
      if (grepl("^[RLK]-[0-9]{4}-[0-9]{2}$", code))
        code <- paste0(substr(code, 3, 6), "00", substr(code, 8, 9))
      stopifnot(!exists(code, districts, inherits = FALSE)); districts[[code]] <- d
    }
    if (if (v == "KF") !municipal else municipal) next
    path <- switch(v, RD = ".//KRETS_RIKSDAG", RF = ".//KRETS_LANDSTING", KF = ".//KRETS_KOMMUN")
    for (area in xml2::xml_find_all(doc, path)) {
      code <- xml2::xml_attr(area, "KOD")
      parent <- if (v == "RD") "00" else substr(code, 1, if (v == "RF") 2 else 4)
      constituency <- if (v != "RD" && endsWith(code, "00")) NULL else code
      parties <- xml2::xml_find_all(area, "./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA")
      for (party in parties) {
        lists <- xml2::xml_find_all(party, "./VALSEDEL|./PARTISEDEL")
        codes <- unique(substr(xml2::xml_attr(lists, "LISTNUMMER"), 1, 4))
        party_id <- if (length(codes) == 1L) codes else xml2::xml_attr(party, "PARTI")
        if (!grepl("^[0-9]+$", party_id)) party_id <- NA_character_
        for (p in xml2::xml_find_all(party, "./PERSONVAL")) {
          id <- xml2::xml_attr(p, "KANDNR")
          if (v == "RF" && id == "451964") id <- "442089"
          stopifnot(!is.na(party_id))
          key <- audit_tuple(list(parent, if (is.null(constituency)) parent else code, party_id, id))
          area_votes <- audit_add(area_votes, key, as.integer(xml2::xml_attr(p, "PERSONKRYSS")))
        }
        for (group in xml2::xml_find_all(party, "./GRUPP_VALDA"))
          for (candidate in xml2::xml_find_all(group, "./VALD")) {
            id <- xml2::xml_attr(candidate, "KANDNR")
            if (is.na(id) || !nzchar(id)) { unfilled <- unfilled + 1L; next }
            basis <- xml2::xml_attr(candidate, "GRUND"); if (is.na(basis)) basis <- NULL
            elected[[length(elected) + 1L]] <- list(id, party_id, parent, constituency,
              as.integer(xml2::xml_attr(candidate, "ORDNING")), basis, xml2::xml_attr(group, "ORDNING"))
            for (substitute in xml2::xml_find_all(group, "./ERSÄTTARE"))
              substitutes[[length(substitutes) + 1L]] <- list(id,
                xml2::xml_attr(substitute, "KANDNR"), party_id, parent, constituency,
                as.integer(xml2::xml_attr(substitute, "ORDNING")), xml2::xml_attr(group, "ORDNING"))
          }
      }
      get_int <- function(nodes, field) {
        x <- xml2::xml_attr(nodes, field); x[is.na(x)] <- "0"; sum(as.integer(x))
      }
      fixed[[code]] <- list(name = xml2::xml_attr(area, "NAMN"),
        seats = get_int(parties, "MANDAT") - get_int(parties, "VARAV_UTJÄMNING"))
      areas[[code]] <- area
    }
  }
  actual <- outputs[[v]]
  actual_e <- lapply(actual$elected_data, function(r) unname(r[c("kandidatnummer", "partikod",
    "invald_valomradeskod", "invald_valkretskod", "invalsordning", "valgrund_id", "ersattargrupp")]))
  actual_s <- lapply(actual$substitute_data, function(r) unname(r[c("ledamot_kandidatnummer",
    "ersattare_kandidatnummer", "partikod", "valomradeskod", "valkretskod", "ersattarordning", "ersattargrupp")]))
  stopifnot(identical(audit_multiset(elected), audit_multiset(actual_e)),
    identical(audit_multiset(substitutes), audit_multiset(actual_s)))
  area_votes <- unlist(as.list(area_votes), use.names = TRUE)
  actual_votes <- new.env(parent = emptyenv())
  for (r in actual$area_votes) actual_votes <- audit_add(actual_votes,
    audit_tuple(unname(r[c("valomradeskod", "personvalsomradeskod", "partikod", "kandidatnummer")])), r$antal_personroster)
  actual_votes <- unlist(as.list(actual_votes), use.names = TRUE)
  stopifnot(setequal(names(area_votes), names(actual_votes)), all(area_votes == actual_votes[names(area_votes)]))
  file <- file.path(root, "valresultat", paste0("slutligt_valresultat_valdistrikt_", letter,
    if (v == "KF") "_antal" else "", ".skv"))
  table <- readr::read_delim(file, delim = ";", locale = readr::locale(encoding = "latin1"),
    col_types = readr::cols(.default = "c"), name_repair = "minimal", na = character(),
    trim_ws = FALSE, show_col_types = FALSE)
  comparisons <- missing <- 0L
  pad <- function(x, width) stringr::str_pad(x, width, pad = "0")
  for (i in seq_len(nrow(table))) {
    r <- as.character(table[i, ])
    suffix <- if (startsWith(r[[3]], "VK")) paste0("00", substr(r[[3]], 3, nchar(r[[3]]))) else pad(r[[3]], 4)
    code <- paste0(pad(r[[1]], 2), pad(r[[2]], 2), suffix)
    stopifnot(exists(code, districts, inherits = FALSE)); d <- districts[[code]]
    district_parties <- xml2::xml_find_all(d, "./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA")
    district_party_ids <- xml2::xml_attr(district_parties, "PARTI")
    for (j in seq.int(7L, ncol(table))) {
      field <- names(table)[[j]]; value <- r[[j]]
      if (!nzchar(trimws(value)) || (v != "KF" && !endsWith(field, " tal"))) next
      alias <- sub(" tal$", "", field)
      if (alias %in% c("OVR", "ÖVR", "BL", "BLANK", "OG") ||
          field %in% c("Rost Giltiga", "Rostande", "Rostb", "VDT") || !grepl("^[0-9]+$", trimws(value))) next
      if (grepl("^[0-9]+$", alias)) alias <- pad(alias, 4)
      nodes <- district_parties[district_party_ids == alias]
      if (!length(nodes)) {
        if (as.integer(value) == 0L) { missing <- missing + 1L; next }
        stop("Positive SKV party missing from XML: ", code, "/", alias)
      }
      stopifnot(length(nodes) == 1L, as.integer(xml2::xml_attr(nodes, "RÖSTER")) == as.integer(value))
      comparisons <- comparisons + 1L
    }
  }
  kind <- c(RD = "ri", RF = "lf", KF = "kf")[[v]]
  seats <- readr::read_delim(file.path(root, "kandidater", paste0("fastamandat_", kind, ".csv")),
    delim = ";", col_names = FALSE, col_types = readr::cols(.default = "c"), na = character(), show_col_types = FALSE)
  for (i in seq_len(nrow(seats))) {
    r <- as.character(seats[i, ])
    if (v == "RD") {
      codes <- names(fixed)[vapply(fixed, function(x) x$name == r[[1]], TRUE)]
      stopifnot(length(codes) == 1L); code <- codes
    } else code <- paste0(r[[if (v == "KF") 3 else 1]], pad(r[[if (v == "KF") 5 else 4]], 2))
    stopifnot(fixed[[code]]$seats == as.integer(tail(r, 1L)))
  }
  report[[v]] <- c(actual[c("ballot_rows", "population_rows", "candidates", "elected", "substitutes",
    "positive", "zero", "missing", "preference_votes")], list(unfilled = unfilled,
    independent_elected = length(elected), independent_substitute_relations = length(substitutes),
    district_skv_rows = nrow(table), district_party_comparisons = comparisons,
    skv_zero_without_xml_party = missing, skv_differences = list(), independent_fixed_mandate_rows = nrow(seats)))
  stopifnot(sum(area_votes) == actual$preference_votes)
  excel <- ".local-data/2010-mandate-excel.json"
  if (file.exists(excel)) {
    x <- audit_json(excel)[[v]]; checks <- 0L; delta <- list()
    for (r in x$rows) {
      code <- paste0(pad(r[[1]], 2), pad(r[[2]], 2), if (v == "KF") pad(r[[3]], 2) else "")
      stopifnot(code %in% names(areas))
      for (j in seq.int(if (v == "KF") 8L else 6L, length(r))) {
        if (is.null(r[[j]])) next
        field <- x$header[[j]]; adjustment <- endsWith(field, " utj"); alias <- sub(" utj$", "", field)
        nodes <- xml2::xml_find_all(areas[[code]], "./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA")
        nodes <- nodes[xml2::xml_attr(nodes, "PARTI") == alias]; value <- 0L
        if (length(nodes) == 1L) {
          n <- as.integer(xml2::xml_attr(nodes, "MANDAT")); a <- xml2::xml_attr(nodes, "VARAV_UTJÄMNING")
          a <- if (is.na(a)) 0L else as.integer(a)
          value <- if (adjustment) a else n - if (v != "KF") a else 0L
        }
        if (value != as.integer(r[[j]])) {
          stopifnot((v == "RF" && startsWith(code, "14")) || (v == "KF" && code == "188004"))
          delta[[length(delta) + 1L]] <- list(area = code, party_field = field, Excel = as.integer(r[[j]]), XML = value)
        }
        checks <- checks + 1L
      }
    }
    excel_report[[v]] <- list(rows = length(x$rows), mandate_cells = checks, differences = delta,
      classification = "Later re-election scope: RF Vastra Gotaland and KF Orebro nordost; validation only")
  }
  cat("PASS independent XML/SKV/mandates", v, "\n")
}
report$mandate_excel <- excel_report
report$raw_integrity <- list(original_files = length(inventory), modified = 0L)
report$scb <- list(RD_preference_votes = 1494924L, RF_preference_votes = 1422296L,
  KF_preference_votes = 1848627L, RD_matches = TRUE, RF_matches = TRUE, KF_matches = TRUE,
  sources = list(
    "https://www.scb.se/contentassets/b485269e93864392b0640b8b8c6b1c28/me0104_2010a01_br_me01br1101.pdf",
    "https://www.scb.se/contentassets/a00250031a1543a4ae0512101861df9b/me0104_2010a01_br_me02br1101.pdf",
    "https://www.scb.se/contentassets/35b0b096633d414e818d0bac3d02d396/me0104_2010a01_br_me03br1101.pdf"),
  note = "Ordinary 2010 election tables; 2011 re-election tables are excluded.")
stopifnot(report$RD$preference_votes == 1494924L, report$RF$preference_votes == 1422296L,
  report$KF$preference_votes == 1848627L)
reference <- ".local-data/2010-source-validation.json"
if (file.exists(reference)) stopifnot(audit_json_equal(report, audit_json(reference)))
audit_write(report, target)
cat("PASS full independent report matches preserved validation\n")
