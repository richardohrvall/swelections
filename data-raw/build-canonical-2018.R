# Stage verified RKL 2018 RDS intermediates for Parquet export. These RDS files
# are not distribution assets. The input candidate file must be Valmyndigheten's
# currently published, redacted kandidaturer.skv; the local named research
# snapshot is deliberately not a build input.
# Usage: Rscript data-raw/build-canonical-2018.R RAW_ROOT OFFICIAL_CANDIDATE_FILE
# RAW_ROOT has 2018/valresultat/{slutresultat.zip,deltagande_partier.skv}.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Ange RAW_ROOT och OFFICIAL_CANDIDATE_FILE.")
root <- normalizePath(args[[1]], mustWork = TRUE)
candidate <- normalizePath(args[[2]], mustWork = TRUE)
pkgload::load_all(".", quiet = TRUE)

sha <- valresultat:::.canonical_sha256
result_file <- file.path(root, "2018", "valresultat", "slutresultat.zip")
party_file <- file.path(root, "2018", "valresultat", "deltagande_partier.skv")
for (file in c(result_file, party_file, candidate))
  if (!file.exists(file)) stop("Råkälla saknas: ", file)
if (!identical(sha(result_file),
  "cb4a490b576e5a57b42b5ca26d38fa1074c692b4cd7eeb2aca2c3de80560b3a6"))
  stop("2018 års slutresultat-ZIP har annan SHA256 än den verifierade snapshoten.")
if (!identical(tolower(unname(tools::md5sum(candidate))),
               "9855ac4280c2a5165389a88c647ae49f"))
  stop("Kandidaturkällan är inte den verifierade gallrade officiella filen.")

# Existing raw APIs require one archive root. Stage only transient raw inputs
# outside the repository, then remove them after the build.
build <- function() {
temp_root <- normalizePath(tempdir(), winslash = "/", mustWork = TRUE)
stage <- tempfile("valresultat-canonical-stage-", tmpdir = temp_root)
if (!startsWith(normalizePath(stage, winslash = "/", mustWork = FALSE),
                paste0(temp_root, "/")))
  stop("Temporar byggrot ligger utanfor systemets tempkatalog.")
on.exit(unlink(stage, recursive = TRUE), add = TRUE)
dir.create(file.path(stage, "2018", "valresultat"), recursive = TRUE)
dir.create(file.path(stage, "2018", "kandidater"), recursive = TRUE)
copies <- c(result_file, party_file, candidate)
dest <- c(file.path(stage, "2018", "valresultat", "slutresultat.zip"),
          file.path(stage, "2018", "valresultat", "deltagande_partier.skv"),
          file.path(stage, "2018", "kandidater", "kandidaturer.skv"))
if (!all(file.copy(copies, dest))) stop("Kunde inte förbereda temporär byggrot.")

outdir <- file.path(".local-data", "canonical-build", "data-v0.1.0")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
values <- c("RD", "RF", "KF")
levels <- list(
  RD = c("valdistrikt", "kommun", "kommunvalkrets", "lan",
         "riksdagsvalkrets", "riket"),
  RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets",
         "region", "riket"),
  KF = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riket")
)
say <- function(...) cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ..., "\n")
save_asset <- function(object, name, surfaces) {
  check_names <- function(x) {
    if (is.data.frame(x)) {
      for (field in intersect(names(x), c("namn", "ledamot_namn",
                                           "ersattare_namn"))) {
        if (any(!is.na(x[[field]])))
          stop("Personnamn i kanoniskt asset: ", name, "/", field)
      }
      if (any(vapply(x, function(column) is.character(column) &&
                     any(column == "Namnet gallrat", na.rm = TRUE), logical(1))))
        stop("'Namnet gallrat' i kanoniskt asset: ", name)
    } else if (is.list(x)) {
      lapply(x, check_names)
    }
    invisible(NULL)
  }
  check_names(object)
  file <- paste0(name, ".rds")
  path <- file.path(outdir, file)
  saveRDS(object, path, compress = "xz", version = 3)
  # Verify that the object is actually readable, including all R column types.
  if (!identical(object, readRDS(path))) stop("RDS-rundtur ändrade asset: ", name)
  data.frame(asset = name, file = file, bytes = unname(file.info(path)$size),
             sha256 = sha(path), surfaces = paste(surfaces, collapse = ","),
             stringsAsFactors = FALSE)
}
entries <- list()
resume <- identical(Sys.getenv("VALRESULTAT_CANONICAL_RESUME"), "1")
existing_entry <- function(name, surfaces) {
  path <- file.path(outdir, paste0(name, ".rds"))
  readRDS(path) # A truncated or invalid RDS is never accepted on resume.
  data.frame(asset = name, file = basename(path),
             bytes = unname(file.info(path)$size), sha256 = sha(path),
             surfaces = paste(surfaces, collapse = ","),
             stringsAsFactors = FALSE)
}
say("Building result tables")
if (resume && file.exists(file.path(outdir, "rkl2018-valresultat.rds"))) {
  entries[[length(entries) + 1L]] <- existing_entry("rkl2018-valresultat",
                                                     "valresultat")
} else {
  results <- list()
  for (v in values) for (lev in levels[[v]]) {
    key <- paste(v, lev, sep = "__")
    say("valresultat", key)
    results[[key]] <- valresultat(ar = 2018L, val = v, niva = lev,
                                 source = "local", data_dir = stage,
                                 progress = FALSE)
  }
  entries[[length(entries) + 1L]] <- save_asset(results, "rkl2018-valresultat",
                                                  "valresultat")
  rm(results); gc()
}

