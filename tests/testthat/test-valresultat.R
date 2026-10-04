test_that("all 48 election-level-count combinations select the decided source", {
  nivaer <- c("valdistrikt", "kommun", "kommunvalkrets", "lan", "region",
              "regionvalkrets", "riksdagsvalkrets", "riket")
  expected <- list(RD = c("D", "U", "U", NA, NA, NA, "M", "M"),
                   RF = c("D", "U", "U", NA, "M", "M", NA, "O"),
                   KF = c("D", "M", "M", "O", NA, NA, NA, "O"))
  last <- NULL
  paths <- unlist(lapply(c("slutlig", "preliminar"), function(r) {
    unlist(lapply(c("RD", "RF", "KF"), function(v) c(fixture_resultatpath(v, "M", r), fixture_resultatpath(v, "O", r))))
  }))
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) tibble::tibble(path = paths),
    .resultat_file_2026 = function(path, ...) path,
    .read_valresultat_raw = function(file, kalla, val, rakning, ...) {
      last <<- list(file = file, kalla = kalla)
      fixture_resultatraw(val, kalla, rakning)
    }
  )
  for (val in names(expected)) for (i in seq_along(nivaer)) for (rakning in c("preliminar", "slutlig")) {
    last <- NULL
    if (is.na(expected[[val]][i])) {
      expect_error(valresultat(detaljniva = "full", val = val, niva = nivaer[i], rakning = rakning), "inte|aktiverat")
      expect_null(last)
    } else {
      out <- valresultat(detaljniva = "full", val = val, niva = nivaer[i], rakning = rakning, progress = FALSE)
      expect_identical(last$kalla, expected[[val]][i])
      expect_identical(last$file, fixture_resultatpath(val, expected[[val]][i], rakning))
      expect_identical(unique(out$geografiniva), nivaer[i])
      expect_identical(unique(out$rakningstillfalle), rakning)
      original_columns <- .valresultat_public_columns_2026(nivaer[i])
      expect_identical(names(out)[seq_along(original_columns)], original_columns)
      typer <- vapply(.valresultat_schema(), typeof, "")
      typer <- c(
        typer, kommunnamn_officiellt = "character", raknat = "logical",
        valar = "integer", valomradessparr = "double", valkretssparr = "double"
      )
      expect_identical(unname(vapply(out[original_columns], typeof, "")),
                       unname(typer[original_columns]))
    }
  }
})

test_that("defaults give exactly one natural main level and invalid inputs fail before IO", {
  local_mocked_bindings(.read_resultatindex_2026 = function(...) stop("INDEX"))
  for (val in list(NULL, character(), NA_character_, c("RD", "RF"), "EU", 1)) {
    expect_error(valresultat(detaljniva = "full", val = val), "val|Val")
  }
  for (ar in list(2021, 2026.5, NA_real_, numeric(), "2026")) {
    expect_error(valresultat(detaljniva = "full", ar = ar), "2022, 2026")
  }
  for (niva in list(character(), NA_character_, c("riket", "kommun"), "fel")) {
    expect_error(valresultat(detaljniva = "full", niva = niva), "niva|Niv")
  }
  for (rakning in list(NULL, NA_character_, "auto", c("slutlig", "preliminar"))) {
    expect_error(valresultat(detaljniva = "full", rakning = rakning), "rakning")
  }
  expect_error(valresultat(detaljniva = "full", source = "local", update = TRUE), 'source = "local".*update = TRUE')
  expect_error(valresultat(detaljniva = "full", progress = NA), "progress")
  expect_error(valresultat(detaljniva = "full", archive = 1), "archive")
  expect_error(valresultat(detaljniva = "full", update = NULL), "update")
  expect_error(valresultat(detaljniva = "full", val = "RF", niva = "lan"), "OS-formatet.*inte aktiverat.*slutlig")
  expect_error(valresultat(detaljniva = "full", val = "RD", niva = "lan"), "RD/lan.*officiell")
})

test_that("NULL levels are identical to explicit main levels for both counts", {
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) tibble::tibble(path = unlist(lapply(c("slutlig", "preliminar"), function(r) {
      vapply(c("RD", "RF", "KF"), function(v) fixture_resultatpath(v, "M", r), "")
    }))),
    .resultat_file_2026 = function(path, ...) path,
    .read_valresultat_raw = function(file, kalla, val, rakning, ...) fixture_resultatraw(val, kalla, rakning)
  )
  for (v in c("RD", "RF", "KF")) for (r in c("slutlig", "preliminar")) {
    expect_identical(valresultat(detaljniva = "full", val = tolower(v), rakning = r, progress = FALSE),
                     valresultat(detaljniva = "full", val = v, niva = c(RD = "riket", RF = "region", KF = "kommun")[[v]], rakning = r, progress = FALSE))
  }
  expect_identical(valresultat(detaljniva = "full", progress = FALSE), valresultat(detaljniva = "full", val = "RD", niva = "riket", rakning = "slutlig", progress = FALSE))
})

test_that("source selection is strict, unique, and never falls back", {
  path <- fixture_resultatpath("RF")
  index <- tibble::tibble(path = c(path, fixture_resultatpath("RF", "O"),
    fixture_resultatpath("RF", "M", "preliminar"), sub("01_RF", "001_RF", path),
    paste0(path, ".bak"), sub("/Test", "/extra/Test", path)))
  expect_identical(.valresultat_paths(index, "RF", "slutlig", "M"), path)
  expect_error(.valresultat_paths(index[2, ], "RF", "slutlig", "M"), "Saknad")
  expect_error(.valresultat_paths(index[3, ], "RF", "slutlig", "M"), "Saknad")
  expect_error(.valresultat_paths(tibble::tibble(path = c(path, sub("Test_2026", "Annat", path))), "RF", "slutlig", "M"), "Dubbla")
  raw <- fixture_resultatraw()
  raw$valtyp <- "KF"
  expect_error(fixture_parse_resultat(raw = raw), "metadata")
  raw <- fixture_resultatraw()
  raw$valomrade$kod <- "99"
  expect_error(fixture_parse_resultat(raw = raw), "valomradeskod")
})

