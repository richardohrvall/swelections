personroster_list_fixture <- function() {
  kandidaturer <- tibble::tibble(
    kandidatnummer = c("1", "1", "2", "3"), valtyp = "RD",
    valomradeskod = "00", valkretskod = "01", partikod = "A",
    listnummer = c("1", "2", "1", "2"), giltig = c(TRUE, TRUE, TRUE, FALSE)
  )
  kandidater <- tibble::tibble(
    kandidatnummer = c("1", "2"), valtyp = "RD", partikod = "A",
    namn = c("Anna", "Bo"), partiforkortning = "A", partibeteckning = "Parti A"
  )
  listnod <- function(nummer, roster, person) {
    list(listnummer = paste0("A-", nummer), antalRoster = roster,
      antalRosterMedPersonrost = as.integer(sum(vapply(person,
        function(x) x$antalPersonroster, 0L))), personroster = person)
  }
  person <- function(kod, roster) list(kandidatNummer = kod, antalPersonroster = roster)
  party <- function(listor, summerade) {
    list(partikod = "A", antalRoster = as.integer(sum(vapply(listor,
      function(x) x$antalRoster, 0L))), listRoster = listor,
      summeradePersonroster = summerade)
  }
  summerad <- function(kod, roster) list(kandidatnummer = kod, antalPersonroster = roster)
  p1 <- party(list(
    listnod("1", 10L, list(person("1", 2L))),
    listnod("2", 10L, list(person("1", 3L), person("3", 1L))),
    listnod("90000", 5L, list())
  ), list(summerad("1", 5L), summerad("3", 1L)))
  p2 <- party(list(listnod("1", 10L, list(person("1", 1L)))),
              list(summerad("1", 1L)))
  district <- function(kod, p) list(
    namn = paste("Distrikt", kod), valdistriktskod = kod,
    valdistriktstyp = "valdistrikt", kommunkod = "0180", lankod = "01",
    valomradeskod = "00", kretskod = "01",
    rostfordelning = list(rosterPaverkaMandat = list(partiRoster = list(p)))
  )
  rost <- list(valtillfalle = "Val_2026", rakningstillfalle = "slutlig",
    valtyp = "RD", valdatum = "2026-09-13", test = FALSE,
    antalValdistriktRaknade = 2L, antalValdistriktSomSkaRaknas = 2L,
    valdistrikt = list(district("018001", p1), district("018002", p2)))
  pm <- party(list(
    listnod("1", 20L, list(person("1", 3L))),
    listnod("2", 10L, list(person("1", 3L), person("3", 1L))),
    listnod("90000", 5L, list())
  ), list(summerad("1", 6L), summerad("3", 1L)))
  mandat <- list(valtillfalle = "Val_2026", rakningstillfalle = "slutlig",
    valtyp = "RD", valdatum = "2026-09-13", test = FALSE,
    valomrade = list(kod = "00", namn = "Riket", valkretsLista = list(
      list(kod = "01", namnValkrets = "Krets 1", antalValdistriktRaknade = 2L,
        antalValdistriktSomSkaRaknas = 2L,
        kvalificeradeForPersonvalLista = list(),
        rostfordelning = list(rosterPaverkaMandat = list(
          antalRoster = 35L, rosterOvrigaPartier = list(antalRoster = 0L),
          partiRoster = list(pm))))
    )))
  omrade <- tibble::tibble(
    kandidatnummer = c("1", "2"), valtyp = "RD", partikod = "A",
    personvalsomradeskod = "01", kvalificerad_personval = FALSE
  )
  list(kandidaturer = kandidaturer, kandidater = kandidater,
       rost = rost, mandat = mandat, omrade = omrade)
}

