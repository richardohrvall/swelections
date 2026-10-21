test_that("historical XML access preserves namespace semantics and node order", {
  doc <- xml2::read_xml(paste0(
    '<ROOT xmlns:p="urn:party"><ROW ID="01" p:label="A"><VALUE>0</VALUE></ROW>',
    '<ROW ID="02"><VALUE>3</VALUE></ROW><p:ROW ID="03"/></ROOT>'))
  for (path in c('./ROW', './ROW/VALUE', './ROW|./p:ROW',
                 './p:ROW', 'ancestor-or-self::ROOT', './missing')) {
    expect_identical(xml2::xml_path(.xml2018_find_all(doc, path)),
                     xml2::xml_path(xml2::xml_find_all(doc, path)), info = path)
    expect_identical(xml2::xml_path(.xml2018_find_first(doc, path)),
                     xml2::xml_path(xml2::xml_find_first(doc, path)), info = path)
  }
  rows <- .xml2018_find_all(doc, './ROW')
  expect_identical(xml2::xml_path(.xml2018_find_all(rows, './VALUE', flatten = TRUE)),
                   xml2::xml_path(xml2::xml_find_all(rows, './VALUE', flatten = TRUE)))
  expect_length(.xml2018_query_ns(doc, 'ancestor-or-self::ROOT'), 0L)
  expect_length(.xml2018_query_ns(doc, './ROW/@ID'), 0L)
  expect_identical(.xml2018_query_ns(doc, './p:ROW'), xml2::xml_ns(doc))
  expect_identical(xml2::xml_attr(rows, 'ID'), c('01', '02'))
  expect_identical(.xml2018_attr(rows[[1]], 'p:label'), NA_character_)

  default <- xml2::read_xml('<ROOT xmlns="urn:default"><ROW ID="1"/></ROOT>')
  expect_identical(length(.xml2018_find_all(default, './ROW')),
                   length(xml2::xml_find_all(default, './ROW')))
  expect_identical(xml2::xml_attr(xml2::xml_root(default), 'ID'), NA_character_)
})

