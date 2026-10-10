# Small deterministic build-tool regressions, separate from installed-package tests.
# Rscript development/test_r_only_preparation.R
source("data-raw/prepare-canonical-2022.R")
testthat::test_that("JSON serialization preserves container and scalar semantics", {
  original <- jsonlite::fromJSON(
    '{"empty_array":[],"empty_object":{},"single":[1],"null":null,"zero":0,"float":1.0,"id":"50975","name":"Å"}',
    simplifyVector = FALSE)
  serialized <- charToRaw(enc2utf8(as.character(jsonlite::toJSON(original,
    auto_unbox = TRUE, null = "null", digits = NA))))
  restored <- canonical2022_json(serialized)
  testthat::expect_true(isTRUE(all.equal(original, restored, tolerance = 0)))
  testthat::expect_identical(names(original$empty_object), names(restored$empty_object))
  testthat::expect_identical(restored$id, "50975")
})
testthat::test_that("R ZIP staging preserves bytes and has fixed metadata", {
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  files <- file.path(root, c("one.zip", "two.zip"))
  values <- list(first.json = charToRaw('{"empty":[],"null":null,"number":0}'),
    second.csv = charToRaw("id;name\r\n1;A\r\n"))
  for (file in files) canonical2022_zip(file, values)
  testthat::expect_identical(canonical2022_bytes(files[[1]]), canonical2022_bytes(files[[2]]))
  testthat::expect_identical(utils::unzip(files[[1]], list = TRUE)$Name, names(values))
  testthat::expect_true(all(format(utils::unzip(files[[1]], list = TRUE)$Date,
    "%Y-%m-%d %H:%M:%S") == "2022-09-11 00:00:00"))
  for (member in names(values))
    testthat::expect_identical(canonical2022_member(files[[1]], member), values[[member]])
})
testthat::test_that("Norrbotten correction is scoped, typed and source preserving", {
  raw <- list(valtyp = "RF", valtillfalle = "Val_20220911", valomrade = list(kod = "25",
    party = list(partikod = "0110", listnummer = "0110-03652", kandidatNummer = "50975",
      child = list(kandidatnummer = 50975L), number = 50975L,
      other = list(kandidatnummer = "123"))))
  x <- canonical2022_correct(raw, "mandatfordelning")
  testthat::expect_identical(x$raw$valomrade$party$kandidatNummer, "488")
  testthat::expect_identical(x$raw$valomrade$party$child$kandidatnummer, 488L)
  testthat::expect_identical(x$raw$valomrade$party$number, 50975L)
  testthat::expect_identical(raw$valomrade$party$kandidatNummer, "50975")
  bad <- raw; bad$valomrade$party$partikod <- "0001"
  testthat::expect_error(canonical2022_correct(bad, "mandatfordelning"))
  bad <- raw; bad$valomrade$party$listnummer <- "0110-OTHER"
  testthat::expect_error(canonical2022_correct(bad, "mandatfordelning"))
  bad <- raw; bad$valtyp <- "KF"
  testthat::expect_error(canonical2022_correct(bad, "mandatfordelning"))
  bad <- raw; bad$valomrade$party$child$kandidatnummer <- 1L
  testthat::expect_error(canonical2022_correct(bad, "mandatfordelning"))
})
