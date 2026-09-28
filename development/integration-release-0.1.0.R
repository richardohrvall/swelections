# Read-only release integration. Run from repository root with raw-data root.
.libPaths(c(file.path(getwd(), ".r-lib"), .libPaths()))
pkgload::load_all(".", quiet = TRUE)
root <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(length(root) == 1L, dir.exists(root))

blocked <- function(...) stop("Blocked network/archive access")
testthat::local_mocked_bindings(
  download_val_file = blocked, archive_val_file = blocked,
  val_remote_url = blocked, .package = "swelections"
)
testthat::local_mocked_bindings(download.file = blocked, .package = "utils")

rel <- c(
  "s/rd/Genrep_2026_slutlig_00_RD.zip",
  "s/rf/Genrep_2026_slutlig_01_RF.zip",
  "s/kf/Genrep_2026_slutlig_0114_KF.zip",
  "s/kf/Genrep_2026_slutlig_0180_KF.zip"
)
files <- file.path(root, "2026", "genrep2026", rel)
stopifnot(all(file.exists(files)))
before <- tools::md5sum(c(file.path(root, "2026/genrep2026/index.md5"), files))
on.exit(stopifnot(identical(before, tools::md5sum(names(before)))), add = TRUE)

for (i in seq_along(files)) {
  raw <- read_raw_json_zip_2026(files[i], "mandatfordelning")
  m <- parse_mandat_2026(raw)
  v <- parse_valda_ersattare_2026(raw)
  p <- parse_personval_2026(raw)
  cat(rel[i], "mandat=", nrow(m), "valda=", nrow(v$valda),
      "ersattare=", nrow(v$ersattare), "valda_available=",
      as.character(.valda_available_2026(raw)), "personval_available=",
      as.character(attr(p, "personval_available")), "\n")
  stopifnot(identical(names(m), names(.mandat_schema_2026())),
            !any(vapply(m, is.list, logical(1))),
            !any(vapply(v$ersattare, is.list, logical(1))))
}

rd <- kandidater(val = "RD", source = "local", data_dir = root, progress = FALSE)
cat("RD kandidater=", nrow(rd),
    "invald TRUE/FALSE/NA=", sum(rd$invald %in% TRUE), "/",
    sum(rd$invald %in% FALSE), "/", sum(is.na(rd$invald)),
    "personval TRUE/FALSE/NA=", sum(rd$kvalificerad_personval %in% TRUE), "/",
    sum(rd$kvalificerad_personval %in% FALSE), "/",
    sum(is.na(rd$kvalificerad_personval)), "\n")
stopifnot(sum(rd$invald %in% TRUE) > 0L,
          !anyNA(rd$invald), !anyNA(rd$kvalificerad_personval))

cat("Read-only release integration passed; MD5 unchanged.\n")
