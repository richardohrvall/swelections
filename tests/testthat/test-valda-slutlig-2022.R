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

test_that("2022 global elected enrichment preserves requested file order", {
  rd <- .fixture_valda_slutlig_2022("RD")
  rf <- .fixture_valda_slutlig_2022("RF")
  kd <- dplyr::bind_rows(rd$kandidaturer, rf$kandidaturer)
  bas <- .kandidater_bas(kd, 2022L)
  parsed <- lapply(list(rf$raw, rd$raw), .valda_parsad_raw_2022,
                   kandidaturdata = kd, kandidater_bas = bas)
  out <- .valda_fran_parsade_2022(parsed, kd, bas, c("RF", "RD"))
  expect_identical(out$valtyp, c("RF", "RD"))
  expect_identical(out$antal_personroster_totalt, c(1L, 1L))
})

test_that("2022 elected enrichment uses all final candidacy areas", {
  cases <- tibble::tibble(
    id = c("35910", "12565", "39734"),
    party = c("1439", "0110", "1439"),
    elected_area = c("0127", "0481", "1282"),
    other_area = c("1480", "0480", "1280"),
    local_votes = c(454L, 54L, 324L),
    total_votes = c(3575L, 205L, 477L)
  )
  for (i in seq_len(nrow(cases))) {
    for (valtyp in c("KF", "RF")) {
      fixture <- .fixture_valda_slutlig_2022(valtyp, indelad = FALSE)
      make_raw <- function(kod, votes, elected) {
        raw <- fixture$raw
        raw$valomrade$kod <- kod
        raw$valomrade$namn <- paste("Area", kod)
        raw$valomrade$valda$partiLedamoterLista <- if (elected) list(list(
          partikod = cases$party[i], ledamoter = list(list(
            kandidatnummer = cases$id[i], namn = "Anna Andersson",
            invalsordning = 1L)))) else list()
        raw$valomrade$mandatfordelning$partiLista <- list(list(
          partikod = cases$party[i], antalMandat = as.integer(elected)))
        raw$valomrade$kvalificeradeForPersonvalLista <- list(list(
          kandidatnummer = cases$id[i], partikod = cases$party[i],
          antalPersonroster = votes))
        p <- raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
        p$partikod <- cases$party[i]
        p$antalRoster <- votes
        p$listRoster[[1]]$antalRoster <- votes
        p$listRoster[[1]]$antalRosterMedPersonrost <- votes
        p$listRoster[[1]]$personroster[[1]] <- list(
          kandidatNummer = cases$id[i], antalPersonroster = votes)
        raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster <- list(p)
        raw
      }
      codes <- if (valtyp == "KF")
        c(cases$elected_area[i], cases$other_area[i]) else c("01", "03")
      raws <- list(make_raw(codes[1], cases$local_votes[i], TRUE),
                   make_raw(codes[2], cases$total_votes[i] - cases$local_votes[i], FALSE))
      before <- serialize(raws, NULL)
      kd <- dplyr::bind_rows(lapply(codes, function(kod)
        dplyr::mutate(fixture$kandidaturer,
          kandidatnummer = cases$id[i], partikod = cases$party[i],
          valomradeskod = kod, valomradesnamn = paste("Area", kod))))
      bas <- .kandidater_bas(kd, 2022L)
      paths <- paste0("s/", tolower(valtyp), "/Val_20220911_", codes, "_", valtyp, ".zip")
      local_mocked_bindings(
        .read_resultatindex = function(...) tibble::tibble(path = paths),
        .resultat_file = function(ar, path, ...) path,
        read_raw_json_zip_2026 = function(file, ...) raws[[match(file, paths)]],
        kandidaturer = function(...) kd
      )
      elected <- .valda_ett_ar(2022L, valtyp, "local", tempdir(), FALSE, FALSE, FALSE)
      candidates <- .add_kandidatresultat_2022(
        bas, kd, valtyp, "local", tempdir(), FALSE, FALSE, FALSE)
      expect_identical(elected$antal_personroster_totalt, cases$total_votes[i])
      expect_identical(elected$antal_personroster_totalt,
                       candidates$antal_personroster_totalt)
      expect_identical(elected$antal_personvalsomraden, 2L)
      expect_identical(elected$antal_personvalsomraden,
                       candidates$antal_personvalsomraden)
      expect_identical(elected$invald_valomradeskod, codes[1])
      expect_identical(nrow(elected), 1L)
      expect_identical(serialize(raws, NULL), before)
    }
  }
})
