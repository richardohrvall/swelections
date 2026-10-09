# R-only, unpublished 2010 prototype. Original sources are read-only.
# Rscript data-raw/build-canonical-2010.R RAW_ROOT OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT OUTPUT_DIR.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) stop("Install nanoparquet.")
s <- swelections:::.sources_2010("local", args[[1]], FALSE, FALSE)
out <- args[[2]]
if (dir.exists(out) && length(list.files(out))) stop("Use an empty output directory.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- swelections:::.canonical_sha256
# Pin every actual build input before parsing, not mutable membership files.
source_files <- c(s$final, s$night,
  file.path(s$root, "kandidater", paste0("alkandur_", c("R", "L", "K"), ".skv")),
  file.path(s$root, "kandidater", "partier_som_anmalt_kandidater.txt"),
  list.files(file.path(s$root, "kandidater", "official-party-identifiers"), full.names = TRUE))
prior_provenance <- jsonlite::fromJSON(file.path(s$root, "kandidater", "official-party-identifiers", "provenance.json"))
preliminary_inputs <- list.files(file.path(s$root, "valresultat"), recursive = TRUE, full.names = TRUE)
preliminary_inputs <- preliminary_inputs[grepl("preliminary-(collection-preservation|presentation)-", preliminary_inputs) &
  grepl("([.]html|source-manifest[.]json)$", preliminary_inputs)]
source_files <- unique(c(source_files, prior_provenance$source, preliminary_inputs))
stopifnot(identical(sha(prior_provenance$source), prior_provenance$source_sha256))
sources <- data.frame(file = normalizePath(source_files, winslash = "/"),
  bytes = as.numeric(file.info(source_files)$size), md5 = unname(tools::md5sum(source_files)),
  sha256 = vapply(source_files, sha, ""))
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
  if (any(vapply(x, is.list, logical(1)))) stop("List column: ", asset)
  for (field in names(x)) names(x[[field]]) <- NULL
  for (field in intersect(c("name", "member_name", "substitute_name"), names(x)))
    if (any(!is.na(x[[field]]))) stop("Candidate names in historical asset: ", asset)
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
seats <- bundles <- list()
candidacies <- candidates <- elected <- substitutes <- population <- list()
for (v in names(levels)) {
  cat("Building results", v, "\n"); flush.console()
  for (count in c("preliminar", "slutlig")) {
    preliminary <- if (count == "preliminar")
      swelections:::.valresultat_preliminary_2014(s, v, "valdistrikt", FALSE, internal = TRUE) else NULL
    parts <- lapply(levels[[v]], function(level) {
      if (count == "slutlig") return(swelections:::.valresultat_final_2014(s, v, level, FALSE))
      x <- preliminary
      if (level != "valdistrikt") {
        x <- swelections:::.xml2014_aggregate_results(x, v, level, 2010L)
        x <- swelections:::.xml2014_preliminary_metadata(x, s, v, level)
      }
      x <- swelections:::.komplettera_kommunnamn_2026(x, x$kommunnamn)
      x <- swelections:::.valresultat_public_andelar_2026(x)
      x[swelections:::.valresultat_public_columns_2026(level)]
    })
    names(parts) <- levels[[v]]
    save_asset(parts, paste0("rkl2010-results-", count, "-", tolower(v)), "results")
  }
  par <- swelections:::.mandat_par_2026(v, NULL)
  seats[[v]] <- swelections:::.mandat_2014(s, par, FALSE)
  b <- swelections:::.xml2014_bundle(s, v, FALSE)
  candidacies[[v]] <- b$kd
  population[[v]] <- b$population
  candidates[[v]] <- swelections:::.kandidater_2014(s, v, TRUE, FALSE, b)
  elected[[v]] <- swelections:::.valda_2014(s, v, FALSE, b)
  substitutes[[v]] <- swelections:::.kort_kommunnamn_2026(b$relations$ersattare)
  for (level in c("personvalsomrade", "valdistrikt")) {
    short <- if (level == "valdistrikt") "district" else "area"
    raw <- if (level == "personvalsomrade") b$areas else
      swelections:::.xml2014_person_read(s, v, level, b$population, FALSE)
    save_asset(raw, paste0("rkl2010-preference-votes-base-", short, "-", tolower(v)),
      "preference-votes-base", ".component")
    flags <- if (level == "personvalsomrade") expand.grid(by_list = c(FALSE, TRUE), zeros = c(FALSE, TRUE)) else
      data.frame(by_list = c(FALSE, TRUE), zeros = FALSE)
    views <- lapply(seq_len(nrow(flags)), function(i)
      swelections:::.metadata_2014(swelections:::.xml2018_person_public(raw,
        b$areas, b$population, level, flags$by_list[[i]], flags$zeros[[i]]), 2010L) |>
      dplyr::arrange(.data$valtyp, .data$valomradeskod, .data$personvalsomradeskod,
        .data$partikod, .data$kandidatnummer,
        dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer")))))
    names(views) <- paste(flags$by_list, flags$zeros, sep = "__")
    save_asset(views, paste0("rkl2010-preference-votes-", short, "-", tolower(v)), "preference_votes", ".person_view")
    rm(raw, views); gc()
  }
}
save_asset(seats, "rkl2010-seats-slutlig", "seats")
for (surface in c("candidacies", "candidates", "elected", "substitutes", "population")) {
  x <- purrr::list_rbind(get(surface))
  if (surface %in% c("candidates", "elected")) {
    types <- unique(purrr::list_rbind(population)[c("kandidatnummer", "valtyp")]) |>
      dplyr::count(.data$kandidatnummer, name = "antal_valtyper")
    x$antal_valtyper <- types$antal_valtyper[match(x$kandidatnummer, types$kandidatnummer)]
    x$flera_valtyper <- x$antal_valtyper > 1L
  }
  asset <- if (surface == "population") "candidate-population" else surface
  save_asset(x, paste0("rkl2010-", asset), surface)
}
if (!identical(vapply(source_files, sha, ""), sources$sha256 |> stats::setNames(source_files)))
  stop("Original sources changed during build.")
manifest <- list(data_version = "data-v0.0.0", schema_version = 2L, format = "parquet",
  valserie = "rkl", valar = 2010L, release_status = "unpublished_local_validation_build", auto_eligible = FALSE,
  built_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  build_commit = trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)),
  build_tree_dirty = length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L,
  sources = sources, assets = purrr::list_rbind(assets), tables = purrr::list_rbind(tables),
  source_selection = list(final = "Preserved official final XML ZIP, 2010-10-07 reporting timestamp",
    preliminary = "Reporting snapshot: election-night ordinary districts plus hash-pinned preliminary collection HTML; 9 RF and 9 KF unreported collection districts and blank category fields remain NA; final collection votes are never used",
    candidates = "Ballot candidacies plus identified final preference-vote/elected/substitute evidence",
    names = "Candidate names redacted to typed NA; local named snapshots are not a name lookup",
    party_identifiers = "Official list-prefix IDs, unambiguous notified-party register and provenance-backed 2006 ballot party IDs for comparison-only parties",
    identity = list(rule = "2010-bjorn-andersson", canonical_id = "442089",
      raw_rf_id = "451964", raw_rd_ballot_id = "497359",
      rd_context = "RD / party 0003 / constituency 03 / list 03600 / position 22",
      evidence = "SOURCE_ID_RECONCILIATION_2010.md; no other identity harmonisation enabled")))
jsonlite::write_json(manifest, file.path(out, "manifest.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
cat("Finished unpublished 2010 build:", out, "\n")