test_that("sparse district lists retain observed rows and exclude generic ballots", {
  x <- personroster_list_fixture()
  out <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE)
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE, TRUE)
  expect_equal(nrow(out), 3L)
  expect_equal(nrow(full), 5L)
  expect_setequal(unique(out$listnummer), c("1", "2"))
  expect_equal(nrow(dplyr::filter(out, kandidatnummer == "2")), 0L)
  expect_identical(dplyr::filter(full, kandidatnummer == "2")$antal_personroster,
                   c(0L, 0L))
  expect_identical(out, dplyr::filter(full, antal_personroster > 0L))
  expect_equal(dplyr::filter(out, kandidatnummer == "1", listnummer == "1")$
    antal_personroster, c(2L, 1L))
  expect_true(all(out$andel_personroster >= 0 & out$andel_personroster <= 1))
  expect_true(all(out$andel_personroster_lista >= 0 &
                    out$andel_personroster_lista <= 1))
  expect_false(any(out$kandidatnummer == "3"))
  expect_type(out$listnummer, "character")
  expect_type(out$antal_listroster, "integer")
  expect_type(out$andel_personroster_lista, "double")
  expect_false(any(vapply(out, is.list, logical(1))))
  expect_identical(names(out), readLines(test_path("fixtures",
    "personroster-district-list-columns.txt")))
  key <- c("valtillfalle", "valtyp", "valomradeskod", "kommunkod",
           "valdistriktskod", "valdistriktstyp", "partikod", "listnummer",
           "kandidatnummer")
  expect_equal(nrow(dplyr::distinct(out, dplyr::across(dplyr::all_of(key)))),
               nrow(out))
})

test_that("district and area results reconcile across lists", {
  x <- personroster_list_fixture()
  district_list <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE)
  district <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE)
  district_full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE, TRUE)
  area_list <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE)
  area_list_full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE, TRUE)
  expect_equal(nrow(district), 2L)
  expect_equal(nrow(district_full), 4L)
  expect_identical(dplyr::filter(district_full, antal_personroster > 0L), district)
  expect_identical(dplyr::filter(district_full, kandidatnummer == "2")$
    antal_personroster, c(0L, 0L))
  expect_identical(names(district), readLines(test_path("fixtures",
    "personroster-district-columns.txt")))
  expect_identical(names(area_list), readLines(test_path("fixtures",
    "personroster-area-list-columns.txt")))
  expect_equal(dplyr::filter(district, kandidatnummer == "1")$antal_personroster,
               c(5L, 1L))
  expect_equal(dplyr::filter(area_list, kandidatnummer == "1")$antal_personroster,
               c(3L, 3L))
  expect_equal(nrow(dplyr::filter(area_list, kandidatnummer == "2")), 0L)
  expect_equal(dplyr::filter(area_list_full, kandidatnummer == "2")$antal_personroster,
               0L)
  expect_equal(dplyr::filter(area_list_full, listnummer == "1")$antal_listroster,
               c(20L, 20L))
  expect_identical(area_list,
                   dplyr::filter(area_list_full, antal_personroster > 0L))
  expect_equal(sum(district_list$antal_personroster), sum(district$antal_personroster))
  expect_equal(sum(district_list$antal_personroster),
               sum(district_full$antal_personroster))
  expect_equal(dplyr::filter(district_list, kandidatnummer == "1", listnummer == "1")$
    andel_personroster_lista, c(0.2, 0.1))
  expect_equal(dplyr::filter(area_list, kandidatnummer == "1", listnummer == "1")$
    andel_personroster_lista, 3 / 20)
})

test_that("partial list material stays NA and absent lists do not create rows", {
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$personroster <- NULL
  out <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE)
  expect_true(all(is.na(dplyr::filter(out, valdistriktskod == "018001",
    listnummer == "1")$antal_personroster)))
  x <- personroster_list_fixture()
  p <- x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  p$listRoster <- p$listRoster[c(1, 3)]
  p$antalRoster <- 15L
  p$summeradePersonroster <- list(list(kandidatnummer = "1", antalPersonroster = 2L))
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
  out <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE)
  expect_false(any(out$valdistriktskod == "018001" & out$listnummer == "2"))
})

