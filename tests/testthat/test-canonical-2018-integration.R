test_that("canonical RKL 2018 reproduces raw public tables", {
  skip_if(swelections_test_env("CANONICAL_FULL_RAW") != "1",
          "Full raw XML sweep is opt-in because it reparses large files")
  build <- swelections_test_env("CANONICAL_DIR")
  root <- swelections_test_env("2018_DATA_DIR")
  skip_if(!nzchar(build) || !nzchar(root),
          "Read-only canonical integration needs build and raw archive")
  skip_if_not_installed("nanoparquet")
  manifest <- .canonical_manifest(file.path(build, "manifest.json"))
  expect_identical(manifest$data_version, "data-v0.1.0")
  expect_identical(manifest$valserie, "rkl")
  expect_identical(as.integer(manifest$valar), 2018L)
  expect_identical(manifest$sources$sha256[
    manifest$sources$source == "slutresultat.zip"],
    "cb4a490b576e5a57b42b5ca26d38fa1074c692b4cd7eeb2aca2c3de80560b3a6")
  expect_identical(manifest$sources$md5[
    manifest$sources$source == "kandidaturer.skv"],
    "9855ac4280c2a5165389a88c647ae49f")
  expect_setequal(list.files(build), c("manifest.json", manifest$assets$file))
  inspect_names <- function(x) {
    if (is.data.frame(x)) {
      for (field in intersect(names(x),
        c("namn", "ledamot_namn", "ersattare_namn")))
        expect_true(all(is.na(x[[field]])), info = field)
      for (field in names(x)) if (is.character(x[[field]]))
        expect_false(any(x[[field]] == "Namnet gallrat", na.rm = TRUE))
    } else if (is.list(x)) lapply(x, inspect_names)
    invisible(NULL)
  }
  for (i in seq_len(nrow(manifest$assets))) {
    file <- file.path(build, manifest$assets$file[[i]])
    expect_identical(as.numeric(file.info(file)$size),
                     as.numeric(manifest$assets$bytes[[i]]))
    expect_identical(.canonical_sha256(file), manifest$assets$sha256[[i]])
    inspect_names(nanoparquet::read_parquet(file))
  }
  urls <- setNames(lapply(manifest$assets$file, function(file) {
    paste0("file:///", gsub("\\\\", "/", normalizePath(file.path(build, file))))
  }), manifest$assets$asset)
  cache <- tempfile("canonical-integration-cache-")
  on.exit(unlink(cache, recursive = TRUE), add = TRUE)
  compare <- function(raw, surface, val = NULL, niva = NULL,
                      per_lista = FALSE, komplettera_nollor = FALSE,
                      resultat = TRUE) {
    got <- .canonical_public_2018(manifest, surface, val, niva,
      per_lista, komplettera_nollor, resultat, cache, urls)
    expect_identical(got, raw,
      info = paste(surface, paste(val, collapse = ","), niva,
                   per_lista, komplettera_nollor))
  }
  levels <- list(
    RD = c("valdistrikt", "kommun", "kommunvalkrets", "lan",
           "riksdagsvalkrets", "riket"),
    RF = c("valdistrikt", "kommun", "kommunvalkrets", "regionvalkrets",
           "region", "riket"),
    KF = c("valdistrikt", "kommun", "kommunvalkrets", "lan", "riket")
  )
  for (val in names(levels)) {
    for (niva in levels[[val]]) compare(
      valresultat(ar = 2018L, val = val, niva = niva, source = "local",
                  data_dir = root, progress = FALSE),
      "valresultat", val, niva)
    compare(mandat(ar = 2018L, val = val, source = "local",
                   data_dir = root, progress = FALSE), "mandat", val)
    for (niva in c("personvalsomrade", "valdistrikt")) {
      for (per_lista in c(FALSE, TRUE)) compare(
        personroster(ar = 2018L, val = val, niva = niva,
                     per_lista = per_lista, source = "local",
                     data_dir = root, progress = FALSE),
        "personroster", val, niva, per_lista)
    }
    for (per_lista in c(FALSE, TRUE)) compare(
      personroster(ar = 2018L, val = val, niva = "personvalsomrade",
                   per_lista = per_lista, komplettera_nollor = TRUE,
                   source = "local", data_dir = root, progress = FALSE),
      "personroster", val, "personvalsomrade", per_lista, TRUE)
  }
  for (val in c("RD", "RF", "KF")) {
    compare(kandidaturer(ar = 2018L, val = val, source = "local",
                        data_dir = root), "kandidaturer", val)
    compare(kandidater(ar = 2018L, val = val, source = "local",
                      data_dir = root, progress = FALSE), "kandidater", val)
    compare(kandidater(ar = 2018L, val = val, resultat = FALSE,
                      source = "local", data_dir = root),
            "kandidater", val, resultat = FALSE)
    compare(valda(ar = 2018L, val = val, source = "local",
                  data_dir = root, progress = FALSE), "valda", val)
    compare(ersattare(ar = 2018L, val = val, source = "local",
                      data_dir = root, progress = FALSE), "ersattare", val)
  }
})

