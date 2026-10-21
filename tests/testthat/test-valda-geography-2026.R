.fixture_elected_multiple_areas_2026 <- function(valtyp = "KF") {
  codes <- if (valtyp == "KF") c("0128", "0120") else c("01", "03")
  kd <- fixture_kandidaturer()[4, ] |>
    dplyr::mutate(valtyp = .env$valtyp, kandidatnummer = "1", partikod = "P",
                  oppen_lista = FALSE, pa_namnvalsedel = TRUE)
  kd <- dplyr::bind_rows(lapply(codes, function(code) dplyr::mutate(kd,
    valomradeskod = code, valomradesnamn = paste("Area", code),
    valkretskod = paste0(code, "01"), valkretsnamn = "Constituency")))
  make_raw <- function(code, votes, elected) {
    node <- list(kod = paste0(code, "01"), namnValkrets = "Constituency",
      antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
      kvalificeradeForPersonvalLista = list(),
      valda = list(partiLedamoterLista = if (elected) list(list(
        partikod = "P", antalTommaStolar = 0L,
        ledamoter = list(list(kandidatnummer = "1", namn = "Candidate",
                              invalsordning = 1L)))) else list()),
      mandatfordelning = list(partiLista = list(list(
        partikod = "P", antalMandat = as.integer(elected)))),
      rostfordelning = list(rosterPaverkaMandat = list(
        antalRoster = 10L, rosterOvrigaPartier = list(antalRoster = 0L),
        partiRoster = list(list(partikod = "P", antalRoster = 10L,
          summeradePersonroster = list(list(kandidatnummer = "1",
                                            antalPersonroster = votes)),
          listRoster = list(list(listnummer = "P-1", antalRoster = 10L,
            antalRosterMedPersonrost = votes, personroster = list(list(
              kandidatNummer = "1", antalPersonroster = votes)))))))))
    area <- if (valtyp == "RF") list(kod = code, namn = paste("Area", code),
      antalValdistriktRaknade = 1L, antalValdistriktSomSkaRaknas = 1L,
      valkretsLista = list(node)) else {
        node$kod <- code; node$namn <- paste("Area", code); node$valkretsLista <- list()
        node
      }
    list(valtillfalle = "Val_2026", valtyp = valtyp,
         rakningstillfalle = "slutlig", valomrade = area)
  }
  list(kd = kd, raw = list(make_raw(codes[1], 3L, TRUE),
                           make_raw(codes[2], 4L, FALSE)))
}

test_that("2026 elected joins use the file area and aggregate all candidacy areas", {
  for (valtyp in c("KF", "RF")) {
    f <- .fixture_elected_multiple_areas_2026(valtyp)
    bas <- .kandidater_bas(f$kd, 2026L)
    parsed <- lapply(f$raw, .valda_parsad_raw_2026,
                      kandidaturdata = f$kd, kandidater_bas = bas)
    expect_identical(parsed[[1]]$personrostomraden$antal_personroster, 3L)
    expect_identical(parsed[[2]]$personrostomraden$antal_personroster, 4L)
    out <- .valda_fran_parsade_2022(parsed, f$kd, bas, valtyp)
    expect_identical(out$kandidatnummer, "1")
    expect_identical(out$antal_personroster_totalt, 7L)
    expect_identical(out$invald_valomradeskod, f$raw[[1]]$valomrade$kod)
    expect_identical(out$invalsordning, 1L)
    expect_false(anyDuplicated(out[c("kandidatnummer", "valtyp", "partikod")]) > 0L)
  }
})

test_that("2026 elected still rejects an actual missing elected party row", {
  f <- .fixture_elected_multiple_areas_2026()
  f$raw[[1]]$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster <- list()
  f$raw[[1]]$valomrade$rostfordelning$rosterPaverkaMandat$antalRoster <- 0L
  expect_error(.valda_parsad_raw_2026(f$raw[[1]], f$kd,
    .kandidater_bas(f$kd, 2026L)), "saknar relevant partirad")
})

test_that("absent unelected party is unknown rather than a fabricated zero", {
  f <- .fixture_elected_multiple_areas_2026()
  extra <- dplyr::mutate(f$kd[1, ], kandidatnummer = "2", partikod = "Q")
  kd <- dplyr::bind_rows(f$kd, extra)
  parsed <- .valda_parsad_raw_2026(f$raw[[1]], kd, .kandidater_bas(kd, 2026L))
  expect_identical(parsed$personrostomraden$kandidatnummer, c("1", "2"))
  expect_identical(parsed$personrostomraden$antal_personroster, c(3L, NA_integer_))
})

test_that("public 2026 elected reads final files once and keeps area-wide enrichment", {
  f <- .fixture_elected_multiple_areas_2026()
  paths <- c("s/kf/Val_2026_slutlig_0128_KF.zip", "s/kf/Val_2026_slutlig_0120_KF.zip")
  reads <- character()
  local_mocked_bindings(
    .read_resultatindex = function(...) tibble::tibble(path = paths),
    kandidaturer = function(...) f$kd,
    .resultat_file = function(ar, path, ...) path,
    read_raw_json_zip_2026 = function(file, type) {
      expect_identical(type, "mandatfordelning")
      reads <<- c(reads, file)
      f$raw[[match(file, paths)]]
    }
  )
  out <- valda(ar = 2026, val = "KF", source = "remote", detaljniva = "full")
  expect_identical(reads, paths)
  expect_identical(out$antal_personroster_totalt, 7L)
  expect_identical(out$invald_valomradeskod, "0128")
})
