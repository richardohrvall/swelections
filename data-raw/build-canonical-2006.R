# R-only local 2006 prototype; sources remain unchanged and outside Git.
# Rscript data-raw/build-canonical-2006.R RAW_ROOT OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT OUTPUT_DIR.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) stop("Install nanoparquet.")
s <- swelections:::.sources_2006("local", args[[1]])
out <- args[[2]]
if (dir.exists(out) && length(list.files(out))) stop("Use an empty output directory.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- swelections:::.canonical_sha256
sources <- s$sources
for (i in seq_len(nrow(sources))) swelections:::.xml2006_source(s, sources$file[[i]])
if (nrow(s$municipal_sources) != 579L) stop("Complete 579-file municipality preservation required.")
for (file in s$municipal_sources$file) swelections:::.xml2006_source(s, paste0("official-final/", file))
ballot <- file.path(s$root, "valresultat", "xml.zip")
ballot_before <- sha(ballot)
assets <- tables <- list()
save_asset <- function(parts, asset, role, discriminator = ".table") {
  if (is.data.frame(parts)) x <- swelections:::.canonical_names_en(parts) else {
    layouts <- lapply(parts, function(x) names(swelections:::.canonical_names_en(x)))
    tables[[length(tables) + 1L]] <<- data.frame(asset = asset, table = names(parts),
      columns = vapply(layouts, paste, "", collapse = ","))
    x <- purrr::list_rbind(lapply(names(parts), function(key) {
      data <- swelections:::.canonical_names_en(parts[[key]])
      data[[discriminator]] <- rep(key, nrow(data)); data
    }))
  }
  x[] <- lapply(x, unname)
  if (any(vapply(x, is.list, logical(1)))) stop("List column: ", asset)
  file <- file.path(out, paste0(asset, ".parquet"))
  nanoparquet::write_parquet(x, file, compression = "gzip")
  restored <- tibble::as_tibble(nanoparquet::read_parquet(file))
  if (!identical(x, restored)) stop("Parquet round trip differs: ", asset)
  assets[[length(assets) + 1L]] <<- data.frame(asset = asset, file = basename(file),
    role = role, rows = nrow(x), bytes = unname(file.info(file)$size), sha256 = sha(file))
  cat("PASS round trip", asset, nrow(x), "\n"); flush.console()
}
levels <- list(RD = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riksdagsvalkrets", "riket"),
  RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets", "region", "riket"),
  KF = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riket"))
seats <- candidacies <- candidates <- base <- elected <- substitutes <- list()
for (v in names(levels)) {
  cat("Building 2006", v, "\n"); flush.console()
  parts <- stats::setNames(lapply(levels[[v]], function(level)
    swelections:::.valresultat_2006(s, v, level, "slutlig")), levels[[v]])
  save_asset(parts, paste0("rkl2006-results-slutlig-", tolower(v)), "results")
  seats[[v]] <- swelections:::.mandat_2006(s, swelections:::.mandat_par_2026(v, NULL))
  b <- swelections:::.xml2006_population(s, v)
  candidacies[[v]] <- b$kd
  base[[v]] <- swelections:::.kandidater_2006(s, v, FALSE, bundle = b)
  candidates[[v]] <- swelections:::.kandidater_2006(s, v, TRUE, bundle = b)
  elected[[v]] <- candidates[[v]] |>
    dplyr::filter(.data$invald %in% TRUE) |>
    swelections:::.valda_invaldsvalkrets_2026() |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
  substitutes[[v]] <- swelections:::.kort_kommunnamn_2026(b$relations$ersattare)
  for (level in c("personvalsomrade", "valdistrikt")) {
    short <- if (level == "valdistrikt") "district" else "area"
    views <- list("FALSE" = if (level == "personvalsomrade") b$pref else
      swelections:::.personroster_2006(s, v, level, FALSE, FALSE),
      "TRUE" = swelections:::.personroster_2006(s, v, level, TRUE, FALSE))
    save_asset(views, paste0("rkl2006-preference-votes-", short, "-", tolower(v)), "preference_votes", ".person_view")
  }
}
save_asset(seats, "rkl2006-seats-slutlig", "seats")
for (surface in c("candidacies", "candidates", "base", "elected", "substitutes"))
  save_asset(purrr::list_rbind(get(surface)), paste0("rkl2006-", if (surface == "base") "candidate-base" else surface), surface)
for (i in seq_len(nrow(sources))) swelections:::.xml2006_source(s, sources$file[[i]])
if (nrow(s$municipal_sources) != 579L) stop("Complete 579-file municipality preservation required.")
for (file in s$municipal_sources$file) swelections:::.xml2006_source(s, paste0("official-final/", file))
stopifnot(identical(sha(ballot), ballot_before))
manifest <- list(data_version = "data-v0.0.0", schema_version = 2L, format = "parquet",
  valserie = "rkl", valar = 2006L, release_status = "unpublished_local_validation_build", auto_eligible = FALSE,
  built_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  build_commit = trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)),
  build_tree_dirty = length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L,
  sources = sources, municipal_sources = s$municipal_sources, ballot_source = list(file = "valresultat/xml.zip", sha256 = ballot_before,
    md5 = unname(tools::md5sum(ballot)), bytes = unname(file.info(ballot)$size)),
  assets = purrr::list_rbind(assets), tables = purrr::list_rbind(tables),
  source_selection = list(final = "Hash-pinned archived final XML; national RD/RF and 290 municipal KF files",
    preliminary = "Not implemented: complete collection source unavailable; election night is never substituted",
    identity = "Package-generated source-observation IDs, not persons; no name-based cross-list/election linkage",
    candidates = "Separate ballot, area preference-vote and original appointed/substitute source observations",
    names = "Archived structured names retained; ballot KANDIDATUPPGIFT retained separately, not parsed into asserted person names",
    unfilled = "Kunde ej utses is an unfilled allocated mandate and never an elected candidate",
    discrepancies = c("RD detailed candidate totals exceed independent official area statistics by 4089 in five constituencies",
      "KF detailed totals 1554153 versus separate Valmyndigheten statistics 1554115: 38 votes; neither source is overwritten",
      "RF SCB wide table has 102 exact duplicate rows; raw table retained unchanged")))
jsonlite::write_json(manifest, file.path(out, "manifest.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
cat("Finished unpublished 2006 build:", out, "\n")
