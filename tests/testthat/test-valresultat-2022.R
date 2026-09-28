test_that("2022 support matrix contains only official D and M nodes", {
  nivaer <- c("valdistrikt", "kommun", "kommunvalkrets", "lan", "region",
              "regionvalkrets", "riksdagsvalkrets", "riket")
  expected <- list(
    RD = c(valdistrikt = "D", riksdagsvalkrets = "M", riket = "M"),
    RF = c(valdistrikt = "D", region = "M", regionvalkrets = "M"),
    KF = c(valdistrikt = "D", kommun = "M", kommunvalkrets = "M")
  )
  for (val in names(expected)) for (niva in nivaer) {
    if (niva %in% names(expected[[val]])) {
      expect_identical(.valresultat_kalla(val, niva, 2022),
                       unname(expected[[val]][[niva]]), info = paste(val, niva))
    } else {
      expect_error(.valresultat_kalla(val, niva, 2022),
                   "2022", info = paste(val, niva))
    }
  }
})

test_that("2022 source selection follows index paths and local never downloads", {
  root <- tempfile()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  old <- options(swelections.resultatsamling_2022 = "val2022")
  on.exit(options(old), add = TRUE)
  path <- "s/rd/Val_20220911_slutlig_00_RD.zip"
  index_path <- val_local_path("index.md5", 2022, "val2022", root)
  dir.create(dirname(index_path), recursive = TRUE)
  writeLines(paste(strrep("a", 32), paste0("./", path)), index_path)
  local_mocked_bindings(val_remote_url = function(...) stop("network"))
  index <- .read_resultatindex(2022, "local", root, FALSE, FALSE)
  expect_identical(.valresultat_paths(index, "RD", "slutlig", "M"), path)
  expect_identical(.resultatsamling(2022), "val2022")
  expect_error(.resultat_file(2022, path, "local", root, FALSE, FALSE),
               "Filen finns inte")
  expect_error(.read_resultatindex(2022, "local", root, TRUE, FALSE), "update = TRUE")
})

test_that("2022 D and M reuse frozen schemas with typed missing history", {
  for (val in c("RD", "RF", "KF")) for (rakning in c("preliminar", "slutlig")) {
    nivaer <- switch(val, RD = c("valdistrikt", "riksdagsvalkrets", "riket"),
                     RF = c("valdistrikt", "regionvalkrets", "region"),
                     KF = c("valdistrikt", "kommunvalkrets", "kommun"))
    for (niva in nivaer) {
      kalla <- .valresultat_kalla(val, niva, 2022)
      raw <- fixture_resultat_2022(val, kalla, rakning)
      path <- sub("Test_2026", "Val_20220911", fixture_resultatpath(val, kalla, rakning))
      internal <- .parse_valresultat(raw, kalla, val, niva, rakning, path)
      actual <- .valresultat_public_2026(internal, niva, raw, ar = 2022L)
      expect_identical(names(internal), names(.valresultat_schema()), info = paste(val, niva))
      expect_identical(vapply(internal, typeof, ""),
                       vapply(.valresultat_schema(), typeof, ""), info = paste(val, niva))
      expect_identical(names(actual), .valresultat_public_columns_2026(niva),
                       info = paste(val, niva))
      reference <- fixture_public_resultat(val, niva, rakning)
      expect_identical(vapply(actual, typeof, ""), vapply(reference, typeof, ""),
                       info = paste(val, niva))
      expect_identical(unique(actual$valtillfalle), "Val_2022")
      expect_identical(unique(actual$rakningstillfalle), rakning)
      expect_true(all(is.na(actual$valdatum)))
      expect_true(all(is.na(actual$valklass)))
      expect_true(all(is.na(actual$test)))
      expect_true(all(is.na(actual$antal_roster_fg)))
      expect_true(all(is.na(actual$diff_andel_roster)))
      expect_true(all(is.na(actual$valdel_fg)))
      expect_true(all(is.na(actual$diff_valdel)))
      expect_equal(actual$andel_roster, actual$antal_roster / actual$giltiga_roster)
      expect_equal(actual$andel_blanka, actual$blanka_roster / actual$totalt_antal_roster)
      expect_equal(actual$andel_ogiltiga, actual$ogiltiga_roster / actual$totalt_antal_roster)
      expect_true(all(actual$antal_roster[actual$partikod == "0002"] > 0))
      .valresultat_check_key(actual, niva)
    }
  }
})

