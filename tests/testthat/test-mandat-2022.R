mandat_2022_fixture <- function(val = "RD", rakning = "slutlig") {
  kod <- switch(val, RD = "00", RF = "01", KF = "0180")
  vk <- switch(val, RD = "01", RF = "0101", KF = "018001")
  parti <- list(partibeteckning = "Parti A", partiforkortning = "A",
                partikod = "A", antalMandat = 2L,
                antalFastaMandat = 2L, antalUtjamningsmandat = 0L)
  nod <- function(kod, namn) {
    list(kod = kod, namnValkrets = namn, antalValdistriktRaknade = 1L,
         antalValdistriktSomSkaRaknas = 1L,
         mandatfordelning = list(partiLista = list(parti)),
         valda = list(partiLedamoterLista = list(list(
           partikod = "A", ledamoter = list(list(kandidatnummer = "1"))
         ))))
  }
  omrade <- nod(kod, "Område")
  omrade$namn <- "Område"
  omrade$valkretsLista <- list(nod(vk, "Valkrets"))
  # I indelade valområden finns valda i valkretsen men inte på områdesnivån.
  omrade$valda <- NULL
  list(valtillfalle = "Val_2022", valtyp = val,
       rakningstillfalle = rakning, valomrade = omrade)
}

test_that("2022 mandate totals and historical missingness are typed", {
  raw <- mandat_2022_fixture()
  out <- parse_mandat_2026(raw)
  expect_identical(unique(out$totalt_antal_mandat), 2L)
  expect_identical(unique(out$antal_mandat), 2L)
  for (name in c("antal_mandat_fg", "antal_fasta_mandat_fg",
                 "antal_utjamningsmandat_fg", "totalt_antal_mandat_fg",
                 "totalt_antal_fasta_mandat_fg",
                 "totalt_antal_utjamningsmandat_fg", "diff_antal_mandat")) {
    expect_type(out[[name]], "integer")
    expect_true(all(is.na(out[[name]])), info = name)
  }
  raw$valomrade$mandatfordelning$partiLista[[1]]$antalMandat <- 0L
  expect_identical(parse_mandat_2026(raw)$antal_mandat[[1]], 0L)
  raw$valomrade$mandatfordelning$partiLista[[1]]$antalMandat <- NULL
  expect_true(is.na(parse_mandat_2026(raw)$totalt_antal_mandat[[1]]))
  raw$valomrade$mandatfordelning <- NULL
  expect_false(any(parse_mandat_2026(raw)$geografiniva == "riket"))
})

test_that("2022 vacancy markers differ from elected people and incomplete data", {
  raw <- mandat_2022_fixture()
  expect_equal(nrow(parse_tomma_stolar_2022(raw)), 0L)
  elected <- raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]]
  elected$ledamoter[[2]] <- list(kandidatnummer = 0L, invalsordning = 0L,
                                namn = "Kunde inte utses", valgrundId = 0L)
  raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]] <- elected
  out <- parse_tomma_stolar_2022(raw)
  expect_identical(out$geografiniva, c("riket", "riksdagsvalkrets"))
  expect_identical(out$antal_tomma_stolar, c(1L, 1L))
  elected$ledamoter[[2]] <- list(kandidatnummer = "2", namn = "Vald person")
  raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]] <- elected
  expect_identical(parse_tomma_stolar_2022(raw)$antal_tomma_stolar, c(0L, 0L))
  raw$valomrade$valkretsLista[[1]]$antalValdistriktRaknade <- 0L
  expect_equal(nrow(parse_tomma_stolar_2022(raw)), 0L)
  raw$valomrade$valkretsLista[[1]]$antalValdistriktRaknade <- 1L
  elected$ledamoter[[3]] <- list(kandidatnummer = "3")
  raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]] <- elected
  expect_error(parse_tomma_stolar_2022(raw), "verstiger")
  elected$ledamoter <- list(elected$ledamoter[[1]],
                            list(kandidatnummer = 0L, namn = "Fel markör"))
  raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]] <- elected
  expect_error(parse_tomma_stolar_2022(raw), "Motstridig platsmark")
  raw$rakningstillfalle <- "preliminar"
  expect_equal(nrow(parse_tomma_stolar_2022(raw)), 0L)
})

test_that("2022 municipality vacancies sum complete constituency markers", {
  raw <- mandat_2022_fixture("KF")
  raw$valomrade$kod <- "2284"
  vk <- raw$valomrade$valkretsLista[[1]]
  vk$kod <- "228401"
  vk$mandatfordelning$partiLista[[1]]$antalMandat <- 1L
  vk$valda$partiLedamoterLista[[1]]$ledamoter <-
    list(list(kandidatnummer = 0L, namn = "Kunde inte utses"))
  other <- vk
  other$kod <- "228402"
  other$valda$partiLedamoterLista[[1]]$ledamoter <-
    list(list(kandidatnummer = "1", namn = "Vald person"))
  raw$valomrade$valkretsLista <- list(vk, other)
  out <- parse_tomma_stolar_2022(raw)
  expect_identical(out$antal_tomma_stolar, c(1L, 1L, 0L))
  expect_identical(out$geografiniva,
                   c("kommun", "kommunvalkrets", "kommunvalkrets"))
  raw$valomrade$valkretsLista[[2]]$valda <- NULL
  expect_false(any(parse_tomma_stolar_2022(raw)$geografiniva == "kommun"))
  raw$valomrade$valkretsLista[[2]] <- other
  raw$valomrade$valkretsLista[[1]]$valda$partiLedamoterLista[[1]]$ledamoter <-
    list(list(kandidatnummer = "1", namn = "Vald person"))
  expect_false(any(parse_tomma_stolar_2022(raw)$geografiniva == "kommun"))
})

