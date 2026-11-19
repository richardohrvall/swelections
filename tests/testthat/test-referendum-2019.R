oland_2019_html_fixture <- function(municipality_code) {
  rows <- if (municipality_code == "0885") {
    list(
      c("B\u00f6da", "629", "138", "310", "13"),
      c("H\u00f6gby", "875", "132", "446", "18"),
      c("K\u00e4lla-Persn\u00e4s", "598", "93", "296", "8"),
      c("Alb\u00f6ke- F\u00f6ra- Breds\u00e4ttra-Egby-L\u00f6t", "953", "230", "397", "14"),
      c("K\u00f6ping", "1 117", "282", "369", "28"),
      c("Borgholms 1", "1 406", "325", "496", "30"),
      c("Borgholms 2", "1 376", "326", "480", "10"),
      c("G\u00e4rdsl\u00f6sa-L\u00e5ngl\u00f6t-Runsten", "1 048", "403", "259", "14"),
      c("R\u00e4pplinge-H\u00f6gsrum", "1 104", "410", "320", "14"),
      c("TOTALT INKOMNA R\u00d6STER 2019-05-26", "9 106", "2 339", "3 373", "149"),
      c("R\u00f6ster onsdagsr\u00e4kningen 2019-05-29", "", "64", "114", "5"),
      c("TOTALT R\u00d6STRESULTAT FOLKOMR\u00d6STNING", "9 106", "2 403", "3 487", "154")
    )
  } else {
    list(
      c("Algutsrum", "1 190", "403", "418", "27"),
      c("Gl\u00f6mminge", "530", "228", "141", "7"),
      c("G\u00e5rdby", "1 207", "388", "442", "39"),
      c("M\u00f6rbyl\u00e5nga-Kastl\u00f6sa", "1 803", "299", "839", "35"),
      c("Runsb\u00e4ck", "1 667", "510", "611", "32"),
      c("Skogsby", "1 272", "381", "459", "25"),
      c("Sn\u00e4ckstrand", "1 404", "524", "460", "25"),
      c("Syd\u00f6land", "848", "187", "389", "13"),
      c("Talludden", "1 206", "326", "387", "28"),
      c("Vickleby-Resmo", "710", "208", "278", "28"),
      c("TOTALT INKOMNA R\u00d6STER 2019-05-26", "11 837", "3 454", "4 424", "259"),
      c("R\u00f6ster onsdagsr\u00e4kningen 2019-05-29", "", "7", "8", "0"),
      c("TOTALT R\u00d6STRESULTAT FOLKOMR\u00d6STNING", "11 837", "3 461", "4 432", "259")
    )
  }
  tr_html <- vapply(rows, function(r) {
    paste0("<tr>", paste0("<td>", r, "</td>", collapse = ""), "</tr>")
  }, character(1L))
  paste0(
    "<!DOCTYPE html><html lang=\"sv\"><head><meta charset=\"utf-8\"></head><body>",
    "<table><thead><tr><th>Valdistrikt</th><th>R\u00f6stber\u00e4ttigade</th>",
    "<th>JA</th><th>NEJ</th><th>BLANK</th></tr></thead><tbody>",
    paste(tr_html, collapse = ""),
    "</tbody></table></body></html>"
  )
}

write_oland_2019_fixture_archive <- function(dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  specs <- .referendum_2019_oland_sources()
  for (i in seq_len(nrow(specs))) {
    code <- specs$municipality_code[i]
    path <- file.path(dir, specs$filename[i])
    writeBin(charToRaw(enc2utf8(oland_2019_html_fixture(code))), path)
    specs$bytes[i] <- as.integer(file.info(path)$size)
    specs$sha256[i] <- .canonical_sha256(path)
  }
  specs
}

test_that("2019 municipal referendum source and district registries stay valid", {
  sources <- .referendum_2019_oland_sources()
  expect_equal(nrow(sources), 2L)
  expect_setequal(sources$municipality_code, c("0840", "0885"))
  expect_true(all(grepl("^[a-f0-9]{64}$", sources$sha256)))
  expect_true(all(sources$bytes > 0L))
  expect_true(all(grepl("id_/", sources$url, fixed = TRUE)))

  districts <- .referendum_2019_oland_districts()
  expect_equal(nrow(districts), 19L)
  expect_equal(sum(districts$municipality_code == "0840"), 10L)
  expect_equal(sum(districts$municipality_code == "0885"), 9L)
  expect_false(anyDuplicated(districts$district_code) > 0L)
})

