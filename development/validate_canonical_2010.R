# Opt-in preserved-source/public-API equivalence. No network or source writes.
# Rscript development/validate_canonical_2010.R RAW_ROOT ASSETS_DIR [SECTION]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% 2:5) stop("Specify RAW_ROOT ASSETS_DIR [SECTION [ELECTION [COUNT]]].")
pkgload::load_all(".", quiet = TRUE)
root <- args[[1]]; dir <- args[[2]]
section <- if (length(args) >= 3L) args[[3]] else "all"
selected_elections <- if (length(args) >= 4L) args[[4]] else c("RD", "RF", "KF")
selected_counts <- if (length(args) == 5L) args[[5]] else c("preliminary", "final")
stopifnot(all(selected_elections %in% c("RD", "RF", "KF")),
  all(selected_counts %in% c("preliminary", "final")))
manifest <- swelections:::.canonical_manifest(file.path(dir, "manifest.json"))
report <- file.path(dirname(dir), paste0("2010-validation-",
  paste(c(section, args[-seq_len(min(3L, length(args)))]), collapse = "-"), ".json"))
options(swelections.canonical_manifest = file.path(dir, "manifest.json"),
  swelections.canonical_assets_dir = dir,
  swelections.canonical_cache_dir = file.path(dirname(dir), "2010-validation-cache"))
checks <- list(); discrepancies <- list()
record <- function(tag, details) {
  checks[[length(checks) + 1L]] <<- list(test = tag, details = details)
  jsonlite::write_json(list(checks = checks, discrepancies = discrepancies), report,
    pretty = TRUE, auto_unbox = TRUE, na = "null")
  cat("PASS", tag, "\n"); flush.console()
}
same <- function(a, b, tag) {
  if (!identical(a, b)) stop("Difference: ", tag, ": ", paste(all.equal(a, b), collapse = "; "))
}
for (i in seq_len(nrow(manifest$sources))) {
  s <- manifest$sources[i, ]
  stopifnot(identical(unname(tools::md5sum(s$file)), s$md5),
    identical(swelections:::.canonical_sha256(s$file), s$sha256))
}
for (i in seq_len(nrow(manifest$assets))) {
  a <- manifest$assets[i, ]; file <- file.path(dir, a$file)
  stopifnot(as.numeric(file.info(file)$size) == a$bytes,
    identical(swelections:::.canonical_sha256(file), a$sha256))
}
stopifnot(setequal(list.files(dir), c(manifest$assets$file, "manifest.json")))
record("source hashes, asset sizes/SHA256 and inventory", nrow(manifest$assets))
# Request-local party register cache only; all result XML are still read directly.
sources <- swelections:::.sources_2010("local", root, FALSE, FALSE)
testthat::local_mocked_bindings(.sources_2010 = function(...) sources,
  .package = "swelections")
# Parse each preserved source family once; run every requested public view and
# aggregation anew. These caches contain raw-reader outputs, never Parquet data.
cache <- new.env(parent = emptyenv())
original_bundle <- swelections:::.xml2014_bundle
original_person <- swelections:::.xml2014_person_read
original_preliminary <- swelections:::.valresultat_preliminary_2014
testthat::local_mocked_bindings(
  .xml2014_bundle = function(sources, val, progress = FALSE) {
    key <- paste0("bundle_", paste(val, collapse = "_"))
    if (!exists(key, cache, inherits = FALSE))
      assign(key, original_bundle(sources, val, progress), cache)
    get(key, cache, inherits = FALSE)
  },
  .xml2014_person_read = function(sources, val, niva, kd, progress = FALSE) {
    key <- paste("person", paste(val, collapse = "_"), niva, sep = "_")
    if (!exists(key, cache, inherits = FALSE))
      assign(key, original_person(sources, val, niva, kd, progress), cache)
    get(key, cache, inherits = FALSE)
  },
  .valresultat_preliminary_2014 = function(sources, val, niva, progress,
                                          internal = FALSE) {
    key <- paste0("preliminary_", val)
    if (!exists(key, cache, inherits = FALSE))
      assign(key, original_preliminary(sources, val, "valdistrikt", progress,
        internal = TRUE), cache)
    x <- get(key, cache, inherits = FALSE)
    if (internal) return(x)
    if (niva != "valdistrikt") {
      x <- swelections:::.xml2014_aggregate_results(x, val, niva, 2010L)
      x <- swelections:::.xml2014_preliminary_metadata(x, sources, val, niva)
    }
    x <- swelections:::.komplettera_kommunnamn_2026(x, x$kommunnamn)
    x <- swelections:::.valresultat_public_andelar_2026(x)
    x[swelections:::.valresultat_public_columns_2026(niva)]
  }, .package = "swelections")
