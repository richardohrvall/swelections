personroster_list_fixture_2022 <- function() {
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

personroster_2022_fixture <- function() {
  x <- personroster_list_fixture_2022()
  x$mandat$valtillfalle <- "Val_20220911"
  x$mandat$valomrade$antalValdistriktRaknade <- 2L
  x$mandat$valomrade$antalValdistriktSomSkaRaknas <- 2L
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterEjPaverkaMandat <- list(antalRoster = 0L)
  for (i in seq_along(x$rost$valdistrikt)) {
    x$rost$valdistrikt[[i]]$rostfordelning$
      rosterEjPaverkaMandat <- list(antalRoster = 0L)
  }
  x$kandidaturer$pa_namnvalsedel <- c(TRUE, FALSE, TRUE, FALSE)
  x
}

test_that("canonical 2022 person bases reproduce all raw views and missingness", {
  skip_if_not_installed("nanoparquet")
  x <- personroster_2022_fixture()
  local_mocked_bindings(.resultat_file = function(...) "fixture.zip",
    read_raw_json_zip_2026 = function(file, type) {
      if (type == "mandatfordelning") x$mandat else x$rost
    }, .kandidater_bas = function(...) x$kandidater)
  for (incomplete in c(FALSE, TRUE)) {
    if (incomplete) x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
      rosterPaverkaMandat$partiRoster[[1]]$listRoster[[2]]$personroster <- NULL
    for (level in c("personvalsomrade", "valdistrikt")) {
      m <- .normalisera_resultat_2022(x$mandat)
      g <- .personroster_2022_geografi(m,
        if (level == "valdistrikt") x$rost else NULL)
      p <- .personroster_2022_population(x$kandidaturer, g$indelad)
      k <- .personroster_2022_kallrader(g$noder, g$geo,
        strikt_listtotal = level == "personvalsomrade")
      p <- .personroster_2022_observerade(p, k$roster)
      parts <- c(k, list(geo = g$geo,
        omraden = dplyr::select(g$omraden, -".personval_nod"),
        officiella = .personval_officiella_2026(g$omraden),
        metadata = tibble::tibble(valtillfalle = m$valtillfalle,
          valtyp = "RD", valdatum = m$valdatum, test = m$test)),
        stats::setNames(p[c("kandidat", "lista", "alla")],
                        paste0("population_", c("kandidat", "lista", "alla"))))
      parts <- lapply(parts, function(data) {
        data$.source_area <- rep("00", nrow(data)); .canonical_names_en(data)
      })
      asset <- paste0("rkl2022-preference-votes-base-",
        if (level == "valdistrikt") "district" else "area", "-rd")
      layouts <- data.frame(asset = asset, table = names(parts),
        columns = vapply(parts, function(z) paste(names(z), collapse = ","), ""))
      combined <- dplyr::bind_rows(lapply(names(parts), function(component) {
        out <- parts[[component]]
        out$.component <- rep(component, nrow(out)); out
      }))
      file <- tempfile(fileext = ".parquet")
      nanoparquet::write_parquet(combined, file)
      roundtrip <- tibble::as_tibble(nanoparquet::read_parquet(file))
      unlink(file)
      fetch <- function(name) {
        if (name == "rkl2022-candidacies") return(.canonical_names_en(x$kandidaturer))
        if (name == "rkl2022-candidates") return(.canonical_names_en(x$kandidater))
        roundtrip
      }
      for (by_list in c(FALSE, TRUE)) for (zeros in c(FALSE, TRUE)) {
        expected <- .personroster_2022_fil(2022L, "fixture", "RD",
          x$kandidaturer, x$kandidater, "local", NULL, FALSE, FALSE,
          level, by_list, zeros) |>
          dplyr::arrange(.data$valtyp, .data$valomradeskod,
            .data$personvalsomradeskod, .data$partikod, .data$kandidatnummer,
            dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
        got <- .canonical_person_2022(list(tables = layouts, schema_version = 2L),
          fetch, "RD", level, by_list, zeros)
        expect_identical(got, expected)
      }
    }
  }
})

test_that("2022 area votes use validated official area lists", {
  x <- personroster_2022_fixture()
  g <- .personroster_2022_geografi(x$mandat)
  p <- .personroster_2022_population(x$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo)
  expect_silent(.personroster_2022_kontrollera_poster(k$roster, p))
  a <- .personroster_2022_omrade(k, p, g$geo, FALSE, FALSE)
  expect_identical(a$antal_personroster[match(c("1", "2"),
    a$kandidatnummer)], c(6L, 0L))
  expect_false("3" %in% a$kandidatnummer)
  sparse <- .personroster_2022_omrade(k, p, g$geo, TRUE, FALSE)
  full <- .personroster_2022_omrade(k, p, g$geo, TRUE, TRUE)
  expect_identical(sort(sparse$antal_personroster), c(3L, 3L))
  expect_equal(nrow(full), nrow(sparse) + 1L)
  expect_true(any(full$antal_personroster == 0L))
  expect_false(any(full$listnummer == "90000"))
  expect_true(all(!is.na(full$antal_personroster)))
  expect_true(any(!x$kandidaturer$pa_namnvalsedel &
    x$kandidaturer$kandidatnummer == "1"))
})

test_that("2022 district views use their own lists and verified zeros", {
  x <- personroster_2022_fixture()
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$personroster[[1]]$
    antalPersonroster <- 5L
  x$rost$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$listRoster[[1]]$antalRosterMedPersonrost <- 5L
  g <- .personroster_2022_geografi(x$mandat, x$rost)
  p <- .personroster_2022_population(x$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo,
    strikt_listtotal = FALSE)
  sparse <- .personroster_2022_distrikt(k, p, FALSE, FALSE)
  full <- .personroster_2022_distrikt(k, p, FALSE, TRUE)
  list_sparse <- .personroster_2022_distrikt(k, p, TRUE, FALSE)
  list_full <- .personroster_2022_distrikt(k, p, TRUE, TRUE)
  expect_true(nrow(full) > nrow(sparse))
  expect_true(nrow(list_full) > nrow(list_sparse))
  expect_false(any(is.na(full$antal_personroster)))
  expect_false(any(list_full$listnummer == "90000"))
  expect_identical(max(sparse$antal_personroster), 8L)
  expect_identical(max(list_sparse$antal_personroster), 5L)
})

test_that("2022 raw contradictions fail before valid-candidate filtering", {
  x <- personroster_2022_fixture()
  g <- .personroster_2022_geografi(x$mandat)
  p <- .personroster_2022_population(x$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo)
  expect_silent(.personroster_2022_kontrollera_poster(k$roster, p))
  k$roster$kandidatnummer[[1]] <- "saknas"
  expect_error(.personroster_2022_kontrollera_poster(k$roster, p),
    "saknar kandidatur")
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]]$listRoster[[3]]$
    antalRosterMedPersonrost <- 1L
  expect_error(.personroster_2022_kallrader(
    .personroster_2022_geografi(x$mandat)$noder, g$geo), "90000|personröster")
})

