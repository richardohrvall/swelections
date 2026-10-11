# 2006 identifiers are package-generated source observations, never person IDs.
.xml2006_id <- function(val, role, key) paste0("2006:", val, ":", role, ":",
  vapply(key, utils::URLencode, "", reserved = TRUE))

.xml2006_candidacy_raw <- function(n) {
  fields <- c("valtyp", "valomradeskod", "valomradesnamn", "valkretskod",
    "valkretsnamn", "partibeteckning", "partiforkortning", "partikod",
    "valsedelsstatus", "listnummer", "valkretsbeteckning_pa_valsedeln",
    "ordning", "anmaldakandidater", "samtycke", "forklaring",
    "kandidatnummer", "namn", "alder_pa_valdagen", "kon",
    "folkbokforingskommun", "valsedelsuppgift",
    "antal_valsedlar_for_den_specifika_listan", "giltig")
  tibble::as_tibble(stats::setNames(rep(list(rep(NA_character_, n)), length(fields)), fields))
}

.read_candidacies_2006 <- function(sources, val = c("RD", "RF", "KF")) {
  b <- .xml2006_ballots(sources)
  b <- b[b$valtyp %in% val, ]
  raw <- .xml2006_candidacy_raw(nrow(b))
  for (field in c("valtyp", "partikod", "partibeteckning", "listnummer",
    "valsedelsuppgift", "kon", "alder_pa_valdagen", "ordning")) raw[[field]] <- as.character(b[[field]])
  raw$valomradeskod <- b$area
  raw$valomradesnamn <- ifelse(b$valtyp == "RD", "Sverige",
    ifelse(b$valtyp == "RF", .valresultat_lannamn_2026(b$area),
      kommunnamn_2026$kommunnamn[match(b$area, kommunnamn_2026$kommunkod)]))
  raw$valkretskod <- paste0(ifelse(b$valtyp == "RD", b$county, b$area), b$constituency)
  raw$valkretsnamn <- b$constituency_name
  raw$valkretsbeteckning_pa_valsedeln <- b$constituency_name
  # Source status is retained; Definitiv/Utkast is not modern S/B.
  raw$valsedelsstatus <- b$status
  # This historical attribute belongs to each ballot; it need not be
  # constant at the modern party/electoral-area registration scope.
  key <- do.call(paste, c(b[c("area", "county", "constituency", "partikod", "listnummer", "ordning")], sep = "|"))
  raw$kandidatnummer <- unlist(lapply(seq_len(nrow(b)), function(i)
    .xml2006_id(b$valtyp[[i]], "ballot", key[[i]])), use.names = FALSE)
  out <- .xml2006_metadata(parse_kandidaturer_2026(raw, 2006L))
  # Modern S/B uppercasing must not rewrite historical source status values.
  out$valsedelsstatus <- b$status
  out$anmalda_kandidater <- ifelse(b$registered == "Ja", TRUE, ifelse(b$registered == "Nej", FALSE, NA))
  out
}

.xml2006_relations <- function(sources, val, progress = FALSE) {
  if (is.null(val)) val <- c("RD", "RF", "KF")
  parsed <- lapply(val, function(v) {
    purrr::map(.xml2006_files(sources, v), function(file) {
      doc <- .xml2006_appointment_slots(.xml2006_read(sources, file, v), v)
      register <- .xml2006_register(doc, v, sources = sources)
      nodes <- xml2::xml_find_all(doc, ".//*[@KANDNR]")
      lookup <- stats::setNames(xml2::xml_attr(nodes, "NAMN"), xml2::xml_attr(nodes, "KANDNR"))
      out <- .xml2018_valda_ersattare_fil(doc, v, register)
      if (nrow(out$valda)) out$valda$namn <- unname(lookup[out$valda$kandidatnummer])
      if (nrow(out$ersattare)) {
        out$ersattare$ledamot_namn <- unname(lookup[out$ersattare$ledamot_kandidatnummer])
        out$ersattare$ersattare_namn <- unname(lookup[out$ersattare$ersattare_kandidatnummer])
      }
      out
    }, .progress = progress)
  }) |> unlist(recursive = FALSE)
  list(valda = .xml2006_metadata(purrr::map(parsed, "valda") |> purrr::list_rbind()),
    ersattare = .xml2006_metadata(purrr::map(parsed, "ersattare") |> purrr::list_rbind()))
}

