#' Svenska valdata från Valmyndigheten
#'
#' The English-first API provides [results()], [seats()], [candidacies()],
#' [candidates()], [elected()], [substitutes()] and [preference_votes()]. The Swedish functions,
#' including [valresultat()] and [personroster()], remain fully supported.
#' English functions return English column names by default. Use `names = "sv"`
#' or `options(swelections.names = "sv")` for Swedish output column names.
#' Language selection changes column names, not data values.
#' Resultatfiler väljs via `index.md5`. Optionen
#' `swelections.resultatsamling_2026` väljer resultatsamling och har för närvarande
#' standardvärdet `"val2026"`. Test-/utvecklingssamlingen `"genrep2026"` kan
#' väljas uttryckligen.
#'
#' En lokal rådatamapp anges med `data_dir` eller optionen
#' `swelections.data_dir`. Explicit `data_dir` har företräde.
#' Med `source = "auto"` används kompletta lokala råfiler först. Om 2018 års
#' råfiler saknas används den publicerade kanoniska samlingen när dess version
#' uttryckligen är godkänd för automatiskt bruk; annars används fjärrkällan.
#' För 2022/2026 används fortsatt den officiella rådatavägen.
#' Med `source = "local"` krävs en befintlig lokal fil och nätåtkomst används aldrig.
#' Med `source = "remote"` används fjärrkällan vid vanlig läsning.
#'
#' `update = TRUE` uppdaterar arbetskopian om innehållet har ändrats.
#' `archive = TRUE` sparar en daterad kopia; en tidigare kopia från samma
#' datum kan ersättas. Dessa alternativ kräver en lokal rådatamapp och
#' kan använda nedladdningslogiken med `source = "auto"` eller `"remote"`.
#' `source = "local", update = TRUE` ger ett fel före filåtkomst.
#' Lokal arkivering kopierar endast en redan befintlig lokal fil; saknas filen
#' ges ett fel utan nedladdning.
#'
#' @importFrom utils download.file unzip
#' @keywords internal
"_PACKAGE"
