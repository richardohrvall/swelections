.valresultat_geo_key <- function(niva) {
  switch(niva,
    valdistrikt = c("valomradeskod", "kommunkod", "valdistriktskod", "valdistriktstyp"),
    kommun = "kommunkod", kommunvalkrets = c("kommunkod", "kommunvalkretskod"),
    lan = "lankod", region = "valomradeskod",
    regionvalkrets = c("valomradeskod", "valkretskod"),
    riksdagsvalkrets = c("valomradeskod", "valkretskod"), riket = character()
  )
}

.valresultat_check_key <- function(data, niva) {
  if (!nrow(data)) return(invisible(NULL))
  geo <- .valresultat_geo_key(niva)
  # Distriktstyp ingår i nyckeln men kan saknas i källan.
  krav <- c("valtillfalle", "valtyp", "rakningstillfalle", setdiff(geo, "valdistriktstyp"))
  if (any(vapply(data[krav], function(x) any(is.na(x) | !nzchar(x)), logical(1)))) {
    stop("Saknad val- eller omr\u00e5desidentitet.", call. = FALSE)
  }
  if (any(!data$ovriga_partier & (is.na(data$partikod) | !nzchar(data$partikod)))) {
    stop("Saknad partikod f\u00f6r enskilt parti.", call. = FALSE)
  }
  nyckel <- c("valtillfalle", "valtyp", "rakningstillfalle", "geografiniva", geo,
              "partikod", "ovriga_partier")
  if (anyDuplicated(data[nyckel])) stop("Duplicerad resultatnyckel.", call. = FALSE)
  invisible(NULL)
}

.valresultat_object <- function(x, namn) {
  if (!is.list(x) || is.null(names(x)) || anyDuplicated(names(x))) {
    stop("Ogiltigt eller saknat objekt: ", namn, ".", call. = FALSE)
  }
}

.valresultat_array <- function(x, namn, tom = FALSE) {
  if (!is.list(x) || (length(x) && !is.null(names(x))) || (!tom && !length(x))) {
    stop("Ogiltig eller saknad samling: ", namn, ".", call. = FALSE)
  }
  x
}

# Kontrollera använda skalärer innan de toleranta befintliga hjälparna körs.
# Personröster, mandat och andra understrukturer ingår inte i denna kontroll.
.valresultat_values <- function(obj) {
  text <- c("valtillfalle", "valklass", "rakningstillfalle", "valtyp", "valdatum",
            "tidigareValdatum", "senasteUppdateringstid", "senasteRapporteringstid",
            "rapporteringsTid", "namn", "namnValkrets", "kod", "kommunkod", "lankod",
            "valdistriktskod", "valdistriktstyp", "valomradeskod", "kretskod",
            "kommunvalkretsKod", "kommunvalkretsNamn", "statusJamforelse",
            "partibeteckning", "partiforkortning", "partikod", "fargkod", "deltaMandatfordelning")
  # Classify field names together; every non-NULL value is still checked below.
  fields <- names(obj)
  text_fields <- fields %in% text
  integer_fields <- grepl(
    "^(antal|totaltAntalRoster|forandringAntal|forandringTotaltAntalRoster|ordningsnummer)", fields)
  double_fields <- grepl(
    "^(andel|valdeltagande|forandringAndel|forandringValdeltagande|valomradessparrProcent|valkretssparrProcent)", fields)
  for (i in seq_along(fields)) {
    namn <- fields[[i]]
    x <- obj[[namn]]
    if (is.null(x)) next
    typ <- if (text_fields[[i]]) "character" else if (namn == "test") "logical" else
      if (integer_fields[[i]]) "integer" else if (double_fields[[i]]) "double" else NULL
    if (is.null(typ)) next
    ok <- length(x) == 1L && switch(typ,
      character = is.character(x), logical = is.logical(x),
      integer = is.numeric(x) && is.finite(x) && x == trunc(x) && abs(x) <= .Machine$integer.max,
      double = is.numeric(x) && is.finite(x)
    )
    if (!ok) stop("Fel typ eller v\u00e4rde i k\u00e4llf\u00e4ltet ", namn, ".", call. = FALSE)
  }
}

