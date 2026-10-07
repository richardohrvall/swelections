# Opt-in complete public/raw equivalence sweep for a local unpublished build.
# Rscript development/validate_canonical_2022.R OUTPUT_DIR [REPORT_JSON]
# The raw comparison archive is the pinned, derived staging archive identified
# in the manifest. All preserved originals are checked again independently.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Specify the canonical asset directory.")
pkgload::load_all(".", quiet = TRUE)
dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
manifest_path <- file.path(dir, "manifest.json")
m <- swelections:::.canonical_manifest(manifest_path)
raw_dir <- m$raw_input_archive
if (!dir.exists(raw_dir)) stop("Pinned raw comparison archive is unavailable.")
report <- if (length(args) >= 2L) args[[2]] else
  file.path(dirname(dir), "canonical-2022-validation.json")
sections <- if (length(args) >= 3L) strsplit(args[[3]], ",", fixed = TRUE)[[1]] else
  c("results", "seats", "candidacies", "candidates", "elected", "substitutes", "preference_votes")
aggregation_only <- length(args) >= 4L && identical(args[[4]], "aggregation")
old <- options(swelections.canonical_manifest = manifest_path,
  swelections.canonical_assets_dir = dir,
  swelections.names = "en",
  swelections.canonical_cache_dir = tempfile("swc22-"))
checks <- list()
discrepancies <- list()
resume <- identical(Sys.getenv("SWELECTIONS_VALIDATION_RESUME"), "1")
if (resume && file.exists(report)) {
  previous <- jsonlite::read_json(report, simplifyVector = FALSE)
  expected <- m$assets[c("asset", "sha256")]
  if (!is.null(previous$asset_checksums)) {
    recorded <- jsonlite::fromJSON(report)$asset_checksums
    stopifnot(identical(recorded$asset, expected$asset),
              identical(recorded$sha256, expected$sha256))
  } else {
    # One interrupted initial prototype sweep predates checkpoint metadata.
    stopifnot(identical(swelections:::.canonical_sha256(manifest_path),
      "5950160ad3cc461082319f41ac6f27425f22c037e4b1b5ccfb507c3a788f04a6"))
  }
  checks <- previous$checks
  discrepancies <- previous$discrepancies
}
record <- function(tag, status, details = NULL) {
  checks[[length(checks) + 1L]] <<- list(test = tag, status = status, details = details)
  cat(status, tag, "\n")
  jsonlite::write_json(list(checks = checks, discrepancies = discrepancies,
    asset_checksums = m$assets[c("asset", "sha256")], raw_archive = raw_dir), report,
    auto_unbox = TRUE, pretty = TRUE, na = "null")
}
same <- function(x, y, tag) {
  if (!identical(x, y)) {
    delta <- all.equal(x, y)
    discrepancies[[length(discrepancies) + 1L]] <<- list(test = tag, differences = delta)
    record(tag, "FAIL", delta)
    stop("Canonical/raw difference: ", tag)
  }
}
clean <- function(x) {
  for (field in names(x)) names(x[[field]]) <- NULL
  x
}
for (i in seq_len(nrow(m$assets))) {
  a <- m$assets[i, ]
  path <- file.path(dir, a$file)
  stopifnot(identical(as.numeric(file.info(path)$size), as.numeric(a$bytes)),
    identical(swelections:::.canonical_sha256(path), a$sha256))
}
stopifnot(setequal(list.files(dir), c(m$assets$file, "manifest.json")))
for (i in seq_len(nrow(m$sources))) {
  s <- m$sources[i, ]
  if (file.exists(s$source)) stopifnot(
    identical(tolower(unname(tools::md5sum(s$source))), s$md5),
    identical(swelections:::.canonical_sha256(s$source), s$sha256))
}
record("original snapshot hashes and asset sizes/SHA256", "PASS")
key_fields <- list(
  candidacies = c("election_year", "election_code", "electoral_area_code",
    "constituency_code", "municipal_constituency_code", "party_code",
    "list_number", "ballot_order", "candidate_number"),
  results = c("election_year", "election_code", "count_stage", "geographic_level",
    "district_code", "district_type", "municipality_code", "region_code",
    "municipal_constituency_code", "constituency_code", "other_parties", "party_code"),
  seats = c("election_year", "election_code", "geographic_level", "electoral_area_code",
    "constituency_code", "municipal_constituency_code", "party_code"),
  candidates = c("election_year", "election_code", "candidate_number", "party_code"),
  elected = c("election_year", "election_code", "candidate_number", "party_code"),
  substitutes = c("election_year", "election_code", "electoral_area_code",
    "municipality_code", "region_code", "constituency_code", "municipal_constituency_code",
    "party_code", "member_candidate_number", "substitute_candidate_number", "substitute_order"),
  preference_votes = c("election_year", "election_code", "preference_vote_area_code",
    "municipality_code", "region_code", "district_code", "district_type",
    "candidate_number", "party_code", "list_number"))
