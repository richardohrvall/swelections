# No network or developer sources: policy fixtures are deliberately independent
# of canonical normalisation and use only the manifest's declared layout.
.source_policy_manifest <- function(series = "rkl", year = 2018L) {
  prefix <- paste0(series, year, "-")
  result <- paste0(prefix, if (series == "eu") "results-final" else "results-rd")
  list(valserie = series, valar = year, schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L, format = "parquet",
    assets = data.frame(asset = c(result, paste0(prefix, "candidates"))),
    tables = data.frame(asset = result, table = "national"))
}

test_that("approved canonical coverage precedes local raw and explicit sources win", {
  m <- .source_policy_manifest()
  local_mocked_bindings(.canonical_manifest_path = function(...) "fixture.json",
    .canonical_manifest = function(...) m, .canonical_require_reader = function() NULL)
  for (root in list(NULL, "a-user-archive")) {
    expect_identical(.select_public_source("auto", 2018L, "valresultat", root,
      val = "RD", niva = "riket"), "canonical_auto")
    for (source in c("local", "remote", "canonical"))
      expect_identical(.select_public_source(source, 2018L, "valresultat", root), source)
  }
  expect_identical(.select_public_source("auto", 2018L, "valresultat", update = TRUE), "auto")
  expect_identical(.select_public_source("auto", 2018L, "valresultat", archive = TRUE), "auto")
  expect_identical(.select_public_source("auto", 2026L, "valresultat"), "auto")
  expect_identical(.select_public_source("auto", 2018L, "valresultat",
    val = "RD", niva = "valdistrikt"), "auto")
  expect_identical(.select_public_source("auto", 2018L, "valresultat",
    val = "RD", niva = "riket", rakning = "preliminar"), "auto")
  expect_identical(.select_public_source("auto", 2018L, "valresultat",
    event_kind = "re_election"), "auto")
})

test_that("canonical failure cannot silently choose a different raw population", {
  local_mocked_bindings(.canonical_manifest_path = function(...) stop("checksum mismatch"))
  expect_error(.select_public_source("auto", 2018L, "valresultat"), "checksum mismatch")
  # Explicit raw choices do not inspect canonical manifests at all.
  expect_identical(.select_public_source("remote", 2018L, "valresultat"), "remote")
  expect_identical(.select_public_source("local", 2018L, "valresultat"), "local")
})

test_that("disabled registered products remain opt-in across families and years", {
  registry <- .canonical_release_registry(); registry$auto_eligible[] <- FALSE
  local_mocked_bindings(.canonical_release_registry = function() registry)
  local_mocked_bindings(.canonical_manifest_path = function(...) stop("must not inspect prototype"))
  for (y in c(2004L, 2009L, 2014L, 2019L, 2024L)) {
    expect_false(.canonical_release(y, "eu")$auto_eligible)
    expect_identical(.select_public_source("auto", y, "results", series = "eu"), "auto")
    expect_identical(.select_public_source("canonical", y, "results", series = "eu"), "canonical")
  }
  for (y in c(2002L, 2006L, 2010L, 2014L, 2022L))
    expect_identical(.select_public_source("auto", y, "results"), "auto")
})

test_that("EU API uses one resolver for every year and all seven functions", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "eu"] <- TRUE
  functions <- list(results, seats, candidacies, candidates, elected, substitutes, preference_votes)
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(year, series, ...) paste(series, year),
    .canonical_manifest = function(path) {
      s <- strsplit(path, " ")[[1]]
      .source_policy_manifest(s[1], as.integer(s[2]))
    }, .canonical_view_covered = function(...) TRUE,
    .canonical_require_reader = function() NULL)
  sentinel <- tibble::tibble(valtyp = "E", valar = 2024L)
  canonical <- function(table, args) { expect_true(args$.canonical_auto || args$source == "canonical"); sentinel }
  raw <- function(table, args) { expect_true(args$source %in% c("auto", "remote", "local")); sentinel }
  local_mocked_bindings(.eu2004_canonical = canonical, .eu2009_canonical = canonical,
    .eu2014_canonical = canonical, .eu2019_canonical = canonical, .eu2024_canonical = canonical,
    .eu2004_read = raw, .eu2009_read = raw, .eu2014_read = raw, .eu2019_read = raw, .eu2024_read = raw)
  for (y in c(2004L, 2009L, 2014L, 2019L, 2024L)) for (fn in functions)
    for (source in c("auto", "canonical", "local", "remote")) {
      out <- fn(year = y, election = "E", source = source, detail = "full")
      expect_identical(out$election_code, "E")
    }
})

