# Rscript development/validate_r_only_2022.R REFERENCE_MANIFEST R_STAGE [REPORT]
# Independent byte/JSON/provenance comparison of the preparation implementations.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 2L)
source("data-raw/prepare-canonical-2022.R")
reference <- jsonlite::read_json(args[[1]], simplifyVector = FALSE)
stage <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
old_stage <- reference$raw_input_archive
report_path <- if (length(args) >= 3L) args[[3]] else file.path(stage, "preparation-comparison.json")
old_files <- sort(list.files(file.path(old_stage, "2022", "val2022"),
  pattern = "[.]zip$", recursive = TRUE), method = "radix")
new_files <- sort(list.files(file.path(stage, "2022", "val2022"),
  pattern = "[.]zip$", recursive = TRUE), method = "radix")
stopifnot(identical(old_files, new_files), length(new_files) == 623L)
differences <- list(); members_checked <- 0L; reconstructed <- 0L
for (name in new_files) {
  old <- file.path(old_stage, "2022", "val2022", name)
  new <- file.path(stage, "2022", "val2022", name)
  old_catalog <- utils::unzip(old, list = TRUE)
  new_catalog <- utils::unzip(new, list = TRUE)
  stopifnot(identical(old_catalog$Name, new_catalog$Name))
  changed_members <- character()
  for (member in old_catalog$Name) {
    a <- canonical2022_member(old, member); b <- canonical2022_member(new, member)
    if (!identical(a, b)) {
      stopifnot(grepl("slutlig_.*_25_RF[.]json$", member),
        isTRUE(all.equal(canonical2022_json(a), canonical2022_json(b), tolerance = 0)))
      changed_members <- c(changed_members, member)
      reconstructed <- reconstructed + 1L
    }
    members_checked <- members_checked + 1L
  }
  if (!identical(canonical2022_bytes(old), canonical2022_bytes(new)))
    differences[[length(differences) + 1L]] <- list(file = name,
      old_sha256 = canonical2022_digest(canonical2022_bytes(old), "sha256"),
      new_sha256 = canonical2022_digest(canonical2022_bytes(new), "sha256"),
      changed_member_bytes = changed_members,
      old_dates = as.character(old_catalog$Date), new_dates = as.character(new_catalog$Date),
      explanation = if (length(changed_members)) "JSON serializer and ZIP implementation" else
        if (name == "parti/kandidaturer.zip") "Fixed candidate timestamp and ZIP implementation" else
          "ZIP implementation; extracted members byte-identical")
}
stopifnot(members_checked == 1245L, reconstructed <= 2L)
# Compare inventoried generations and correction paths independently of path separators.
actual <- jsonlite::read_json(file.path(stage, "provenance.json"), simplifyVector = FALSE)
normalise_source <- function(x) {
  x$source <- gsub("\\", "/", x$source, fixed = TRUE)
  if (x$classification == "official_historical_candidate_snapshot") x$url <- NULL
  # Builder adds the historical candidate URL after preparation; other URLs
  # must still be equal.
  x
}
stopifnot(identical(lapply(reference$sources, normalise_source),
  lapply(actual$sources, normalise_source)))
for (i in seq_along(actual$harmonisation)) {
  a <- reference$harmonisation[[i]]; b <- actual$harmonisation[[i]]
  a$source <- gsub("\\", "/", a$source, fixed = TRUE)
  a$derived_sha256 <- b$derived_sha256 <- NULL
  stopifnot(identical(a, b))
}
# Repeated ZIP writes must be byte-identical, not merely equivalent JSON.
samples <- c(head(new_files, 1L), "s/rf/Val_20220911_slutlig_25_RF.zip", "parti/kandidaturer.zip")
for (name in samples) {
  file <- file.path(stage, "2022", "val2022", name)
  members <- setNames(lapply(utils::unzip(file, list = TRUE)$Name,
    function(member) canonical2022_member(file, member)), utils::unzip(file, list = TRUE)$Name)
  again <- tempfile(fileext = ".zip")
  canonical2022_zip(again, members)
  stopifnot(identical(canonical2022_bytes(file), canonical2022_bytes(again)))
  unlink(again)
}
# Explicit scalar-type, party/list-scope and cardinality regressions.
fixture <- list(valtyp = "RF", valtillfalle = "Val_20220911",
  valomrade = list(kod = "25", parti = list(partikod = "0110", listnummer = "0110-03652",
    kandidatNummer = "50975", nested = list(kandidatnummer = 50975L))))
x <- canonical2022_correct(fixture, "mandatfordelning")
stopifnot(identical(x$raw$valomrade$parti$kandidatNummer, "488"),
  identical(x$raw$valomrade$parti$nested$kandidatnummer, 488L),
  identical(fixture$valomrade$parti$kandidatNummer, "50975"))
bad <- fixture; bad$valomrade$parti$partikod <- "9999"
stopifnot(inherits(try(canonical2022_correct(bad, "mandatfordelning"), silent = TRUE), "try-error"))
jsonlite::write_json(list(containers = 623L, extracted_members = members_checked,
  reconstructed_json_byte_differences = reconstructed, differences = differences,
  repeated_zip_identity = TRUE, provenance_equivalence = TRUE, scoped_id_tests = TRUE),
  report_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
cat("PASS 623 containers, 1245 members, source provenance and scoped identity tests\n")
cat("Explained ZIP differences:", length(differences), "; transformed JSON:", reconstructed, "\n")
