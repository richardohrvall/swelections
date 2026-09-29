#' Officiella valresultat för 2018, 2022 och 2026
#'
#' Läser en valtyp, en räkning och en geografisk nivå för ett eller flera valår
#' från Valmyndighetens
#' officiella primärkälla. Ingen geografisk aggregering eller automatisk
#' reservkälla används om den valda källan saknas.
#'
#' @param ar Ett eller flera exakta valår, till exempel `c(2018, 2022, 2026)`, eller
#'   `"alla"` för samtliga stödda år för vald valtyp. Dubbletter tas bort med
#'   den först angivna årsordningen bevarad. Standard är 2026 när inga
#'   intervallgränser anges.
#' @param fran,till Inklusiva gränser för ett intervall bland **stödda** valår.
#'   Används som alternativ till `ar`; `fran = 2021, till = 2026` väljer i
#'   nuläget 2022 och 2026. Utelämnad gräns är öppen.
#' @param val Exakt en valtyp: `"RD"`, `"RF"` eller `"KF"`. Inte `NULL`.
#' @param rakning Exakt en räkning: `"slutlig"` (default) eller `"preliminar"`.
#' @param niva En geografisk nivå. `NULL` ger valets huvudnivå: RD `"riket"`,
#'   RF `"region"`, KF `"kommun"`. Se nivåerna nedan.
#' @param names `"sv"` (standard) eller `"en"` för publika kolumnnamn.
#'   Endast kolumnnamn ändras; datavärden och typer bevaras.
#' @inheritParams mandat
#'
#' @details
#' RD stöder valdistrikt, kommun, kommunvalkrets, riksdagsvalkrets och riket.
#' RF stöder valdistrikt, kommun, kommunvalkrets, region, regionvalkrets och
#' riket. KF stöder valdistrikt, kommun, kommunvalkrets, lan och riket.
#' Detta är 2026 års nivåer. För 2022 stöds endast de officiella D- och
#' M-noderna, vid såväl preliminär som slutlig räkning:
#'
#' | Val | D: valdistrikt | M: valkrets | M: valområde |
#' | --- | --- | --- | --- |
#' | RD | valdistrikt | riksdagsvalkrets | riket |
#' | RF | valdistrikt | regionvalkrets | region |
#' | KF | valdistrikt | kommunvalkrets (där indelning finns) | kommun |
#'
#' Övriga 2022-nivåer stöds inte: separata U/O-summeringar finns inte i
#' 2022 års resultatindex. Nivåer skapas inte genom egen distriktsaggregering.
#' För 2018 används Valmyndighetens separata slutliga XML-källa. RD stöder
#' valdistrikt, kommun, kommunvalkrets, län, riksdagsvalkrets och riket; RF
#' valdistrikt, kommun, kommunvalkrets, regionvalkrets, region och riket; KF
#' valdistrikt, kommun, kommunvalkrets, län och riket. Preliminär 2018-räkning
#' stöds inte. XML-värden normaliseras till samma interna och publika schema;
#' saknade jämförelseuppgifter är typade `NA`.
#' RD/lan stöds inte. RF/lan är dokumenterat i OS-formatet men ännu inte
#' aktiverat, eftersom faktisk slutlig källa inte är verifierad.
#'
#' Distriktsresultat läses ur individuell röstfördelning. RD/RF:s kommuner
#' och kommunvalkretsar läses ur underordnad summering. Valområden och deras
#' mandatvalkretsar läses ur mandatfilens röstfördelning. RF/KF:s riksresultat
#' och KF:s länsresultat läses ur överordnad summering (OS), om filen finns
#' i valt index. Räkningstillfället bevaras i `rakningstillfalle`.
#'
#' En rad avser val, geografiskt område och parti/kategori. Områdestotaler
#' upprepas på partiraderna och ska inte summeras över partier. Internt
#' harmoniseras alla källor till samma 83 kolumner. Det publika resultatet
#' innehåller en gemensam analyskärna och endast den geografiska identifikation
#' som är relevant för vald `niva`. Datum, tidsstämplar och geografiska koder
#' är character, antal integer, publika andelar double på 0–1-skalan och
#' indikatorer logical. Publika andelar uttrycks som proportioner på 0–1-skalan.
#' Där exakta täljare och nämnare finns och deras semantik är verifierad
#' beräknas andelarna från antalsuppgifterna. Officiella källvärden används
#' annars. Differenser mellan andelar uttrycks på samma skala:
#' `0.025` betyder en ökning med 2,5 procentenheter och är inte en relativ
#' procentuell förändring. `valomradessparr` och `valkretssparr` följer samma
#' 0–1-konvention. Saknade eller ej tillämpliga fält är typade `NA`.
#' Historik och differenser bevaras endast där källan publicerar dem.
#' 2022 års resultat-JSON saknar de flesta föregående-val- och
#' jämförelsefälten; dessa är typade `NA`. Separata historiska
#' jämförelsekällor är ännu inte integrerade. Källans `Val_20220911`
#' normaliseras till `Val_2022`; saknade valdatum och andra metadata gissas
#' inte. D-nivåns aktuella andelar använder distriktets officiella rösttal och
#' röstberättigade. M-nivån använder mandatfilens områdes-/valkretsnoder och
#' `antalRostberattigadeIRaknadeValdistrikt` som valdeltagandets nämnare.
#'
#' `antal_valdistrikt_raknade` och `antal_valdistrikt_som_ska_raknas` avser
#' filpopulationen. Motsvarigheterna med suffix `_omrade` exponeras bara där
#' den returnerade områdespopulationen är en annan analytiskt relevant nivå.
#' `antal_rostberattigade_raknade` finns på aggregerade nivåer och är källans
#' antal röstberättigade i hittills räknade valdistrikt för området. På
#' valdistriktsnivå ligger `raknat` och distriktets `rapporteringstid` direkt
#' efter geografin. Där används `antal_rostberattigade` för distriktets eget
#' antal när rådata anger det, även om distriktet ännu inte är räknat.
#' På ett rapporterat vanligt valdistrikt beräknas `valdel` som totala röster
#' dividerat med distriktets röstberättigade och motsvarar Valmyndighetens
#' `valdeltagandeVallokal`. Det är inte fullt valdeltagande bland alla som hör
#' till distriktet: sena förtids- och brevröster redovisas i separata
#' uppsamlingsdistrikt och kan inte föras tillbaka till ett vanligt distrikt.
#' Uppsamlingsdistrikt saknar därför `valdel`. På aggregerade nivåer används
#' totala röster dividerat med röstberättigade i hittills räknade valdistrikt.
#' `over_sparr` fylls bara från ett uttryckligt relevant besked i mandatkällan.
#' Övriga partier får en rad endast om källnoden finns; explicit noll behålls.
#' På valdistriktsnivå är `raknat` `TRUE` för distrikt med ett rapporterat
#' röstfördelningsobjekt och `FALSE` när den befintliga
#' `rostfordelning`-nyckeln är `NULL`. Oräknade distrikt behålls med det
#' officiella partiuniversumet från mandatfilens röstfördelning i samma ZIP;
#' deras aktuella röster, andelar och resultatmått är typade `NA`. En
#' uttrycklig nolla i ett rapporterat resultat behålls som 0. En saknad
#' `rostfordelning`-nyckel eller en motsägelsefull struktur ger fel.
#' `kommunnamn` är paketets korta analysnamn, uppslaget exakt via `kommunkod`.
#' `kommunnamn_officiellt` bevarar Valmyndighetens benämning när källan har
#' en sådan; den konstrueras aldrig från kortnamnet.
#' Flera valår staplas i long format, inte i årsspecifika wide-kolumner.
#' `valar` är en `integer`-tidsvariabel direkt efter `valtillfalle`.
#' Exakta år i `ar` behåller angiven ordning. `"alla"` och `fran`/`till`
#' ordnas kronologiskt. Samtliga valda år måste stödja samma begärda
#' valtyp/räkning/nivå; ett saknat år eller en otillgänglig källa ger fel
#' utan partiellt flerårsresultat.
#'
#' De geografiska kolumnerna är: valdistrikt — `valdistriktskod`,
#' `valdistriktsnamn`, `valdistriktstyp`, `kommunkod`, `kommunnamn`,
#' `kommunnamn_officiellt`, `lankod`,
#' `lannamn`, `valomradeskod`, `valomradesnamn`, `valkretskod`,
#' `valkretsnamn`, `kommunvalkretskod`, `kommunvalkretsnamn`; kommun —
#' `lankod`, `lannamn`, `kommunkod`, `kommunnamn`,
#' `kommunnamn_officiellt`; kommunvalkrets — samma
#' läns- och kommunidentitet samt `kommunvalkretskod`,
#' `kommunvalkretsnamn`; län — `lankod`, `lannamn`; region —
#' `valomradeskod`, `valomradesnamn`; region- och riksdagsvalkrets —
#' `valomradeskod`, `valomradesnamn`, `valkretskod`, `valkretsnamn`; riket —
#' inga ytterligare geografiska kolumner. `geografiniva` finns alltid.
#'
#' `data_dir` går före optionen `swelections.data_dir`. Resultatsamlingen
#' väljs med optionen `swelections.resultatsamling_2026` (default `"val2026"`).
#' Test-/utvecklingssamlingen `"genrep2026"` kan väljas uttryckligen.
#' För 2022 används `"val2022"` och vid behov optionen
#' `swelections.resultatsamling_2022`.
#' `source = "local"` använder aldrig nätet. Lokal arkivering kopierar endast
#' befintliga filer; en snapshot från samma datum får ersättas.
#' @return En tibble i long format med ett nivåspecifikt publikt
#'   kolumnkontrakt, `valar` som integer och unika val-/områdes-/partinycklar.
#'   Inga mandat eller personröster ingår. `dplyr::bind_rows()` kan användas
#'   för att skapa unionen av kolumner från flera nivåer.
#' @seealso [results()], [mandat()], [swelections-package]
#' @examples
#' \dontrun{
#' valresultat(val = "RD", source = "local", data_dir = "mitt_arkiv")
#' valresultat(val = "KF", niva = "kommun", rakning = "preliminar")
#' valresultat(ar = c(2022, 2026), val = "RD", niva = "riket")
#' valresultat(ar = "alla", val = "RD", niva = "riket")
#' valresultat(fran = 2010, till = 2026, val = "RD", niva = "riket")
#' }
#' @export
valresultat <- function(
    ar = 2026, val = "RD", rakning = c("slutlig", "preliminar"),
    niva = NULL, source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv"
) {
  .check_output_language(names)
  ar_angivet <- !missing(ar)
  .check_text(val, "val")
  val <- toupper(val)
  if (!val %in% c("RD", "RF", "KF")) stop("Ok\u00e4nd valtyp.", call. = FALSE)
  valar <- .resolve_valar(ar, fran, till, "valresultat", val, ar_angivet)
  if (missing(rakning)) rakning <- "slutlig"
  .check_text(rakning, "rakning")
  if (!rakning %in% c("slutlig", "preliminar")) {
    stop("Ok\u00e4nd rakning; ange slutlig eller preliminar.", call. = FALSE)
  }
  if (is.null(niva)) niva <- c(RD = "riket", RF = "region", KF = "kommun")[[val]]
  .check_text(niva, "niva")
  if (length(valar) == 1L) {
    kallor <- .valresultat_kalla(val, niva, valar[[1]])
  } else {
    provning <- lapply(valar, function(ar) {
      tryCatch(.valresultat_kalla(val, niva, ar), error = identity)
    })
    saknas <- vapply(provning, inherits, logical(1), "error")
    if (any(saknas)) {
      stop("Niv\u00e5n ", niva, " f\u00f6r ", val, "/", rakning,
           " kan inte levereras f\u00f6r \u00e5r: ", paste(valar[saknas], collapse = ", "),
           ". ", paste(vapply(provning[saknas], conditionMessage, ""), collapse = " "),
           call. = FALSE)
    }
    kallor <- unlist(provning, use.names = FALSE)
  }
  source <- .check_public_args(
    valar[[1]], "valresultat", source, data_dir, update, archive, progress,
    valar_resolved = TRUE
  )
  .check_canonical_years(source, valar)
  purrr::map2(valar, kallor, function(ar, kalla) {
    tryCatch(
      .valresultat_ett_ar(ar, val, rakning, niva, kalla, source, data_dir,
                         update, archive, progress),
      error = function(e) stop("Val\u00e5r ", ar, ": ", conditionMessage(e), call. = FALSE)
    )
  }) |> purrr::list_rbind() |> .public_output_names(names)
}