say("Building mandate tables")
if (resume && file.exists(file.path(outdir, "rkl2018-mandat.rds"))) {
  entries[[length(entries) + 1L]] <- existing_entry("rkl2018-mandat", "mandat")
} else {
  mandates <- lapply(values, function(v) mandat(ar = 2018L, val = v,
    source = "local", data_dir = stage, progress = FALSE))
  names(mandates) <- values
  entries[[length(entries) + 1L]] <- save_asset(mandates, "rkl2018-mandat", "mandat")
  rm(mandates); gc()
}

say("Building candidate tables")
if (resume && file.exists(file.path(outdir, "rkl2018-kandidater.rds"))) {
  entries[[length(entries) + 1L]] <- existing_entry("rkl2018-kandidater",
    c("kandidaturer", "kandidater", "valda", "ersattare"))
} else {
candidate_tables <- list(
  kandidaturer = kandidaturer(ar = 2018L, source = "local", data_dir = stage,
                             archive = FALSE),
  kandidater = kandidater(ar = 2018L, source = "local", data_dir = stage,
                         progress = FALSE),
  valda = valda(ar = 2018L, source = "local", data_dir = stage,
               progress = FALSE),
  ersattare = ersattare(ar = 2018L, source = "local", data_dir = stage,
                       progress = FALSE)
)
entries[[length(entries) + 1L]] <- save_asset(candidate_tables,
  "rkl2018-kandidater", names(candidate_tables))
rm(candidate_tables); gc()
}

# These two small normalized sources are sufficient for all four person-vote
# views, including completion. They retain list numbers and validation context.
for (v in values) {
  say("Building person-vote base", v)
  area_name <- paste0("rkl2018-person-omrade-", tolower(v))
  district_name <- paste0("rkl2018-person-distrikt-", tolower(v))
  if (resume && all(file.exists(file.path(outdir,
                                    paste0(c(area_name, district_name), ".rds"))))) {
    entries[[length(entries) + 1L]] <- existing_entry(area_name, "personroster")
    entries[[length(entries) + 1L]] <- existing_entry(district_name, "personroster")
    next
  }
  kd <- kandidaturer(ar = 2018L, val = v, source = "local", data_dir = stage,
                    archive = FALSE)
  area <- valresultat:::.xml2018_person_las(v, "personvalsomrade", kd,
    "local", stage, FALSE, FALSE, FALSE)
  district <- valresultat:::.xml2018_person_las(v, "valdistrikt", kd,
    "local", stage, FALSE, FALSE, FALSE)
  entries[[length(entries) + 1L]] <- save_asset(area,
    area_name, "personroster")
  entries[[length(entries) + 1L]] <- save_asset(district,
    district_name, "personroster")
  rm(kd, area, district); gc()
}

manifest <- list(
  schema_version = 1L,
  data_version = "data-v0.1.0",
  valserie = "rkl",
  valar = 2018L,
  built_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  package_version = unname(read.dcf("DESCRIPTION", fields = "Version")[[1]]),
  build_commit = trimws(system2("git", "rev-parse HEAD", stdout = TRUE)),
  build_tree_dirty = length(system2("git", "status --porcelain", stdout = TRUE)) > 0L,
  build_code_sha256 = data.frame(
    file = c("data-raw/build-canonical-2018.R", "R/canonical_backend.R"),
    sha256 = vapply(c("data-raw/build-canonical-2018.R",
                      "R/canonical_backend.R"), sha, character(1))
  ),
  public_surfaces = c("valresultat", "mandat", "kandidaturer", "kandidater",
                      "valda", "ersattare", "personroster"),
  assets = do.call(rbind, entries),
  sources = data.frame(
    source = c("slutresultat.zip", "deltagande_partier.skv",
               "kandidaturer.skv"),
    identity = c("Valmyndigheten, arkiverat slutresultat RKL 2018",
      "Valmyndigheten, deltagande partier RKL 2018",
      "Valmyndigheten, nu publicerad gallrad kandidaturfil RKL 2018"),
    classification = c("official_archived_snapshot", "official_published",
                       "official_published_redacted"),
    url = c(NA_character_,
      "https://historik.val.se/val/val2018/valsedlar/partier/deltagande_partier.skv",
      "https://historik.val.se/val/val2018/valsedlar/partier/kandidaturer.skv"),
    md5 = tolower(unname(tools::md5sum(copies))),
    sha256 = vapply(copies, sha, character(1)),
    stringsAsFactors = FALSE
  )
)
jsonlite::write_json(manifest, file.path(outdir, "manifest.json"),
                     auto_unbox = TRUE, pretty = TRUE, na = "null")
say("Finished", outdir)
print(manifest$assets[, c("asset", "bytes", "sha256")])
}
build()
