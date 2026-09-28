#' Kandidaturer
#'
#' Hämtar kandidaturdata från Valmyndigheten.
#'
#' @param ar Ett eller flera exakta valår (2018, 2022, 2026), eller `"alla"`.
#'   Dubbletter tas bort med den första årsordningen bevarad. Utan årsurval
#'   används 2026.
#' @param fran,till Inklusiva gränser bland stödda valår, som alternativ till
#'   `ar`. En utelämnad gräns är öppen.
#' @param val En eller flera valtyper: `"RD"`, `"RF"` eller `"KF"`.
#'   `NULL` ger alla.
#' @param source Datakälla: `"auto"`, `"local"` eller `"remote"`.
#'   `"local"` använder aldrig nätet och får inte kombineras med `update = TRUE`.
#'   Lokal arkivering kräver en redan befintlig lokal fil.
#' @param data_dir Lokal rotmapp för rådata.
#' @param update Om `TRUE`, uppdateras den lokala arbetskopian.
#' @param archive Om `TRUE`, sparas även en daterad snapshot.
#'
#' @return En tibble där en rad är en källrad för en kandidatur eller
#'   listrelation i ett valområde och eventuell valkrets. En giltig kandidat
#'   kan sakna tryckt namnvalsedel. En kandidat kan ha flera rader och
#'   ogiltiga kandidaturer bevaras. Den avsedda radnyckeln
#'   är `valtyp`, `valomradeskod`, `valkretskod`, `partikod`, `listnummer`,
#'   `ordning` och `kandidatnummer` tillsammans.
#'   Källans namn bevaras i `namn` för 2022/2026 och `giltig` är logical.
#'   För 2018 är publikt `namn` alltid `NA_character_`: den nu publicerade
#'   officiella filen är namngallrad, och en äldre namngiven lokal snapshot
#'   får inte ändra det publika namnkontraktet. Namn används aldrig som nyckel.
#'   För KF är valområdet kommunen och `valomradesnamn` är paketets korta
#'   kommunnamn, uppslaget exakt via `valomradeskod`.
#'   `valar` är en heltalskolumn direkt efter `valtillfalle`. Flera år
#'   staplas i long format. `oppen_lista` avser partiets status i valområdet:
#'   `TRUE` om kandidater inte är anmälda och `FALSE` om de är anmälda.
#'   `pa_namnvalsedel` avser en namnvalsedel som skickats till tryck enligt
#'   kandidatfilens `VALSEDELSSTATUS`. `S` ger `TRUE` och kräver listnummer
#'   och ordning. `B` eller blank status ger `FALSE` endast när den faktiska
#'   kandidatfilens innehållshash motsvarar en verifierad komplett snapshot;
#'   annars ges `NA`. Därför kan en äldre lokal snapshot ge `NA` för samma
#'   valår som ger `FALSE` med en verifierad historisk fil. Listnummer som
#'   senare uppstår i valresultatet, inklusive `90000`, påverkar inte fältet.
#' @examples
#' \dontrun{
#' kandidaturer(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' kandidaturer(ar = c(2022, 2026), val = "KF")
#' kandidaturer(ar = "alla", val = "RD")
#' kandidaturer(fran = 2022, till = 2026, val = "RF")
#' }
#' @seealso [kandidater()], [swelections-package]
#' @export
kandidaturer <- function(
    ar = 2026,
    val = NULL,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    fran = NULL,
    till = NULL
) {
  ar_angivet <- !missing(ar)
  val <- .valtyper(val)
  valar <- .resolve_valar(ar, fran, till, "kandidaturer",
                         if (is.null(val)) "RD" else val[[1]], ar_angivet)
  if (!is.null(val) && length(val) > 1L && !all(vapply(val[-1], function(v) {
    all(valar %in% .stodd_valar("kandidaturer", v))
  }, logical(1)))) {
    stop("Valda \u00e5r st\u00f6ds inte f\u00f6r alla valtyper.", call. = FALSE)
  }
  source <- .check_public_args(
    valar[[1]], "kandidaturer", source, data_dir, update, archive,
    valar_resolved = TRUE
  )
  purrr::map(valar, function(ett_ar) {
    tryCatch(
      .kandidaturer_ett_ar(ett_ar, val, source, data_dir, update, archive),
      error = function(e) stop("Val\u00e5r ", ett_ar, ": ", conditionMessage(e),
                               call. = FALSE)
    )
  }) |> purrr::list_rbind()
}

.kandidaturer_ett_ar <- function(ar, val, source, data_dir, update, archive) {
  if (ar == 2018L) {
    file <- .kalla_2018("kandidaturer", source, data_dir, update, archive)
    out <- .read_kandidaturer_2018(file)
    if (!is.null(val)) out <- dplyr::filter(out, valtyp %in% val)
    return(.kort_kommunnamn_2026(out))
  }
  kalla <- .kandidatur_kalla(ar)
  file <- .resolve_val_file(
    path = kalla$path, ar = ar, samling = kalla$samling, source = source,
    data_dir = data_dir, base_url = kalla$base_url,
    update = update, archive = archive
  )
  out <- if (ar == 2022L) read_kandidaturer_2022(file) else read_kandidaturer_2026(file)

  if (!is.null(val)) {
    out <- out |>
      dplyr::filter(valtyp %in% val)
  }

  .kort_kommunnamn_2026(out)
}


.valtyper <- function(val = NULL) {

  if (is.null(val)) {
    return(NULL)
  }

  .check_text(val, "val", flera = TRUE)
  val <- toupper(val)

  allowed <- c("RD", "RF", "KF")
  invalid <- setdiff(val, allowed)

  if (length(invalid) > 0) {
    stop(
      "Ok\u00e4nd valtyp: ",
      paste(invalid, collapse = ", "),
      ". Till\u00e5tna v\u00e4rden \u00e4r RD, RF och KF.",
      call. = FALSE
    )
  }

  unique(val)
}
