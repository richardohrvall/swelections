# Supplementary identifiers for previous-election comparison parties that have
# no 2014 result list. Votes, candidates and relations are never taken from 2010.
# Usage: Rscript data-raw/build-party-identifiers-2014.R <rkl source root>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
pkgload::load_all(".", quiet = TRUE)
root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
source <- file.path(root, "2010", "valresultat", "slutresultat.zip")
rows <- lapply(c(RD = "R", RF = "L", KF = "K"), function(letter) {
  members <- utils::unzip(source, list = TRUE)$Name
  members <- members[grepl(paste0("^slutresultat_(00|[0-9]{4})", letter, "[.]xml$"), members)]
  lapply(members, function(member) {
    con <- unz(source, member, open = "rb")
    on.exit(close(con))
    doc <- xml2::read_xml(con, options = "NONET")
    stopifnot(xml2::xml_attr(doc, "VALDAG") == "20100919")
    val <- c(R = "RD", L = "RF", K = "KF")[[letter]]
    municipal <- .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD")
    area <- if (val == "RD" || is.na(municipal)) "00" else
      if (val == "RF") substr(municipal, 1L, 2L) else municipal
    .xml2014_register(doc, val, area)$data
  }) |> purrr::list_rbind()
}) |> purrr::list_rbind() |> unique()
folder <- file.path(root, "2014", "kandidater", "official-ballot-metadata")
dir.create(folder, recursive = TRUE, showWarnings = FALSE)
target <- file.path(folder, "party-identifiers-2010-complete.csv")
if (file.exists(target)) {
  existing <- readr::read_csv(target,
    col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  if (!identical(as.data.frame(existing), as.data.frame(rows)))
    stop("Refusing to overwrite different existing metadata: ", target)
} else readr::write_csv(rows, target)
jsonlite::write_json(list(
  purpose = "Official party identifiers only; no 2010 counts or candidates used",
  source = source, md5 = unname(tools::md5sum(source)),
  sha256 = .canonical_sha256(source),
  output_sha256 = .canonical_sha256(target)),
  file.path(folder, "party-identifiers-2010-complete-provenance.json"), auto_unbox = TRUE, pretty = TRUE)
