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
