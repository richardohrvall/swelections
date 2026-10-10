# Local, unpublished RKL 2022 canonical build. Never modifies original sources.
# Rscript data-raw/build-canonical-2022.R SOURCE_ROOT OUTPUT_DIR
# SOURCE_ROOT: the preserved rkl/2022 collection, including valresultat/filer.
# Derived raw input containers live in an external temporary staging directory;
# the output contains only English Parquet assets and manifest.json.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify SOURCE_ROOT OUTPUT_DIR.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) stop("Install nanoparquet.")
source_root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
out <- args[[2]]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)
resume <- Sys.getenv("SWELECTIONS_CANONICAL_2022_STAGE", "")
if (length(list.files(out)) && !nzchar(resume)) stop("Build into an empty output directory.")
stage <- if (nzchar(resume)) normalizePath(resume, mustWork = TRUE) else
  tempfile("swelections-canonical-2022-", tmpdir = Sys.getenv("TEMP", tempdir()))
dir.create(stage, showWarnings = FALSE)
cat("External derived input archive:", stage, "\n")
# Keep the staging archive for the subsequent independent public-API sweep.
# It contains derived containers, not redistributed release assets.
corrections <- file.path(stage, "official-corrections")
dir.create(corrections, showWarnings = FALSE)
sha <- swelections:::.canonical_sha256
index_path <- file.path(corrections, "index.md5")
index_url <- "https://resultat.val.se/resultatfiler/val2022/index.md5"
if (!nzchar(resume)) swelections:::.download_file(index_url, index_path)
if (!identical(unname(tools::md5sum(index_path)), "b064f6690eb17434fb48997f7f827ae2"))
  stop("Official index differs from the reviewed 2022 source generation; review before building.")
index <- swelections:::parse_index_2026(readLines(index_path, warn = FALSE))
for (area in c("0136", "1439", "1860", "2506")) {
  path <- paste0("s/kf/Val_20220911_slutlig_", area, "_KF.zip")
  expected <- index$md5[index$path == path]
  if (length(expected) != 1L) stop("Missing correction in official index: ", path)
  file <- file.path(corrections, basename(path))
  if (!nzchar(resume))
    swelections:::.download_file(paste0("https://resultat.val.se/resultatfiler/val2022/", path), file)
  if (!identical(tolower(unname(tools::md5sum(file))), tolower(expected)))
    stop("Official ZIP MD5 does not match index: ", path)
}
source("data-raw/prepare-canonical-2022.R")
if (!nzchar(resume)) canonical2022_prepare(source_root, stage, corrections) else
  canonical2022_validate(source_root, stage, corrections)
provenance <- jsonlite::read_json(file.path(stage, "provenance.json"), simplifyVector = TRUE)
candidate_selected <- provenance$sources$classification == "official_historical_candidate_snapshot" &
  provenance$sources$selected
provenance$sources$url[candidate_selected] <-
  "https://data.val.se/filer/val2022/parti/kandidaturer.zip"
assets <- list()
tables <- list()
reuse <- function(asset, role, layouts = NULL) {
  file <- file.path(out, paste0(asset, ".parquet"))
  if (!nzchar(resume) || !file.exists(file)) return(FALSE)
  x <- tibble::as_tibble(nanoparquet::read_parquet(file))
  assets[[length(assets) + 1L]] <<- data.frame(asset = asset, file = basename(file),
    role = role, rows = nrow(x), bytes = unname(file.info(file)$size), sha256 = sha(file))
  if (!is.null(layouts)) {
    if (identical(layouts, "seat-layout"))
      layouts <- stats::setNames(rep(list(setdiff(names(x), ".table")), 3L), c("RD", "RF", "KF"))
    tables[[length(tables) + 1L]] <<- data.frame(asset = asset,
      table = names(layouts), columns = vapply(layouts, paste, collapse = ",", ""))
  }
  cat("Reusing previously round-trip validated", asset, "\n")
  TRUE
}
save_asset <- function(parts, asset, role, discriminator = ".table") {
  # Single data frames have no discriminator; component/level layouts are explicit.
  if (is.data.frame(parts)) {
    x <- swelections:::.canonical_names_en(parts)
  } else {
    layouts <- lapply(parts, function(x) names(swelections:::.canonical_names_en(x)))
    tables[[length(tables) + 1L]] <<- data.frame(asset = asset,
      table = names(parts), columns = vapply(layouts, paste, collapse = ",", ""))
    x <- purrr::list_rbind(lapply(names(parts), function(key) {
      data <- swelections:::.canonical_names_en(parts[[key]])
      data[[discriminator]] <- rep(key, nrow(data))
      data
    }))
  }
  if (any(vapply(x, is.list, logical(1)))) stop("List column in ", asset)
  for (field in names(x)) names(x[[field]]) <- NULL
  file <- file.path(out, paste0(asset, ".parquet"))
  nanoparquet::write_parquet(x, file, compression = "gzip")
  restored <- tibble::as_tibble(nanoparquet::read_parquet(file))
  if (!identical(x, restored)) stop("Parquet round trip differs: ", asset)
  assets[[length(assets) + 1L]] <<- data.frame(asset = asset, file = basename(file),
    role = role, rows = nrow(x), bytes = unname(file.info(file)$size), sha256 = sha(file))
  cat("PASS round trip", asset, nrow(x), "rows\n")
}
raw <- function(surface, ...) do.call(swelections:::.raw_public_api[[surface]],
  c(list(ar = 2022L, source = "local", data_dir = stage), list(...)))
