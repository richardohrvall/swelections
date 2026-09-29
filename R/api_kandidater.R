#' Kandidater
#'
#' Skapar en analysvänlig kandidatfil.
#'
#' En rad motsvarar kandidatnummer × valtyp × parti. Kandidater som
#' ställer upp på flera politiska nivåer eller för flera partier kan därför
#' förekomma på flera rader.
#'
#' `oppen_lista` sammanfattar kandidatens giltiga kandidaturer och är känd
#' endast när alla ger samma status. `pa_namnvalsedel` är `TRUE` om minst en
#' giltig kandidatur stod på en tryckt namnvalsedel; om ingen gjorde det är
#' värdet `FALSE` bara när alla berörda kandidaturer har verifierad negativ
#' status. En äldre eller okänd kandidatfil kan därför ge `NA`.
#'
#' `antal_personroster_totalt` är känt endast när varje relevant
#' personvalsområde har ett känt värde. För 2026 används i första hand
#' officiella personvalstal, därefter verifierat komplett områdesmaterial.
#' För 2022 används de officiella slutliga områdeslistornas personröster;
#' varje lista avstäms mot sina personröster och partiets röster. Röster från
#' flera resultatlistor summeras en gång per kandidat och område, oavsett om
#' listan motsvarar en tryckt namnvalsedel. `90000` är partiröster och ger inga
#' ytterligare redovisade kandidatpersonröster. Om en komplett områdesstruktur
#' saknar en partirad är kandidatens redovisade personröster där 0; ett område
#' vars resultatstruktur inte kan verifieras ger `NA`.
#' Personvalskvalificering bedöms separat.
#'
#' För 2018 läses personröster och invaldsuppgifter från det slutliga
#' XML-resultatet. Publika namn är alltid `NA`, även om en lokal historisk
#' kandidatsnapshot innehåller namn. Resultatberoende 2018-anrop kräver en
#' lokal kopia av slutresultat-ZIP på rådatavägen, eller den separat
#' versionerade kanoniska Parquet-samlingen med `source = "canonical"`.
#'
#' @param ar Ett eller flera exakta valår (2018, 2022, 2026), eller `"alla"`.
#'   Dubbletter tas bort med den första årsordningen bevarad. Standard är 2026.
#' @param fran,till Inklusiva årsgränser bland stödda år, som alternativ till
#'   `ar`. En utelämnad gräns är öppen.
#' @param val En eller flera valtyper: `"RD"`, `"RF"` eller `"KF"`.
#'   `NULL` ger alla.
#' @param resultat Om `TRUE`, kompletteras kandidaterna med personröster,
#'   personval och invaldsuppgifter från slutliga resultatfiler.
#' @param source Datakälla: `"auto"`, `"local"`, `"remote"` eller `"canonical"`.
#'   `"canonical"` avser den separat versionerade 2018-samlingen i Parquet.
#'   Ett publicerat manifest hämtas automatiskt; en lokal byggversion kan
#'   väljas via `options(swelections.canonical_manifest = "...")`.
#'   `"auto"` väljer kompletta lokala officiella råfiler först, därefter en
#'   publicerad kanonisk samling som uttryckligen godkänts för automatiskt
#'   bruk, annars officiell fjärrkälla. För 2022/2026 används rådatavägen.
#'   `"local"` använder aldrig nätet och får inte kombineras med `update = TRUE`.
#'   Lokal arkivering kräver en redan befintlig lokal fil.
#' @param data_dir Lokal rotmapp för rådata.
#' @param update Om `TRUE`, uppdateras lokala arbetskopior.
#' @param archive Om `TRUE`, sparas även daterade snapshots.
#' @param progress Visa progressindikator vid läsning av resultatfiler.
#' @param names `"sv"` (standard) eller `"en"` för publika kolumnnamn.
#'
#' @return En tibble med en rad per `kandidatnummer`, `valtyp` och `partikod`,
#'   byggd från giltiga kandidaturer. Namn normaliseras deterministiskt och
#'   `namn_varierar` anger om flera normaliserade namn förekommer.
#'   `valar` är en heltalskolumn direkt efter `valtillfalle`; flera år staplas.
#'   `oppen_lista` är kandidatens entydiga status över giltiga kandidaturer.
#'   `pa_namnvalsedel` anger om kandidaten stod på minst en tryckt
#'   namnvalsedel, till skillnad från [kandidaturer()] där fältet avser
#'   den enskilda kandidaturen. Blandade eller okända underlag kan ge `NA`.
#'   Med `resultat = TRUE` tillkommer resultatkolumner. `invald` och
#'   `kvalificerad_personval` är `NA` när relevant information saknas,
#'   och `FALSE` när informationen finns men kandidaten inte uppfyller villkoret.
#'   `antal_personroster_totalt` summerar verifierade områdesvärden; för 2026
#'   är det samma områdesvärden som ligger till grund för [personroster()].
#'   Totalen är 0 endast när samtliga relevanta områden är verifierade nollor;
#'   ett okänt område ger `NA`. Antalsfält är integer och indikatorer logical.
#'   `antal_valkretsar` är antal distinkta valkretsar med giltig kandidatur
#'   inom kandidatens nyckel, även om flera listor används i samma valkrets.
#'   När antalet är större än ett är kandidatnivåns `valkretskod` och
#'   `valkretsnamn` `NA`; vid otillräcklig kandidaturgeografi är även antalet
#'   `NA`. Fältet är integer och gäller 2018, 2022 och 2026.
#'   Kandidatidentitet och parti följs av personröst-, personvals- och
#'   invaldsfält; tekniska kandidatursammanfattningar ligger sist.
#'   För KF är `valomradesnamn` paketets korta kommunnamn när kandidaten har
#'   ett entydigt valområde. Vid flera valområden är både `valomradeskod` och
#'   `valomradesnamn` `NA`, medan `antal_valomraden` och `flera_valomraden`
#'   visar varför. `invald_valomradeskod` och `invald_valomradesnamn` beskriver
#'   det faktiska invaldsområdet oberoende av kandidaturernas antal; även där
#'   används kort kommunnamn för KF. `folkbokforingskommun` ändras inte.
#' @examples
#' \dontrun{
#' kandidater(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' kandidater(ar = c(2022, 2026), val = "RD")
#' }
#' @seealso [candidates()], [kandidaturer()], [valda()], [swelections-package]
#' @export
kandidater <- function(
    ar = 2026,
    val = NULL,
    resultat = TRUE,
    source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive(),
    fran = NULL,
    till = NULL,
    names = "sv"
) {
  .check_output_language(names)
  ar_angivet <- !missing(ar)
  val <- .valtyper(val)
  valar <- .resolve_valar(ar, fran, till, "kandidater",
                         if (is.null(val)) "RD" else val[[1]], ar_angivet)
  source <- .check_public_args(
    valar[[1]], "kandidater", source, data_dir, update, archive, progress,
    valar_resolved = TRUE
  )
  .check_canonical_years(source, valar)
  .check_flag(resultat, "resultat")

  purrr::map(valar, function(ett_ar) {
    tryCatch(
      .kandidater_ett_ar(ett_ar, val, resultat, source, data_dir, update,
                         archive, progress),
      error = function(e) stop("Val\u00e5r ", ett_ar, ": ", conditionMessage(e),
                               call. = FALSE)
    )
  }) |> purrr::list_rbind() |> .public_output_names(names)
}

