test_that("standard is a projection of full with unchanged rows and values", {
  raw <- tibble::tibble(
    valtillfalle = "Val_2026", valar = 2026L, valtyp = "KF",
    rakningstillfalle = "slutlig", geografiniva = "kommun",
    kommunkod = "0180", kommunnamn = "Stockholm",
    partikod = c("1", "2"), antal_roster = c(4L, 6L),
    andel_roster = c(0.4, 0.6), rapporteringstid = "2026-09-13"
  )
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(valresultat = function(...) raw)))
  standard <- results(election = "municipal", level = "municipality")
  full <- results(election = "municipal", level = "municipality",
                  detail = "full")
  expect_identical(standard, full[names(standard)])
  expect_identical(nrow(standard), nrow(full))
  expect_false("reporting_time" %in% names(standard))
  expect_true("reporting_time" %in% names(full))
  expect_identical(standard, valresultat(val = "KF", niva = "kommun", names = "en"))
  expect_identical(results(election = "KF", level = "municipality", names = "sv"),
                   valresultat(val = "KF", niva = "kommun"))
  expect_error(results(detail = "wide"), "detail")
  expect_error(valresultat(detaljniva = "wide"), "detail")
})

test_that("standard seat geography uses the municipality and regional area", {
  raw <- tibble::tibble(
    valar = c(2026L, 2026L), valtyp = c("KF", "RF"),
    rakningstillfalle = "slutlig", geografiniva = c("kommun", "region"),
    valomradeskod = c("0180", "01"),
    valomradesnamn = c("Stockholm", "Region Stockholm"),
    partikod = "1", antal_mandat = 1L
  )
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(mandat = function(...) raw)))
  out <- seats()
  expect_identical(out$municipality_code, c("0180", NA_character_))
  expect_identical(out$region_code, c(NA_character_, "01"))
  expect_false("electoral_area_code" %in% names(out))
  expect_identical(out, seats(detail = "full")[names(out)])
})

test_that("broader municipal preference votes use area totals and omit qualification", {
  raw <- tibble::tibble(
    valtillfalle = "Val_2026", valar = 2026L, valtyp = "KF",
    kandidatnummer = c("A", "B", "A"), namn = c("A", "B", "A"),
    partikod = "P", partiforkortning = "P", partibeteckning = "Parti P",
    geografiniva = "personvalsomrade",
    personvalsomradeskod = c("018001", "018001", "018002"),
    personvalsomradesnamn = c("First", "First", "Second"),
    valomradeskod = "0180", valomradesnamn = "Stockholm",
    valkretskod = c("018001", "018001", "018002"),
    valkretsnamn = c("First", "First", "Second"),
    antal_personroster = c(2L, 0L, 3L),
    antal_partiroster = c(20L, 20L, 30L),
    andel_personroster = c(0.1, 0, 0.1),
    kvalificerad_personval = c(TRUE, FALSE, TRUE),
    rakningstillfalle = "slutlig", valdatum = "2026-09-13", test = FALSE
  )
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(personroster = function(..., niva) {
      expect_identical(niva, "personvalsomrade")
      raw
    })))
  out <- preference_votes(election = "municipal", level = "municipality")
  expect_identical(out$candidate_number, c("A", "B"))
  expect_identical(out$preference_votes, c(5L, 0L))
  expect_identical(out$party_votes, c(50L, 50L))
  expect_identical(out$preference_vote_share, c(0.1, 0))
  expect_identical(out$municipality_code, c("0180", "0180"))
  expect_false("qualified_by_preference_votes" %in% names(out))
  expect_false("preference_vote_area_code" %in% names(out))
  expect_identical(out, personroster(val = "KF", niva = "kommun", names = "en"))
  expect_error(preference_votes(election = "municipal", level = "municipality",
                                by_list = TRUE), "not available")
  incomplete <- raw
  incomplete$partikod[incomplete$personvalsomradeskod == "018002"] <- "Q"
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(personroster = function(...) incomplete)))
  partial <- preference_votes(election = "municipal", level = "municipality")
  expect_true(all(is.na(partial$preference_votes)))
  expect_true(all(is.na(partial$party_votes[partial$party_code == "P"])))
  expect_true(all(is.na(partial$preference_vote_share[partial$party_code == "P"])))
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(personroster = function(...) dplyr::bind_rows(raw, raw[1, ]))))
  expect_error(preference_votes(election = "municipal", level = "municipality"),
               "unique candidate keys")
})

