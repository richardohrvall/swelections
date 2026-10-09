# 2014 adapters read preserved sources without altering the snapshots. Shared
# XML normalisers remain responsible for the harmonised data types.
.sources_2014 <- function(source, data_dir, update = FALSE, archive = FALSE) {
  .check_source_update(source, update)
  if (source == "remote" || update || archive)
    stop("2014 requires preserved local sources; update/archive are not supported.",
         call. = FALSE)
  root <- val_data_dir(data_dir)
  if (is.null(root)) stop("2014 requires `data_dir`.", call. = FALSE)
  root <- file.path(root, "2014")
  final <- file.path(root, "valresultat", "slutresultat_20141001")
  if (!dir.exists(final)) stop("Missing preserved 2014 final XML directory: ",
                              final, call. = FALSE)
  list(root = root, year = 2014L, final = final,
       night = file.path(root, "valresultat", "valnatt"),
       registers = new.env(parent = emptyenv()))
}

.xml2014_members <- function(sources, val, niva, mandat = FALSE,
                             night = FALSE) {
  if (identical(sources$year, 2010L)) return(.xml2010_members(sources, val, niva, mandat, night))
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  municipal <- niva %in% c("valdistrikt", "kommun", "kommunvalkrets") &&
    (!mandat || val == "KF")
  prefix <- if (night) "valnatt" else "slutresultat"
  folder <- if (night) sources$night else sources$final
  pattern <- paste0("^", prefix, "_", if (municipal) "[0-9]{4}" else "00",
                    letter, "[.]xml$")
  files <- sort(list.files(folder, pattern, full.names = TRUE))
  expected <- if (municipal) if (val == "RF") 289L else 290L else 1L
  if (length(files) != expected)
    stop("Incomplete 2014 XML source for ", val, "/", niva, call. = FALSE)
  files
}

.xml2014_file <- function(file, val, night = FALSE) {
  if (!is.null(attr(file, "zip"))) return(.xml2010_file(file, val, night))
  doc <- xml2::read_xml(file, options = c("NONET", "NOBLANKS"))
  root <- xml2::xml_root(doc)
  if (!identical(.xml2018_attr(root, "VALDAG"), "20140914") ||
      !identical(.xml2018_attr(root, "VALTYP"),
        c(RD = "Riksdagsval", RF = "Landstingsval",
          KF = "Kommunfullm\u00e4ktigval")[[val]]) ||
      !identical(.xml2018_attr(root, "FILNAMN"), basename(file)) ||
      !.xml2018_attr(root, "RAPPORTERING") %in% if (night)
        "VALNATTSRAPPORTERING" else c("SLUTLIG R\u00d6STR\u00c4KNING RESULTAT",
          "SLUTLIG R\u00d6STR\u00c4KNING PRELIMIN\u00c4RA RESULTAT"))
    stop("Invalid 2014 XML metadata: ", file, call. = FALSE)
  placeholders <- xml2::xml_find_all(doc,
    ".//VALD[(not(@KANDNR) or @KANDNR='') and @NAMN='Kunde ej utses']")
  if (length(placeholders)) xml2::xml_set_attr(placeholders, "NAMN", "Kunde inte utses")
  doc
}

.xml2014_register <- function(doc, val, area = NULL) {
  parties <- xml2::xml_find_all(doc, "./PARTI")
  lists <- xml2::xml_find_all(doc, ".//GILTIGA/VALSEDEL|.//GILTIGA/PARTISEDEL")
  list_aliases <- xml2::xml_find_chr(lists, "string(../@PARTI)")
  list_codes <- substr(xml2::xml_attr(lists, "LISTNUMMER"), 1L, 4L)
  identifiers <- unique(tibble::tibble(alias = list_aliases, code = list_codes))
  rows <- lapply(parties, function(p) {
    alias <- .xml2018_attr(p, "F\u00d6RKORTNING")
    if (is.na(alias)) return(NULL)
    codes <- identifiers$code[which(identifiers$alias == alias)]
    codes <- codes[!is.na(codes) & grepl("^[0-9]{4}$", codes)]
    if (!length(codes) && grepl("^[0-9]{4}$", alias)) codes <- alias
    if (length(codes) != 1L) return(NULL)
    tibble::tibble(valtyp = val, valomradeskod = if (is.null(area)) "00" else area,
      partiforkortning = alias,
      partibeteckning = .xml2018_attr(p, "BETECKNING"), partikod = codes)
  })
  empty <- tibble::tibble(valtyp = character(), valomradeskod = character(),
    partiforkortning = character(), partibeteckning = character(), partikod = character())
  .xml2018_reg_index(dplyr::bind_rows(empty, purrr::list_rbind(rows)))
}

