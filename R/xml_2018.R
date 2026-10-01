# 2018 års XML är ett separat råformat. Funktionerna nedan översätter dess
# officiella noder till samma interna resultat- och mandatscheman som senare år.
.xml2018_attr <- function(node, namn) {
  if (inherits(node, "xml_missing")) return(NA_character_)
  x <- xml2::xml_attr(node, namn)
  if (is.na(x) || !nzchar(x)) NA_character_ else x
}

.xml2018_int <- function(node, namn) {
  x <- .xml2018_attr(node, namn)
  if (is.na(x)) return(NA_integer_)
  if (!grepl("^[+-]?[0-9]+$", x)) stop("Ogiltigt XML-heltal: ", namn, ".", call. = FALSE)
  as.integer(x)
}

.xml2018_dbl <- function(node, namn) {
  x <- .xml2018_attr(node, namn)
  if (is.na(x)) return(NA_real_)
  out <- suppressWarnings(as.double(sub(",", ".", x, fixed = TRUE)))
  if (!is.finite(out)) stop("Ogiltigt XML-decimaltal: ", namn, ".", call. = FALSE)
  out
}

.xml2018_valdag <- function(node, namn) {
  x <- .xml2018_attr(xml2::xml_root(node), namn)
  if (is.na(x)) return(NA_character_)
  if (!grepl("^[0-9]{8}$", x)) stop("Ogiltigt XML-valdatum: ", namn, ".", call. = FALSE)
  paste0(substr(x, 1L, 4L), "-", substr(x, 5L, 6L), "-", substr(x, 7L, 8L))
}

.xml2018_barn <- function(node, namn) xml2::xml_find_all(node, paste0("./", namn))
.xml2018_forsta <- function(node, namn) xml2::xml_find_first(node, paste0("./", namn))

.xml2018_fil <- function(zip, member, val) {
  con <- unz(zip, member, open = "rb")
  on.exit(close(con), add = TRUE)
  doc <- xml2::read_xml(con, options = c("NONET", "NOBLANKS"))
  root <- xml2::xml_root(doc)
  valt <- c(RD = "Riksdagsval", RF = "Landstingsval", KF = "Kommunfullm\u00e4ktigval")[[val]]
  if (!identical(.xml2018_attr(root, "VALDAG"), "20180909") ||
      !identical(.xml2018_attr(root, "VALTYP"), valt) ||
      !identical(.xml2018_attr(root, "RAPPORTERING"),
                 "SLUTLIG R\u00d6STR\u00c4KNING RESULTAT") ||
      !identical(.xml2018_attr(root, "FILNAMN"), member)) {
    stop("XML-filens valtyp, valdag eller r\u00e4kning st\u00e4mmer inte med filnamnet.", call. = FALSE)
  }
  doc
}

.xml2018_members <- function(zip, val, niva, mandat = FALSE) {
  bokstav <- c(RD = "R", RF = "L", KF = "K")[[val]]
  kommunfiler <- niva %in% c("valdistrikt", "kommun", "kommunvalkrets") &&
    (!mandat || val == "KF")
  expected <- if (kommunfiler) {
    paste0("slutresultat_[0-9]{4}", bokstav, "[.]xml")
  } else {
    paste0("slutresultat_00", bokstav, "[.]xml")
  }
  filer <- utils::unzip(zip, list = TRUE)$Name
  hit <- sort(filer[grepl(paste0("^", expected, "$"), filer)])
  if (!length(hit) || (!kommunfiler && length(hit) != 1L)) {
    stop("Saknade eller dubbla 2018-XML-filer f\u00f6r ", val, "/", niva, ".", call. = FALSE)
  }
  # Gotland har kommunal men ingen separat landstingsvalfil (RF).
  forvantat <- if (val == "RF") 289L else 290L
  if (kommunfiler && (length(hit) != forvantat ||
                      anyDuplicated(substr(basename(hit), 14L, 17L)))) {
    stop("2018-arkivet saknar en komplett upps\u00e4ttning kommunfiler f\u00f6r ", val,
         ".", call. = FALSE)
  }
  hit
}

