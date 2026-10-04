test_that("open list is party-area status, distinct from the printed ballot", {
  raw <- fixture_kandidaturer_raw()
  a <- parse_kandidaturer_2026(raw, ar = 2022L,
                                namnvalsedlar_kompletta = TRUE)
  expect_identical(a$valar, rep(2022L, 4))
  expect_identical(a$valomradeskod, rep("00", 4))
  expect_identical(a$oppen_lista, rep(TRUE, 4))
  expect_identical(a$pa_namnvalsedel, c(TRUE, TRUE, FALSE, FALSE))
  expect_identical(a$giltig, c(TRUE, TRUE, TRUE, FALSE))
  expect_identical(a$listnummer[1:2], c("10001", "10001"))
  expect_identical(a$valkretsbeteckning_pa_valsedeln[1:2],
                   c("HELA LANDET", "HELA LANDET"))
  b <- parse_kandidaturer_2026(raw)
  expect_identical(b$pa_namnvalsedel, c(TRUE, TRUE, NA, NA))
  expect_identical(b$valar, rep(2026L, 4))
  raw$anmaldakandidater <- "J"
  expect_identical(parse_kandidaturer_2026(raw)$oppen_lista, rep(FALSE, 4))
  raw$anmaldakandidater <- NA_character_
  expect_true(all(is.na(parse_kandidaturer_2026(raw)$oppen_lista)))
  raw$anmaldakandidater[1] <- "J"
  raw$anmaldakandidater[2] <- "N"
  expect_error(parse_kandidaturer_2026(raw), "ANM")
  raw <- fixture_kandidaturer_raw()
  raw$valsedelsstatus[4] <- "O"
  expect_true(is.na(parse_kandidaturer_2026(
    raw, 2022L, namnvalsedlar_kompletta = TRUE
  )$pa_namnvalsedel[4]))
})

test_that("a printed ballot requires a list and an ordering", {
  raw <- fixture_kandidaturer_raw()
  raw$listnummer[1] <- NA_character_
  expect_error(parse_kandidaturer_2026(raw), "saknar listnummer")
  raw <- fixture_kandidaturer_raw()
  raw$ordning[1] <- NA_character_
  expect_error(parse_kandidaturer_2026(raw), "saknar listnummer")
})

test_that("candidacy year selection preserves order, binding, and source paths", {
  raw <- fixture_kandidaturer_raw()
  paths <- list()
  local_mocked_bindings(
    .resolve_val_file = function(path, ar, samling, source, data_dir,
                                  base_url, update, archive) {
      paths[[length(paths) + 1L]] <<- list(path, ar, samling, base_url)
      as.character(ar)
    },
    read_kandidaturer_2022 = function(file) {
      expect_identical(file, "2022")
      parse_kandidaturer_2026(raw, 2022L, TRUE)
    },
    read_kandidaturer_2026 = function(file) {
      expect_identical(file, "2026")
      parse_kandidaturer_2026(raw)
    }
  )
  a <- kandidaturer(detaljniva = "full", ar = 2022, val = "RD")
  b <- kandidaturer(detaljniva = "full", val = "RD")
  expect_identical(b$valar, rep(2026L, 4))
  expect_identical(kandidaturer(detaljniva = "full", ar = c(2022, 2026), val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(kandidaturer(detaljniva = "full", ar = c(2026, 2022, 2026), val = "RD"),
                   dplyr::bind_rows(b, a))
  expect_identical(kandidaturer(detaljniva = "full", fran = 2022, till = 2026, val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(kandidaturer(detaljniva = "full", fran = 2026, val = "RD"), b)
  expect_identical(kandidaturer(detaljniva = "full", fran = 2022, till = 2022, val = "RD"), a)
  expect_error(kandidaturer(detaljniva = "full", ar = 2022, fran = 2022), "alternativa")
  expect_error(kandidaturer(detaljniva = "full", ar = 2024), "2022.*2026")
  expect_identical(paths[[1]][[1]], "parti/kandidaturer.zip")
  expect_identical(paths[[1]][[3]], "val2022")
  expect_identical(paths[[2]][[1]], "parti/kandidaturer.csv")
  expect_identical(paths[[2]][[3]], "val2026")
})

test_that("failure in one candidacy year does not return partial data", {
  local_mocked_bindings(
    .resolve_val_file = function(path, ar, ...) {
      if (ar == 2026L) stop("saknad kandidaturfil")
      as.character(ar)
    },
    read_kandidaturer_2022 = function(file) {
      parse_kandidaturer_2026(fixture_kandidaturer_raw(), 2022L, TRUE)
    }
  )
  expect_error(kandidaturer(detaljniva = "full", ar = c(2022, 2026)), "2026.*saknad")
})

test_that("2022 local candidacy source is required and never fetched implicitly", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  local_mocked_bindings(download_val_file = function(...) stop("Oväntad nätåtkomst"),
                        val_remote_url = function(...) stop("Oväntad nätåtkomst"))
  expect_error(kandidaturer(detaljniva = "full", ar = 2022, source = "local", data_dir = root),
               "Filen finns inte")
  expect_error(kandidaturer(detaljniva = "full", ar = 2022, source = "local", data_dir = root,
                           update = TRUE), 'source = "local".*update = TRUE')
})
