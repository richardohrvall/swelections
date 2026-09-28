# Frivillig kontroll av alla 2022 års officiella mandat-ZIP. Råfiler läses
# från extern fixturekatalog eller hämtas en och en till R:s temporära katalog.
pkgload::load_all(".", quiet = TRUE)
index <- swelections:::parse_index_2026(readLines(
  "https://resultat.val.se/resultatfiler/val2022/index.md5", warn = FALSE
))
index <- index[grepl("^[ps]/(rd|rf|kf)/Val_20220911_(preliminar|slutlig)_[0-9]{2,4}_(RD|RF|KF)\\.zip$",
                     index$path), , drop = FALSE]
stopifnot(nrow(index) == 622L)
root <- Sys.getenv("VALRESULTAT_2022_INTEGRATION_DIR", "")
check_one <- function(path, md5) {
  val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", path)
  rakning <- if (startsWith(path, "p/")) "preliminar" else "slutlig"
  local <- if (nzchar(root)) file.path(root, path) else ""
  temporary <- !nzchar(local) || !file.exists(local)
  file <- if (temporary) tempfile(fileext = ".zip") else local
  if (temporary) {
    on.exit(unlink(file), add = TRUE)
    utils::download.file(paste0("https://resultat.val.se/resultatfiler/val2022/",
                                path), file, mode = "wb", quiet = TRUE)
  }
  stopifnot(identical(unname(tools::md5sum(file)), md5))
  raw <- swelections:::.read_valresultat_raw(file, "M", val, rakning, ar = 2022L)
  seats <- swelections:::parse_mandat_2026(raw)
  vacant <- swelections:::parse_tomma_stolar_2022(raw)
  if (nrow(vacant)) {
    seats <- dplyr::left_join(seats, vacant,
      by = dplyr::join_by(valtyp, geografiniva, valomradeskod,
                         valkretskod, partikod))
  } else {
    seats$antal_tomma_stolar <- NA_integer_
  }
  public <- swelections:::.mandat_public_2026(
    swelections:::.kort_kommunnamn_2026(seats), ar = 2022L
  )
  stopifnot(identical(names(seats), c(names(swelections:::.mandat_schema_2026()),
                                      "antal_tomma_stolar")),
            identical(names(public),
                      names(swelections:::.mandat_public_schema_2026())),
            identical(typeof(public$valar), "integer"),
            !anyDuplicated(public[c("valar", "valtyp", "rakningstillfalle",
                                    "geografiniva", "valomradeskod",
                                    "valkretskod", "partikod")]),
            !any(vapply(public, is.list, logical(1))),
            all(is.na(seats$antal_mandat) | seats$antal_mandat >= 0L),
            all(is.na(vacant$antal_tomma_stolar) | vacant$antal_tomma_stolar >= 0L))
  if (rakning == "preliminar") stopifnot(nrow(vacant) == 0L)
  area_level <- c(RD = "riket", RF = "region", KF = "kommun")[[val]]
  vacant_area <- vacant[vacant$geografiniva == area_level, , drop = FALSE]
  if (!length(raw$valomrade$valkretsLista)) {
    stopifnot(!any(seats$geografiniva %in%
                   c("riksdagsvalkrets", "regionvalkrets", "kommunvalkrets")))
  }
  for (group in split(seats, paste(seats$geografiniva, seats$valkretskod))) {
    total <- unique(group$totalt_antal_mandat)
    if (!anyNA(group$antal_mandat)) {
      stopifnot(length(total) == 1L,
                identical(total, as.integer(sum(group$antal_mandat))))
    }
  }
  data.frame(path, val, rakning, areas = 1L,
             constituencies = length(raw$valomrade$valkretsLista),
             rows = nrow(seats), vacant_known = nrow(vacant),
             vacant_positive = sum(vacant_area$antal_tomma_stolar > 0L),
             vacant_total = sum(vacant_area$antal_tomma_stolar),
             stringsAsFactors = FALSE)
}
results <- vector("list", nrow(index))
for (i in seq_len(nrow(index))) {
  results[[i]] <- tryCatch(check_one(index$path[[i]], index$md5[[i]]),
                           error = function(e) data.frame(
                             path = index$path[[i]], error = conditionMessage(e)
                           ))
  if (i %% 20L == 0L || i == nrow(index)) {
    cat("Mandat 2022:", i, "/", nrow(index), "\n")
    flush.console()
  }
  if (i %% 50L == 0L) gc(FALSE)
}
out <- dplyr::bind_rows(results)
dir.create(".check", showWarnings = FALSE)
utils::write.csv(out, ".check/mandat-2022-sweep.csv", row.names = FALSE)
cat("Fel:", sum(!is.na(out$error)), "\n")
if (any(!is.na(out$error))) print(out[!is.na(out$error), c("path", "error")], row.names = FALSE)
print(dplyr::summarise(out, files = dplyr::n(), rows = sum(rows),
                       constituencies = sum(constituencies),
                       vacant_known = sum(vacant_known),
                       vacant_positive = sum(vacant_positive),
                       vacant_total = sum(vacant_total), .by = c(val, rakning)))
final <- out[out$rakning == "slutlig", ]
stopifnot(identical(as.integer(tapply(final$vacant_total, final$val, sum)[c("RD", "RF", "KF")]),
                    c(0L, 0L, 17L)))
if (any(!is.na(out$error))) quit(status = 1L)