test_that("official 2022 KF vacancy cases total 17 in source-shaped fixtures", {
  cases <- tibble::tribble(
    ~valomradeskod, ~partikod, ~antal_mandat, ~antal_tomma_stolar,
    "1762", "0001", 1L, 1L, "1814", "0110", 5L, 2L,
    "1860", "0110", 3L, 2L, "1861", "0068", 2L, 1L,
    "2026", "0110", 4L, 2L, "2284", "0110", 6L, 1L,
    "2401", "0110", 3L, 2L, "2404", "0110", 2L, 1L,
    "2422", "0001", 3L, 1L, "2425", "0110", 6L, 3L,
    "2481", "0110", 2L, 1L
  )
  parsed <- purrr::map_dfr(seq_len(nrow(cases)), function(i) {
    raw <- mandat_2022_fixture("KF")
    raw$valomrade$kod <- cases$valomradeskod[[i]]
    raw$valomrade$valkretsLista <- list()
    raw$valomrade$mandatfordelning$partiLista[[1]]$partikod <-
      cases$partikod[[i]]
    raw$valomrade$mandatfordelning$partiLista[[1]]$antalMandat <-
      cases$antal_mandat[[i]]
    ordinarie <- lapply(seq_len(cases$antal_mandat[[i]] -
                               cases$antal_tomma_stolar[[i]]), function(n) {
      list(kandidatnummer = as.character(n), namn = paste("Kandidat", n))
    })
    markorer <- rep(list(list(kandidatnummer = 0L,
                              namn = "Kunde inte utses")),
                    cases$antal_tomma_stolar[[i]])
    raw$valomrade$valda <- list(partiLedamoterLista = list(list(
      partikod = cases$partikod[[i]],
      ledamoter = c(ordinarie, markorer)
    )))
    parse_tomma_stolar_2022(raw)
  })
  expect_identical(parsed$valomradeskod, cases$valomradeskod)
  expect_identical(parsed$partikod, cases$partikod)
  expect_identical(parsed$antal_tomma_stolar, cases$antal_tomma_stolar)
  expect_identical(sum(parsed$antal_tomma_stolar), 17L)
})

test_that("mandat uses shared year selection and preserves the long contract", {
  paths <- function(ar) tibble::tibble(path = vapply(c("RD", "RF", "KF"),
    function(val) paste0("s/", tolower(val), "/Val_",
                         if (ar == 2022L) "20220911" else "2026",
                         "_slutlig_", switch(val, RD = "00", RF = "01", KF = "0180"),
                         "_", val, ".zip"), ""))
  local_mocked_bindings(
    .read_resultatindex = function(ar, ...) paths(ar),
    .resultat_file = function(ar, path, ...) path,
    .read_valresultat_raw = function(file, kalla, val, rakning, ...) {
      mandat_2022_fixture(val, rakning)
    },
    read_raw_json_zip_2026 = function(file, ...) {
      val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", file)
      raw <- mandat_2022_fixture(val)
      raw$valtillfalle <- "Val_2026"
      raw$valomrade$valkretsLista[[1]]$valda <- NULL
      raw
    }
  )
  cases <- list(RD = c("riket", "riksdagsvalkrets"),
                RF = c("region", "regionvalkrets"),
                KF = c("kommun", "kommunvalkrets"))
  for (val in names(cases)) for (niva in cases[[val]]) {
    a <- mandat(detaljniva = "full", ar = 2022, val = val, niva = niva, progress = FALSE)
    b <- mandat(detaljniva = "full", ar = 2026, val = val, niva = niva, progress = FALSE)
    both <- mandat(detaljniva = "full", ar = c(2022, 2026), val = val, niva = niva,
                   progress = FALSE)
    expect_identical(both, dplyr::bind_rows(a, b), info = paste(val, niva))
    expect_identical(names(both)[1:2], c("valtillfalle", "valar"))
    expect_type(both$valar, "integer")
    expect_identical(unique(both$valar), c(2022L, 2026L))
    expect_identical(mandat(detaljniva = "full", fran = 2021, till = 2026, val = val, niva = niva,
                            progress = FALSE), both)
    expect_identical(mandat(detaljniva = "full", ar = c(2026, 2022, 2026), val = val,
                            niva = niva, progress = FALSE),
                     dplyr::bind_rows(b, a))
  }
})

test_that("mandat rejects bad year and level before source access", {
  calls <- 0L
  local_mocked_bindings(.read_resultatindex = function(...) { calls <<- calls + 1L })
  expect_error(mandat(detaljniva = "full", ar = c(2022, 2026), val = "RD", niva = "kommun"),
               "kommun")
  expect_error(mandat(detaljniva = "full", ar = 2024, val = "RD"), "2022.*2026")
  expect_error(mandat(detaljniva = "full", ar = 2022, fran = 2022), "ar.*fran")
  expect_equal(calls, 0L)
})