validate <- function(name, args, label) {
  if (!name %in% sections) return(invisible(NULL))
  fun <- getExportedValue("swelections", name)
  completed <- vapply(checks, function(x)
    identical(x$test, label) && identical(x$status, "PASS"), logical(1))
  if (resume && any(completed)) {
    cat("REUSE recorded raw/canonical PASS", label, "\n")
    # A completed panel plus its recorded subset/zero audit need not be
    # reconstructed merely to resume the remaining requests.
    zero_audit <- paste(args$election, isTRUE(args$by_list),
                        "verified added district zeros")
    if (name == "preference_votes" && identical(args$level, "district") &&
        isTRUE(args$include_zeros) && any(vapply(checks, function(x)
          identical(x$test, zero_audit) && identical(x$status, "PASS"), logical(1))))
      return(invisible(NULL))
    return(clean(do.call(fun, c(args,
      list(source = "canonical", names = "en", detail = "full")))))
  }
  # Official raw path is actually exercised, not replaced with stored expected output.
  source_warnings <- character()
  elapsed <- system.time(expected <- withCallingHandlers(clean(do.call(fun, c(args,
    list(source = "local", data_dir = raw_dir, names = "en", detail = "full")))),
    warning = function(w) source_warnings <<- c(source_warnings, conditionMessage(w))))[["elapsed"]]
  # Read/decode the actual canonical backend once per argument set. The four
  # public language/detail calls still execute their real wrappers/projections;
  # a completed multi-million-row panel need not be decoded four times.
  reader <- swelections:::.canonical_source
  memo <- new.env(parent = emptyenv())
  memo$args <- NULL
  cached_reader <- function(...) {
    current <- list(...)
    if (!identical(current, memo$args)) {
      memo$data <- do.call(reader, current)
      memo$args <- current
    }
    memo$data
  }
  testthat::local_mocked_bindings(.canonical_source = cached_reader,
    .package = "swelections", .env = environment())
  got <- clean(do.call(fun, c(args, list(source = "canonical", names = "en", detail = "full"))))
  same(got, expected, paste(label, "full en/raw"))
  rm(expected); gc()
  full_sv <- do.call(fun, c(args, list(source = "canonical", names = "sv", detail = "full")))
  same(clean(swelections:::.public_output_names(full_sv, "en")), got,
       paste(label, "full sv/en"))
  rm(full_sv); gc()
  standard <- clean(do.call(fun, c(args, list(source = "canonical", names = "en"))))
  same(standard, got[names(standard)], paste(label, "standard projection"))
  standard_sv <- do.call(fun, c(args, list(source = "canonical", names = "sv")))
  same(clean(swelections:::.public_output_names(standard_sv, "en")), standard,
       paste(label, "standard sv/en"))
  rm(standard_sv); gc()
  stopifnot(nrow(got) == nrow(standard), ncol(standard) < ncol(got),
    !any(vapply(got, is.list, logical(1))))
  fields <- intersect(key_fields[[name]], names(got))
  if (length(fields)) {
    if (dplyr::n_distinct(got[fields]) != nrow(got)) stop("Duplicate public key: ", label)
  }
  preference <- if (name %in% c("preference_votes", "candidates"))
    intersect(c("preference_votes", "total_preference_votes"), names(got)) else character()
  details <- list(rows = nrow(got), standard_columns = ncol(standard),
    full_columns = ncol(got), raw_elapsed_seconds = elapsed,
    source_warnings = unique(source_warnings),
    types = vapply(got, typeof, ""), missing = vapply(got, function(x) sum(is.na(x)), 0L))
  if (length(preference)) {
    x <- got[[preference[[1]]]]
    details$preference_counts <- c(positive = sum(x > 0L, na.rm = TRUE),
                                  zero = sum(x == 0L, na.rm = TRUE), missing = sum(is.na(x)))
  }
  if (name == "results") {
    known <- !is.na(got$total_votes) & !is.na(got$valid_votes) & !is.na(got$invalid_votes)
    stopifnot(all(got$total_votes[known] == got$valid_votes[known] + got$invalid_votes[known]))
    stopifnot(all(got$votes[!is.na(got$votes)] >= 0L))
  }
  if (name == "preference_votes") {
    known <- !is.na(got$preference_votes) & !is.na(got$party_votes) & got$party_votes > 0L
    stopifnot(all(got$preference_vote_share[known] ==
                   got$preference_votes[known] / got$party_votes[known]))
    if (!is.null(args$level) && args$level %in% c("municipality", "region"))
      stopifnot(!"qualified_by_preference_votes" %in% names(got))
    if ("list_votes" %in% names(got)) {
      zero_denominator <- !is.na(got$list_votes) & got$list_votes == 0L
      stopifnot(all(is.na(got$list_preference_vote_share[zero_denominator])))
    }
  }
  record(label, "PASS", details)
  invisible(got)
}
levels <- list(RD = c("district", "parliamentary_constituency", "national"),
  RF = c("district", "regional_constituency", "region"),
  KF = c("district", "municipal_constituency", "municipality"))
