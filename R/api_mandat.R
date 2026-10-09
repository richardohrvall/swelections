.mandat_nivamatris_2026 <- function() {
  tibble::tribble(
    ~valtyp, ~geografiniva,
    "RD", "riket", "RD", "riksdagsvalkrets",
    "RF", "region", "RF", "regionvalkrets",
    "KF", "kommun", "KF", "kommunvalkrets"
  )
}

.mandat_par_2026 <- function(val, niva) {
  val <- if (is.null(val)) c("RD", "RF", "KF") else val
  matris <- dplyr::filter(.mandat_nivamatris_2026(), valtyp %in% val)
  if (is.null(niva)) return(matris)
  .check_text(niva, "niva", flera = TRUE)
  ok <- unique(.mandat_nivamatris_2026()$geografiniva)
  okanda <- setdiff(niva, ok)
  if (length(okanda)) stop("Ok\u00e4nd geografisk niv\u00e5: ", paste(okanda, collapse = ", "), ".", call. = FALSE)
  saknas <- setdiff(unique(niva), matris$geografiniva)
  if (length(saknas)) {
    stop("Niv\u00e5n ", paste(saknas, collapse = ", "),
         " st\u00f6ds inte f\u00f6r vald valtyp.", call. = FALSE)
  }
  dplyr::filter(matris, geografiniva %in% niva)
}

.mandat_public_schema_2026 <- function() {
  .mandat_public_2026(
    dplyr::mutate(.mandat_schema_2026(), antal_tomma_stolar = integer())
  )
}

.mandat_public_2026 <- function(data, ar = 2026L) {
  data <- .publika_andelar_0_1_2026(
    data, c("valomradessparr_procent", "valkretssparr_procent")
  )
  names(data)[names(data) == "valomradessparr_procent"] <- "valomradessparr"
  names(data)[names(data) == "valkretssparr_procent"] <- "valkretssparr"
  data |>
    dplyr::mutate(valar = as.integer(ar), .after = valtillfalle)
}