test_that("stored 2018 candidate summaries preserve selection-dependent fields", {
  kd <- fixture_kandidaturer() |>
    dplyr::mutate(oppen_lista = TRUE, pa_namnvalsedel = TRUE)
  rf <- kd[1, ]
  rf$valtyp <- "RF"
  kd <- dplyr::bind_rows(kd, rf)
  stored <- .kandidater_bas(kd, 2018L)
  stored$result_marker <- seq_len(nrow(stored))
  stored <- stored[rev(seq_len(nrow(stored))), ]
  encode <- function(x) paste(x$kandidatnummer, x$valtyp, x$partikod, sep = "\r")
  for (selection in list("RD", "RF", "KF", c("KF", "RF"), c("RF", "RD", "KF"))) {
    selected <- dplyr::filter(kd, .data$valtyp %in% selection)
    base <- .kandidater_bas(selected, 2018L)
    out <- dplyr::filter(stored, .data$valtyp %in% selection)
    index <- match(encode(out), encode(base))
    expected <- out
    for (field in names(base)) expected[[field]] <- base[[field]][index]
    expect_identical(.canonical_2018_candidate_selection(out, selected), expected)
    expect_identical(.canonical_2018_candidate_selection(out, selected, base_only = TRUE),
                     base)
    # Elected rows retain elected geography and may include several elected relations.
    elected <- dplyr::bind_rows(out, out[1, ])
    elected$vald_valomradeskod <- rep("0180", nrow(elected))
    expected <- elected
    index <- match(encode(elected), encode(base))
    expected$antal_valtyper <- base$antal_valtyper[index]
    expected$flera_valtyper <- base$flera_valtyper[index]
    expect_identical(.canonical_2018_candidate_selection(elected, selected, elected = TRUE),
                     expected)
  }
  expect_identical(.canonical_2018_candidate_selection(stored, kd, base_only = TRUE),
                   .kandidater_bas(kd, 2018L))
  bad <- stored
  bad$kandidatnummer[1] <- "missing"
  expect_error(.canonical_2018_candidate_selection(bad, kd), "candidate keys disagree")
  expect_error(.canonical_2018_candidate_selection(bad, kd, elected = TRUE),
               "elected candidate keys disagree")
  expect_error(.canonical_2018_candidate_selection(dplyr::bind_rows(stored, stored[1, ]), kd),
               "candidate keys disagree")
  expect_error(.canonical_2018_candidate_selection(stored, kd[0, ]), "inga giltiga")
  for (field in c("partibeteckning", "oppen_lista", "giltig")) {
    incomplete <- kd[setdiff(names(kd), field)]
    message <- function(expr) tryCatch({ force(expr); "no error" },
                                       error = function(e) conditionMessage(e))
    expect_identical(message(.canonical_2018_candidate_selection(stored, incomplete)),
                     message(.kandidater_bas(incomplete, 2018L)), info = field)
  }
})
test_that("XML result party batches preserve order, types and missing values", {
  doc <- xml2::read_xml(paste0(
    '<RESULTAT VALDAG="20180909"><KOMMUN KOD="0180" R\u00d6STER="7">',
    '<VALDELTAGANDE SUMMA_R\u00d6STER="9"/>',
    '<GILTIGA PARTI="A" R\u00d6STER="0" R\u00d6STER_FGVAL="2"/>',
    '<\u00d6VRIGA_GILTIGA><GILTIGA PARTI="B" R\u00d6STER="6"/>',
    '<HANDSKRIVNA R\u00d6STER="1"/></\u00d6VRIGA_GILTIGA>',
    '</KOMMUN></RESULTAT>'))
  node <- .xml2018_find_first(doc, './KOMMUN')
  for (val in c('RD', 'RF', 'KF')) {
    geo <- .xml2018_geo(node, val, 'kommun', doc)
    register <- .xml2018_reg_index(tibble::tibble(
      valtyp = rep(val, 2), valomradeskod = rep(geo$valomradeskod, 2),
      partiforkortning = c('A', 'B'), partibeteckning = c('Parti A', 'Parti B'),
      partikod = c('0001', '0002')))
    out <- .xml2018_partirader(node, geo, node, val, register)
    prototype <- .valresultat_schema()
    expect_identical(.xml2018_partirader(node, geo, node, val, register, prototype), out)
    expect_identical(prototype, .valresultat_schema())
    expect_s3_class(out, 'tbl_df')
    expect_identical(names(out), names(.valresultat_schema()))
    expect_identical(vapply(out, typeof, ''), vapply(.valresultat_schema(), typeof, ''))
    expect_identical(out$partikod, c('0001', '0002', NA_character_))
    expect_identical(out$partiforkortning, c('A', 'B', NA_character_))
    expect_identical(out$ovriga_partier, c(FALSE, FALSE, TRUE))
    expect_identical(out$antal_roster, c(0L, 6L, 1L))
    expect_identical(out$antal_roster_fg, c(2L, NA_integer_, NA_integer_))
    expect_identical(out$diff_antal_roster, c(-2L, NA_integer_, NA_integer_))
    expect_identical(out$ogiltiga_roster, rep(2L, 3))
    expect_identical(out$valtyp, rep(val, 3))
    expect_identical(out$kommunkod, rep('0180', 3))
    expect_identical(out$andel_roster, rep(NA_real_, 3))
    xml2::xml_set_attr(node, 'R\u00d6STER', '8')
    expect_error(.xml2018_partirader(node, geo, node, val, register),
                 'Partir.*st.*mmer inte')
    xml2::xml_set_attr(node, 'R\u00d6STER', '7')
  }
  empty <- xml2::read_xml('<RESULTAT/>')
  expect_identical(.xml2018_partirader(empty, list(), empty, 'KF', NULL),
                   .valresultat_schema())
  party <- .xml2018_find_first(node, './GILTIGA')
  xml2::xml_set_attr(party, 'R\u00d6STER', '1.5')
  expect_error(.xml2018_partirader(node, geo, node, val, register), 'Ogiltigt XML-heltal')
})