.xml2018_partiregister <- function(file) {
  if (grepl("^https?://", file)) {
    tmp <- tempfile(fileext = ".skv")
    on.exit(unlink(tmp), add = TRUE)
    .download_file(file, tmp)
    file <- tmp
  }
  x <- readr::read_delim(
    file, delim = ";", locale = readr::locale(encoding = "ISO-8859-1"),
    col_types = readr::cols(.default = readr::col_character()),
    na = "", show_col_types = FALSE, progress = FALSE
  ) |> janitor::clean_names()
  required <- c("valtyp", "valomradeskod", "partiforkortning", "partibeteckning", "partikod")
  if (!all(required %in% names(x))) stop("Ogiltigt partiregister f\u00f6r 2018.", call. = FALSE)
  x$valtyp <- dplyr::recode_values(x$valtyp, "R" ~ "RD", "L" ~ "RF", "K" ~ "KF")
  x$valomradeskod <- ifelse(x$valtyp == "KF",
                           sprintf("%04d", as.integer(x$valomradeskod)),
                           sprintf("%02d", as.integer(x$valomradeskod)))
  x$partikod <- sprintf("%04d", as.integer(x$partikod))
  .xml2018_reg_index(x)
}

.xml2018_reg_index <- function(x) {
  alias <- ifelse(is.na(x$partiforkortning) | !nzchar(x$partiforkortning),
                  x$partikod, x$partiforkortning)
  list(
    data = x,
    local = list2env(split(seq_len(nrow(x)),
                           paste(x$valtyp, x$valomradeskod, alias, sep = "|")),
                     parent = emptyenv()),
    global = list2env(split(seq_len(nrow(x)), paste(x$valtyp, alias, sep = "|")),
                      parent = emptyenv())
  )
}