test_that("live preliminary metadata is normalized to the public spelling", {
  raw <- fixture_resultatraw("RD", "M", "preliminar")
  raw$valtillfalle <- "Val_2026"
  raw$rakningstillfalle <- "preliminär"
  out <- fixture_parse_resultat(
    val = "RD", niva = "riket", rakning = "preliminar", raw = raw
  )
  expect_identical(unique(out$valtillfalle), "Val_2026")
  expect_identical(unique(out$valtyp), "RD")
  expect_identical(unique(out$rakningstillfalle), "preliminar")
})

test_that("the canonical district parser skips unreported RD, RF and KF districts", {
  gor_orapporterat <- function(x) {
    x["rostfordelning"] <- list(NULL)
    x$rapporteringsTid <- ""
    x
  }
  for (val in c("RD", "RF", "KF")) {
    raw <- fixture_resultatraw(val, "D", "preliminar")
    raw$rakningstillfalle <- "preliminär"
    raw$antalValdistriktRaknade <- 1L
    raw$antalValdistriktSomSkaRaknas <- 2L
    raw$valdistrikt[[2]] <- gor_orapporterat(raw$valdistrikt[[2]])

    direkt <- parse_rostfordelning_2026(raw)
    expect_identical(unique(direkt$valdistriktskod), "01800001", info = val)
    out <- fixture_parse_resultat(
      val, "valdistrikt", "preliminar", raw = raw
    )
    expect_identical(unique(out$valdistriktskod), "01800001", info = val)
    expect_identical(unique(out$rakningstillfalle), "preliminar", info = val)

    nollrad <- raw
    nollrad$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
      partiRoster[[1]]$antalRoster <- 0L
    noll <- fixture_parse_resultat(
      val, "valdistrikt", "preliminar", raw = nollrad
    )
    expect_identical(
      noll$antal_roster[noll$partikod == "0001"], 0L, info = val
    )

    alla_null <- raw
    alla_null$valdistrikt[[1]] <- gor_orapporterat(
      alla_null$valdistrikt[[1]]
    )
    alla_null$antalValdistriktRaknade <- 0L
    tom <- parse_rostfordelning_2026(alla_null)
    expect_equal(nrow(tom), 0L, info = val)
    expect_identical(names(tom), names(direkt), info = val)
    expect_identical(vapply(tom, typeof, ""), vapply(direkt, typeof, ""), info = val)
    kanonisk_tom <- fixture_parse_resultat(
      val, "valdistrikt", "preliminar", raw = alla_null
    )
    expect_equal(nrow(kanonisk_tom), 0L, info = val)
    expect_identical(names(kanonisk_tom), names(.valresultat_schema()), info = val)
    expect_identical(
      vapply(kanonisk_tom, typeof, ""),
      vapply(.valresultat_schema(), typeof, ""),
      info = val
    )
  }
})

test_that("public district results retain counted and uncounted districts", {
  gor_orapporterat <- function(x) {
    x["rostfordelning"] <- list(NULL)
    x$rapporteringsTid <- ""
    x
  }
  for (val in c("RD", "RF", "KF")) {
    raw <- fixture_resultatraw(val, "D", "preliminar")
    raw$rakningstillfalle <- "preliminär"
    raw$antalValdistriktRaknade <- 1L
    raw$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
      partiRoster[[1]]$antalRoster <- 0L
    raw$valdistrikt[[2]]$antalRostberattigade <- 777L
    raw$valdistrikt[[2]] <- gor_orapporterat(raw$valdistrikt[[2]])

    out <- fixture_public_resultat(val, "valdistrikt", "preliminar", raw)
    expect_setequal(unique(out$valdistriktskod), c("01800001", "01800002"))
    expect_identical(unique(out$raknat[out$valdistriktskod == "01800001"]), TRUE, info = val)
    expect_identical(unique(out$raknat[out$valdistriktskod == "01800002"]), FALSE, info = val)
    expect_true(all(is.na(out$antal_roster[!out$raknat])), info = val)
    expect_true(all(is.na(out$andel_roster[!out$raknat])), info = val)
    expect_identical(unique(out$antal_rostberattigade[!out$raknat]), 777L, info = val)
    expect_false("antal_rostberattigade_raknade" %in% names(out), info = val)
    expect_identical(out$antal_roster[out$raknat & out$partikod == "0001"], 0L, info = val)
    expect_equal(dplyr::n_distinct(out$valdistriktskod[out$raknat]), 1L, info = val)
    expect_identical(
      dplyr::n_distinct(out$valdistriktskod[out$raknat]),
      unique(out$antal_valdistrikt_raknade),
      info = val
    )

    tidigare <- fixture_parse_resultat(val, "valdistrikt", "preliminar", raw) |>
      .valresultat_public_andelar_2026()
    rapporterat <- dplyr::filter(out, raknat)
    kompletterade <- c(
      "kommunnamn", "lannamn", "valomradesnamn", "valkretskod", "valkretsnamn"
    )
    jamfor <- setdiff(intersect(names(tidigare), names(rapporterat)), kompletterade)
    expect_identical(
      dplyr::arrange(rapporterat[jamfor], partikod),
      dplyr::arrange(tidigare[jamfor], partikod),
      info = val
    )
  }
})