if (length(args) >= 4L && identical(args[[4]], "mixed")) {
  for (name in c("elected", "substitutes"))
    validate(name, list(year = 2022L, election = c("RF", "RD"), progress = FALSE),
             paste(name, "requested RF/RD order"))
  validate("preference_votes", list(year = 2022L, progress = FALSE),
           "preference_votes mixed RD/RF/KF raw ordering")
  options(old)
  cat("Mixed-election public/raw sweep finished. Report:", report, "\n")
  quit(status = 0L)
}
for (v in names(levels)) for (count in c("preliminary", "final")) {
  for (level in levels[[v]]) validate("results", list(year = 2022L, election = v,
    count = count, level = level, progress = FALSE), paste("results", v, count, level))
  for (level in setdiff(levels[[v]], "district")) validate("seats", list(
    year = 2022L, election = v, count = count, level = level, progress = FALSE),
    paste("seats", v, count, level))
}
for (v in names(levels)) for (name in c("candidacies", "candidates", "elected", "substitutes")) {
  extra <- if (name != "candidacies") list(progress = FALSE) else list()
  validate(name, c(list(year = 2022L, election = v), extra), paste(name, v))
}
if ("preference_votes" %in% sections && !aggregation_only)
for (v in names(levels)) for (level in c("preference_vote_area", "district"))
  for (by_list in c(FALSE, TRUE)) for (zeros in c(FALSE, TRUE)) {
    out <- validate("preference_votes", list(year = 2022L, election = v,
      level = level, by_list = by_list, include_zeros = zeros, progress = FALSE),
      paste("preference_votes", v, level, by_list, zeros))
    if (zeros && level == "district" && !is.null(out)) {
      sparse <- preference_votes(2022L, election = v, level = level,
        by_list = by_list, include_zeros = FALSE, source = "canonical",
        names = "en", detail = "full")
      full <- out
      key <- intersect(key_fields$preference_votes, names(full))
      added <- dplyr::anti_join(full, sparse, by = key)
      stopifnot(all(!is.na(added$preference_votes)), all(added$preference_votes == 0L))
      common <- dplyr::semi_join(full, sparse, by = key)
      same(clean(common), clean(sparse), paste(v, by_list, "completed panel preserves sparse rows"))
      record(paste(v, by_list, "verified added district zeros"), "PASS", nrow(added))
      rm(sparse, full, added, common)
    }
    rm(out); gc()
  }
