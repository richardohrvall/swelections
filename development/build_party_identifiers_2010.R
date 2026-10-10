# Rscript development/build_party_identifiers_2010.R [RAW_ROOT OUTPUT_DIR]
# Party identity metadata only. Never imports votes or candidate identities.
source("development/source_tools.R")
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else ".local-data/rkl"
out <- if (length(args) >= 2L) args[[2]] else ".local-data/r-only-party-identifiers-2010"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source_zip <- file.path(root, "2006", "valresultat", "xml.zip")
records <- list()
decode <- function(x) xml2::xml_text(xml2::read_html(paste0("<span>", x, "</span>")))
for (member in utils::unzip(source_zip, list = TRUE)$Name) {
  if (!endsWith(member, ".zip")) next
  letter <- substr(member, nchar(member) - 4L, nchar(member) - 4L)
  v <- c(R = "RD", L = "RF", K = "KF")[[letter]]
  if (is.null(v)) next
  area <- if (v == "KF") substr(member, 1, 4) else if (v == "RF") substr(member, 1, 2) else "00"
  nested <- tempfile(tmpdir = out, fileext = ".zip"); writeBin(audit_zip(source_zip, member), nested)
  for (name in utils::unzip(nested, list = TRUE)$Name) {
    if (!endsWith(name, ".xml")) next
    doc <- audit_xml(nested, name)
    for (party in xml2::xml_find_all(doc, ".//PARTI[@KOD and @BETECKNING]"))
      records[[length(records) + 1L]] <- c(v, area, decode(xml2::xml_attr(party, "BETECKNING")), xml2::xml_attr(party, "KOD"))
  }
  unlink(nested)
}
records <- unique(do.call(rbind, records)); values <- list()
current <- file.path(root, "2010", "valresultat", "slutresultat.zip")
for (member in utils::unzip(current, list = TRUE)$Name) {
  if (!endsWith(member, ".xml")) next
  letter <- substr(member, nchar(member) - 4L, nchar(member) - 4L)
  v <- c(R = "RD", L = "RF", K = "KF")[[letter]]
  code <- sub(paste0(letter, "[.]xml$"), "", sub("^slutresultat_", "", member))
  area <- if (v == "KF" && nchar(code) == 4L) code else
    if (v == "RF" && nchar(code) == 4L) substr(code, 1, 2) else "00"
  for (party in xml2::xml_find_all(audit_xml(current, member), ".//PARTI")) {
    label <- xml2::xml_attr(party, "BETECKNING")
    codes <- unique(records[records[, 1] == v & records[, 2] == area & records[, 3] == decode(label), 4])
    if (length(codes) == 1L) values[[length(values) + 1L]] <- c(v, area, label, codes)
  }
}
values <- unique(do.call(rbind, values)); values <- values[do.call(order, c(as.data.frame(values), list(method = "radix"))), , drop = FALSE]
colnames(values) <- c("valtyp", "valomradeskod", "partibeteckning", "partikod")
file <- file.path(out, "previous-election-2006.csv")
if (file.exists(file)) stop("Use a new output directory; never replace a preserved lookup.")
readr::write_csv(as.data.frame(values), file, eol = "\r\n", quote = "needed")
reference <- file.path(root, "2010", "kandidater", "official-party-identifiers", "previous-election-2006.csv")
if (file.exists(reference)) {
  preserved <- readr::read_csv(reference, col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  stopifnot(identical(as.data.frame(values, stringsAsFactors = FALSE), as.data.frame(preserved)))
}
audit_write(list(purpose = "Party IDs only for prior-election comparison rows; no 2006 votes/candidates",
  source = source_zip, source_md5 = audit_hash(source_zip, "md5"), source_sha256 = audit_hash(source_zip),
  output_sha256 = audit_hash(file), rows = nrow(values),
  matching = "Exact election/area and source party designation (HTML entities decoded only for matching)"),
  file.path(out, "provenance.json"))
cat("PASS party metadata values", nrow(values), "\n")