test_that("public district results handle none and all counted", {
  for (val in c("RD", "RF", "KF")) {
    alla <- fixture_resultatraw(val, "D", "preliminar")
    out_alla <- fixture_public_resultat(val, "valdistrikt", "preliminar", alla)
    expect_true(all(out_alla$raknat), info = val)
    expect_equal(dplyr::n_distinct(out_alla$valdistriktskod), 2L, info = val)

    inga <- fixture_resultatraw(val, "D", "preliminar")
    inga$valdistrikt <- lapply(inga$valdistrikt, function(x) {
      x["rostfordelning"] <- list(NULL)
      x$rapporteringsTid <- ""
      x
    })
    inga$antalValdistriktRaknade <- 0L
    out_inga <- fixture_public_resultat(val, "valdistrikt", "preliminar", inga)
    expect_false(any(out_inga$raknat), info = val)
    expect_equal(dplyr::n_distinct(out_inga$valdistriktskod), 2L, info = val)
    expect_true(all(is.na(out_inga$antal_roster)), info = val)
    expect_true(all(is.na(out_inga$andel_roster)), info = val)
    expect_false(any(is.na(out_inga$partikod)), info = val)
  }
})

test_that("uncounted districts use the official constituency party universe", {
  raw <- fixture_resultatraw("RD", "D", "preliminar")
  raw$valdistrikt[[2]]$kretskod <- "02"
  raw$valdistrikt[[2]]["rostfordelning"] <- list(NULL)
  raw$valdistrikt[[2]]$rapporteringsTid <- ""
  raw$antalValdistriktRaknade <- 1L
  context <- attr(raw, "valresultat_distrikt_context")
  extra <- context$mandat$valomrade$valkretsLista[[2]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[1]]
  extra$partikod <- "0003"
  extra$partibeteckning <- "Parti C"
  extra$partiforkortning <- "C"
  context$mandat$valomrade$valkretsLista[[2]]$rostfordelning$
    rosterPaverkaMandat$partiRoster[[3]] <- extra
  attr(raw, "valresultat_distrikt_context") <- context

  out <- fixture_public_resultat("RD", "valdistrikt", "preliminar", raw)
  expect_setequal(out$partikod[!out$raknat], c("0001", "0002", "0003"))
  expect_false("0003" %in% out$partikod[out$raknat])

  context$mandat$valomrade$valkretsLista[[2]]$rostfordelning$
    rosterPaverkaMandat$rosterOvrigaPartier <- list(antalRoster = 0, andelRoster = 0)
  attr(raw, "valresultat_distrikt_context") <- context
  med_ovriga <- fixture_public_resultat("RD", "valdistrikt", "preliminar", raw)
  special <- med_ovriga[!med_ovriga$raknat & med_ovriga$ovriga_partier, ]
  expect_equal(nrow(special), 1L)
  expect_true(is.na(special$partikod))
  expect_true(is.na(special$antal_roster))
})

test_that("official party universes are used for both counting stages", {
  for (val in c("RD", "RF", "KF")) for (rakning in c("preliminar", "slutlig")) {
    raw <- fixture_resultatraw(val, "D", rakning)
    raw$valdistrikt[[2]]["rostfordelning"] <- list(NULL)
    raw$valdistrikt[[2]]$rapporteringsTid <- ""
    raw$antalValdistriktRaknade <- 1L
    context <- attr(raw, "valresultat_distrikt_context")
    nod <- context$mandat$valomrade$valkretsLista[[1]]
    expected <- vapply(
      nod$rostfordelning$rosterPaverkaMandat$partiRoster,
      function(x) x$partikod, character(1)
    )
    out <- fixture_public_resultat(val, "valdistrikt", rakning, raw)
    expect_setequal(out$partikod[!out$raknat], expected)
  }
})

test_that("district parties outside the official universe are rejected", {
  raw <- fixture_resultatraw("RD", "D", "preliminar")
  raw$valdistrikt[[1]]$rostfordelning$rosterPaverkaMandat$
    partiRoster[[1]]$partikod <- "9999"
  expect_error(
    fixture_public_resultat("RD", "valdistrikt", "preliminar", raw),
    "saknas i mandatfilens partiuniversum"
  )
})

test_that("district geography is completed from official 2026 context", {
  for (val in c("RD", "RF", "KF")) {
    out <- fixture_public_resultat(val, "valdistrikt")
    expect_false(anyNA(out$kommunnamn), info = val)
    expect_false(anyNA(out$lannamn), info = val)
    expect_false(anyNA(out$valomradesnamn), info = val)
    expect_false(anyNA(out$valkretskod), info = val)
    expect_false(anyNA(out$valkretsnamn), info = val)
  }
  expect_equal(.valresultat_lannamn_2026("09"), "Gotlands län")
  expect_true(is.na(.valresultat_lannamn_2026("99")))
})

test_that("missing or malformed district result structures still fail", {
  raw <- fixture_resultatraw("RD", "D", "preliminar")
  raw$valdistrikt[[1]]$rostfordelning <- NULL
  expect_error(parse_rostfordelning_2026(raw), "Saknad nyckel.*rostfordelning")
  expect_error(
    fixture_parse_resultat("RD", "valdistrikt", "preliminar", raw),
    "Saknad nyckel.*rostfordelning"
  )
  raw <- fixture_resultatraw("RD", "D", "preliminar")
  raw$valdistrikt[[1]]$rostfordelning <- list()
  expect_error(
    fixture_parse_resultat("RD", "valdistrikt", "preliminar", raw),
    "rostfordelning"
  )
  raw <- fixture_resultatraw("RD", "D", "preliminar")
  raw$valdistrikt[[2]]["rostfordelning"] <- list(NULL)
  expect_error(
    fixture_parse_resultat("RD", "valdistrikt", "preliminar", raw),
    "Rapporterade valdistrikt"
  )
})