.xml2014_register_all <- function(sources, val) {
  if (identical(sources$year, 2010L)) return(.xml2010_register_all(sources, val))
  cached <- get0(val, envir = sources$registers, inherits = FALSE)
  if (!is.null(cached)) return(cached)
  files <- unlist(lapply(c("RD", "RF", "KF"), function(v)
    c(.xml2014_members(sources, v, "riket"), .xml2014_members(sources, v, "kommun"))))
  descriptions <- list()
  rows <- lapply(files, function(f) {
    v <- c(R = "RD", L = "RF", K = "KF")[[sub(".*([RLK])[.]xml$", "\\1", f)]]
    doc <- .xml2014_file(f, v)
    municipal <- .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD")
    area <- if (v == "RD" || is.na(municipal)) "00" else
      if (v == "RF") substr(municipal, 1L, 2L) else municipal
    parties <- xml2::xml_find_all(doc, "./PARTI")
    descriptions[[length(descriptions) + 1L]] <<- tibble::tibble(valtyp = v,
      valomradeskod = area, partiforkortning = xml2::xml_attr(parties, "F\u00d6RKORTNING"),
      partibeteckning = xml2::xml_attr(parties, "BETECKNING"))
    .xml2014_register(doc, v, area)$data
  }) |> purrr::list_rbind() |> unique()
  catalogue <- unique(rows[c("partibeteckning", "partikod")])
  previous_file <- file.path(sources$root, "kandidater", "official-ballot-metadata", "party-identifiers-2010-complete.csv")
  if (file.exists(previous_file)) {
    previous <- readr::read_csv(previous_file,
      col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    prior_catalogue <- previous[!previous$partibeteckning %in% catalogue$partibeteckning,
      c("partibeteckning", "partikod")]
    catalogue <- unique(dplyr::bind_rows(catalogue, prior_catalogue))
  }
  catalogue <- catalogue[!duplicated(catalogue$partibeteckning) &
    !duplicated(catalogue$partibeteckning, fromLast = TRUE), ]
  extra <- purrr::list_rbind(descriptions) |> unique()
  extra$partikod <- catalogue$partikod[match(extra$partibeteckning, catalogue$partibeteckning)]
  if (file.exists(previous_file)) {
    columns <- c("valtyp", "partiforkortning", "partibeteckning")
    encode <- function(x) do.call(paste, c(x[columns], sep = "|"))
    prior <- unique(previous[c(columns, "partikod")])
    prior_key <- encode(prior)
    unique_key <- !duplicated(prior_key) & !duplicated(prior_key, fromLast = TRUE)
    prior <- prior[unique_key, ]
    current_names <- unique(rows$partibeteckning)
    missing <- which(is.na(extra$partikod) & !extra$partibeteckning %in% current_names)
    extra$partikod[missing] <- prior$partikod[match(encode(extra[missing, ]), encode(prior))]
  }
  extra <- extra[!is.na(extra$partikod) & !is.na(extra$partiforkortning), ]
  rows <- unique(dplyr::bind_rows(rows, extra))
  for (v in c("RD", "RF", "KF")) assign(v,
    .xml2018_reg_index(rows[rows$valtyp == v, ]), envir = sources$registers)
  get(val, envir = sources$registers, inherits = FALSE)
}

.metadata_2014 <- function(out, ar = 2014L) {
  out$valtillfalle <- rep(paste0("Val_", ar), nrow(out))
  out$valar <- rep(as.integer(ar), nrow(out))
  if ("valdatum" %in% names(out)) out$valdatum <- rep(if (ar == 2010L) "2010-09-19" else "2014-09-14", nrow(out))
  out
}

# Repeated KANDNR nodes are additive official records, not duplicate people.
# Consolidation is performed on an in-memory XML document, never on raw files.
.xml2014_consolidate_person <- function(doc) {
  records <- xml2::xml_find_all(doc, ".//PERSONVAL")
  record_ids <- xml2::xml_attr(records, "KANDNR")
  record_counts <- xml2::xml_attr(records, "PERSONKRYSS")
  if (anyNA(record_ids) || any(!nzchar(record_ids)) ||
      anyNA(record_counts) || any(!grepl("^[0-9]+$", record_counts)) ||
      anyNA(as.integer(record_counts)))
    stop("Invalid 2014 candidate preference-vote record.", call. = FALSE)
  repeated <- xml2::xml_find_all(doc,
    ".//PERSONVAL[@KANDNR = preceding-sibling::PERSONVAL/@KANDNR]")
  parents <- xml2::xml_parent(repeated)
  for (p in parents) {
    nodes <- xml2::xml_find_all(p, "./PERSONVAL")
    ids <- xml2::xml_attr(nodes, "KANDNR")
    counts <- as.integer(xml2::xml_attr(nodes, "PERSONKRYSS"))
    if (anyNA(ids) || any(!nzchar(ids)) || anyNA(counts) || any(counts < 0L))
      stop("Invalid 2014 candidate preference-vote record.", call. = FALSE)
    for (id in unique(ids[duplicated(ids)])) {
      hit <- which(ids == id)
      xml2::xml_set_attr(nodes[[hit[[1]]]], "PERSONKRYSS",
                         as.character(sum(as.double(counts[hit]))))
      qualified <- xml2::xml_attr(nodes[hit], "\u00d6VER_SP\u00c4RR")
      if (any(qualified == "J", na.rm = TRUE))
        xml2::xml_set_attr(nodes[[hit[[1]]]], "\u00d6VER_SP\u00c4RR", "J")
      xml2::xml_remove(nodes[hit[-1]])
    }
  }
  doc
}

.read_candidacies_2014 <- function(sources, val) {
  if (identical(sources$year, 2010L)) return(.read_candidacies_2010(sources, val))
  out <- lapply(val, function(v) {
    doc <- .xml2014_file(.xml2014_members(sources, v, "riket")[[1]], v)
    register <- .xml2014_register(doc, v)$data
    if (v == "RD") {
      metadata <- file.path(sources$root, "kandidater", "official-ballot-metadata", "00R.xml")
      if (!file.exists(metadata)) stop("Missing official 2014 RD ballot metadata.", call. = FALSE)
      ballot <- xml2::read_xml(metadata, options = "NONET")
      parties <- xml2::xml_find_all(ballot, ".//PARTI")
      extra <- tibble::tibble(valtyp = v, valomradeskod = "00",
        partiforkortning = NA_character_,
        partibeteckning = xml2::xml_attr(parties, "BETECKNING"),
        partikod = sprintf("%04d", as.integer(xml2::xml_attr(parties, "KOD"))))
      extra <- unique(extra[!is.na(extra$partikod), ])
      extra <- extra[!extra$partikod %in% register$partikod, ]
      register <- dplyr::bind_rows(register, extra)
    }
    file <- file.path(sources$root, "kandidater",
      paste0("alkandur_", c(RD = "R", RF = "L", KF = "K")[[v]], ".skv"))
    x <- readr::read_delim(file, delim = ";", col_names = FALSE,
      col_types = readr::cols(.default = readr::col_character()),
      locale = readr::locale(encoding = "ISO-8859-1"),
      show_col_types = FALSE, progress = FALSE)
    offset <- c(RD = 0L, RF = 2L, KF = 4L)[[v]]
    if (ncol(x) != 12L + offset) stop("Invalid 2014 ballot schema.", call. = FALSE)
    # Official result list identifiers contain the party code. Match the
    # numeric ballot identifier, not a party designation shared by local parties.
    files <- .xml2014_members(sources, v, "kommun")
    mapping <- lapply(files, function(f) {
      z <- .xml2014_file(f, v)
      ids <- xml2::xml_attr(xml2::xml_find_all(z, ".//VALSEDEL|.//PARTISEDEL"), "LISTNUMMER")
      tibble::tibble(listnummer = sub("^[0-9]{4}-", "", ids),
        partikod = substr(ids, 1L, 4L))
    }) |> purrr::list_rbind() |> unique()
    if (v == "RD") {
      lists <- xml2::xml_find_all(ballot, ".//VALSEDEL")
      extra <- tibble::tibble(listnummer = xml2::xml_attr(lists, "LISTNUMMER"),
        partikod = vapply(lists, function(l) sprintf("%04d", as.integer(
          .xml2018_attr(xml2::xml_find_first(l, "ancestor::PARTI[1]"), "KOD"))), ""))
      mapping <- unique(dplyr::bind_rows(mapping, extra))
    }
    mapping <- mapping[mapping$listnummer != "90000", ]
    if (anyDuplicated(mapping$listnummer))
      stop("Ambiguous official 2014 list/party identifier.", call. = FALSE)
    pk <- mapping$partikod[match(sprintf("%05d", as.integer(x[[offset + 6L]])), mapping$listnummer)]
    if (anyNA(pk)) {
      metadata <- file.path(sources$root, "kandidater", "official-ballot-metadata", "00R.xml")
      ballot_parties <- xml2::xml_find_all(xml2::read_xml(metadata, options = "NONET"), ".//PARTI")
      party <- unique(dplyr::bind_rows(register[c("partibeteckning", "partikod")],
        tibble::tibble(partibeteckning = xml2::xml_attr(ballot_parties, "BETECKNING"),
          partikod = sprintf("%04d", as.integer(xml2::xml_attr(ballot_parties, "KOD"))))))
      # Only an unambiguous official party designation/code is usable when
      # the ballot itself has no observed result list.
      party <- party[!duplicated(party$partibeteckning) &
                       !duplicated(party$partibeteckning, fromLast = TRUE), ]
      missing <- which(is.na(pk))
      pk[missing] <- party$partikod[match(x[[offset + 4L]][missing], party$partibeteckning)]
    }
    if (anyNA(pk)) stop("2014 ballot party not identified in official XML: ",
      paste(unique(paste(x[[offset + 4L]][is.na(pk)], x[[offset + 6L]][is.na(pk)],
        x[[2]][is.na(pk)])), collapse = "; "), call. = FALSE)
    raw <- tibble::tibble(valtyp = v,
      valomradeskod = if (v == "RD") "00" else if (v == "RF") x[[2]] else
        paste0(x[[2]], x[[4]]),
      valomradesnamn = if (v == "RD") "Sverige" else if (v == "RF") x[[3]] else x[[5]],
      valkretskod = x[[offset + 2L]], valkretsnamn = x[[offset + 3L]],
      partibeteckning = x[[offset + 4L]],
      partiforkortning = register$partiforkortning[match(pk, register$partikod)],
      partikod = pk, valsedelsstatus = ifelse(x[[offset + 5L]] == "Skickad", "S", "B"),
      listnummer = sprintf("%05d", as.integer(x[[offset + 6L]])), ordning = x[[offset + 7L]],
      kandidatnummer = x[[offset + 8L]], namn = NA_character_,
      alder_pa_valdagen = x[[offset + 10L]], kon = x[[offset + 11L]],
      valsedelsuppgift = x[[offset + 12L]], giltig = NA_character_,
      anmaldakandidater = NA_character_, samtycke = NA_character_,
      forklaring = NA_character_, folkbokforingskommun = NA_character_,
      valkretsbeteckning_pa_valsedeln = NA_character_,
      antal_valsedlar_for_den_specifika_listan = NA_character_)
    parse_kandidaturer_2026(raw, ar = 2014L)
  }) |> purrr::list_rbind()
  .kort_kommunnamn_2026(out)
}

.valresultat_final_2014 <- function(sources, val, niva, progress) {
  .valresultat_niva_2018(val, niva)
  files <- .xml2014_members(sources, val, niva)
  register <- .xml2014_register_all(sources, val)
  out <- purrr::map(files, function(file) {
    doc <- .xml2014_file(file, val)
    reg <- .xml2014_register(doc, val)
    reg <- .xml2018_reg_index(unique(dplyr::bind_rows(register$data, reg$data)))
    root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
    purrr::map(.xml2018_noder(doc, niva, val), function(node)
      .xml2018_partirader(node, .xml2018_geo(node, val, niva, doc), root, val, reg)) |>
      purrr::list_rbind()
  }, .progress = progress) |> purrr::list_rbind()
  out <- .metadata_2014(out, .historical_year(sources))
  out <- .xml2014_known_vote_totals(out)
  if (niva == "valdistrikt") out$raknat <- rep(TRUE, nrow(out))
  out <- .komplettera_kommunnamn_2026(out, out$kommunnamn)
  out <- .valresultat_public_andelar_2026(out)
  out <- out[.valresultat_public_columns_2026(niva)]
  .valresultat_check_key(out, niva)
  out
}

.xml2014_known_vote_totals <- function(x) {
  for (suffix in c("", "_fg")) {
    total <- paste0("totalt_antal_roster", suffix)
    valid <- paste0("giltiga_roster", suffix)
    invalid <- paste0("ogiltiga_roster", suffix)
    # In 2014 the complete invalid-vote partition is BLANK + OG. Collection
    # nodes contain those components even when VALDELTAGANDE is absent.
    invalid_components <- x[[paste0("blanka_roster", suffix)]] +
      x[[paste0("ovriga_ogiltiga", suffix)]]
    known_invalid <- !is.na(invalid_components)
    if (any(known_invalid & !is.na(x[[invalid]]) &
        x[[invalid]] != invalid_components, na.rm = TRUE))
      stop("2014 invalid votes disagree with blank/other components.", call. = FALSE)
    fill_invalid <- known_invalid & is.na(x[[invalid]])
    x[[invalid]][fill_invalid] <- invalid_components[fill_invalid]
    expected <- x[[valid]] + x[[invalid]]
    known <- !is.na(expected)
    if (any(known & !is.na(x[[total]]) & x[[total]] != expected, na.rm = TRUE))
      stop("2014 total votes disagree with valid/invalid vote components.", call. = FALSE)
    missing <- known & is.na(x[[total]])
    x[[total]][missing] <- expected[missing]
  }
  x
}