test_that("regional preference votes recompute shares and preserve missing coverage", {
  area <- tibble::tibble(
    valar = 2026L, valtyp = "RF", valomradeskod = "01",
    valomradesnamn = "Region Stockholm",
    personvalsomradeskod = c("0110", "0120", "0110"),
    partikod = c("P", "P", "Q"), kandidatnummer = c("A", "A", "B"),
    antal_personroster = c(2L, 3L, 1L),
    antal_partiroster = c(10L, 20L, 4L)
  )
  out <- .aggregate_preference_area(area, "region")
  a <- dplyr::filter(out, .data$partikod == "P")
  b <- dplyr::filter(out, .data$partikod == "Q")
  expect_identical(a$antal_personroster, 5L)
  expect_identical(a$antal_partiroster, 30L)
  expect_identical(a$andel_personroster, 5 / 30)
  expect_true(is.na(b$antal_personroster))
  expect_true(is.na(b$antal_partiroster))
  expect_true(is.na(b$andel_personroster))
  expect_identical(anyDuplicated(out[c("valomradeskod", "partikod",
                                    "kandidatnummer")]), 0L)
  standard <- .public_detail(out, "preference_votes", "standard")
  expect_identical(standard$regionkod, c("01", "01"))
  expect_false("valomradeskod" %in% names(standard))
  expect_false("kvalificerad_personval" %in% names(standard))
})

test_that("candidate standard geography separates candidacy from election outcome", {
  raw <- tibble::tibble(
    valar = 2026L, valtyp = "RD", kandidatnummer = "1", namn = "A",
    partikod = "P", valomradeskod = "00", valomradesnamn = "Riket",
    valkretskod = "01", valkretsnamn = "Krets 1",
    invald_valkretskod = "02", invald_valkretsnamn = "Krets 2",
    invald = TRUE, antal_personroster_totalt = 2L,
    teknisk_extra = "source"
  )
  candidate <- .public_detail(raw, "candidates", "standard")
  expect_identical(candidate$kandidatur_valkretskod, "01")
  expect_identical(candidate$invald_valkretskod, "02")
  expect_false("valkretskod" %in% names(candidate))
  expect_false("teknisk_extra" %in% names(candidate))
  full <- .public_detail(raw, "candidates", "full")
  expect_identical(candidate, full[names(candidate)])
  expect_true("teknisk_extra" %in% names(full))
})