#' Mandat
#'
#' Hämtar mandatfördelningen.
#'
#' För 2010 används bevarade slutliga XML-/valsedelskällor och samma
#' historiska normalisering som 2014. Publika kandidatnamn är saknade.
#' Preliminära resultat kräver en komplett separat officiell
#' uppsamlingsdistriktssnapshot; valnatt ersätter aldrig preliminär räkning.
#'
#' @param ar Ett eller flera exakta valår (2018, 2022, 2026), eller `"alla"`.
#'   Dubbletter tas bort med den första årsordningen bevarad. Utan årsurval
#'   används 2026.
#' @param fran,till Inklusiva gränser bland stödda valår, som alternativ till
#'   `ar`. En utelämnad gräns är öppen.
#' @param val En eller flera valtyper: `"RD"`, `"RF"` eller `"KF"`.
#'   `NULL` ger alla.
#' @param rakning Exakt en räkning: `"slutlig"` eller `"preliminar"`.
#' @param niva En eller flera geografiska nivåer. RD stöder `"riket"` och
#'   `"riksdagsvalkrets"`, RF `"region"` och `"regionvalkrets"`, och KF
#'   `"kommun"` och `"kommunvalkrets"`. `NULL` ger alla relevanta nivåer.
#' @param source Datakälla: `"auto"`, `"local"`, `"remote"` eller `"canonical"`.
#'   `"canonical"` avser den separat versionerade 2018-samlingen eller ett uttryckligen konfigurerat 2022-bygge i Parquet,
#'   Ett publicerat manifest hämtas automatiskt; en lokal byggversion kan
#'   väljas via `options(swelections.canonical_manifest = "...")`.
#' @param data_dir Lokal rotmapp för rådata.
#' @param update Om `TRUE`, uppdateras lokala arbetskopior.
#' @param archive Om `TRUE`, sparas även daterade snapshots.
#' @param progress Visa progressindikator.
#' @param names `"sv"` (standard) eller `"en"` för publika kolumnnamn.
#' @param detaljniva `"standard"` för centrala analysvariabler eller `"full"`
#'   för alla tillgängliga harmoniserade fält.
#'   Endast kolumnnamn ändras.
#' @return En tibble där en rad avser val, räkning, geografisk nivå och
#'   område samt parti. Områdestotaler upprepas på partirader och nivåerna
#'   ska inte summeras tillsammans. Saknade totalsummor är `NA` när någon
#'   mandatkomponent är okänd. `antal_tomma_stolar` är `NA` utan verifierat
#'   underlag och explicit noll bevaras. För slutlig 2022 beräknas tomma stolar
#'   som partiets mandat minus unika valda ordinarie ledamöter. Valmyndighetens
#'   platsmarkör `"Kunde inte utses"` räknas inte som person och används som
#'   kontroll av fullständiga valda-listor. I valkretsindelade områden används
#'   kompletta valkretsuppgifter för valområdets differens;
#'   valområdet; annars används `NA`. Preliminära 2022-resultat får `NA` för
#'   tomma stolar. Historiska mandat- och jämförelsefält som
#'   saknas i 2022 års JSON är typade `NA`. För 2018 läses endast slutlig
#'   XML. XML-källans aktuella mandat och valda-platsmarkörer används direkt;
#'   historiska mandatfält som saknas i XML är `NA`.
#'   `valar` är en heltalskolumn direkt efter `valtillfalle`. Flera år staplas
#'   i long format. `"alla"` och `fran`/`till` ger stigande årsordning.
#'   `valomradessparr` och `valkretssparr` är proportioner på 0–1-skalan.
#'   För KF är `valomradesnamn` paketets korta kommunnamn, uppslaget via
#'   `valomradeskod`; separata kommunfält dupliceras inte.
#' @examples
#' \dontrun{
#' mandat(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' mandat(ar = c(2022, 2026), val = "RD", niva = "riket")
#' mandat(ar = "alla", val = "RF", niva = "region")
#' mandat(fran = 2022, till = 2026, val = "KF", niva = "kommun")
#' }
#' @seealso [seats()], [valda()], [ersattare()], [swelections-package]
#' @export
mandat <- function(
    ar = 2026,
    val = NULL,
    rakning = c("slutlig", "preliminar"),
    niva = NULL,
    source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL,
    update = FALSE,
    archive = FALSE,
    progress = interactive(),
    fran = NULL,
    till = NULL,
    names = "sv",
    detaljniva = "standard"
) {
  .check_output_language(names)
  ar_angivet <- !missing(ar)
  if (missing(rakning)) rakning <- "slutlig"
  .check_text(rakning, "rakning")
  if (!rakning %in% c("slutlig", "preliminar")) {
    stop("Ok\u00e4nd rakning; ange slutlig eller preliminar.", call. = FALSE)
  }
  val <- .valtyper(val)
  par <- .mandat_par_2026(val, niva)
  val <- unique(par$valtyp)
  valar <- .resolve_valar(ar, fran, till, "mandat", val[[1]], ar_angivet)
  if (length(val) > 1L && !all(vapply(val[-1], function(v) {
    all(valar %in% .stodd_valar("mandat", v))
  }, logical(1)))) stop("Valda \u00e5r st\u00f6ds inte f\u00f6r alla valtyper.", call. = FALSE)
  source <- .check_public_args(
    valar[[1]], "mandat", source, data_dir, update, archive, progress,
    valar_resolved = TRUE
  )
  .check_canonical_years(source, valar)
  purrr::map(valar, function(valar_ett) {
    tryCatch(
      .mandat_ett_ar(valar_ett, val, rakning, par, source, data_dir,
                     update, archive, progress),
      error = function(e) stop("Val\u00e5r ", valar_ett, ": ", conditionMessage(e),
                               call. = FALSE)
    )
  }) |> purrr::list_rbind() |> .public_output_names(names)
}

