# Preserved 2006 sources are immutable; adaptation only changes in-memory XML.
.sources_2006 <- function(source, data_dir, update = FALSE, archive = FALSE) {
  .auto_requires_local(source, "RKL 2006 raw data")
  if (!source %in% c("auto", "local") || update || archive)
    stop("2006 requires preserved local sources; remote/update/archive are not supported.", call. = FALSE)
  root <- val_data_dir(data_dir)
  if (is.null(root)) stop("2006 requires a configured raw-data directory.", call. = FALSE)
  root <- file.path(root, "2006")
  snapshot <- file.path(root, "archived-assessment-20261011")
  manifest <- file.path(snapshot, "source_objects.csv")
  if (!file.exists(manifest) || !identical(unname(tools::md5sum(manifest)),
      "dcc6c527e33335c37c6381280a89699b"))
    stop("Missing or changed 2006 source inventory: ", manifest, call. = FALSE)
  municipal <- file.path(root, "official-final-municipal-preservation-20261011")
  municipal_manifest <- file.path(municipal, "source-manifest.json")
  entries <- if (file.exists(municipal_manifest)) jsonlite::fromJSON(municipal_manifest)$sources else NULL
  list(root = root, snapshot = snapshot, year = 2006L, municipal = municipal, municipal_sources = entries,
    sources = utils::read.csv(manifest, stringsAsFactors = FALSE),
    cache = new.env(parent = emptyenv()))
}

.xml2006_source <- function(sources, file) {
  if (startsWith(file, "official-final/")) {
    name <- sub("^official-final/", "", file)
    entry <- sources$municipal_sources[sources$municipal_sources$file == name, ]
    path <- file.path(sources$municipal, name)
    if (nrow(entry) != 1L || !file.exists(path) || file.info(path)$size != entry$bytes ||
        !identical(unname(tools::md5sum(path)), entry$md5) ||
        !identical(.canonical_sha256(path), entry$sha256))
      stop("Missing or changed official 2006 municipality source: ", file, call. = FALSE)
    return(path)
  }
  index <- match(file, sources$sources$file)
  if (is.na(index)) stop("Unregistered 2006 source: ", file, call. = FALSE)
  path <- file.path(sources$snapshot, file)
  entry <- sources$sources[index, ]
  if (!file.exists(path) || file.info(path)$size != entry$bytes ||
      !identical(unname(tools::md5sum(path)), entry$md5) ||
      !identical(.canonical_sha256(path), entry$sha256))
    stop("Changed 2006 source: ", file, call. = FALSE)
  path
}

.xml2006_files <- function(sources, val, national = FALSE) {
  if (val != "KF" || national) return(paste0("objects/",
    switch(val, RD = "direct-archived-final-RD-XML.xml",
      RF = "direct-archived-final-RF-XML.xml",
      KF = "final-current-KF-national-control.xml")))
  entries <- sources$sources
  files <- entries$file[entries$source_type == "XML" &
    grepl("^KF municipality [0-9]{4}$", entries$coverage)]
  if (length(files) != 290L || anyDuplicated(files))
    stop("Expected 290 preserved KF municipality XML sources.", call. = FALSE)
  sort(files)
}

.xml2006_read <- function(sources, file, val) {
  doc <- xml2::read_xml(.xml2006_source(sources, file), options = c("NONET", "NOBLANKS"))
  if (!identical(.xml2018_attr(doc, "VALDAG"), "20060917") ||
      !identical(.xml2018_attr(doc, "VALTYP"), c(RD = "Riksdagsval",
        RF = "Landstingsval", KF = "Kommunfullm\u00e4ktigval")[[val]]) ||
      !identical(.xml2018_attr(doc, "RAPPORTERING"), "SLUTLIG R\u00d6STR\u00c4KNING RESULTAT"))
    stop("Unexpected 2006 final-result metadata: ", file, call. = FALSE)
  doc
}

