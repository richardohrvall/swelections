# 2018 publicerades före index.md5-formatet. Lokala filer följer den
# ursprungliga katalogindelningen, medan fjärradresserna är separata.
.kalla_2018 <- function(typ, source, data_dir, update = FALSE, archive = FALSE) {
  source <- match.arg(source, c("auto", "local", "remote"))
  .check_source_update(source, update)
  spec <- switch(typ,
    resultat = list(path = "valresultat/slutresultat.zip", url = NULL),
    partier = list(path = "valresultat/deltagande_partier.skv",
      url = "https://historik.val.se/val/val2018/valsedlar/partier/deltagande_partier.skv"),
    kandidaturer = list(path = "kandidater/kandidaturer.skv",
      url = "https://historik.val.se/val/val2018/valsedlar/partier/kandidaturer.skv"),
    stop("Ok\u00e4nd k\u00e4lltyp f\u00f6r 2018.", call. = FALSE)
  )
  rot <- val_data_dir(data_dir)
  lokal <- if (is.null(rot)) NULL else file.path(rot, "2018", spec$path)
  if (source == "local") {
    if (is.null(lokal) || !file.exists(lokal)) {
      stop("Filen finns inte i det lokala arkivet: ",
           if (is.null(lokal)) spec$path else lokal,
           call. = FALSE)
    }
    if (archive) .arkivera_2018(lokal, rot, spec$path)
    return(lokal)
  }
  if (source == "auto" && !update && !is.null(lokal) && file.exists(lokal)) {
    if (archive) .arkivera_2018(lokal, rot, spec$path)
    return(lokal)
  }
  if (is.null(spec$url)) {
    stop("2018 \u00e5rs slutliga XML-arkiv kan inte l\u00e4ngre h\u00e4mtas fr\u00e5n den ",
         "officiella statistiksidan. Anv\u00e4nd `source = \"local\"` och ett ",
         "befintligt arkiv i `data_dir`.", call. = FALSE)
  }
  if (!update && !archive) return(spec$url)
  if (is.null(lokal)) {
    stop("`update` eller `archive` kr\u00e4ver en lokal datamapp f\u00f6r 2018.", call. = FALSE)
  }
  dir.create(dirname(lokal), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(fileext = paste0(".", tools::file_ext(spec$path)))
  on.exit(unlink(tmp), add = TRUE)
    .download_file(spec$url, tmp)
  if (!file.exists(lokal) || !same_file_md5(tmp, lokal)) {
    if (!file.copy(tmp, lokal, overwrite = TRUE)) {
      stop("Kunde inte uppdatera den lokala 2018-filen.", call. = FALSE)
    }
  }
  if (archive) .arkivera_2018(lokal, rot, spec$path)
  lokal
}

.arkivera_2018 <- function(file, rot, path) {
  target <- file.path(rot, "2018", "archive", as.character(Sys.Date()), path)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(target) || !same_file_md5(file, target)) {
    if (!file.copy(file, target, overwrite = TRUE)) {
      stop("Kunde inte arkivera 2018-filen.", call. = FALSE)
    }
  }
  invisible(target)
}

.lokal_zip_2018 <- function(file) {
  if (!grepl("^https?://", file)) return(file)
  tmp <- tempfile(fileext = ".zip")
    .download_file(file, tmp)
  tmp
}
