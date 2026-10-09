test_that("2010 ZIP metadata distinguishes night from final without changing raw data", {
  archive <- test_path("fixtures", "2010", "metadata-fixture.zip")
  f <- "slutresultat_00R.xml"
  hash <- unname(tools::md5sum(archive))
  member <- structure(basename(f), zip = archive)
  expect_s3_class(.xml2010_file(member, "RD"), "xml_document")
  expect_error(.xml2010_file(member, "RD", night = TRUE), "metadata")
  expect_error(.xml2010_file(member, "RF"), "metadata")
  expect_identical(unname(tools::md5sum(archive)), hash)
})

test_that("historical metadata uses the requested year with stable types", {
  x <- tibble::tibble(valtillfalle = "old", valar = 0L, valdatum = "old")
  expect_identical(.metadata_2014(x, 2010L), tibble::tibble(
    valtillfalle = "Val_2010", valar = 2010L, valdatum = "2010-09-19"))
  expect_identical(.metadata_2014(x)$valar, 2014L)
  expect_identical(.historical_year(list()), 2014L)
})

test_that("2010 uses the existing seven-function year model without a night stage", {
  for (surface in c("valresultat", "mandat", "kandidaturer", "kandidater",
    "valda", "ersattare", "personroster")) {
    for (v in c("RD", "RF", "KF")) expect_true(2010L %in% .stodd_valar(surface, v))
  }
  expect_error(valresultat(2010, val = "RD", rakning = "election_night", source = "local"))
  expect_error(mandat(2010, val = "RD", rakning = "preliminar", source = "local"), "final")
})

test_that("2010 remote requests cannot silently use a different historical source", {
  expect_error(.sources_2010("remote", tempdir()), "preserved local")
  expect_error(.sources_2010("local", tempdir(), archive = TRUE), "update/archive")
})

test_that("an empty result-only population retains ballot column types", {
  kd <- fixture_kandidaturer()[4L, ] |>
    dplyr::mutate(valtyp = "KF", kandidatnummer = "1", partikod = "0001",
      valomradeskod = "0184", valomradesnamn = "Solna", valkretskod = "00")
  geo <- tibble::tibble(valtyp = "KF", valomradeskod = "0184",
    personvalsomradeskod = "0184", valkretskod = NA_character_, valkretsnamn = NA_character_)
  votes <- tibble::tibble(valtyp = "KF", valomradeskod = "0184",
    personvalsomradeskod = "0184", partikod = "0001", kandidatnummer = "1")
  relation <- tibble::tibble(valtyp = "KF", partikod = "0001", kandidatnummer = "1",
    valomradeskod = "0184", valkretskod = NA_character_)
  out <- .xml2014_population(kd, list(geo = geo, roster = votes), list(valda = relation,
    ersattare = dplyr::rename(relation, ersattare_kandidatnummer = "kandidatnummer")), 2010L)
  expect_identical(out$kandidatnummer, "1")
  expect_type(out$valkretskod, "character")
  expect_equal(nrow(out), nrow(kd))
})

test_that("2010 comparison-only parties use scoped official identity metadata", {
  root <- tempfile(); dir.create(root)
  folder <- file.path(root, "kandidater", "official-party-identifiers")
  dir.create(folder, recursive = TRUE)
  writeLines('valtyp,valomradeskod,partibeteckning,partikod\nKF,0191,Old party,0340',
    file.path(folder, "previous-election-2006.csv"))
  doc <- xml2::read_xml('<VAL><PARTI FÖRKORTNING="ASK" BETECKNING="Old party"/><KOMMUN KOD="0191"><GILTIGA PARTI="ASK" RÖSTER="0" RÖSTER_FGVAL="439"/></KOMMUN></VAL>')
  local_mocked_bindings(.xml2010_members = function(...) list("fixture"),
    .xml2010_file = function(...) doc)
  sources <- list(root = root, registers = new.env(parent = emptyenv()))
  register <- .xml2010_register_all(sources, "KF")
  expect_identical(.xml2018_parti("ASK", "KF", "0191", register)$partikod, "0340")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, ".//GILTIGA"), "RÖSTER"), "0")
})