.kandidater_ett_ar <- function(ar, val, resultat, source, data_dir, update,
                               archive, progress) {
  source <- .select_public_source(source, ar, "kandidater", data_dir,
                                  update, archive, include_results = resultat)
  if (source %in% c("canonical", "canonical_auto"))
    return(.canonical_2018_source("kandidater", val, resultat = resultat,
      auto_selected = identical(source, "canonical_auto")))
  kandidaturdata <- kandidaturer(
    ar = ar,
    val = val,
    source = source,
    data_dir = data_dir,
    update = update,
    archive = archive
  )

  out <- .kandidater_bas(kandidaturdata, ar)

  if (!is.null(val)) {
    out <- out |>
      dplyr::filter(valtyp %in% val)
  } else {
    val <- c("RD", "RF", "KF")
  }

  if (!isTRUE(resultat)) {
    return(out)
  }

  add_resultat <- if (ar == 2018L) .add_kandidatresultat_2018 else
    if (ar == 2022L) .add_kandidatresultat_2022 else
      .add_kandidatresultat_2026
  add_resultat(
    kandidater = out,
    kandidaturer = kandidaturdata,
    val = val,
    source = source,
    data_dir = data_dir,
    update = update,
    archive = archive,
    progress = progress
  )
}

.kandidater_bas <- function(kandidaturdata, ar) {
  out <- make_kandidater_2026(kandidaturdata) |>
    dplyr::mutate(valar = as.integer(ar), .after = valtillfalle)
  dplyr::left_join(
    out, .kandidatstatus(kandidaturdata),
    by = dplyr::join_by(kandidatnummer, valtyp, partikod),
    relationship = "one-to-one"
  )
}

