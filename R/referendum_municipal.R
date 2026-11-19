# Municipal referendums: event-keyed registry, SHA256-verified HTML snapshots,
# and canonical Parquet support under the shared referendum schema.

.referendum_municipal_cache <- new.env(parent = emptyenv())

.referendum_events <- function() {
  tibble::tibble(
    election_year = c(2003L, 2019L),
    election_date = c("2003-09-14", "2019-05-26"),
    election_code = c("F", "F"),
    election_kind = c("ordinary", "ordinary"),
    scope_level = c("national", "municipality"),
    scope_code = c("00", "0840,0885"),
    scope_name = c("Sweden", "M\u00f6rbyl\u00e5nga, Borgholm"),
    election_event = c(
      "Folkomr\u00f6stning 14 september 2003 om inf\u00f6rande av euron",
      "SE-F-2019-05-26-0840-0885"
    ),
    referendum_question = c(
      "Anser du att Sverige skall inf\u00f6ra euron som valuta",
      "\u00d6land en kommun?"
    ),
    final_results_available = c(TRUE, TRUE),
    canonical_available = c(TRUE, FALSE),
    preliminary_available = c(FALSE, FALSE),
    source_url = c(
      "https://historik.val.se/val/emu2003/resultat/slutresultat/index.html",
      paste(
        c(
          "https://web.archive.org/web/20190825225455id_/https://www.borgholm.se/resultat-fran-folkomrostningen-oland-en-kommun/",
          "https://web.archive.org/web/20190824002001id_/https://www.morbylanga.se/kommun-politik/Oland-en-kommun/Preliminart-resultat-folkomrostningen-Oland-en-kommun/"
        ),
        collapse = "; "
      )
    ),
    stringsAsFactors = FALSE
  )[, c(
    "election_year", "election_date", "election_code", "election_kind",
    "scope_level", "scope_code", "scope_name", "election_event",
    "referendum_question", "final_results_available", "canonical_available",
    "preliminary_available", "source_url"
  )]
}

.referendum_2019_oland_sources <- function() {
  tibble::tibble(
    election_event = c("SE-F-2019-05-26-0840-0885", "SE-F-2019-05-26-0840-0885"),
    municipality_code = c("0840", "0885"),
    municipality_name = c("M\u00f6rbyl\u00e5nga", "Borgholm"),
    county_code = c("08", "08"),
    filename = c("morbylanga-2019-05-26.html", "borgholm-2019-05-26.html"),
    aliases = list(
      c("morbylanga-2019-05-26.html", "Preliminart-resultat-folkomrostningen-Oland-en-kommun.html"),
      c("borgholm-2019-05-26.html", "resultat-fran-folkomrostningen-oland-en-kommun.html")
    ),
    expected_eligible = c(11837L, 9106L),
    bytes = c(249931L, 217191L),
    sha256 = c(
      "dfaba0c81ce466795c353566f4f4f5143d85a4722aadf184140531951cb8bb94",
      "b509ff31353a2bec7fcad73fddf851c3d361925e2185cf22a4ee02b9893060f7"
    ),
    url = c(
      "https://web.archive.org/web/20190824002001id_/https://www.morbylanga.se/kommun-politik/Oland-en-kommun/Preliminart-resultat-folkomrostningen-Oland-en-kommun/",
      "https://web.archive.org/web/20190825225455id_/https://www.borgholm.se/resultat-fran-folkomrostningen-oland-en-kommun/"
    )
  )
}

