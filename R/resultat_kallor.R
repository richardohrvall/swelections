# Resultatindex och ZIP-sökvägar delas mellan valåren. Indexet bestämmer alltid
# de faktiska filnamnen; varken valdag eller filprefix byggs in i sökvägen.
.resultatsamling <- function(ar) {
  if (ar == 2026) return(.resultatsamling_2026())
  getOption("swelections.resultatsamling_2022",
            getOption("valresultat.resultatsamling_2022", "val2022"))
}

.read_resultatindex <- function(ar, source, data_dir, update, archive) {
  file <- .resolve_val_file(
    path = "index.md5", ar = ar, samling = .resultatsamling(ar),
    source = source, data_dir = data_dir, update = update, archive = archive
  )
  readLines(file, warn = FALSE, encoding = "UTF-8") |> parse_index_2026()
}

.resultat_file <- function(ar, path, source, data_dir, update, archive) {
  .resolve_val_file(
    path = path, ar = ar, samling = .resultatsamling(ar),
    source = source, data_dir = data_dir, update = update, archive = archive
  )
}

.valresultat_index_for_ar <- function(ar, source, data_dir, update, archive) {
  if (ar == 2026L) {
    .read_resultatindex_2026(source, data_dir, update, archive)
  } else {
    .read_resultatindex(ar, source, data_dir, update, archive)
  }
}

.valresultat_file_for_ar <- function(ar, path, source, data_dir, update, archive) {
  if (ar == 2026L) {
    .resultat_file_2026(path, source, data_dir, update, archive)
  } else {
    .resultat_file(ar, path, source, data_dir, update, archive)
  }
}

# 2022 års JSON saknar bl.a. valdatum, valklass och test. De lämnas saknade.
# Endast det verifierade råa valtillfället normaliseras till samma form som
# 2026 års publika resultat: Val_2022 respektive Val_2026.
.normalisera_resultat_2022 <- function(raw) {
  if (!identical(raw$valtillfalle, "Val_20220911")) {
    stop("Ov\u00e4ntat valtillfalle i 2022 \u00e5rs resultatfil.", call. = FALSE)
  }
  raw$valtillfalle <- "Val_2022"
  .normalisera_rakningsmetadata_2026(raw)
}
