# Frivillig read-only-kontroll av alla officiella 2022-resultat-ZIP.
# ZIP-filer hämtas en i taget till R:s temporära katalog och raderas direkt.
# Kör från repots rot med ett installerat/på PATH tillgängligt R och nätåtkomst.
pkgload::load_all(".", quiet = TRUE)
index_url <- "https://resultat.val.se/resultatfiler/val2022/index.md5"
index <- swelections:::parse_index_2026(readLines(index_url, warn = FALSE))
pattern <- "^[ps]/(rd|rf|kf)/Val_20220911_(preliminar|slutlig)_[0-9]{2,4}_(RD|RF|KF)\\.zip$"
index <- index[grepl(pattern, index$path), , drop = FALSE]
stopifnot(nrow(index) == 622L, !anyDuplicated(index$path), !anyNA(index$md5))

check_file <- function(path, md5) {
  val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", path)
  rakning <- if (startsWith(path, "p/")) "preliminar" else "slutlig"
  base <- Sys.getenv("VALRESULTAT_2022_INTEGRATION_DIR", "")
  local <- if (nzchar(base)) file.path(base, path) else ""
  temporary <- !nzchar(local) || !file.exists(local)
  file <- if (temporary) tempfile(fileext = ".zip") else local
  if (temporary) {
    on.exit(unlink(file), add = TRUE)
    url <- paste0("https://resultat.val.se/resultatfiler/val2022/", path)
    for (attempt in seq_len(3L)) {
      ok <- tryCatch({
        utils::download.file(url, file, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) FALSE)
      if (ok && file.exists(file)) break
      if (attempt == 3L) stop("Kunde inte hämta: ", path)
      Sys.sleep(attempt)
    }
  }
  if (!identical(unname(tools::md5sum(file)), md5)) {
    stop("MD5 stämmer inte: ", path)
  }
  raw_d <- swelections:::.read_valresultat_raw(
    file, "D", val, rakning, distrikt_context = TRUE, ar = 2022L
  )
  raw_m <- attr(raw_d, "valresultat_distrikt_context")$mandat
  levels <- switch(val, RD = c("riket", "riksdagsvalkrets"),
                   RF = c("region", "regionvalkrets"),
                   KF = c("kommun", "kommunvalkrets"))
  parse_public <- function(raw, kalla, niva) {
    internal <- swelections:::.parse_valresultat(raw, kalla, val, niva, rakning, path)
    stopifnot(identical(names(internal), names(swelections:::.valresultat_schema())))
    public <- swelections:::.valresultat_public_2026(internal, niva, raw, ar = 2022L)
    stopifnot(identical(names(public), swelections:::.valresultat_public_columns_2026(niva)),
              identical(typeof(public$valar), "integer"),
              !any(vapply(public, is.list, logical(1))))
    swelections:::.valresultat_check_key(public, niva)
    public
  }
  d <- parse_public(raw_d, "D", "valdistrikt")
  area <- parse_public(raw_m, "M", levels[[1]])
  krets <- parse_public(raw_m, "M", levels[[2]])
  distriktskoder <- unique(d$valdistriktskod)
  raknade <- unique(d$valdistriktskod[d$raknat])
  stopifnot(length(distriktskoder) == length(raw_d$valdistrikt),
            length(raknade) == raw_d$antalValdistriktRaknade,
            identical(sum(d$antal_roster, na.rm = TRUE),
                      sum(area$antal_roster, na.rm = TRUE)))
  for (result in list(d, area, krets)) {
    valid <- !is.na(result$giltiga_roster) & result$giltiga_roster > 0
    stopifnot(isTRUE(all.equal(result$andel_roster[valid],
                               result$antal_roster[valid] /
                                 result$giltiga_roster[valid])))
  }
  data.frame(path = path, val = val, rakning = rakning,
             district_rows = nrow(d), districts = length(distriktskoder),
             counted = length(raknade), area_rows = nrow(area),
             constituency_rows = nrow(krets), stringsAsFactors = FALSE)
}

results <- vector("list", nrow(index))
for (i in seq_len(nrow(index))) {
  results[[i]] <- tryCatch(check_file(index$path[[i]], index$md5[[i]]),
                           error = function(e) {
                             data.frame(path = index$path[[i]], val = NA_character_,
                                        rakning = NA_character_, district_rows = NA_integer_,
                                        districts = NA_integer_, counted = NA_integer_,
                                        area_rows = NA_integer_, constituency_rows = NA_integer_,
                                        error = conditionMessage(e))
                           })
  if (i %% 10L == 0L || i == nrow(index)) {
    cat("Kontrollerade", i, "av", nrow(index), "\n")
    flush.console()
  }
  if (i %% 50L == 0L) gc(FALSE)
}
out <- dplyr::bind_rows(results)
dir.create(".check", showWarnings = FALSE)
utils::write.csv(out, ".check/valresultat-2022-sweep.csv", row.names = FALSE,
                 na = "")
cat("Fel:", sum(!is.na(out$error)), "\n")
if (any(!is.na(out$error))) {
  print(out[!is.na(out$error), c("path", "error")], row.names = FALSE)
  quit(status = 1L)
}
print(dplyr::summarise(out, files = dplyr::n(), district_rows = sum(district_rows),
                       districts = sum(districts), area_rows = sum(area_rows),
                       constituency_rows = sum(constituency_rows),
                       .by = c(val, rakning)))