.xml2006_preference_rows <- function(nodes, doc, file, val, geo, info,
                                      party_votes, list = NULL) {
  if (inherits(nodes, "xml_document")) nodes <- xml2::xml_find_all(nodes, "/*")
  n <- length(nodes)
  if (!n) return(NULL)
  names <- xml2::xml_attr(nodes, "NAMN")
  names[names %in% c("Namnet gallrat", "Personuppgift borttagen")] <- NA_character_
  counts <- as.integer(xml2::xml_attr(nodes, "PERSONKRYSS"))
  if (anyNA(counts) || any(counts < 0L)) stop("Invalid 2006 preference-vote observation.", call. = FALSE)
  ids <- .xml2006_id(val, if (is.null(list)) "area" else "list",
    paste(file, xml2::xml_path(nodes), sep = "|"))
  out <- tibble::tibble(valtillfalle = rep("Val_2006", n), valar = rep(2006L, n),
    valtyp = rep(val, n), kandidatnummer = ids, namn = names,
    partikod = rep(info$partikod, n), partiforkortning = rep(info$partiforkortning, n),
    partibeteckning = rep(info$partibeteckning, n), geografiniva = rep("personvalsomrade", n),
    personvalsomradeskod = rep(geo$area_code, n), personvalsomradesnamn = rep(geo$area_name, n),
    valomradeskod = rep(geo$valomradeskod, n), valomradesnamn = rep(geo$valomradesnamn, n),
    valkretskod = rep(geo$valkretskod, n), valkretsnamn = rep(geo$valkretsnamn, n),
    antal_personroster = counts, antal_partiroster = rep(party_votes, n),
    andel_personroster = if (!is.na(party_votes) && party_votes > 0L) counts / party_votes else rep(NA_real_, n),
    kvalificerad_personval = if (is.null(list)) dplyr::recode_values(xml2::xml_attr(nodes, "\u00d6VER_SP\u00c4RR"),
      "J" ~ TRUE, "N" ~ FALSE, default = NA) else rep(NA, n),
    rakningstillfalle = rep("slutlig", n), valdatum = rep("2006-09-17", n), test = rep(FALSE, n))
  if (identical(geo$geografiniva, "valdistrikt")) {
    out$geografiniva <- rep("valdistrikt", n)
    for (field in c("valdistriktskod", "valdistriktsnamn", "valdistriktstyp", "kommunkod", "kommunnamn", "lankod", "lannamn")) out[[field]] <- rep(geo[[field]], n)
  }
  if (!is.null(list)) {
    out$listnummer <- rep(.xml2018_attr(list, "LISTNUMMER"), n)
    out$antal_listroster <- rep(.xml2018_int(list, "R\u00d6STER"), n)
    out$andel_personroster_lista <- if (!is.na(out$antal_listroster[[1]]) && out$antal_listroster[[1]] > 0L)
      counts / out$antal_listroster else rep(NA_real_, n)
    # KANDIDAT is a source list position, not a person identifier.
    out$ordning <- as.integer(xml2::xml_attr(nodes, "KANDIDAT"))
  }
  out
}

