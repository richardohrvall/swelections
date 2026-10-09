# ZIP-backed 2010 read adapter. Sources are never extracted or rewritten.
.sources_2010 <- function(source, data_dir, update = FALSE, archive = FALSE) {
  .check_source_update(source, update)
  if (source == "remote" || update || archive)
    stop("2010 requires preserved local sources; update/archive are not supported.", call. = FALSE)
  root <- val_data_dir(data_dir)
  if (is.null(root)) stop("2010 requires `data_dir`.", call. = FALSE)
  root <- file.path(root, "2010")
  final <- file.path(root, "valresultat", "slutresultat.zip")
  if (!file.exists(final)) stop("Missing preserved 2010 final XML ZIP: ", final, call. = FALSE)
  list(root = root, year = 2010L, final = final,
    night = file.path(root, "valresultat", "valnatt.zip"),
    registers = new.env(parent = emptyenv()))
}

.xml2010_members <- function(sources, val, niva, mandat = FALSE, night = FALSE) {
  zip <- if (night) sources$night else sources$final
  if (!file.exists(zip)) stop("Missing preserved 2010 XML ZIP: ", zip, call. = FALSE)
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  municipal <- niva %in% c("valdistrikt", "kommun", "kommunvalkrets") && (!mandat || val == "KF")
  pattern <- paste0("^", if (night) "valnatt" else "slutresultat", "_",
    if (municipal) "[0-9]{4}" else "00", letter, "[.]xml$")
  files <- sort(utils::unzip(zip, list = TRUE)$Name)
  files <- files[grepl(pattern, files)]
  expected <- if (municipal) if (val == "RF") 289L else 290L else 1L
  if (length(files) != expected) stop("Incomplete 2010 XML source for ", val, "/", niva, call. = FALSE)
  # map() extracts individual elements, so the ZIP must be attached to each item.
  lapply(files, function(f) structure(f, zip = zip))
}

.xml2010_file <- function(file, val, night = FALSE) {
  con <- unz(attr(file, "zip"), as.character(file), open = "rb")
  on.exit(close(con), add = TRUE)
  doc <- xml2::read_xml(con, options = c("NONET", "NOBLANKS"))
  root <- xml2::xml_root(doc)
  if (!identical(.xml2018_attr(root, "VALDAG"), "20100919") ||
      !identical(.xml2018_attr(root, "VALTYP"), c(RD = "Riksdagsval", RF = "Landstingsval",
        KF = "Kommunfullm\u00e4ktigval")[[val]]) ||
      !identical(.xml2018_attr(root, "FILNAMN"), as.character(file)) ||
      !identical(.xml2018_attr(root, "RAPPORTERING"), if (night)
        "VALNATTSRAPPORTERING" else "SLUTLIG R\u00d6STR\u00c4KNING RESULTAT"))
    stop("Invalid 2010 XML metadata: ", file, call. = FALSE)
  if (!night) doc <- .xml2010_candidate_identity(doc)$doc
  placeholders <- xml2::xml_find_all(doc,
    ".//VALD[(not(@KANDNR) or @KANDNR='') and @NAMN='Kunde ej utses']")
  if (length(placeholders)) xml2::xml_set_attr(placeholders, "NAMN", "Kunde inte utses")
  doc
}

