test_that("canonical RKL 2018 reproduces raw public tables", {
  skip_if(swelections_test_env("CANONICAL_FULL_RAW") != "1",
          "Full raw XML sweep is opt-in because it reparses large files")
  build <- swelections_test_env("CANONICAL_DIR")
  root <- swelections_test_env("2018_DATA_DIR")
  skip_if(!nzchar(build) || !nzchar(root),
          "Read-only canonical integration needs build and raw archive")
  skip_if_not_installed("nanoparquet")
  manifest <- .canonical_manifest(file.path(build, "manifest.json"))
  manifest_text <- paste(readLines(file.path(build, "manifest.json"),
                               warn = FALSE), collapse = "\n")
  expect_false(grepl('"_row"', manifest_text, fixed = TRUE))
  expect_false(grepl("C:\\\\", manifest_text, fixed = TRUE))
  expect_identical(manifest$data_version, "data-v0.1.0")
  expect_identical(as.integer(manifest$schema_version), 2L)
  expect_identical(manifest$valserie, "rkl")
  expect_identical(as.integer(manifest$valar), 2018L)
  expect_identical(manifest$sources$sha256[
    manifest$sources$source == "slutresultat.zip"],
    "cb4a490b576e5a57b42b5ca26d38fa1074c692b4cd7eeb2aca2c3de80560b3a6")
  expect_identical(manifest$sources$md5[
    manifest$sources$source == "kandidaturer.skv"],
    "9855ac4280c2a5165389a88c647ae49f")
  # The named research snapshot is not the candidate source of this release.
  # An explicit file allows read-only validation without replacing that archive.
  candidate_file <- swelections_test_env("CANONICAL_CANDIDATE_FILE")
  if (!nzchar(candidate_file))
    candidate_file <- file.path(root, "2018", "kandidater", "kandidaturer.skv")
  candidate_source <- manifest$sources[
    manifest$sources$source == "kandidaturer.skv", ]
  if (!file.exists(candidate_file) ||
      !identical(tolower(unname(tools::md5sum(candidate_file))), candidate_source$md5) ||
      !identical(.canonical_sha256(candidate_file), candidate_source$sha256)) {
    stop("Direct canonical/raw validation requires the exact candidate snapshot ",
         "in the manifest. Set SWELECTIONS_TEST_CANONICAL_CANDIDATE_FILE; ",
         "the older named research snapshot is not an equivalent fixture.")
  }
  raw_source <- .kalla_2018
  local_mocked_bindings(.kalla_2018 = function(typ, source, data_dir,
                                              update = FALSE, archive = FALSE) {
    if (typ == "kandidaturer") return(candidate_file)
    raw_source(typ, source, data_dir, update, archive)
  })
  expect_setequal(list.files(build), c("manifest.json", manifest$assets$file))
  inspect_names <- function(x) {
    if (is.data.frame(x)) {
      for (field in intersect(names(x),
        c("name", "member_name", "substitute_name")))
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
    asset_data <- nanoparquet::read_parquet(file)
    expect_true("election_code" %in% names(asset_data))
    expect_false("valtyp" %in% names(asset_data))
    expect_identical(names(.canonical_names_en(.canonical_names_sv(asset_data))),
                     names(asset_data))
    inspect_names(asset_data)
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
    table <- c(valresultat = "results", mandat = "seats",
               kandidaturer = "candidacies", kandidater = "candidates",
               valda = "elected", ersattare = "substitutes",
               personroster = "preference_votes")[[surface]]
    got <- .public_detail(got, table, "full")
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
      valresultat(detaljniva = "full", ar = 2018L, val = val, niva = niva, source = "local",
                  data_dir = root, progress = FALSE),
      "valresultat", val, niva)
    compare(mandat(detaljniva = "full", ar = 2018L, val = val, source = "local",
                   data_dir = root, progress = FALSE), "mandat", val)
    for (niva in c("personvalsomrade", "valdistrikt")) {
      for (per_lista in c(FALSE, TRUE)) compare(
        personroster(detaljniva = "full", ar = 2018L, val = val, niva = niva,
                     per_lista = per_lista, source = "local",
                     data_dir = root, progress = FALSE),
        "personroster", val, niva, per_lista)
    }
    for (per_lista in c(FALSE, TRUE)) compare(
      personroster(detaljniva = "full", ar = 2018L, val = val, niva = "personvalsomrade",
                   per_lista = per_lista, komplettera_nollor = TRUE,
                   source = "local", data_dir = root, progress = FALSE),
      "personroster", val, "personvalsomrade", per_lista, TRUE)
  }
  for (val in c("RD", "RF", "KF")) {
    compare(kandidaturer(detaljniva = "full", ar = 2018L, val = val, source = "local",
                        data_dir = root), "kandidaturer", val)
    compare(kandidater(detaljniva = "full", ar = 2018L, val = val, source = "local",
                      data_dir = root, progress = FALSE), "kandidater", val)
    compare(kandidater(detaljniva = "full", ar = 2018L, val = val, resultat = FALSE,
                      source = "local", data_dir = root),
            "kandidater", val, resultat = FALSE)
    compare(valda(detaljniva = "full", ar = 2018L, val = val, source = "local",
                  data_dir = root, progress = FALSE), "valda", val)
    compare(ersattare(detaljniva = "full", ar = 2018L, val = val, source = "local",
                      data_dir = root, progress = FALSE), "ersattare", val)
  }
  old <- options(swelections.canonical_manifest = file.path(build, "manifest.json"),
                 swelections.canonical_assets_dir = build,
                 swelections.canonical_cache_dir = cache)
  on.exit(options(old), add = TRUE)
  for (language in c("sv", "en")) {
    check_public <- function(raw, canonical)
      expect_identical(canonical, raw, info = paste("public", language))
    check_public(results(2018, "parliamentary", level = "national",
                         source = "local", data_dir = root, names = language),
                 results(2018, "parliamentary", level = "national",
                         source = "canonical", names = language))
    check_public(seats(2018, "parliamentary", source = "local",
                       data_dir = root, names = language),
                 seats(2018, "parliamentary", source = "canonical",
                       names = language))
    for (pair in list(list(candidacies, "candidacies"),
                      list(candidates, "candidates"),
                      list(elected, "elected"),
                      list(substitutes, "substitutes"),
                      list(preference_votes, "preference_votes"))) {
      fun <- pair[[1L]]
      check_public(fun(2018, "parliamentary", source = "local",
                       data_dir = root, names = language),
                   fun(2018, "parliamentary", source = "canonical",
                       names = language))
    }
  }
})