.referendum_2019_oland_districts <- function() {
  tibble::tribble(
    ~municipality_code, ~district_code, ~district_name,
    "0840", "08401406", "Algutsrum",
    "0840", "08401304", "Gl\u00f6mminge",
    "0840", "08400401", "G\u00e5rdby",
    "0840", "08400303", "M\u00f6rbyl\u00e5nga-Kastl\u00f6sa",
    "0840", "08401503", "Runsb\u00e4ck",
    "0840", "08401504", "Skogsby",
    "0840", "08401501", "Sn\u00e4ckstrand",
    "0840", "08400811", "Syd\u00f6land",
    "0840", "08401502", "Talludden",
    "0840", "08400105", "Vickleby-Resmo",
    "0885", "08850203", "Alb\u00f6ke-F\u00f6ra-Breds\u00e4ttra-Egby-L\u00f6t",
    "0885", "08850101", "Borgholms 1",
    "0885", "08850102", "Borgholms 2",
    "0885", "08851313", "B\u00f6da",
    "0885", "08851010", "G\u00e4rdsl\u00f6sa-L\u00e5ngl\u00f6t-Runsten",
    "0885", "08851415", "H\u00f6gby",
    "0885", "08851516", "K\u00e4lla-Persn\u00e4s",
    "0885", "08850707", "K\u00f6ping",
    "0885", "08850808", "R\u00e4pplinge-H\u00f6gsrum"
  )
}

.referendum_municipal_file <- function(entry, source, data_dir) {
  root <- val_data_dir(data_dir)
  if (source == "local") {
    if (is.null(root) || !nzchar(root)) {
      stop("Specify `data_dir` for preserved local 2019 municipal referendum sources.",
           call. = FALSE)
    }
    roots <- unique(c(
      file.path(root, "referendum", "2019"),
      file.path(root, "folkomrostning", "2019"),
      file.path(root, "2019"),
      root
    ))
    existing_root <- roots[dir.exists(roots)][1L]
    if (!is.na(existing_root)) {
      candidates <- sort(list.files(existing_root, recursive = TRUE, full.names = TRUE))
      aliases <- entry$aliases[[1L]]
      named <- candidates[basename(candidates) %in% aliases]
      for (f in named) {
        if (identical(.canonical_sha256(f), entry$sha256)) return(f)
      }
      if (length(named)) {
        stop("Changed or unverified 2019 municipal referendum source: ",
             basename(named[[1L]]), call. = FALSE)
      }
      for (f in candidates[grepl("\\.html?$", candidates, ignore.case = TRUE)]) {
        if (identical(.canonical_sha256(f), entry$sha256)) return(f)
      }
    }
    stop("Missing preserved 2019 municipal referendum source: ", entry$filename,
         call. = FALSE)
  }
  cached <- if (exists(entry$url, .referendum_municipal_cache, inherits = FALSE)) {
    get(entry$url, .referendum_municipal_cache, inherits = FALSE)
  } else NULL
  if (is.null(cached) || !file.exists(cached)) {
    f <- tempfile(fileext = ".html")
    .download_file(entry$url, f, expected_bytes = entry$bytes)
    if (!identical(.canonical_sha256(f), entry$sha256)) {
      unlink(f)
      stop("Changed 2019 municipal referendum source checksum: ", entry$filename,
           call. = FALSE)
    }
    assign(entry$url, f, .referendum_municipal_cache)
    cached <- f
  }
  cached
}

.referendum_clean_ws <- function(x) {
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}

.referendum_parse_int <- function(x, field) {
  cleaned <- gsub("[[:space:]\u00a0]+", "", x)
  if (length(cleaned) != 1L || is.na(cleaned) || !grepl("^[0-9]+$", cleaned) ||
      as.double(cleaned) > .Machine$integer.max) {
    stop("Invalid municipal referendum count for ", field, ": ", x, call. = FALSE)
  }
  as.integer(cleaned)
}

.referendum_norm_district_name <- function(x) {
  x <- .referendum_clean_ws(x)
  gsub("-[[:space:]]+", "-", x)
}