for (v in c("RF", "KF")) {
  aggregate <- validate("preference_votes", list(year = 2022L,
    election = v, level = if (v == "RF") "region" else "municipality", progress = FALSE),
    paste("preference_votes", v, "broader aggregation"))
  if ("preference_votes" %in% sections) {
    area <- preference_votes(2022L, election = v, source = "canonical", detail = "full")
    parent_key <- c("election_year", "election_code", "electoral_area_code")
    party_key <- c(parent_key, "party_code")
    candidate_key <- c(party_key, "candidate_number")
    encode <- function(x, fields) do.call(paste, c(x[fields], sep = "\r"))
    parent_areas <- tapply(area$preference_vote_area_code, encode(area, parent_key),
                           function(x) length(unique(x)))
    party_areas <- unique(area[c(party_key, "preference_vote_area_code", "party_votes")])
    party_denominators <- vapply(split(party_areas, encode(party_areas, party_key)),
      function(x) {
        complete <- nrow(x) == parent_areas[[encode(x[1L, ], parent_key)]]
        if (!complete || anyNA(x$party_votes)) NA_integer_ else as.integer(sum(x$party_votes))
      }, 0L)
    candidate_numerators <- vapply(split(area, encode(area, candidate_key)),
      function(x) if (anyNA(x$preference_votes)) NA_integer_ else as.integer(sum(x$preference_votes)), 0L)
    # The public broader view deliberately refuses partial party-area coverage.
    complete_party <- vapply(split(party_areas, encode(party_areas, party_key)),
      function(x) nrow(x) == parent_areas[[encode(x[1L, ], parent_key)]], logical(1))
    candidate_numerators[!complete_party[encode(area[match(names(candidate_numerators),
      encode(area, candidate_key)), ], party_key)]] <- NA_integer_
    same(unname(candidate_numerators[encode(aggregate, candidate_key)]),
         aggregate$preference_votes, paste(v, "independent area numerator sum"))
    same(unname(party_denominators[encode(aggregate, party_key)]),
         aggregate$party_votes, paste(v, "independent area denominator sum"))
    stopifnot(!"qualified_by_preference_votes" %in% names(aggregate))
    record(paste(v, "independent non-overlapping area aggregation"), "PASS",
      list(rows = nrow(aggregate), missing_numerator = sum(is.na(aggregate$preference_votes)),
           missing_denominator = sum(is.na(aggregate$party_votes))))
  }
}
for (v in names(levels)) validate("candidates", list(year = 2022L, election = v,
  include_results = FALSE, progress = FALSE), paste("candidates", v, "without results"))
