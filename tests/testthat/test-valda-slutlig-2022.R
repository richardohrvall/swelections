.fixture_valda_slutlig_2022 <- function(valtyp, indelad = TRUE,
                                      tom_stol = FALSE) {
  kod <- c(RD = "00", RF = "01", KF = "0180")[[valtyp]]
  valkretskod <- if (indelad) paste0(kod, "01") else NA_character_
  ledamoter <- list(list(kandidatnummer = "1", namn = "Anna Andersson",
                        invalsordning = 1L))
  if (tom_stol) {
    ledamoter[[2]] <- list(kandidatnummer = "0", namn = "Kunde inte utses",
                          invalsordning = 2L)
  }
  nod <- list(
    kod = if (indelad) valkretskod else kod,
    namnValkrets = if (indelad) "Officiell valkrets" else NULL,
    antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
    kvalificeradeForPersonvalLista = list(),
    valda = list(partiLedamoterLista = list(list(
      partikod = "P", ledamoter = ledamoter))),
    mandatfordelning = list(partiLista = list(list(
      partikod = "P", antalMandat = length(ledamoter)))),
    rostfordelning = list(
      rosterPaverkaMandat = list(
        rosterOvrigaPartier = list(antalRoster = 0L),
        partiRoster = list(list(partikod = "P", antalRoster = 2L,
          listRoster = list(list(listnummer = "2022-1", antalRoster = 2L,
            antalRosterMedPersonrost = 1L,
            personroster = list(list(kandidatNummer = "1",
                                      antalPersonroster = 1L))))))),
      rosterEjPaverkaMandat = list(partiRoster = list())
    )
  )
  area <- if (indelad) list(
    kod = kod, namn = "Officiellt valområde",
    antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
    valkretsLista = list(nod)
  ) else {
    nod$namn <- "Officiellt valområde"
    nod$valkretsLista <- list()
    nod
  }
  raw <- list(valtillfalle = "Val_20220911", valtyp = valtyp,
              rakningstillfalle = "slutlig", valomrade = area)
  kd <- dplyr::filter(fixture_kandidaturer(), kandidatnummer == "1",
                      valtyp == "KF") |>
    dplyr::mutate(
      valtillfalle = "Val_2022", valtyp = .env$valtyp,
      valomradeskod = kod, valomradesnamn = "Officiellt valområde",
      valkretskod = .env$valkretskod,
      valkretsnamn = if (indelad) "Officiell valkrets" else NA_character_,
      partikod = "P", oppen_lista = FALSE, pa_namnvalsedel = TRUE
    )
  list(raw = raw, kandidaturer = kd,
       kandidater = .kandidater_bas(kd, 2022L))
}

test_that("final 2022 RD, RF and KF use official elected nodes", {
  for (valtyp in c("RD", "RF", "KF")) {
    fixture <- .fixture_valda_slutlig_2022(valtyp,
      indelad = valtyp != "KF", tom_stol = valtyp == "KF")
    out <- .valda_fran_raw_2022(
      fixture$raw, fixture$kandidaturer, fixture$kandidater) |>
      .valda_invaldsvalkrets_2026() |>
      dplyr::select(-antal_valkretsar)
    expect_identical(nrow(out), 1L)
    expect_identical(out$kandidatnummer, "1")
    expect_identical(out$valtyp, valtyp)
    expect_identical(out$antal_personroster_totalt, 1L)
    expect_identical(out$valar, 2022L)
    expect_identical(names(out)[1:2], c("valtillfalle", "valar"))
    expect_false("antal_valkretsar" %in% names(out))
    expect_identical(out$valkretskod,
                     if (valtyp == "KF") NA_character_ else
                       paste0(c(RD = "00", RF = "01")[[valtyp]], "01"))
  }
})

test_that("missing or unfinished final 2022 elected node is an error", {
  fixture <- .fixture_valda_slutlig_2022("KF", indelad = FALSE)
  fixture$raw$valomrade$valda <- NULL
  expect_error(.valda_fran_raw_2022(
    fixture$raw, fixture$kandidaturer, fixture$kandidater),
    "Slutlig invaldsrelation 2022")
  fixture$raw$valomrade$valda <- list(partiLedamoterLista = list())
  fixture$raw$valomrade$antalValdistriktRaknade <- 0L
  expect_error(.valda_fran_raw_2022(
    fixture$raw, fixture$kandidaturer, fixture$kandidater),
    "Slutlig invaldsrelation 2022")
})