test_that("canonical configuration distinguishes families, events and legacy years", {
  withr::local_options(swelections.canonical_manifest = c(`2014` = "legacy.json",
    `eu:2014` = "eu.json", `rkl:ordinary:2014` = "rkl.json",
    `rkl:re_election:2014` = "rerun.json"))
  expect_identical(.canonical_configured_manifest(2014L, "eu"), "eu.json")
  expect_identical(.canonical_configured_manifest(2014L, "rkl"), "rkl.json")
  expect_identical(.canonical_configured_manifest(2014L, "rkl", "re_election"), "rerun.json")
  expect_null(.canonical_configured_manifest(2024L, "eu"))
  options(swelections.canonical_manifest = c(`2014` = "legacy.json"))
  expect_identical(.canonical_configured_manifest(2014L, "eu"), "legacy.json")
  options(swelections.canonical_manifest = "single.json")
  expect_identical(.canonical_configured_manifest(2024L, "eu"), "single.json")
})

test_that("RKL API selects approved canonical before historical raw dispatch", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "rkl"] <- TRUE
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) "fixture",
    .canonical_manifest = function(...) .source_policy_manifest(),
    .canonical_view_covered = function(...) TRUE,
    .canonical_require_reader = function() NULL,
    .canonical_source = function(ar, surface, val, ...) tibble::tibble(valtyp = "RD", valomradeskod = "00", personvalsomradeskod = "00", partikod = "0001", kandidatnummer = "123"))
  for (y in c(2002L, 2006L, 2010L, 2014L, 2018L, 2022L))
    for (fn in list(results, seats, candidates, elected, substitutes, preference_votes))
      expect_identical(fn(year = y, election = "RD")$election_code, "RD")
  # 2002 has no public full candidacy register; preserve that unsupported view.
  for (y in c(2006L, 2010L, 2014L, 2018L, 2022L))
    expect_identical(candidacies(year = y, election = "RD")$election_code, "RD")
})

test_that("unsupported remote and absent coverage keep existing raw behavior", {
  for (y in c(2004L, 2009L, 2014L))
    expect_error(results(y, "E", source = "remote"), "preserved|original")
  local_mocked_bindings(.valresultat_index_for_ar = function(ar, source, ...) {
    expect_identical(source, "auto"); stop("existing official raw route")
  })
  expect_error(results(2026L, "regional"), "existing official raw route")
})

test_that("canonical layouts separate election type, stage and requested view", {
  m <- .source_policy_manifest()
  expect_true(.canonical_view_covered(m, "results", "RD", "riket"))
  expect_false(.canonical_view_covered(m, "results", "KF", "riket"))
  expect_false(.canonical_view_covered(m, "results", "RD", "riket", "preliminar"))
  expect_false(.canonical_view_covered(m, "preference_votes", "RD", "valdistrikt"))
  expect_false(.canonical_view_covered(m, "results", "RD", "valdistrikt"))
  m <- .source_policy_manifest("eu", 2019L)
  expect_true(.canonical_view_covered(m, "results", niva = "riket"))
  expect_false(.canonical_view_covered(m, "results", niva = "riket", rakning = "preliminar"))
  expect_true(.canonical_view_covered(m, "candidates"))
  expect_false(.canonical_view_covered(m, "candidates", include_results = FALSE))
})

test_that("an existing raw request never switches source inside candidate enrichment", {
  withr::local_options(swelections.internal_raw_request = TRUE)
  local_mocked_bindings(.canonical_manifest_path = function(...) stop("must not select canonical"))
  expect_identical(.select_public_source("auto", 2018L, "kandidaturer"), "auto")
  expect_identical(.select_public_source("local", 2018L, "kandidaturer"), "local")
  expect_identical(.select_public_source("remote", 2018L, "kandidaturer"), "remote")
})

test_that("failed raw operations restore the request-local source context", {
  withr::local_options(swelections.internal_raw_request = NULL)
  local_mocked_bindings(.valresultat_index_for_ar = function(...) stop("raw failed"))
  expect_error(results(2026L, source = "auto"), "raw failed")
  expect_null(getOption("swelections.internal_raw_request"))
})

test_that("published 2018 uses a new contract-specific manifest-cache key", {
  expect_identical(.canonical_release(2018L)$cache_key, "data-v0.4.0")
  expect_identical(.canonical_release(2018L)$event_kind, "ordinary")
})

test_that("a selected canonical source reports a missing reader without raw fallback", {
  local_mocked_bindings(.canonical_manifest_path = function(...) "fixture",
    .canonical_manifest = function(...) .source_policy_manifest(),
    .canonical_require_reader = function() stop("install nanoparquet"))
  expect_error(.select_public_source("auto", 2018L, "results", val = "RD", niva = "riket"),
    "install nanoparquet")
})

