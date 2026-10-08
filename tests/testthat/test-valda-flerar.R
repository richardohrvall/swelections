test_that("valda year selections retain exact-year order and long format", {
  local_mocked_bindings(.valda_ett_ar = function(ar, val, ...) {
    tibble::tibble(
      valtillfalle = paste0("Val_", ar), valar = as.integer(ar),
      kandidatnummer = paste0("k", ar), valtyp = val[[1]],
      partikod = "P", invald = TRUE
    )
  })
  c <- valda(detaljniva = "full", ar = 2018, val = "RD")
  a <- valda(detaljniva = "full", ar = 2022, val = "RD")
  b <- valda(detaljniva = "full", ar = 2026, val = "RD")
  expect_identical(valda(detaljniva = "full", ar = c(2022, 2026), val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(valda(detaljniva = "full", ar = c(2026, 2022, 2026), val = "RD"),
                   dplyr::bind_rows(b, a))
  expect_identical(valda(detaljniva = "full", ar = c(2026, 2018, 2022), val = "RD"),
                   dplyr::bind_rows(b, c, a))
  expect_identical(valda(detaljniva = "full", ar = "alla", val = "RD"), dplyr::bind_rows(valda(detaljniva = "full", ar = 2014, val = "RD"), c, a, b))
  expect_identical(valda(detaljniva = "full", fran = 2022, till = 2026, val = "RD"),
                   dplyr::bind_rows(a, b))
  expect_identical(names(a)[1:2], c("valtillfalle", "valar"))
  expect_type(a$valar, "integer")
  expect_identical(tail(names(formals(valda)), 4),
                   c("fran", "till", "names", "detaljniva"))
  expect_false("rakning" %in% names(formals(valda)))
})

test_that("valda rejects invalid year choices before sources are read", {
  local_mocked_bindings(.valda_ett_ar = function(...) stop("Unexpected source access"))
  expect_error(valda(detaljniva = "full", ar = 2016, val = "RD"), "2016")
  expect_error(valda(detaljniva = "full", ar = 2022, fran = 2022, val = "RD"), "alternativa")
  expect_error(valda(detaljniva = "full", ar = 2025, val = "KF"), "2025")
})

test_that("final index requires every election area without using preliminary data", {
  index <- tibble::tibble(path = c(
    "p/rf/Val_2026_preliminar_01_RF.zip",
    "p/rf/Val_2026_preliminar_02_RF.zip",
    "s/rf/Val_2026_slutlig_01_RF.zip"
  ))
  expect_error(.valda_slutliga_paths(index, "RF"), "02")
  index <- dplyr::bind_rows(index,
    tibble::tibble(path = "s/rf/Val_2026_slutlig_02_RF.zip"))
  expect_identical(.valda_slutliga_paths(index, "RF")$path,
                   index$path[3:4])
})