test_that("2022 other-party nodes distinguish absent from explicit zero", {
  raw <- fixture_resultat_2022("RD", "M")
  path <- "s/rd/Val_20220911_slutlig_00_RD.zip"
  absent <- .parse_valresultat(raw, "M", "RD", "riket", "slutlig", path)
  expect_false(any(absent$ovriga_partier))
  raw$valomrade$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier <-
    list(antalRoster = 0L)
  zero <- .parse_valresultat(raw, "M", "RD", "riket", "slutlig", path)
  expect_identical(sum(zero$ovriga_partier), 1L)
  expect_identical(zero$antal_roster[zero$ovriga_partier], 0L)
})

test_that("2022 district context derives only official constituency geography", {
  raw <- fixture_resultat_2022("KF", "D")
  path <- "s/kf/Val_20220911_slutlig_0180_KF.zip"
  parsed <- .parse_valresultat(raw, "D", "KF", "valdistrikt", "slutlig", path)
  actual <- .valresultat_public_2026(parsed, "valdistrikt", raw, ar = 2022L)
  expect_identical(unique(actual$kommunvalkretskod), "01")
  expect_identical(unique(actual$kommunvalkretsnamn), "Krets 01")
  expect_identical(unique(actual$kommunnamn), "Stockholm")
  expect_true(all(actual$raknat))
  raw$valdistrikt[[2]]["rostfordelning"] <- list(NULL)
  raw$antalValdistriktRaknade <- 1L
  parsed <- .parse_valresultat(raw, "D", "KF", "valdistrikt", "slutlig", path)
  actual <- .valresultat_public_2026(parsed, "valdistrikt", raw, ar = 2022L)
  expect_identical(length(unique(actual$valdistriktskod)), 2L)
  expect_identical(length(unique(actual$valdistriktskod[actual$raknat])), 1L)
  expect_true(all(is.na(actual$antal_roster[!actual$raknat])))
  expect_true(all(is.na(actual$andel_roster[!actual$raknat])))
})

test_that("2022 default levels and unsupported years are validated before I/O", {
  expect_error(valresultat(ar = 2021), "2021.*2022, 2026")
  expect_error(valresultat(ar = 2022, val = "RD", niva = "kommun"), "2022")
  expect_error(valresultat(ar = 2022, val = "RF", niva = "riket"), "2022")
  expect_error(valresultat(ar = 2022, val = "KF", niva = "lan"), "2022")
  calls <- character()
  local_mocked_bindings(
    .read_resultatindex = function(ar, source, data_dir, update, archive) {
      tibble::tibble(path = c(
        "s/rd/Val_20220911_slutlig_00_RD.zip",
        "s/rf/Val_20220911_slutlig_01_RF.zip",
        "s/kf/Val_20220911_slutlig_0180_KF.zip"
      ))
    },
    .resultat_file = function(ar, path, source, data_dir, update, archive) path,
    .read_valresultat_raw = function(file, kalla, val, rakning, distrikt_context, ar) {
      calls <<- c(calls, paste(val, kalla, ar))
      fixture_resultat_2022(val, kalla, rakning)
    }
  )
  for (val in c("RD", "RF", "KF")) {
    result <- valresultat(ar = 2022, val = val, progress = FALSE)
    expect_identical(unique(result$geografiniva),
                     c(RD = "riket", RF = "region", KF = "kommun")[[val]])
  }
  expect_identical(calls, c("RD M 2022", "RF M 2022", "KF M 2022"))
})