.valresultat_votes <- function(obj) {
  .valresultat_object(obj, "omrade")
  .valresultat_values(obj)
  rost <- obj$rostfordelning
  .valresultat_object(rost, "rostfordelning (resultatet inte tillg\u00e4ngligt)")
  giltiga <- rost$rosterPaverkaMandat
  .valresultat_object(giltiga, "rosterPaverkaMandat")
  .valresultat_values(giltiga)
  partier <- giltiga$partiRoster
  if (!is.null(partier)) {
    .valresultat_array(partier, "partiRoster", tom = TRUE)
    for (parti in partier) {
      .valresultat_object(parti, "partiRoster[]")
      .valresultat_values(parti)
      .valresultat_scalar(parti$partikod, "partikod")
    }
  }
  ovriga <- giltiga$rosterOvrigaPartier
  if (!is.null(ovriga)) {
    .valresultat_object(ovriga, "rosterOvrigaPartier")
    falt <- c("antalRoster", "andelRoster", "antalRosterForegaendeVal",
              "andelRosterForegaendeVal", "forandringAntalRoster", "forandringAndelRoster")
    if (!any(names(ovriga) %in% falt)) {
      stop("Tomt rosterOvrigaPartier-objekt utan r\u00f6stf\u00e4lt.", call. = FALSE)
    }
    .valresultat_values(ovriga)
  }
  ogiltiga <- rost$rosterEjPaverkaMandat
  if (!is.null(ogiltiga)) {
    .valresultat_object(ogiltiga, "rosterEjPaverkaMandat")
    .valresultat_values(ogiltiga)
    for (namn in c("rosterEjAnmaltDeltagande", "blankaRoster", "ovrigaOgiltiga")) {
      if (!is.null(ogiltiga[[namn]])) {
        .valresultat_object(ogiltiga[[namn]], namn)
        .valresultat_values(ogiltiga[[namn]])
      }
    }
  }
  !is.null(ovriga)
}

