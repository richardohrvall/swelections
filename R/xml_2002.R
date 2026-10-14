# 2002 final XML adapters. Raw snapshots and election-night sources stay immutable.
.sources_2002 <- function(source, data_dir, update = FALSE, archive = FALSE) {
  if (!source %in% c("auto", "local") || update || archive)
    stop("2002 requires preserved local final sources; remote/update/archive are unsupported.", call. = FALSE)
  root <- val_data_dir(data_dir)
  if (is.null(root)) stop("2002 requires a configured raw-data directory.", call. = FALSE)
  root <- file.path(root, "2002")
  path <- file.path(root, "final-source-selection.json")
  if (!file.exists(path)) stop("Missing 2002 final source selection: ", path, call. = FALSE)
  manifest <- jsonlite::read_json(path, simplifyVector = TRUE)
  if (!identical(manifest$election_date, "2002-09-15") ||
      !is.data.frame(manifest$sources) || anyDuplicated(manifest$sources$export))
    stop("Invalid 2002 final source selection.", call. = FALSE)
  list(root = root, sources = manifest$sources, year = 2002L,
       cache = new.env(parent = emptyenv()))
}

.xml2002_source <- function(sources, file) {
  row <- sources$sources[sources$sources$export == file, ]
  if (nrow(row) != 1L) stop("Missing registered 2002 export: ", file, call. = FALSE)
  path <- file.path(sources$root, row$file)
  if (!file.exists(path) || file.info(path)$size != row$bytes ||
      !identical(unname(tools::md5sum(path)), row$md5) ||
      !identical(.canonical_sha256(path), row$sha256))
    stop("Missing or changed 2002 source: ", file, call. = FALSE)
  if (file == "slutresultat_2034K.xml" &&
      !identical(row$md5, "3249b5428225a4e6d0c77dbcd1d17340"))
    stop("Orsa 2002 requires the pinned original election, not the 2003 rerun.", call. = FALSE)
  path
}

.xml2002_read <- function(sources, file, val) {
  doc <- xml2::read_xml(.xml2002_source(sources, file), options = c("NONET", "NOBLANKS"))
  if (!identical(.xml2018_attr(doc, "TILLF\u00c4LLE"), "Allm\u00e4nna val 15 September 2002") ||
      !identical(.xml2018_attr(doc, "RAPPORTERING"), "SLUTLIG SAMMANR\u00c4KNING RESULTAT") ||
      !identical(.xml2018_attr(doc, "VALTYP"), c(RD = "Riksdagsval", RF = "Landstingsval",
        KF = "Kommunfullm\u00e4ktigval")[[val]]) ||
      !identical(.xml2018_attr(doc, "FILNAMN"), file))
    stop("Unexpected 2002 election occasion/counting stage: ", file, call. = FALSE)
  if (grepl("_00[RLK][.]xml$", file)) {
    if (length(xml2::xml_find_all(doc, "./NATION")) != 1L)
      stop("Unexpected 2002 national export geography: ", file, call. = FALSE)
  } else {
    node <- xml2::xml_find_all(doc, "./KOMMUN")
    code <- substr(sub("^slutresultat_", "", file), 1L, 4L)
    if (length(node) != 1L || !identical(.xml2018_attr(node[[1]], "KOD"), code))
      stop("Unexpected 2002 municipal export geography: ", file, call. = FALSE)
  }
  # A national file can retain the ordinary root label while replacing Orsa.
  if (val == "KF") {
    orsa <- xml2::xml_find_all(doc, ".//KOMMUN[@KOD='2034']")
    for (node in orsa) {
      turnout <- xml2::xml_find_first(node, "./VALDELTAGANDE")
      if (!identical(.xml2018_int(node, "R\u00d6STER"), 4009L) ||
          !identical(.xml2018_int(turnout, "SUMMA_R\u00d6STER"), 4070L))
        stop("2002 source incorporates the Orsa rerun instead of the ordinary election.", call. = FALSE)
    }
  }
  doc
}

.xml2002_files <- function(sources, val, municipal = FALSE) {
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  if (!municipal) return(paste0("slutresultat_00", letter, ".xml"))
  files <- sort(sources$sources$export[grepl(paste0("^slutresultat_[0-9]{4}", letter, "[.]xml$"), sources$sources$export)])
  expected <- if (val == "RF") 289L else 290L
  if (length(files) != expected) stop("Incomplete preserved 2002 municipality/district sources for ", val,
    ": ", length(files), "/", expected, ".", call. = FALSE)
  national <- .xml2002_read(sources, paste0("slutresultat_00", letter, ".xml"), val)
  codes <- xml2::xml_attr(xml2::xml_find_all(national,
    "./NATION/L\u00c4N/KRETS_RIKSDAG/KOMMUN"), "KOD")
  wanted <- paste0("slutresultat_", codes, letter, ".xml")
  if (length(codes) != expected || anyDuplicated(codes) || !setequal(files, wanted))
    stop("Incomplete preserved 2002 municipality/district sources: geography population differs for ", val, ".", call. = FALSE)
  files
}

