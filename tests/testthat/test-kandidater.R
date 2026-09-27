test_that("candidate table preserves its key and excludes invalid candidacies", {
  out <- make_kandidater_2026(fixture_kandidaturer())
  expect_equal(nrow(out), 4L)
  expect_equal(nrow(dplyr::distinct(out, kandidatnummer, valtyp, partikod)), nrow(out))
  expect_false("3" %in% out$kandidatnummer)
  expect_false(any(vapply(out, is.list, logical(1))))
  expect_identical(names(out), c(
    "valtillfalle", "kandidatnummer", "valtyp", "partikod",
    "partiforkortning", "partibeteckning", "namn", "kon",
    "alder_pa_valdagen", "folkbokforingskommun",
    "valomradeskod", "valomradesnamn", "valkretskod", "valkretsnamn", "antal_valkretsar",
    "namn_varierar", "antal_namn", "antal_valomraden", "flera_valomraden",
    "flera_valkretsar", "antal_listor", "flera_listor", "antal_partier",
    "flera_partier", "antal_valtyper", "flera_valtyper"
  ))
  expect_type(out$kandidatnummer, "character")
  expect_type(out$alder_pa_valdagen, "integer")
  expect_type(out$namn_varierar, "logical")
  kf <- dplyr::filter(out, valtyp == "KF")
  expect_identical(kf$valomradeskod, "0180")
  expect_identical(kf$valomradesnamn, "Stockholm")
  expect_false(any(c("kommunkod", "kommunnamn", "kommunnamn_officiellt") %in% names(out)))
  anna <- dplyr::filter(out, kandidatnummer == "1", valtyp == "RD", partikod == "A")
  expect_identical(anna$namn, "Anna Andersson")
  expect_true(anna$namn_varierar)
  expect_identical(anna$antal_valkretsar, 2L)
  expect_identical(anna$antal_listor, 2L)
  expect_identical(anna$valkretskod, NA_character_)
  expect_true(anna$flera_partier)
  expect_true(anna$flera_valtyper)
  reversed <- make_kandidater_2026(fixture_kandidaturer()[6:1, ])
  expect_equal(dplyr::arrange(out, kandidatnummer, valtyp, partikod),
               dplyr::arrange(reversed, kandidatnummer, valtyp, partikod))
})

test_that("public candidacies complete KF municipality names by code", {
  local_mocked_bindings(
    .resolve_val_file = function(...) "fixture.csv",
    read_kandidaturer_2026 = function(...) fixture_kandidaturer()
  )
  out <- kandidaturer(val = "KF")
  expect_identical(out$valomradeskod, "0180")
  expect_identical(out$valomradesnamn, "Stockholm")
  expect_false(any(c("kommunkod", "kommunnamn", "kommunnamn_officiellt") %in% names(out)))
})

test_that("name normalisation preserves spelling and aliases", {
  expect_identical(.normalisera_kandidatnamn(c("  Berg, Bo  ", "Alias", "A, B, C", NA)),
                   c("Bo Berg", "Alias", "A, B, C", NA_character_))
})

test_that("personal election and elected status distinguish NA from FALSE", {
  candidates <- fixture_kandidatnycklar()
  unknown <- add_personroster_to_kandidater_2026(
    candidates, fixture_personroster(), fixture_personval(FALSE)
  )
  expect_identical(unknown$kvalificerad_personval, c(NA, NA))
  expect_identical(unknown$antal_personvalsomraden, c(NA_integer_, NA_integer_))
  known <- add_personroster_to_kandidater_2026(
    candidates, fixture_personroster(), fixture_personval()
  )
  expect_identical(known$antal_personroster_totalt, c(NA_integer_, NA_integer_))
  expect_identical(known$kvalificerad_personval, c(TRUE, FALSE))
  expect_identical(known$antal_personvalsomraden, c(1L, 0L))
  expect_identical(add_valda_to_kandidater_2026(candidates, fixture_valda()[0, ])$invald,
                   c(NA, NA))
  expect_identical(add_valda_to_kandidater_2026(candidates, fixture_valda())$invald,
                   c(TRUE, FALSE))
})

test_that("candidate result pipeline respects availability without network access", {
  for (available in c(FALSE, TRUE)) {
    local_mocked_bindings(
      .read_resultatindex_2026 = function(...) tibble::tibble(path = "s/rd/val_00_RD.zip"),
      .parse_kandidatresultat_fil_2026 = function(...) list(
        status = tibble::tibble(valtyp = "RD", valomradeskod = "00",
                               valda_available = available, personval_available = available),
        personroster = tibble::tibble(kandidatnummer = "1", valtyp = "RD", partikod = "A",
                                     valomradeskod = "00", antal_personroster = 7L),
        personroster_status = tibble::tibble(valtyp = "RD", valomradeskod = "00", partikod = "A",
                                            personroster_available = available),
        personrostomraden = tibble::tibble(
          kandidatnummer = c("1", "2"), valtyp = "RD", partikod = "A",
          antal_personroster = if (available) c(7L, 0L) else c(NA_integer_, NA_integer_)
        ),
        personval = fixture_personval(available),
        valda = if (available) fixture_valda() else fixture_valda()[0, ]
      )
    )
    out <- .add_kandidatresultat_2026(
      dplyr::filter(make_kandidater_2026(fixture_kandidaturer()),
                    valtyp == "RD", partikod == "A"),
      fixture_kandidaturer(), "RD", progress = FALSE
    )
    expected <- if (available) c(TRUE, FALSE) else c(NA, NA)
    expect_identical(out$invald, expected)
    expect_identical(out$kvalificerad_personval, expected)
    expect_identical(out$antal_personroster_totalt, if (available) c(7L, 0L) else c(NA_integer_, NA_integer_))
    expect_equal(nrow(out), 2L)
    expect_false(any(vapply(out, is.list, logical(1))))
    expect_identical(names(out), c(
      "valtillfalle", "kandidatnummer", "valtyp", "partikod",
      "partiforkortning", "partibeteckning", "namn",
      "antal_personroster_totalt", "kvalificerad_personval",
      "antal_personvalsomraden", "invald", "invald_valomradeskod",
      "invald_valomradesnamn", "invald_valkretskod", "invald_valkretsnamn",
      "invalsordning", "valgrund_id", "valgrund_text", "ersattargrupp",
      "kon", "alder_pa_valdagen", "folkbokforingskommun",
      "valomradeskod", "valomradesnamn", "valkretskod", "valkretsnamn", "antal_valkretsar",
      "namn_varierar", "antal_namn", "antal_valomraden", "flera_valomraden",
      "flera_valkretsar", "antal_listor", "flera_listor",
      "antal_partier", "flera_partier", "antal_valtyper", "flera_valtyper"
    ))
  }
})