.referendum_2019_parse_html <- function(file, entry, source_file) {
  doc <- xml2::read_html(file, encoding = "UTF-8")
  tables <- xml2::xml_find_all(doc, ".//table")
  if (!length(tables)) {
    stop("No result table found in 2019 municipal referendum source: ",
         entry$municipality_name, call. = FALSE)
  }
  parsed_rows <- NULL
  for (tbl in tables) {
    trs <- xml2::xml_find_all(tbl, ".//tr")
    rows <- lapply(trs, function(tr) {
      cells <- xml2::xml_find_all(tr, "./th|./td")
      vapply(cells, function(c) .referendum_clean_ws(xml2::xml_text(c)), character(1L))
    })
    rows <- rows[vapply(rows, length, integer(1L)) >= 5L]
    if (length(rows) && identical(toupper(rows[[1L]][1L]), "VALDISTRIKT") &&
        all(c("JA", "NEJ", "BLANK") %in% toupper(rows[[1L]][3:5]))) {
      parsed_rows <- rows
      break
    }
  }
  if (is.null(parsed_rows)) {
    stop("Expected referendum result table not found for ",
         entry$municipality_name, call. = FALSE)
  }

  header <- parsed_rows[[1L]]
  if (!grepl("R\u00f6stber\u00e4ttigade", header[[2L]], ignore.case = TRUE) ||
      !identical(toupper(header[3:5]), c("JA", "NEJ", "BLANK"))) {
    stop("Unexpected referendum table columns for ", entry$municipality_name,
         call. = FALSE)
  }

  body <- parsed_rows[-1L]
  labels <- vapply(body, `[[`, character(1L), 1L)
  idx_prelim <- which(grepl("^TOTALT INKOMNA R\u00d6STER", labels, ignore.case = TRUE))
  idx_wed <- which(grepl("^R\u00f6ster onsdagsr\u00e4kningen", labels, ignore.case = TRUE))
  idx_total <- which(grepl("^TOTALT R\u00d6STRESULTAT", labels, ignore.case = TRUE))
  if (length(idx_prelim) != 1L || length(idx_wed) != 1L || length(idx_total) != 1L) {
    stop("Missing summary or Wednesday count rows for ", entry$municipality_name,
         call. = FALSE)
  }
  ordinary_rows <- body[seq_len(idx_prelim - 1L)]
  if (!length(ordinary_rows)) {
    stop("No ordinary voting districts found for ", entry$municipality_name,
         call. = FALSE)
  }

  district_map <- .referendum_2019_oland_districts()
  district_map <- district_map[district_map$municipality_code == entry$municipality_code, ,
                               drop = FALSE]

  parse_unit <- function(cells, district_code, district_name, district_type,
                         literal_name, node_type, eligible_required = TRUE) {
    eligible <- if (eligible_required) {
      .referendum_parse_int(cells[[2L]], paste0(literal_name, " eligible"))
    } else {
      if (nzchar(.referendum_clean_ws(cells[[2L]]))) {
        stop("Unexpected eligible count on collection row for ",
             entry$municipality_name, call. = FALSE)
      }
      NA_integer_
    }
    votes <- c(
      JA = .referendum_parse_int(cells[[3L]], paste0(literal_name, " JA")),
      NEJ = .referendum_parse_int(cells[[4L]], paste0(literal_name, " NEJ")),
      BLANK = .referendum_parse_int(cells[[5L]], paste0(literal_name, " BLANK"))
    )
    valid <- as.integer(sum(votes))
    options <- names(votes)
    tibble::tibble(
      valtillfalle = entry$election_event,
      valar = 2019L,
      valdatum = "2019-05-26",
      valtyp = "F",
      rakningstillfalle = "slutlig",
      folkomrostningsfraga = "\u00d6land en kommun?",
      geografiniva = "valdistrikt",
      valdistriktskod = district_code,
      valdistriktsnamn = district_name,
      kommunkod = entry$municipality_code,
      kommunnamn = entry$municipality_name,
      lankod = entry$county_code,
      lannamn = .valresultat_lannamn_2026(entry$county_code),
      valdistriktstyp = district_type,
      rostningsalternativkod = options,
      rostningsalternativnamn = unname(c(JA = "Ja", NEJ = "Nej", BLANK = "Blank")[options]),
      blankt_alternativ = options == "BLANK",
      antal_roster = unname(votes),
      andel_roster = if (valid > 0L) unname(votes) / valid else NA_real_,
      giltiga_roster = valid,
      blanka_roster = unname(votes["BLANK"]),
      ogiltiga_roster = NA_integer_,
      totalt_antal_roster = NA_integer_,
      antal_rostberattigade = eligible,
      antal_rostberattigade_svenska_i_sverige = NA_integer_,
      antal_rostberattigade_svenska_utomlands = NA_integer_,
      antal_rostberattigade_utlandska = NA_integer_,
      valdel = NA_real_,
      raknat = TRUE,
      antal_valdistrikt_raknade_omrade = NA_integer_,
      antal_valdistrikt_som_ska_raknas_omrade = NA_integer_,
      kall_enhetskod = district_code,
      kall_enhetsnamn = literal_name,
      kall_nodtyp = node_type,
      kallfil = source_file,
      kalla_sha256 = entry$sha256,
      kalla_url = entry$url,
      senaste_uppdateringstid = NA_character_,
      rapporteringstid = NA_character_,
      kall_rostprocent = NA_real_,
      kall_valdeltagandeprocent = NA_real_
    )
  }

  ordinary_tibbles <- lapply(ordinary_rows, function(cells) {
    literal <- cells[[1L]]
    norm_name <- .referendum_norm_district_name(literal)
    idx <- match(norm_name, district_map$district_name)
    if (is.na(idx)) {
      stop("Unrecognized voting district in ", entry$municipality_name, ": ",
           literal, call. = FALSE)
    }
    parse_unit(
      cells,
      district_code = district_map$district_code[idx],
      district_name = district_map$district_name[idx],
      district_type = "valdistrikt",
      literal_name = literal,
      node_type = "ordinary",
      eligible_required = TRUE
    )
  })
  ordinary_df <- purrr::list_rbind(ordinary_tibbles)

  if (!setequal(unique(ordinary_df$valdistriktskod), district_map$district_code) ||
      anyDuplicated(ordinary_df[c("valdistriktskod", "rostningsalternativkod")])) {
    stop("Missing or duplicate ordinary districts for ", entry$municipality_name,
         call. = FALSE)
  }

  ordinary_units <- ordinary_df[!duplicated(ordinary_df$valdistriktskod), , drop = FALSE]
  if (!identical(sum(ordinary_units$antal_rostberattigade), entry$expected_eligible)) {
    stop("Ordinary district eligible voters disagree with municipality total for ",
         entry$municipality_name, call. = FALSE)
  }

  prelim_row <- body[[idx_prelim]]
  prelim_expected <- c(
    JA = .referendum_parse_int(prelim_row[[3L]], "prelim JA"),
    NEJ = .referendum_parse_int(prelim_row[[4L]], "prelim NEJ"),
    BLANK = .referendum_parse_int(prelim_row[[5L]], "prelim BLANK")
  )
  ordinary_sums <- vapply(
    c("JA", "NEJ", "BLANK"),
    function(opt) as.integer(sum(ordinary_df$antal_roster[ordinary_df$rostningsalternativkod == opt])),
    integer(1L)
  )
  if (!identical(unname(ordinary_sums), unname(prelim_expected))) {
    stop("Ordinary district vote sums disagree with 2019-05-26 total for ",
         entry$municipality_name, call. = FALSE)
  }

  wed_row <- body[[idx_wed]]
  wed_code <- paste0("F-", entry$municipality_code, "-00")
  wed_df <- parse_unit(
    wed_row,
    district_code = wed_code,
    district_name = "Uppsamlingsdistrikt",
    district_type = "uppsamlingsdistrikt",
    literal_name = wed_row[[1L]],
    node_type = "collection",
    eligible_required = FALSE
  )

  total_row <- body[[idx_total]]
  total_expected <- c(
    JA = .referendum_parse_int(total_row[[3L]], "total JA"),
    NEJ = .referendum_parse_int(total_row[[4L]], "total NEJ"),
    BLANK = .referendum_parse_int(total_row[[5L]], "total BLANK")
  )
  combined <- dplyr::bind_rows(ordinary_df, wed_df)
  combined_sums <- vapply(
    c("JA", "NEJ", "BLANK"),
    function(opt) as.integer(sum(combined$antal_roster[combined$rostningsalternativkod == opt])),
    integer(1L)
  )
  if (!identical(unname(combined_sums), unname(total_expected))) {
    stop("Ordinary + Wednesday votes disagree with total referendum result for ",
         entry$municipality_name, call. = FALSE)
  }

  combined
}

