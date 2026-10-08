test_that("2014 repeated candidate records are added within their own node", {
  doc <- xml2::read_xml(paste0('<VAL><GILTIGA PERSONKRYSS="7">',
    '<PERSONVAL KANDNR="42" PERSONKRYSS="2" NAMN="A"/>',
    '<PERSONVAL KANDNR="42" PERSONKRYSS="3" NAMN="B"/>',
    '<PERSONVAL KANDNR="43" PERSONKRYSS="2"/>',
    '<VALSEDEL><PERSONVAL KANDNR="42" PERSONKRYSS="2"/>',
    '<PERSONVAL KANDNR="42" PERSONKRYSS="3"/></VALSEDEL>',
    '</GILTIGA></VAL>'))
  consolidated <- .xml2014_consolidate_person(doc)
  direct <- xml2::xml_find_all(consolidated, "./GILTIGA/PERSONVAL")
  expect_identical(xml2::xml_attr(direct, "KANDNR"), c("42", "43"))
  expect_identical(xml2::xml_attr(direct, "PERSONKRYSS"), c("5", "2"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(consolidated,
    "./GILTIGA/VALSEDEL/PERSONVAL"), "PERSONKRYSS"), "5")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(consolidated,
    "./GILTIGA"), "PERSONKRYSS"), "7")
})

test_that("2014 consolidation never accepts malformed vote records", {
  for (record in c('<PERSONVAL KANDNR="1" PERSONKRYSS="-1"/>',
    '<PERSONVAL KANDNR="1"/>', '<PERSONVAL PERSONKRYSS="1"/>')) {
    doc <- xml2::read_xml(paste0("<VAL><GILTIGA>", record, "</GILTIGA></VAL>"))
    expect_error(.xml2014_consolidate_person(doc), "Invalid 2014")
  }
})

test_that("2014 presentation numbers preserve zero and missingness", {
  expect_identical(.xml2014_html_number("0"), 0)
  expect_identical(.xml2014_html_number("\u00a0"), NA_real_)
  expect_identical(.xml2014_html_number("-2,5%"), -2.5)
  expect_identical(.xml2014_html_number("1\u00a0234"), 1234)
  expect_error(.xml2014_html_number("unknown"), "Invalid 2014")
})

test_that("2014 source metadata and unfilled seats are normalised in memory", {
  file <- tempfile("slutresultat_", fileext = ".xml")
  on.exit(unlink(file))
  doc <- xml2::read_xml(paste0('<VAL VALDAG="20140914" VALTYP="Kommunfullm&#228;ktigval" ',
    'RAPPORTERING="SLUTLIG R&#214;STR&#196;KNING PRELIMIN&#196;RA RESULTAT" ',
    'FILNAMN="', basename(file), '"><VALD NAMN="Kunde ej utses"/></VAL>'))
  xml2::write_xml(doc, file)
  hash <- unname(tools::md5sum(file))
  out <- .xml2014_file(file, "KF")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(out, "./VALD"), "NAMN"),
    "Kunde inte utses")
  expect_identical(unname(tools::md5sum(file)), hash)
  expect_error(.xml2014_file(file, "RD"), "Invalid 2014 XML metadata")
})

test_that("2014 adapters retain typed historical metadata", {
  out <- .metadata_2014(.valresultat_schema())
  expect_type(out$valar, "integer")
  expect_type(out$valtillfalle, "character")
  expect_type(out$valdatum, "character")
  expect_equal(nrow(out), 0L)
  expect_error(.sources_2014("remote", tempdir()), "preserved local")
})

