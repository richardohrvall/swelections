# Local unpublished 2019 municipal referendum build:
# Rscript data-raw/build-canonical-referendum-2019.R SOURCE_DIRECTORY OUTPUT_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify SOURCE_DIRECTORY OUTPUT_DIRECTORY.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) {
  stop("Install optional nanoparquet for builds.")
}
src <- args[[1]]
out <- args[[2]]
if (!dir.exists(src)) stop("Missing source directory: ", src)
if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) {
  stop("Use an empty output directory.")
}
dir.create(out, recursive = TRUE, showWarnings = FALSE)

sources_spec <- swelections:::.referendum_2019_oland_sources()
source_records <- vector("list", nrow(sources_spec))
for (i in seq_len(nrow(sources_spec))) {
  entry <- sources_spec[i, , drop = FALSE]
  p <- swelections:::.referendum_municipal_file(entry, "local", src)
  stopifnot(
    identical(as.integer(file.info(p)$size), as.integer(entry$bytes)),
    identical(swelections:::.canonical_sha256(p), entry$sha256)
  )
  source_records[[i]] <- data.frame(
    election_event = entry$election_event,
    municipality_code = entry$municipality_code,
    municipality_name = entry$municipality_name,
    file = entry$filename,
    bytes = as.integer(file.info(p)$size),
    md5 = unname(tools::md5sum(p)),
    sha256 = entry$sha256,
    url = entry$url,
    stringsAsFactors = FALSE
  )
}

levels <- c("municipality", "district")
parts <- lapply(levels, function(level) {
  full <- results(2019, election = "referendum", level = level,
                  source = "local", data_dir = src, names = "en", detail = "full")
  standard <- results(2019, election = "referendum", level = level,
                      source = "local", data_dir = src, names = "en", detail = "standard")
  stopifnot(identical(full[names(standard)], standard))
  idx <- match(full$municipality_code, sources_spec$municipality_code)
  stopifnot(!anyNA(idx))
  full$source_file <- sources_spec$filename[idx]
  full
})
names(parts) <- levels

asset <- "referendum2019-results-final"
tables <- data.frame(
  asset = asset,
  table = levels,
  columns = vapply(parts, function(x) paste(names(x), collapse = ","), ""),
  standard_columns = vapply(
    levels,
    function(level) {
      paste(names(results(2019, election = "referendum", level = level,
                          source = "local", data_dir = src, names = "en",
                          detail = "standard")), collapse = ",")
    },
    ""
  ),
  stringsAsFactors = FALSE
)

x <- purrr::list_rbind(lapply(levels, function(level) {
  z <- parts[[level]]
  z$.table <- level
  z
}))
x[] <- lapply(x, unname)
parquet_file <- file.path(out, paste0(asset, ".parquet"))
nanoparquet::write_parquet(x, parquet_file, compression = "gzip")
stopifnot(identical(x, tibble::as_tibble(nanoparquet::read_parquet(parquet_file))))

source("data-raw/canonical-build-contract.R")
events_df <- swelections:::.referendum_events()
events_df <- events_df[events_df$election_year == 2019L, , drop = FALSE]
manifest <- canonical_build_contract(list(
  format = "parquet",
  valserie = "folkomr",
  valar = 2019L,
  event_kind = "ordinary",
  auto_eligible = FALSE,
  events = events_df,
  sources = dplyr::bind_rows(source_records),
  assets = data.frame(
    asset = asset,
    file = basename(parquet_file),
    rows = nrow(x),
    bytes = unname(file.info(parquet_file)$size),
    sha256 = swelections:::.canonical_sha256(parquet_file),
    stringsAsFactors = FALSE
  ),
  tables = tables,
  source_selection = list(
    primary = "Archived Borgholm (0885) and Mörbylånga (0840) final referendum tables from 2019-05-26/2019-05-29",
    options = "JA, NEJ and BLANK are valid voting options; invalid ballots are unreported in municipal tables so invalid_votes, total_votes and turnout remain typed NA",
    geography = "19 ordinary voting districts plus 2 municipal Wednesday collection units (F-0840-00, F-0885-00) matching EU 2019 district codes",
    electorate = "Wednesday collection units have missing eligible_voters and turnout; ordinary referendum electorate includes municipal referendum voters beyond EU 2019 citizens",
    preliminary = "Complete preliminary source unavailable"
  )
))
manifest_path <- file.path(out, "referendum2019-manifest.json")
jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE, na = "null")
swelections:::.canonical_manifest(manifest_path)

cat("PASS unpublished 2019 referendum build:", nrow(x), "rows, 2 source hashes, Parquet round trip\n")
