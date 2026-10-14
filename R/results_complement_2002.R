# Complementary final RD votes only; never used by candidate/preference readers.
.rd2002_complement_scope <- function() {
  data.frame(municipality = c("1380", "1381", "1384"), ordinary = c(49L, 15L, 37L), collection = 1L)
}
.rd2002_complement_sources <- function(sources) {
  x <- data.frame(file = c("scb/valres_parti_valdistr2002_ri.dta", "snd/snd0237-10-3.zip"),
    provider = c("SCB-derived district-party data", "SND RD 0237-010 version 2.1"),
    bytes = c(37361804, 4136329),
    md5 = c("4d914f7a4b6ed159dc0736df8b94be27", "ac27fa12700498899791abb58290596f"),
    sha256 = c("e834e5de6a9befe93be2183ca05f991c5758c8832b1de56b1031a5fc2365f730",
      "47a4b1288efa238d5bc90149ff8d9e387d504484a0da37ada78f2b1e84b607d6"))
  for (i in seq_len(nrow(x))) {
    path <- file.path(sources$root, x$file[i])
    if (!file.exists(path) || file.info(path)$size != x$bytes[i] ||
        unname(tools::md5sum(path)) != x$md5[i] || .canonical_sha256(path) != x$sha256[i])
      stop("Missing or changed complementary 2002 source: ", x$file[i], call. = FALSE)
  }
  x
}
.rd2002_result_coverage <- function(sources) {
  national <- .xml2002_read(sources, "slutresultat_00R.xml", "RD")
  codes <- xml2::xml_attr(xml2::xml_find_all(national, "./NATION/L\u00c4N/KRETS_RIKSDAG/KOMMUN"), "KOD")
  files <- sort(sources$sources$export[grepl("^slutresultat_[0-9]{4}R[.]xml$", sources$sources$export)])
  wanted <- paste0("slutresultat_", codes, "R.xml"); missing <- codes[!wanted %in% files]
  if (length(codes) != 290L || anyDuplicated(codes) || any(!files %in% wanted) ||
      any(!missing %in% .rd2002_complement_scope()$municipality))
    stop("Incomplete 2002 RD result coverage outside the verified complementary scope.", call. = FALSE)
  list(files = files, missing = missing)
}
.rd2002_party_aliases <- function() {
  c("0001" = "M", "0004" = "C", "0003" = "FP", "0068" = "KD", "0055" = "MP",
    "0002" = "S", "0005" = "V", "0029" = "EAP", "0069" = "KOMM", "0074" = "SOC.P",
    "0091" = "NYF", "0110" = "SD", "0107" = "SPI", "0189" = "ENH", "0244" = "NBP",
    "0365" = "0365", "0367" = "0367", "9997" = "\u00d6VR")
}
.rd2002_reconcile <- function(votes, totals, municipality) {
  fail <- function() stop("Complementary 2002 RD votes do not reconcile with Valmyndigheten: ",
    .xml2018_attr(municipality, "KOD"), ".", call. = FALSE)
  major <- c("0001", "0004", "0003", "0068", "0055", "0002", "0005")
  aliases <- .rd2002_party_aliases()
  if (anyNA(totals[c("district", "giltiga", "ogiltiga", "rostande", "tot", "m", "c", "fp", "kd", "mp", "s", "v", "vvr")]) || anyNA(votes[c("llkkdddd", "partikod", "antrost")]) || any(votes$antrost < 0 | votes$antrost != floor(votes$antrost)) ||
      anyDuplicated(votes[c("llkkdddd", "partikod")]) ||
      !setequal(unique(votes$llkkdddd), totals$district) || anyDuplicated(totals$district)) fail()
  for (i in seq_len(nrow(totals))) {
    x <- votes[votes$llkkdddd == totals$district[i], ]
    valid <- sum(x$antrost[x$partikod != "9999"]); invalid <- sum(x$antrost[x$partikod == "9999"])
    expected <- as.double(unlist(totals[i, c("giltiga", "ogiltiga", "rostande")]))
    if (anyNA(expected) || !identical(c(valid, invalid, valid + invalid), expected)) fail()
    for (j in seq_along(major)) {
      count <- x$antrost[x$partikod == major[j]]
      if (length(count) != 1L || count != totals[[c("m", "c", "fp", "kd", "mp", "s", "v")[j]]][i]) fail()
    }
    if (sum(x$antrost[!x$partikod %in% c(major, "9999")]) != totals$vvr[i]) fail()
  }
  value <- function(node) .xml2018_int(node, "R\u00d6STER")
  for (party in xml2::xml_find_all(municipality, "./GILTIGA|./GILTIGA/VARAV_\u00d6VRIGA")) {
    alias <- .xml2018_attr(party, "PARTI")
    parent_other <- alias == "\u00d6VR" && xml2::xml_name(xml2::xml_parent(party)) == "KOMMUN"
    code <- if (grepl("^[0-9]{4}$", alias)) alias else names(aliases)[aliases == alias]
    count <- if (parent_other) sum(votes$antrost[!votes$partikod %in% c(major, "9999")]) else
      if (length(code) == 1L) sum(votes$antrost[votes$partikod == code]) else NA_real_
    if (is.na(count) || is.na(value(party)) || count != value(party)) fail()
  }
  if (sum(totals$giltiga) != value(municipality) ||
      sum(totals$ogiltiga) != value(xml2::xml_find_first(municipality, "./OGILTIGA[@TEXT='OG']")) ||
      sum(totals$rostande) != .xml2018_int(xml2::xml_find_first(municipality, "./VALDELTAGANDE"), "SUMMA_R\u00d6STER")) fail()
  invisible(TRUE)
}
.rd2002_complement <- function(sources, municipalities) {
  entries <- .rd2002_complement_sources(sources)
  if (!requireNamespace("haven", quietly = TRUE))
    stop("Complementary local 2002 RD results require the optional package 'haven'.", call. = FALSE)
  cache <- get0("rd-complement-2002", sources$cache, inherits = FALSE)
  if (!is.null(cache) && all(municipalities %in% names(cache))) return(cache[municipalities])
  x <- haven::read_dta(file.path(sources$root, entries$file[1]))
  member <- "snd0237-10-3/data/Svenska valdata_Riksdagsvalet 2002.v2_1.sav"
  td <- tempfile("swelections-2002-"); dir.create(td)
  resolved <- normalizePath(td, winslash = "/", mustWork = TRUE)
  if (!startsWith(resolved, paste0(normalizePath(tempdir(), winslash = "/"), "/")))
    stop("Unexpected temporary extraction path.", call. = FALSE)
  on.exit(unlink(resolved, recursive = TRUE), add = TRUE)
  file <- utils::unzip(file.path(sources$root, entries$file[2]), files = member, exdir = resolved)
  if (length(file) != 1L) stop("Missing verified SND RD member.", call. = FALSE)
  snd <- haven::read_sav(file); snd[] <- lapply(snd, haven::zap_labels)
  national <- .xml2002_read(sources, "slutresultat_00R.xml", "RD")
  scope <- .rd2002_complement_scope()
  out <- lapply(municipalities, function(code) {
    v <- x[x$llkk == code, ]; t <- snd[as.character(snd$llkkff) == code, ]
    t$district <- as.character(t$llkkffdd); collection <- t$district == "99999997"
    t$district[collection] <- paste0(code, "9800"); expected <- scope[scope$municipality == code, ]
    if (nrow(expected) != 1L || sum(collection) != expected$collection || sum(!collection) != expected$ordinary)
      stop("Incomplete complementary district coverage: ", code, call. = FALSE)
    mun <- xml2::xml_find_first(national, paste0(".//KOMMUN[@KOD='", code, "']"))
    .rd2002_reconcile(v, t, mun)
    geometry_file <- paste0("slutresultat_", code, "K.xml")
    geometry <- .xml2002_read(sources, geometry_file, "KF")
    districts <- xml2::xml_find_all(geometry, "./KOMMUN/KRETS_KOMMUN/VALDISTRIKT")
    keys <- xml2::xml_attr(districts, "KOD")
    if (anyDuplicated(keys) || !setequal(keys, t$district[!collection]))
      stop("Complementary 2002 district geography differs from Valmyndigheten: ", code, call. = FALSE)
    parents <- xml2::xml_find_first(districts, "parent::*"); j <- match(t$district, keys)
    t$municipal_constituency <- xml2::xml_attr(parents, "KOD")[j]
    t$municipal_constituency_name <- xml2::xml_attr(parents, "NAMN")[j]
    t$collection <- collection; t$district_name <- v$vdnamn[match(t$district, v$llkkdddd)]
    region <- xml2::xml_find_first(mun, "ancestor::KRETS_RIKSDAG[1]")
    county <- xml2::xml_find_first(mun, "ancestor::L\u00c4N[1]")
    list(votes = v, totals = t, municipality = code, municipality_name = .xml2018_attr(mun, "NAMN"),
      county = .xml2018_attr(county, "KOD"), county_name = .xml2018_attr(county, "NAMN"),
      constituency = .xml2018_attr(region, "KOD"), constituency_name = .xml2018_attr(region, "NAMN"),
      provenance = list(reason = "Missing Valmyndigheten RD municipal export",
        missing_export = paste0("slutresultat_", code, "R.xml"), sources = entries,
        authoritative_result = sources$sources[sources$sources$export == "slutresultat_00R.xml", ],
        snd_member = member, snd_member_sha256 = .canonical_sha256(file),
        geography = sources$sources[sources$sources$export == geometry_file, ],
        reconciliation = "All municipal party, valid, invalid and cast counts match national Valmyndigheten XML; SND controls every district",
        ordinary = expected$ordinary, collection = expected$collection,
        scb_collection_code = paste0(code, "9800"), snd_collection_code = "99999997",
        source_eligible_voters = sum(t$tot),
        valmyndigheten_eligible_voters = .xml2018_int(xml2::xml_find_first(mun, "./VALDELTAGANDE"), "R\u00d6STBER\u00c4TTIGADE")))
  })
  names(out) <- municipalities; assign("rd-complement-2002", out, sources$cache); out
}
.rd2002_complement_rows <- function(bundle, niva) {
  units <- if (niva == "valdistrikt") bundle$totals$district else
    unique(bundle$totals$municipal_constituency[!bundle$totals$collection &
      !grepl("00$", bundle$totals$municipal_constituency)])
  if (!length(units)) return(.valresultat_schema())
  purrr::map(units, function(unit) {
    t <- bundle$totals[if (niva == "valdistrikt") bundle$totals$district == unit else
      !is.na(bundle$totals$municipal_constituency) & bundle$totals$municipal_constituency == unit, ]
    x <- bundle$votes[bundle$votes$llkkdddd %in% t$district & bundle$votes$partikod != "9999", ]
    x <- x |> dplyr::group_by(.data$partikod, .data$partinamn) |>
      dplyr::summarise(antrost = as.integer(sum(.data$antrost)), .groups = "drop")
    out <- .valresultat_schema()[rep(NA_integer_, nrow(x)), , drop = FALSE]
    out$valtyp <- "RD"; out$rakningstillfalle <- "slutlig"; out$geografiniva <- niva
    out$kommunkod <- bundle$municipality; out$kommunnamn <- bundle$municipality_name
    out$lankod <- bundle$county; out$lannamn <- bundle$county_name
    out$valomradeskod <- "00"; out$valomradesnamn <- "Sverige"
    out$valkretskod <- bundle$constituency; out$valkretsnamn <- bundle$constituency_name
    out$kommunvalkretskod <- if (niva == "valdistrikt") t$municipal_constituency[1] else unit
    out$kommunvalkretsnamn <- t$municipal_constituency_name[1]
    if (!is.na(out$kommunvalkretskod[1]) && endsWith(out$kommunvalkretskod[1], "00")) {
      out$kommunvalkretskod[] <- NA_character_; out$kommunvalkretsnamn[] <- NA_character_
    }
    if (niva == "valdistrikt") {
      out$valdistriktskod <- unit; out$valdistriktsnamn <- t$district_name[1]
      out$valdistriktstyp <- if (t$collection[1]) "uppsamlingsdistrikt" else "valdistrikt"
      out$raknat <- TRUE
    }
    out$antal_roster <- x$antrost; out$partikod <- x$partikod; out$partibeteckning <- x$partinamn
    out$partiforkortning <- unname(.rd2002_party_aliases()[x$partikod])
    out$partiforkortning[grepl("^[0-9]{4}$", out$partiforkortning)] <- NA_character_
    out$ovriga_partier <- x$partikod == "9997"
    out$partikod[out$ovriga_partier] <- NA_character_; out$partiforkortning[out$ovriga_partier] <- NA_character_
    out$giltiga_roster <- as.integer(sum(t$giltiga)); out$ogiltiga_roster <- as.integer(sum(t$ogiltiga))
    out$totalt_antal_roster <- as.integer(sum(t$rostande))
    out$antal_rostberattigade <- as.integer(sum(t$tot))
    out$antal_rostberattigade_raknade <- out$antal_rostberattigade
    out
  }) |> purrr::list_rbind()
}