test_that("explicit null results are skipped in other preliminary source types", {
  under <- fixture_resultatraw("RD", "U", "preliminar")
  kommun2 <- under$kommuner[[1]]
  kommun2$kommunkod <- "0181"
  kommun2["rostfordelning"] <- list(NULL)
  under$kommuner[[2]] <- kommun2
  expect_identical(
    unique(fixture_parse_resultat("RD", "kommun", "preliminar", under)$kommunkod),
    "0180"
  )

  mandat_raw <- fixture_resultatraw("RF", "M", "preliminar")
  mandat_raw$valomrade$valkretsLista[[2]]["rostfordelning"] <- list(NULL)
  expect_identical(
    unique(fixture_parse_resultat(
      "RF", "regionvalkrets", "preliminar", mandat_raw
    )$valkretskod),
    "01"
  )

  over <- fixture_resultatraw("KF", "O", "preliminar")
  lan2 <- over$helaLandet$lan[[1]]
  lan2$lankod <- "02"
  lan2["rostfordelning"] <- list(NULL)
  over$helaLandet$lan[[2]] <- lan2
  expect_identical(
    unique(fixture_parse_resultat("KF", "lan", "preliminar", over)$lankod),
    "01"
  )
})

test_that("absent, null, empty and zero other-party nodes are distinct in every source", {
  for (kalla in c("D", "U", "M", "O")) {
    val <- if (kalla == "O") "KF" else "RD"
    niva <- c(D = "valdistrikt", U = "kommun", M = "riket", O = "riket")[[kalla]]
    for (mode in c("absent", "null", "zero", "unknown", "empty", "wrong")) {
      raw <- fixture_resultatraw(val, kalla)
      obj <- switch(kalla, D = raw$valdistrikt[[1]], U = raw$kommuner[[1]], M = raw$valomrade, O = raw$helaLandet)
      obj$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier <- NULL
      if (mode != "absent") obj$rostfordelning$rosterPaverkaMandat["rosterOvrigaPartier"] <- list(switch(mode,
        null = NULL, zero = list(antalRoster = 0, andelRoster = 0),
        unknown = list(antalRoster = NULL), empty = list(), wrong = 0))
      if (kalla == "D") raw$valdistrikt[[1]] <- obj
      if (kalla == "U") raw$kommuner[[1]] <- obj
      if (kalla == "M") raw$valomrade <- obj
      if (kalla == "O") raw$helaLandet <- obj
      if (mode %in% c("empty", "wrong")) {
        expect_error(fixture_parse_resultat(val, niva, raw = raw), "rosterOvrigaPartier")
      } else {
        out <- fixture_parse_resultat(val, niva, raw = raw)
        ovriga <- out[out$ovriga_partier, ]
        expect_equal(nrow(ovriga), as.integer(mode %in% c("zero", "unknown")))
        if (mode == "zero") expect_identical(ovriga$antal_roster, 0L)
        if (mode == "unknown") expect_identical(ovriga$antal_roster, NA_integer_)
        expect_true(all(is.na(ovriga$over_sparr)))
      }
    }
  }
})

test_that("schema retains structural NA, source units and two reporting populations", {
  d <- fixture_parse_resultat(niva = "valdistrikt")
  expect_true(all(is.na(d$antal_valdistrikt_raknade_omrade)))
  expect_true(all(is.na(d$antal_rostberattigade_raknade)))
  expect_true(all(is.na(d$kommunnamn)))
  expect_equal(d$valdel, rep(55, 4))
  u <- fixture_parse_resultat(niva = "kommun")
  expect_equal(u$valdel, c(60, 60))
  expect_identical(u$valomradeskod, c("00", "00"))
  m <- fixture_parse_resultat("KF", "kommunvalkrets")
  expect_equal(m$antal_valdistrikt_raknade, rep(2L, 4))
  expect_equal(m$antal_valdistrikt_raknade_omrade, rep(1L, 4))
  expect_equal(m$lankod, rep("01", 4))
  expect_identical(m$valkretskod, m$kommunvalkretskod)
  expect_true(all(is.na(m$kretskod)))
  expect_true(all(is.na(fixture_parse_resultat("RF", "region")$lankod)))
  expect_true(all(is.na(fixture_parse_resultat("KF", "riket")$valomradeskod)))
  expect_true(all(is.na(m$antal_roster_fg)))
  expect_identical(m$roster_ej_anmalt_deltagande, rep(0L, 4))
  raw <- fixture_resultatraw()
  raw$test <- NULL
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$antalRoster <- NULL
  out <- fixture_parse_resultat(raw = raw)
  expect_identical(out$test, c(NA, NA))
  expect_identical(out$antal_roster, c(NA_integer_, 4L))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$antalRoster <- "fel"
  expect_error(fixture_parse_resultat(raw = raw), "typ")
})

test_that("empty divisions are typed but existing areas with null results fail", {
  for (val in c("RD", "RF", "KF")) {
    niva <- c(RD = "riksdagsvalkrets", RF = "regionvalkrets", KF = "kommunvalkrets")[[val]]
    raw <- fixture_resultatraw(val)
    raw$valomrade$valkretsLista <- list()
    expect_identical(fixture_parse_resultat(val, niva, raw = raw), .valresultat_schema())
    raw <- fixture_resultatraw(val)
    raw$valomrade$valkretsLista[[1]]$rostfordelning <- NULL
    expect_error(fixture_parse_resultat(val, niva, raw = raw), "rostfordelning")
  }
  raw <- fixture_resultatraw("RD", "U")
  raw$kommuner[[1]]$kommunvalkretsar <- NULL
  expect_identical(fixture_parse_resultat(niva = "kommunvalkrets", raw = raw), .valresultat_schema())
  raw$kommuner <- NULL
  expect_error(fixture_parse_resultat(niva = "kommun", raw = raw), "kommuner")
})

