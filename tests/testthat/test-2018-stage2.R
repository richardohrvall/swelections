test_that("2018 elected members and substitutes follow the final XML relation", {
  doc <- xml2::read_xml(paste0(
    '<VAL VALDAG="20180909" VALDAG_FGVAL="20140914">',
    '<KOMMUN KOD="0184" NAMN="Solna stad">',
    '<KRETS_KOMMUN KOD="018400" NAMN="Solna stad">',
    '<GILTIGA PARTI="M" RÖSTER="5" PERSONKRYSS="3">',
    '<GRUPP_VALDA ORDNING="1">',
    '<VALD KANDNR="1" ORDNING="1" GRUND="P"/>',
    '<VALD NAMN="Kunde inte utses"/>',
    '<ERSÄTTARE KANDNR="2" ORDNING="1"/>',
    '</GRUPP_VALDA>',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3" ÖVER_SPÄRR="J"/>',
    '<VALSEDEL LISTNUMMER="0001-100" RÖSTER="5" PERSONKRYSS="3">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3"/>',
    '</VALSEDEL><PARTISEDEL LISTNUMMER="0001-90000" RÖSTER="0"/>',
    '</GILTIGA>',
    '</KRETS_KOMMUN></KOMMUN></VAL>'
  ))
  register <- .xml2018_reg_index(tibble::tibble(
    valtyp = "KF", valomradeskod = "0184", partiforkortning = "M",
    partibeteckning = "Moderaterna", partikod = "0001"
  ))
  elected <- .xml2018_valda_ersattare_fil(doc, "KF", register)
  expect_equal(nrow(elected$valda), 1L)
  expect_equal(nrow(elected$ersattare), 1L)
  expect_identical(elected$valda$kandidatnummer, "1")
  expect_identical(elected$valda$valkretskod, NA_character_)
  expect_identical(elected$ersattare$ersattare_kandidatnummer, "2")
  expect_identical(elected$ersattare$ledamot_namn, NA_character_)
  expect_identical(elected$ersattare$ersattare_namn, NA_character_)
})

test_that("2018 personal votes distinguish observed, verified zero and unknown", {
  doc <- xml2::read_xml(paste0(
    '<VAL VALDAG="20180909"><KOMMUN KOD="0184" NAMN="Solna stad">',
    '<KRETS_KOMMUN KOD="018400" NAMN="Solna stad">',
    '<GILTIGA PARTI="M" RÖSTER="5" PERSONKRYSS="3">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3" ÖVER_SPÄRR="J"/>',
    '<VALSEDEL LISTNUMMER="0001-100" RÖSTER="5" PERSONKRYSS="3">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3"/>',
    '</VALSEDEL><PARTISEDEL LISTNUMMER="0001-90000" RÖSTER="0"/>',
    '</GILTIGA>',
    '</KRETS_KOMMUN></KOMMUN></VAL>'
  ))
  register <- .xml2018_reg_index(tibble::tibble(
    valtyp = "KF", valomradeskod = "0184",
    partiforkortning = c("M", "X"),
    partibeteckning = c("Moderaterna", "Parti X"),
    partikod = c("0001", "0002")
  ))
  raw <- .xml2018_person_fil(doc, "KF", "personvalsomrade", register)
  expect_identical(sum(raw$lista$listnummer == "90000"), 1L)
  kd <- fixture_kandidaturer()[rep(4L, 3L), ] |>
    dplyr::mutate(kandidatnummer = c("1", "2", "3"),
      partikod = c("0001", "0001", "0002"),
      partiforkortning = c("M", "M", "X"),
      partibeteckning = c("Moderaterna", "Moderaterna", "Parti X"),
      valomradeskod = "0184", valomradesnamn = "Solna stad",
      valkretskod = "00", valkretsnamn = "Solna stad",
      listnummer = "100", namn = NA_character_,
      oppen_lista = FALSE, pa_namnvalsedel = TRUE)
  out <- .xml2018_person_public(raw, raw, kd, "personvalsomrade",
                                FALSE, FALSE)
  expect_identical(out$antal_personroster[
    match(c("1", "2", "3"), out$kandidatnummer)], c(3L, 0L, NA_integer_))
  expect_identical(out$namn, rep(NA_character_, 3L))
  sparse <- .xml2018_person_public(raw, raw, kd, "personvalsomrade",
                                   TRUE, FALSE)
  complete <- .xml2018_person_public(raw, raw, kd, "personvalsomrade",
                                     TRUE, TRUE)
  expect_equal(nrow(sparse), 1L)
  expect_equal(nrow(complete), 2L)
  expect_identical(sort(complete$antal_personroster), c(0L, 3L))
  expect_false(anyNA(complete$antal_personroster))
  expect_false("90000" %in% complete$listnummer)
  expect_identical(complete$valomradesnamn, rep("Solna", 2L))
})