test_that("2019 Oland referendum parsing handles districts, Wednesday collection, and strict missingness", {
  archive <- withr::local_tempdir()
  specs <- write_oland_2019_fixture_archive(archive)
  local_mocked_bindings(.referendum_2019_oland_sources = function() specs)

  muni <- results(2019, election = "referendum", level = "municipality",
                  source = "local", data_dir = archive, detail = "full")
  expect_equal(nrow(muni), 6L)
  expect_setequal(muni$municipality_code, c("0840", "0885"))
  expect_true(all(muni$election_year == 2019L))
  expect_true(all(muni$election_date == "2019-05-26"))
  expect_true(all(muni$election_code == "F"))
  expect_true(all(muni$referendum_question == "\u00d6land en kommun?"))
  expect_true(all(muni$election_event == "SE-F-2019-05-26-0840-0885"))
  expect_false(any(grepl("party", names(muni))))

  morb <- muni[muni$municipality_code == "0840", ]
  expect_identical(
    stats::setNames(morb$votes, morb$voting_option_code)[c("JA", "NEJ", "BLANK")],
    c(JA = 3461L, NEJ = 4432L, BLANK = 259L)
  )
  expect_true(all(morb$valid_votes == 8152L))
  expect_true(all(morb$eligible_voters == 11837L))
  expect_equal(sum(morb$vote_share), 1)
  expect_identical(morb$is_blank_option, morb$voting_option_code == "BLANK")

  borg <- muni[muni$municipality_code == "0885", ]
  expect_identical(
    stats::setNames(borg$votes, borg$voting_option_code)[c("JA", "NEJ", "BLANK")],
    c(JA = 2403L, NEJ = 3487L, BLANK = 154L)
  )
  expect_true(all(borg$valid_votes == 6044L))
  expect_true(all(borg$eligible_voters == 9106L))
  expect_equal(sum(borg$vote_share), 1)

  # Unreported invalid ballots keep invalid_votes, total_votes and turnout strictly NA.
  expect_identical(muni$invalid_votes, rep(NA_integer_, 6L))
  expect_identical(muni$total_votes, rep(NA_integer_, 6L))
  expect_identical(muni$turnout, rep(NA_real_, 6L))

  # Default level for 2019 municipal referendum is municipality.
  expect_identical(
    results(2019, election = "referendum", source = "local", data_dir = archive),
    results(2019, election = "referendum", level = "municipality",
            source = "local", data_dir = archive)
  )

  # District output includes 19 ordinary + 2 collection units = 21 units x 3 options.
  dist <- results(2019, election = "referendum", level = "district",
                  source = "local", data_dir = archive, detail = "full")
  expect_equal(nrow(dist), 63L)
  expect_equal(sum(dist$district_type == "ordinary"), 57L)
  expect_equal(sum(dist$district_type == "collection"), 6L)

  wed <- dist[dist$district_type == "collection", ]
  expect_setequal(unique(wed$district_code), c("F-0840-00", "F-0885-00"))
  expect_true(all(is.na(wed$eligible_voters)))
  expect_true(all(is.na(wed$turnout)))
  expect_true(all(is.na(wed$invalid_votes)))
  expect_true(all(is.na(wed$total_votes)))

  wed_0885 <- wed[wed$municipality_code == "0885", ]
  expect_identical(
    stats::setNames(wed_0885$votes, wed_0885$voting_option_code)[c("JA", "NEJ", "BLANK")],
    c(JA = 64L, NEJ = 114L, BLANK = 5L)
  )
  alb <- dist[dist$district_code == "08850203", ]
  expect_identical(unique(alb$district_name), "Alb\u00f6ke-F\u00f6ra-Breds\u00e4ttra-Egby-L\u00f6t")
  expect_identical(unique(alb$eligible_voters), 953L)
})

test_that("2019 municipal referendum API aligns English and Swedish interfaces", {
  archive <- withr::local_tempdir()
  specs <- write_oland_2019_fixture_archive(archive)
  local_mocked_bindings(.referendum_2019_oland_sources = function() specs)

  for (lvl_en in c("municipality", "district")) {
    lvl_sv <- unname(.english_argument_values$level[[lvl_en]])
    en_full <- results(2019, election = "referendum", level = lvl_en,
                       source = "local", data_dir = archive, names = "en", detail = "full")
    en_std <- results(2019, election = "F", level = lvl_en,
                      source = "local", data_dir = archive, names = "en", detail = "standard")
    sv_full <- valresultat(2019, val = "F", niva = lvl_sv,
                           source = "local", data_dir = archive, names = "sv", detaljniva = "full")
    sv_std <- valresultat(2019, val = "F", niva = lvl_sv,
                          source = "local", data_dir = archive, names = "sv", detaljniva = "standard")

    expect_identical(en_std, en_full[names(en_std)])
    expect_gt(ncol(en_full), ncol(en_std))
    expect_identical(
      results(2019, election = "referendum", level = lvl_en,
              source = "local", data_dir = archive, names = "sv", detail = "full"),
      sv_full
    )
    expect_identical(.public_output(sv_full, "en"), en_full)
    expect_identical(.public_output(sv_std, "en"), en_std)
  }
})

