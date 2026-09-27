test_that("public functions reject invalid arguments before reading files", {
  local_mocked_bindings(
    .read_resultatindex_2026 = function(...) stop("Unexpected file access"),
    val_file = function(...) stop("Unexpected file access")
  )
  for (fun in list(personroster, ersattare)) {
    expect_error(fun(ar = 2022), "2026")
    expect_error(fun(val = "EU"), "valtyp")
    expect_error(fun(source = "invalid"), "arg")
  }
  expect_error(valda(ar = 2024), "2022.*2026")
  expect_error(valda(val = "EU"), "valtyp")
  expect_error(valda(source = "invalid"), "arg")
  expect_error(kandidater(ar = 2024), "2022.*2026")
  expect_error(kandidater(val = "EU"), "valtyp")
  expect_error(kandidater(source = "invalid"), "arg")
  expect_error(kandidaturer(ar = 2024), "2022.*2026")
  expect_error(kandidaturer(val = "EU"), "valtyp")
  expect_error(kandidaturer(source = "invalid"), "arg")
  expect_error(mandat(ar = 2024), "2022.*2026")
  expect_error(mandat(val = "EU"), "valtyp")
  expect_error(mandat(source = "invalid"), "arg")
  expect_error(mandat(rakning = "invalid"), "rakning")
  expect_error(mandat(niva = "invalid"), "geografisk")
  expect_null(.valtyper(NULL))
  expect_identical(.valtyper(c("rd", "KF", "rd")), c("RD", "KF"))
})

test_that("missing candidate columns and duplicate elections are rejected", {
  expect_error(make_kandidater_2026(tibble::tibble()), "kolumner saknas")
  expect_error(parse_kandidaturer_2026(tibble::tibble()), "kolumner saknas")
  expect_error(make_kandidater_2026(dplyr::mutate(fixture_kandidaturer(), giltig = FALSE)),
               "inga giltiga")
  expect_error(add_valda_to_kandidater_2026(
    fixture_kandidatnycklar(), dplyr::bind_rows(fixture_valda(), fixture_valda())
  ), "vald mer")
})

test_that("valda dispatches only to the official final-year path", {
  local_mocked_bindings(.valda_ett_ar = function(ar, ...) {
    tibble::tibble(valar = as.integer(ar), kandidatnummer = "1", invald = TRUE)
  })
  expect_identical(valda()$valar, 2026L)
  expect_identical(valda(ar = c(2026, 2022, 2026))$valar,
                   c(2026L, 2022L))
})
