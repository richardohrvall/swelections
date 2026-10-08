# Independent candidate/person-vote source audit, before public filtering.
# Rscript development/diagnose_sources_2014.R RAW_ROOT REPORT_JSON
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT REPORT_JSON.")
pkgload::load_all(".", quiet = TRUE)
s <- swelections:::.sources_2014("local", args[[1]], FALSE, FALSE)
audit <- list()
for (v in c("RD", "RF", "KF")) {
  cat("Direct source audit", v, "\n"); flush.console()
  register <- swelections:::.xml2014_register_all(s, v)
  kd <- swelections:::.read_candidacies_2014(s, v)
  kd$giltig <- TRUE
  if (v == "RD") attr(kd, "rd_entydiga") <- swelections:::.xml2018_rd_entydiga(kd)
  records <- function(files, district) {
    purrr::list_rbind(lapply(files, function(f) {
      doc <- swelections:::.xml2014_file(f, v)
      nodes <- if (district) swelections:::.xml2018_noder(doc, "valdistrikt", v) else
        swelections:::.xml2018_personomraden(doc, v)
      rd <- if (district && v == "RD") swelections:::.xml2018_rd_krets_fran_listor(doc, kd) else NULL
      purrr::list_rbind(lapply(nodes, function(node) {
        geo <- swelections:::.xml2018_persongeo(node, v, doc,
          if (district) "valdistrikt" else "personvalsomrade")
        if (!is.null(rd)) geo$personvalsomradeskod <- paste0(geo$lankod, rd)
        parties <- xml2::xml_find_all(node, "./GILTIGA|./\u00d6VRIGA_GILTIGA/GILTIGA")
        purrr::list_rbind(lapply(parties, function(p) {
          pv <- xml2::xml_find_all(p, "./PERSONVAL")
          if (!length(pv)) return(NULL)
          party <- swelections:::.xml2018_parti(swelections:::.xml2018_attr(p, "PARTI"),
            v, geo$valomradeskod, register, p)
          tibble::tibble(valtyp = v, valomradeskod = geo$valomradeskod,
            personvalsomradeskod = geo$personvalsomradeskod, partikod = party$partikod,
            kandidatnummer = xml2::xml_attr(pv, "KANDNR"),
            antal = as.integer(xml2::xml_attr(pv, "PERSONKRYSS")))
        }))
      }))
    }))
  }
  area <- records(swelections:::.xml2014_members(s, v,
    if (v == "KF") "kommun" else "riket"), FALSE)
  district <- records(swelections:::.xml2014_members(s, v, "valdistrikt"), TRUE)
  key <- c("valtyp", "valomradeskod", "personvalsomradeskod", "partikod", "kandidatnummer")
  area_sum <- dplyr::summarise(area, area = sum(.data$antal), .by = dplyr::all_of(key))
  district_sum <- dplyr::summarise(district, district = sum(.data$antal), .by = dplyr::all_of(key))
  compare <- dplyr::full_join(area_sum, district_sum, by = key)
  compare$delta <- dplyr::coalesce(compare$area, 0L) - dplyr::coalesce(compare$district, 0L)
  relations <- swelections:::.xml2014_relations(s, v)
  result_ids <- unique(c(area$kandidatnummer, relations$valda$kandidatnummer,
    relations$ersattare$ersattare_kandidatnummer))
  positive <- unique(area$kandidatnummer[area$antal > 0L])
  population <- unique(c(kd$kandidatnummer, result_ids))
  scb <- c(RD = 5905L, RF = 12627L, KF = 53668L)[[v]]
  audit[[v]] <- list(ballot_rows = nrow(kd), ballot_candidate_ids = length(unique(kd$kandidatnummer)),
    official_positive_candidate_ids = length(positive),
    result_only_positive_ids = length(setdiff(positive, kd$kandidatnummer)),
    result_only_nonpositive_ids = length(setdiff(result_ids, union(kd$kandidatnummer, positive))),
    union_candidate_ids = length(population), scb_nominated_persons = scb,
    difference_from_scb = length(population) - scb,
    elected = nrow(relations$valda), substitutes = nrow(relations$ersattare),
    raw_area_records = nrow(area), area_candidate_keys = nrow(area_sum),
    repeated_area_records = nrow(area) - nrow(area_sum),
    area_votes = sum(area$antal), district_votes = sum(district$antal),
    area_district_differences = compare[compare$delta != 0L, ])
  jsonlite::write_json(audit, args[[2]], auto_unbox = TRUE, pretty = TRUE, na = "null")
  print(audit[[v]][c("union_candidate_ids", "elected", "area_votes", "district_votes")])
}
