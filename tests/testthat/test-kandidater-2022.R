test_that("candidate-level ballot and open-list status use distinct three-state rules", {
  cases <- tibble::tibble(
    kandidatnummer = rep(as.character(seq_len(9)), each = 2L),
    valtyp = "RD", partikod = "P", giltig = TRUE,
    oppen_lista = c(TRUE, TRUE, FALSE, FALSE, TRUE, FALSE,
                    TRUE, NA, NA, NA, TRUE, FALSE,
                    FALSE, FALSE, FALSE, NA, NA, NA),
    pa_namnvalsedel = c(TRUE, FALSE, TRUE, NA, FALSE, FALSE,
                        FALSE, NA, NA, NA, TRUE, TRUE,
                        NA, FALSE, TRUE, NA, FALSE, FALSE)
  )
  out <- .kandidatstatus(cases)
  expect_identical(out$oppen_lista,
                   c(TRUE, FALSE, NA, NA, NA, NA, FALSE, NA, NA))
  expect_identical(out$pa_namnvalsedel,
                   c(TRUE, TRUE, FALSE, NA, NA, TRUE, NA, TRUE, FALSE))
  older <- cases[1:2, ]
  older$pa_namnvalsedel <- c(NA, NA)
  expect_identical(.kandidatstatus(older)$pa_namnvalsedel, NA)
})

test_that("candidate year selection preserves order and does not change old positional arguments", {
  local_mocked_bindings(
    .kandidater_ett_ar = function(ar, val, resultat, source, data_dir,
                                  update, archive, progress) {
      tibble::tibble(valar = as.integer(ar), valtyp = val[[1]])
    }
  )
  expect_identical(kandidater(detaljniva = "full", ar = c(2026, 2022, 2026), val = "RD")$valar,
                   c(2026L, 2022L))
  expect_identical(kandidater(detaljniva = "full", ar = c(2026, 2018, 2022), val = "RD")$valar,
                   c(2026L, 2018L, 2022L))
  expect_identical(kandidater(detaljniva = "full", ar = "alla", val = "RF")$valar,
                   c(2010L, 2014L, 2018L, 2022L, 2026L))
  expect_identical(kandidater(detaljniva = "full", fran = 2022, val = "KF")$valar,
                   c(2022L, 2026L))
  expect_identical(kandidater(detaljniva = "full", till = 2022, val = "KF")$valar,
                   c(2010L, 2014L, 2018L, 2022L))
  expect_error(kandidater(detaljniva = "full", ar = 2022, fran = 2022, val = "RD"),
               "alternativa")
  expect_error(kandidater(detaljniva = "full", ar = 2016, val = "RD"), "2016")
})

test_that("public candidate years stack without changing the established columns", {
  cand <- fixture_kandidaturer()
  cand$oppen_lista <- c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
  cand$pa_namnvalsedel <- c(TRUE, FALSE, FALSE, FALSE, NA, NA)
  local_mocked_bindings(kandidaturer = function(ar, ...) {
    dplyr::mutate(cand, valtillfalle = paste0("Val_", ar))
  })
  a <- kandidater(detaljniva = "full", ar = 2022, val = "RD", resultat = FALSE)
  b <- kandidater(detaljniva = "full", ar = 2026, val = "RD", resultat = FALSE)
  both <- kandidater(detaljniva = "full", ar = c(2022, 2026), val = "RD", resultat = FALSE)
  expect_identical(both, dplyr::bind_rows(a, b))
  expect_identical(names(both)[1:2], c("valtillfalle", "valar"))
  expect_type(both$valar, "integer")
  expect_type(both$antal_valkretsar, "integer")
  expect_identical(both$antal_valkretsar,
                   c(a$antal_valkretsar, b$antal_valkretsar))
  expect_setequal(setdiff(names(both), names(make_kandidater_2026(cand))),
                  c("valar", "oppen_lista", "pa_namnvalsedel",
                    "kandidatur_valomradeskod", "kandidatur_valomradesnamn",
                    "kandidatur_valkretskod", "kandidatur_valkretsnamn"))
  expect_identical(
    dplyr::select(b, -valar, -oppen_lista, -pa_namnvalsedel,
                  -dplyr::starts_with("kandidatur_")),
    dplyr::filter(
      make_kandidater_2026(dplyr::mutate(cand, valtillfalle = "Val_2026")),
      valtyp == "RD"
    )
  )
  expect_equal(nrow(dplyr::distinct(both, valar, kandidatnummer, valtyp, partikod)),
               nrow(both))
})