.xml2006_preference <- function(sources, val, per_lista = FALSE, progress = FALSE, niva = "personvalsomrade") {
  if (is.null(val)) val <- c("RD", "RF", "KF")
  lapply(val, function(v) {
    files <- if (niva == "valdistrikt" && v != "KF") {
      entries <- sources$municipal_sources
      selected <- entries$file[grepl(paste0("^slutresultat_[0-9]{4}", c(RD = "R", RF = "L")[[v]], "[.]xml$"), entries$file)]
      if (length(selected) != (if (v == "RF") 289L else 290L)) stop("Incomplete 2006 district sources.", call. = FALSE)
      paste0("official-final/", sort(selected))
    } else .xml2006_files(sources, v)
    purrr::map(files, function(file) {
      doc <- .xml2006_read(sources, file, v)
      register <- .xml2006_register(doc, v, sources = sources)
      areas <- if (niva == "valdistrikt") .xml2018_noder(doc, "valdistrikt", v) else xml2::xml_find_all(doc, switch(v,
        RD = "./NATION/L\u00c4N/KRETS_RIKSDAG",
        RF = "./NATION/L\u00c4N/KRETS_LANDSTING", KF = "./KOMMUN/KRETS_KOMMUN"))
      purrr::map(areas, function(area) {
        geo <- .xml2006_geography(sources, area, v, if (niva == "valdistrikt") "valdistrikt" else switch(v, RD = "riksdagsvalkrets", RF = "regionvalkrets", KF = "kommunvalkrets"), doc)
        geo$area_code <- .xml2018_attr(area, "KOD")
        geo$area_name <- .xml2018_attr(area, "NAMN")
        if (niva == "valdistrikt") {
          if (v == "KF") {
            parent <- xml2::xml_find_first(area, "ancestor::KRETS_KOMMUN[1]")
            geo$area_code <- .xml2018_attr(parent, "KOD")
            geo$area_name <- .xml2018_attr(parent, "NAMN")
          } else {
            geo$area_code <- geo$valkretskod
            geo$area_name <- geo$valkretsnamn
          }
        }
        if (v == "KF") {
          geo$valkretskod <- geo$kommunvalkretskod
          geo$valkretsnamn <- geo$kommunvalkretsnamn
        }
        purrr::map(xml2::xml_find_all(area, "./GILTIGA[not(@PARTI='\u00d6VR')]"), function(party) {
          info <- .xml2018_parti(.xml2018_attr(party, "PARTI"), v, geo$valomradeskod, register, party, area)
          votes <- .xml2018_int(party, "R\u00d6STER")
          if (!per_lista) return(.xml2006_preference_rows(xml2::xml_find_all(party, "./PERSONVAL"), doc, file, v, geo, info, votes))
          purrr::map(xml2::xml_find_all(party, "./VALSEDEL"), function(list) {
            nodes <- xml2::xml_find_all(list, "./PERSONVAL")
            counts <- as.integer(xml2::xml_attr(nodes, "PERSONKRYSS"))
            if (anyNA(counts) || sum(as.double(counts)) != .xml2018_int(list, "PERSONKRYSS"))
              stop("2006 list candidate counts disagree with the list person-vote total.", call. = FALSE)
            .xml2006_preference_rows(nodes, doc, file, v, geo, info, votes, list)
          }) |> purrr::list_rbind()
        }) |> purrr::list_rbind()
      }) |> purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
}

.xml2006_supplement <- function(sources, val, progress = FALSE) {
  letter <- c(RD = "R", RF = "L", KF = "K")[[val]]
  entries <- sources$sources
  pattern <- paste0("/ovriga_personroster/", letter, "/[0-9/]+/index[.]html$")
  entries <- entries[entries$source_type == "HTML" & grepl(pattern, entries$original_url), ]
  entries$route <- sub(".*/ovriga_personroster/", "", entries$original_url)
  if (val == "RD") {
    entries <- entries[!is.na(entries$archived_url) & nzchar(entries$archived_url), ]
  } else entries <- entries[grepl("^objects/complete-current-other-", entries$file), ]
  if (nrow(entries) != c(RD = 29L, RF = 98L, KF = 394L)[[val]] || anyDuplicated(entries$route))
    stop("Incomplete or ambiguous 2006 supplementary candidate sources.", call. = FALSE)
  purrr::map(.xml2006_files(sources, val), function(file) {
    doc <- .xml2006_read(sources, file, val)
    areas <- xml2::xml_find_all(doc, switch(val,
      RD = "./NATION/L\u00c4N/KRETS_RIKSDAG", RF = "./NATION/L\u00c4N/KRETS_LANDSTING", KF = "./KOMMUN/KRETS_KOMMUN"))
    purrr::map(areas, function(area) {
      geo <- .xml2018_geo(area, val, switch(val, RD = "riksdagsvalkrets", RF = "regionvalkrets", KF = "kommunvalkrets"), doc)
      geo$area_code <- .xml2018_attr(area, "KOD")
      geo$area_name <- .xml2018_attr(area, "NAMN")
      route <- paste0(letter, "/", switch(val,
        RD = substr(geo$area_code, 3L, 4L),
        RF = paste(substr(geo$area_code, 1L, 2L), substr(geo$area_code, 3L, 4L), sep = "/"),
        KF = paste(substr(geo$area_code, 1L, 2L), substr(geo$area_code, 3L, 4L), substr(geo$area_code, 5L, 6L), sep = "/")), "/index.html")
      hit <- match(route, entries$route)
      if (is.na(hit)) stop("Missing 2006 supplementary area: ", route, call. = FALSE)
      entry <- entries[hit, ]
      html <- xml2::read_html(.xml2006_source(sources, entry$file),
        encoding = if (val == "RD") "ISO-8859-1" else "UTF-8", options = "NONET")
      register <- .xml2006_register(doc, val, geo$valomradeskod, sources)
      definitions <- xml2::xml_find_all(doc, "./PARTI")
      party <- NA_character_
      records <- list()
      ordinal <- 0L
      for (row in xml2::xml_find_all(html, ".//tr")) {
        header <- xml2::xml_find_all(row, ".//h3")
        if (length(header)) { party <- trimws(xml2::xml_text(header[[1]])); next }
        cells <- xml2::xml_find_all(row, "./td")
        if (length(cells) != 3L) next
        values <- trimws(xml2::xml_text(cells))
        count <- gsub("[[:space:]\u00a0]", "", values[[2]])
        if (!grepl("^[0-9]+$", count) || !grepl("%", values[[3]], fixed = TRUE)) next
        ordinal <- ordinal + 1L
        aliases <- xml2::xml_attr(definitions, "F\u00d6RKORTNING")[xml2::xml_attr(definitions, "BETECKNING") == party]
        aliases <- unique(aliases[!is.na(aliases)])
        info <- list(partikod = NA_character_, partiforkortning = NA_character_, partibeteckning = party)
        denominator <- NA_integer_
        if (length(aliases) == 1L) {
          candidates <- register$data[register$data$partiforkortning == aliases, ]
          codes <- unique(candidates$partikod)
          if (length(codes) == 1L) info$partikod <- codes
          info$partiforkortning <- if (grepl("^[0-9]+$", aliases)) NA_character_ else aliases
          party_node <- xml2::xml_find_all(area, "./GILTIGA|./GILTIGA/VARAV_\u00d6VRIGA")
          selected <- party_node[xml2::xml_attr(party_node, "PARTI") == aliases]
          if (length(selected) == 1L) denominator <- .xml2018_int(selected[[1]], "R\u00d6STER")
        }
        node <- xml2::read_xml("<PERSONVAL/>")
        xml2::xml_set_attr(node, "NAMN", values[[1]])
        xml2::xml_set_attr(node, "PERSONKRYSS", count)
        if (val == "KF") {
          geo$valkretskod <- geo$kommunvalkretskod
          geo$valkretsnamn <- geo$kommunvalkretsnamn
        }
        record <- .xml2006_preference_rows(node, doc, entry$file, val, geo, info, denominator)
        record$kandidatnummer <- .xml2006_id(val, "supplement", paste(route, ordinal, sep = "|"))
        records[[ordinal]] <- record
      }
      purrr::list_rbind(records)
    }) |> purrr::list_rbind()
  }, .progress = progress) |> purrr::list_rbind()
}

.personroster_2006 <- function(sources, val, niva, per_lista,
                              komplettera_nollor, progress = FALSE) {
  if (!niva %in% c("personvalsomrade", "valdistrikt")) stop("Unsupported 2006 preference-vote level.", call. = FALSE)
  # Only observed source records are published. No unobserved person identity
  # or ballot-to-person linkage can be asserted from an absent name record.
  out <- .xml2006_preference(sources, val, per_lista, progress, niva)
  if (!per_lista && niva == "personvalsomrade") {
    values <- if (is.null(val)) c("RD", "RF", "KF") else val
    out <- dplyr::bind_rows(out, purrr::list_rbind(lapply(values, function(v)
      .xml2006_supplement(sources, v, progress))))
  }
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  out <- .kort_kommunnamn_2026(out)
  if (anyDuplicated(out[c("valtyp", "kandidatnummer", "partikod", "personvalsomradeskod")]))
    stop("Duplicate 2006 source-observation preference-vote key.", call. = FALSE)
  out
}

.xml2006_population <- function(sources, val, progress = FALSE) {
  kd <- .read_candidacies_2006(sources, if (is.null(val)) c("RD", "RF", "KF") else val)
  pref <- .personroster_2006(sources, val, "personvalsomrade", FALSE, FALSE, progress)
  rel <- .xml2006_relations(sources, val, progress)
  evidence <- dplyr::bind_rows(pref, rel$valda,
    dplyr::rename(rel$ersattare, kandidatnummer = "ersattare_kandidatnummer", namn = "ersattare_namn")) |>
    dplyr::distinct(.data$valtyp, .data$partikod, .data$kandidatnummer, .keep_all = TRUE)
  raw <- .xml2006_candidacy_raw(nrow(evidence))
  for (field in intersect(names(raw), names(evidence))) raw[[field]] <- as.character(evidence[[field]])
  extra <- .xml2006_metadata(parse_kandidaturer_2026(raw, 2006L))
  list(kd = kd, population = dplyr::bind_rows(kd, extra), pref = pref, relations = rel)
}

.kandidater_2006 <- function(sources, val, resultat, progress = FALSE, bundle = NULL) {
  if (is.null(bundle)) bundle <- .xml2006_population(sources, val, progress)
  population <- bundle$population
  # Internal inclusion evidence is not a fabricated public validity attribute.
  population$giltig <- rep(TRUE, nrow(population))
  bas <- .kandidater_bas(population, 2006L)
  index <- match(bas$kandidatnummer, population$kandidatnummer)
  bas$namn <- population$namn[index]
  # Counting distinct people/parties/elections is unsupported for these IDs.
  for (field in intersect(c("antal_partier", "flera_partier", "antal_valtyper", "flera_valtyper"), names(bas))) bas[[field]][] <- NA
  if (!resultat) return(bas)
  status <- unique(population[c("valtyp", "valomradeskod", "valomradesnamn")])
  status$valda_available <- rep(FALSE, nrow(status))
  status$personval_available <- rep(FALSE, nrow(status))
  pref <- bundle$pref
  qualified <- unique(pref[pref$kvalificerad_personval %in% TRUE,
    c("kandidatnummer", "valtyp", "partikod", "valomradeskod", "valkretskod")])
  out <- .add_kandidatresultat_fran_parsade_2026(bas, population,
    unique(population$valtyp), list(list(status = status,
      personrostomraden = pref[c("kandidatnummer", "valtyp", "partikod", "antal_personroster")],
      personval = qualified, valda = bundle$relations$valda)))
  index <- match(out$kandidatnummer, pref$kandidatnummer)
  observed <- !is.na(index)
  out$kvalificerad_personval[observed] <- pref$kvalificerad_personval[index[observed]]
  out
}

.valda_2006 <- function(sources, val, progress = FALSE) {
  bundle <- .xml2006_population(sources, val, progress)
  .kandidater_2006(sources, val, TRUE, progress, bundle) |>
    dplyr::filter(.data$invald %in% TRUE) |>
    .valda_invaldsvalkrets_2026() |>
    dplyr::select(-dplyr::any_of("antal_valkretsar"))
}

.ersattare_2006 <- function(sources, val, progress = FALSE) {
  out <- .xml2006_relations(sources, val, progress)$ersattare
  out$partikod[grepl("^source-unresolved:", out$partikod)] <- NA_character_
  .kort_kommunnamn_2026(out)
}