test_that("sparse district rows preserve explicit source zeros", {
  x <- personroster_list_fixture()
  p <- x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  p$summeradePersonroster <- append(p$summeradePersonroster,
    list(list(kandidatnummer = "2", antalPersonroster = 0L)))
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
  sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE)
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE, TRUE)
  expect_equal(nrow(sparse), 3L)
  expect_identical(dplyr::filter(sparse, kandidatnummer == "2")$
    antal_personroster, 0L)
  expect_equal(nrow(full), 4L)
  expect_equal(sum(full$antal_personroster == 0L), 2L)
})

test_that("sparse list views preserve explicit source zeros", {
  x <- personroster_list_fixture()
  p <- x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  p$listRoster[[1]]$personroster <- append(p$listRoster[[1]]$personroster,
    list(list(kandidatNummer = "2", antalPersonroster = 0L)))
  p$summeradePersonroster <- append(p$summeradePersonroster,
    list(list(kandidatnummer = "2", antalPersonroster = 0L)))
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
  m <- x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]]
  m$listRoster[[1]]$personroster <- append(m$listRoster[[1]]$personroster,
    list(list(kandidatNummer = "2", antalPersonroster = 0L)))
  m$summeradePersonroster <- append(m$summeradePersonroster,
    list(list(kandidatnummer = "2", antalPersonroster = 0L)))
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]] <- m
  for (niva in c("valdistrikt", "personvalsomrade")) {
    sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
      x$rost, x$mandat, niva, TRUE)
    full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
      x$rost, x$mandat, niva, TRUE, TRUE)
    expect_identical(dplyr::filter(sparse, kandidatnummer == "2")$
      antal_personroster, 0L)
    expect_true(all(sparse$antal_personroster %in% full$antal_personroster))
  }
})

test_that("missing list nodes never generate completed district rows", {
  x <- personroster_list_fixture()
  x$kandidaturer <- dplyr::bind_rows(x$kandidaturer,
    dplyr::mutate(x$kandidaturer[4, ], kandidatnummer = "4", giltig = TRUE))
  x$kandidater <- dplyr::bind_rows(x$kandidater,
    dplyr::mutate(x$kandidater[2, ], kandidatnummer = "4", namn = "Dana"))
  p <- x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  p$listRoster <- p$listRoster[c(1, 3)]
  p$antalRoster <- 15L
  p$summeradePersonroster <- list(list(kandidatnummer = "1", antalPersonroster = 2L))
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE, TRUE)
  expect_false(any(full$kandidatnummer == "4"))
})

test_that("observed district summaries survive incomplete list detail", {
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$personroster <- NULL
  sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE)
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE, TRUE)
  expect_identical(dplyr::filter(sparse, valdistriktskod == "018001")$
    antal_personroster, 5L)
  expect_equal(nrow(dplyr::filter(full, valdistriktskod == "018001",
                                  kandidatnummer == "2")), 0L)
})

test_that("incomplete area coverage cannot turn absent list votes into zero", {
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[2]]$rostfordelning <- NULL
  x$rost$antalValdistriktRaknade <- 1L
  out <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE)
  expect_true(all(is.na(out$antal_personroster)))
  expect_true(all(is.na(out$antal_listroster)))
})

test_that("contradictory list and summary values fail before validity filtering", {
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[2]]$personroster[[2]]$antalPersonroster <- 2L
  expect_error(.personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE), "antalRosterMedPersonrost")
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$summeradePersonroster[[1]]$antalPersonroster <- 6L
  expect_error(.personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", FALSE), "summeradePersonroster")
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$listnummer <- "B-1"
  expect_error(.personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "valdistrikt", TRUE), "partikod")
})

test_that("public detail arguments are checked without accessing data", {
  local_mocked_bindings(kandidaturer = function(...) stop("File access"))
  expect_error(personroster(detaljniva = "full", niva = "kommun"),
               "requires election")
  expect_error(personroster(detaljniva = "full", niva = NA_character_), "niva")
  expect_error(personroster(detaljniva = "full", per_lista = NA), "per_lista")
  expect_error(personroster(detaljniva = "full", per_lista = 1), "per_lista")
  expect_error(personroster(detaljniva = "full", komplettera_nollor = NA), "komplettera_nollor")
  expect_error(personroster(detaljniva = "full", komplettera_nollor = 1), "komplettera_nollor")
})

