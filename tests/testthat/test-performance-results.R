test_that("batched result field classification retains scalar validation", {
  expect_null(.valresultat_values(list(
    namn = 'Area', partikod = '0010', test = FALSE, antalRoster = 0L,
    ordningsnummer = .Machine$integer.max, andelRoster = 0, valdeltagande = 1,
    blankaRoster = list(), namnValkrets = NULL, unknown = list(anything = Inf))))
  for (field in c('namn', 'partikod', 'kommunvalkretsKod'))
    expect_error(.valresultat_values(stats::setNames(list(1L), field)), field)
  for (value in list(1L, 'TRUE', NA_real_))
    expect_error(.valresultat_values(list(test = value)), 'test')
  for (field in c('antalRoster', 'ordningsnummer', 'forandringAntalRoster'))
    for (value in list(1.5, Inf, NA_real_, 2147483648, '2', c(1L, 2L)))
      expect_error(.valresultat_values(stats::setNames(list(value), field)), field)
  for (field in c('andelRoster', 'valdeltagande', 'valkretssparrProcent'))
    for (value in list(Inf, NaN, NA_real_, '0.1', numeric()))
      expect_error(.valresultat_values(stats::setNames(list(value), field)), field)
  expect_error(.valresultat_values(list(antalRoster = 'bad', test = 1L)), 'antalRoster')
  expect_null(.valresultat_values(list(antalRoster = NULL, test = NULL)))
  expect_null(.valresultat_values(list(1L, 'unclassified unnamed value')))
  # The surrounding object validator rejects duplicate keys. Keep this helper's
  # original named lookup too, rather than changing it to positional lookup.
  expect_null(.valresultat_values(stats::setNames(list(0L, 'ignored'), c('antalRoster', 'antalRoster'))))
})
test_that("EU result and geography readers avoid repeated namespace discovery", {
  doc <- xml2::read_xml(paste0(
    '<VAL><NATION KOD="00"><L\u00c4N KOD="01"><KOMMUN KOD="0180" NAMN="Stockholm">',
    '<KRETS_KOMMUN KOD="018001" NAMN="Krets 1"><VALDISTRIKT KOD="01800001" NAMN="Distrikt" R\u00d6STER="3">',
    '<VALDELTAGANDE SUMMA_R\u00d6STER="4"/><GILTIGA PARTI="A" R\u00d6STER="3"/>',
    '<OGILTIGA TEXT="BLANK" R\u00d6STER="1"/><OGILTIGA TEXT="OGEJ" R\u00d6STER="0"/>',
    '<OGILTIGA TEXT="OG" R\u00d6STER="0"/>',
    '</VALDISTRIKT></KRETS_KOMMUN></KOMMUN></L\u00c4N></NATION></VAL>'))
  node <- .xml2018_find_first(doc, './/VALDISTRIKT')
  reg <- .xml2018_reg_index(tibble::tibble(valtyp = 'E', valomradeskod = '00',
    partiforkortning = 'A', partibeteckning = 'Parti A', partikod = '0001'))
  local_mocked_bindings(xml_ns = function(...) stop('unexpected namespace scan'), .package = 'xml2')
  geo <- .eu2019_geo(node, 'valdistrikt')
  expect_identical(geo$kommunkod, '0180')
  expect_identical(geo$kommunvalkretskod, '018001')
  expect_identical(geo$valdistriktskod, '01800001')
  for (year in c(2014L, 2019L)) {
    out <- if (year == 2014L) .eu2014_result_node(node, doc, 'valdistrikt', reg) else
      .eu2019_result_node(node, doc, 'valdistrikt', reg, 'slutlig')
    expect_identical(out$antal_roster, 3L)
    expect_identical(out$giltiga_roster, 3L)
    expect_identical(out$ogiltiga_roster, 1L)
    expect_identical(out$totalt_antal_roster, 4L)
    expect_identical(out$partikod, '0001')
    expect_identical(out$valdistriktskod, '01800001')
  }
})