test_that("every English and Swedish table shares the standard/full projection", {
  raw <- tibble::tibble(
    valtillfalle = "Val_2026", valar = 2026L, valtyp = "RD",
    kandidatnummer = "1", namn = "A", partikod = "P",
    valomradeskod = "00", valomradesnamn = "Riket",
    valkretskod = "01", valkretsnamn = "Krets 1",
    personvalsomradeskod = "01", personvalsomradesnamn = "Krets 1",
    antal_roster = 4L, antal_mandat = 1L, antal_personroster = 2L,
    antal_partiroster = 4L, andel_personroster = 0.5,
    rapporteringstid = "preserved"
  )
  local_mocked_bindings(.raw_public_api = lapply(.raw_public_api,
    function(...) function(...) raw))
  english <- list(
    results = function(detail) results(election = "RD", level = "national", detail = detail),
    seats = function(detail) seats(election = "RD", detail = detail),
    candidacies = function(detail) candidacies(election = "RD", detail = detail),
    candidates = function(detail) candidates(election = "RD", detail = detail),
    elected = function(detail) elected(election = "RD", detail = detail),
    substitutes = function(detail) substitutes(election = "RD", detail = detail),
    preference_votes = function(detail) preference_votes(election = "RD", detail = detail)
  )
  swedish <- list(
    results = function() valresultat(val = "RD", niva = "riket", names = "en"),
    seats = function() mandat(val = "RD", names = "en"),
    candidacies = function() kandidaturer(val = "RD", names = "en"),
    candidates = function() kandidater(val = "RD", names = "en"),
    elected = function() valda(val = "RD", names = "en"),
    substitutes = function() ersattare(val = "RD", names = "en"),
    preference_votes = function() personroster(val = "RD", names = "en")
  )
  for (table in names(english)) {
    standard <- english[[table]]("standard")
    full <- english[[table]]("full")
    expect_identical(standard, full[names(standard)], info = table)
    expect_identical(standard, swedish[[table]](), info = table)
    expect_identical(nrow(standard), nrow(raw), info = table)
    expect_false("reporting_time" %in% names(standard), info = table)
    expect_true("reporting_time" %in% names(full), info = table)
  }
})

test_that("KF constituency naming is semantic across all seven tables", {
  raw <- tibble::tibble(
    valar = 2026L, valtyp = c("RD", "RF", "KF"),
    kandidatnummer = "1", namn = "Unchanged", partikod = "P",
    valomradeskod = c("00", "01", "0136"),
    valomradesnamn = c("Riket", "Stockholm", "Haninge"),
    valkretskod = c("01", "0101", "013601"),
    valkretsnamn = c("Stockholms kommun", "Regional krets", "Haninge Norra"),
    invald_valkretskod = c("02", "0102", "013602"),
    invald_valkretsnamn = c("Stockholms län", "Annan regional krets", "Haninge Södra")
  )
  for (table in names(.standard_fields)) {
    full <- .public_detail(raw, table, "full")
    standard <- .public_detail(raw, table, "standard")
    prefix <- if (table %in% c("candidacies", "candidates")) "kandidatur_" else
      if (table == "elected") "invald_" else ""
    expect_identical(standard[[paste0(prefix, "kommunvalkretskod")]],
                     c(NA_character_, NA_character_,
                       if (table == "elected") "013602" else "013601"), info = table)
    expect_true(is.na(standard[[paste0(prefix, "valkretskod")]][3]), info = table)
    expect_identical(standard, full[names(standard)], info = table)
    expect_identical(.public_output_names(standard, "en")$election_code, raw$valtyp)
    expect_identical(.canonical_names_sv(.public_output_names(standard, "en")),
                     standard, info = table)
    expect_identical(.canonical_names_sv(.public_output_names(full, "en")),
                     full, info = table)
    if (table == "candidates") {
      expect_identical(standard$invald_kommunvalkretskod[3], "013602")
      expect_identical(standard$kandidatur_kommunvalkretskod[3], "013601")
    }
    kf <- .public_detail(raw[3, ], table, "standard")
    expect_false(paste0(prefix, "valkretskod") %in% names(kf), info = table)
    # The source representation remains available, including its KF value.
    expect_identical(full[[paste0("kall_", prefix, "valkretskod")]][3],
                     if (table == "elected") "013602" else "013601", info = table)
    expect_identical(nrow(standard), nrow(raw))
  }
})

test_that("RD/RF district constituencies are distinct from municipal context", {
  raw <- tibble::tibble(valtyp = c("RD", "RF", "KF"),
    geografiniva = "valdistrikt", valdistriktskod = "01800101",
    valkretskod = c("01", "0101", "018003"),
    valkretsnamn = c("RD", "RF", "KF"),
    kommunvalkretskod = "018003", kommunvalkretsnamn = "Municipal")
  out <- .public_detail(raw, "results", "standard")
  expect_identical(out$valkretskod, c("01", "0101", NA_character_))
  expect_identical(out$kommunvalkretskod, rep("018003", 3))
  expect_identical(out, .public_detail(raw, "results", "full")[names(out)])
})

