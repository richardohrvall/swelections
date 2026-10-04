personrostomrades_fixture <- function(incomplete_first = FALSE,
                                     official_votes = 3L) {
  kandidaturer <- fixture_kandidaturer() |>
    dplyr::filter(valtyp == "RD", partikod == "A", giltig %in% TRUE)
  extra <- dplyr::filter(kandidaturer, kandidatnummer == "2") |>
    dplyr::mutate(valkretskod = "02", valkretsnamn = "Krets 2", listnummer = "7")
  kandidaturer <- dplyr::bind_rows(kandidaturer, extra)

  party <- function(votes) {
    list(
      partikod = "A", antalRoster = 10L,
      summeradePersonroster = list(list(
        kandidatnummer = "1", antalPersonroster = votes
      )),
      listRoster = list(list(
        listnummer = "1", antalRosterMedPersonrost = votes,
        personroster = list(list(
          kandidatNummer = "1", antalPersonroster = votes
        ))
      ))
    )
  }
  p1 <- party(3L)
  if (incomplete_first) p1$summeradePersonroster <- NULL
  p2 <- party(4L)
  district <- function(code, krets, p) {
    list(
      valdistriktskod = code, valdistriktstyp = "valdistrikt",
      kommunkod = "0180", valomradeskod = "00", kretskod = krets,
      rostfordelning = list(
        rosterPaverkaMandat = list(partiRoster = list(p))
      )
    )
  }
  rost <- list(
    valtillfalle = "Val_2026", rakningstillfalle = "slutlig",
    valtyp = "RD", valdatum = "2026-09-13", test = FALSE,
    antalValdistriktRaknade = 2L, antalValdistriktSomSkaRaknas = 2L,
    valdistrikt = list(district("0101", "01", p1), district("0201", "02", p2))
  )
  node <- function(code, name, qualified = list()) {
    list(
      kod = code, namnValkrets = name,
      antalValdistriktRaknade = 1L,
      antalValdistriktSomSkaRaknas = 1L,
      kvalificeradeForPersonvalLista = qualified,
      rostfordelning = list(
        rosterPaverkaMandat = list(
          partiRoster = list(list(partikod = "A", antalRoster = 10L))
        )
      )
    )
  }
  qualified <- list(list(
    partikod = "A", kandidatnummer = "1",
    antalPersonroster = official_votes,
    andelPersonroster = 10 * official_votes
  ))
  mandat <- list(
    valtillfalle = "Val_2026", rakningstillfalle = "slutlig",
    valtyp = "RD", valdatum = "2026-09-13", test = FALSE,
    valomrade = list(
      kod = "00", namn = "Riket",
      valkretsLista = list(
        node("01", "Krets 1", qualified),
        node("02", "Krets 2")
      )
    )
  )
  list(
    kandidaturer = kandidaturer,
    kandidater = make_kandidater_2026(kandidaturer),
    rost = rost,
    mandat = mandat
  )
}

test_that("person vote areas have the fixed public schema, key and 0-1 shares", {
  x <- personrostomrades_fixture()
  out <- .personrostomraden_2026(x$kandidaturer, x$kandidater, x$rost, x$mandat) |>
    dplyr::mutate(valar = 2026L, .after = valtillfalle)
  expect_identical(
    names(out),
    readLines(test_path("fixtures", "personroster-public-columns.txt"))
  )
  expect_identical(unname(vapply(out, typeof, "")), c(
    "character", "integer", rep("character", 13L), "integer", "integer", "double",
    "logical", "character", "character", "logical"))
  key <- c("valtillfalle", "valtyp", "geografiniva", "valomradeskod",
           "personvalsomradeskod", "partikod", "kandidatnummer")
  expect_equal(nrow(dplyr::distinct(out, dplyr::across(dplyr::all_of(key)))), nrow(out))
  expect_false(any(vapply(out, is.list, logical(1))))
  expect_type(out$antal_personroster, "integer")
  expect_type(out$antal_partiroster, "integer")
  expect_type(out$andel_personroster, "double")
  expect_type(out$kvalificerad_personval, "logical")
  expect_true(all(out$andel_personroster >= 0 & out$andel_personroster <= 1))

  anna <- dplyr::filter(out, kandidatnummer == "1")
  expect_identical(anna$antal_personroster, c(3L, 4L))
  expect_equal(anna$andel_personroster, c(0.3, 0.4))
  expect_identical(anna$kvalificerad_personval, c(TRUE, FALSE))
  bo <- dplyr::filter(out, kandidatnummer == "2")
  expect_identical(bo$antal_personroster, c(0L, 0L))
  expect_identical(bo$andel_personroster, c(0, 0))
})

test_that("official personal votes override incomplete detail only in their area", {
  x <- personrostomrades_fixture(incomplete_first = TRUE)
  out <- .personrostomraden_2026(x$kandidaturer, x$kandidater, x$rost, x$mandat)
  anna <- dplyr::filter(out, kandidatnummer == "1")
  bo <- dplyr::filter(out, kandidatnummer == "2")
  expect_identical(anna$antal_personroster, c(3L, 4L))
  expect_identical(bo$antal_personroster, c(NA_integer_, 0L))
  expect_identical(bo$kvalificerad_personval, c(FALSE, FALSE))
  totals <- .personrosttotaler_fran_omraden_2026(out)
  expect_identical(
    dplyr::filter(totals, kandidatnummer == "1")$antal_personroster_totalt,
    7L
  )
  expect_identical(
    dplyr::filter(totals, kandidatnummer == "2")$antal_personroster_totalt,
    NA_integer_
  )
})

