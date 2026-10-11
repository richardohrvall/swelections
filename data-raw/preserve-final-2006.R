# Preserve official final district sources separately from archived named XML.
# Rscript data-raw/preserve-final-2006.R RAW_ROOT SNAPSHOT_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT SNAPSHOT_DIRECTORY.")
pkgload::load_all(".", quiet = TRUE)
out <- args[[2]]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
base <- "https://historik.val.se/val/val2006/slutlig/xml/"
index <- file.path(out, "index.html")
if (!file.exists(index)) swelections:::.download_file(paste0(base, "index.html"), index)
h <- xml2::read_html(index, options = "NONET")
files <- unique(basename(xml2::xml_attr(xml2::xml_find_all(h, "//a[@href]"), "href")))
files <- sort(files[grepl("^slutresultat_[0-9]{4}[RL][.]xml$", files)])
stopifnot(sum(grepl("R[.]xml$", files)) == 290L, sum(grepl("L[.]xml$", files)) == 289L)
manifest_file <- file.path(out, "source-manifest.json")
records <- if (file.exists(manifest_file)) jsonlite::fromJSON(manifest_file)$sources else NULL
for (i in seq_along(files)) {
  file <- files[[i]]
  target <- file.path(out, file)
  if (!is.null(records) && file %in% records$file) {
    row <- records[records$file == file, ]
    stopifnot(file.exists(target), identical(unname(tools::md5sum(target)), row$md5),
      identical(swelections:::.canonical_sha256(target), row$sha256))
    next
  }
  if (file.exists(target)) stop("Unregistered pre-existing source; do not overwrite: ", target)
  stage <- tempfile(tmpdir = out, fileext = ".xml")
  swelections:::.download_file(paste0(base, file), stage)
  x <- xml2::read_xml(stage, options = "NONET")
  stopifnot(identical(xml2::xml_attr(x, "VALDAG"), "20060917"),
    identical(xml2::xml_attr(x, "FILNAMN"), file),
    identical(xml2::xml_attr(x, "RAPPORTERING"), "SLUTLIG RÖSTRÄKNING RESULTAT"))
  stopifnot(file.rename(stage, target))
  row <- data.frame(file = file, url = paste0(base, file),
    retrieved_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    bytes = unname(file.info(target)$size), md5 = unname(tools::md5sum(target)),
    sha256 = swelections:::.canonical_sha256(target),
    source_report_time = xml2::xml_attr(x, "TID_RAPPORT"))
  records <- dplyr::bind_rows(records, row)
  jsonlite::write_json(list(source = paste0(base, "index.html"),
    index_md5 = unname(tools::md5sum(index)), expected = 579L,
    sources = records), manifest_file, pretty = TRUE, auto_unbox = TRUE)
  if (i %% 20L == 0L) {cat("Preserved", i, "/", length(files), "\n");flush.console()}
  Sys.sleep(.3)
}
stopifnot(nrow(records) == 579L)
cat("PASS complete official municipal collection", nrow(records), "\n")