.xml2002_metadata <- function(out) {
  out$valtillfalle <- rep("Val_2002", nrow(out))
  out$valar <- rep(2002L, nrow(out))
  if ("valdatum" %in% names(out)) out$valdatum <- rep("2002-09-15", nrow(out))
  out
}

.xml2002_register <- function(doc, val, area = "00", sources = NULL) {
  key <- paste("register-2002", val, area, .xml2018_attr(doc, "FILNAMN"),
    .xml2018_attr(xml2::xml_find_first(doc, "./KOMMUN"), "KOD"), sep = "|")
  if (!is.null(sources)) {
    cached <- get0(key, sources$cache, inherits = FALSE)
    if (!is.null(cached)) return(cached)
  }
  # No 2006 ballot fallback: only this 2002 XML's official party/list evidence.
  out <- .xml2006_register(doc, val, area, sources = NULL)
  if (!is.null(sources)) assign(key, out, sources$cache)
  out
}

.xml2002_documents <- function(sources, val, niva) {
  if (niva %in% c("valdistrikt", "kommunvalkrets")) {
    coverage <- if (val == "RD") .rd2002_result_coverage(sources) else
      list(files = .xml2002_files(sources, val, TRUE), missing = character())
    docs <- lapply(coverage$files, function(file) .xml2002_read(sources, file, val))
    attr(docs, "rd_complement_municipalities") <- coverage$missing
    return(docs)
  }
  doc <- .xml2002_read(sources, .xml2002_files(sources, val), val)
  if (niva != "kommun") return(list(doc))
  nodes <- xml2::xml_find_all(doc, "./NATION/L\u00c4N/KRETS_RIKSDAG/KOMMUN")
  expected <- if (val == "RF") 289L else 290L
  if (length(nodes) != expected || anyDuplicated(xml2::xml_attr(nodes, "KOD")))
    stop("Overlapping/incomplete 2002 municipality branch.", call. = FALSE)
  lapply(nodes, function(node) {
    out <- xml2::read_xml("<VAL/>")
    xml2::xml_attrs(out) <- xml2::xml_attrs(doc)
    for (party in xml2::xml_find_all(doc, "./PARTI")) xml2::xml_add_child(out, party)
    xml2::xml_add_child(out, node)
    out
  })
}

.xml2002_nodes <- function(doc, niva, val) {
  if (niva != "valdistrikt") return(.xml2018_noder(doc, niva, val))
  # 2002 RD/RF collections are municipality children; KF collections are
  # constituency children. Keep both placements once, in source order.
  xml2::xml_find_all(doc, "./KOMMUN/KRETS_KOMMUN/VALDISTRIKT|./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT|./KOMMUN/ONSDAGSDISTRIKT")
}