test_that("official personal votes are validated against complete detail and share", {
  x <- personrostomrades_fixture(official_votes = 4L)
  expect_error(
    .personrostomraden_2026(x$kandidaturer, x$kandidater, x$rost, x$mandat),
    "Officiellt personr"
  )
  x <- personrostomrades_fixture()
  x$mandat$valomrade$valkretsLista[[1]]$kvalificeradeForPersonvalLista[[1]]$
    andelPersonroster <- 31
  expect_error(
    .personrostomraden_2026(x$kandidaturer, x$kandidater, x$rost, x$mandat),
    "personr"
  )
})

test_that("undivided areas hide technical constituency codes", {
  x <- personrostomrades_fixture()
  x$kandidaturer <- dplyr::filter(x$kandidaturer, kandidatnummer == "1")[1, ] |>
    dplyr::mutate(
      valtyp = "KF", valomradeskod = "0114", valomradesnamn = "Kommun",
      valkretskod = "011400", valkretsnamn = "Kommun"
    )
  x$kandidater <- make_kandidater_2026(x$kandidaturer)
  x$rost$valtyp <- "KF"
  x$rost$antalValdistriktRaknade <- 1L
  x$rost$antalValdistriktSomSkaRaknas <- 1L
  x$rost$valdistrikt <- x$rost$valdistrikt[1]
  x$rost$valdistrikt[[1]]$valomradeskod <- "0114"
  x$rost$valdistrikt[[1]]$kretskod <- "011400"
  x$mandat$valtyp <- "KF"
  root <- x$mandat$valomrade$valkretsLista[[1]]
  root$kod <- "0114"
  root$namn <- "Kommun"
  root$namnValkrets <- NULL
  root$valkretsLista <- list()
  x$mandat$valomrade <- root

  out <- .personrostomraden_2026(x$kandidaturer, x$kandidater, x$rost, x$mandat)
  expect_identical(out$geografiniva, "kommun")
  expect_identical(out$personvalsomradeskod, "0114")
  expect_identical(out$valkretskod, NA_character_)
  expect_identical(out$valkretsnamn, NA_character_)
  expect_identical(out$valomradesnamn, "Upplands Väsby")
  expect_identical(out$personvalsomradesnamn, "Upplands Väsby")
  expect_false(any(c("kommunkod", "kommunnamn", "kommunnamn_officiellt") %in% names(out)))
})

test_that("RF person vote geography distinguishes divided and undivided areas", {
  x <- personrostomrades_fixture()
  x$mandat$valtyp <- "RF"
  x$mandat$valomrade$kod <- "01"
  x$mandat$valomrade$namn <- "Region"
  x$mandat$valomrade$valkretsLista[[1]]$kod <- "0101"
  x$mandat$valomrade$valkretsLista[[1]]$namnValkrets <- "Regionkrets"
  divided <- .personvalsomraden_mandat_2026(x$mandat)
  expect_identical(divided$geografiniva, rep("regionvalkrets", 2))
  expect_identical(divided$personvalsomradeskod[[1]], "0101")

  root <- x$mandat$valomrade$valkretsLista[[1]]
  root$kod <- "01"
  root$namn <- "Region"
  root$namnValkrets <- NULL
  root$valkretsLista <- list()
  x$mandat$valomrade <- root
  undivided <- .personvalsomraden_mandat_2026(x$mandat)
  expect_identical(undivided$geografiniva, "region")
  expect_identical(undivided$personvalsomradeskod, "01")
  expect_identical(undivided$valkretskod, NA_character_)
})

test_that("public personroster validates arguments without file access", {
  local_mocked_bindings(
    kandidaturer = function(...) stop("Unexpected file access")
  )
  expect_error(personroster(detaljniva = "full", ar = 2024), "2022.*2026")
  expect_error(personroster(detaljniva = "full", val = "EU"), "valtyp")
  expect_error(personroster(detaljniva = "full", source = "invalid"), "arg")
  expect_error(personroster(detaljniva = "full", source = "local", update = TRUE), "local")
})

test_that("public personroster returns the shared area table", {
  x <- personrostomrades_fixture()
  expected <- .personrostomraden_2026(
    x$kandidaturer, x$kandidater, x$rost, x$mandat
  ) |>
    dplyr::mutate(valar = 2026L, .after = valtillfalle)
  local_mocked_bindings(
    kandidaturer = function(...) x$kandidaturer,
    .las_kandidatresultat_filer_2026 = function(...) {
      list(list(personrostomraden = expected))
    }
  )
  expect_identical(personroster(detaljniva = "full", val = "RD", progress = FALSE), expected)
  expect_identical(personroster(detaljniva = "full", val = "RD", komplettera_nollor = TRUE,
                               progress = FALSE), expected)
})