.mandat_ett_ar <- function(ar, val, rakning, par, source, data_dir,
                           update, archive, progress) {
  if (ar %in% c(2010L, 2014L)) {
    if (rakning != "slutlig") stop(ar, " seats require final election XML.", call. = FALSE)
    if (source == "canonical") return(.canonical_source(ar, "mandat", val,
      unique(par$geografiniva), rakning = rakning))
    return(.mandat_2014(.sources_historical(ar, source, data_dir, update, archive), par, progress))
  }
  if (ar == 2018L && rakning != "slutlig") {
    stop("2018 st\u00f6der endast slutlig r\u00e4kning i det officiella XML-underlaget.",
         call. = FALSE)
  }
  source <- .select_public_source(source, ar, "mandat", data_dir,
                                  update, archive)
  if (source %in% c("canonical", "canonical_auto"))
    return(.canonical_source(ar, "mandat", val,
        unique(par$geografiniva),
        rakning = rakning, auto_selected = identical(source, "canonical_auto")))
  if (ar == 2018L) {
    return(.mandat_2018(val, par, source, data_dir, update, archive, progress))
  }
  index <- .valresultat_index_for_ar(ar, source, data_dir, update, archive)

  prefix <- dplyr::recode_values(
    rakning,
    "slutlig" ~ "s",
    "preliminar" ~ "p"
  )

  paths <- purrr::map_dfr(
    val,
    \(valtyp) {

      pattern <- dplyr::recode_values(
        valtyp,
        "RD" ~ paste0("^", prefix, "/rd/.*_00_RD\\.zip$"),
        "RF" ~ paste0("^", prefix, "/rf/.*_[0-9]{2}_RF\\.zip$"),
        "KF" ~ paste0("^", prefix, "/kf/.*_[0-9]{4}_KF\\.zip$")
      )

      index |>
        dplyr::filter(stringr::str_detect(path, pattern)) |>
        dplyr::transmute(
          valtyp = valtyp,
          path
        )
    }
  )

  saknade_val <- setdiff(val, unique(paths$valtyp))
  if (length(saknade_val)) {
    stop(
      "Hittade ingen mandatfil f\u00f6r: ", paste(saknade_val, collapse = ", "), ".",
      call. = FALSE
    )
  }
  filkod <- sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", paths$path)
  if (anyDuplicated(paste(paths$valtyp, filkod))) {
    stop("Dubbla mandatfiler f\u00f6r samma filidentitet.", call. = FALSE)
  }

  parsed <- purrr::map(
    paths$path,
    \(path) {

      file <- .valresultat_file_for_ar(
        ar, path, source, data_dir, update, archive
      )
      raw <- if (ar == 2022L) {
        .read_valresultat_raw(file, "M", paths$valtyp[[match(path, paths$path)]],
                             rakning, ar = ar)
      } else {
        .normalisera_rakningsmetadata_2026(
          read_raw_json_zip_2026(file, type = "mandatfordelning")
        )
      }

      if (!identical(as_chr_na(raw$valtyp), paths$valtyp[[match(path, paths$path)]]) ||
          !identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), rakning)) {
        stop("Mandatfilens valtyp eller r\u00e4kning st\u00e4mmer inte med fils\u00f6kv\u00e4gen.", call. = FALSE)
      }

      mandat_data <- parse_mandat_2026(raw)

      tomma_stolar <- if (ar == 2022L) {
        parse_tomma_stolar_2022(raw)
      } else {
        parse_tomma_stolar_2026(raw)
      }

      if (nrow(tomma_stolar) > 0) {
        mandat_data <- mandat_data |>
          dplyr::left_join(
            tomma_stolar,
            by = dplyr::join_by(
              valtyp,
              geografiniva,
              valomradeskod,
              valkretskod,
              partikod
            )
          )
      } else {
        mandat_data <- mandat_data |>
          dplyr::mutate(
            antal_tomma_stolar = NA_integer_
          )
      }

      mandat_data
    },
    .progress = progress
  ) |>
    purrr::list_rbind() |>
    dplyr::inner_join(par, by = dplyr::join_by(valtyp, geografiniva))

  parsed <- dplyr::bind_rows(
    dplyr::mutate(.mandat_schema_2026(), antal_tomma_stolar = integer()),
    parsed
  )
  parsed <- .kort_kommunnamn_2026(parsed)
  parsed <- .mandat_public_2026(parsed, ar)
  nyckel <- c("valtillfalle", "valtyp", "rakningstillfalle", "geografiniva",
              "valomradeskod", "valkretskod", "partikod")
  obligatoriska <- setdiff(nyckel, "valkretskod")
  if (nrow(parsed) && (anyNA(parsed[obligatoriska]) || anyDuplicated(parsed[nyckel]))) {
    stop("Mandatresultatet har saknad eller dubblerad nyckel.", call. = FALSE)
  }
  parsed
}
