.fixture_ersattare_slutlig <- function(ar, valtyp, indelad = TRUE) {
  kod <- c(RD = "00", RF = "01", KF = "0184")[[valtyp]]
  valkretskod <- if (indelad) paste0(kod, "01") else NA_character_
  parti <- list(
    partikod = "P", partibeteckning = "Parti P", partiforkortning = "P",
    antalMandat = 2L, antalTommaStolar = 0L,
    ledamoter = list(
      list(kandidatnummer = "1", namn = "Ledamot ett",
           ersattargrupp = "A", ersattareList = list(
             list(kandidatnummer = "3", namn = "Gemensam ersattare",
                  ersattarordning = 1L, valgrundId = "L"),
             list(kandidatnummer = "0", namn = "Kunde inte utses",
                  ersattarordning = 2L))),
      list(kandidatnummer = "2", namn = "Ledamot tva",
           ersattargrupp = "B", ersattareList = list(
             list(kandidatnummer = "3", namn = "Gemensam ersattare",
                  ersattarordning = 2L, valgrundId = "M")))
    )
  )
  nod <- list(
    kod = if (indelad) valkretskod else kod,
    namnValkrets = if (indelad) "Officiell valkrets" else NULL,
    antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
    mandatfordelning = list(partiLista = list(list(
      partikod = "P", antalMandat = 2L))),
    valda = list(partiLedamoterLista = list(parti))
  )
  if (indelad) {
    area <- list(kod = kod, namn = "Officiellt valomrade",
                 antalValdistriktRaknade = 1L,
                 antalValdistriktSomSkaRaknas = 1L,
                 valkretsLista = list(nod))
  } else {
    nod$namn <- "Solna stad"
    nod$valkretsLista <- list()
    area <- nod
  }
  list(
    raw = list(valtillfalle = if (ar == 2022L) "Val_20220911" else "Val_2026",
               rakningstillfalle = "slutlig", valtyp = valtyp,
               valdatum = paste0(ar, "-09-13"), valomrade = area),
    kandidaturer = tibble::tibble(
      kandidatnummer = c("1", "2", "3"), valtyp = valtyp,
      partikod = "P", giltig = TRUE,
      valkretskod = c(valkretskod, valkretskod, NA_character_)
    ),
    valkretskod = valkretskod
  )
}

test_that("2022 and 2026 RD, RF and KF retain official substitute relations", {
  for (ar in c(2022L, 2026L)) for (valtyp in c("RD", "RF", "KF")) {
    fixture <- .fixture_ersattare_slutlig(ar, valtyp,
      indelad = valtyp != "KF")
    out <- .ersattare_fran_raw(fixture$raw, ar)
    expect_identical(nrow(out), 2L)
    expect_identical(out$valar, rep(ar, 2))
    expect_identical(out$ersattare_kandidatnummer, c("3", "3"))
    expect_setequal(out$ledamot_kandidatnummer, c("1", "2"))
    expect_setequal(out$ersattarordning, c(1L, 2L))
    expect_setequal(out$ersattargrupp, c("A", "B"))
    expect_identical(unique(out$valkretskod), fixture$valkretskod)
    expect_false("antal_valkretsar" %in% names(out))
    expect_silent(.ersattare_validera_kandidater(out, fixture$kandidaturer))
  }
})

test_that("unfinished final nodes cannot produce substitute rows", {
  for (ar in c(2022L, 2026L)) {
    fixture <- .fixture_ersattare_slutlig(ar, "RD")
    fixture$raw$valomrade$valkretsLista[[1]]$valda <- NULL
    expect_error(.ersattare_fran_raw(fixture$raw, ar), "Slutlig")
    fixture <- .fixture_ersattare_slutlig(ar, "RD")
    fixture$raw$valomrade$antalValdistriktRaknade <- 0L
    expect_error(.ersattare_fran_raw(fixture$raw, ar), "Slutlig")
  }
})

test_that("substitute and member identifiers must match valid candidacies", {
  fixture <- .fixture_ersattare_slutlig(2022L, "RD")
  out <- .ersattare_fran_raw(fixture$raw, 2022L)
  fixture$kandidaturer$giltig[[3]] <- FALSE
  expect_error(.ersattare_validera_kandidater(out, fixture$kandidaturer),
               "ersattare_kandidatnummer")
})
