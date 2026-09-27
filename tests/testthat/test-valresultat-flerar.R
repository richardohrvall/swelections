fixture_flerar_index <- function(ar) {
  paths <- unlist(lapply(c("preliminar", "slutlig"), function(rakning) {
    vapply(c("RD", "RF", "KF"), function(val) {
      path <- fixture_resultatpath(val, "M", rakning)
      if (ar == 2022L) sub("Test_2026", "Val_20220911", path) else path
    }, character(1))
  }))
  tibble::tibble(path = paths)
}

test_that("shared year resolver distinguishes exact years, all and inclusive ranges", {
  expect_identical(.stodd_valar("valresultat", "RD"), c(2018L, 2022L, 2026L))
  expect_identical(.stodd_valar("valresultat", "RF"), c(2018L, 2022L, 2026L))
  expect_identical(.stodd_valar("valresultat", "KF"), c(2018L, 2022L, 2026L))
  expect_identical(.stodd_valar("mandat", "RD"), c(2018L, 2022L, 2026L))
  expect_identical(.resolve_valar(2026L), 2026L)
  expect_identical(.resolve_valar(c(2026, 2022, 2026)), c(2026L, 2022L))
  expect_identical(.resolve_valar("alla"), c(2018L, 2022L, 2026L))
  expect_identical(.resolve_valar(fran = 2022, ar_angivet = FALSE), c(2022L, 2026L))
  expect_identical(.resolve_valar(till = 2022, ar_angivet = FALSE), c(2018L, 2022L))
  expect_identical(.resolve_valar(fran = 2021, till = 2026,
                                  ar_angivet = FALSE), c(2022L, 2026L))
  for (ar in list(2019:2022, 2024, 2022.5, numeric(), NA_real_, "2022",
                  c(2022, "alla"), NULL)) {
    expect_error(.resolve_valar(ar), "2018.*2022.*2026")
  }
  expect_error(.resolve_valar(2022, fran = 2018), "ar.*fran")
  expect_error(.resolve_valar("alla", till = 2022), "ar.*till")
  expect_error(.resolve_valar(fran = 2026, till = 2022, ar_angivet = FALSE),
               "fran.*till")
  expect_identical(.resolve_valar(till = 2021, ar_angivet = FALSE), 2018L)
  for (grans in list(2022:2026, 2022.5, NA_real_, "2022", TRUE)) {
    expect_error(.resolve_valar(fran = grans, ar_angivet = FALSE), "fran")
  }
})

test_that("multi-year results equal bound single-year results without changing order", {
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) fixture_flerar_index(2026L),
    .read_resultatindex = function(ar, ...) fixture_flerar_index(ar),
    .resultat_file_2026 = function(path, ...) path,
    .resultat_file = function(ar, path, ...) path,
    .read_valresultat_raw = function(file, kalla, val, rakning,
                                    distrikt_context = FALSE, ar = 2026) {
      if (ar == 2022L) fixture_resultat_2022(val, kalla, rakning)
      else fixture_resultatraw(val, kalla, rakning)
    }
  )
  for (case in list(
    c("RD", "riket"), c("RD", "valdistrikt"),
    c("RF", "region"), c("KF", "kommun")
  )) {
    val <- case[[1]]
    niva <- case[[2]]
    a <- valresultat(ar = 2022, val = val, niva = niva, progress = FALSE)
    b <- valresultat(ar = 2026, val = val, niva = niva, progress = FALSE)
    ab <- valresultat(ar = c(2022, 2026), val = val, niva = niva,
                     progress = FALSE)
    expect_identical(ab, dplyr::bind_rows(a, b), info = paste(val, niva))
    expect_identical(valresultat(ar = c(2026, 2022, 2026), val = val,
                                niva = niva, progress = FALSE),
                     dplyr::bind_rows(b, a), info = paste(val, niva))
    expect_identical(names(ab)[1:2], c("valtillfalle", "valar"))
    expect_identical(typeof(ab$valar), "integer")
    expect_identical(unique(ab$valar), c(2022L, 2026L))
    expect_identical(valresultat(fran = 2022, val = val, niva = niva,
                                progress = FALSE), ab)
    expect_identical(valresultat(fran = 2022, till = 2022, val = val, niva = niva,
                                progress = FALSE), a)
  }
  expect_identical(valresultat(progress = FALSE),
                   valresultat(ar = 2026, progress = FALSE))
  expect_identical(valresultat(2026, "RD", "slutlig", "riket", progress = FALSE),
                   valresultat(ar = 2026, val = "RD", rakning = "slutlig",
                               niva = "riket", progress = FALSE))
})

test_that("multi-year requests reject unsupported combinations before source I/O", {
  calls <- 0L
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) { calls <<- calls + 1L; stop("IO") },
    .read_resultatindex = function(...) { calls <<- calls + 1L; stop("IO") }
  )
  expect_error(valresultat(ar = c(2022, 2026), val = "RD", niva = "kommun"),
               "2022")
  expect_error(valresultat(ar = "alla", val = "RF", niva = "riket"), "2022")
  expect_error(valresultat(fran = 2021, till = 2026, val = "KF", niva = "lan"),
               "2022")
  expect_identical(calls, 0L)
  expect_error(valresultat(ar = 2022, fran = 2018), "ar.*fran")
  expect_error(valresultat(ar = "alla", till = 2022), "ar.*till")
  expect_error(valresultat(ar = 2021), "2021.*2022.*2026")
  expect_error(valresultat(fran = 2019, till = 2021), "2018.*2022.*2026")
})

test_that("missing local source in any selected year aborts the whole request", {
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) fixture_flerar_index(2026L),
    .read_resultatindex = function(ar, ...) fixture_flerar_index(ar),
    .resultat_file_2026 = function(path, ...) path,
    .resultat_file = function(ar, path, ...) {
      stop("Filen finns inte i det lokala arkivet: ", path)
    },
    .read_valresultat_raw = function(file, kalla, val, rakning,
                                    distrikt_context = FALSE, ar = 2026) {
      fixture_resultatraw(val, kalla, rakning)
    }
  )
  expect_error(valresultat(ar = c(2026, 2022), val = "RD", source = "local",
                          progress = FALSE), "Val_20220911.*Filen finns inte")
})
