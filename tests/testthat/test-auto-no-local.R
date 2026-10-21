test_that("auto ignores user raw files and raw-root options for modern sources", {
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  withr::local_options(swelections.data_dir = root, valresultat.data_dir = root)
  for (year in c(2022L, 2026L)) {
    dir.create(file.path(root, year, "test"), recursive = TRUE)
    file <- file.path(root, year, "test", "fixture.zip")
    writeLines("user snapshot", file)
    for (arg in list(NULL, root)) {
      expect_identical(val_file("fixture.zip", year, "test", "auto", arg),
        "https://resultat.val.se/resultatfiler/test/fixture.zip")
      expect_identical(val_file("fixture.zip", year, "test", "local", arg),
        normalizePath(file, winslash = "/"))
    }
  }
  options(swelections.data_dir = NULL)
  expect_match(val_file("fixture.zip", 2026L, "test", "auto"), "^https://")
})

test_that("remote archive operations refresh rather than reuse a user snapshot", {
  root <- tempfile(); dir.create(file.path(root, "2026", "test"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  file <- val_local_path("fixture.txt", 2026L, "test", root)
  writeLines("old local snapshot", file)
  local_mocked_bindings(.download_file = function(url, dest) {
    expect_match(url, "^https://")
    writeLines("fresh remote response", dest)
  })
  result <- .resolve_val_file("fixture.txt", 2026L, "test", "auto", root, archive = TRUE)
  expect_identical(readLines(result), "fresh remote response")
  expect_identical(readLines(val_archive_path("fixture.txt", 2026L, "test", root)),
    "fresh remote response")
})

test_that("historical raw readers require explicit local even with an archive configured", {
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  withr::local_options(swelections.data_dir = root, valresultat.data_dir = root)
  local_mocked_bindings(.canonical_release = function(...) NULL)
  functions <- list(results, seats, candidates, elected, substitutes, preference_votes)
  for (year in c(2002L, 2006L, 2010L, 2014L)) {
    dir.create(file.path(root, year, "valresultat"), recursive = TRUE)
    writeLines("user snapshot", file.path(root, year, "valresultat", "slutresultat.zip"))
    for (fn in functions) expect_error(fn(year, "RD", data_dir = root), 'source = "local"')
    if (year != 2002L)
      expect_error(candidacies(year, "RD", data_dir = root), 'source = "local"')
  }
  for (year in c(2004L, 2009L, 2014L)) {
    dir.create(file.path(root, "eu", year), recursive = TRUE)
    writeLines("user snapshot", file.path(root, "eu", year, "slutresultat.zip"))
    for (fn in c(functions, list(candidacies)))
      expect_error(fn(year, "E", data_dir = root), 'source = "local"')
  }
})

test_that("2018 auto never reads local XML or candidacy snapshots", {
  root <- tempfile(); dir.create(file.path(root, "2018", "valresultat"), recursive = TRUE)
  dir.create(file.path(root, "2018", "kandidater"))
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  writeLines("user snapshot", file.path(root, "2018", "valresultat", "slutresultat.zip"))
  writeLines("user snapshot", file.path(root, "2018", "kandidater", "kandidaturer.skv"))
  expect_error(.kalla_2018("resultat", "auto", root), 'source = "local"')
  expect_match(.kalla_2018("kandidaturer", "auto", root), "^https://")
  expect_true(file.exists(.kalla_2018("resultat", "local", root)))
})

test_that("EU remote-capable readers ignore existing user snapshots under auto", {
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  dir.create(file.path(root, "valresultat")); dir.create(file.path(root, "kandidater"))
  writeLines("user snapshot", file.path(root, "slutresultat.zip"))
  writeLines("user snapshot", file.path(root, "valresultat", "EU-val_2024_slutlig_00_E.zip"))
  writeLines("user snapshot", file.path(root, "kandidater", "kandidaturer.zip"))
  local_mocked_bindings(.eu2019_cache = new.env(parent = emptyenv()),
    .eu2024_cache = new.env(parent = emptyenv()),
    .download_file = function(...) stop("REMOTE requested"))
  expect_error(.eu2019_file("final", "auto", root), "REMOTE requested")
  expect_error(.eu2024_file("results", "auto", root), "REMOTE requested")
  expect_error(.eu2024_file("candidacies", "auto", root), "REMOTE requested")
})

test_that("referendum auto selects remote despite a complete user archive", {
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  writeLines("user snapshot", file.path(root, "final.xml"))
  local_mocked_bindings(.referendum2003_file = function(source, root, filename) {
    expect_identical(source, "remote"); stop("REMOTE requested")
  })
  expect_error(.referendum2003_raw("auto", root, "riket"), "REMOTE requested")
  expect_error(.referendum2003_raw("auto", root, "valdistrikt"), "REMOTE requested")
})

test_that("partial EU 2009 approval uses canonical for six functions, never local for preference", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "eu" & registry$year == 2009L] <- TRUE
  assets <- paste0("eu2009-", c("results-final", "seats-final", "candidacies",
    "candidates", "elected", "substitutes", "candidate-base", "source-designations"))
  manifest <- list(valserie = "eu", valar = 2009L,
    assets = data.frame(asset = assets), tables = data.frame(asset = assets, table = "national"))
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) "fixture", .canonical_manifest = function(...) manifest,
    .canonical_require_reader = function() NULL,
    .eu2009_canonical = function(table, args) tibble::tibble(valar = 2009L, valtyp = "E"))
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  writeLines("user snapshot", file.path(root, "slutresultat.zip"))
  withr::local_options(swelections.data_dir = root)
  for (fn in list(results, seats, candidacies, candidates, elected, substitutes))
    expect_identical(fn(2009L, "E")$election_year, 2009L)
  expect_identical(candidates(2009L, "E", include_results = FALSE)$election_year, 2009L)
  for (level in c("preference_vote_area", "national", "county", "municipality",
                  "municipal_constituency", "district"))
    expect_error(preference_votes(2009L, "E", level = level), 'source = "local"')
  local_mocked_bindings(.eu2009_read = function(table, args) {
    expect_identical(args$source, "local"); tibble::tibble(valar = 2009L, valtyp = "E")
  })
  expect_identical(preference_votes(2009L, "E", source = "local", data_dir = root)$election_year, 2009L)
})

test_that("re-election auto never selects a preserved local archive", {
  local_mocked_bindings(.re_file = function(...) stop("must not inspect user archive"))
  for (year in c(2003L, 2011L, 2015L, 2019L))
    expect_error(seats(year, "municipal", election_kind = "re_election"), 'source = "local"')
})