test_that("2022 incomplete lists do not turn observed partial sums into totals", {
  x <- personroster_2022_fixture()
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]]$listRoster[[2]]$personroster <- NULL
  g <- .personroster_2022_geografi(x$mandat)
  p <- .personroster_2022_population(x$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo)
  area <- .personroster_2022_omrade(k, p, g$geo, FALSE, FALSE)
  expect_true(all(is.na(area$antal_personroster)))
  sparse <- .personroster_2022_omrade(k, p, g$geo, TRUE, FALSE)
  full <- .personroster_2022_omrade(k, p, g$geo, TRUE, TRUE)
  expect_identical(sparse$antal_personroster, 3L)
  expect_identical(nrow(full), nrow(sparse) + 1L)
  expect_true(all(!is.na(full$antal_personroster)))
})

test_that("2022 explicit zero remains in sparse list results", {
  x <- personroster_2022_fixture()
  x$mandat$valomrade$valkretsLista[[1]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]]$listRoster[[1]]$
    personroster[[2]] <- list(kandidatNummer = "2", antalPersonroster = 0L)
  g <- .personroster_2022_geografi(x$mandat)
  p <- .personroster_2022_population(x$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo)
  sparse <- .personroster_2022_omrade(k, p, g$geo, TRUE, FALSE)
  expect_true(any(sparse$kandidatnummer == "2" &
    sparse$antal_personroster == 0L))
})

test_that("2022 observed cross-area candidate votes are not dropped", {
  x <- personroster_2022_fixture()
  extra <- x$kandidaturer[1, ]
  extra$kandidatnummer <- "4"
  extra$valomradeskod <- "02"
  extra$valkretskod <- "02"
  alla <- dplyr::bind_rows(x$kandidaturer, extra)
  p <- .personroster_2022_population(x$kandidaturer, TRUE, alla)
  observed <- tibble::tibble(valtyp = "RD", valomradeskod = "00",
    personvalsomradeskod = "01", partikod = "A",
    kandidatnummer = "4", antal_personroster = 1L)
  expect_silent(.personroster_2022_kontrollera_poster(observed, p))
  p <- .personroster_2022_observerade(p, observed)
  expect_true("4" %in% p$kandidat$kandidatnummer)
  expect_false("4" %in% p$lista$kandidatnummer)
})

