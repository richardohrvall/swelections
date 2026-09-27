test_that("ersattare year selections stack exact-year results in requested order", {
  local_mocked_bindings(.ersattare_ett_ar = function(ar, val, ...) {
    tibble::tibble(
      valtillfalle = paste0("Val_", ar), valar = as.integer(ar),
      valtyp = val[[1]], partikod = "P", ledamot_kandidatnummer = "1",
      ersattare_kandidatnummer = paste0("e", ar), ersattarordning = 1L
    )
  })
  a <- ersattare(ar = 2022, val = "RD")
  b <- ersattare(ar = 2026, val = "RD")
  expect_identical(ersattare(ar = c(2022, 2026), val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(ersattare(ar = c(2026, 2022, 2026), val = "RD"),
                   dplyr::bind_rows(b, a))
  expect_identical(ersattare(ar = "alla", val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(ersattare(fran = 2022, till = 2026, val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(names(a)[1:2], c("valtillfalle", "valar"))
  expect_type(a$valar, "integer")
  expect_identical(tail(names(formals(ersattare)), 2), c("fran", "till"))
  expect_false("rakning" %in% names(formals(ersattare)))
})

test_that("ersattare rejects invalid years before source access", {
  local_mocked_bindings(.ersattare_ett_ar = function(...) stop("Unexpected IO"))
  expect_error(ersattare(ar = 2018, val = "RD"), "2018")
  expect_error(ersattare(ar = 2022, fran = 2022, val = "RD"), "alternativa")
  expect_error(ersattare(ar = 2025, val = "KF"), "2025")
})

test_that("ersattare requires all final area files without preliminary fallback", {
  index <- tibble::tibble(path = c(
    "p/rf/Val_2026_preliminar_01_RF.zip",
    "p/rf/Val_2026_preliminar_02_RF.zip",
    "s/rf/Val_2026_slutlig_01_RF.zip"
  ))
  expect_error(.slutliga_mandat_paths(index, "RF", "ersattare"), "02")
  index <- dplyr::bind_rows(index,
    tibble::tibble(path = "s/rf/Val_2026_slutlig_02_RF.zip"))
  expect_identical(.slutliga_mandat_paths(index, "RF", "ersattare")$path,
                   index$path[3:4])
})