.valresultat_ett_ar <- function(ar, val, rakning, niva, kalla, source,
                               data_dir, update, archive, progress) {
  if (ar == 2018L && rakning != "slutlig") {
    stop("2018 st\u00f6der endast slutlig r\u00e4kning i det officiella XML-underlaget.",
         call. = FALSE)
  }
  source <- .select_public_source(source, ar, "valresultat", data_dir,
                                  update, archive)
  if (ar == 2018L) {
    if (source %in% c("canonical", "canonical_auto"))
      return(.canonical_2018_source("valresultat", val, niva,
        auto_selected = identical(source, "canonical_auto")))
    return(.valresultat_2018(val, niva, source, data_dir, update, archive, progress))
  }
  index <- .valresultat_index_for_ar(ar, source, data_dir, update, archive)
  paths <- .valresultat_paths(index, val, rakning, kalla)
  resultat <- purrr::map(paths, function(path) {
    tryCatch({
      file <- .valresultat_file_for_ar(ar, path, source, data_dir, update, archive)
      raw <- .read_valresultat_raw(
        file, kalla, val, rakning, distrikt_context = kalla == "D", ar = ar
      )
      harmoniserat <- .parse_valresultat(raw, kalla, val, niva, rakning, path)
      .valresultat_public_2026(harmoniserat, niva, raw, ar = ar)
    }, error = function(e) {
      stop(path, ": ", conditionMessage(e), call. = FALSE)
    })
  }, .progress = progress) |>
    purrr::list_rbind()
  .valresultat_check_key(resultat, niva)
  identitet <- c("valtillfalle", "valtyp", "rakningstillfalle", "geografiniva")
  if (nrow(unique(resultat[identitet])) > 1L) {
    stop("Filerna avser olika val eller r\u00e4kningar.", call. = FALSE)
  }
  nyckel <- c(.valresultat_geo_key(niva), "ovriga_partier", "partikod")
  dplyr::arrange(resultat, dplyr::across(dplyr::all_of(nyckel)))
}