.referendum_2019_aggregate_municipality <- function(district_df) {
  munis <- unique(district_df$kommunkod)
  purrr::list_rbind(lapply(munis, function(m) {
    sub <- district_df[district_df$kommunkod == m, , drop = FALSE]
    units <- sub[!duplicated(sub$valdistriktskod), , drop = FALSE]
    ordinary <- units[units$valdistriktstyp == "valdistrikt", , drop = FALSE]
    opts <- c("JA", "NEJ", "BLANK")
    votes <- vapply(
      opts,
      function(opt) as.integer(sum(sub$antal_roster[sub$rostningsalternativkod == opt])),
      integer(1L)
    )
    valid <- as.integer(sum(votes))
    eligible <- as.integer(sum(ordinary$antal_rostberattigade))
    n_units <- as.integer(nrow(units))
    first <- sub[1L, , drop = FALSE]
    tibble::tibble(
      valtillfalle = first$valtillfalle,
      valar = first$valar,
      valdatum = first$valdatum,
      valtyp = first$valtyp,
      rakningstillfalle = first$rakningstillfalle,
      folkomrostningsfraga = first$folkomrostningsfraga,
      geografiniva = "kommun",
      kommunkod = m,
      kommunnamn = first$kommunnamn,
      lankod = first$lankod,
      lannamn = first$lannamn,
      rostningsalternativkod = opts,
      rostningsalternativnamn = unname(c(JA = "Ja", NEJ = "Nej", BLANK = "Blank")[opts]),
      blankt_alternativ = opts == "BLANK",
      antal_roster = unname(votes),
      andel_roster = if (valid > 0L) unname(votes) / valid else NA_real_,
      giltiga_roster = valid,
      blanka_roster = unname(votes["BLANK"]),
      ogiltiga_roster = NA_integer_,
      totalt_antal_roster = NA_integer_,
      antal_rostberattigade = eligible,
      antal_rostberattigade_svenska_i_sverige = NA_integer_,
      antal_rostberattigade_svenska_utomlands = NA_integer_,
      antal_rostberattigade_utlandska = NA_integer_,
      valdel = NA_real_,
      raknat = TRUE,
      antal_valdistrikt_raknade_omrade = n_units,
      antal_valdistrikt_som_ska_raknas_omrade = n_units,
      kall_enhetskod = m,
      kall_enhetsnamn = first$kommunnamn,
      kall_nodtyp = "municipality",
      kallfil = first$kallfil,
      kalla_sha256 = first$kalla_sha256,
      kalla_url = first$kalla_url,
      senaste_uppdateringstid = NA_character_,
      rapporteringstid = NA_character_,
      kall_rostprocent = NA_real_,
      kall_valdeltagandeprocent = NA_real_
    )
  }))
}

