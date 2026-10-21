test_that("2018 canonical never substitutes final data for preliminary requests", {
  local_mocked_bindings(.canonical_manifest_path = function(...) stop("must not fetch"))
  for (val in c("RD", "RF", "KF")) {
    expect_error(results(2018, val, count = "preliminary", source = "canonical"),
      "2018 st.*endast slutlig")
    expect_error(seats(2018, val, count = "preliminary", source = "canonical"),
      "2018 st.*endast slutlig")
    expect_error(valresultat(2018, val, rakning = "preliminar", source = "canonical"),
      "2018 st.*endast slutlig")
    expect_error(mandat(2018, val, rakning = "preliminar", source = "canonical"),
      "2018 st.*endast slutlig")
  }
})

test_that("the 2018 stage guard leaves final and other-year dispatch unchanged", {
  marker <- tibble::tibble(value = 1L)
  local_mocked_bindings(.canonical_manifest_path = function(...) "fixture",
    .canonical_2018_source = function(...) marker,
    .canonical_2014_source = function(...) list(...) )
  for (surface in c("valresultat", "mandat")) {
    expect_identical(.canonical_source(2018L, surface, "RD", rakning = "slutlig"), marker)
    other <- .canonical_source(2014L, surface, "RD", rakning = "preliminar")
    expect_true("preliminar" %in% unlist(other))
  }
})

test_that("Ragunda corrects one original elected seat and is idempotent", {
  doc <- xml2::read_xml(paste0(
    '<VAL VALDAG="20180909"><KOMMUN KOD="2303">',
    '<KRETS_KOMMUN><GILTIGA PARTI="SD" MANDAT="3">',
    '<GRUPP_VALDA ORDNING="0">',
    '<VALD ORDNING="1" KANDNR="150262" GRUND="P"/>',
    '<VALD ORDNING="2" KANDNR="106462" GRUND="P"/>',
    '<VALD ORDNING="3" KANDNR="" NAMN="Kunde inte utses" GRUND="J"/>',
    '</GRUPP_VALDA></GILTIGA></KRETS_KOMMUN></KOMMUN></VAL>'))
  .xml2018_ragunda_elected(doc, "KF")
  rows <- xml2::xml_find_all(doc, ".//VALD")
  expect_identical(xml2::xml_attr(rows,"KANDNR"), c("150262", "106462", "534885"))
  expect_identical(xml2::xml_attr(rows,"ORDNING"), c("1", "2", "3"))
  expect_identical(xml2::xml_attr(rows,"GRUND"), c("P", "P", "J"))
  once <- as.character(doc)
  expect_identical(as.character(.xml2018_ragunda_elected(doc,"KF")), once)
  xml2::xml_set_attr(rows[[3L]], "KANDNR", "different")
  expect_error(.xml2018_ragunda_elected(doc,"KF"), "conflicts")
  xml2::xml_set_attr(xml2::xml_root(doc), "VALDAG", "20140914")
  expect_identical(.xml2018_ragunda_elected(doc,"KF"), doc)
})

test_that("Ragunda candidacy retains only supported correction attributes", {
  x <- fixture_kandidaturer()[4L, ]
  x$valar <- 2018L; x$valtillfalle <- "2018"
  x$valomradeskod <- "2303"; x$partikod <- "0110"
  x$kandidatnummer <- "150262"
  x$ordning <- 1L; x$samtycke <- "ja"; x$oppen_lista <- TRUE
  x$valsedelsstatus <- "S"; x$pa_namnvalsedel <- TRUE
  y <- .xml2018_ragunda_candidacy(x)
  expect_identical(y[1L, ], x)
  expect_identical(vapply(y, typeof, ""), vapply(x, typeof, ""))
  expect_identical(y$kandidatnummer[[2L]], "534885")
  expect_identical(y$listnummer[[2L]], "17638")
  expect_identical(y$ordning[[2L]], 3L)
  expect_true(y$giltig[[2L]]); expect_identical(y$samtycke[[2L]], "ja")
  expect_true(is.na(y$namn[[2L]])); expect_true(is.na(y$pa_namnvalsedel[[2L]]))
  expect_true(is.na(y$alder_pa_valdagen[[2L]]))
  expect_identical(.xml2018_ragunda_candidacy(y), y)
  x$valtyp <- "RF"
  expect_identical(.xml2018_ragunda_candidacy(x), x)
})

test_that("Ragunda preference correction has no invented ballot-list allocation", {
  raw <- list(geo = tibble::tibble(valtyp = "KF", valomradeskod = "2303",
      personvalsomradeskod = "2303", node_id = 1L, valdistriktskod = "23030409"),
    parti = tibble::tibble(valtyp = "KF", valomradeskod = "2303",
      personvalsomradeskod = "2303", partikod = "0110", node_id = 1L),
    roster = tibble::tibble(valtyp = "KF", valomradeskod = "2303",
      personvalsomradeskod = "2303", partikod = "0110", node_id = 1L,
      kandidatnummer = "150262", antal_personroster = 86L, kvalificerad_personval = TRUE),
    lista = tibble::tibble(listnummer = "15437"),
    listroster = tibble::tibble(listnummer = "15437", antal_personroster = 86L))
  y <- .xml2018_ragunda_votes(raw,"valdistrikt")
  expect_identical(y$roster$antal_personroster, c(86L,5L))
  expect_identical(y$roster$kandidatnummer, c("150262","534885"))
  expect_false(y$roster$kvalificerad_personval[[2L]])
  expect_identical(y$listroster, raw$listroster)
  expect_identical(y$lista, raw$lista)
  expect_identical(y$parti, raw$parti)
  expect_identical(.xml2018_ragunda_votes(y,"valdistrikt"), y)
  raw$geo$valdistriktskod <- "23030205"
  expect_identical(.xml2018_ragunda_votes(raw,"valdistrikt"), raw)
  p <- .xml2018_ragunda_provenance()
  expect_identical(p$electoral_start,"2018-09-09")
  expect_identical(p$decision_date,"2018-12-12")
  expect_true(is.na(p$implementing_decision_date))
})