test_that("unobserved 2010 ballots use UTF-8 official party registration in their municipality", {
  root <- tempfile(); dir.create(file.path(root, "kandidater"), recursive = TRUE)
  ballot <- "K;12;Skåne län;80;Malmö;00;Malmö;Kommunisterna;Skickad;1751;1;42;Research name;40;M;Teacher"
  writeLines(iconv(ballot, "UTF-8", "ISO-8859-1"),
    file.path(root, "kandidater", "alkandur_K.skv"), useBytes = TRUE)
  writeLines("Valtyp\tValomrade\tPartikod\tPartibeteckning\nK\tMalmö\t672\tKommunisterna\nK\tGällivare\t509\tKommunisterna",
    file.path(root, "kandidater", "partier_som_anmalt_kandidater.txt"), useBytes = TRUE)
  mapping <- tibble::tibble(valtyp = character(), listnummer = character(), partikod = character())
  register <- .xml2018_reg_index(tibble::tibble(valtyp = character(), valomradeskod = character(),
    partibeteckning = character(), partiforkortning = character(), partikod = character()))
  cache <- new.env(parent = emptyenv()); cache$list_mapping <- mapping
  local_mocked_bindings(.xml2010_register_all = function(...) register)
  out <- .read_candidacies_2010(list(root = root, registers = cache), "KF")
  expect_identical(out$partikod, "0672")
  expect_identical(out$kandidatnummer, "42")
  expect_true(all(is.na(out$namn)))
  expect_identical(out$listnummer, "01751")
  expect_identical(out$valar, 2010L)
})

test_that("2010 same-name municipal parties retain distinct geographic source identities", {
  root <- tempfile(); folder <- file.path(root, "kandidater", "official-party-identifiers")
  dir.create(folder, recursive = TRUE)
  writeLines(c("valtyp,valomradeskod,partibeteckning,partikod",
    "KF,2510,Alternativet,0200", "KF,2161,Frihetliga Kommunalfolket,0533"),
    file.path(folder, "previous-election-2006.csv"))
  party <- function(alias, label, code = NULL) paste0('<PARTI FÖRKORTNING="', alias,
    '" BETECKNING="', label, '"/><GILTIGA PARTI="', alias,
    '" RÖSTER="0">', if (is.null(code)) "" else paste0('<VALSEDEL LISTNUMMER="', code,
      '-00001"/>'), '</GILTIGA>')
  docs <- list(
    nation = xml2::read_xml(paste0('<VAL><NATION KOD="00"/>',
      party("ALT", "Alternativet"), party("ALTER", "Alternativet"),
      party("FKL", "Frihetliga Kommunalfolket"), party("FRK", "Frihetliga Kommunalfolket"), '</VAL>')),
    a = xml2::read_xml(paste0('<VAL><KOMMUN KOD="0781"/>', party("ALTER", "Alternativet", "0510"), '</VAL>')),
    b = xml2::read_xml(paste0('<VAL><KOMMUN KOD="2510"/>', party("ALT", "Alternativet"), '</VAL>')),
    c = xml2::read_xml(paste0('<VAL><KOMMUN KOD="2039"/>', party("FRK", "Frihetliga Kommunalfolket", "0079"), '</VAL>')),
    d = xml2::read_xml(paste0('<VAL><KOMMUN KOD="2161"/>', party("FKL", "Frihetliga Kommunalfolket"), '</VAL>')))
  local_mocked_bindings(.xml2010_members = function(sources, val, niva, ...) {
    if (val != "KF") return(list())
    as.list(if (niva == "riket") "nation" else c("a", "b", "c", "d"))
  }, .xml2010_file = function(file, ...) docs[[file]])
  reg <- .xml2010_register_all(list(root = root, registers = new.env(parent = emptyenv())), "KF")
  for (area in c("00", "2510")) expect_identical(.xml2018_parti("ALT", "KF", area, reg)$partikod, "0200")
  for (area in c("00", "2161")) expect_identical(.xml2018_parti("FKL", "KF", area, reg)$partikod, "0533")
  expect_identical(.xml2018_parti("ALTER", "KF", "00", reg)$partikod, "0510")
  expect_identical(.xml2018_parti("FRK", "KF", "00", reg)$partikod, "0079")
})

test_that("configured 2010 candidate assets use the requested year prefix", {
  root <- tempfile(); dir.create(root)
  path <- file.path(root, "manifest.json"); writeLines("{}", path)
  asset <- "rkl2010-candidacies"
  writeLines("fixture", file.path(root, paste0(asset, ".parquet")))
  data <- fixture_kandidaturer() |> dplyr::mutate(valar = 2010L)
  local_mocked_bindings(.canonical_manifest = function(...) list(valar = 2010L,
    schema_version = 2L, format = "parquet", valserie = "rkl",
    assets = data.frame(asset = asset, file = paste0(asset, ".parquet"))),
    .canonical_asset = function(manifest, requested, ...) {
      expect_identical(requested, asset)
      .canonical_names_en(data)
    })
  out <- .canonical_2014_source(path, "kandidaturer", "RD", NULL,
    FALSE, FALSE, TRUE, "slutlig", ar = 2010L)
  expect_identical(out, dplyr::filter(data, .data$valtyp == "RD"))
})
