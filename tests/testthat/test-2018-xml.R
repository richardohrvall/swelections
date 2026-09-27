test_that("2018 XML normalises votes and mandates without combining periods", {
  doc <- xml2::read_xml(paste0(
    '<RESULTAT VALDAG="20180909" VALDAG_FGVAL="20140914">',
    '<NATION KOD="00" TID_RAPPORT="2018-09-20" ',
    'KLARA_VALDISTRIKT="1" ALLA_VALDISTRIKT="1" MANDAT_VALOMRÅDE="1" ',
    'RÖSTER="6" RÖSTER_FGVAL="5">',
    '<VALDELTAGANDE RÖSTBERÄTTIGADE="10" ',
    'RÖSTBERÄTTIGADE_KLARA_VALDISTRIKT="10" SUMMA_RÖSTER="7" ',
    'SUMMA_RÖSTER_FGVAL="6"/>',
    '<GILTIGA PARTI="A" RÖSTER="6" RÖSTER_FGVAL="5" ',
    'MANDAT="1" MANDAT_FGVAL="2" VARAV_UTJÄMNING="0">',
    '<GRUPP_VALDA><VALD KANDNR="123" NAMN="Person"/></GRUPP_VALDA>',
    '</GILTIGA></NATION></RESULTAT>'
  ))
  node <- xml2::xml_find_first(doc, "./NATION")
  register <- .xml2018_reg_index(tibble::tibble(
    valtyp = "RD", valomradeskod = "00", partiforkortning = "A",
    partibeteckning = "Parti A", partikod = "0001"
  ))
  geo <- .xml2018_geo(node, "RD", "riket", doc)
  votes <- .xml2018_partirader(node, geo, node, "RD", register)
  expect_identical(names(votes), names(.valresultat_schema()))
  expect_identical(vapply(votes, typeof, ""),
                   vapply(.valresultat_schema(), typeof, ""))
  expect_identical(votes$antal_roster, 6L)
  expect_identical(votes$antal_roster_fg, 5L)
  expect_identical(votes$diff_antal_roster, 1L)
  expect_identical(votes$ogiltiga_roster, 1L)
  expect_identical(votes$partikod, "0001")
  expect_identical(votes$valdatum, "2018-09-09")
  expect_identical(votes$valdatum_fg, "2014-09-14")
  expect_equal(.valresultat_public_andelar_2026(votes)$andel_roster, 1)
  seats <- .xml2018_mandatrader(node, doc, node, "RD", "riket", register)
  expect_identical(seats$antal_mandat, 1L)
  expect_identical(seats$antal_mandat_fg, 2L)
  expect_identical(seats$antal_tomma_stolar, 0L)
  expect_identical(seats$totalt_antal_mandat, 1L)
})

test_that("2018 vacancies require a validated elected relation", {
  doc <- xml2::read_xml(paste0(
    '<RESULTAT><NATION KOD="00" MANDAT_VALOMRÅDE="1">',
    '<GILTIGA PARTI="A" MANDAT="1">',
    '<GRUPP_VALDA><VALD NAMN="Kunde inte utses"/></GRUPP_VALDA>',
    '</GILTIGA></NATION></RESULTAT>'
  ))
  node <- xml2::xml_find_first(doc, "./NATION")
  party <- xml2::xml_find_first(node, "./GILTIGA")
  expect_identical(.xml2018_tomma_stolar(node, party, "RD", 1L), 1L)
  xml2::xml_remove(xml2::xml_find_first(party, "./GRUPP_VALDA"))
  expect_true(is.na(.xml2018_tomma_stolar(node, party, "RD", 1L)))
})

test_that("2018 support matrix and local source are strict", {
  expect_identical(.stodd_valar("kandidaturer", "RD"), c(2018L, 2022L, 2026L))
  for (val in c("RD", "RF", "KF")) {
    for (niva in c("valdistrikt", "kommun", "kommunvalkrets", "lan",
                   "region", "regionvalkrets", "riksdagsvalkrets", "riket")) {
      supported <- niva %in% switch(val,
        RD = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riksdagsvalkrets", "riket"),
        RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets", "region", "riket"),
        KF = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riket"))
      if (supported) expect_silent(.valresultat_niva_2018(val, niva))
      else expect_error(.valresultat_niva_2018(val, niva), "stöds inte")
    }
  }
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  local_mocked_bindings(download_val_file = function(...) stop("network"),
                        val_remote_url = function(...) stop("network"))
  expect_error(.kalla_2018("resultat", "local", root), "Filen finns inte")
  expect_error(.kalla_2018("resultat", "local", root, update = TRUE),
               "update = TRUE")
  expect_error(.kalla_2018("resultat", "remote", root),
               "kan inte längre hämtas")
})

test_that("2018 candidacy names are absent regardless of local source content", {
  raw <- fixture_kandidaturer_raw()
  names(raw)[match(c("anmaldakandidater", "folkbokforingskommun",
                     "antal_valsedlar_for_den_specifika_listan"), names(raw))] <-
    c("ANMKAND", "FOLKBOKFORINGSORT", "ANT_BEST_VALS")
  names(raw) <- toupper(names(raw))
  raw$VALTYP <- "R"
  raw$NAMN <- c("Namngiven A", "Namngiven A", "Namngiven A", "Namngiven B")
  file <- tempfile(fileext = ".skv")
  on.exit(unlink(file), add = TRUE)
  readr::write_delim(raw, file, delim = ";", na = "")
  out <- .read_kandidaturer_2018(file)
  expect_identical(out$namn, rep(NA_character_, 4))
  expect_identical(out$valar, rep(2018L, 4))
  expect_identical(out$kandidatnummer, c("1", "1", "1", "2"))
  expect_identical(out$pa_namnvalsedel[1:2], c(TRUE, TRUE))
  expect_true(all(is.na(out$pa_namnvalsedel[3:4])))
})