test_that("2014 population includes result-only votes and original relations", {
  kd <- fixture_kandidaturer()[4L, ] |>
    dplyr::mutate(valtyp = "KF", kandidatnummer = "1", partikod = "0001",
      valomradeskod = "0184", valomradesnamn = "Solna", valkretskod = "00",
      giltig = NA, namn = NA_character_)
  geo <- tibble::tibble(valtyp = "KF", valomradeskod = "0184",
    personvalsomradeskod = "0184", valomradesnamn = "Solna",
    valkretskod = NA_character_, valkretsnamn = NA_character_)
  areas <- list(geo = geo, roster = tibble::tibble(valtyp = "KF",
    valomradeskod = "0184", personvalsomradeskod = "0184", partikod = "0001",
    kandidatnummer = "2", antal_personroster = 7L))
  relations <- list(valda = tibble::tibble(valtyp = "KF", partikod = "0001",
    kandidatnummer = "3", valomradeskod = "0184", valomradesnamn = "Solna",
    valkretskod = NA_character_, valkretsnamn = NA_character_),
    ersattare = tibble::tibble(valtyp = "KF", partikod = "0001",
      ersattare_kandidatnummer = "4", valomradeskod = "0184",
      valomradesnamn = "Solna", valkretskod = NA_character_, valkretsnamn = NA_character_))
  out <- .xml2014_population(kd, areas, relations)
  expect_setequal(out$kandidatnummer, as.character(1:4))
  expect_true(all(is.na(out$namn)))
  expect_true(all(is.na(out$listnummer[out$kandidatnummer != "1"])))
  expect_identical(kd$giltig, NA)
  expect_identical(areas$roster$antal_personroster, 7L)
})

test_that("2014 party codes come from official prefixed list identifiers", {
  doc <- xml2::read_xml(paste0('<VAL><PARTI F\u00d6RKORTNING="M" BETECKNING="Moderaterna"/>',
    '<KOMMUN><GILTIGA PARTI="M"><VALSEDEL LISTNUMMER="0001-01000"/>',
    '<VALSEDEL LISTNUMMER="0001-02000"/><PARTISEDEL LISTNUMMER="0001-90000"/>',
    '</GILTIGA></KOMMUN></VAL>'))
  register <- .xml2014_register(doc, "KF", "0184")
  expect_identical(register$data$partikod, "0001")
  expect_identical(register$data$partiforkortning, "M")
  expect_identical(register$data$valomradeskod, "0184")
})

test_that("2014 KF elected abbreviations come from the elected area's XML", {
  doc <- xml2::read_xml(paste0('<VAL VALDAG="20140914">',
    '<PARTI F\u00d6RKORTNING="M" BETECKNING="Moderaterna"/>',
    '<KOMMUN KOD="0184" NAMN="Solna"><KRETS_KOMMUN KOD="018400" NAMN="Solna">',
    '<GILTIGA PARTI="M"><VALSEDEL LISTNUMMER="0001-01000"/>',
    '<GRUPP_VALDA ORDNING="1"><VALD KANDNR="42" ORDNING="1" GRUND="E"/>',
    '</GRUPP_VALDA></GILTIGA></KRETS_KOMMUN></KOMMUN></VAL>'))
  register <- .xml2014_register(doc, "KF", "0184")
  relation <- .xml2018_valda_ersattare_fil(doc, "KF", register)$valda
  before <- tibble::tibble(valtyp = c("KF", "RD"), partikod = "0001",
    kandidatnummer = c("42", "43"), partiforkortning = c(NA_character_, "M"),
    invald = TRUE, invald_valomradeskod = c("0184", "00"),
    invalsordning = 1L, antal_personroster_totalt = c(7L, 9L))
  local_mocked_bindings(
    .xml2014_bundle = function(...) list(relations = list(valda = relation)),
    .kandidater_2014 = function(...) before,
    .valda_invaldsvalkrets_2026 = function(x) x
  )
  out <- .valda_2014(NULL, c("KF", "RD"), FALSE)
  expect_identical(out$partiforkortning, c("M", "M"))
  expect_identical(out[setdiff(names(out), "partiforkortning")],
                   before[setdiff(names(before), "partiforkortning")])
  expect_identical(relation$partikod, "0001")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, ".//VALSEDEL"),
                                "LISTNUMMER"), "0001-01000")
})

