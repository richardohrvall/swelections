test_that("official 2022 candidacies preserve rows, validity and keys", {
  root <- swelections_test_env("KANDIDATURER_DATA_DIR")
  zip <- swelections_test_env("KANDIDATURER_2022_ZIP")
  if (!nzchar(zip) && nzchar(root)) {
    zip <- file.path(root, "2022", "val2022", "parti", "kandidaturer.zip")
  }
  skip_if_not(file.exists(zip), "Official 2022 candidate ZIP not configured")
  current <- swelections_test_env("KANDIDATURER_2026_CSV")
  if (!nzchar(current) && nzchar(root)) {
    current <- file.path(root, "2026", "val2026", "parti", "kandidaturer.csv")
  }
  if (!nzchar(root)) root <- dirname(zip)
  local_mocked_bindings(.resolve_val_file = function(path, ar, ...) {
    if (ar == 2022L) zip else current
  })
  expect_identical(unname(tools::md5sum(zip)),
                   "6f7f7a37a54b25d6163441fa59189ef5")
  extracted <- tempfile()
  dir.create(extracted)
  on.exit(unlink(extracted, recursive = TRUE), add = TRUE)
  csv <- utils::unzip(zip, "kandidaturer.csv", exdir = extracted)
  expect_identical(unname(tools::md5sum(csv)),
                   "639daa9630a1f2554f1c6839473448ee")
  a <- kandidaturer(ar = 2022, source = "local", data_dir = root)
  expect_equal(nrow(a), 170781L)
  expect_equal(sum(a$giltig %in% TRUE), 168233L)
  expect_equal(sum(a$giltig %in% FALSE), 2548L)
  expect_setequal(unique(a$valtyp), c("RD", "RF", "KF"))
  expect_true(all(a$valar == 2022L))
  key <- c("valtyp", "valomradeskod", "valkretskod", "partikod",
           "listnummer", "ordning", "kandidatnummer")
  expect_equal(nrow(dplyr::distinct(a, dplyr::across(dplyr::all_of(key)))), nrow(a))
  expect_identical(unique(dplyr::filter(a, valtyp == "RD")$valomradeskod), "00")
  gotland <- dplyr::filter(a, valtyp == "KF", valomradeskod == "0980")
  expect_equal(nrow(gotland), 314L)
  expect_identical(unique(gotland$valomradesnamn), "Gotland")
  expect_equal(sum(a$pa_namnvalsedel %in% FALSE), 4040L)
  expect_false(anyNA(a$pa_namnvalsedel))
  expect_false(anyNA(a$oppen_lista))
  snapshot_dir <- testthat::test_path("..", "..", ".local-data", "kandidater")
  augusti <- file.path(snapshot_dir, "kandidaturer_20220812.csv")
  valdagen <- file.path(snapshot_dir, "kandidaturer_20220911.csv")
  if (file.exists(augusti) && file.exists(valdagen)) {
    expect_identical(unname(tools::md5sum(augusti)),
                     "a91645a8e6e6d35d897b645c2e360923")
    expect_identical(unname(tools::md5sum(valdagen)),
                     "4073efa71b60a13b46e4d1fd39794114")
    read_snapshot <- function(path) {
      readr::read_delim(
        path, delim = ";",
        col_types = readr::cols(.default = readr::col_character()),
        trim_ws = FALSE, show_col_types = FALSE, progress = FALSE
      ) |>
        janitor::clean_names() |>
        parse_kandidaturer_2026(
          ar = 2022L,
          namnvalsedlar_kompletta = .namnvalsedlar_kompletta(path, 2022L)
        )
    }
    aug <- read_snapshot(augusti)
    election <- read_snapshot(valdagen)
    expect_equal(sum(aug$pa_namnvalsedel %in% TRUE), 165414L)
    expect_equal(sum(aug$pa_namnvalsedel %in% FALSE), 0L)
    expect_equal(sum(is.na(aug$pa_namnvalsedel)), 2732L)
    expect_equal(sum(election$pa_namnvalsedel %in% TRUE), 166742L)
    expect_equal(sum(election$pa_namnvalsedel %in% FALSE), 0L)
    expect_equal(sum(is.na(election$pa_namnvalsedel)), 4026L)
    person <- function(data) dplyr::filter(
      data, valtyp == "RD", valomradeskod == "00",
      valkretskod == "01", partikod == "1610", listnummer == "05969",
      ordning == 1L, kandidatnummer == "58431"
    )
    expect_identical(person(aug)$valsedelsstatus, "B")
    expect_true(is.na(person(aug)$pa_namnvalsedel))
    expect_identical(person(election)$pa_namnvalsedel, TRUE)
    expect_identical(person(a)$pa_namnvalsedel, TRUE)
    blank <- function(data) dplyr::filter(
      data, valtyp == "RD", valomradeskod == "00",
      valkretskod == "01", partikod == "1482",
      kandidatnummer == "1196"
    )
    expect_true(is.na(blank(aug)$pa_namnvalsedel))
    expect_true(is.na(blank(election)$pa_namnvalsedel))
    expect_identical(blank(a)$pa_namnvalsedel, FALSE)
  }
  if (file.exists(current)) {
    b <- kandidaturer(ar = 2026, source = "local", data_dir = root)
    if (identical(unname(tools::md5sum(current)),
                  .verifierade_kandidatur_csv_md5(2026L))) {
      expect_equal(sum(b$pa_namnvalsedel %in% TRUE), 173196L)
      expect_equal(sum(b$pa_namnvalsedel %in% FALSE), 5497L)
      expect_false(anyNA(b$pa_namnvalsedel))
    }
    ab <- kandidaturer(ar = c(2022, 2026), source = "local", data_dir = root)
    expect_identical(ab, dplyr::bind_rows(a, b))
    expect_equal(nrow(dplyr::distinct(b, dplyr::across(dplyr::all_of(key)))), nrow(b))
  }
})
