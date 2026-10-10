# Actual package outputs for the separately parsed XML/SKV validator.
# Rscript development/export_source_validation_2010.R [ARCHIVE_ROOT OUTPUT_JSON]
pkgload::load_all(".", quiet = TRUE)
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else ".local-data/rkl"
target <- if (length(args) >= 2L) args[[2]] else ".local-data/2010-independent-outputs.json"
if (file.exists(target)) stop("Choose a new output file; preserved references are immutable.")
s <- swelections:::.sources_2010("local", root)
outputs <- list()
for (v in c("RD", "RF", "KF")) {
  b <- swelections:::.xml2014_bundle(s, v, FALSE)
  ca <- swelections:::.kandidater_2014(s, v, TRUE, FALSE, b)
  el <- swelections:::.valda_2014(s, v, FALSE, b)
  su <- b$relations$ersattare
  pv <- ca$antal_personroster_totalt
  outputs[[v]] <- list(ballot_rows = nrow(b$kd), population_rows = nrow(b$population),
    candidates = nrow(ca), elected = nrow(el), substitutes = nrow(su),
    positive = sum(pv > 0, na.rm = TRUE), zero = sum(pv == 0, na.rm = TRUE),
    missing = sum(is.na(pv)), preference_votes = sum(b$areas$roster$antal_personroster),
    elected_data = el, substitute_data = su, area_votes = b$areas$roster)
  cat("Exported source-validation outputs", v, "\n")
}
jsonlite::write_json(outputs, target, auto_unbox = TRUE, na = "null", null = "null")