.referendum_municipal_raw <- function(year, source, data_dir, level) {
  if (!identical(as.integer(year), 2019L)) {
    stop("Unsupported municipal referendum year: ", year, call. = FALSE)
  }
  sources <- .referendum_2019_oland_sources()
  district_df <- purrr::list_rbind(lapply(seq_len(nrow(sources)), function(i) {
    entry <- sources[i, , drop = FALSE]
    file <- .referendum_municipal_file(entry, source, data_dir)
    source_label <- if (source == "local") basename(file) else entry$filename
    .referendum_2019_parse_html(file, entry, source_label)
  }))
  if (level == "valdistrikt") return(district_df)
  if (level == "kommun") return(.referendum_2019_aggregate_municipality(district_df))
  stop("Unsupported 2019 municipal referendum geographic level.", call. = FALSE)
}

.canonical_referendum_municipal <- function(year, level, auto_selected = FALSE) {
  .canonical_require_reader()
  path <- .canonical_configured_manifest(as.integer(year), "folkomr", "ordinary")
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path)) {
    stop(year, " referendum canonical data require an explicitly configured local manifest.",
         call. = FALSE)
  }
  manifest <- .canonical_manifest(path)
  if (!identical(manifest$valserie, "folkomr") ||
      !identical(as.integer(manifest$valar), as.integer(year)) ||
      !identical(as.integer(manifest$schema_version), 3L) ||
      !identical(manifest$format, "parquet")) {
    stop("Expected final referendum ", year, " English Parquet schema version 3.",
         call. = FALSE)
  }
  asset <- paste0("referendum", as.integer(year), "-results-final")
  entry <- manifest$assets[manifest$assets$asset == asset, , drop = FALSE]
  if (nrow(entry) != 1L) stop("Missing referendum results asset: ", asset, call. = FALSE)
  data <- .canonical_fetcher(manifest, path)(asset)
  .canonical_table(manifest, data, asset, level)
}