test_that("2014 is supported consistently without a new counting-stage value", {
  for (surface in c("valresultat", "mandat", "kandidaturer", "kandidater",
                    "valda", "ersattare", "personroster"))
    for (val in c("RD", "RF", "KF"))
      expect_true(2014L %in% .stodd_valar(surface, val))
  expect_error(results(2014, count = "election_night"), "count")
  expect_error(seats(2014, count = "preliminary", source = "local"), "final election XML")
  expect_silent(.check_canonical_years("canonical", 2014L))
  expect_error(.canonical_source(2014L, "valresultat", "RD", "riket"), "configured")
})

test_that("2014 preliminary aggregation sums district totals once per district", {
  x <- .valresultat_schema()[rep(NA_integer_, 4L), ]
  x$valtyp <- "KF"
  x$geografiniva <- "valdistrikt"
  x$raknat <- TRUE
  x$valdistriktskod <- rep(c("K-0184-01", "K-0184-02"), each = 2L)
  x$kommunkod <- "0184"; x$kommunnamn <- "Solna"
  x$lankod <- "01"; x$lannamn <- "Stockholm"
  x$partikod <- rep(c("0001", "0002"), 2L)
  x$partiforkortning <- rep(c("A", "B"), 2L)
  x$partibeteckning <- x$partiforkortning; x$ovriga_partier <- FALSE
  x$antal_roster <- c(2L, 3L, 5L, 7L)
  x$giltiga_roster <- c(5L, 5L, 12L, 12L)
  x$antal_roster_fg <- NA_integer_
  out <- .xml2014_aggregate_results(x, "KF", "kommun")
  expect_identical(out$antal_roster, c(7L, 10L))
  expect_identical(out$giltiga_roster, c(17L, 17L))
  expect_true(all(is.na(out$antal_roster_fg)))
  expect_identical(out$valar, c(2014L, 2014L))
  expect_identical(out$valomradeskod, c("0184", "0184"))
})

