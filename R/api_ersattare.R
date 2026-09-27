#' Ersättare
#'
#' Hämtar officiella relationer mellan valda ledamöter och deras ersättare
#' från slutliga mandatfiler. Preliminära filer används aldrig för att
#' uppskatta ersättare.
#'
#' @param ar Ett eller flera exakta valår (2022, 2026), eller `"alla"`.
#'   Dubbletter tas bort med den första årsordningen bevarad. Standard är 2026.
#' @param val En eller flera valtyper: `"RD"`, `"RF"` eller `"KF"`.
#'   `NULL` ger alla.
#' @param source Datakälla: `"auto"`, `"local"` eller `"remote"`.
#'   `"local"` använder aldrig nätet och får inte kombineras med `update = TRUE`.
#'   Lokal arkivering kräver en redan befintlig lokal fil.
#' @param data_dir Lokal rotmapp för rådata.
#' @param update Om `TRUE`, uppdateras lokala arbetskopior.
#' @param archive Om `TRUE`, sparas även daterade snapshots.
#' @param progress Visa progressindikator.
#' @param fran,till Inklusiva årsgränser bland stödda år, som alternativ till
#'   `ar`. En utelämnad gräns är öppen.
#'
#' @return En tibble där en rad är relationen mellan en vald ledamot och en
#'   ersättare inom val, område/valkrets, parti och ersättargrupp.
#'   Samma ersättare kan förekomma på flera rader när de officiella relationerna
#'   avser olika ledamöter, valkretsar eller ersättarordningar.
#'   Den avsedda radnyckeln är `valar`, `valtyp`, `geografiniva`,
#'   `valomradeskod`, `valkretskod`, `partikod`, `ledamot_kandidatnummer`,
#'   `ersattare_kandidatnummer` och `ersattarordning` tillsammans. Ordning är integer; koder och
#'   namn är character. Parti- och relationsfält ligger före geografi och
#'   teknisk valmetadata. `valar` är integer direkt efter `valtillfalle`.
#'   `valkretskod` och `valkretsnamn` avser den officiella ersättarrelationens
#'   valkrets, inte ersättarens samtliga kandidaturer. Ett känt tomt resultat
#'   behåller samma typade schema; saknad eller ofärdig slutlig relation ger fel.
#'   För KF är `valomradesnamn` paketets korta kommunnamn, uppslaget via
#'   `valomradeskod`; separata kommunfält dupliceras inte.
#' @examples
#' \dontrun{
#' ersattare(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' ersattare(ar = c(2022, 2026), val = "RD")
#' }
#' @seealso [valda()], [mandat()], [valresultat-package]
#' @export
ersattare <- function(
    ar = 2026,
    val = NULL,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive(),
    fran = NULL,
    till = NULL
) {
  ar_angivet <- !missing(ar)
  val <- .valtyper(val)
  val <- if (is.null(val)) c("RD", "RF", "KF") else val
  valar <- .resolve_valar(ar, fran, till, "ersattare", val[[1]], ar_angivet)
  if (length(val) > 1L && !all(vapply(val[-1], function(v) {
    all(valar %in% .stodd_valar("ersattare", v))
  }, logical(1)))) {
    stop("Valda \u00e5r st\u00f6ds inte f\u00f6r alla valtyper.", call. = FALSE)
  }
  source <- .check_public_args(
    valar[[1]], "ersattare", source, data_dir, update, archive, progress,
    valar_resolved = TRUE
  )
  purrr::map(valar, function(ett_ar) {
    tryCatch(
      .ersattare_ett_ar(ett_ar, val, source, data_dir, update, archive,
                        progress),
      error = function(e) stop("Val\u00e5r ", ett_ar, ": ", conditionMessage(e),
                               call. = FALSE)
    )
  }) |> purrr::list_rbind()
}
