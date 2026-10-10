# Independent raw JSON trace; never reconciles area/district values.
# Rscript development/diagnose_2022_rd_person_votes.R [SOURCE_ROOT AUDIT_JSON REPORT_JSON]
source("development/source_tools.R")
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else ".local-data/rkl/2022/valresultat/filer"
input <- if (length(args) >= 2L) args[[2]] else ".local-data/canonical-build/2022-aggregate-audit.json"
target <- if (length(args) >= 3L) args[[3]] else ".local-data/r-only-2022-rd-person-vote-traces.json"
differences <- audit_json(input)[[1]]$differences
keys <- vapply(differences, function(x) audit_tuple(list(x$preference_vote_area_code,
  x$party_code, x$candidate_number)), "")
party_keys <- vapply(differences, function(x) audit_tuple(list(x$preference_vote_area_code, x$party_code)), "")
parties <- function(x) {
  if (!is.list(x)) return(list())
  if (all(c("partikod", "listRoster") %in% names(x))) return(list(x))
  result <- list()
  for (child in x) result <- c(result, parties(child))
  result
}
env <- function() new.env(parent = emptyenv())
party_records <- list(area = env(), district = env())
list_records <- list(area = env(), district = env()); target_lists <- env()
observed <- list(area = env(), district = env())
area_names <- env(); metadata <- list()
append_record <- function(env, key, value) {
  if (!exists(key, env, inherits = FALSE)) attr(env, "record_keys") <- c(attr(env, "record_keys"), key)
  x <- if (exists(key, env, inherits = FALSE)) env[[key]] else list()
  env[[key]] <- c(x, list(value))
}
get_records <- function(env, key) if (exists(key, env, inherits = FALSE)) env[[key]] else list()
for (level in c("area", "district")) {
  kind <- if (level == "area") "mandatfordelning" else "rostfordelning"
  raw <- audit_json(file.path(root, paste0("Val_20220911_slutlig_", kind, "_00_RD.json")))
  owner <- if (level == "area") raw$valomrade else raw
  meta <- c("senasteUppdateringstid", "antalUppdateringar")
  counts <- c("antalValdistriktRaknade", "antalValdistriktSomSkaRaknas")
  metadata[[level]] <- c(setNames(lapply(meta, function(field) raw[[field]]), meta),
    setNames(lapply(counts, function(field) owner[[field]]), counts))
  nodes <- if (level == "area") raw$valomrade$valkretsLista else raw$valdistrikt
  for (node in nodes) {
    area <- as.character(if (level == "area") node$kod else node$kretskod)
    if (level == "area") area_names[[area]] <- node$namnValkrets
    for (party in parties(node$rostfordelning)) {
      id <- as.character(party$partikod); party_key <- audit_tuple(list(area, id))
      if (party_key %in% party_keys) append_record(party_records[[level]], party_key,
        list(votes = party$antalRoster, district_code = node$valdistriktskod))
      for (ballot in party$listRoster) {
        list_key <- audit_tuple(list(area, id, ballot$listnummer))
        persons <- ballot$personroster
        candidate_keys <- vapply(persons, function(p) audit_tuple(list(area, id, as.character(p$kandidatNummer))), "")
        if (level == "area" && any(candidate_keys %in% keys)) target_lists[[list_key]] <- TRUE
        if (exists(list_key, target_lists, inherits = FALSE)) append_record(list_records[[level]], list_key,
          list(votes = ballot$antalRoster, votes_with_preference = ballot$antalRosterMedPersonrost,
            identified_candidate_votes = sum(vapply(persons, function(p) p$antalPersonroster, 0))))
        for (p in persons) {
          key <- audit_tuple(list(area, id, as.character(p$kandidatNummer)))
          if (key %in% keys) append_record(observed[[level]], key,
            list(list_number = ballot$listnummer, name = p$namn, votes = p$antalPersonroster,
              ballot_order = p$kandidatNummerPaListan, district_code = node$valdistriktskod,
              district_type = node$valdistriktstyp))
        }
      }
    }
  }
}
sum_field <- function(posts, field) sum(vapply(posts, function(x) if (is.null(x[[field]])) 0 else x[[field]], 0))
traces <- lapply(differences, function(row) {
  key <- audit_tuple(list(row$preference_vote_area_code, row$party_code, row$candidate_number))
  party_key <- audit_tuple(list(row$preference_vote_area_code, row$party_code))
  a <- get_records(observed$area, key); d <- get_records(observed$district, key)
  dp <- get_records(party_records$district, party_key)
  trace <- c(row, list(preference_vote_area_name = area_names[[row$preference_vote_area_code]],
    raw_area_list_sum = sum_field(a, "votes"), raw_district_list_sum = sum_field(d, "votes"),
    area_party_records = get_records(party_records$area, party_key), district_party_records_count = length(dp),
    observed_district_party_votes = sum_field(dp, "votes"), area_posts = a, district_posts = d))
  stopifnot(trace$raw_area_list_sum == row$preference_votes, trace$raw_district_list_sum == row$district_sum)
  lists <- sort(unique(vapply(a, `[[`, "", "list_number")), method = "radix")
  trace$list_checks <- lapply(lists, function(number) {
    list_key <- audit_tuple(list(row$preference_vote_area_code, row$party_code, number))
    fields <- c("votes", "votes_with_preference", "identified_candidate_votes")
    list(list_number = number, area = get_records(list_records$area, list_key),
      district_totals = setNames(lapply(fields, function(field)
        sum_field(get_records(list_records$district, list_key), field)), fields))
  })
  trace
})
within <- list()
for (level in names(list_records)) for (key in attr(list_records[[level]], "record_keys"))
  for (post in list_records[[level]][[key]]) if (post$votes_with_preference != post$identified_candidate_votes)
    within[[length(within) + 1L]] <- list(level = level,
      key = jsonlite::fromJSON(key, simplifyVector = FALSE), record = post)
result <- list(metadata = metadata, differences = traces, count = length(traces),
  excess_area_votes = sum(vapply(traces, function(x) x$raw_area_list_sum - x$raw_district_list_sum, 0)),
  within_list_counter_differences = within)
stopifnot(result$count == 14L, result$excess_area_votes == 15L)
reference <- ".local-data/canonical-build/2022-rd-person-vote-source-traces.json"
if (file.exists(reference)) stopifnot(audit_json_equal(result, audit_json(reference)))
audit_write(result, target)
cat("PASS 14 combinations, 15-vote discrepancy preserved; source trace matches\n")