test_that("canonical RKL 2018 reproduces all staged raw-path outputs", {
  build <- swelections_test_env("CANONICAL_DIR")
  stage <- swelections_test_env("CANONICAL_STAGE_DIR")
  skip_if(!nzchar(build) || !nzchar(stage),
          "Read-only canonical integration needs assets and raw-path stage")
  skip_if_not_installed("nanoparquet")
  manifest <- .canonical_manifest(file.path(build, "manifest.json"))
  expect_identical(manifest$format, "parquet")
  expect_identical(manifest$data_version, "data-v0.1.0")
  expect_identical(as.integer(manifest$valar), 2018L)
  expect_identical(manifest$sources$sha256[
    manifest$sources$source == "slutresultat.zip"],
    "cb4a490b576e5a57b42b5ca26d38fa1074c692b4cd7eeb2aca2c3de80560b3a6")
  expect_identical(manifest$sources$classification[
    manifest$sources$source == "slutresultat.zip"],
    "official_archived_snapshot")
  expect_setequal(list.files(build), c("manifest.json", manifest$assets$file))
  for (i in seq_len(nrow(manifest$assets))) {
    file <- file.path(build, manifest$assets$file[[i]])
    expect_identical(as.numeric(file.info(file)$size),
                     as.numeric(manifest$assets$bytes[[i]]))
    expect_identical(.canonical_sha256(file), manifest$assets$sha256[[i]])
    x <- nanoparquet::read_parquet(file)
    for (field in intersect(names(x), c("namn", "ledamot_namn",
                                           "ersattare_namn")))
      expect_true(all(is.na(x[[field]])), info = paste(basename(file), field))
    for (field in names(x)) if (is.character(x[[field]]))
      expect_false(any(x[[field]] == "Namnet gallrat", na.rm = TRUE))
  }
  urls <- setNames(lapply(manifest$assets$file, function(file)
    paste0("file:///", gsub("\\\\", "/", normalizePath(file.path(build, file))))),
    manifest$assets$asset)
  cache <- tempfile("canonical-integration-cache-")
  on.exit(unlink(cache, recursive = TRUE), add = TRUE)
  fetch <- function(...) .canonical_public_2018(manifest, ..., cache_dir = cache,
                                                  urls = urls)
  results <- readRDS(file.path(stage, "rkl2018-valresultat.rds"))
  for (key in names(results)) {
    split <- strsplit(key, "__", fixed = TRUE)[[1L]]
    expect_identical(fetch("valresultat", split[[1L]], split[[2L]]),
                     results[[key]], info = key)
  }
  mandates <- readRDS(file.path(stage, "rkl2018-mandat.rds"))
  for (val in names(mandates))
    expect_identical(fetch("mandat", val), mandates[[val]], info = val)
  candidates <- readRDS(file.path(stage, "rkl2018-kandidater.rds"))
  for (surface in names(candidates))
    expect_identical(fetch(surface), candidates[[surface]], info = surface)
  for (val in c("RD", "RF", "KF")) {
    area <- readRDS(file.path(stage, paste0("rkl2018-person-omrade-",
                                             tolower(val), ".rds")))
    district <- readRDS(file.path(stage, paste0("rkl2018-person-distrikt-",
                                                 tolower(val), ".rds")))
    fetch_base <- function(asset) .canonical_asset(manifest, asset, cache,
                                                    urls[[asset]])
    for (level in c("personvalsomrade", "valdistrikt")) {
      expected_base <- if (level == "personvalsomrade") area else district
      actual_base <- .canonical_person_base(manifest, fetch_base, val, level)
      for (component in names(expected_base))
        expect_identical(actual_base[[component]], expected_base[[component]],
                         info = paste(val, level, component))
    }
    kd <- dplyr::filter(candidates$kandidaturer, .data$valtyp == val)
    for (level in c("personvalsomrade", "valdistrikt")) {
      raw <- if (level == "personvalsomrade") area else district
      for (per_lista in c(FALSE, TRUE)) {
        for (complete in if (level == "personvalsomrade") c(FALSE, TRUE) else FALSE) {
          expected <- .xml2018_person_public(raw, area, kd, level,
            per_lista, complete) |>
            dplyr::arrange(.data$valtyp, .data$valomradeskod,
              .data$personvalsomradeskod, .data$partikod,
              .data$kandidatnummer,
              dplyr::across(dplyr::any_of(c("valdistriktskod", "listnummer"))))
          expect_identical(fetch("personroster", val, level, per_lista,
                                 complete), expected,
                           info = paste(val, level, per_lista, complete))
        }
      }
    }
  }
  # A completed district panel is too large to store as an asset. Rebuild a
  # representative RD person-vote area from both validated base paths.
  fetch_asset <- function(asset) .canonical_asset(manifest, asset, cache,
                                                   urls[[asset]])
  area_raw <- readRDS(file.path(stage, "rkl2018-person-omrade-rd.rds"))
  district_raw <- readRDS(file.path(stage, "rkl2018-person-distrikt-rd.rds"))
  area_parquet <- .canonical_person_base(manifest, fetch_asset, "RD",
                                          "personvalsomrade")
  district_parquet <- .canonical_person_base(manifest, fetch_asset, "RD",
                                              "valdistrikt")
  for (component in names(area_raw))
    expect_identical(area_parquet[[component]], area_raw[[component]],
                     info = paste("RD area", component))
  for (component in names(district_raw))
    expect_identical(district_parquet[[component]], district_raw[[component]],
                     info = paste("RD district", component))
  restrict_area <- function(x) lapply(x, function(table)
    dplyr::filter(table, .data$personvalsomradeskod == "1010"))
  kd_area <- dplyr::filter(candidates$kandidaturer,
                           .data$valtyp == "RD", .data$valkretskod == "10")
  for (per_lista in c(FALSE, TRUE)) {
    expected <- .xml2018_person_public(restrict_area(district_raw),
      restrict_area(area_raw), kd_area,
      "valdistrikt", per_lista, TRUE)
    actual <- .xml2018_person_public(restrict_area(district_parquet),
      restrict_area(area_parquet), kd_area,
      "valdistrikt", per_lista, TRUE)
    expect_gt(nrow(actual), 0L)
    expect_identical(actual, expected,
                     info = paste("RD 1010 completed district", per_lista))
  }
})