test_that("a future approved EU entry works end-to-end from a published location and offline cache", {
  skip_if_not_installed("nanoparquet")
  root <- tempfile("source-policy-release-"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  cache <- file.path(root, "cache")
  withr::local_options(swelections.canonical_manifest = NULL,
    swelections.canonical_assets_dir = NULL, swelections.canonical_base_url = NULL,
    swelections.canonical_cache_dir = cache)
  # A deliberately small independent Parquet fixture; no raw normalisation.
  value <- tibble::tibble(election_year = 2024L, election_code = "E",
    geographic_level = "national", party_code = "0001", votes = 1L,
    valid_votes = 1L, invalid_votes = 0L)
  payload <- value; payload$.table <- "national"
  asset <- "eu2024-results-final"
  file <- file.path(root, paste0(asset, ".parquet"))
  nanoparquet::write_parquet(payload, file)
  manifest <- list(data_version = "data-v9.9.9", schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L,
    valserie = "eu", valar = 2024L, format = "parquet", sources = list(),
    assets = data.frame(asset = asset, file = basename(file),
      bytes = unname(file.info(file)$size), sha256 = .canonical_sha256(file)),
    tables = data.frame(asset = asset, table = "national", columns = paste(names(value), collapse = ",")))
  jsonlite::write_json(manifest, file.path(root, .canonical_release(2024L, "eu")$manifest_file), auto_unbox = TRUE)
  registry <- .canonical_release_registry()
  i <- registry$series == "eu" & registry$year == 2024L
  registry$auto_eligible[i] <- TRUE
  registry$data_version[i] <- "data-v9.9.9"
  registry$base_url[i] <- paste0("file:///", normalizePath(root, winslash = "/"))
  local_mocked_bindings(.canonical_release_registry = function() registry)
  expect_identical(results(2024L, "E", detail = "full"), value)
  expect_identical(results(2024L, "E", source = "canonical", detail = "full"), value)
  # Neither manifest nor asset need to be re-downloaded after a complete read.
  unlink(c(file, file.path(root, .canonical_release(2024L, "eu")$manifest_file)))
  expect_identical(results(2024L, "E", detail = "full"), value)
})

test_that("family-qualified manifests are validated rather than silently ignored", {
  path <- tempfile(fileext = ".json"); writeLines("fixture", path)
  on.exit(unlink(path), add = TRUE)
  local_mocked_bindings(.canonical_manifest = function(p) {
    if (p == path) .source_policy_manifest("eu", 2024L) else .source_policy_manifest()
  }, .canonical_release_manifest = function(...) "published-rkl-manifest")
  withr::local_options(swelections.canonical_manifest = c(`rkl:ordinary:2018` = path))
  expect_error(.canonical_manifest_path(2018L, auto_selected = TRUE),
    "requested election family/year/event/schema")
  release <- .canonical_release(2018L); release$base_url <- "file:///published-fixture"
  local_mocked_bindings(.canonical_release = function(...) release)
  # A single unqualified manifest for another family/year is not an override
  # of every registered product in a multi-family session.
  options(swelections.canonical_manifest = path)
  expect_identical(.canonical_manifest_path(2018L, auto_selected = TRUE), "published-rkl-manifest")
})

test_that("same-version EU releases have independent year-specific manifest caches", {
  work <- tempfile("eu-year-cache-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  withr::local_options(swelections.canonical_cache_dir = file.path(work, "cache"))
  releases <- lapply(c(2019L, 2024L), function(year) {
    source <- file.path(work, as.character(year))
    dir.create(source)
    manifest <- list(data_version = "data-v9.9.9", schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L,
      valserie = "eu", valar = year, format = "parquet", sources = list(),
      assets = data.frame(asset = "small", file = "small.parquet", bytes = 1L,
        sha256 = paste(rep("a", 64L), collapse = "")),
      tables = data.frame(asset = "small", table = "first", columns = "key"))
    jsonlite::write_json(manifest, file.path(source, "manifest.json"), auto_unbox = TRUE)
    list(year = year, series = "eu", event_kind = "ordinary",
      data_version = "data-v9.9.9", schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L,
      base_url = paste0("file:///", gsub("\\\\", "/", normalizePath(source))))
  })
  cached <- lapply(releases, .canonical_release_manifest)
  expect_false(identical(cached[[1]], cached[[2]]))
  for (i in seq_along(releases)) {
    expect_identical(as.integer(.canonical_manifest(cached[[i]])$valar), releases[[i]]$year)
    unlink(file.path(work, as.character(releases[[i]]$year)), recursive = TRUE)
    expect_identical(.canonical_release_manifest(releases[[i]]), cached[[i]])
  }
  # Explicit keys, including the published 2018 cache layout, stay compatible.
  expect_identical(.canonical_release(2018L)$cache_key, "data-v0.4.0")
})
