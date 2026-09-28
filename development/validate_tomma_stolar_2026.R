# Frivillig read-only-kontroll mot explicita tomma stolar i officiella 2026-filer.
pkgload::load_all(".", quiet = TRUE)
index <- swelections:::parse_index_2026(readLines(
  "https://resultat.val.se/resultatfiler/val2026/index.md5", warn = FALSE
))
index <- index[grepl("^s/(rd|rf|kf)/[^/]+_slutlig_[0-9]{2,4}_(RD|RF|KF)\\.zip$",
                     index$path), , drop = FALSE]
check_one <- function(path, md5) {
  file <- tempfile(fileext = ".zip")
  on.exit(unlink(file), add = TRUE)
  utils::download.file(paste0("https://resultat.val.se/resultatfiler/val2026/",
                              path), file, mode = "wb", quiet = TRUE)
  stopifnot(identical(unname(tools::md5sum(file)), md5))
  raw <- swelections:::read_raw_json_zip_2026(file, "mandatfordelning")
  nodes <- c(list(raw$valomrade), raw$valomrade$valkretsLista)
  compared <- mismatch <- 0L
  for (node in nodes) {
    if (is.null(node$valda$partiLedamoterLista) ||
        is.null(node$mandatfordelning$partiLista)) next
    mandates <- node$mandatfordelning$partiLista
    codes <- vapply(mandates, function(p) as.character(p$partikod), "")
    for (elected in node$valda$partiLedamoterLista) {
      m <- mandates[[match(elected$partikod, codes)]]
      if (is.null(m) || is.null(m$antalMandat) ||
          is.null(elected$antalTommaStolar) || is.null(elected$ledamoter)) next
      ids <- unique(vapply(elected$ledamoter,
                           function(x) as.character(x$kandidatnummer), ""))
      compared <- compared + 1L
      if (m$antalMandat - length(ids) != elected$antalTommaStolar) {
        mismatch <- mismatch + 1L
      }
    }
  }
  data.frame(path, val = sub(".*_([A-Z]{2})\\.zip$", "\\1", path),
             compared, mismatch, stringsAsFactors = FALSE)
}
results <- vector("list", nrow(index))
for (i in seq_len(nrow(index))) {
  results[[i]] <- tryCatch(check_one(index$path[[i]], index$md5[[i]]),
                           error = function(e) data.frame(
                             path = index$path[[i]], error = conditionMessage(e)
                           ))
  if (i %% 20L == 0L || i == nrow(index)) {
    cat("Tomma stolar 2026:", i, "/", nrow(index), "\n")
    flush.console()
  }
}
out <- dplyr::bind_rows(results)
dir.create(".check", showWarnings = FALSE)
utils::write.csv(out, ".check/tomma-stolar-2026.csv", row.names = FALSE)
cat("Fel:", sum(!is.na(out$error)), " Avvikelser:", sum(out$mismatch, na.rm = TRUE), "\n")
print(dplyr::summarise(out, files = dplyr::n(), compared = sum(compared),
                       mismatch = sum(mismatch), .by = val))
if (any(!is.na(out$error)) || any(out$mismatch > 0L, na.rm = TRUE)) quit(status = 1L)