test_that("party and area keys are validated without dropping duplicates", {
  raw <- fixture_resultatraw()
  raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[2]]$partikod <- "0001"
  expect_error(fixture_parse_resultat(raw = raw), "Duplicerad resultatnyckel")
  raw <- fixture_resultatraw()
  raw$valomrade$valkretsLista[[2]]$kod <- "01"
  expect_error(fixture_parse_resultat(niva = "riksdagsvalkrets", raw = raw), "Duplicerad omr")
  raw <- fixture_resultatraw("RD", "D")
  raw$valdistrikt[[1]]$kommunkod <- NULL
  expect_error(fixture_parse_resultat(niva = "valdistrikt", raw = raw), "identitet")
})

test_that("threshold flags use only explicit party-node mandate statements", {
  for (val in c("RD", "RF", "KF")) for (rakning in c("preliminar", "slutlig")) {
    nivaer <- switch(val, RD = c("riket", "riksdagsvalkrets"),
                     RF = c("region", "regionvalkrets"), KF = c("kommun", "kommunvalkrets"))
    for (niva in nivaer) {
      out <- fixture_parse_resultat(val, niva, rakning)
      expect_identical(out$over_sparr, rep(c(TRUE, FALSE), nrow(out) / 2))
    }
    raw <- fixture_resultatraw(val, "M", rakning)
    raw$valomrade$valkretsLista[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$deltaMandatfordelning <- NULL
    raw$valomrade$valkretsLista[[1]]$rostfordelning$rosterPaverkaMandat$partiRoster[[2]]$deltaMandatfordelning <- "okant"
    expect_true(all(is.na(fixture_parse_resultat(val, nivaer[2], rakning, raw)$over_sparr[1:2])))
  }
  for (spec in list(c("RD", "valdistrikt"), c("RD", "kommun"), c("KF", "lan"), c("RF", "riket"))) {
    expect_true(all(is.na(fixture_parse_resultat(spec[1], spec[2])$over_sparr)))
  }
})

test_that("official fixture levels satisfy vote identities without API aggregation", {
  for (val in c("RD", "RF", "KF")) for (rakning in c("preliminar", "slutlig")) {
    niveaux <- switch(val, RD = c("valdistrikt", "kommun", "kommunvalkrets", "riksdagsvalkrets", "riket"),
      RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets", "region", "riket"),
      KF = c("valdistrikt", "kommunvalkrets", "kommun", "lan", "riket"))
    for (niva in niveaux) {
      out <- fixture_parse_resultat(val, niva, rakning)
      expect_equal(out$totalt_antal_roster, out$giltiga_roster + out$ogiltiga_roster)
      expect_equal(out$ogiltiga_roster, out$blanka_roster + out$roster_ej_anmalt_deltagande + out$ovriga_ogiltiga)
      expect_equal(sum(out$antal_roster[out$partikod == "0001"]), 6)
      expect_equal(sum(out$antal_roster[out$partikod == "0002"]), 4)
      omraden <- out[!duplicated(out[c(.valresultat_geo_key(niva), "geografiniva")]), ]
      expect_equal(sum(omraden$totalt_antal_roster), 12)
    }
  }
})

test_that("the 83-column contract matches the frozen design, including empty output", {
  contract <- utils::read.table(test_path("fixtures", "valresultat-schema.txt"),
                                col.names = c("namn", "typ"), stringsAsFactors = FALSE)
  for (out in list(.valresultat_schema(), fixture_parse_resultat(),
                   fixture_parse_resultat("KF", "lan"), fixture_parse_resultat(niva = "valdistrikt"))) {
    expect_identical(names(out), contract$namn)
    expect_identical(unname(vapply(out, typeof, "")), contract$typ)
  }
})

test_that("every public level has an exact frozen column contract", {
  kontrakt <- readLines(test_path("fixtures", "valresultat-public-columns.txt"), warn = FALSE)
  delar <- strsplit(kontrakt, "|", fixed = TRUE)
  for (rad in delar) {
    niva <- rad[1]
    kolumner <- strsplit(rad[2], ",", fixed = TRUE)[[1]]
    val <- switch(niva,
      lan = "KF", region = "RF", regionvalkrets = "RF",
      riksdagsvalkrets = "RD", "RD"
    )
    out <- fixture_public_resultat(val, niva)
    expect_identical(names(out), kolumner, info = niva)
    typer <- c(
      vapply(.valresultat_schema(), typeof, ""),
      kommunnamn_officiellt = "character", raknat = "logical",
      valar = "integer", valomradessparr = "double", valkretssparr = "double"
    )
    expect_identical(
      unname(vapply(out, typeof, "")), unname(typer[kolumner]), info = niva
    )
  }
})

test_that("public shares use exact count ratios for D, U, M and O sources", {
  lagg_till_andelar <- function(raw, kalla) {
    hamta <- function() switch(kalla,
      D = raw$valdistrikt[[1]], U = raw$kommuner[[1]],
      M = raw$valomrade, O = raw$helaLandet
    )
    spara <- function(obj) {
      if (kalla == "D") raw$valdistrikt[[1]] <<- obj
      if (kalla == "U") raw$kommuner[[1]] <<- obj
      if (kalla == "M") raw$valomrade <<- obj
      if (kalla == "O") raw$helaLandet <<- obj
    }
    obj <- hamta()
    obj$totaltAntalRoster <- 13L
    obj$antalRostberattigade <- 17L
    obj$antalRostberattigadeIRaknadeValdistrikt <- 16L
    preliminar <- identical(raw$rakningstillfalle, "preliminar")
    obj$valdeltagande <- if (preliminar) 81.3 else 81.25
    obj$valdeltagandeVallokal <- if (preliminar) 76.5 else 76.47
    obj$totaltAntalRosterForegaendeVal <- 11L
    obj$antalRostberattigadeForegaendeVal <- 15L
    obj$valdeltagandeForegaendeVal <- if (preliminar) 73.3 else 73.33
    obj$forandringValdeltagande <- 8.0
    obj$statusJamforelse <- "Kan j\u00e4mf\u00f6ras"
    obj$rostfordelning$rosterPaverkaMandat$antalRoster <- 11L
    obj$rostfordelning$rosterPaverkaMandat$antalRosterForegaendeVal <- 9L
    parti <- obj$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
    parti$antalRoster <- 7L
    parti$andelRoster <- if (preliminar) 63.6 else 63.64
    parti$antalRosterForegaendeVal <- 6L
    parti$andelRosterForegaendeVal <- if (preliminar) 66.7 else 66.67
    parti$forandringAndelRoster <- -3.1
    obj$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- parti
    parti <- obj$rostfordelning$rosterPaverkaMandat$partiRoster[[2]]
    parti$antalRoster <- 4L
    parti$andelRoster <- if (preliminar) 36.4 else 36.36
    parti$antalRosterForegaendeVal <- 3L
    parti$andelRosterForegaendeVal <- if (preliminar) 33.3 else 33.33
    parti$forandringAndelRoster <- 3.1
    obj$rostfordelning$rosterPaverkaMandat$partiRoster[[2]] <- parti
    ogiltiga <- obj$rostfordelning$rosterEjPaverkaMandat
    ogiltiga$antalRoster <- 2L
    ogiltiga$andelRosterAvTotaltAntalRoster <- if (preliminar) 15.4 else 15.38
    ogiltiga$antalRosterForegaendeVal <- 2L
    ogiltiga$andelRosterAvTotaltAntalRosterForegaendeVal <- if (preliminar) 18.2 else 18.18
    ogiltiga$forandringAndelRosterAvTotaltAntalRoster <- -2.8
    ogiltiga$rosterEjAnmaltDeltagande$andelRosterAvTotaltAntalRoster <- 0
    ogiltiga$rosterEjAnmaltDeltagande$antalRosterForegaendeVal <- 0L
    ogiltiga$rosterEjAnmaltDeltagande$
      andelRosterAvTotaltAntalRosterForegaendeVal <- 0
    ogiltiga$rosterEjAnmaltDeltagande$
      forandringAndelRosterAvTotaltAntalRoster <- 0
    ogiltiga$blankaRoster$antalRoster <- 2L
    ogiltiga$blankaRoster$andelRosterAvTotaltAntalRoster <- if (preliminar) 15.4 else 15.38
    ogiltiga$blankaRoster$antalRosterForegaendeVal <- 1L
    ogiltiga$blankaRoster$andelRosterAvTotaltAntalRosterForegaendeVal <- if (preliminar) 9.1 else 9.09
    ogiltiga$blankaRoster$forandringAndelRosterAvTotaltAntalRoster <- 6.3
    ogiltiga$ovrigaOgiltiga$antalRoster <- 0L
    ogiltiga$ovrigaOgiltiga$andelRosterAvTotaltAntalRoster <- 0
    ogiltiga$ovrigaOgiltiga$antalRosterForegaendeVal <- 1L
    ogiltiga$ovrigaOgiltiga$andelRosterAvTotaltAntalRosterForegaendeVal <- if (preliminar) 9.1 else 9.09
    ogiltiga$ovrigaOgiltiga$forandringAndelRosterAvTotaltAntalRoster <- -9.1
    obj$rostfordelning$rosterEjPaverkaMandat <- ogiltiga
    spara(obj)
    raw
  }

  specs <- list(
    D = c(val = "RD", niva = "valdistrikt"),
    U = c(val = "RD", niva = "kommun"),
    M = c(val = "RD", niva = "riket"),
    O = c(val = "KF", niva = "riket")
  )
  for (kalla in names(specs)) {
    spec <- specs[[kalla]]
    raw <- lagg_till_andelar(fixture_resultatraw(spec[["val"]], kalla), kalla)
    internt <- fixture_parse_resultat(spec[["val"]], spec[["niva"]], raw = raw)
    expect_equal(internt$andel_roster[[1]], 63.64, info = kalla)
    out <- fixture_public_resultat(spec[["val"]], spec[["niva"]], raw = raw)
    rad <- out[out$partikod == "0001", ][1, ]
    expect_equal(rad$andel_roster, 7 / 11, info = kalla)
    expect_equal(rad$andel_roster_fg, 6 / 9, info = kalla)
    expect_equal(rad$diff_andel_roster, 7 / 11 - 6 / 9, info = kalla)
    expect_equal(rad$diff_andel_roster,
                 rad$andel_roster - rad$andel_roster_fg, info = kalla)
    expect_equal(rad$valdel, if (kalla == "D") 13 / 17 else 13 / 16, info = kalla)
    expect_equal(rad$valdel_fg, 11 / 15, info = kalla)
    expect_equal(rad$diff_valdel, rad$valdel - rad$valdel_fg, info = kalla)
    expect_equal(rad$andel_ogiltiga, 2 / 13, info = kalla)
    expect_equal(rad$andel_ogiltiga_fg, 2 / 11, info = kalla)
    expect_equal(rad$diff_andel_ogiltiga, 2 / 13 - 2 / 11, info = kalla)
    expect_identical(rad$andel_ej_anmalt_deltagande, 0, info = kalla)
    expect_identical(rad$diff_andel_ej_anmalt_deltagande, 0, info = kalla)
    expect_identical(rad$andel_ovriga_ogiltiga, 0, info = kalla)
    expect_equal(rad$andel_ovriga_ogiltiga_fg, 1 / 11, info = kalla)
    expect_equal(rad$diff_andel_ovriga_ogiltiga, -1 / 11, info = kalla)
    expect_gt(nchar(format(rad$andel_roster, digits = 15)), 4L)
  }

  mandat_raw <- lagg_till_andelar(fixture_resultatraw("RD", "M"), "M")
  mandat_raw$valomrade$valomradessparrProcent <- 4
  mandat_raw$valomrade$valkretssparrProcent <- 12
  out <- fixture_public_resultat("RD", "riket", raw = mandat_raw)
  expect_false(any(c("valomradessparr_procent", "valkretssparr_procent") %in%
                     names(out)))
  expect_identical(unique(out$valomradessparr), 0.04)
  expect_identical(unique(out$valkretssparr), 0.12)
})

test_that("exact public shares preserve zero and missing information", {
  data <- .valresultat_schema()[rep(NA_integer_, 6L), , drop = FALSE]
  data$geografiniva <- rep("valdistrikt", 6L)
  data$valdistriktstyp <- c(rep("valdistrikt", 5L), "uppsamlingsdistrikt")
  data$raknat <- c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE)
  data$status_jamforelse <- c(
    "Kan jämföras", "Kan jämföras", "Kan jämföras", "Kan jämföras",
    "Kan ej jämföras", "Kan jämföras"
  )
  data$antal_roster <- c(1L, 0L, 1L, NA_integer_, 1L, 1L)
  data$giltiga_roster <- c(3L, 3L, 0L, NA_integer_, 3L, 3L)
  data$antal_roster_fg <- rep(1L, 6L)
  data$giltiga_roster_fg <- rep(4L, 6L)
  data$totalt_antal_roster <- c(2L, 2L, 1L, 0L, 2L, 2L)
  data$antal_rostberattigade <- c(5L, 5L, 0L, 5L, 5L, 5L)
  data$totalt_antal_roster_fg <- rep(2L, 6L)
  data$antal_rostberattigade_fg <- rep(5L, 6L)
  data$ogiltiga_roster <- c(1L, 0L, 1L, NA_integer_, 1L, 1L)
  data$ogiltiga_roster_fg <- rep(1L, 6L)
  data$roster_ej_anmalt_deltagande <- 0L
  data$roster_ej_anmalt_deltagande_fg <- 0L
  data$blanka_roster <- data$ogiltiga_roster
  data$blanka_roster_fg <- data$ogiltiga_roster_fg
  data$ovriga_ogiltiga <- 0L
  data$ovriga_ogiltiga_fg <- 0L

  out <- .valresultat_public_andelar_2026(data)
  expect_equal(out$andel_roster[1], 1 / 3)
  expect_identical(out$andel_roster[2], 0)
  expect_true(is.na(out$andel_roster[3]))
  expect_true(is.na(out$andel_roster[4]))
  expect_identical(out$andel_ogiltiga[2], 0)
  expect_true(is.na(out$valdel[3]))
  expect_true(is.na(out$valdel[4]))
  expect_true(is.na(out$valdel[6]))
  expect_true(all(is.na(out[5, c(
    "andel_roster_fg", "diff_andel_roster", "valdel_fg", "diff_valdel",
    "andel_ogiltiga_fg", "diff_andel_ogiltiga"
  )])))
  expect_equal(out$valdel_fg[6], 2 / 5)
})