validate <- function(fun, arguments, tag) {
  f <- getExportedValue("swelections", fun)
  raw <- do.call(f, c(arguments, list(source = "local", data_dir = root,
    detail = "full", names = "en")))
  full <- do.call(f, c(arguments, list(source = "canonical", detail = "full", names = "en")))
  same(full, raw, paste(tag, "raw"))
  sv <- do.call(f, c(arguments, list(source = "canonical", detail = "full", names = "sv")))
  same(swelections:::.public_output_names(sv, "en"), full, paste(tag, "full language"))
  standard <- do.call(f, c(arguments, list(source = "canonical", names = "en")))
  same(standard, full[names(standard)], paste(tag, "projection"))
  sv <- do.call(f, c(arguments, list(source = "canonical", names = "sv")))
  same(swelections:::.public_output_names(sv, "en"), standard, paste(tag, "standard language"))
  swedish_function <- c(results = "valresultat", seats = "mandat",
    candidacies = "kandidaturer", candidates = "kandidater", elected = "valda",
    substitutes = "ersattare", preference_votes = "personroster")[[fun]]
  translated <- arguments
  keys <- c(year = "ar", election = "val", count = "rakning", level = "niva",
    include_results = "resultat", by_list = "per_lista", include_zeros = "komplettera_nollor")
  for (key in intersect(names(keys), names(translated))) {
    value <- translated[[key]]
    if (key %in% c("election", "count", "level"))
      value <- swelections:::.english_argument_value(value, key)
    translated[[key]] <- NULL
    translated[[keys[[key]]]] <- value
  }
  swedish <- getExportedValue("swelections", swedish_function)
  for (detail in c("standard", "full")) {
    x <- do.call(swedish, c(translated, list(source = "canonical", names = "sv",
      detaljniva = detail)))
    same(swelections:::.public_output_names(x, "en"),
      if (detail == "full") full else standard, paste(tag, "Swedish wrapper", detail))
  }
  stopifnot(nrow(standard) == nrow(full), !any(vapply(full, is.list, logical(1))))
  record(tag, list(rows = nrow(full), columns_standard = ncol(standard), columns_full = ncol(full),
    types = vapply(full, typeof, ""), missing = vapply(full, function(x) sum(is.na(x)), 0L)))
  full
}
levels <- list(RD = c("district", "municipality", "municipal_constituency", "county", "parliamentary_constituency", "national"),
  RF = c("district", "municipality", "municipal_constituency", "regional_constituency", "region", "national"),
  KF = c("district", "municipality", "municipal_constituency", "county", "national"))