.xml2010_register_all <- function(sources, val) {
  cached <- get0(val, envir = sources$registers, inherits = FALSE)
  if (!is.null(cached)) return(cached)
  descriptions <- mappings <- list()
  rows <- lapply(c("RD", "RF", "KF"), function(v) {
    files <- c(.xml2010_members(sources, v, "riket"), .xml2010_members(sources, v, "kommun"))
    purrr::map(files, function(f) {
      doc <- .xml2010_file(f, v)
      municipal <- .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD")
      area <- if (v == "RD" || is.na(municipal)) "00" else if (v == "RF") substr(municipal, 1L, 2L) else municipal
      parties <- xml2::xml_find_all(doc, "./PARTI")
      descriptions[[length(descriptions) + 1L]] <<- tibble::tibble(valtyp = v, valomradeskod = area,
        partiforkortning = xml2::xml_attr(parties, "F\u00d6RKORTNING"),
        partibeteckning = xml2::xml_attr(parties, "BETECKNING"))
      ids <- xml2::xml_attr(xml2::xml_find_all(doc, ".//VALSEDEL|.//PARTISEDEL"), "LISTNUMMER")
      mappings[[length(mappings) + 1L]] <<- tibble::tibble(valtyp = v,
        listnummer = sub("^[0-9]{4}-", "", ids), partikod = substr(ids, 1L, 4L))
      .xml2014_register(doc, v, area)$data
    }) |> purrr::list_rbind()
  }) |> purrr::list_rbind() |> unique()
  catalogue <- unique(rows[c("partibeteckning", "partikod")])
  catalogue <- catalogue[!duplicated(catalogue$partibeteckning) &
    !duplicated(catalogue$partibeteckning, fromLast = TRUE), ]
  extra <- purrr::list_rbind(descriptions) |> unique()
  # Identical designations can belong to distinct municipal parties. Resolve
  # source abbreviation and geographic scope before any designation fallback.
  encode_local <- function(x) paste(x$valtyp, x$valomradeskod, x$partiforkortning, sep = "|")
  local <- unique(rows[c("valtyp", "valomradeskod", "partiforkortning", "partikod")])
  local_keys <- encode_local(local)
  local <- local[!duplicated(local_keys) & !duplicated(local_keys, fromLast = TRUE), ]
  extra$partikod <- local$partikod[match(encode_local(extra), encode_local(local))]
  prior_file <- file.path(sources$root, "kandidater", "official-party-identifiers", "previous-election-2006.csv")
  if (file.exists(prior_file)) {
    prior <- readr::read_csv(prior_file, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    key <- c("valtyp", "valomradeskod", "partibeteckning")
    encode <- function(x) do.call(paste, c(x[key], sep = "|"))
    prior_keys <- encode(prior)
    if (anyDuplicated(prior_keys)) stop("Ambiguous official previous-election party metadata.", call. = FALSE)
    missing <- which(is.na(extra$partikod))
    extra$partikod[missing] <- prior$partikod[match(encode(extra[missing, ]), prior_keys)]
  }
  # National aliases inherit only an unambiguous code established in a
  # municipality. ALT/ALTER and FKL/FRK must retain their distinct party IDs.
  scoped <- unique(extra[extra$valomradeskod != "00" & !is.na(extra$partikod),
    c("valtyp", "partiforkortning", "partikod")])
  alias_key <- function(x) paste(x$valtyp, x$partiforkortning, sep = "|")
  keys <- alias_key(scoped)
  scoped <- scoped[!duplicated(keys) & !duplicated(keys, fromLast = TRUE), ]
  missing <- which(is.na(extra$partikod))
  extra$partikod[missing] <- scoped$partikod[match(alias_key(extra[missing, ]), alias_key(scoped))]
  missing <- which(is.na(extra$partikod))
  extra$partikod[missing] <- catalogue$partikod[match(extra$partibeteckning[missing], catalogue$partibeteckning)]
  rows <- unique(dplyr::bind_rows(rows, extra[!is.na(extra$partikod), ]))
  assign("list_mapping", unique(purrr::list_rbind(mappings)), envir = sources$registers)
  for (v in c("RD", "RF", "KF")) assign(v,
    .xml2018_reg_index(rows[rows$valtyp == v, ]), envir = sources$registers)
  get(val, envir = sources$registers, inherits = FALSE)
}

.read_candidacies_2010 <- function(sources, val) {
  purrr::map(val, function(v) {
    register <- .xml2010_register_all(sources, v)$data
    mapping <- get("list_mapping", envir = sources$registers)
    mapping <- unique(mapping[mapping$valtyp == v & mapping$listnummer != "90000",
      c("listnummer", "partikod")])
    if (anyDuplicated(mapping$listnummer)) stop("Ambiguous official 2010 list/party identifier.", call. = FALSE)
    file <- file.path(sources$root, "kandidater", paste0("alkandur_", c(RD = "R", RF = "L", KF = "K")[[v]], ".skv"))
    x <- readr::read_delim(file, delim = ";", col_names = FALSE,
      col_types = readr::cols(.default = readr::col_character()),
      locale = readr::locale(encoding = "ISO-8859-1"), show_col_types = FALSE, progress = FALSE)
    offset <- c(RD = 0L, RF = 2L, KF = 4L)[[v]]
    if (ncol(x) != 12L + offset) stop("Invalid 2010 ballot schema.", call. = FALSE)
    lists <- sprintf("%05d", as.integer(x[[offset + 6L]]))
    pk <- mapping$partikod[match(lists, mapping$listnummer)]
    # A list not observed in the result is identified by the official party
    # register, never by a candidate name.
    file <- file.path(sources$root, "kandidater", "partier_som_anmalt_kandidater.txt")
    notified <- readr::read_delim(file, delim = "\t", col_types = readr::cols(.default = readr::col_character()),
      locale = readr::locale(encoding = "UTF-8"), show_col_types = FALSE, progress = FALSE)
    parties <- unique(dplyr::bind_rows(register[c("partibeteckning", "partikod")],
      tibble::tibble(partibeteckning = notified[[4]], partikod = sprintf("%04d", as.integer(notified[[3]])))))
    parties <- parties[!duplicated(parties$partibeteckning) &
      !duplicated(parties$partibeteckning, fromLast = TRUE), ]
    missing <- which(is.na(pk))
    pk[missing] <- parties$partikod[match(x[[offset + 4L]][missing], parties$partibeteckning)]
    missing <- which(is.na(pk))
    if (length(missing)) {
      area <- if (v == "RD") rep("00", nrow(x)) else if (v == "RF") x[[2]] else paste0(x[[2]], x[[4]])
      scoped <- unique(register[c("valomradeskod", "partibeteckning", "partikod")])
      key <- paste(scoped$valomradeskod, scoped$partibeteckning, sep = "|")
      scoped <- scoped[!duplicated(key) & !duplicated(key, fromLast = TRUE), ]
      pk[missing] <- scoped$partikod[match(paste(area[missing], x[[offset + 4L]][missing], sep = "|"),
        paste(scoped$valomradeskod, scoped$partibeteckning, sep = "|"))]
    }
    missing <- which(is.na(pk))
    if (length(missing)) {
      scoped <- notified[notified[[1]] == c(RD = "R", RF = "L", KF = "K")[[v]], ]
      key <- paste(scoped[[2]], scoped[[4]], sep = "|")
      scoped <- scoped[!duplicated(key) & !duplicated(key, fromLast = TRUE), ]
      area_names <- if (v == "KF") x[[5]] else x[[3]]
      pk[missing] <- sprintf("%04d", as.integer(scoped[[3]][match(
        paste(area_names[missing], x[[offset + 4L]][missing], sep = "|"),
        paste(scoped[[2]], scoped[[4]], sep = "|"))]))
      pk[pk == "  NA"] <- NA_character_
    }
    if (anyNA(pk)) stop("2010 ballot party not identified: ",
      paste(unique(paste(x[[offset + 4L]][is.na(pk)], x[[2]][is.na(pk)], x[[4]][is.na(pk)], lists[is.na(pk)])), collapse = "; "), call. = FALSE)
    raw <- tibble::tibble(valtyp = v,
      valomradeskod = if (v == "RD") "00" else if (v == "RF") x[[2]] else paste0(x[[2]], x[[4]]),
      valomradesnamn = if (v == "RD") "Sverige" else if (v == "RF") x[[3]] else x[[5]],
      valkretskod = x[[offset + 2L]], valkretsnamn = x[[offset + 3L]],
      partibeteckning = x[[offset + 4L]], partiforkortning = register$partiforkortning[match(pk, register$partikod)],
      partikod = pk, valsedelsstatus = ifelse(x[[offset + 5L]] == "Skickad", "S", "B"),
      listnummer = lists, ordning = x[[offset + 7L]], kandidatnummer = x[[offset + 8L]],
      namn = NA_character_, alder_pa_valdagen = x[[offset + 10L]], kon = x[[offset + 11L]],
      valsedelsuppgift = x[[offset + 12L]], giltig = NA_character_, anmaldakandidater = NA_character_,
      samtycke = NA_character_, forklaring = NA_character_, folkbokforingskommun = NA_character_,
      valkretsbeteckning_pa_valsedeln = NA_character_, antal_valsedlar_for_den_specifika_listan = NA_character_)
    # Approved Bjorn linkage: RD ballot ID differs from the RD election XML.
    bjorn <- raw$valtyp == "RD" & raw$kandidatnummer == "497359" &
      raw$partikod == "0003" & raw$valkretskod == "03" & raw$listnummer == "03600" & raw$ordning == "22"
    raw$kandidatnummer[bjorn] <- "442089"
    parse_kandidaturer_2026(raw, ar = 2010L)
  }) |> purrr::list_rbind() |> .kort_kommunnamn_2026()
}

.sources_historical <- function(ar, source, data_dir, update, archive) {
  if (ar == 2010L) .sources_2010(source, data_dir, update, archive) else
    .sources_2014(source, data_dir, update, archive)
}

.historical_year <- function(sources) {
  if (is.null(sources$year)) 2014L else sources$year
}