test_that("historical collection presentation preserves explicit zero and missing history", {
  file <- tempfile(fileext = ".html")
  on.exit(unlink(file), add = TRUE)
  writeLines(paste0('<html><table class="sorteringsbar_tabell">',
    '<tr><td>A</td><td>Parti A</td><td>0</td><td>0,0%</td><td></td><td></td><td></td><td></td></tr>',
    '<tr><td>SUM</td><td>Giltiga r&#246;ster</td><td>0</td><td></td><td></td><td></td><td></td><td></td></tr>',
    '</table></html>'), file)
  doc <- xml2::read_xml('<VAL><KOMMUN KOD="0184" NAMN="Solna"><KRETS_KOMMUN KOD="018400"><ONSDAGSDISTRIKT KOD="K-0184-01" NAMN="Uppsamlingsdistrikt"/></KRETS_KOMMUN></KOMMUN></VAL>')
  node <- xml2::xml_find_first(doc, './/ONSDAGSDISTRIKT')
  register <- .xml2018_reg_index(tibble::tibble(valtyp = "KF", valomradeskod = "0184",
    partiforkortning = "A", partibeteckning = "Parti A", partikod = "0001"))
  out <- .xml2014_collection(file, node, doc, "KF", register)
  expect_identical(out$antal_roster, 0L)
  expect_identical(out$antal_roster_fg, NA_integer_)
  expect_type(out$antal_roster, "integer")
})
test_that("2014 preliminary metadata uses explicit aggregate presentation counts", {
  root <- withr::local_tempdir()
  snapshot <- file.path(root, "valresultat", "preliminary-presentation-fixture")
  dir.create(snapshot, recursive = TRUE)
  file <- file.path(snapshot, "aggregate.html")
  row <- function(label, name, current, previous) paste0("<tr><td>", label,
    "</td><td>", name, "</td><td>", current,
    "</td><td></td><td></td><td></td><td>", previous, "</td><td></td></tr>")
  writeLines(paste0("<html><table class='sorteringsbar_tabell'>",
    row("", "Giltiga r\u00f6ster", 10, 8),
    row("VDT", "Valdeltagande", 12, 10),
    row("", "Antal r\u00f6stber\u00e4ttigade", 20, 16), "</table></html>"), file,
    useBytes = TRUE)
  jsonlite::write_json(list(sources = data.frame(
    url = c("https://historik.val.se/val/val2014/prelresultat/R/rike/index.html",
      "https://historik.val.se/val/val2018/prelresultat/R/rike/index.html"),
    file = c("aggregate.html", "not-a-2014-source.html"),
    md5 = c(unname(tools::md5sum(file)), "excluded-year"))),
    file.path(snapshot, "source-manifest.json"), auto_unbox = TRUE)
  x <- .valresultat_schema()[NA_integer_, ]
  x$geografiniva <- "riket"; x$valtyp <- "RD"
  x$giltiga_roster <- 10L; x$totalt_antal_roster <- 12L; x$antal_roster <- 5L
  out <- .xml2014_preliminary_metadata(x, list(root = root), "RD", "riket")
  expect_identical(out$antal_rostberattigade, 20L)
  expect_identical(out$antal_rostberattigade_raknade, 20L)
  expect_identical(out$antal_rostberattigade_fg, 16L)
  expect_identical(out$totalt_antal_roster_fg, 10L)
  expect_identical(out$giltiga_roster_fg, 8L)
  shares <- .valresultat_public_andelar_2026(out)
  expect_identical(shares$valdel, 12 / 20)
  expect_identical(shares$valdel_fg, 10 / 16)
  expect_identical(out$antal_roster, x$antal_roster)
  x$totalt_antal_roster <- 13L
  expect_error(.xml2014_preliminary_metadata(x, list(root = root), "RD", "riket"),
    "disagrees with official presentation")
  write("changed", file)
  expect_error(.xml2014_preliminary_metadata(out, list(root = root), "RD", "riket"),
    "Changed preliminary metadata")
})
test_that("collection votes do not introduce a second electorate", {
  x <- .valresultat_schema()[rep(NA_integer_, 3L), ]
  x$valdistriktskod <- c("one", "one", "collection")
  x$valdistriktstyp <- c("valdistrikt", "valdistrikt", "uppsamlingsdistrikt")
  x$raknat <- TRUE
  x$antal_rostberattigade <- c(20L, 20L, NA_integer_)
  x$antal_roster <- c(3L, 4L, 2L)
  x$partikod <- c("0001", "0002", "0001")
  out <- .xml2014_aggregate_results(x, "RD", "riket")
  expect_identical(out$antal_rostberattigade, c(20L, 20L))
  expect_identical(out$antal_rostberattigade_raknade, c(20L, 20L))
  expect_identical(out$antal_roster, c(5L, 4L))
  x$antal_rostberattigade[1:2] <- NA_integer_
  expect_true(all(is.na(.xml2014_aggregate_results(x, "RD", "riket")$antal_rostberattigade)))
})
test_that("2014 missing collection turnout nodes do not hide known vote totals", {
  x <- .valresultat_schema()[rep(NA_integer_, 2L), ]
  x$giltiga_roster <- c(449L, 3L); x$ogiltiga_roster <- c(5L, NA_integer_)
  x$giltiga_roster_fg <- c(329L, 1L); x$ogiltiga_roster_fg <- c(2L, NA_integer_)
  out <- .xml2014_known_vote_totals(x)
  expect_identical(out$totalt_antal_roster, c(454L, NA_integer_))
  expect_identical(out$totalt_antal_roster_fg, c(331L, NA_integer_))
  x$totalt_antal_roster[[1]] <- 455L
  expect_error(.xml2014_known_vote_totals(x), "disagree with valid/invalid")
})