.parse_valresultat <- function(raw, kalla, val, niva, rakning, path) {
  schema <- .valresultat_schema()
  raw <- .normalisera_rakningsmetadata_2026(raw)
  .valresultat_object(raw, "rot")
  .valresultat_values(raw)
  .valresultat_scalar(raw$valtillfalle, "valtillfalle")
  if (!identical(raw$valtyp, val) ||
      !identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), rakning)) {
    stop("R\u00e5metadata st\u00e4mmer inte med vald valtyp/rakning.", call. = FALSE)
  }
  filkod <- sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", path)
  geo_names <- names(schema)[17:31]
  poster <- list()
  # En metadatapost per källområde; ingen geografisk aggregering.
  lagg_till <- function(obj, geo) {
    if (!.rostfordelning_tillganglig_2026(obj)) return(invisible(FALSE))
    finns <- .valresultat_votes(obj)
    geografi <- as.list(rep(NA_character_, length(geo_names)))
    names(geografi) <- geo_names
    geografi$geografiniva <- niva
    for (namn in names(geo)) geografi[[namn]] <- as_chr_na(geo[[namn]])
    poster[[length(poster) + 1L]] <<- list(obj = obj, geo = geografi, ovriga = finns)
    invisible(TRUE)
  }
  if (kalla == "D") {
    distrikt <- .valresultat_array(raw$valdistrikt, "valdistrikt")
    for (obj in distrikt) {
      if (!identical(obj$valomradeskod, filkod)) stop("Fel valomradeskod i distrikt.", call. = FALSE)
      lagg_till(obj, list(
        valdistriktsnamn = obj$namn, valdistriktstyp = obj$valdistriktstyp,
        valdistriktskod = obj$valdistriktskod, kommunkod = obj$kommunkod,
        lankod = obj$lankod, valomradeskod = obj$valomradeskod, kretskod = obj$kretskod,
        kommunvalkretskod = obj$kommunvalkretsKod, kommunvalkretsnamn = obj$kommunvalkretsNamn
      ))
    }
  } else if (kalla == "U") {
    kommuner <- .valresultat_array(raw$kommuner, "kommuner")
    for (i in seq_along(kommuner)) {
      kommun <- kommuner[[i]]
      .valresultat_object(kommun, "kommun")
      .valresultat_values(kommun)
      geo <- list(kommunkod = kommun$kommunkod, kommunnamn = kommun$namn,
                  lankod = kommun$lankod, valomradeskod = filkod)
      if (niva == "kommun") {
        lagg_till(kommun, geo)
        raw$kommuner[[i]]$kommunvalkretsar <- NULL
      } else {
        # Frånvaro/null betyder ingen redovisad indelning, inte en ny krets.
        kretsar <- kommun$kommunvalkretsar
        if (!is.null(kretsar)) .valresultat_array(kretsar, "kommunvalkretsar", tom = TRUE)
        for (krets in kretsar) {
          lagg_till(krets, c(geo, list(kommunvalkretskod = krets$kod, kommunvalkretsnamn = krets$namn)))
        }
        raw$kommuner[[i]]["rostfordelning"] <- list(NULL)
      }
    }
  } else if (kalla == "M") {
    omrade <- raw$valomrade
    .valresultat_object(omrade, "valomrade")
    .valresultat_values(omrade)
    if (!identical(omrade$kod, filkod)) stop("Fel valomradeskod i mandatfil.", call. = FALSE)
    geo <- list(valomradeskod = omrade$kod, valomradesnamn = omrade$namn)
    if (val == "KF") {
      if (!grepl("^[0-9]{4}$", filkod)) stop("Ogiltig kommunkod.", call. = FALSE)
      geo <- c(geo, list(kommunkod = omrade$kod, kommunnamn = omrade$namn, lankod = substr(filkod, 1, 2)))
    }
    if (niva %in% c("riket", "region", "kommun")) {
      lagg_till(omrade, geo)
      raw$valomrade$valkretsLista <- NULL
    } else {
      kretsar <- omrade$valkretsLista
      if (!is.null(kretsar)) .valresultat_array(kretsar, "valkretsLista", tom = TRUE)
      for (krets in kretsar) {
        kretsgeo <- c(geo, list(valkretskod = krets$kod, valkretsnamn = krets$namnValkrets))
        if (val == "KF") kretsgeo <- c(kretsgeo, list(kommunvalkretskod = krets$kod, kommunvalkretsnamn = krets$namnValkrets))
        lagg_till(krets, kretsgeo)
      }
      raw$valomrade["rostfordelning"] <- list(NULL)
    }
  } else {
    .valresultat_object(raw$helaLandet, "helaLandet")
    if (niva == "riket") {
      lagg_till(raw$helaLandet, list())
      # Behåll namnet: annars kan befintliga parsers delmatcha $lan mot $lankod.
      raw$helaLandet$lan <- list()
    } else {
      lan <- .valresultat_array(raw$helaLandet$lan, "lan")
      for (i in seq_along(lan)) {
        lagg_till(lan[[i]], list(lankod = lan[[i]]$lankod, lannamn = lan[[i]]$namn))
        raw$helaLandet$lan[[i]]$kommuner <- NULL
      }
      raw$helaLandet["rostfordelning"] <- list(NULL)
    }
  }
  if (!length(poster)) return(schema)
  meta <- purrr::map(poster, function(x) tibble::as_tibble(x$geo)) |> purrr::list_rbind()
  nyckel <- .valresultat_geo_key(niva)
  krav <- setdiff(nyckel, "valdistriktstyp")
  if (any(vapply(meta[krav], function(x) any(is.na(x) | !nzchar(x)), logical(1)))) {
    stop("Saknad omr\u00e5desidentitet.", call. = FALSE)
  }
  # Riket har en enda områdespost, annars matchas explicit områdesidentitet.
  id <- function(x) {
    if (!length(nyckel)) return(rep("riket", nrow(x)))
    do.call(paste, c(unname(x[nyckel]), sep = "\r"))
  }
  if (anyDuplicated(id(meta))) stop("Duplicerad omr\u00e5desidentitet i k\u00e4llan.", call. = FALSE)
  data <- switch(kalla,
    D = parse_rostfordelning_2026(raw), U = parse_underordnad_summering_2026(raw),
    M = parse_rostfordelning_mandat_2026(raw),
    O = if (val == "RF") parse_overordnad_summering_rf_2026(raw) else parse_overordnad_summering_kf_2026(raw)
  )
  if (!nrow(data)) return(schema)
  if (kalla == "O" && niva == "lan" && val == "RF") data$geografiniva[data$geografiniva == "region"] <- "lan"
  data <- data[data$geografiniva == niva, , drop = FALSE]
  if (kalla == "M" && val == "KF") {
    data$kommunkod <- data$valomradeskod
    data$kommunvalkretskod <- data$valkretskod
  }
  index <- match(id(data), id(meta))
  if (anyNA(index)) stop("Parserns omr\u00e5den matchar inte k\u00e4llan.", call. = FALSE)
  finns <- vapply(poster, function(x) x$ovriga, logical(1))
  behall <- !data$ovriga_partier | finns[index]
  data <- data[behall, , drop = FALSE]
  index <- index[behall]
  for (namn in geo_names) data[[namn]] <- meta[[namn]][index]
  if (kalla == "M") {
    data$antal_valdistrikt_raknade_omrade <- data$antal_valdistrikt_raknade
    data$antal_valdistrikt_som_ska_raknas_omrade <- data$antal_valdistrikt_som_ska_raknas
    data$antal_valdistrikt_raknade <- rep(as_int_na(raw$valomrade$antalValdistriktRaknade), nrow(data))
    data$antal_valdistrikt_som_ska_raknas <- rep(as_int_na(raw$valomrade$antalValdistriktSomSkaRaknas), nrow(data))
  }
  if (kalla != "M") data$over_sparr <- rep(NA, nrow(data))
  # Explicit kontrakt: saknade kolumner fylls, inga parserspecifika extrafält.
  for (namn in names(schema)) {
    prototyp <- schema[[namn]]
    if (!namn %in% names(data)) data[[namn]] <- rep(prototyp[NA_integer_], nrow(data))
    x <- data[[namn]]
    data[[namn]] <- switch(typeof(prototyp),
      character = as.character(x), integer = as.integer(x),
      double = as.double(x), logical = as.logical(x)
    )
  }
  data <- data[names(schema)]
  .valresultat_check_key(data, niva)
  data
}