.xml2006_register <- function(doc, val, area = "00", sources = NULL) {
  cache_key <- paste("register", val, area, .xml2018_attr(doc, "FILNAMN"),
    .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD"), sep = "|")
  if (!is.null(sources)) {
    cached <- get0(cache_key, sources$cache, inherits = FALSE)
    if (!is.null(cached)) return(cached)
  }
  register <- .xml2014_register(doc, val, area)$data
  parties <- xml2::xml_find_all(doc, "./PARTI")
  aliases <- xml2::xml_attr(parties, "F\u00d6RKORTNING")
  codes <- c(M = "0001", C = "0004", FP = "0003", KD = "0068",
    MP = "0055", S = "0002", V = "0005")
  extra <- tibble::tibble(valtyp = val, valomradeskod = area,
    partiforkortning = aliases,
    partibeteckning = xml2::xml_attr(parties, "BETECKNING"),
    partikod = ifelse(grepl("^[0-9]{4}$", aliases), aliases, unname(codes[aliases])))
  lists <- xml2::xml_find_all(doc, ".//GILTIGA/VALSEDEL|.//GILTIGA/PARTISEDEL")
  list_alias <- xml2::xml_find_chr(lists, "string(../@PARTI)")
  list_codes <- substr(xml2::xml_attr(lists, "LISTNUMMER"), 1L, 4L)
  for (i in which(is.na(extra$partikod))) {
    found <- unique(list_codes[list_alias == extra$partiforkortning[[i]]])
    found <- found[!is.na(found) & grepl("^[0-9]{4}$", found)]
    if (length(found) == 1L) extra$partikod[[i]] <- found
  }
  if (!is.null(sources)) {
    ballots <- .xml2006_ballots(sources)
    ballots <- ballots[ballots$valtyp == val & (area == "00" | ballots$area == area), ]
    catalogue <- unique(ballots[c("partibeteckning", "partikod")])
    catalogue <- catalogue[!duplicated(catalogue$partibeteckning) & !duplicated(catalogue$partibeteckning, fromLast = TRUE), ]
    missing <- is.na(extra$partikod)
    extra$partikod[missing] <- catalogue$partikod[match(extra$partibeteckning[missing], catalogue$partibeteckning)]
    # A cross-area fallback is permitted only for an unambiguous official
    # designation/code within this election type, never for candidate names.
    catalogue <- unique(.xml2006_ballots(sources)[.xml2006_ballots(sources)$valtyp == val, c("partibeteckning", "partikod")])
    catalogue <- catalogue[!duplicated(catalogue$partibeteckning) & !duplicated(catalogue$partibeteckning, fromLast = TRUE), ]
    missing <- is.na(extra$partikod)
    extra$partikod[missing] <- catalogue$partikod[match(extra$partibeteckning[missing], catalogue$partibeteckning)]
  }
  if (!is.null(sources)) {
    catalogue <- unique(.xml2006_ballots(sources)[c("partibeteckning", "partikod")])
    catalogue <- catalogue[!duplicated(catalogue$partibeteckning) & !duplicated(catalogue$partibeteckning, fromLast = TRUE), ]
    missing <- is.na(extra$partikod)
    extra$partikod[missing] <- catalogue$partikod[match(extra$partibeteckning[missing], catalogue$partibeteckning)]
  }
  # An internal token allows the shared reader to retain an explicitly named
  # source party even when no official numeric code is available. It is
  # removed before publication; it is not a new public party identifier.
  missing <- is.na(extra$partikod) & !extra$partiforkortning %in% c("BLANK", "OG", "\u00d6VR")
  extra$partikod[missing] <- paste("source-unresolved", val, area, extra$partiforkortning[missing], sep = ":")
  extra <- extra[!is.na(extra$partikod), ]
  out <- .xml2018_reg_index(unique(dplyr::bind_rows(register, extra)))
  if (!is.null(sources)) assign(cache_key, out, sources$cache)
  out
}

.xml2006_metadata <- function(out) {
  out$valtillfalle <- rep("Val_2006", nrow(out))
  out$valar <- rep(2006L, nrow(out))
  if ("valdatum" %in% names(out)) out$valdatum <- rep("2006-09-17", nrow(out))
  out
}

# National RD/RF files contain a non-overlapping municipality branch under
# KRETS_RIKSDAG. Copying a municipality into an ephemeral document lets the
# shared reader preserve its existing geography semantics.
.xml2006_documents <- function(sources, val, niva) {
  low <- niva %in% c("kommun", "kommunvalkrets", "valdistrikt")
  if (val != "KF" && niva %in% c("kommunvalkrets", "valdistrikt")) {
    entries <- sources$municipal_sources
    files <- entries$file[grepl(paste0("^slutresultat_[0-9]{4}", c(RD = "R", RF = "L")[[val]], "[.]xml$"), entries$file)]
    if (length(files) != (if (val == "RF") 289L else 290L) || anyDuplicated(files))
      stop("Missing complete preserved official 2006 municipality/district sources.", call. = FALSE)
    return(lapply(sort(files), function(file) .xml2006_read(sources, paste0("official-final/", file), val)))
  }
  files <- .xml2006_files(sources, val, national = !low && val == "KF")
  docs <- lapply(files, function(file) .xml2006_read(sources, file, val))
  if (!low || val == "KF") return(docs)
  doc <- docs[[1]]
  municipalities <- xml2::xml_find_all(doc, ".//KRETS_RIKSDAG/KOMMUN")
  codes <- xml2::xml_attr(municipalities, "KOD")
  if (length(codes) != (if (val == "RF") 289L else 290L) || anyDuplicated(codes))
    stop("Incomplete/overlapping 2006 municipality branch.", call. = FALSE)
  lapply(municipalities, function(municipality) {
    out <- xml2::read_xml("<VAL/>")
    xml2::xml_attrs(out) <- xml2::xml_attrs(doc)
    for (party in xml2::xml_find_all(doc, "./PARTI")) xml2::xml_add_child(out, party)
    xml2::xml_add_child(out, municipality)
    if (val == "RD") {
      constituency <- xml2::xml_find_first(municipality, "ancestor::KRETS_RIKSDAG[1]")
      xml2::xml_set_attr(out, "SWELECTIONS_RD_CODE", .xml2018_attr(constituency, "KOD"))
      xml2::xml_set_attr(out, "SWELECTIONS_RD_NAME", .xml2018_attr(constituency, "NAMN"))
    }
    out
  })
}

.valresultat_2006 <- function(sources, val, niva, rakning, progress = FALSE, internal = FALSE) {
  if (rakning != "slutlig") stop("2006 has no complete preserved preliminary collection source; election-night data are not the full preliminary result.", call. = FALSE)
  .valresultat_niva_2018(val, niva)
  if ((val == "RF" && niva == "riket") || (val == "KF" && niva %in% c("riket", "lan"))) {
    x <- .valresultat_2006(sources, val, "kommun", rakning, progress, internal = TRUE)
    x$valdistriktskod <- x$kommunkod
    x$raknat <- rep(TRUE, nrow(x))
    out <- .xml2006_metadata(.xml2014_aggregate_results(x, val, niva))
    out$rakningstillfalle <- rep("slutlig", nrow(out))
    if (internal) return(out)
    out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
    out <- .valresultat_public_andelar_2026(out)[.valresultat_public_columns_2026(niva)]
    .xml2006_result_key(out, niva)
    return(out)
  }
  out <- purrr::map(.xml2006_documents(sources, val, niva), function(doc) {
    root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
    purrr::map(.xml2018_noder(doc, niva, val), function(node) {
      .xml2006_other_parties(node)
      other <- .xml2018_forsta(node, "\u00d6VRIGA_GILTIGA")
      if (!inherits(other, "xml_missing") && !length(xml2::xml_children(other))) {
        child <- xml2::xml_add_child(other, "HANDSKRIVNA")
        xml2::xml_attrs(child) <- xml2::xml_attrs(other)
      }
      geo <- .xml2006_geography(sources, node, val, niva, doc)
      register <- .xml2006_register(doc, val, geo$valomradeskod, sources)
      .xml2018_partirader(node, geo, root, val, register)
    }) |> purrr::list_rbind()
  }, .progress = progress) |> purrr::list_rbind()
  out <- .xml2006_metadata(.xml2014_known_vote_totals(out))
  out$partibeteckning[out$ovriga_partier %in% TRUE] <- "\u00d6vriga partier"
  if (niva == "valdistrikt") out$raknat <- rep(TRUE, nrow(out))
  out <- .komplettera_kommunnamn_2026(out, out$kommunnamn)
  if (internal) return(out)
  out <- .valresultat_public_andelar_2026(out)[.valresultat_public_columns_2026(niva)]
  unresolved <- grepl("^source-unresolved:", out$partikod)
  out$partikod[unresolved] <- NA_character_
  .xml2006_result_key(out, niva)
  out
}

# A slot identifier is only evidence of an appointed source observation. It
# must never be interpreted as a source person ID or matched through names.
.xml2006_appointment_slots <- function(doc, val) {
  nodes <- xml2::xml_find_all(doc, ".//VALD|.//ERS\u00c4TTARE")
  placeholder <- xml2::xml_attr(nodes, "NAMN") %in% "Kunde ej utses"
  xml2::xml_set_attr(nodes[placeholder], "NAMN", "Kunde inte utses")
  actual <- nodes[!placeholder]
  ids <- .xml2006_id(val, "slot", vapply(actual, function(node)
    paste(.xml2018_attr(doc, "FILNAMN"), xml2::xml_path(node), sep = "|"), ""))
  xml2::xml_set_attr(actual, "KANDNR", ids)
  doc
}

.mandat_2006 <- function(sources, par, rakning = "slutlig", progress = FALSE) {
  if (rakning != "slutlig") stop("2006 seats require final election XML.", call. = FALSE)
  out <- purrr::map(seq_len(nrow(par)), function(i) {
    val <- par$valtyp[[i]]
    niva <- par$geografiniva[[i]]
    files <- .xml2006_files(sources, val)
    purrr::map(files, function(file) {
      doc <- .xml2006_appointment_slots(.xml2006_read(sources, file, val), val)
      root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
      register <- .xml2006_register(doc, val,
        if (val == "KF") .xml2018_attr(root, "KOD") else "00", sources)
      # An OVR row with zero seats is an aggregate, not an identified party.
      xml2::xml_remove(xml2::xml_find_all(doc, ".//GILTIGA[@PARTI='\u00d6VR' and @MANDAT='0']"))
      purrr::map(.xml2018_mandat_noder(doc, val, niva),
        .xml2018_mandatrader, doc = doc, root = root, val = val, niva = niva,
        register = register) |> purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  .mandat_public_2026(.kort_kommunnamn_2026(.xml2006_metadata(out)), 2006L)
}

.xml2006_ballots <- function(sources) {
  cached <- get0("ballots", sources$cache, inherits = FALSE)
  if (!is.null(cached)) return(cached)
  zip <- file.path(sources$root, "valresultat", "xml.zip")
  if (!file.exists(zip) || !identical(unname(tools::md5sum(zip)),
      "cdf5e7f9caa29cdf679f4b051cc79571")) stop("Missing or changed 2006 ballot ZIP.", call. = FALSE)
  folder <- tempfile("swelections-2006-ballots-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  utils::unzip(zip, exdir = folder)
  rows <- lapply(sort(list.files(folder, pattern = "[.]zip$", full.names = TRUE)), function(inner) {
    target <- file.path(folder, tools::file_path_sans_ext(basename(inner)))
    dir.create(target)
    utils::unzip(inner, exdir = target)
    purrr::list_rbind(lapply(sort(list.files(target, pattern = "[.]xml$", full.names = TRUE)), function(file) {
      doc <- xml2::read_xml(file, options = c("NONET", "NOBLANKS"))
      nodes <- xml2::xml_find_all(doc, ".//VALSEDEL/KANDIDAT")
      if (!length(nodes)) return(NULL)
      lists <- xml2::xml_find_first(nodes, "parent::*")
      parties <- xml2::xml_find_first(nodes, "parent::*/parent::*")
      constituencies <- xml2::xml_find_first(nodes, "parent::*/parent::*/parent::*")
      areas <- xml2::xml_find_first(nodes, "ancestor::OMR\u00c5DE[1]")
      counties <- xml2::xml_find_first(nodes, "ancestor::L\u00c4N[1]")
      tibble::tibble(valtyp = rep(c(R = "RD", L = "RF", K = "KF")[[.xml2018_attr(doc, "VALTYPKOD")]], length(nodes)),
        area = xml2::xml_attr(areas, "KOD"), county = xml2::xml_attr(counties, "KOD"),
        constituency = xml2::xml_attr(constituencies, "KOD"),
        constituency_name = xml2::xml_attr(constituencies, "NAMN"),
        partikod = xml2::xml_attr(parties, "KOD"),
        partibeteckning = xml2::xml_attr(parties, "BETECKNING"),
        listnummer = xml2::xml_attr(lists, "LISTNUMMER"),
        status = xml2::xml_attr(lists, "STATUS"),
        registered = xml2::xml_attr(lists, "KANDIDATANM\u00c4LAN"),
        ordning = as.integer(xml2::xml_attr(nodes, "ORDNING")),
        valsedelsuppgift = xml2::xml_attr(nodes, "KANDIDATUPPGIFT"),
        kon = xml2::xml_attr(nodes, "K\u00d6N"),
        alder_pa_valdagen = as.integer(xml2::xml_attr(nodes, "\u00c5LDER")))
    }))
  }) |> purrr::list_rbind()
  key <- c("valtyp", "area", "county", "constituency", "partikod", "listnummer", "ordning")
  if (anyDuplicated(rows[key])) stop("Duplicate 2006 ballot occurrence key.", call. = FALSE)
  assign("ballots", rows, sources$cache)
  rows
}

# VARAV_OVRIGA is a partition, not additional votes above the OVR total.
.xml2006_other_parties <- function(node) {
  other <- xml2::xml_find_first(node, "./GILTIGA[@PARTI='\u00d6VR']")
  if (inherits(other, "xml_missing")) return(invisible(NULL))
  group <- xml2::xml_add_child(node, "\u00d6VRIGA_GILTIGA")
  xml2::xml_attrs(group) <- xml2::xml_attrs(other)
  details <- xml2::xml_find_all(other, "./VARAV_\u00d6VRIGA")
  if (!length(details)) {
    child <- xml2::xml_add_child(group, "HANDSKRIVNA")
    xml2::xml_attrs(child) <- xml2::xml_attrs(other)
  } else {
    counts <- as.integer(xml2::xml_attr(details, "R\u00d6STER"))
    if (anyNA(counts) || sum(as.double(counts)) != .xml2018_int(other, "R\u00d6STER"))
      stop("2006 other-party partition disagrees with its source total.", call. = FALSE)
    for (detail in details) {
      child <- xml2::xml_add_child(group, if (.xml2018_attr(detail, "PARTI") == "\u00d6VR")
        "HANDSKRIVNA" else "GILTIGA")
      xml2::xml_attrs(child) <- xml2::xml_attrs(detail)
    }
  }
  xml2::xml_remove(other)
  invisible(NULL)
}

.xml2006_result_key <- function(data, niva) {
  geo <- .valresultat_geo_key(niva)
  required <- c("valtillfalle", "valtyp", "rakningstillfalle", setdiff(geo, "valdistriktstyp"))
  if (anyNA(data[required])) stop("Missing 2006 election/geography identity.", call. = FALSE)
  # Explicit source aliases/designations distinguish parties for which the
  # preserved Valmyndigheten sources do not expose a numeric party code.
  key <- c(required, "geografiniva", "partikod", "ovriga_partier", "partiforkortning", "partibeteckning")
  if (anyDuplicated(data[key])) stop("Duplicate 2006 source-party result key.", call. = FALSE)
  invisible(NULL)
}

.xml2006_geography <- function(sources, node, val, niva, doc) {
  geo <- .xml2018_geo(node, val, niva, doc)
  if (!val %in% c("RD", "RF") || !niva %in% c("kommun", "kommunvalkrets", "valdistrikt")) return(geo)
  key <- paste0("geography-", val)
  index <- get0(key, sources$cache, inherits = FALSE)
  if (is.null(index)) {
    national <- .xml2006_read(sources, .xml2006_files(sources, val), val)
    areas <- xml2::xml_find_all(national, if (val == "RD") ".//KRETS_RIKSDAG" else ".//KRETS_LANDSTING")
    municipalities <- xml2::xml_find_all(areas, "./KOMMUN", flatten = TRUE)
    parents <- xml2::xml_find_first(municipalities, "parent::*")
    index <- list(areas = tibble::tibble(code = xml2::xml_attr(areas, "KOD"), name = xml2::xml_attr(areas, "NAMN")),
      municipalities = unique(tibble::tibble(municipality = xml2::xml_attr(municipalities, "KOD"), code = xml2::xml_attr(parents, "KOD"))))
    assign(key, index, sources$cache)
  }
  if (val == "RD" || niva == "kommun") {
    codes <- unique(index$municipalities$code[index$municipalities$municipality == geo$kommunkod])
    code <- if (length(codes) == 1L) codes else NA_character_
  } else code <- .xml2018_attr(xml2::xml_find_first(node, "ancestor-or-self::KRETS_KOMMUN[1]"), "KRETS_LANDSTING")
  geo$valkretskod <- code
  geo$valkretsnamn <- index$areas$name[match(code, index$areas$code)]
  geo
}
