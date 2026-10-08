# R-only, unpublished 2014 prototype. Original sources are read-only.
# Rscript data-raw/build-canonical-2014.R RAW_ROOT OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT OUTPUT_DIR.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) stop("Install nanoparquet.")
s <- swelections:::.sources_2014("local", args[[1]], FALSE, FALSE)
out <- args[[2]]
if (dir.exists(out) && length(list.files(out))) stop("Use an empty output directory.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- swelections:::.canonical_sha256
# Pin every actual build input before parsing, not mutable membership files.
snapshot <- list.dirs(file.path(s$root, "valresultat"), recursive = FALSE)
snapshot <- snapshot[grepl("preliminary-presentation-", basename(snapshot))]
if (length(snapshot) != 1L) stop("Ambiguous preliminary snapshot.")
html_manifest <- jsonlite::fromJSON(file.path(snapshot, "source-manifest.json"))$sources
html <- file.path(snapshot, gsub("\\", "/", html_manifest$file, fixed = TRUE))
source_files <- unique(c(list.files(s$final, "[.]xml$", full.names = TRUE),
  list.files(s$night, "[.]xml$", full.names = TRUE), html,
  file.path(snapshot, "source-manifest.json"),
  file.path(s$root, "kandidater", paste0("alkandur_", c("R", "L", "K"), ".skv")),
  list.files(file.path(s$root, "kandidater", "official-ballot-metadata"),
    "^(00R[.]xml|provenance[.]json|party-identifiers-2010-complete.*)$", full.names = TRUE)))
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
    if (count == "preliminar") {
      district <- swelections:::.valresultat_preliminary_2014(s, v, "valdistrikt", FALSE,
        internal = TRUE)
      parts <- lapply(levels[[v]], function(level) {
        x <- if (level == "valdistrikt") district else
          swelections:::.xml2014_aggregate_results(district, v, level)
        if (level != "valdistrikt") x <- swelections:::.xml2014_preliminary_metadata(x, s, v, level)
        x <- swelections:::.komplettera_kommunnamn_2026(x, x$kommunnamn)
        x <- swelections:::.valresultat_public_andelar_2026(x)
        x[swelections:::.valresultat_public_columns_2026(level)]
      })
    } else parts <- lapply(levels[[v]], function(level)
      swelections:::.valresultat_final_2014(s, v, level, FALSE))
    names(parts) <- levels[[v]]
    save_asset(parts, paste0("rkl2014-results-", count, "-", tolower(v)), "results")
  }
  par <- swelections:::.mandat_par_2026(v, NULL)
  seats[[v]] <- swelections:::.mandat_2014(s, par, FALSE)
  b <- swelections:::.xml2014_bundle(s, v, FALSE)
  candidacies[[v]] <- b$kd
  population[[v]] <- b$population
  candidates[[v]] <- swelections:::.kandidater_2014(s, v, TRUE, FALSE, b)
  elected[[v]] <- swelections:::.valda_2014(s, v, FALSE)
  substitutes[[v]] <- swelections:::.kort_kommunnamn_2026(b$relations$ersattare)
  for (level in c("personvalsomrade", "valdistrikt")) {
    short <- if (level == "valdistrikt") "district" else "area"
    raw <- if (level == "personvalsomrade") b$areas else
      swelections:::.xml2014_person_read(s, v, level, b$population, FALSE)
    save_asset(raw, paste0("rkl2014-preference-votes-base-", short, "-", tolower(v)),
      "preference-votes-base", ".component")
    flags <- if (level == "personvalsomrade") expand.grid(by_list = c(FALSE, TRUE), zeros = c(FALSE, TRUE)) else
      data.frame(by_list = c(FALSE, TRUE), zeros = FALSE)
    views <- lapply(seq_len(nrow(flags)), function(i)
      swelections:::.metadata_2014(swelections:::.xml2018_person_public(raw,
        b$areas, b$population, level, flags$by_list[[i]], flags$zeros[[i]])) |>
      dplyr::arrange(.data$valtyp, .data$valomradeskod, .data$personvalsomradeskod,
        .data$partikod, .data$kandidatnummer,
        dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer")))))
    names(views) <- paste(flags$by_list, flags$zeros, sep = "__")
    save_asset(views, paste0("rkl2014-preference-votes-", short, "-", tolower(v)), "preference_votes", ".person_view")
    rm(raw, views); gc()
  }
}
save_asset(seats, "rkl2014-seats-slutlig", "seats")
for (surface in c("candidacies", "candidates", "elected", "substitutes", "population")) {
  x <- purrr::list_rbind(get(surface))
  if (surface %in% c("candidates", "elected")) {
    types <- unique(purrr::list_rbind(population)[c("kandidatnummer", "valtyp")]) |>
      dplyr::count(.data$kandidatnummer, name = "antal_valtyper")
    x$antal_valtyper <- types$antal_valtyper[match(x$kandidatnummer, types$kandidatnummer)]
    x$flera_valtyper <- x$antal_valtyper > 1L
  }
  asset <- if (surface == "population") "candidate-population" else surface
  save_asset(x, paste0("rkl2014-", asset), surface)
}
if (!identical(vapply(source_files, sha, ""), sources$sha256 |> stats::setNames(source_files)))
  stop("Original sources changed during build.")
manifest <- list(data_version = "data-v0.3.0", schema_version = 2L, format = "parquet",
  valserie = "rkl", valar = 2014L, release_status = "unpublished_local_validation_build", auto_eligible = FALSE,
  built_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  build_commit = trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)),
  build_tree_dirty = length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L,
  sources = sources, assets = purrr::list_rbind(assets), tables = purrr::list_rbind(tables),
  source_selection = list(final = "Preserved official final XML, 20141001 collection",
    preliminary = "Election-night ordinary districts plus preliminary collection HTML; no final vote values",
    candidates = "Ballot candidacies plus identified final preference-vote/elected/substitute evidence",
    names = "Candidate names redacted to typed NA; local named snapshots are not a name lookup",
    party_identifiers = "Official list-prefix IDs; prior party identity metadata only for otherwise unidentified historical parties"))
jsonlite::write_json(manifest, file.path(out, "manifest.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
cat("Finished unpublished 2014 build:", out, "\n")