test_that("preference area and substitute context avoid redundant standard aliases", {
  raw <- tibble::tibble(valtyp = "KF", geografiniva = "personvalsomrade",
    valomradeskod = "0136", valomradesnamn = "Haninge",
    valkretskod = "013601", valkretsnamn = "Haninge Norra",
    personvalsomradeskod = "013601", personvalsomradesnamn = "Haninge Norra")
  p <- .public_detail(raw, "preference_votes", "standard")
  expect_identical(p$personvalsomradeskod, "013601")
  expect_false(any(c("valkretskod", "kommunvalkretskod") %in% names(p)))
  s <- .public_detail(raw, "substitutes", "standard")
  expect_identical(s$kommunkod, "0136")
  expect_identical(s$kommunvalkretskod, "013601")
  expect_false("valomradeskod" %in% names(s))
  expect_true("valomradeskod" %in% names(.public_detail(raw, "substitutes", "full")))
  expect_identical(.public_detail(raw, "substitutes", "full")$kall_valomradeskod,
                   "0136")
  raw$valkretskod <- "013600"
  raw$personvalsomradeskod <- "0136"
  out <- .public_detail(raw, "candidacies", "standard")
  expect_true(is.na(out$kandidatur_kommunvalkretskod))
  expect_identical(.public_detail(raw, "candidacies", "full")$kall_kandidatur_valkretskod,
                   "013600")
})

test_that("empty and filtered tables use the requested election schema in both languages", {
  raw <- tibble::tibble(
    valar = 2026L, valtyp = c("RD", "RF", "KF"),
    geografiniva = "personvalsomrade", kandidatnummer = "1", namn = "A",
    partikod = "P", valomradeskod = c("00", "01", "0136"),
    valomradesnamn = c("Riket", "Stockholm", "Haninge"),
    valkretskod = c("01", "0101", "013601"), valkretsnamn = "Constituency",
    invald_valkretskod = c("02", "0102", "013602"),
    invald_valkretsnamn = "Elected constituency",
    personvalsomradeskod = c("01", "0101", "013601"),
    personvalsomradesnamn = "Constituency", antal_personroster = 2L,
    antal_partiroster = 4L, andel_personroster = 0.5,
    rapporteringstid = "source metadata")
  current <- raw
  local_mocked_bindings(.raw_public_api = lapply(.raw_public_api,
    function(...) function(...) current))
  english <- list(results, seats, candidacies, candidates, elected, substitutes,
                  preference_votes)
  swedish <- list(valresultat, mandat, kandidaturer, kandidater, valda, ersattare,
                  personroster)
  for (election in c("RD", "RF", "KF")) {
    populated <- raw[raw$valtyp == election, ]
    for (i in seq_along(english)) {
      current <- populated
      for (detail in c("standard", "full")) {
        args <- list(election = election, names = "sv", detail = detail)
        filled <- do.call(english[[i]], args)
        current <- populated[0, ]
        empty <- do.call(english[[i]], args)
        expect_identical(empty, filled[0, ], info = paste(i, election, detail))
        en <- do.call(english[[i]], utils::modifyList(args, list(names = "en")))
        expect_identical(.canonical_names_sv(en), empty)
        expect_identical(empty, do.call(swedish[[i]],
          list(val = election, detaljniva = detail)))
        current <- populated
      }
      current <- populated[0, ]
      standard <- do.call(english[[i]], list(election = election, names = "sv"))
      full <- do.call(english[[i]],
                      list(election = election, names = "sv", detail = "full"))
      expect_identical(standard, full[names(standard)])
      if (election == "KF") {
        expect_false(any(c("valkretskod", "kandidatur_valkretskod",
                           "invald_valkretskod") %in% names(standard)))
      }
    }
  }
  # Filtering a mixed request down to KF does not change its column contract.
  for (i in 2:7) {
    current <- raw
    filled <- do.call(english[[i]], list(names = "sv"))
    current <- raw[3, ]
    filtered <- do.call(english[[i]], list(names = "sv"))
    expect_identical(names(filtered), names(filled))
    current <- raw[0, ]
    expect_identical(do.call(english[[i]], list(names = "sv")), filled[0, ])
  }
})