test_that("EU result readers reuse an immutable request-local schema through adapters", {
  doc <- xml2::read_xml(paste0(
    '<VAL><NATION KOD="00" NAMN="Sverige" R\u00d6STER="5">',
    '<GILTIGA PARTI="A" R\u00d6STER="3"/><GILTIGA PARTI="B" R\u00d6STER="0"/>',
    '<\u00d6VRIGA_GILTIGA><HANDSKRIVNA R\u00d6STER="2"/></\u00d6VRIGA_GILTIGA>',
    '<OGILTIGA TEXT="BLANK" R\u00d6STER="1"/><OGILTIGA TEXT="OGEJ" R\u00d6STER="0"/>',
    '<OGILTIGA TEXT="OG" R\u00d6STER="1"/></NATION></VAL>'))
  node <- .xml2018_find_first(doc, './NATION')
  reg <- .xml2018_reg_index(tibble::tibble(valtyp = 'E', valomradeskod = '00',
    partiforkortning = c('A', 'B'), partibeteckning = c('Alpha', 'Beta'),
    partikod = c('0001', '0002')))
  schema <- .valresultat_schema()
  untouched <- schema
  readers <- list(
    function(s) .eu2004_result_node(node, doc, 'riket', reg, s),
    function(s) .eu2014_result_node(node, doc, 'riket', reg, s),
    function(s) .eu2019_result_node(node, doc, 'riket', reg, 'slutlig', s))
  expected <- list(.eu2004_result_node(node, doc, 'riket', reg),
    .eu2014_result_node(node, doc, 'riket', reg),
    .eu2019_result_node(node, doc, 'riket', reg, 'slutlig'))
  local_mocked_bindings(.valresultat_schema = function() stop('unexpected schema rebuild'))
  for (i in seq_along(readers)) {
    out <- readers[[i]](schema)
    expect_identical(out, expected[[i]])
    expect_identical(out$antal_roster, c(3L, 0L, 2L))
    expect_true(all(is.na(out$antal_rostberattigade)))
    expect_identical(schema, untouched)
    out$antal_roster[1] <- 99L
    expect_identical(readers[[i]](schema), expected[[i]])
  }
  xml2::xml_set_attr(node, 'R\u00d6STER', '6')
  for (reader in readers)
    expect_error(reader(schema), 'party/valid totals disagree')
})

test_that("preliminary EU schema reuse preserves aggregated other parties and missingness", {
  doc <- xml2::read_xml(paste0('<VAL><NATION KOD="00" R\u00d6STER="5">',
    '<GILTIGA PARTI="A" R\u00d6STER="3"/><\u00d6VRIGA_GILTIGA R\u00d6STER="2"/>',
    '<OGILTIGA TEXT="BLANK" R\u00d6STER="1"/><OGILTIGA TEXT="OGEJ" R\u00d6STER="0"/>',
    '<OGILTIGA TEXT="OG" R\u00d6STER="0"/></NATION></VAL>'))
  node <- .xml2018_find_first(doc, './NATION')
  reg <- .xml2018_reg_index(tibble::tibble(valtyp = 'E', valomradeskod = '00',
    partiforkortning = 'A', partibeteckning = 'Alpha', partikod = '0001'))
  schema <- .valresultat_schema()
  expected <- .eu2019_result_node(node, doc, 'riket', reg, 'preliminar')
  local_mocked_bindings(.valresultat_schema = function() stop('unexpected schema rebuild'))
  actual <- .eu2019_result_node(node, doc, 'riket', reg, 'preliminar', schema)
  expect_identical(actual, expected)
  expect_identical(actual$ovriga_partier, c(FALSE, TRUE))
  expect_true(is.na(actual$partikod[2]))
  expect_identical(actual$antal_roster, c(3L, 2L))
  expect_identical(actual$roster_ej_anmalt_deltagande, c(0L, 0L))
  expect_true(all(is.na(actual$antal_rostberattigade)))
})
