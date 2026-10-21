test_that("canonical manifest and cache use versioned checksums", {
  work <- tempfile("canonical-test-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  asset <- file.path(work, "small.rds")
  value <- tibble::tibble(valar = 2018L, antal = c(0L, NA_integer_))
  saveRDS(value, asset)
  entry <- data.frame(asset = "small", file = "small.rds",
                      bytes = unname(file.info(asset)$size),
                      sha256 = .canonical_sha256(asset),
                      surfaces = "mandat")
  manifest <- list(data_version = "data-v0.1.0", schema_version = 1L,
                   valserie = "rkl", valar = 2018L, assets = entry,
                   sources = list())
  manifest_path <- file.path(work, "manifest.json")
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE,
                       pretty = TRUE)
  manifest <- .canonical_manifest(manifest_path)
  cache <- file.path(work, "cache")
  url <- paste0("file:///", gsub("\\\\", "/", normalizePath(asset)))
  expect_identical(.canonical_asset(manifest, "small", cache, url), value)
  expect_identical(.canonical_asset(manifest, "small", cache), value)
  expect_error(.canonical_asset(manifest, "absent", cache), "Unknown")
  cache_file <- file.path(cache, manifest$data_version, "small",
                          substr(entry$sha256, 1L, 16L), "small.rds")
  writeBin(charToRaw("damaged"), cache_file)
  expect_error(.canonical_asset(manifest, "small", cache), "saknas i cache")
  expect_false(file.exists(cache_file))
  expect_identical(.canonical_asset(manifest, "small", cache, url), value)
  wrong <- file.path(work, "wrong.rds")
  bytes <- readBin(asset, "raw", n = file.info(asset)$size)
  bytes[[length(bytes)]] <- as.raw(bitwXor(as.integer(bytes[[length(bytes)]]), 1L))
  writeBin(bytes, wrong)
  expect_identical(file.info(wrong)$size, file.info(asset)$size)
  expect_false(identical(.canonical_sha256(wrong), entry$sha256))
  wrong_url <- paste0("file:///", gsub("\\\\", "/", normalizePath(wrong)))
  unlink(cache_file)
  expect_error(.canonical_asset(manifest, "small", cache, wrong_url),
               "Incorrect SHA256 or size")
  expect_false(file.exists(cache_file))
})

test_that("manifest rejects unsafe or ambiguous asset identifiers", {
  work <- tempfile(fileext = ".json")
  on.exit(unlink(work), add = TRUE)
  bad <- list(data_version = "data-v0.1.0", schema_version = 1L,
              valserie = "rkl", valar = 2018L, sources = list(),
              assets = data.frame(asset = c("same", "same"),
                file = c("one.rds", "two.rds"), bytes = c(1L, 1L),
                sha256 = rep(paste(rep("a", 64), collapse = ""), 2L)))
  jsonlite::write_json(bad, work, auto_unbox = TRUE)
  expect_error(.canonical_manifest(work), "Ogiltiga")
  bad$assets$asset <- c("one", "two")
  bad$assets$file[[1]] <- "../one.rds"
  jsonlite::write_json(bad, work, auto_unbox = TRUE)
  expect_error(.canonical_manifest(work), "Ogiltiga")
})

test_that("Parquet canonical assets preserve public R types", {
  skip_if_not_installed("nanoparquet")
  work <- tempfile("canonical-parquet-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  value <- tibble::tibble(kod = c("01", NA_character_),
                          antal = c(0L, NA_integer_),
                          andel = c(0, NA_real_),
                          klar = c(FALSE, NA))
  asset <- file.path(work, "typed.parquet")
  nanoparquet::write_parquet(value, asset, compression = "gzip")
  manifest <- list(data_version = "data-v0.1.0", schema_version = 1L,
                   valserie = "rkl", valar = 2018L, sources = list(),
                   assets = data.frame(asset = "typed", file = "typed.parquet",
                     bytes = unname(file.info(asset)$size),
                     sha256 = .canonical_sha256(asset)))
  url <- paste0("file:///", gsub("\\\\", "/", normalizePath(asset)))
  cache <- file.path(work, "cache")
  expect_identical(.canonical_asset(manifest, "typed", cache, url), value)
  expect_identical(.canonical_asset(manifest, "typed", cache), value)
})

test_that("Parquet manifests require nonambiguous table layouts", {
  work <- tempfile(fileext = ".json")
  on.exit(unlink(work), add = TRUE)
  manifest <- list(data_version = "data-v0.1.0", schema_version = 1L,
                   valserie = "rkl", valar = 2018L, format = "parquet",
                   sources = list(),
                   assets = data.frame(asset = "one", file = "one.parquet",
                     bytes = 1L, sha256 = paste(rep("a", 64), collapse = "")))
  jsonlite::write_json(manifest, work, auto_unbox = TRUE)
  expect_error(.canonical_manifest(work), "Ogiltigt Parquet-manifest")
  manifest$tables <- data.frame(asset = c("one", "one"),
                                table = c("same", "same"),
                                columns = c("x", "x"))
  jsonlite::write_json(manifest, work, auto_unbox = TRUE)
  expect_error(.canonical_manifest(work), "Ogiltigt Parquet-manifest")
})