if (section %in% c("all", "results")) for (v in selected_elections) {
  totals <- list()
  for (count in selected_counts) for (level in levels[[v]]) {
    x <- validate("results", list(year = 2010L, election = v, count = count, level = level,
      progress = FALSE), paste("results", v, count, level))
    key <- intersect(c("election_year", "election_code", "district_code", "municipality_code", "county_code",
      "region_code", "constituency_code", "municipal_constituency_code", "party_code", "other_parties"), names(x))
    stopifnot(!anyDuplicated(x[key]))
    geo <- switch(level, district = c("municipality_code", "district_code", "district_type"),
      municipality = "municipality_code", municipal_constituency = c("municipality_code", "municipal_constituency_code"),
      county = "county_code", region = "region_code",
      parliamentary_constituency = "constituency_code", regional_constituency = "constituency_code",
      national = character())
    units <- unique(x[intersect(c(geo, "total_votes", "valid_votes", "invalid_votes"), names(x))])
    if (level != "municipal_constituency")
      totals[[level]] <- vapply(units[c("total_votes", "valid_votes", "invalid_votes")],
        function(z) if (anyNA(z)) NA_real_ else sum(as.double(z)), 0)
    known <- !is.na(x$total_votes) & !is.na(x$valid_votes) & !is.na(x$invalid_votes)
    stopifnot(all(x$total_votes[known] == x$valid_votes[known] + x$invalid_votes[known]))
  }
  for (level in setdiff(names(totals), "national")) {
    known <- !is.na(totals[[level]]) & !is.na(totals$national)
    if (any(totals[[level]][known] != totals$national[known]))
      stop("Official geographic result total difference: ", v, "/", level)
  }
  record(paste("geographic vote aggregates", v), totals)
}
if (section %in% c("all", "candidates")) for (v in selected_elections) {
  for (fun in c("candidacies", "candidates", "elected", "substitutes")) {
    extra <- if (fun == "candidacies") list() else list(progress = FALSE)
    x <- validate(fun, c(list(year = 2010L, election = v), extra), paste(fun, v))
    fields <- intersect(c("name", "member_name", "substitute_name"), names(x))
    stopifnot(all(vapply(x[fields], function(z) all(is.na(z)), logical(1))))
    if (fun %in% c("candidates", "elected")) stopifnot(!anyDuplicated(x[c("candidate_number", "election_code", "party_code")]))
    if (fun == "elected") stopifnot(nrow(x) == c(RD = 349L, RF = 1662L, KF = 12969L)[[v]])
  }
  validate("candidates", list(year = 2010L, election = v, include_results = FALSE,
    progress = FALSE), paste("candidates", v, "base"))
}
if (section %in% c("all", "seats")) for (v in selected_elections) {
  for (level in switch(v, RD = c("national", "parliamentary_constituency"),
    RF = c("region", "regional_constituency"), KF = c("municipality", "municipal_constituency"))) {
    x <- validate("seats", list(year = 2010L, election = v, level = level, progress = FALSE), paste("seats", v, level))
    if (level %in% c("national", "region", "municipality")) {
      stopifnot(sum(x$unfilled_seats) == c(RD = 0L, RF = 0L, KF = 9L)[[v]])
      stopifnot(sum(x$seats) == c(RD = 349L, RF = 1662L, KF = 12978L)[[v]])
    }
  }
}
if (section %in% c("all", "preference_votes")) for (v in selected_elections) {
  for (level in c("preference_vote_area", "district"))
    for (by_list in c(FALSE, TRUE)) for (zeros in c(FALSE, TRUE)) {
      x <- validate("preference_votes", list(year = 2010L, election = v, level = level,
        by_list = by_list, include_zeros = zeros, progress = FALSE), paste("preference", v, level, by_list, zeros))
      key <- intersect(c("candidate_number", "party_code", "preference_vote_area_code", "district_code", "district_type", "list_number"), names(x))
      stopifnot(!anyDuplicated(x[key]))
      known <- !is.na(x$preference_votes) & !is.na(x$party_votes) & x$party_votes > 0L
      stopifnot(all(x$preference_vote_share[known] == x$preference_votes[known] / x$party_votes[known]))
    }
  if (v != "RD") validate("preference_votes", list(year = 2010L, election = v,
    level = if (v == "RF") "region" else "municipality", progress = FALSE), paste("preference", v, "aggregate"))
}
cat("COMPLETE", section, "\n")
