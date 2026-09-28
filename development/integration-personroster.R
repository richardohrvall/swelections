# Read-only integration. Kör från repots rot, ange rådatamappen som argument.
.libPaths(c(file.path(getwd(), ".r-lib"), .libPaths()))
pkgload::load_all(".", quiet = TRUE)
root <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(!is.na(root), dir.exists(root))
main <- function() {
  blocked <- function(...) stop("Blocked network/archive access")
  testthat::local_mocked_bindings(download_val_file = blocked, archive_val_file = blocked,
    val_remote_url = blocked, .package = "swelections")
  testthat::local_mocked_bindings(download.file = blocked, .package = "utils")
  paths <- list.files(file.path(root, "2026/genrep2026"), "\\.zip$", recursive = TRUE)
  files <- file.path(root, "2026/genrep2026", paths)
  csv <- file.path(root, "2026/val2026/parti/kandidaturer.csv")
  before <- tools::md5sum(c(files, csv))
  on.exit(stopifnot(identical(before, tools::md5sum(names(before)))), add = TRUE)
  kandidaturer <- read_kandidaturer_2026(csv)
  for (i in seq_along(paths)) {
    path <- paths[i]
    val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", path)
    kod <- sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", path)
    cat("\n", path, "\n", sep = "")
    raw <- .read_valresultat_raw(files[i], "D", val, "slutlig")
    u <- .personrostunderlag_2026(raw, kod)
    print(table(u$status$personroster_available, useNA = "always"))
    cat("Verifierade kandidatsummor:", nrow(u$roster), "\n")
    kandidaturer_urval <- dplyr::filter(kandidaturer, valtyp == val, valomradeskod == kod)
    totals <- .personrosttotaler_2026(kandidaturer_urval, u$status, u$roster)
    cat("Giltiga kandidatnycklar i lokalt omradesurval:", nrow(totals),
        "; NA:", sum(is.na(totals$antal_personroster_totalt)),
        "; noll:", sum(totals$antal_personroster_totalt == 0L, na.rm = TRUE),
        "; positiv:", sum(totals$antal_personroster_totalt > 0L, na.rm = TRUE), "\n")
    stopifnot(!anyDuplicated(totals[c("kandidatnummer", "valtyp", "partikod")]),
              is.integer(totals$antal_personroster_totalt))
    proof <- dplyr::left_join(totals, u$status,
      by = c("valtyp", "partikod"), relationship = "many-to-one")
    stopifnot(all(is.na(proof$antal_personroster_totalt[!proof$personroster_available %in% TRUE])))
    # Samma råobjekt genom filsteget, med verklig mandatfil men utan ny läsning
    # av den stora distriktsfilen. Kontrollera status och totalsummor exakt.
    file_step <- local({
      old_reader <- read_raw_json_zip_2026
      testthat::local_mocked_bindings(read_raw_json_zip_2026 = function(zip_file, type) {
        if (type == "rostfordelning") raw else old_reader(zip_file, type)
      }, .package = "swelections")
      .parse_kandidatresultat_fil_2026(path, val, source = "local", data_dir = root)
    })
    stopifnot(identical(file_step$personroster_status, u$status), identical(file_step$personroster, u$roster))
    rm(raw, u, file_step)
    gc()
  }
  cat("\nSamtliga read-only kontroller passerade; MD5 oforandrat.\n")
}
main()
