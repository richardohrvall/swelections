# Local unpublished referendum build: Rscript ... SOURCE_DIRECTORY OUTPUT_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop('Specify SOURCE_DIRECTORY OUTPUT_DIRECTORY.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('nanoparquet', quietly = TRUE)) stop('Install optional nanoparquet for builds.')
out <- args[[2]]
if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) stop('Use an empty output directory.')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
electorate_provenance <- file.path(args[[1]], 'scb-electorate-composition.html.provenance.json')
if (!file.exists(electorate_provenance)) stop('Build requires SCB electorate composition and provenance.')
electorate_source <- jsonlite::read_json(electorate_provenance, simplifyVector = TRUE)
levels <- c('national', 'county', 'parliamentary_constituency', 'municipality', 'municipal_constituency', 'district')
parts <- lapply(levels, function(level) results(2003, election = 'referendum', level = level,
  source = 'local', data_dir = args[[1]], names = 'en', detail = 'full'))
names(parts) <- unname(swelections:::.english_argument_values$level[levels])
asset <- 'referendum2003-results-final'
tables <- data.frame(asset = asset, table = swelections:::.canonical_storage_key(names(parts)), columns = vapply(parts, function(x) paste(names(x), collapse = ','), ''))
x <- purrr::list_rbind(lapply(names(parts), function(key) {z <- parts[[key]]; z$.table <- swelections:::.canonical_storage_key(key); z}))
x[] <- lapply(x, unname)
file <- file.path(out, paste0(asset, '.parquet'))
nanoparquet::write_parquet(x, file, compression = 'gzip')
stopifnot(identical(x, tibble::as_tibble(nanoparquet::read_parquet(file))))
provenance <- file.path(args[[1]], 'source-manifest.json')
if (!file.exists(provenance)) stop('Build requires preserved source provenance.')
sources <- jsonlite::read_json(provenance, simplifyVector = TRUE)
selected <- sources[sources$file == 'final.xml' | startsWith(sources$file, 'final-municipal/'), ]
stopifnot(nrow(selected) == 291L)
for (i in seq_len(nrow(selected))) {
 p <- file.path(args[[1]], selected$file[i])
 stopifnot(file.info(p)$size == selected$size[i], unname(tools::md5sum(p)) == selected$md5[i],
  swelections:::.canonical_sha256(p) == selected$sha256[i])
}
manifest <- list(data_version = 'data-v0.4.0', schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L, format = 'parquet',
 valserie = 'folkomr', valar = 2003L, release_status = 'unpublished_local_validation_build', auto_eligible = FALSE,
 built_at_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
 build_commit = trimws(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE)),
 build_tree_dirty = length(system2('git', c('status', '--porcelain'), stdout = TRUE)) > 0L,
 sources = selected, validation_sources = sources[grepl('^scb|^quality|^protocol|^snd-catalogue', sources$file), ],
 electorate_sources = list(electorate_source),
 assets = data.frame(asset = asset, file = basename(file), rows = nrow(x),
  bytes = unname(file.info(file)$size), sha256 = swelections:::.canonical_sha256(file)), tables = tables,
 source_selection = list(primary = 'Valmyndigheten final referendum XML, 14 September 2003',
  options = 'JA, NEJ and BLANK are valid voting options; OG is a separate invalid-ballot measure',
  geography = '5976 ordinary districts plus 396 Wednesday units; technical 00 containers are not public constituencies',
  electorate = 'SCB supplies three disjoint citizenship/residence groups for nation/counties only; sums match Valmyndigheten. Finer groups remain missing; Wednesday units have no independent electorate or turnout',
  preliminary = 'Separate preliminary Wednesday snapshot unrecovered; election night is not a complete preliminary stage'))
source("data-raw/canonical-build-contract.R")
manifest <- canonical_build_contract(manifest)
jsonlite::write_json(manifest, file.path(out, 'manifest.json'), pretty = TRUE, auto_unbox = TRUE, na = 'null')
cat('PASS unpublished referendum build:', nrow(x), 'rows, 291 source hashes, Parquet round trip\n')