for (name in c("candidacies", "candidates", "elected", "substitutes")) {
  extra <- if (name != "candidacies") list(progress = FALSE) else list()
  validate(name, c(list(year = 2022L), extra), paste(name, "mixed RD/RF/KF"))
}
# Election-time Norrbotten relationships, not later mandate-period replacements.
if (any(c("elected", "substitutes") %in% sections)) {
e <- elected(2022L, election = "RF", source = "canonical", detail = "full", progress = FALSE)
e25 <- dplyr::filter(e, .data$elected_electoral_area_code == "25")
stopifnot("488" %in% e25$candidate_number, !"50975" %in% e25$candidate_number,
          "15077" %in% e25$candidate_number, !"16569" %in% e25$candidate_number)
s <- substitutes(2022L, election = "RF", source = "canonical", detail = "full", progress = FALSE)
s25 <- dplyr::filter(s, .data$source_electoral_area_code == "25")
stopifnot("488" %in% s25$member_candidate_number,
          "16569" %in% s25$substitute_candidate_number,
          "40674" %in% s25$substitute_candidate_number,
          "18598" %in% s25$substitute_candidate_number)
stopifnot(nrow(e25) == 71L, nrow(s25) == 1259L)
bo <- candidates(2022L, election = "RF", source = "canonical", progress = FALSE)
bo <- dplyr::filter(bo, .data$candidate_number == "488", .data$party_code == "0110")
stopifnot(nrow(bo) == 1L, bo$total_preference_votes == 430L)
record("Norrbotten corrected Bo ID and original election-time relations", "PASS",
       list(elected = nrow(e25), substitute_relations = nrow(s25), Bo_preference_votes = 430L))
}
if ("seats" %in% sections) {
  empty <- vapply(names(levels), function(v) {
    level <- c(RD = "national", RF = "region", KF = "municipality")[[v]]
    x <- seats(2022L, election = v, level = level, source = "canonical", progress = FALSE)
    if (anyNA(x$unfilled_seats)) stop("Unknown election-time unfilled seat count: ", v)
    sum(x$unfilled_seats)
  }, 0L)
  stopifnot(identical(unname(empty), c(0L, 0L, 17L)))
  record("election-time unfilled seats RD/RF/KF", "PASS", empty)
}
if ("candidates" %in% sections) {
  kd <- candidacies(2022L, source = "canonical", detail = "full")
  ca <- candidates(2022L, source = "canonical", detail = "full", progress = FALSE)
  el <- elected(2022L, source = "canonical", detail = "full", progress = FALSE)
  su <- substitutes(2022L, source = "canonical", detail = "full", progress = FALSE)
  key <- c("election_year", "election_code", "party_code", "candidate_number")
  valid <- dplyr::distinct(dplyr::filter(kd, .data$valid %in% TRUE),
    dplyr::across(dplyr::all_of(key)))
  stopifnot(!nrow(dplyr::anti_join(ca, valid, by = key)),
            !nrow(dplyr::anti_join(valid, ca, by = key)))
  selected <- dplyr::filter(ca, .data$elected %in% TRUE)
  stopifnot(!nrow(dplyr::anti_join(el, selected, by = key)),
            !nrow(dplyr::anti_join(selected, el, by = key)))
  for (field in c("member_candidate_number", "substitute_candidate_number")) {
    relations <- su[c("election_year", "election_code", "party_code", field)]
    names(relations)[[4L]] <- "candidate_number"
    stopifnot(!nrow(dplyr::anti_join(relations, valid, by = key)))
    if (field == "member_candidate_number")
      stopifnot(!nrow(dplyr::anti_join(relations, el, by = key)))
  }
  shared <- intersect(c("total_preference_votes", "qualified_by_preference_votes",
    "preference_vote_areas_count", "elected_electoral_area_code",
    "elected_constituency_code", "order_of_election", "election_basis_id"), names(el))
  matched <- dplyr::left_join(el[key], selected[c(key, shared)], by = key,
                            relationship = "one-to-one")
  differences <- lapply(shared, function(field) {
    a <- el[[field]]; b <- matched[[field]]
    different <- xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b)
    rows <- which(different)
    if (!length(rows)) return(NULL)
    cbind(el[rows, c(key, "name")], data.frame(field = field,
      elected_value = as.character(a[rows]), candidate_value = as.character(b[rows])))
  }) |> purrr::list_rbind()
  if (nrow(differences)) {
    discrepancies[[length(discrepancies) + 1L]] <- list(
      test = "candidate/elected shared result values",
      classification = "Existing raw API cross-surface difference, not reconciled in canonical data",
      differences = differences)
    record("candidate/elected shared result values", "FAIL", differences)
  } else record("candidate/elected shared result values", "PASS")
  record("valid candidate population and elected/substitute references", "PASS",
    list(candidacies = nrow(kd), candidate_keys = nrow(ca),
         elected_keys = nrow(el), substitute_relations = nrow(su)))
}
options(old)
cat("Public/raw sweep finished; unresolved diagnostics:", length(discrepancies),
    ". Report:", report, "\n")
