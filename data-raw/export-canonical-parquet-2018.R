# Convert the verified RKL 2018 build intermediates to portable Parquet assets.
# Usage: Rscript data-raw/export-canonical-parquet-2018.R STAGE_DIR OUTPUT_DIR
# STAGE_DIR is produced by build-canonical-2018.R. No raw source is distributed.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Ange STAGE_DIR och OUTPUT_DIR.")
stage <- normalizePath(args[[1]], mustWork = TRUE)
out <- args[[2]]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, mustWork = TRUE)
if (identical(stage, out)) stop("Staging och output maste vara olika kataloger.")
pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("nanoparquet", quietly = TRUE)) stop("Installera nanoparquet.")

sha <- swelections:::.canonical_sha256
source_manifest <- jsonlite::read_json(file.path(stage, "manifest.json"),
                                      simplifyVector = TRUE)
assets <- list()
tables <- list()
save_asset <- function(x, asset, role, table_columns = NULL) {
  if (!is.data.frame(x) || any(vapply(x, is.list, logical(1))))
    stop("Kanonisk tabell maste vara platt: ", asset)
  x <- swelections:::.canonical_names_en(x)
  path <- file.path(out, paste0(asset, ".parquet"))
  nanoparquet::write_parquet(x, path, compression = "gzip")
  got <- tibble::as_tibble(nanoparquet::read_parquet(path))
  for (column in names(x)) names(x[[column]]) <- NULL
  if (!identical(x, got)) stop("Parquet-rundtur skiljer sig: ", asset)
  assets[[length(assets) + 1L]] <<- data.frame(
    asset = asset, file = basename(path), role = role,
    rows = nrow(x), bytes = unname(file.info(path)$size), sha256 = sha(path))
  if (!is.null(table_columns)) {
    table_columns <- lapply(table_columns, function(columns)
      names(swelections:::.canonical_names_en(
        stats::setNames(as.list(rep(NA, length(columns))), columns))))
    tables[[length(tables) + 1L]] <<- data.frame(
      asset = asset, table = names(table_columns),
      columns = vapply(table_columns, paste, collapse = ",", character(1)))
  }
  cat(asset, nrow(x), file.info(path)$size, "bytes\n")
}
read_stage <- function(name) readRDS(file.path(stage, paste0(name, ".rds")))
combine <- function(x, discriminator) {
  dplyr::bind_rows(lapply(names(x), function(key) {
    dplyr::mutate(x[[key]], !!discriminator := key, .before = 1L)
  }))
}
result <- read_stage("rkl2018-valresultat")
for (v in c("RD", "RF", "KF")) {
  subset <- result[startsWith(names(result), paste0(v, "__"))]
  names(subset) <- sub("^[A-Z]+__", "", names(subset))
  save_asset(combine(subset, ".table"),
             paste0("rkl2018-results-", tolower(v)),
             "results", lapply(subset, names))
}
rm(result); gc()

mandates <- read_stage("rkl2018-mandat")
save_asset(combine(mandates, ".table"), "rkl2018-seats",
           "seats", lapply(mandates, names))
rm(mandates); gc()

candidate <- read_stage("rkl2018-kandidater")
for (surface in names(candidate)) {
  x <- candidate[[surface]]
  for (field in intersect(names(x), c("namn", "ledamot_namn", "ersattare_namn"))) {
    if (any(!is.na(x[[field]]))) stop("Personnamn i ", surface)
  }
  if (any(vapply(x, function(col) is.character(col) &&
                 any(col == "Namnet gallrat", na.rm = TRUE), logical(1))))
    stop("Gallringsmarkor i ", surface)
  english_surface <- c(kandidaturer = "candidacies", kandidater = "candidates",
                       valda = "elected", ersattare = "substitutes")[[surface]]
  save_asset(x, paste0("rkl2018-", english_surface), english_surface)
}
kd <- candidate$kandidaturer
rm(candidate); gc()

for (v in c("RD", "RF", "KF")) {
  vlow <- tolower(v)
  area <- read_stage(paste0("rkl2018-person-omrade-", vlow))
  kd_v <- dplyr::filter(kd, .data$valtyp == v)
  for (level in c("personvalsomrade", "valdistrikt")) {
    short <- if (level == "personvalsomrade") "omrade" else "distrikt"
    raw <- if (level == "personvalsomrade") area else
      read_stage(paste0("rkl2018-person-distrikt-", vlow))
    save_asset(combine(raw, ".component"),
      paste0("rkl2018-preference-votes-base-",
             if (short == "omrade") "area" else "district", "-", vlow),
      "preference-votes-base", lapply(raw, names))
    flags <- if (level == "personvalsomrade")
      expand.grid(per_lista = c(FALSE, TRUE),
                  komplettera_nollor = c(FALSE, TRUE)) else
      data.frame(per_lista = c(FALSE, TRUE),
                 komplettera_nollor = c(FALSE, FALSE))
    views <- lapply(seq_len(nrow(flags)), function(i) {
      x <- swelections:::.xml2018_person_public(raw, area, kd_v, level,
        flags$per_lista[[i]], flags$komplettera_nollor[[i]]) |>
        dplyr::arrange(.data$valtyp, .data$valomradeskod,
          .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
          dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
      x <- dplyr::mutate(x,
        .person_view = paste(flags$per_lista[[i]],
                             flags$komplettera_nollor[[i]], sep = "__"),
        .before = 1L)
      x
    })
    layouts <- lapply(views, function(x) names(x)[!startsWith(names(x), ".")])
    names(layouts) <- paste(flags$per_lista, flags$komplettera_nollor, sep = "__")
    save_asset(dplyr::bind_rows(views),
      paste0("rkl2018-preference-votes-",
             if (short == "omrade") "area" else "district", "-", vlow),
      "preference-votes", layouts)
    rm(raw, views); gc()
  }
  rm(area, kd_v); gc()
}

manifest <- source_manifest
manifest$schema_version <- 2L
manifest$format <- "parquet"
manifest$public_surfaces <- c("results", "seats", "candidacies", "candidates",
                              "elected", "substitutes", "preference_votes")
manifest$sources$classification <- c("official_archived_snapshot",
  "official_published", "official_published_redacted")
manifest$built_at_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
manifest$package_version <- unname(read.dcf("DESCRIPTION", fields = "Version")[[1]])
manifest$build_commit <- trimws(system2("git", "rev-parse HEAD", stdout = TRUE))
manifest$build_tree_dirty <- length(system2("git", "status --porcelain",
                                          stdout = TRUE)) > 0L
manifest$assets <- do.call(rbind, assets)
manifest$tables <- do.call(rbind, tables)
manifest$build_code_sha256 <- data.frame(
  file = c("data-raw/build-canonical-2018.R",
           "data-raw/export-canonical-parquet-2018.R",
           "R/canonical_backend.R", "R/output_names.R"),
  sha256 = vapply(c("data-raw/build-canonical-2018.R",
                    "data-raw/export-canonical-parquet-2018.R",
                    "R/canonical_backend.R", "R/output_names.R"), sha,
                  character(1)))
for (field in c("sources", "assets", "tables", "build_code_sha256"))
  rownames(manifest[[field]]) <- NULL
jsonlite::write_json(manifest, file.path(out, "manifest.json"),
                     auto_unbox = TRUE, pretty = TRUE, na = "null")
cat("Fardigt:", out, "\n")