.referendum_municipal_results <- function(year, count, level, source, data_dir,
                                          update, archive, progress, names, detail) {
  language <- .english_output_language(names)
  detail <- .check_detail(detail)
  if (!identical(count, "final")) {
    stop(year, " municipal referendum supports final results only.", call. = FALSE)
  }
  if (is.null(level)) level <- "municipality"
  level <- .english_argument_value(level, "level")
  if (length(level) != 1L || !level %in% c("kommun", "valdistrikt")) {
    stop("Unsupported ", year, " municipal referendum geographic level; use municipality or district.",
         call. = FALSE)
  }
  source <- match.arg(source, c("auto", "local", "remote", "canonical"))
  for (flag in list(update, archive, progress)) {
    if (!is.logical(flag) || length(flag) != 1L || is.na(flag)) {
      stop("Expected scalar logical flags.", call. = FALSE)
    }
  }
  if (update || archive) {
    stop("Municipal referendum sources are read-only; preserve snapshots separately.",
         call. = FALSE)
  }
  if (source == "canonical") {
    .check_public_args(as.integer(year), "results", source, data_dir, update, archive,
                       valar_resolved = TRUE)
    data <- .canonical_referendum_municipal(as.integer(year), level, FALSE)
  } else {
    data <- .referendum_municipal_raw(as.integer(year), source, data_dir, level)
  }
  if (anyDuplicated(data[c("valtillfalle", "kall_enhetskod", "rostningsalternativkod")])) {
    stop("Duplicate municipal referendum result keys.", call. = FALSE)
  }
  if (detail == "standard") {
    data <- data[, intersect(.referendum2003_standard, names(data)), drop = FALSE]
  }
  .public_output(data, language)
}

.referendum_results <- function(year, year_missing, from, to, count, level,
                                source, data_dir, update, archive, progress, names, detail) {
  # Preserve `results(election = "referendum", year = "all", ...)` national default
  # when `level` is NULL or national-only, while dispatching explicit 2019+ municipal
  # referendums cleanly through the shared `election = "referendum"` / `"F"` surface.
  if (year_missing && is.null(from) && is.null(to)) {
    return(.referendum2003_results(year, year_missing, from, to, count, level,
      source, data_dir, update, archive, progress, names, detail))
  }
  if (identical(year, "all") && is.null(from) && is.null(to)) {
    level_en <- if (is.null(level)) "national" else
      names(.english_argument_values$level)[match(.english_argument_value(level, "level"),
        unname(.english_argument_values$level))]
    if (!level_en %in% c("municipality", "district")) {
      return(.referendum2003_results(year, year_missing, from, to, count, level,
        source, data_dir, update, archive, progress, names, detail))
    }
  }
  years <- .resolve_valar(
    if (identical(year, "all")) "alla" else year, from, to,
    "valresultat", "F", !year_missing
  )
  parts <- lapply(years, function(y) {
    if (identical(as.integer(y), 2003L)) {
      .referendum2003_results(
        2003L, FALSE, NULL, NULL, count, level, source, data_dir,
        update, archive, progress, names, detail
      )
    } else {
      .referendum_municipal_results(
        y, count, level, source, data_dir, update, archive, progress, names, detail
      )
    }
  })
  if (length(parts) == 1L) return(parts[[1L]])
  dplyr::bind_rows(parts)
}
