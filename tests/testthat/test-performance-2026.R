test_that("batched mandate relations preserve source order, types and vacancies", {
  for (val in c("RD", "RF", "KF")) for (divided in c(TRUE, FALSE)) {
    member <- function(id, subs) list(kandidatnummer = id, namn = paste("Member", id),
      invalsordning = as.integer(id), ersattargrupp = paste0("G", id),
      ersattareList = subs)
    sub <- function(id, order) list(kandidatnummer = id, namn = paste("Sub", id),
      ersattarordning = order, valgrundId = "L")
    party <- list(partikod = "001", partibeteckning = "Party", ledamoter = list(
      member("2", list(sub("8", 2L), sub("9", 1L))),
      member("1", list(sub("8", 1L))), member("0", list())))
    node <- list(kod = "0101", namnValkrets = "Constituency",
      valda = list(partiLedamoterLista = list(party, list(ledamoter = list()))))
    raw <- list(valtyp = val, valtillfalle = "Val_2026", test = FALSE,
      rakningstillfalle = "slutlig", valdatum = "2026-09-13",
      valomrade = if (divided) list(kod = "01", namn = "Area",
        valkretsLista = list(node)) else c(list(namn = "Area"), node))
    got <- parse_valda_ersattare_2026(raw)
    expect_identical(got$valda$kandidatnummer, c("2", "1", "0"))
    expect_identical(got$valda$invalsordning, c(2L, 1L, 0L))
    expect_identical(got$ersattare$ledamot_kandidatnummer, c("2", "2", "1"))
    expect_identical(got$ersattare$ersattare_kandidatnummer, c("8", "9", "8"))
    expect_identical(got$ersattare$ersattarordning, c(2L, 1L, 1L))
    expect_identical(got$ersattare$ersattargrupp, c("G2", "G2", "G1"))
    expect_true(all(is.na(got$valda$valgrund_id)))
    expect_identical(got$valda$partikod, rep("001", 3L))
    expect_identical(got$valda$test, rep(FALSE, 3L))
    raw$valomrade <- list(kod = "01", namn = "Area", valda = NULL)
    empty <- parse_valda_ersattare_2026(raw)
    expect_identical(names(empty$valda), names(got$valda))
    expect_identical(names(empty$ersattare), names(got$ersattare))
    expect_identical(vapply(empty$valda, typeof, ""), vapply(got$valda, typeof, ""))
    expect_identical(vapply(empty$ersattare, typeof, ""),
      vapply(got$ersattare, typeof, ""))
    expect_identical(nrow(empty$valda), 0L)
    expect_identical(nrow(empty$ersattare), 0L)
  }
})

test_that("batched district candidate groups retain first-seen order and verified zeros", {
  candidate <- function(id, votes) list(kandidatnummer = id, antalPersonroster = votes)
  party <- function(votes) list(partikod = "P", antalRoster = 10L,
    summeradePersonroster = votes,
    listRoster = list(list(listnummer = "P-1", antalRosterMedPersonrost =
      sum(vapply(votes, function(r) r$antalPersonroster, 0L)),
      personroster = lapply(votes, function(r) list(kandidatNummer = r$kandidatnummer,
        antalPersonroster = r$antalPersonroster)))))
  district <- function(id, votes) list(valomradeskod = "01", kommunkod = "0180",
    valdistriktskod = id, valdistriktstyp = "valdistrikt", kretskod = "0101",
    rostfordelning = list(rosterPaverkaMandat = list(partiRoster = list(party(votes)))))
  raw <- list(valtyp = "RF", rakningstillfalle = "slutlig",
    antalValdistriktSomSkaRaknas = 2L, antalValdistriktRaknade = 2L,
    valdistrikt = list(district("2", list(candidate("9", 0L), candidate("1", 3L))),
      district("1", list(candidate("1", 2L), candidate("8", 1L)))))
  areas <- tibble::tibble(personvalsomradeskod = "0101", valkretskod = "0101")
  got <- .personrostomradesunderlag_2026(raw, "01", areas)
  expect_identical(got$status$personroster_available, TRUE)
  expect_identical(got$status$antal_partiroster_distrikt, 20L)
  expect_identical(got$roster$kandidatnummer, c("9", "1", "8"))
  expect_identical(got$roster$antal_personroster_summerat, c(0L, 5L, 1L))
  raw$antalValdistriktRaknade <- 1L
  incomplete <- .personrostomradesunderlag_2026(raw, "01", areas)
  expect_true(is.na(incomplete$status$personroster_available))
  expect_identical(nrow(incomplete$roster), 0L)
})

test_that("grouped relations retain legacy dollar lookup and invalid-record errors", {
  withr::local_options(list(warnPartialMatchDollar = FALSE))
  sub <- list(kandidatnummer_source = "8", ersattarordning_source = 3L)
  member <- list(kandidatnummer_source = "7", namn_source = "Source name",
    invalsordning_source = 2L, ersattareList = list(sub))
  raw <- list(valtyp = "KF", rakningstillfalle = "slutlig",
    valomrade = list(kod = "0180", namn = "Area", valda = list(
      partiLedamoterLista = list(list(partikod = "P", ledamoter = list(member))))))
  got <- parse_valda_ersattare_2026(raw)
  expect_identical(got$valda$kandidatnummer, "7")
  expect_identical(got$valda$namn, "Source name")
  expect_identical(got$valda$invalsordning, 2L)
  expect_identical(got$ersattare$ersattare_kandidatnummer, "8")
  expect_identical(got$ersattare$ersattarordning, 3L)
  raw$valomrade$valda$partiLedamoterLista[[1]]$ledamoter[[1]]$
    ersattareList <- list(NULL, sub)
  missing <- parse_valda_ersattare_2026(raw)
  expect_identical(missing$ersattare$ersattare_kandidatnummer, c(NA_character_, "8"))
  raw$valomrade$valda$partiLedamoterLista[[1]]$ledamoter[[1]]$
    ersattareList <- list("invalid record")
  expect_error(parse_valda_ersattare_2026(raw), "invalid for atomic")
})