.xml2018_reg_fran_listor <- function(zip, val, register) {
  members <- .xml2018_members(zip, val, "kommun")
  extra <- purrr::map(members, function(member) {
    doc <- .xml2018_fil(zip, member, val)
    area <- xml2::xml_find_first(doc, "./KOMMUN")
    grupper <- xml2::xml_find_all(area,
      "./KRETS_KOMMUN/GILTIGA|./KRETS_KOMMUN/\u00d6VRIGA_GILTIGA/GILTIGA")
    purrr::map(grupper, function(g) {
      listor <- xml2::xml_find_all(g, "./VALSEDEL|./PARTISEDEL")
      nummer <- xml2::xml_attr(listor, "LISTNUMMER")
      koder <- unique(substr(nummer[grepl("^[0-9]{4}-", nummer)], 1L, 4L))
      if (!length(koder)) return(NULL)
      if (length(koder) != 1L) stop("En 2018-lista har mots\u00e4gande partikoder.", call. = FALSE)
      alias <- .xml2018_attr(g, "PARTI")
      rootparty <- xml2::xml_find_all(doc, "./PARTI")
      hit <- rootparty[xml2::xml_attr(rootparty, "F\u00d6RKORTNING") == alias]
      tibble::tibble(
        valtyp = val, valomradeskod = .xml2018_attr(area, "KOD"),
        partiforkortning = alias,
        partibeteckning = if (length(hit) == 1L) .xml2018_attr(hit[[1]], "BETECKNING") else NA_character_,
        partikod = koder
      )
    }) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  if (nrow(extra)) {
    register <- .xml2018_reg_index(dplyr::bind_rows(register$data, unique(extra)))
  }
  register
}

.xml2018_parti <- function(rawkod, val, valomradeskod, register,
                            parti = NULL, omrade = NULL) {
  if (is.na(rawkod)) stop("Parti saknar kod i 2018-XML.", call. = FALSE)
  index <- get0(paste(val, valomradeskod, rawkod, sep = "|"),
                envir = register$local, inherits = FALSE)
  if (is.null(index)) {
    index <- get0(paste(val, rawkod, sep = "|"),
                  envir = register$global, inherits = FALSE)
  }
  kandidater <- register$data[index, , drop = FALSE]
  koder <- unique(kandidater$partikod)
  if ((length(koder) != 1L || is.na(koder)) && !is.null(parti)) {
    listor <- xml2::xml_find_all(parti, "./VALSEDEL|./PARTISEDEL")
    if (!length(listor) && !is.null(omrade)) {
      under <- xml2::xml_find_all(omrade, ".//GILTIGA")
      under <- under[xml2::xml_attr(under, "PARTI") == rawkod]
      listor <- xml2::xml_find_all(under, "./VALSEDEL|./PARTISEDEL",
                                   flatten = TRUE)
    }
    nummer <- xml2::xml_attr(listor, "LISTNUMMER")
    nummer <- nummer[grepl("^[0-9]{4}-[0-9]+$", nummer)]
    koder <- unique(substr(nummer, 1L, 4L))
  }
  if (length(koder) != 1L || is.na(koder)) {
    stop("Partikoden f\u00f6r `", rawkod, "` kan inte best\u00e4mmas entydigt i ",
         val, "/", valomradeskod, ".", call. = FALSE)
  }
  beteckningar <- unique(kandidater$partibeteckning)
  beteckning <- if (length(beteckningar) == 1L) beteckningar else NA_character_
  if (is.na(beteckning) && !is.null(parti)) {
    rotpartier <- xml2::xml_find_all(xml2::xml_root(parti), "./PARTI")
    hit <- rotpartier[xml2::xml_attr(rotpartier, "F\u00d6RKORTNING") == rawkod]
    if (length(hit) == 1L) beteckning <- .xml2018_attr(hit[[1]], "BETECKNING")
  }
  forkortning <- if (grepl("^[0-9]+$", rawkod)) NA_character_ else rawkod
  list(partikod = koder, partibeteckning = beteckning,
       partiforkortning = forkortning)
}

.xml2018_noder <- function(doc, niva, val) {
  xpath <- switch(niva,
    riket = "./NATION", lan = "./NATION/L\u00c4N", region = "./NATION/L\u00c4N",
    riksdagsvalkrets = "./NATION/L\u00c4N/KRETS_RIKSDAG",
    regionvalkrets = "./NATION/L\u00c4N/KRETS_LANDSTING",
    kommun = "./KOMMUN", kommunvalkrets = "./KOMMUN/KRETS_KOMMUN",
    valdistrikt = "./KOMMUN/KRETS_KOMMUN/VALDISTRIKT|./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT"
  )
  noder <- xml2::xml_find_all(doc, xpath)
  if (niva == "kommunvalkrets") {
    # Kod xx00 är endast den tekniska enda kretsen i ett odelat område.
    noder <- noder[!grepl("00$", xml2::xml_attr(noder, "KOD"))]
  }
  noder
}

.xml2018_geo <- function(node, val, niva, doc) {
  root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
  kommun <- if (niva %in% c("valdistrikt", "kommun", "kommunvalkrets")) root else
    xml2::xml_find_first(node, "ancestor-or-self::KOMMUN[1]")
  lan <- xml2::xml_find_first(node, "ancestor-or-self::L\u00c4N[1]")
  if (inherits(lan, "xml_missing") && !inherits(kommun, "xml_missing")) {
    lankod <- substr(.xml2018_attr(kommun, "KOD"), 1L, 2L)
  } else {
    lankod <- .xml2018_attr(lan, "KOD")
  }
  valomradeskod <- switch(val, RD = "00", RF = lankod,
                           KF = .xml2018_attr(kommun, "KOD"))
  valomradesnamn <- switch(val, RD = "Sverige",
                            RF = if (!inherits(lan, "xml_missing")) .xml2018_attr(lan, "NAMN") else
                              .valresultat_lannamn_2026(lankod),
                            KF = .xml2018_attr(kommun, "NAMN"))
  krets <- if (niva == "riksdagsvalkrets" || niva == "regionvalkrets") node else
    if (niva == "kommunvalkrets" || niva == "valdistrikt") {
      xml2::xml_find_first(node, "ancestor-or-self::KRETS_KOMMUN[1]")
    } else xml2::xml_find_first(node, "./__saknas__")
  distrikt <- niva == "valdistrikt"
  list(
    geografiniva = niva,
    valomradeskod = valomradeskod, valomradesnamn = valomradesnamn,
    lankod = lankod,
    lannamn = if (!inherits(lan, "xml_missing")) .xml2018_attr(lan, "NAMN") else
      .valresultat_lannamn_2026(lankod),
    kommunkod = .xml2018_attr(kommun, "KOD"),
    kommunnamn = .xml2018_attr(kommun, "NAMN"),
    valkretskod = if (niva %in% c("riksdagsvalkrets", "regionvalkrets"))
      .xml2018_attr(krets, "KOD") else NA_character_,
    valkretsnamn = if (niva %in% c("riksdagsvalkrets", "regionvalkrets"))
      .xml2018_attr(krets, "NAMN") else NA_character_,
    kommunvalkretskod = if (niva %in% c("kommunvalkrets", "valdistrikt") &&
                              !grepl("00$", .xml2018_attr(krets, "KOD")))
      .xml2018_attr(krets, "KOD") else NA_character_,
    kommunvalkretsnamn = if (niva %in% c("kommunvalkrets", "valdistrikt") &&
                               !grepl("00$", .xml2018_attr(krets, "KOD")))
      .xml2018_attr(krets, "NAMN") else NA_character_,
    valdistriktskod = if (distrikt) .xml2018_attr(node, "KOD") else NA_character_,
    valdistriktsnamn = if (distrikt) .xml2018_attr(node, "NAMN") else NA_character_,
    valdistriktstyp = if (distrikt) {
      if (xml2::xml_name(node) == "ONSDAGSDISTRIKT") "uppsamlingsdistrikt" else "valdistrikt"
    } else NA_character_
  )
}
