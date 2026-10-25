test_that("retired 2022 result remote fails before network, cache or fallback", {
  local_mocked_bindings(
    .resolve_val_file = function(...) stop("raw resolution forbidden"),
    .download_file = function(...) stop("network forbidden"))
  for (source in c("remote", "auto")) {
    expect_error(.read_resultatindex(2022L, source, tempdir(), FALSE, FALSE),
      "2022 remote result distribution is no longer publicly available")
    expect_error(.resultat_file(2022L, "s/rd/old.zip", source, tempdir(), FALSE, FALSE),
      "No fallback")
  }
  for (fun in list(results, seats, candidates, elected, substitutes, preference_votes))
    for (election in c("RD", "RF", "KF"))
      expect_error(fun(year = 2022L, election = election, source = "remote"),
        "2022 remote result distribution is no longer publicly available")
})

test_that("2022 local resolution and 2026 result resolution remain available", {
  calls <- list()
  local_mocked_bindings(.resolve_val_file = function(...) {
    calls[[length(calls) + 1L]] <<- list(...); "fixture.zip"
  })
  expect_identical(.resultat_file(2022L, "saved.zip", "local", tempdir(), FALSE, FALSE),
    "fixture.zip")
  expect_identical(calls[[1]]$source, "local")
  expect_identical(.resultat_file(2026L, "current.zip", "remote", NULL, FALSE, FALSE),
    "fixture.zip")
  expect_identical(calls[[2]]$source, "remote")
})

test_that("2022 canonical selection and explicit remote selection stay distinct", {
  m <- list(valserie = "rkl", valar = 2022L, schema_version = 3L,
    value_schema_version = 1L, storage_schema_version = 1L, format = "parquet",
    assets = data.frame(asset = "rkl2022-results-rd"),
    tables = data.frame(asset = "rkl2022-results-rd", table = "national"))
  local_mocked_bindings(.canonical_manifest_path = function(...) "fixture.json",
    .canonical_manifest = function(...) m, .canonical_view_covered = function(...) TRUE,
    .canonical_require_reader = function() NULL)
  expect_identical(.select_public_source("auto", 2022L, "valresultat",
    val = "RD", niva = "riket"), "canonical_auto")
  expect_identical(.select_public_source("canonical", 2022L, "valresultat"), "canonical")
  expect_identical(.select_public_source("remote", 2022L, "valresultat"), "remote")
})

test_that("2022 candidacy remote retains its independent official CSV route", {
  expected <- tibble::tibble(valtyp = "RD", kandidatnummer = "123")
  local_mocked_bindings(.resolve_val_file = function(path, ar, samling, source, base_url, ...) {
    expect_identical(source, "remote")
    expect_identical(path, "parti/kandidaturer.zip")
    expect_identical(base_url, "https://data.val.se/filer/val2022")
    "official-candidates.zip"
  }, .kort_kommunnamn_2026 = function(x) x, read_kandidaturer_2022 = function(file) {
    expect_identical(file, "official-candidates.zip"); expected
  })
  expect_identical(.kandidaturer_ett_ar(2022L, "RD", "remote", NULL, FALSE, FALSE), expected)
})
