test_that("the central mapping covers every frozen public column", {
  paths <- list.files(test_path("fixtures"),
                      pattern = "public-columns|district-columns|area-list-columns",
                      full.names = TRUE)
  columns <- unique(unlist(strsplit(
    sub("^[^|]*\\|", "", unlist(lapply(paths, readLines))), ",",
    fixed = TRUE
  )))
  columns <- unique(c(columns,
    "valsedelsstatus", "listnummer", "valkretsbeteckning_pa_valsedeln",
    "ordning", "anmalda_kandidater", "samtycke", "forklaring",
    "valsedelsuppgift", "antal_valsedlar_lista", "giltig",
    "ledamot_kandidatnummer", "ledamot_namn",
    "ersattare_kandidatnummer", "ersattare_namn", "ersattarordning"
  ))
  translated <- .public_name_en(columns)
  expect_length(translated, length(columns))
  expect_false(anyDuplicated(translated) > 0L)
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", translated)))
  expect_error(.public_name_en("unknown_column"), "column mapping")
})

test_that("all seven English functions forward to the supported Swedish API", {
  output <- tibble::tibble(
    valtillfalle = "Val_2026", valar = 2026L, valtyp = "KF",
    geografiniva = "kommun", kommunkod = "0180", antal_roster = 0L,
    andel_roster = NA_real_, invald = FALSE
  )
  received <- list()
  record <- function(label) {
    force(label)
    function(...) {
      received[[label]] <<- list(...)
      output
    }
  }
  local_mocked_bindings(
    valresultat = record("results"), mandat = record("seats"),
    kandidaturer = record("candidacies"), kandidater = record("candidates"),
    valda = record("elected"), ersattare = record("substitutes"),
    personroster = record("preference_votes")
  )
  calls <- list(
    results = results(election = "KF", count = "final", level = "municipality"),
    seats = seats(election = "KF", count = "preliminary", level = "municipality"),
    candidacies = candidacies(election = "KF"),
    candidates = candidates(election = "KF", include_results = FALSE),
    elected = elected(election = "KF"),
    substitutes = substitutes(election = "KF"),
    preference_votes = preference_votes(election = "KF", level = "district",
                                        by_list = TRUE, include_zeros = TRUE)
  )
  for (result in calls) {
    expect_identical(result, .public_output_names(output, "en"))
    expect_identical(nrow(result), nrow(output))
    expect_identical(unname(vapply(result, typeof, "")),
                     unname(vapply(output, typeof, "")))
    expect_identical(result$geographic_level, "kommun")
    expect_identical(result$election_type, "KF")
  }
  expect_identical(received$results$rakning, "slutlig")
  expect_identical(received$results$niva, "kommun")
  expect_identical(received$seats$rakning, "preliminar")
  expect_identical(received$candidates$resultat, FALSE)
  expect_identical(received$preference_votes$niva, "valdistrikt")
  expect_identical(received$preference_votes$per_lista, TRUE)
  expect_identical(received$preference_votes$komplettera_nollor, TRUE)
  expect_false("ar" %in% names(received$results))
  expect_identical(results(year = 2022, from = NULL, to = NULL,
                           names = "sv"), output)
  expect_identical(received$results$ar, 2022)
  results(year = "all", names = "sv")
  expect_identical(received$results$ar, "alla")
  results(from = 2022, to = 2026, names = "sv")
  expect_false("ar" %in% names(received$results))
  expect_identical(received$results$fran, 2022)
  expect_identical(received$results$till, 2026)
})

test_that("output language option is English-only and an explicit choice wins", {
  output <- tibble::tibble(valar = 2026L, antal_roster = 0L,
                           andel_roster = NA_real_, invald = FALSE)
  local_mocked_bindings(valresultat = function(...) output)
  old <- options(swelections.names = "sv")
  on.exit(options(old), add = TRUE)
  expect_identical(results(), output)
  expect_identical(results(names = "en"),
                   .public_output_names(output, "en"))
  expect_identical(results(names = "sv"), output)
  expect_error(results(names = "de"), "names")
  expect_error(results(names = NA_character_), "names")
  options(swelections.names = "de")
  expect_error(results(), "names")
  expect_identical(results(names = "en"),
                   .public_output_names(output, "en"))
})

test_that("English count and level values are strict and systematic", {
  expect_identical(.english_argument_value("final", "count"), "slutlig")
  expect_identical(.english_argument_value("preliminary", "count"), "preliminar")
  expect_identical(.english_argument_value(
    c("district", "municipality", "municipal_constituency", "county",
      "region", "regional_constituency", "parliamentary_constituency",
      "national"), "level"),
    c("valdistrikt", "kommun", "kommunvalkrets", "lan", "region",
      "regionvalkrets", "riksdagsvalkrets", "riket"))
  expect_error(results(count = "slutlig"), "count")
  expect_error(results(level = "kommun"), "level")
  expect_error(results(level = "unknown"), "level")
  expect_error(results(election = "EU"), "valtyp")
  expect_error(seats(election = "EU"), "valtyp|Val")
  expect_error(seats(election = "RD", level = "municipality"), "st.*ds inte")
  expect_error(preference_votes(level = "municipality"), "level")
  expect_error(preference_votes(by_list = NA), "by_list")
  expect_error(preference_votes(include_zeros = 1), "include_zeros")
  expect_identical(.english_argument_value("personal_vote_area", "level"),
                   "personvalsomrade")
})

test_that("actual result fixture is identical across English and Swedish calls", {
  path <- fixture_resultatpath("KF", "M", "slutlig")
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) tibble::tibble(path = path),
    .resultat_file_2026 = function(...) path,
    .read_valresultat_raw = function(...) fixture_resultatraw("KF", "M", "slutlig")
  )
  sv <- valresultat(val = "KF", rakning = "slutlig", niva = "kommun",
                    progress = FALSE)
  en <- results(election = "KF", count = "final", level = "municipality",
                progress = FALSE)
  expect_identical(en, .public_output_names(sv, "en"))
  expect_identical(results(election = "KF", count = "final",
                           level = "municipality", names = "sv",
                           progress = FALSE), sv)
  expect_identical(valresultat(val = "KF", niva = "kommun", names = "en",
                              progress = FALSE), en)
  expect_identical(en$municipality_name, sv$kommunnamn)
  expect_identical(en$vote_share, sv$andel_roster)
  expect_identical(en$votes, sv$antal_roster)
})