.valresultat_scalar <- function(x, namn) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("`", namn, "` ska vara exakt ett icke-tomt textv\u00e4rde, inte NULL/NA.", call. = FALSE)
  }
}

.valresultat_kalla <- function(val, niva, ar = 2026) {
  if (ar == 2018L) {
    .valresultat_niva_2018(val, niva)
    return("XML")
  }
  if (ar == 2022) {
    matris <- list(
      RD = c(valdistrikt = "D", riksdagsvalkrets = "M", riket = "M"),
      RF = c(valdistrikt = "D", regionvalkrets = "M", region = "M"),
      KF = c(valdistrikt = "D", kommunvalkrets = "M", kommun = "M")
    )
    kalla <- unname(matris[[val]][niva])
    if (is.na(kalla)) {
      stop("Niv\u00e5n ", niva, " st\u00f6ds inte f\u00f6r ", val,
           " \u00e5r 2022: officiell resultatnod saknas.", call. = FALSE)
    }
    return(kalla)
  }
  # RF/lan har en beslutad filklass men en separat aktiveringskontroll.
  matris <- list(
    RD = c(valdistrikt = "D", kommun = "U", kommunvalkrets = "U",
           riksdagsvalkrets = "M", riket = "M"),
    RF = c(valdistrikt = "D", kommun = "U", kommunvalkrets = "U",
           region = "M", regionvalkrets = "M", riket = "O", lan = "O"),
    KF = c(valdistrikt = "D", kommun = "M", kommunvalkrets = "M",
           lan = "O", riket = "O")
  )
  if (niva == "lan" && val == "RD") {
    stop("RD/lan st\u00f6ds inte: officiell l\u00e4nssummering saknas.", call. = FALSE)
  }
  if (niva == "lan" && val == "RF") {
    stop("RF/lan finns i OS-formatet men \u00e4r inte aktiverat: slutlig k\u00e4lla ",
         "\u00e4r inte verifierad. Anv\u00e4nd region.", call. = FALSE)
  }
  kalla <- unname(matris[[val]][niva])
  if (is.na(kalla)) {
    stop("Niv\u00e5n ", niva, " st\u00f6ds inte f\u00f6r ", val, ".",
         if (niva == "region") " Administrativ indelning ben\u00e4mns lan.", call. = FALSE)
  }
  kalla
}