levels <- list(RD = c("valdistrikt", "riksdagsvalkrets", "riket"),
  RF = c("valdistrikt", "regionvalkrets", "region"),
  KF = c("valdistrikt", "kommunvalkrets", "kommun"))
for (count in c("preliminar", "slutlig")) {
  for (v in names(levels)) {
    asset <- paste0("rkl2022-results-", count, "-", tolower(v))
    layouts <- stats::setNames(lapply(levels[[v]], function(level)
      names(swelections:::.canonical_names_en(stats::setNames(
        as.list(rep(NA, length(swelections:::.valresultat_public_columns_2026(level)))),
        swelections:::.valresultat_public_columns_2026(level))))), levels[[v]])
    if (reuse(asset, "results", layouts)) next
    parts <- stats::setNames(lapply(levels[[v]], function(level)
      raw("valresultat", val = v, rakning = count, niva = level, progress = FALSE)), levels[[v]])
    save_asset(parts, paste0("rkl2022-results-", count, "-", tolower(v)), "results")
    rm(parts); gc()
  }
  if (reuse(paste0("rkl2022-seats-", count), "seats", "seat-layout")) next
  parts <- stats::setNames(lapply(names(levels), function(v)
    raw("mandat", val = v, rakning = count, progress = FALSE)), names(levels))
  save_asset(parts, paste0("rkl2022-seats-", count), "seats")
  rm(parts); gc()
}
for (surface in c("kandidaturer", "kandidater", "valda", "ersattare")) {
  cat("Building", surface, "\n")
  english <- c(kandidaturer = "candidacies", kandidater = "candidates",
               valda = "elected", ersattare = "substitutes")[[surface]]
  if (reuse(paste0("rkl2022-", english), english)) next
  x <- if (surface == "kandidaturer") raw(surface) else raw(surface, progress = FALSE)
  save_asset(x, paste0("rkl2022-", english), english)
  rm(x); gc()
}
kd <- raw("kandidaturer")
candidate_identity <- swelections:::.canonical_names_sv(tibble::as_tibble(
  nanoparquet::read_parquet(file.path(out, "rkl2022-candidates.parquet"))))