test_that("public detail modes route to their respective results", {
  x <- personroster_list_fixture()
  local_mocked_bindings(
    kandidaturer = function(...) x$kandidaturer,
    make_kandidater_2026 = function(...) x$kandidater,
    .las_kandidatresultat_filer_2026 = function(..., personroster_niva,
                                               personroster_per_lista,
                                               personroster_komplettera_nollor) {
      list(list(personroster_utokad = .personroster_utokad_2026(
        x$kandidaturer, x$kandidater, x$rost, x$mandat,
        personroster_niva, personroster_per_lista,
        personroster_komplettera_nollor)))
    }
  )
  for (mode in list(list("valdistrikt", FALSE), list("valdistrikt", TRUE),
                    list("personvalsomrade", TRUE))) {
    out <- personroster(detaljniva = "full", val = "RD", niva = mode[[1]], per_lista = mode[[2]],
                       progress = FALSE)
    expect_identical(unique(out$geografiniva),
                     if (mode[[1]] == "valdistrikt") "valdistrikt" else "riksdagsvalkrets")
    expect_identical("listnummer" %in% names(out), mode[[2]])
    expect_type(out$antal_personroster, "integer")
    expect_type(out$antal_partiroster, "integer")
    expect_type(out$andel_personroster, "double")
    expect_type(out$kvalificerad_personval, "logical")
  }
  full <- personroster(detaljniva = "full", val = "RD", niva = "valdistrikt",
                       komplettera_nollor = TRUE, progress = FALSE)
  expect_equal(nrow(full), 4L)
  district_list_full <- personroster(detaljniva = "full", val = "RD", niva = "valdistrikt",
    per_lista = TRUE, komplettera_nollor = TRUE, progress = FALSE)
  area_list_full <- personroster(detaljniva = "full", val = "RD", per_lista = TRUE,
    komplettera_nollor = TRUE, progress = FALSE)
  expect_equal(nrow(district_list_full), 5L)
  expect_equal(nrow(area_list_full), 3L)
})

test_that("reconciled final areas keep observed values and complete true zeros", {
  x <- personroster_list_fixture()
  known <- .personrostomraden_2026(x$kandidaturer, x$kandidater,
                                    x$rost, x$mandat)
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$summeradePersonroster <- NULL
  # Den äldre partidistriktstatusen blir nu NA trots att områdets listor
  # och samtliga distrikt fortfarande kan stämmas av exakt.
  omraden <- .personvalsomraden_mandat_2026(x$mandat)
  expect_true(all(.personrostomraden_avstamda_2026(x$rost, omraden)))
  expect_true(all(is.na(.personrostomradesunderlag_2026(
    x$rost, "00", omraden)$status$personroster_available)))
  area <- .personrostomraden_2026(x$kandidaturer, x$kandidater,
                                   x$rost, x$mandat)
  expect_identical(area$antal_personroster, known$antal_personroster)
  expect_identical(area$antal_personroster, c(6L, 0L))
  expect_identical(.personrosttotaler_fran_omraden_2026(area)$
    antal_personroster_totalt, c(6L, 0L))
  sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE)
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE, TRUE)
  expect_equal(nrow(sparse), 2L)
  expect_false(anyNA(sparse$antal_personroster))
  expect_identical(dplyr::filter(full, kandidatnummer == "2")$
    antal_personroster, 0L)
  expect_identical(dplyr::filter(full, kandidatnummer == "2")$
    antal_listroster, 20L)
})