.valresultat_2002 <- function(sources, val, niva, rakning, progress = FALSE) {
  if (rakning != "slutlig") stop("2002 preliminary collection results remain unrecovered; election night is not the complete preliminary result.", call. = FALSE)
  .valresultat_niva_2018(val, niva)
  docs <- .xml2002_documents(sources, val, niva)
  out <- purrr::map(docs, function(doc) {
    root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
    purrr::map(.xml2002_nodes(doc, niva, val), function(node) {
      geo <- .xml2002_geography(sources, node, val, niva, doc)
      if (val == "RD") .xml2002_apply_supplement(node, niva, geo$valkretskod)
      .xml2006_other_parties(node)
      register <- .xml2002_register(doc, val, geo$valomradeskod, sources)
      x <- .xml2018_partirader(node, geo, root, val, register)
      # OG is combined invalid ballots in 2002; it is not the other-invalid category.
      og <- xml2::xml_find_first(node, "./OGILTIGA[@TEXT='OG']")
      x$ogiltiga_roster <- rep(.xml2018_int(og, "R\u00d6STER"), nrow(x))
      x$ogiltiga_roster_fg <- rep(.xml2018_int(og, "R\u00d6STER_FGVAL"), nrow(x))
      x$ovriga_ogiltiga[] <- NA_integer_
      x$ovriga_ogiltiga_fg[] <- NA_integer_
      x$diff_ovriga_ogiltiga[] <- NA_integer_
      if (anyNA(x$giltiga_roster) && !anyNA(x$antal_roster)) x$giltiga_roster[] <- as.integer(sum(as.double(x$antal_roster)))
      for (suffix in c("", "_fg")) {
        total <- paste0("totalt_antal_roster", suffix)
        missing <- is.na(x[[total]])
        x[[total]][missing] <- (x[[paste0("giltiga_roster", suffix)]] +
          x[[paste0("ogiltiga_roster", suffix)]])[missing]
      }
      for (field in c("totalt_antal_roster", "giltiga_roster", "ogiltiga_roster")) {
        difference <- x[[field]] - x[[paste0(field, "_fg")]]
        difference[!.jamforelse_tillaten_2026(x$status_jamforelse)] <- NA_integer_
        x[[paste0("diff_", field)]] <- difference
      }
      if (niva == "valdistrikt") x$raknat <- ifelse(!is.na(x$giltiga_roster) &
        !is.na(.xml2018_attr(node, "TID_RAPPORT")), TRUE, NA)
      x
    }) |> purrr::list_rbind()
  }, .progress = progress) |> purrr::list_rbind()
  complementary <- attr(docs, "rd_complement_municipalities", exact = TRUE)
  if (length(complementary)) {
    bundles <- .rd2002_complement(sources, complementary)
    out <- dplyr::bind_rows(out,
      purrr::map(bundles, .rd2002_complement_rows, niva = niva) |> purrr::list_rbind())
  }
  if (!nrow(out)) out <- .valresultat_schema()
  out$partibeteckning[out$ovriga_partier %in% TRUE] <- "\u00d6vriga partier"
  out <- .xml2002_metadata(.komplettera_kommunnamn_2026(out, out$kommunnamn))
  out <- .valresultat_public_andelar_2026(out)[.valresultat_public_columns_2026(niva)]
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  .xml2006_result_key(out, niva)
  out
}

.xml2002_appointment_slots <- function(doc, val) {
  doc <- .xml2006_appointment_slots(doc, val)
  nodes <- xml2::xml_find_all(doc, ".//*[@KANDNR]")
  xml2::xml_set_attr(nodes, "KANDNR", sub("^2006:", "2002:", xml2::xml_attr(nodes, "KANDNR")))
  doc
}

.mandat_2002 <- function(sources, par, rakning = "slutlig", progress = FALSE) {
  if (rakning != "slutlig") stop("2002 mandates require the final election result.", call. = FALSE)
  out <- purrr::map(seq_len(nrow(par)), function(i) {
    val <- par$valtyp[[i]]; niva <- par$geografiniva[[i]]
    files <- .xml2002_files(sources, val, val == "KF")
    purrr::map(files, function(file) {
      doc <- .xml2002_appointment_slots(.xml2002_read(sources, file, val), val)
      root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
      register <- .xml2002_register(doc, val, if (val == "KF") .xml2018_attr(root, "KOD") else "00", sources)
      xml2::xml_remove(xml2::xml_find_all(doc, ".//GILTIGA[@PARTI='\u00d6VR' and @MANDAT='0']"))
      purrr::map(.xml2018_mandat_noder(doc, val, niva), .xml2018_mandatrader,
        doc = doc, root = root, val = val, niva = niva, register = register) |> purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  .mandat_public_2026(.kort_kommunnamn_2026(.xml2002_metadata(out)), 2002L)
}

.xml2002_geography <- function(sources, node, val, niva, doc) {
  geo <- .xml2018_geo(node, val, niva, doc)
  if (!val %in% c("RD", "RF") || !niva %in% c("kommun", "kommunvalkrets", "valdistrikt")) return(geo)
  key <- paste0("geography-", val)
  index <- get0(key, sources$cache, inherits = FALSE)
  if (is.null(index)) {
    national <- .xml2002_read(sources, .xml2002_files(sources, val), val)
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
  } else {
    code <- .xml2018_attr(xml2::xml_find_first(node, "ancestor-or-self::KRETS_KOMMUN[1]"), "KRETS_LANDSTING")
    if (is.na(code) && xml2::xml_name(node) == "ONSDAGSDISTRIKT") {
      district <- .xml2018_attr(node, "KOD")
      candidate <- paste0(substr(geo$kommunkod, 1L, 2L), sub(".*-", "", district))
      if (candidate %in% index$areas$code) code <- candidate
    }
    if (is.na(code)) {
      candidates <- unique(index$municipalities$code[index$municipalities$municipality == geo$kommunkod])
      if (length(candidates) == 1L) code <- candidates
    }
  }
  geo$source_preference_area_code <- code
  if (!is.na(code) && endsWith(code, "00")) code <- NA_character_
  geo$valkretskod <- code
  geo$valkretsnamn <- index$areas$name[match(code, index$areas$code)]
  geo
}