test_that("exact shares agree with official rounded source percentages", {
  exakt <- c(.exakt_andel_2026(7L, 11L), .exakt_andel_2026(13L, 17L),
             .exakt_andel_2026(2L, 13L))
  preliminar <- c(63.6, 76.5, 15.4)
  slutlig <- c(63.64, 76.47, 15.38)
  expect_true(all(abs(100 * exakt - preliminar) <= 0.05 + .Machine$double.eps))
  expect_true(all(abs(100 * exakt - slutlig) <= 0.005 + .Machine$double.eps))
})

test_that("public reporting metadata exposes only analytically distinct scopes", {
  distrikt <- fixture_public_resultat("RD", "valdistrikt")
  geo_slut <- match("kommunvalkretsnamn", names(distrikt))
  expect_identical(
    names(distrikt)[geo_slut + seq_len(2L)], c("raknat", "rapporteringstid")
  )
  expect_false("antal_rostberattigade_raknade" %in% names(distrikt))

  aggregerade <- c(
    kommun = "RD", kommunvalkrets = "RD", lan = "KF", region = "RF",
    regionvalkrets = "RF", riksdagsvalkrets = "RD", riket = "RD"
  )
  for (niva in names(aggregerade)) {
    out <- fixture_public_resultat(aggregerade[[niva]], niva)
    expect_true("antal_rostberattigade_raknade" %in% names(out), info = niva)
    expect_true(
      match("rapporteringstid", names(out)) <
        match("senaste_uppdateringstid", names(out)),
      info = niva
    )
  }

  for (niva in c("lan", "region", "regionvalkrets", "riksdagsvalkrets", "riket")) {
    expect_false(
      "senaste_uppdateringstid_omrade" %in%
        names(fixture_public_resultat(aggregerade[[niva]], niva)),
      info = niva
    )
  }
  for (niva in c("kommun", "kommunvalkrets")) {
    expect_true(
      "senaste_uppdateringstid_omrade" %in%
        names(fixture_public_resultat(aggregerade[[niva]], niva)),
      info = niva
    )
  }
  for (niva in c("region", "riket")) {
    out <- fixture_public_resultat(aggregerade[[niva]], niva)
    expect_false("antal_valdistrikt_raknade_omrade" %in% names(out), info = niva)
    expect_false("antal_valdistrikt_som_ska_raknas_omrade" %in% names(out), info = niva)
  }
  for (niva in c(
    "kommun", "kommunvalkrets", "lan", "regionvalkrets", "riksdagsvalkrets"
  )) {
    out <- fixture_public_resultat(aggregerade[[niva]], niva)
    expect_true("antal_valdistrikt_raknade_omrade" %in% names(out), info = niva)
    expect_true("antal_valdistrikt_som_ska_raknas_omrade" %in% names(out), info = niva)
  }
})