test_that("a zero-vote list absent everywhere gets zero only after reconciliation", {
  x <- personroster_list_fixture()
  x$kandidaturer <- dplyr::bind_rows(x$kandidaturer,
    dplyr::mutate(x$kandidaturer[4, ], kandidatnummer = "4",
                  listnummer = "3", giltig = TRUE),
    dplyr::mutate(x$kandidaturer[4, ], kandidatnummer = "5",
                  listnummer = NA_character_, giltig = TRUE))
  x$kandidater <- dplyr::bind_rows(x$kandidater,
    dplyr::mutate(x$kandidater[2, ], kandidatnummer = "4", namn = "Dana"),
    dplyr::mutate(x$kandidater[2, ], kandidatnummer = "5", namn = "Eli"))
  full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE, TRUE)
  missing <- dplyr::filter(full, kandidatnummer == "4")
  expect_equal(nrow(missing), 1L)
  expect_identical(missing$antal_personroster, 0L)
  expect_identical(missing$antal_listroster, 0L)
  expect_true(is.na(missing$andel_personroster_lista))
  sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE)
  expect_false(any(sparse$kandidatnummer == "4"))
  area <- .personrostomraden_2026(x$kandidaturer, x$kandidater,
                                   x$rost, x$mandat)
  expect_identical(dplyr::filter(area, kandidatnummer == "5")$
    antal_personroster, 0L)

  x$rost$antalValdistriktRaknade <- 1L
  x$rost$valdistrikt[[2]]$rostfordelning <- NULL
  partial <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE, TRUE)
  missing <- dplyr::filter(partial, kandidatnummer == "4")
  expect_equal(nrow(missing), 0L)
  partial_area <- .personrostomraden_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat)
  expect_true(is.na(dplyr::filter(partial_area, kandidatnummer == "4")$
    antal_personroster))
  expect_true(is.na(dplyr::filter(partial_area, kandidatnummer == "5")$
    antal_personroster))
})

test_that("completion adds only verified zeros in all sparse modes", {
  x <- personroster_list_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$personroster <- NULL
  x$rost$valdistrikt[[2]]$rostfordelning <- NULL
  x$rost$antalValdistriktRaknade <- 1L
  for (mode in list(list("valdistrikt", FALSE), list("valdistrikt", TRUE),
                    list("personvalsomrade", TRUE))) {
    sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
      x$rost, x$mandat, mode[[1]], mode[[2]], FALSE)
    full <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
      x$rost, x$mandat, mode[[1]], mode[[2]], TRUE)
    key <- c("valtyp", "valomradeskod", "personvalsomradeskod",
      "partikod", "kandidatnummer",
      if (mode[[1]] == "valdistrikt") c("kommunkod", "valdistriktskod",
                                        "valdistriktstyp"),
      if (mode[[2]]) "listnummer")
    added <- dplyr::anti_join(full, sparse, by = key)
    expect_true(all(added$antal_personroster == 0L))
    expect_false(anyNA(added$antal_personroster))
    expect_equal(nrow(dplyr::anti_join(sparse, full, by = key)), 0L)
  }
})

test_that("a final path with unfinished districts is not complete", {
  x <- personroster_list_fixture()
  x$rost$antalValdistriktRaknade <- 1L
  x$rost$valdistrikt[[2]]$rostfordelning <- NULL
  omraden <- .personvalsomraden_mandat_2026(x$mandat)
  expect_false(any(.personrostomraden_avstamda_2026(x$rost, omraden)))
  area <- .personrostomraden_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat)
  expect_true(all(is.na(area$antal_personroster)))
  sparse <- .personroster_utokad_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat, "personvalsomrade", TRUE)
  expect_true(all(is.na(sparse$antal_personroster)))
  x <- personroster_list_fixture()
  x$rost$rakningstillfalle <- "preliminär"
  expect_false(any(.personrostomraden_avstamda_2026(x$rost, omraden)))
  x <- personroster_list_fixture()
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$rosterOvrigaPartier$antalRoster <- 1L
  expect_false(any(.personrostomraden_avstamda_2026(x$rost,
    .personvalsomraden_mandat_2026(x$mandat))))
})

test_that("fully counted but contradictory area and district lists fail", {
  x <- personroster_list_fixture()
  p <- x$rost$valdistrikt[[2]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
  p$antalRoster <- 11L
  p$listRoster[[1]]$antalRoster <- 11L
  x$rost$valdistrikt[[2]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
  expect_error(.personrostomraden_2026(x$kandidaturer, x$kandidater,
    x$rost, x$mandat), "listr")
})