test_that("2019 municipal referendum validates checksums, table integrity, and unsupported requests", {
  archive <- withr::local_tempdir()
  specs <- write_oland_2019_fixture_archive(archive)
  local_mocked_bindings(.referendum_2019_oland_sources = function() specs)

  expect_error(
    results(2019, election = "referendum", source = "local"),
    "Specify `data_dir`"
  )
  expect_error(
    results(2019, election = "referendum", count = "preliminary", source = "local", data_dir = archive),
    "final results only"
  )
  expect_error(
    results(2019, election = "referendum", level = "national", source = "local", data_dir = archive),
    "geographic level"
  )
  expect_error(
    results(2019, election = "referendum", level = "county", source = "local", data_dir = archive),
    "geographic level"
  )
  expect_error(
    results(2019, election = "referendum", update = TRUE, source = "local", data_dir = archive),
    "read-only"
  )
  expect_error(
    results(2019, election = "referendum", archive = TRUE, source = "local", data_dir = archive),
    "read-only"
  )

  # Tampered local file triggers SHA256 failure.
  bad_dir <- withr::local_tempdir()
  write_oland_2019_fixture_archive(bad_dir)
  writeLines("tampered", file.path(bad_dir, specs$filename[1]))
  expect_error(
    results(2019, election = "referendum", source = "local", data_dir = bad_dir),
    "Changed or unverified"
  )

  # Tampered summary total inside HTML fails reconciliation.
  corrupt_html <- sub("<td>2 403</td>", "<td>2 404</td>", oland_2019_html_fixture("0885"), fixed = TRUE)
  corrupt_file <- tempfile(fileext = ".html")
  writeBin(charToRaw(enc2utf8(corrupt_html)), corrupt_file)
  on.exit(unlink(corrupt_file), add = TRUE)
  expect_error(
    .referendum_2019_parse_html(corrupt_file, specs[specs$municipality_code == "0885", ], "corrupt.html"),
    "disagree with total referendum result"
  )
})

test_that("election_events and valtillfallen expose 2019 referendum metadata without altering defaults", {
  default_events <- election_events()
  expect_false("F" %in% default_events$election_code)

  ref_events <- election_events(election = "referendum")
  expect_equal(ref_events$election_year, c(2003L, 2019L))
  expect_identical(ref_events$election_code, c("F", "F"))

  ev2019 <- election_events(year = 2019, election = "referendum")
  expect_equal(nrow(ev2019), 1L)
  expect_identical(ev2019$election_event, "SE-F-2019-05-26-0840-0885")
  expect_identical(ev2019$referendum_question, "\u00d6land en kommun?")
  expect_identical(ev2019$scope_level, "municipality")
  expect_identical(ev2019$scope_code, "0840,0885")

  sv2019 <- valtillfallen(ar = 2019, val = "F")
  expect_equal(nrow(sv2019), 1L)
  expect_identical(sv2019$valtillfalle, "SE-F-2019-05-26-0840-0885")
  expect_identical(sv2019$folkomrostningsfraga, "\u00d6land en kommun?")
  expect_identical(sv2019$omfattningsniva, "kommun")
  expect_identical(sv2019$valklass, "ordinarie")

  expect_equal(nrow(election_events(2019, "referendum", "re_election")), 0L)
})

test_that("2019 municipal referendum supports canonical Parquet manifest roundtrip", {
  skip_if_not_installed("nanoparquet")
  archive <- withr::local_tempdir()
  canonical_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()
  specs <- write_oland_2019_fixture_archive(archive)
  local_mocked_bindings(.referendum_2019_oland_sources = function() specs)

  levels <- c("municipality", "district")
  parts <- lapply(levels, function(lvl) {
    df <- results(2019, election = "referendum", level = lvl,
                  source = "local", data_dir = archive, names = "en", detail = "full")
    df$.table <- lvl
    df
  })
  x <- dplyr::bind_rows(parts)
  x[] <- lapply(x, unname)
  asset <- "referendum2019-results-final"
  pq <- file.path(canonical_dir, paste0(asset, ".parquet"))
  nanoparquet::write_parquet(x, pq, compression = "gzip")

  manifest_path <- file.path(canonical_dir, "referendum2019-manifest.json")
  manifest <- list(
    data_version = "data-v0.4.1",
    schema_version = 3L,
    value_schema_version = 1L,
    storage_schema_version = 1L,
    format = "parquet",
    valserie = "folkomr",
    valar = 2019L,
    event_kind = "ordinary",
    sources = specs[c("municipality_code", "filename", "bytes", "sha256", "url")],
    assets = data.frame(
      asset = asset, file = basename(pq), rows = nrow(x),
      bytes = unname(file.info(pq)$size), sha256 = .canonical_sha256(pq),
      stringsAsFactors = FALSE
    ),
    tables = data.frame(
      asset = asset, table = levels,
      columns = vapply(parts, function(z) paste(setdiff(names(z), ".table"), collapse = ","), ""),
      stringsAsFactors = FALSE
    )
  )
  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE, na = "null")

  withr::local_options(list(
    swelections.canonical_manifest = c(`folkomr:ordinary:2019` = manifest_path),
    swelections.canonical_cache_dir = cache_dir
  ))

  for (lvl in levels) {
    for (lang in c("en", "sv")) {
      for (det in c("standard", "full")) {
        expect_identical(
          results(2019, election = "referendum", level = lvl, source = "canonical",
                  names = lang, detail = det),
          results(2019, election = "referendum", level = lvl, source = "local",
                  data_dir = archive, names = lang, detail = det)
        )
      }
    }
  }
})