.fixture_kandidatresultat_2022 <- function() {
  list(
    valtillfalle = "Val_20220911", rakningstillfalle = "slutlig",
    valtyp = "KF",
    valomrade = list(
      kod = "0180", namn = "Stockholms kommun",
      antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
      valkretsLista = list(), kvalificeradeForPersonvalLista = list(),
      valda = list(partiLedamoterLista = list()),
      mandatfordelning = list(partiLista = list(list(
        partikod = "P", antalMandat = 0L))),
      rostfordelning = list(
        rosterPaverkaMandat = list(rosterOvrigaPartier = list(antalRoster = 0L),
          partiRoster = list(list(
          partikod = "P", antalRoster = 3L,
          listRoster = list(list(
            listnummer = "2022-1", antalRoster = 3L,
            antalRosterMedPersonrost = 3L,
            personroster = list(
              list(kandidatNummer = "1", antalPersonroster = 2L),
              list(kandidatNummer = "3", antalPersonroster = 1L)
            )
          ))
        ))),
        rosterEjPaverkaMandat = list(partiRoster = list())
      )
    )
  )
}

test_that("2022 area lists preserve reported votes and verified zeros", {
  raw <- .fixture_kandidatresultat_2022()
  cand <- tibble::tibble(
    kandidatnummer = c("1", "2", "3"), valtyp = "KF", partikod = "P",
    valomradeskod = "0180", valkretskod = NA_character_,
    giltig = c(TRUE, TRUE, FALSE), oppen_lista = FALSE
  )
  local_mocked_bindings(parse_valda_ersattare_2026 = function(...) list(
    valda = fixture_valda()[0, ]
  ))
  out <- .kandidatresultat_raw_2022(raw, cand)$personrostomraden
  expect_identical(out$kandidatnummer, c("1", "2"))
  expect_identical(out$antal_personroster, c(2L, 0L))
  party <- raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  party$antalRoster <- 5L
  party$listRoster[[2]] <- list(
    listnummer = "2022-90000", antalRoster = 2L,
    antalRosterMedPersonrost = 0L, personroster = list()
  )
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- party
  cand$oppen_lista <- TRUE
  reported <- .kandidatresultat_raw_2022(raw, cand)$personrostomraden
  expect_identical(reported$antal_personroster, c(2L, 0L))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$listRoster[[2]]$personroster <-
    list(list(kandidatNummer = "1", antalPersonroster = 1L))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$listRoster[[2]]$antalRosterMedPersonrost <- 1L
  expect_error(.kandidatresultat_raw_2022(raw, cand), "90000")
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$listRoster[[2]]$antalRosterMedPersonrost <- 2L
  expect_error(.kandidatresultat_raw_2022(raw, cand), "inom 2022")
})

test_that("2022 omitted party has zero reported candidate votes only with verified aggregate", {
  raw <- .fixture_kandidatresultat_2022()
  cand <- tibble::tibble(
    kandidatnummer = c("1", "4"), valtyp = "KF", partikod = c("P", "Q"),
    valomradeskod = "0180", valkretskod = NA_character_,
    giltig = TRUE, oppen_lista = c(FALSE, TRUE)
  )
  local_mocked_bindings(parse_valda_ersattare_2026 = function(...) list(
    valda = fixture_valda()[0, ]
  ))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier$antalRoster <- 2L
  out <- .kandidatresultat_raw_2022(raw, cand)$personrostomraden
  expect_identical(out$antal_personroster, c(2L, 0L))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier <- NULL
  unknown <- .kandidatresultat_raw_2022(raw, cand)$personrostomraden
  expect_identical(unknown$antal_personroster, c(2L, NA_integer_))
})

test_that("2022 person votes from several result lists are counted once per list", {
  raw <- .fixture_kandidatresultat_2022()
  party <- raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  party$antalRoster <- 5L
  party$listRoster[[2]] <- list(
    listnummer = "2022-2", antalRoster = 2L,
    antalRosterMedPersonrost = 1L,
    personroster = list(list(kandidatNummer = "1", antalPersonroster = 1L))
  )
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- party
  raw$valomrade$kvalificeradeForPersonvalLista <- list(list(
    kandidatnummer = "1", partikod = "P", antalPersonroster = 3L
  ))
  cand <- tibble::tibble(
    kandidatnummer = c("1", "2", "3"), valtyp = "KF", partikod = "P",
    valomradeskod = "0180", valkretskod = NA_character_,
    giltig = c(TRUE, TRUE, FALSE), oppen_lista = FALSE
  )
  local_mocked_bindings(parse_valda_ersattare_2026 = function(...) list(
    valda = fixture_valda()[0, ]
  ))
  out <- .kandidatresultat_raw_2022(raw, cand)$personrostomraden
  expect_identical(out$antal_personroster, c(3L, 0L))
  party$listRoster[[2]]$listnummer <- "2022-1"
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- party
  expect_error(.kandidatresultat_raw_2022(raw, cand), "dubbla listnummer")
})