test_that("2018 result-dependent APIs are registered for all election types", {
  for (fun in c("kandidater", "valda", "ersattare", "personroster")) {
    for (val in c("RD", "RF", "KF")) {
      expect_identical(.stodd_valar(fun, val), c(2010L, 2014L, 2018L, 2022L, 2026L))
    }
  }
})

test_that("2018 district votes include Wednesday and reject candidate votes on 90000", {
  doc <- xml2::read_xml(paste0(
    '<VAL VALDAG="20180909"><KOMMUN KOD="0184" NAMN="Solna stad">',
    '<KRETS_KOMMUN KOD="018400" NAMN="Solna stad">',
    '<GILTIGA PARTI="M" RÖSTER="5" PERSONKRYSS="3">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3" ÖVER_SPÄRR="J"/>',
    '<VALSEDEL LISTNUMMER="0001-100" RÖSTER="5" PERSONKRYSS="3">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="3"/></VALSEDEL>',
    '</GILTIGA>',
    '<VALDISTRIKT KOD="01840101" NAMN="Ett">',
    '<GILTIGA PARTI="M" RÖSTER="3" PERSONKRYSS="2">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="2"/>',
    '<VALSEDEL LISTNUMMER="0001-100" RÖSTER="3" PERSONKRYSS="2">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="2"/></VALSEDEL>',
    '</GILTIGA></VALDISTRIKT>',
    '<ONSDAGSDISTRIKT KOD="01849001" NAMN="Onsdag">',
    '<GILTIGA PARTI="M" RÖSTER="2" PERSONKRYSS="1">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="1"/>',
    '<VALSEDEL LISTNUMMER="0001-100" RÖSTER="2" PERSONKRYSS="1">',
    '<PERSONVAL KANDNR="1" PERSONKRYSS="1"/></VALSEDEL>',
    '</GILTIGA></ONSDAGSDISTRIKT>',
    '</KRETS_KOMMUN></KOMMUN></VAL>'
  ))
  register <- .xml2018_reg_index(tibble::tibble(
    valtyp = "KF", valomradeskod = "0184", partiforkortning = "M",
    partibeteckning = "Moderaterna", partikod = "0001"
  ))
  raw <- .xml2018_person_distrikt_fil(doc, "KF", register, NULL, 1L)
  expect_equal(nrow(raw$geo), 2L)
  expect_setequal(raw$geo$valdistriktstyp,
    c("valdistrikt", "uppsamlingsdistrikt"))
  expect_identical(sum(raw$roster$antal_personroster), 3L)
  expect_identical(sum(raw$listroster$antal_personroster), 3L)
  area <- .xml2018_person_fil(doc, "KF", "personvalsomrade", register)
  kd <- fixture_kandidaturer()[rep(4L, 2L), ] |>
    dplyr::mutate(kandidatnummer = c("1", "2"), partikod = "0001",
      valomradeskod = "0184", valomradesnamn = "Solna stad",
      valkretskod = "00", valkretsnamn = "Solna stad",
      listnummer = "100", namn = NA_character_,
      oppen_lista = FALSE, pa_namnvalsedel = TRUE)
  for (per_lista in c(FALSE, TRUE)) {
    sparse <- .xml2018_person_public(raw, area, kd,
      "valdistrikt", per_lista, FALSE)
    complete <- .xml2018_person_public(raw, area, kd,
      "valdistrikt", per_lista, TRUE)
    expect_equal(nrow(sparse), 2L)
    expect_equal(nrow(complete), 4L)
    expect_identical(sort(complete$antal_personroster), c(0L, 0L, 1L, 2L))
    expect_false(anyNA(complete$antal_personroster))
    expect_identical(unique(complete$kommunnamn), "Solna")
  }
  bad <- xml2::read_xml(as.character(doc))
  node <- xml2::xml_find_first(bad, ".//VALDISTRIKT/GILTIGA/VALSEDEL")
  xml2::xml_set_attr(node, "LISTNUMMER", "0001-90000")
  expect_error(.xml2018_person_distrikt_fil(bad, "KF", register, NULL, 1L),
    "90000")
})