.valresultat_paths <- function(index, val, rakning, kalla) {
  prefix <- if (rakning == "slutlig") "s" else "p"
  kod <- if (kalla == "O") "OS" else switch(val, RD = "00", RF = "[0-9]{2}", KF = "[0-9]{4}")
  pattern <- paste0("^", prefix, "/", tolower(val), "/[^/]+_", rakning, "_", kod, "_", val, "\\.zip$")
  paths <- sort(index$path[!is.na(index$path) & grepl(pattern, index$path)])
  if (!length(paths)) {
    stop("Saknad prim\u00e4rk\u00e4lla ", kalla, " f\u00f6r ", val, "/", rakning, ".", call. = FALSE)
  }
  koder <- sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", paths)
  if (anyDuplicated(koder)) stop("Dubbla filer f\u00f6r samma filidentitet.", call. = FALSE)
  paths
}

.read_valresultat_raw <- function(file, kalla, val, rakning,
                                 distrikt_context = FALSE, ar = 2026) {
  if (grepl("^https?://", file)) {
    lokal <- tempfile(fileext = ".zip")
    on.exit(unlink(lokal), add = TRUE)
    utils::download.file(file, lokal, mode = "wb", quiet = TRUE)
    file <- lokal
  }
  filer <- utils::unzip(file, list = TRUE)$Name
  typ <- switch(kalla, D = "rostfordelning", M = "mandatfordelning", U = "summering", O = "summering")
  # Kräv rätt typsegment, val och räkning samt exakt en träff.
  # Rotstrukturen verifieras dessutom före parsning, särskilt för OS.
  if (kalla == "O") typ <- "(?:overordnad_)?summering"
  pattern <- paste0("(^|/)[^/]+_", rakning, "_", typ,
                    "(?:_[^/]+)?_", val, "\\.json$")
  poster <- filer[grepl(pattern, filer, perl = TRUE)]
  if (length(poster) != 1L) {
    stop("F\u00f6rv\u00e4ntade exakt en JSON-fil f\u00f6r ", kalla, "/", val, "/", rakning,
         "; hittade ", length(poster), ".", call. = FALSE)
  }
  exdir <- tempfile()
  dir.create(exdir)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
  utils::unzip(file, files = poster, exdir = exdir)
  raw <- jsonlite::fromJSON(file.path(exdir, poster), simplifyVector = FALSE)
  if (ar == 2022) raw <- .normalisera_resultat_2022(raw)
  if (distrikt_context) {
    if (kalla != "D") stop("Distriktskontext kr\u00e4ver k\u00e4lltyp D.", call. = FALSE)
    context <- list(
      mandat = .read_valresultat_raw(file, "M", val, rakning, ar = ar),
      summering = NULL
    )
    if (ar == 2026 && val %in% c("RD", "RF")) {
      context$summering <- .read_valresultat_raw(file, "U", val, rakning, ar = ar)
    }
    attr(raw, "valresultat_distrikt_context") <- context
  }
  raw
}