.kandidatstatus <- function(kandidaturdata) {
  kandidaturdata |>
    dplyr::filter(giltig %in% TRUE) |>
    dplyr::summarise(
      oppen_lista = .enhetlig_status(
        dplyr::pick(dplyr::all_of("oppen_lista"))[[1]]),
      pa_namnvalsedel = .existentiell_status(
        dplyr::pick(dplyr::all_of("pa_namnvalsedel"))[[1]]),
      .by = c(kandidatnummer, valtyp, partikod)
    )
}

.enhetlig_status <- function(x) {
  if (all(x %in% TRUE)) return(TRUE)
  if (all(x %in% FALSE)) return(FALSE)
  NA
}

.existentiell_status <- function(x) {
  if (any(x %in% TRUE)) return(TRUE)
  if (all(x %in% FALSE)) return(FALSE)
  NA
}


#' Valda kandidater
#'
#' Läser personer i Valmyndighetens officiella slutliga invaldsrelation och
#' kompletterar med kandidatmetadata. Preliminära resultatfiler saknar denna
#' relation och används aldrig som reservkälla.
#'
#' @inheritParams ersattare
#' @param ar Ett eller flera exakta valår (2018, 2022, 2026), eller `"alla"`.
#'   Dubbletter tas bort med den första årsordningen bevarad. Standard är 2026.
#' @param fran,till Inklusiva årsgränser bland stödda år, som alternativ till
#'   `ar`. En utelämnad gräns är öppen.
#' @param progress Visa progressindikator vid läsning av resultatfiler.
#' @return En tibble med en rad per vald kandidat, valtyp och parti. Endast
#'   personer i den verifierade slutliga invaldsrelationen ingår; en saknad
#'   eller ännu ofärdig slutlig källa ger fel. Ingen egen preliminär
#'   invaldsfördelning beräknas.
#'   Kolumnerna motsvarar `kandidater(resultat = TRUE)` utom
#'   `antal_valkretsar`, som beskriver kandidaturer och inte invaldsrelationen.
#'   `valkretskod` och `valkretsnamn` kommer från invaldsrelationen och anger
#'   valkretsen där personen valdes, även vid kandidatur i flera valkretsar.
#'   I odelade valområden är dessa fält `NA`. `valar` är integer direkt efter
#'   `valtillfalle`; flera år staplas i angiven årsordning. För 2018 hämtas
#'   personröster och invaldsrelation från slutresultatets XML, och publika
#'   namn är alltid `NA`. För 2022 hämtas personröster från slutliga
#'   områdeslistor, för 2026 från verifierade områdessummeringar.
#'   Kandidatfilens övriga metadata och dess `NA` bevaras.
#' @examples
#' \dontrun{
#' valda(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' valda(ar = c(2022, 2026), val = "RD")
#' }
#' @seealso [elected()], [kandidater()], [ersattare()], [swelections-package]
#' @export
valda <- function(
    ar = 2026,
    val = NULL,
    source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive(),
    fran = NULL,
    till = NULL,
    names = "sv"
) {
  .check_output_language(names)
  ar_angivet <- !missing(ar)
  val <- .valtyper(val)
  val <- if (is.null(val)) c("RD", "RF", "KF") else val
  valar <- .resolve_valar(ar, fran, till, "valda", val[[1]], ar_angivet)
  if (length(val) > 1L && !all(vapply(val[-1], function(v) {
    all(valar %in% .stodd_valar("valda", v))
  }, logical(1)))) {
    stop("Valda \u00e5r st\u00f6ds inte f\u00f6r alla valtyper.", call. = FALSE)
  }
  source <- .check_public_args(
    valar[[1]], "valda", source, data_dir, update, archive, progress,
    valar_resolved = TRUE
  )
  .check_canonical_years(source, valar)
  purrr::map(valar, function(ett_ar) {
    tryCatch(
      .valda_ett_ar(ett_ar, val, source, data_dir, update, archive, progress),
      error = function(e) stop("Val\u00e5r ", ett_ar, ": ", conditionMessage(e),
                               call. = FALSE)
    )
  }) |> purrr::list_rbind() |> .public_output_names(names)
}