test_that("personroster keeps exact multi-year order and a shared year column", {
  make <- function(ar, ...) tibble::tibble(
    valtillfalle = paste0("Val_", ar), valar = as.integer(ar),
    valtyp = "RD", kandidatnummer = "1", antal_personroster = 2L)
  local_mocked_bindings(
    .sources_historical = function(ar, ...) list(year = ar),
    .personroster_2014 = function(sources, ...) make(sources$year),
    .personroster_ett_ar_2018 = make,
    .personroster_ett_ar_2022 = make,
    .personroster_ett_ar_2026 = make,
    .select_public_source = function(...) "local"
  )
  expect_identical(personroster(detaljniva = "full", ar = c(2026, 2022, 2026))$valar,
    c(2026L, 2022L))
  expect_identical(personroster(detaljniva = "full", ar = c(2026, 2018, 2022))$valar,
    c(2026L, 2018L, 2022L))
  expect_identical(personroster(detaljniva = "full", ar = "alla")$valar,
    c(2010L, 2014L, 2018L, 2022L, 2026L))
  expect_identical(personroster(detaljniva = "full", fran = 2022, till = 2026)$valar,
    c(2022L, 2026L))
  expect_identical(personroster(detaljniva = "full", ar = 2022)$valar, 2022L)
  expect_error(personroster(detaljniva = "full", ar = 2022, fran = 2022), "alternativa")
  expect_error(personroster(detaljniva = "full", ar = 2024), "stöds")
})

test_that("2022 person votes never fall back to preliminary result files", {
  index <- tibble::tibble(path =
    "p/rd/Val_20220911_preliminar_00_RD.zip")
  expect_error(.slutliga_mandat_paths(index, "RD", "personroster"),
    "Slutlig resultatkälla saknas")
})

test_that("all four person vote views share multi-year dispatch", {
  seen <- list()
  make <- function(ar, val, source, data_dir, update, archive, progress,
                   niva, per_lista, komplettera_nollor) {
    seen[[length(seen) + 1L]] <<- c(ar, niva, per_lista,
                                     komplettera_nollor)
    tibble::tibble(valtillfalle = paste0("Val_", ar), valar = as.integer(ar))
  }
  local_mocked_bindings(
    .personroster_ett_ar_2022 = make,
    .personroster_ett_ar_2026 = make
  )
  for (n in c("personvalsomrade", "valdistrikt")) {
    for (l in c(FALSE, TRUE)) {
      for (z in c(FALSE, TRUE)) {
        out <- personroster(detaljniva = "full", ar = c(2022, 2026), niva = n,
          per_lista = l, komplettera_nollor = z)
        expect_identical(out$valar, c(2022L, 2026L))
      }
    }
  }
  expect_length(seen, 16L)
})

test_that("2022 geography covers RF constituencies and undivided KF", {
  rf <- personroster_2022_fixture()
  rf$mandat$valtyp <- "RF"
  rf$mandat$valomrade$kod <- "01"
  rf$mandat$valomrade$namn <- "Region Stockholm"
  rf$mandat$valomrade$valkretsLista[[1]]$kod <- "0101"
  rf$kandidaturer$valtyp <- "RF"
  rf$kandidaturer$valomradeskod <- "01"
  rf$kandidaturer$valkretskod <- "0101"
  for (i in seq_along(rf$rost$valdistrikt)) {
    rf$rost$valdistrikt[[i]]$valomradeskod <- "01"
    rf$rost$valdistrikt[[i]]$kretskod <- "0101"
  }
  g <- .personroster_2022_geografi(rf$mandat, rf$rost)
  p <- .personroster_2022_population(rf$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo, FALSE)
  expect_identical(unique(k$roster$personvalsomradeskod), "0101")
  expect_true(nrow(.personroster_2022_distrikt(k, p, TRUE, TRUE)) > 0L)

  kf <- personroster_2022_fixture()
  root <- kf$mandat$valomrade$valkretsLista[[1]]
  root$kod <- "0180"
  root$namn <- "Stockholms kommun"
  root$namnValkrets <- NULL
  root$valkretsLista <- list()
  kf$mandat$valtyp <- "KF"
  kf$mandat$valomrade <- root
  kf$kandidaturer$valtyp <- "KF"
  kf$kandidaturer$valomradeskod <- "0180"
  kf$kandidaturer$valkretskod <- "018000"
  g <- .personroster_2022_geografi(kf$mandat)
  p <- .personroster_2022_population(kf$kandidaturer, g$indelad)
  k <- .personroster_2022_kallrader(g$noder, g$geo)
  expect_false(g$indelad)
  expect_identical(g$geo$personvalsomradeskod, "0180")
  expect_identical(g$geo$valkretskod, NA_character_)
  expect_true(nrow(.personroster_2022_omrade(k, p, g$geo, FALSE, FALSE)) > 0L)
})