test_that("mixed substitutes keep only distinct parent roles and preserve raw context in full", {
  raw <- tibble::tibble(valtyp = c("RD", "RF", "KF"),
    valomradeskod = c("00", "01", "0136"),
    valomradesnamn = c("Riket", "Stockholm", "Haninge"),
    valkretskod = c("01", "0101", "013601"),
    valkretsnamn = c("RD constituency", "RF constituency", "KF constituency"))
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(ersattare = function(...) raw)))
  standard <- substitutes(names = "sv")
  full <- substitutes(names = "sv", detail = "full")
  expect_identical(standard$valomradeskod, c("00", NA_character_, NA_character_))
  expect_identical(standard$valkretskod, c("01", "0101", NA_character_))
  expect_identical(standard$regionkod, c(NA_character_, "01", NA_character_))
  expect_identical(standard$kommunkod, c(NA_character_, NA_character_, "0136"))
  expect_identical(standard$kommunvalkretskod,
                   c(NA_character_, NA_character_, "013601"))
  expect_identical(full$kall_valomradeskod, raw$valomradeskod)
  expect_identical(full$kall_valomradesnamn, raw$valomradesnamn)
  expect_identical(standard, full[names(standard)])
  expect_false(any(grepl("^kall_", names(standard))))
  expect_identical(standard, ersattare())
  expect_identical(.canonical_names_sv(substitutes()), standard)
  expect_identical(.canonical_names_sv(substitutes(detail = "full")), full)
})

test_that("seat level selection determines the election schema even with election NULL", {
  raw <- tibble::tibble(valtyp = "KF", valomradeskod = "0136",
    valomradesnamn = "Haninge", valkretskod = "013601",
    valkretsnamn = "Haninge Norra")
  current <- raw
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(mandat = function(...) current)))
  populated <- seats(level = "municipal_constituency")
  expect_true("municipal_constituency_code" %in% names(populated))
  expect_false(any(c("constituency_code", "region_code") %in% names(populated)))
  expect_identical(populated, seats(election = "municipal", level = "municipal_constituency"))
  current <- raw[0, ]
  expect_identical(seats(level = "municipal_constituency"), populated[0, ])
  expect_identical(seats(level = "municipal_constituency"),
                   mandat(niva = "kommunvalkrets", names = "en"))
})

test_that("empty broader preference views have the same schema and types as populated views", {
  raw <- tibble::tibble(valar = 2026L, valtyp = "KF", valomradeskod = "0136",
    valomradesnamn = "Haninge", personvalsomradeskod = "013601",
    personvalsomradesnamn = "Haninge Norra", valkretskod = "013601",
    valkretsnamn = "Haninge Norra", partikod = "P", kandidatnummer = "1",
    antal_personroster = 2L, antal_partiroster = 4L)
  current <- raw
  local_mocked_bindings(.raw_public_api = utils::modifyList(.raw_public_api,
    list(personroster = function(...) current)))
  for (election in c("KF", "RF")) {
    raw$valtyp <- election
    level <- if (election == "KF") "municipality" else "region"
    sv_level <- if (election == "KF") "kommun" else "region"
    for (detail in c("standard", "full")) {
      current <- raw
      filled <- preference_votes(election = election, level = level, detail = detail)
      current <- raw[0, ]
      empty <- preference_votes(election = election, level = level, detail = detail)
      expect_identical(empty, filled[0, ])
      expect_identical(empty, personroster(val = election, niva = sv_level,
        detaljniva = detail, names = "en"))
      expect_identical(.canonical_names_sv(empty),
        preference_votes(election = election, level = level, detail = detail, names = "sv"))
    }
  }
})