test_that("2014 collection invalid totals use the complete BLANK and OG partition", {
  x <- .valresultat_schema()[rep(NA_integer_, 2L), ]
  x$giltiga_roster <- c(236L, 3L)
  x$blanka_roster <- c(8L, 0L); x$ovriga_ogiltiga <- c(1L, NA_integer_)
  out <- .xml2014_known_vote_totals(x)
  expect_identical(out$ogiltiga_roster, c(9L, NA_integer_))
  expect_identical(out$totalt_antal_roster, c(245L, NA_integer_))
  expect_true(all(is.na(out$roster_ej_anmalt_deltagande)))
  x$ogiltiga_roster[[1]] <- 10L
  expect_error(.xml2014_known_vote_totals(x), "blank/other")
})

test_that("2014 public preference views do not leak internal population evidence", {
  x <- tibble::tibble(valtyp = "RD", valomradeskod = "00",
    personvalsomradeskod = "0001", partikod = "0001", kandidatnummer = 1L)
  attr(x, "result_only_keys") <- x["kandidatnummer"]
  x$listnummer <- c(source_node = "000100001")
  local_mocked_bindings(.xml2018_person_public = function(...) x)
  out <- .personroster_2014(NULL, "RD", "personvalsomrade", FALSE, FALSE,
    FALSE, bundle = list(areas = list(), population = x))
  expect_null(attr(out, "result_only_keys"))
  expect_identical(out$kandidatnummer, 1L)
  expect_identical(out$listnummer, "000100001")
})

test_that("mixed 2014 canonical preferences preserve raw global ordering", {
  local_mocked_bindings(
    .select_public_source = function(...) "canonical",
    .canonical_source = function(ar, surface, val, ...) tibble::tibble(
      valar = 2014L, valtyp = val, valomradeskod = "01",
      personvalsomradeskod = "0101", partikod = "1", kandidatnummer = "1")
  )
  out <- personroster(2014L, val = c("RF", "RD"), source = "canonical",
    detaljniva = "full")
  expect_identical(out$valtyp, c("RD", "RF"))
})

test_that("2014 canonical candidate ordering follows the raw population union", {
  root <- withr::local_tempdir()
  path <- file.path(root, "manifest.json"); file.create(path)
  row <- function(val, id) tibble::tibble(valtyp = val, kandidatnummer = id,
    partikod = "0001")
  kd <- dplyr::bind_rows(row("RD", "1"), row("RF", "2"))
  observed <- list(RD = row("RD", "3"), RF = row("RF", "4"))
  candidates <- purrr::list_rbind(c(list(kd), observed))
  substitutes <- dplyr::rename(kd, ersattare_kandidatnummer = "kandidatnummer")
  data <- list(candidacies = kd, candidates = candidates,
    `candidate-population` = candidates, elected = kd, substitutes = substitutes,
    `preference-votes-base-area-rd` = observed$RD,
    `preference-votes-base-area-rf` = observed$RF)
  names(data) <- paste0("rkl2014-", names(data))
  assets <- data.frame(asset = names(data), file = paste0(names(data), ".parquet"))
  file.create(file.path(root, assets$file))
  withr::local_options(swelections.canonical_assets_dir = root)
  local_mocked_bindings(
    .canonical_manifest = function(...) list(valar = 2014L, schema_version = 2L,
      format = "parquet", valserie = "rkl", assets = assets),
    .canonical_asset = function(manifest, asset, ...) .canonical_names_en(data[[asset]]),
    .canonical_table = function(manifest, x, ...) .canonical_names_sv(x)
  )
  call <- function(surface) .canonical_2014_source(path, surface, c("RF", "RD"),
    NULL, FALSE, FALSE, TRUE, "slutlig")
  expect_identical(call("kandidaturer")$valtyp, c("RF", "RD"))
  expect_identical(call("ersattare")$valtyp, c("RF", "RD"))
  expect_identical(call("kandidater")$kandidatnummer, c("2", "1", "4", "3"))
  expect_identical(call("valda")$kandidatnummer, c("2", "1"))
})