test_that("public results from different levels can be row-bound", {
  distrikt <- fixture_public_resultat("RD", "valdistrikt")
  riket <- fixture_public_resultat("RD", "riket")
  out <- dplyr::bind_rows(distrikt, riket)
  expect_setequal(unique(out$geografiniva), c("valdistrikt", "riket"))
  expect_true("raknat" %in% names(out))
  expect_true(all(is.na(out$raknat[out$geografiniva == "riket"])))
})

test_that("public result municipality names separate short and official labels", {
  for (niva in c("valdistrikt", "kommun", "kommunvalkrets")) {
    out <- fixture_public_resultat("KF", niva)
    expect_identical(unique(out$kommunkod), "0180", info = niva)
    expect_identical(unique(out$kommunnamn), "Stockholm", info = niva)
    expect_identical(unique(out$kommunnamn_officiellt), "Omrade", info = niva)
  }
})

test_that("local index and ZIP pipeline never uses the network, including archival", {
  unexpected <- function(...) stop("Unexpected network access")
  local_mocked_bindings(val_remote_url = unexpected, download_val_file = unexpected)
  local_mocked_bindings(download.file = unexpected, .package = "utils")
  root <- tempfile()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  old <- options(swelections.resultatsamling_2026 = "test", swelections.data_dir = root)
  on.exit(options(old), add = TRUE)
  path <- fixture_resultatpath()
  file <- val_local_path(path, 2026, "test", root)
  dir.create(dirname(file), recursive = TRUE)
  expect_true(file.copy(test_path("fixtures", "valresultat-rd.zip"), file))
  indexfile <- val_local_path("index.md5", 2026, "test", root)
  writeLines(paste(unname(tools::md5sum(file)), paste0("./", path)), indexfile)
  out <- valresultat(detaljniva = "full", source = "local", progress = FALSE)
  expect_identical(out$antal_roster, c(6L, 4L))
  expect_identical(valresultat(detaljniva = "full", source = "local", archive = TRUE, progress = FALSE), out)
  expect_true(same_file_md5(file, val_archive_path(path, 2026, "test", root)))
  expect_true(same_file_md5(indexfile, val_archive_path("index.md5", 2026, "test", root)))
  for (niva in c("valdistrikt", "kommun", "kommunvalkrets", "riksdagsvalkrets")) {
    actual <- valresultat(detaljniva = "full", niva = niva, source = "local", progress = FALSE)
    expect_equal(sum(actual$antal_roster), 10L)
  }
  expect_identical(valresultat(detaljniva = "full", source = "auto", data_dir = root, progress = FALSE), out)
  expect_error(valresultat(detaljniva = "full", source = "local", data_dir = tempfile()), "Filen finns inte")
  expect_error(valresultat(detaljniva = "full", source = "local", update = TRUE), 'source = "local".*update = TRUE')
  expect_error(valresultat(detaljniva = "full", source = "local", rakning = "preliminar"), "Saknad prim")
  missing_path <- sub("Test_2026", "Missing", path)
  writeLines(paste(strrep("a", 32), paste0("./", missing_path)), indexfile)
  expect_error(valresultat(detaljniva = "full", source = "local", archive = TRUE), "Filen finns inte")
  expect_false(file.exists(val_archive_path(missing_path, 2026, "test", root)))
})