test_that("public candidate column contract keeps constituency count beside geography", {
  kandidaturdata <- dplyr::mutate(
    fixture_kandidaturer(), oppen_lista = TRUE, pa_namnvalsedel = TRUE
  )
  local_mocked_bindings(
    kandidaturer = function(...) kandidaturdata,
    .valda_ett_ar = function(...) {
      kandidater(val = "RD", progress = FALSE) |>
        dplyr::filter(invald %in% TRUE) |>
        .valda_invaldsvalkrets_2026() |>
        dplyr::select(-antal_valkretsar)
    },
    .read_resultatindex_2026 = function(...) tibble::tibble(path = "s/rd/val_00_RD.zip"),
    .parse_kandidatresultat_fil_2026 = function(...) list(
      status = tibble::tibble(valtyp = "RD", valomradeskod = "00",
                              valda_available = TRUE, personval_available = TRUE),
      personroster = tibble::tibble(kandidatnummer = "1", valtyp = "RD",
                                   partikod = "A", valomradeskod = "00",
                                   antal_personroster = 7L),
      personrostomraden = tibble::tibble(
        kandidatnummer = c("1", "2"), valtyp = "RD", partikod = "A",
        antal_personroster = c(7L, 0L)
      ),
      personval = fixture_personval(), valda = fixture_valda()
    )
  )
  out <- kandidater(val = "RD", progress = FALSE)
  expected <- strsplit(readLines(test_path("fixtures", "kandidater-public-columns.txt")),
                       ",", fixed = TRUE)[[1]]
  expect_identical(names(out), expected)
  expect_length(expected, 41L)
  expect_type(out$antal_valkretsar, "integer")
  valda_out <- valda(val = "RD", progress = FALSE)
  valda_expected <- strsplit(readLines(test_path("fixtures", "valda-public-columns.txt")),
                             ",", fixed = TRUE)[[1]]
  expect_identical(names(valda_out), valda_expected)
  expect_length(valda_expected, 40L)
  expect_gt(nrow(valda_out), 0L)
  expect_identical(dplyr::select(valda_out, -valkretskod, -valkretsnamn),
                   dplyr::select(dplyr::filter(out, invald %in% TRUE),
                                 -antal_valkretsar, -valkretskod, -valkretsnamn))
})

test_that("valda omits the candidacy constituency count", {
  candidates <- tibble::tibble(
    kandidatnummer = c("1", "2"),
    invald = c(TRUE, FALSE),
    antal_valkretsar = c(29L, 1L),
    marker = c("a", "b")
  )
  local_mocked_bindings(.valda_ett_ar = function(...) {
    dplyr::filter(candidates, invald %in% TRUE) |>
      dplyr::select(-antal_valkretsar)
  })
  out <- valda(progress = FALSE)
  expect_identical(out, dplyr::filter(candidates, invald %in% TRUE) |>
                     dplyr::select(-antal_valkretsar))
})

test_that("positive candidate status survives partial data without inventing negatives", {
  attr_value <- fixture_personval(TRUE)
  attr(attr_value, "personval_available") <- NA
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) tibble::tibble(path = "s/rd/val_00_RD.zip"),
    .parse_kandidatresultat_fil_2026 = function(...) list(
      status = tibble::tibble(valtyp = "RD", valomradeskod = "00",
                              valda_available = NA, personval_available = NA),
      personroster = tibble::tibble(kandidatnummer = "1", valtyp = "RD", partikod = "A",
                                    valomradeskod = "00", antal_personroster = 7L),
      personroster_status = tibble::tibble(valtyp = "RD", valomradeskod = "00", partikod = "A",
                                           personroster_available = NA),
      personrostomraden = tibble::tibble(
        kandidatnummer = c("1", "2"), valtyp = "RD", partikod = "A",
        antal_personroster = c(NA_integer_, NA_integer_)
      ),
      personval = attr_value, valda = fixture_valda()
    )
  )
  out <- .add_kandidatresultat_2026(
    fixture_kandidatnycklar(), fixture_kandidaturer(), "RD", progress = FALSE
  )
  expect_identical(out$invald, c(TRUE, NA))
  expect_identical(out$kvalificerad_personval, c(TRUE, NA))
  expect_identical(out$antal_personvalsomraden, c(1L, NA_integer_))
  expect_identical(out$antal_personroster_totalt, c(NA_integer_, NA_integer_))
})
