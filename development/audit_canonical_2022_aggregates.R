# Independent arithmetic checks on assets already compared exactly with raw APIs.
# Rscript development/audit_canonical_2022_aggregates.R ASSET_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
pkgload::load_all(".", quiet = TRUE)
dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
old <- options(swelections.canonical_manifest = file.path(dir, "manifest.json"),
  swelections.canonical_assets_dir = dir,
  swelections.canonical_cache_dir = tempfile("swc22-audit-"))
checks <- list()
record <- function(label, differences, details = NULL) {
  checks[[length(checks) + 1L]] <<- list(test = label,
    status = if (nrow(differences)) "DISCREPANCY" else "PASS",
    differences = differences, details = details)
  cat(checks[[length(checks)]]$status, label, nrow(differences), "differences\n")
  jsonlite::write_json(checks, file.path(dirname(dir), "2022-aggregate-audit.json"),
    auto_unbox = TRUE, pretty = TRUE, na = "null")
}
sum_known <- function(x) if (anyNA(x)) NA_integer_ else as.integer(sum(x))
different <- function(a, b) xor(is.na(a), is.na(b)) |
  (!is.na(a) & !is.na(b) & a != b)
for (v in c("RD", "RF", "KF")) {
  area <- preference_votes(2022L, election = v, source = "canonical", detail = "full")
  district <- preference_votes(2022L, election = v, level = "district",
    source = "canonical", detail = "full")
  key <- c("election_code", "party_code", "candidate_number", "preference_vote_area_code")
  totals <- district |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::summarise(district_sum = sum_known(.data$preference_votes), .groups = "drop")
  joined <- dplyr::full_join(dplyr::select(area,
    dplyr::all_of(c(key, "preference_votes"))), totals, by = key,
    relationship = "one-to-one")
  # No observed district posts is a diagnostic observed sum of zero, not a
  # new public completeness inference or an alteration of missing source data.
  absent <- !do.call(paste, c(joined[key], sep = "\r")) %in%
    do.call(paste, c(totals[key], sep = "\r"))
  joined$district_sum[absent] <- 0L
  record(paste(v, "area versus identified district preference votes"),
    joined[different(joined$preference_votes, joined$district_sum), ],
    list(area_rows = nrow(area), observed_district_rows = nrow(district)))
  rm(area, district, totals, joined); gc()
  for (count in c("preliminary", "final")) {
    district <- results(2022L, election = v, count = count, level = "district",
      source = "canonical", detail = "full")
    level <- c(RD = "national", RF = "region", KF = "municipality")[[v]]
    area <- results(2022L, election = v, count = count, level = level,
      source = "canonical", detail = "full")
    geography <- c(RD = "", RF = "region_code", KF = "municipality_code")[[v]]
    key <- c(if (nzchar(geography)) geography, "party_code", "other_parties")
    totals <- district |>
      dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
      dplyr::summarise(district_sum = sum_known(.data$votes), .groups = "drop")
    joined <- dplyr::full_join(dplyr::select(area, dplyr::all_of(c(key, "votes"))),
      totals, by = key, relationship = "one-to-one")
    # Missing rows are retained for diagnostic inspection, never filled in assets.
    record(paste(v, count, "district votes versus official main level"),
      joined[different(joined$votes, joined$district_sum), ],
      list(district_rows = nrow(district), main_rows = nrow(area)))
    rm(area, district, totals, joined); gc()
  }
}
options(old)