test_that("ZIP reader rejects ambiguous, wrong-type and wrong-count entries", {
  file <- test_path("fixtures", "valresultat-rd.zip")
  expect_identical(.read_valresultat_raw(file, "M", "RD", "slutlig")$valtyp, "RD")
  expect_error(.read_valresultat_raw(file, "M", "RF", "slutlig"), "hittade 0")
  expect_error(.read_valresultat_raw(file, "M", "RD", "preliminar"), "hittade 0")
  local_mocked_bindings(unzip = function(...) data.frame(Name = c(
    "A_slutlig_mandatfordelning_00_RD.json", "B_slutlig_mandatfordelning_00_RD.json"
  )), .package = "utils")
  expect_error(.read_valresultat_raw(file, "M", "RD", "slutlig"), "hittade 2")
})

test_that("all public source flags are forwarded without changing their semantics", {
  calls <- list()
  local_mocked_bindings(
    .read_resultatindex_2026 = function(source, data_dir, update, archive) {
      calls[[1]] <<- list(source, data_dir, update, archive)
      tibble::tibble(path = fixture_resultatpath())
    },
    .resultat_file_2026 = function(path, source, data_dir, update, archive) {
      calls[[2]] <<- list(source, data_dir, update, archive)
      path
    },
    .read_valresultat_raw = function(...) fixture_resultatraw()
  )
  for (source in c("local", "auto", "remote")) for (update in c(FALSE, TRUE)) for (archive in c(FALSE, TRUE)) {
    calls <- list()
    if (source == "local" && update) {
      expect_error(valresultat(detaljniva = "full", source = source, update = update, archive = archive), "update = TRUE")
      expect_length(calls, 0)
    } else {
      valresultat(detaljniva = "full", source = source, data_dir = "fixture", update = update, archive = archive, progress = FALSE)
      expect_identical(calls, rep(list(list(source, "fixture", update, archive)), 2))
    }
  }
})

test_that("OS totals use the existing within-node identity and preserve missing operands", {
  raw <- fixture_resultatraw("KF", "O")
  raw$helaLandet$totaltAntalRoster <- NULL
  out <- fixture_parse_resultat("KF", "riket", raw = raw)
  expect_identical(out$totalt_antal_roster, c(12L, 12L))
  raw$helaLandet$rostfordelning$rosterEjPaverkaMandat$antalRoster <- NULL
  expect_true(all(is.na(fixture_parse_resultat("KF", "riket", raw = raw)$totalt_antal_roster)))
})
