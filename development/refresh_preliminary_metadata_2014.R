# One-time validation-build refresh after fixing missing aggregate metadata.
# A fresh build-canonical-2014.R already includes this step before writing assets.
# Never use this tool on published assets or a clean release build.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Specify RAW_ROOT UNPUBLISHED_2014_BUILD.")
pkgload::load_all(".", quiet = TRUE)
dir <- args[[2]]; path <- file.path(dir, "manifest.json")
m <- jsonlite::fromJSON(path)
stopifnot(m$valar == 2014L, m$release_status == "unpublished_local_validation_build",
  isTRUE(m$build_tree_dirty))
sha <- swelections:::.canonical_sha256
s <- swelections:::.sources_2014("local", args[[1]], FALSE, FALSE)
for (i in seq_len(nrow(m$sources))) stopifnot(
  identical(unname(tools::md5sum(m$sources$file[[i]])), m$sources$md5[[i]]),
  identical(sha(m$sources$file[[i]]), m$sources$sha256[[i]]))
for (v in c("RD", "RF", "KF")) {
  id <- paste0("rkl2014-results-slutlig-", tolower(v))
  i <- which(m$assets$asset == id); stopifnot(length(i) == 1L)
  file <- file.path(dir, m$assets$file[[i]])
  stopifnot(identical(sha(file), m$assets$sha256[[i]]))
  old <- tibble::as_tibble(nanoparquet::read_parquet(file))
  x <- swelections:::.canonical_names_sv(old)
  stored_columns <- names(x)
  schema <- swelections:::.valresultat_schema()
  for (n in setdiff(names(schema), names(x))) x[[n]] <- schema[[n]][rep(NA_integer_, nrow(x))]
  for (n in c("valomradessparr", "valkretssparr")) {
    if (n %in% names(x)) x[[paste0(n, "_procent")]] <- 100 * x[[n]]
    x[[n]] <- NULL
  }
  x <- swelections:::.xml2014_known_vote_totals(x)
  x <- swelections:::.valresultat_public_andelar_2026(x)
  new <- swelections:::.canonical_names_en(x[stored_columns])
  stopifnot(identical(old$votes, new$votes), identical(old$party_code, new$party_code),
    identical(old$district_code, new$district_code), identical(dim(old), dim(new)))
  nanoparquet::write_parquet(new, file, compression = "gzip")
  stopifnot(identical(new, tibble::as_tibble(nanoparquet::read_parquet(file))))
  m$assets$bytes[[i]] <- as.numeric(file.info(file)$size)
  m$assets$sha256[[i]] <- sha(file)
  cat("Updated component-verified final vote totals", v, "\n")
}
for (v in c("RD", "RF", "KF")) {
  id <- paste0("rkl2014-results-preliminar-", tolower(v))
  i <- which(m$assets$asset == id); stopifnot(length(i) == 1L)
  file <- file.path(dir, m$assets$file[[i]])
  stopifnot(identical(sha(file), m$assets$sha256[[i]]))
  old <- tibble::as_tibble(nanoparquet::read_parquet(file))
  district <- swelections:::.canonical_names_sv(old[old$.table == "valdistrikt", ])
  schema <- swelections:::.valresultat_schema()
  for (n in setdiff(names(schema), names(district)))
    district[[n]] <- schema[[n]][rep(NA_integer_, nrow(district))]
  parts <- lapply(unique(old$.table), function(level) {
    data <- old[old$.table == level, ]
    if (level == "valdistrikt") return(data)
    x <- swelections:::.xml2014_aggregate_results(district, v, level)
    x <- swelections:::.xml2014_preliminary_metadata(x, s, v, level)
    x <- swelections:::.komplettera_kommunnamn_2026(x, x$kommunnamn)
    x <- swelections:::.valresultat_public_andelar_2026(x)
    result <- swelections:::.canonical_names_en(
      x[swelections:::.valresultat_public_columns_2026(level)])
    result$.table <- rep(level, nrow(result))
    for (n in setdiff(names(old), names(result))) result[[n]] <- old[[n]][rep(NA_integer_, nrow(result))]
    result[names(old)]
  })
  new <- purrr::list_rbind(parts)
  stopifnot(identical(old$votes, new$votes), identical(old$party_code, new$party_code),
    identical(old$district_code, new$district_code), identical(dim(old), dim(new)))
  nanoparquet::write_parquet(new, file, compression = "gzip")
  stopifnot(identical(new, tibble::as_tibble(nanoparquet::read_parquet(file))))
  m$assets$bytes[[i]] <- as.numeric(file.info(file)$size)
  m$assets$sha256[[i]] <- sha(file)
  cat("Updated hash-validated aggregate metadata", v, "\n")
}
m$normalization_completed_at_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
code <- c(list.files("R", "[.]R$", full.names = TRUE), "data-raw/build-canonical-2014.R",
  "development/refresh_preliminary_metadata_2014.R")
m$build_code_files <- data.frame(file = code, sha256 = vapply(code, sha, ""))
m$source_selection$aggregate_metadata <- paste(
  "Explicit, hash-pinned preliminary presentation metadata fills otherwise missing",
  "electorate/historical totals; current totals must match district construction")
m$source_selection$collection_vote_totals <- paste(
  "A missing collection VALDELTAGANDE node does not hide known total votes:",
  "total equals explicit valid plus invalid vote components")
jsonlite::write_json(m, path, pretty = TRUE, auto_unbox = TRUE, na = "null")