test_that("canonical RKL 2018 reproduces all staged raw-path outputs", {
  build <- swelections_test_env("CANONICAL_DIR")
  stage <- swelections_test_env("CANONICAL_STAGE_DIR")
  skip_if(!nzchar(build) || !nzchar(stage),
          "Read-only canonical integration needs assets and raw-path stage")
  skip_if_not_installed("nanoparquet")
  manifest <- .canonical_manifest(file.path(build, "manifest.json"))
  manifest_text <- paste(readLines(file.path(build, "manifest.json"),
                               warn = FALSE), collapse = "\n")
  expect_false(grepl('"_row"', manifest_text, fixed = TRUE))
  expect_false(grepl("C:\\\\", manifest_text, fixed = TRUE))
  expect_identical(manifest$format, "parquet")
  expect_identical(manifest$data_version, "data-v0.1.0")
  expect_identical(as.integer(manifest$schema_version), 2L)
  expect_equal(nrow(manifest$assets), 20L)
  expect_true(all(startsWith(manifest$assets$asset, "rkl2018-")))
  expect_true(all(grepl("^[a-z0-9-]+[.]parquet$", manifest$assets$file)))
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
    expect_true("election_code" %in% names(x))
    expect_false("valtyp" %in% names(x))
    for (field in intersect(names(x), c("name", "member_name",
                                           "substitute_name")))
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

test_that("public 2018 APIs preserve raw-built values in both name languages", {
  build <- swelections_test_env("CANONICAL_DIR")
  stage <- swelections_test_env("CANONICAL_STAGE_DIR")
  skip_if(!nzchar(build) || !nzchar(stage),
          "Canonical public integration needs local assets and raw-built stage")
  skip_if_not_installed("nanoparquet")
  cache <- tempfile("canonical-public-cache-")
  on.exit(unlink(cache, recursive = TRUE), add = TRUE)
  old <- options(swelections.canonical_manifest = file.path(build, "manifest.json"),
                 swelections.canonical_assets_dir = build,
                 swelections.canonical_cache_dir = cache)
  on.exit(options(old), add = TRUE)
  manifest <- .canonical_manifest(file.path(build, "manifest.json"))
  urls <- stats::setNames(lapply(manifest$assets$file, function(file)
    paste0("file:///", gsub("\\\\", "/", normalizePath(file.path(build, file))))),
    manifest$assets$asset)
  expected <- function(surface, val, level = NULL) .canonical_public_2018(
    manifest, surface, val, level, cache_dir = cache, urls = urls)
  check <- function(actual_sv, actual_en, raw_built, table) {
    raw_standard <- .public_detail(raw_built, table, "standard")
    expect_identical(actual_sv, raw_standard)
    expect_identical(actual_en, .public_output_names(raw_standard, "en"))
    expect_identical(unname(vapply(actual_sv, typeof, "")),
                     unname(vapply(actual_en, typeof, "")))
  }
  for (pair in list(c("RD", "parliamentary", "riket", "national"),
                    c("RF", "regional", "region", "region"),
                    c("KF", "municipal", "kommun", "municipality"))) {
    val <- pair[[1L]]; election <- pair[[2L]]
    check(results(2018, election, level = pair[[4L]], source = "canonical",
                  names = "sv"),
          results(2018, election, level = pair[[4L]], source = "canonical",
                  names = "en"), expected("valresultat", val, pair[[3L]]),
          "results")
    check(seats(2018, election, source = "canonical", names = "sv"),
          seats(2018, election, source = "canonical", names = "en"),
          expected("mandat", val), "seats")
    for (entry in list(
      list(fun = candidacies, surface = "kandidaturer"),
      list(fun = candidates, surface = "kandidater"),
      list(fun = elected, surface = "valda"),
      list(fun = substitutes, surface = "ersattare"))) {
      check(entry$fun(2018, election, source = "canonical", names = "sv"),
            entry$fun(2018, election, source = "canonical", names = "en"),
            expected(entry$surface, val), switch(entry$surface,
              kandidaturer = "candidacies", kandidater = "candidates",
              valda = "elected", ersattare = "substitutes"))
    }
    check(preference_votes(2018, election, source = "canonical", names = "sv"),
          preference_votes(2018, election, source = "canonical", names = "en"),
          expected("personroster", val, "personvalsomrade"),
          "preference_votes")
  }
  check(candidates(2018, "parliamentary", include_results = FALSE,
                   source = "canonical", names = "sv"),
        candidates(2018, "parliamentary", include_results = FALSE,
                   source = "canonical", names = "en"),
        .canonical_public_2018(manifest, "kandidater", "RD", resultat = FALSE,
                               cache_dir = cache, urls = urls), "candidates")
  for (level in c("preference_vote_area", "district")) {
    swedish_level <- if (level == "district") "valdistrikt" else "personvalsomrade"
    check(preference_votes(2018, "parliamentary", level = level,
                           by_list = TRUE, source = "canonical", names = "sv"),
          preference_votes(2018, "parliamentary", level = level,
                           by_list = TRUE, source = "canonical", names = "en"),
          .canonical_public_2018(manifest, "personroster", "RD", swedish_level,
                                 per_lista = TRUE, cache_dir = cache,
                                 urls = urls), "preference_votes")
  }
})

test_that("auto uses the published release path, not a local build override", {
  build <- swelections_test_env("CANONICAL_DIR")
  skip_if(!nzchar(build), "Canonical integration needs local release assets")
  skip_if_not_installed("nanoparquet")
  root <- tempfile("canonical-auto-raw-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  cache <- tempfile("canonical-auto-cache-")
  on.exit(unlink(cache, recursive = TRUE), add = TRUE)
  old <- options(swelections.data_dir = root,
                 swelections.canonical_manifest = "unpublished-local-build.json",
                 swelections.canonical_cache_dir = cache)
  on.exit(options(old), add = TRUE)
  local_mocked_bindings(.canonical_release_manifest = function(release,
      missing_ok = FALSE) file.path(build, "manifest.json"))
  calls <- list(
    list(fun = results, args = list(year = 2018, election = "parliamentary",
                                    level = "national")),
    list(fun = seats, args = list(year = 2018, election = "parliamentary")),
    list(fun = candidacies, args = list(year = 2018,
                                       election = "parliamentary")),
    list(fun = candidates, args = list(year = 2018,
                                      election = "parliamentary")),
    list(fun = elected, args = list(year = 2018, election = "parliamentary")),
    list(fun = substitutes, args = list(year = 2018,
                                       election = "parliamentary")),
    list(fun = preference_votes, args = list(year = 2018,
                                             election = "parliamentary"))
  )
  for (entry in calls) {
    options(swelections.canonical_manifest = "unpublished-local-build.json")
    actual <- do.call(entry$fun, c(entry$args, list(source = "auto")))
    options(swelections.canonical_manifest = file.path(build, "manifest.json"))
    expected <- do.call(entry$fun, c(entry$args, list(source = "canonical")))
    expect_identical(actual, expected)
  }
  options(swelections.canonical_manifest = NULL)
  expect_identical(
    results(2018, "parliamentary", level = "national",
            source = "canonical"),
    results(2018, "parliamentary", level = "national",
            source = "auto"))
})