index <- swelections:::.read_resultatindex(2022L, "local", stage, FALSE, FALSE)
for (v in names(levels)) {
  kd_v <- dplyr::filter(kd, .data$valtyp == v)
  paths <- swelections:::.slutliga_mandat_paths(index, v, "personroster")$path
  for (level in c("personvalsomrade", "valdistrikt")) {
    short <- if (level == "valdistrikt") "district" else "area"
    base_asset <- paste0("rkl2022-preference-votes-base-", short, "-", tolower(v))
    view_asset <- paste0("rkl2022-preference-votes-", short, "-", tolower(v))
    reuse_pair <- nzchar(resume) && all(file.exists(file.path(out,
      paste0(c(base_asset, view_asset), ".parquet"))))
    cat("Building normalized preference-vote base", v, level, "\n")
    # On resume only the typed source layouts need rebuilding; all files are
    # independently checked against the pinned archive before reaching here.
    per_file <- lapply(if (reuse_pair) head(paths, 1L) else paths, function(path) {
      file <- swelections:::.resultat_file(2022L, path, "local", stage, FALSE, FALSE)
      m <- swelections:::.normalisera_resultat_2022(
        swelections:::read_raw_json_zip_2026(file, type = "mandatfordelning"))
      d <- if (level == "valdistrikt")
        swelections:::read_raw_json_zip_2026(file, type = "rostfordelning") else NULL
      geo <- swelections:::.personroster_2022_geografi(m, d)
      area <- swelections:::as_chr_na(m$valomrade$kod)
      pop <- swelections:::.personroster_2022_population(
        dplyr::filter(kd_v, .data$valomradeskod == area), geo$indelad, kd_v)
      source <- swelections:::.personroster_2022_kallrader(geo$noder, geo$geo,
        strikt_listtotal = level == "personvalsomrade")
      swelections:::.personroster_2022_kontrollera_poster(source$roster, pop)
      pop <- swelections:::.personroster_2022_observerade(pop, source$roster)
      omraden <- dplyr::select(geo$omraden, -".personval_nod")
      parts <- c(source, list(geo = geo$geo, omraden = omraden,
        officiella = swelections:::.personval_officiella_2026(geo$omraden),
        metadata = tibble::tibble(valtillfalle = m$valtillfalle,
          valtyp = v, valdatum = swelections:::as_chr_na(m$valdatum),
          test = swelections:::as_lgl_na(m$test))),
        stats::setNames(pop[c("kandidat", "lista", "alla")],
                        paste0("population_", c("kandidat", "lista", "alla"))))
      lapply(parts, function(data) { data$.source_area <- rep(area, nrow(data)); data })
    })
    parts <- stats::setNames(lapply(names(per_file[[1]]), function(component)
      purrr::list_rbind(lapply(per_file, `[[`, component))), names(per_file[[1]]))
    base_layout <- lapply(parts, function(x) names(swelections:::.canonical_names_en(x)))
    if (!reuse(base_asset, "preference-votes-base", base_layout))
      save_asset(parts, base_asset, "preference-votes-base", ".component")
    # Independent analysis-facing assets match the established 2018 product.
    # Area assets contain all four views; district assets contain sparse views.
    # Completed district panels are reconstructed on demand from the bases.
    flags <- if (level == "personvalsomrade")
      expand.grid(by_list = c(FALSE, TRUE), zeros = c(FALSE, TRUE)) else
      data.frame(by_list = c(FALSE, TRUE), zeros = FALSE)
    views <- lapply(seq_len(nrow(flags)), function(i) {
      view <- purrr::list_rbind(lapply(per_file, function(p) {
        p <- lapply(p, function(z) { z$.source_area <- NULL; z })
        population <- stats::setNames(p[paste0("population_", c("kandidat", "lista", "alla"))],
                                       c("kandidat", "lista", "alla"))
        key <- c("valtyp", "partikod", "kandidatnummer")
        population$alla_globalt <- dplyr::distinct(kd_v, dplyr::across(dplyr::all_of(key)))
        population$giltiga_globalt <- dplyr::distinct(dplyr::filter(kd_v, .data$giltig %in% TRUE),
                                                     dplyr::across(dplyr::all_of(key)))
        swelections:::.personroster_2022_public(as.list(p$metadata[1L, ]),
          list(geo = p$geo, omraden = p$omraden), population,
          p[c("parti", "lista", "roster")], candidate_identity,
          level, flags$by_list[[i]], flags$zeros[[i]], p$officiella)
      })) |>
        dplyr::arrange(.data$valtyp, .data$valomradeskod,
          .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
          dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
      view
    })
    names(views) <- paste(flags$by_list, flags$zeros, sep = "__")
    view_layout <- lapply(views, function(x) names(swelections:::.canonical_names_en(x)))
    if (!reuse(view_asset, "preference_votes", view_layout))
      save_asset(views, view_asset, "preference_votes", ".person_view")
    rm(per_file, parts); gc()
  }
}
# Recheck every original snapshot used or preserved in the source inventory.
before <- provenance$original_source_sha256
for (file in names(before)) if (!identical(sha(file), before[[file]]))
  stop("Original source changed during build: ", file)
manifest <- list(data_version = "data-v0.2.0", schema_version = 2L,
  format = "parquet", valserie = "rkl", valar = 2022L,
  built_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  build_commit = trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)),
  build_tree_dirty = length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L,
  package_version = unname(read.dcf("DESCRIPTION", fields = "Version")[[1]]),
  public_surfaces = c("results", "seats", "candidacies", "candidates", "elected",
                      "substitutes", "preference_votes"),
  release_status = "unpublished_local_validation_build", auto_eligible = FALSE,
  sources = provenance$sources, harmonisation = provenance$harmonisation,
  source_selection = list(
    principle = "Fixed election result including documented election-result corrections, excluding mandate-period changes",
    preliminary = "Complete preserved official preliminary snapshots",
    final_corrected_kf = c("0136", "1439", "1860", "2506"),
    final_rf25 = "Preserved original relations with scoped 50975-to-488 candidate-ID correction only",
    candidate_snapshot = "kandidaturer_20241218.csv; MD5 639daa9630a1f2554f1c6839473448ee",
    source_values = "Source language retained; source-specific missingness not filled speculatively"),
  source_index = list(url = index_url, md5 = unname(tools::md5sum(index_path)), sha256 = sha(index_path)),
  raw_input_archive = stage, source_root = source_root,
  build_code_sha256 = data.frame(file = c(list.files("R", full.names = TRUE),
    "data-raw/build-canonical-2022.R", "data-raw/prepare-canonical-2022.R"),
    sha256 = vapply(c(list.files("R", full.names = TRUE),
      "data-raw/build-canonical-2022.R", "data-raw/prepare-canonical-2022.R"), sha, "")),
  assets = purrr::list_rbind(assets), tables = purrr::list_rbind(tables))
jsonlite::write_json(manifest, file.path(out, "manifest.json"),
  pretty = TRUE, auto_unbox = TRUE, na = "null")
cat("Finished unpublished local build:", out, "\nRaw comparison archive:", stage, "\n")