test_that("table layouts restore level-specific columns and types", {
  first <- tibble::tibble(.table = "first", key = "01", count = 0L)
  second <- tibble::tibble(.table = "second", key = "02", share = NA_real_)
  data <- dplyr::bind_rows(first, second)
  manifest <- list(tables = data.frame(asset = "levels",
    table = c("first", "second"),
    columns = c("key,count", "key,share")))
  expect_identical(.canonical_table(manifest, data, "levels", "first"),
                   dplyr::select(first, -".table"))
  expect_identical(.canonical_table(manifest, data, "levels", "second"),
                   dplyr::select(second, -".table"))
  expect_error(.canonical_table(manifest, data, "levels", "missing"),
               "Kanonisk tabell saknas")
})

test_that("canonical is explicit and separate from raw local files", {
  expect_identical(.check_public_args(2018L, "results", "auto", NULL,
                                      FALSE, FALSE, valar_resolved = TRUE), "auto")
  for (fun in list(results, seats, candidacies, candidates, elected,
                   substitutes, preference_votes)) {
    expect_error(fun(year = 2026, source = "canonical"), "supports 2018.*2014/2022")
  }
  expect_silent(.check_canonical_years("canonical", c(2018L, 2022L)))
  expect_error(results(year = 2018, source = "canonical", data_dir = "raw"),
               "data_dir")
  expect_error(results(year = 2018, source = "canonical", update = TRUE),
               "update")
  old <- options(swelections.canonical_manifest = NULL)
  on.exit(options(old), add = TRUE)
  local_mocked_bindings(.canonical_release_manifest = function(release,
      missing_ok = FALSE) {
    if (missing_ok) return(NULL)
    stop("Published canonical manifest is unavailable.")
  })
  expect_error(results(year = 2018, source = "canonical"), "Published canonical manifest is unavailable")
  options(swelections.canonical_manifest = "nonexistent-canonical.json")
  local_mocked_bindings(.valresultat_2018 = function(...) {
    tibble::tibble(valtyp = "RD")
  })
  expect_error(results(year = 2018, source = "canonical"), "valid canonical")
  expect_error(results(year = 2018, source = "auto"), "valid canonical")
})

test_that("release manifest is fetched, checked and cached separately", {
  release_dir <- tempfile("canonical-release-")
  cache_dir <- tempfile("canonical-cache-")
  dir.create(release_dir)
  on.exit(unlink(c(release_dir, cache_dir), recursive = TRUE), add = TRUE)
  release <- list(year = 2018L, series = "rkl", data_version = "data-v9.9.9",
                  schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L,
                  base_url = paste0("file:///", gsub("\\\\", "/",
                    normalizePath(release_dir))))
  manifest <- list(data_version = release$data_version,
    schema_version = 3L, value_schema_version = 1L, storage_schema_version = 1L, valserie = "rkl", valar = 2018L,
    format = "parquet", sources = list(),
    assets = data.frame(asset = "small", file = "small.parquet", bytes = 1L,
      sha256 = paste(rep("a", 64L), collapse = "")),
    tables = data.frame(asset = "small", table = "first", columns = "key"))
  file <- file.path(release_dir, "manifest.json")
  jsonlite::write_json(manifest, file, auto_unbox = TRUE)
  old <- options(swelections.canonical_cache_dir = cache_dir)
  on.exit(options(old), add = TRUE)
  cached <- .canonical_release_manifest(release)
  expect_true(file.exists(cached))
  expect_identical(.canonical_release_manifest(release), cached)
  manifest$schema_version <- 4L
  jsonlite::write_json(manifest, file, auto_unbox = TRUE)
  unlink(cached)
  expect_null(.canonical_release_manifest(release, missing_ok = TRUE))
  expect_error(.canonical_release_manifest(release), "unavailable or invalid")
})

test_that("canonical schema translates shared and base-only names without values", {
  original <- tibble::tibble(
    valtyp = c("RD", "KF"), valklass = c("Ordinarie", NA_character_),
    antal_roster = c(0L, NA_integer_), antal_roster_fg = c(1L, NA_integer_),
    diff_andel_roster = c(-0.01, NA_real_),
    personvalsomradeskod = c("01", "0980"),
    antal_personroster = c(0L, NA_integer_),
    parti_complete = c(TRUE, FALSE), node_id = c(1L, 2L))
  canonical <- .canonical_names_en(original)
  expect_named(canonical, c(
    "election_code", "election_kind", "votes", "previous_votes",
    "vote_share_change", "preference_vote_area_code",
    "preference_votes", "party_complete", "node_id"))
  expect_identical(.canonical_names_sv(canonical), original)
  expect_identical(canonical$election_code, c("RD", "KF"))
  expect_identical(canonical$election_kind, c("Ordinarie", NA_character_))
  expect_identical(canonical$preference_votes, c(0L, NA_integer_))
})
