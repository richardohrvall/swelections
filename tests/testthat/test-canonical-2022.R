test_that("2022 remains unpublished and is not selected automatically", {
  expect_null(.canonical_release(2022L))
  expect_identical(.select_public_source("auto", 2022L, "valresultat"), "auto")
  old <- options(swelections.canonical_manifest = NULL)
  on.exit(options(old), add = TRUE)
  for (fun in list(results, seats, candidacies, candidates, elected,
                  substitutes, preference_votes)) {
    expect_error(fun(year = 2022L, source = "canonical"), "configured local build")
  }
})

test_that("2022 canonical relations preserve requested election order", {
  source <- tibble::tibble(valtyp = c("RD", "RF", "KF"),
                          ledamot_kandidatnummer = c("1", "2", "3"))
  fetch <- function(...) .canonical_names_en(source)
  out <- .canonical_public_2022(list(), fetch, "ersattare", c("RF", "RD"),
    NULL, FALSE, FALSE, TRUE, "slutlig")
  expect_identical(out$valtyp, c("RF", "RD"))
  expect_identical(out$ledamot_kandidatnummer, c("2", "1"))
})

test_that("mixed 2022 canonical preference views follow raw global ordering", {
  local_mocked_bindings(
    .select_public_source = function(...) "canonical",
    .canonical_source = function(ar, surface, val, ...) tibble::tibble(
      valar = 2022L, valtyp = val, valomradeskod = "01",
      personvalsomradeskod = "0101", partikod = "1", kandidatnummer = "1")
  )
  out <- personroster(2022L, source = "canonical", detaljniva = "full")
  expect_identical(out$valtyp, c("KF", "RD", "RF"))
  out <- personroster(2022L, val = c("RF", "RD"), source = "canonical",
                     detaljniva = "full")
  expect_identical(out$valtyp, c("RD", "RF"))
})

test_that("materialized candidate bases preserve raw ordering and subset counts", {
  kd <- fixture_kandidaturer()
  if (!"oppen_lista" %in% names(kd)) kd$oppen_lista <- TRUE
  if (!"pa_namnvalsedel" %in% names(kd)) kd$pa_namnvalsedel <- TRUE
  stored <- .kandidater_bas(kd, 2022L)
  # Asset/result sorting must not affect the no-result candidacy view.
  stored <- stored[rev(seq_len(nrow(stored))), ]
  for (values in list(NULL, "RD", "KF", c("RD", "KF"))) {
    input <- if (is.null(values)) kd else dplyr::filter(kd, .data$valtyp %in% values)
    expect_identical(.canonical_candidate_base_2022(input, stored),
                     .kandidater_bas(input, 2022L))
  }
})

test_that("2022 canonical count, language and detail are independent", {
  skip_if_not_installed("nanoparquet")
  root <- tempfile("canonical-2022-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  entries <- list()
  layouts <- list()
  for (count in c("preliminar", "slutlig")) {
    x <- tibble::tibble(valar = 2022L, valtyp = "KF",
      rakningstillfalle = count, geografiniva = "kommun",
      valomradeskod = "0980", valomradesnamn = "Gotland",
      partikod = "A", antal_roster = 0L, andel_roster = NA_real_,
      valkretskod = NA_character_, valkretsnamn = NA_character_)
    asset <- paste0("rkl2022-results-", count, "-kf")
    y <- .canonical_names_en(x)
    columns <- names(y)
    y$.table <- "kommun"
    path <- file.path(root, paste0(asset, ".parquet"))
    nanoparquet::write_parquet(y, path)
    entries[[count]] <- data.frame(asset = asset, file = basename(path),
      bytes = unname(file.info(path)$size), sha256 = .canonical_sha256(path))
    layouts[[count]] <- data.frame(asset = asset, table = "kommun",
                                   columns = paste(columns, collapse = ","))
  }
  manifest <- list(data_version = "data-v0.2.0", schema_version = 2L,
    format = "parquet", valserie = "rkl", valar = 2022L, sources = list(),
    assets = dplyr::bind_rows(entries), tables = dplyr::bind_rows(layouts))
  path <- file.path(root, "manifest.json")
  jsonlite::write_json(manifest, path, auto_unbox = TRUE)
  old <- options(swelections.canonical_manifest = path,
                  swelections.canonical_assets_dir = root,
                  swelections.canonical_cache_dir = file.path(root, "cache"))
  on.exit(options(old), add = TRUE)
  for (count in c("preliminary", "final")) {
    full <- results(2022, election = "municipal", count = count,
      level = "municipality", source = "canonical", detail = "full")
    standard <- results(2022, election = "municipal", count = count,
      level = "municipality", source = "canonical")
    sv <- valresultat(2022, val = "KF",
      rakning = if (count == "final") "slutlig" else "preliminar",
      niva = "kommun", source = "canonical")
    expect_identical(standard, full[names(standard)])
    expect_identical(standard, .public_output_names(sv, "en"))
    expect_identical(standard$votes, 0L)
    expect_identical(standard$vote_share, NA_real_)
    expect_false("constituency_code" %in% names(standard))
    expect_true("municipal_constituency_code" %in% names(standard))
  }
  manifest$valar <- 2018L
  jsonlite::write_json(manifest, path, auto_unbox = TRUE)
  expect_error(results(2022, source = "canonical"), "Expected RKL 2022")
})

test_that("normalized 2022 base vocabulary round trips without changing values", {
  x <- tibble::tibble(node_id = 1L, party_id = 2L, list_id = 3L,
    listnummer_raw = "0110-03652", kandidatnamn_raw = "Bo Larsson",
    parti_complete = TRUE, list_complete = FALSE, ovriga_complete = NA,
    personval_available = TRUE, antal_personroster_officiellt = 430L)
  expect_identical(.canonical_names_sv(.canonical_names_en(x)), x)
  expect_identical(.canonical_names_en(x)$official_preference_votes, 430L)
})

test_that("2022 stored preference views are selected without changing zeros or NA", {
  for (level in c("personvalsomrade", "valdistrikt")) {
    flags <- if (level == "personvalsomrade")
      expand.grid(by_list = c(FALSE, TRUE), zeros = c(FALSE, TRUE)) else
      data.frame(by_list = c(FALSE, TRUE), zeros = FALSE)
    asset <- paste0("rkl2022-preference-votes-",
      if (level == "personvalsomrade") "area" else "district", "-kf")
    layouts <- data.frame(asset = asset,
      table = paste(flags$by_list, flags$zeros, sep = "__"),
      columns = "candidate_number,preference_votes")
    data <- dplyr::bind_rows(lapply(layouts$table, function(view)
      tibble::tibble(.person_view = view, candidate_number = c("1", "2", "3"),
                    preference_votes = c(5L, 0L, NA_integer_))))
    fetch <- function(name) { expect_identical(name, asset); data }
    for (i in seq_len(nrow(flags))) {
      got <- .canonical_public_2022(list(tables = layouts, schema_version = 2L),
        fetch, "personroster", "KF", level, flags$by_list[[i]], flags$zeros[[i]],
        TRUE, "slutlig")
      expect_identical(got$antal_personroster, c(5L, 0L, NA_integer_))
      expect_identical(got$kandidatnummer, c("1", "2", "3"))
    }
  }
})
