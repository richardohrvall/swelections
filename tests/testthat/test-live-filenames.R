test_that("live index paths with Val_2026 are used without prefix assumptions", {
  expect_identical(
    val_remote_url("index.md5", "val2026"),
    "https://resultat.val.se/resultatfiler/val2026/index.md5"
  )
  md5 <- strrep("a", 32)
  paths <- c(
    "p/rd/Val_2026_preliminar_00_RD.zip",
    "s/rd/Val_2026_slutlig_00_RD.zip",
    "s/rf/Val_2026_slutlig_01_RF.zip",
    "s/kf/Val_2026_slutlig_0180_KF.zip",
    "s/rf/Val_2026_slutlig_OS_RF.zip",
    "s/kf/Val_2026_slutlig_OS_KF.zip"
  )
  index_file <- tempfile()
  writeLines(paste(md5, paste0("./", paths)), index_file)
  old <- options(swelections.resultatsamling_2026 = NULL,
                 valresultat.resultatsamling_2026 = NULL)
  on.exit(options(old), add = TRUE)
  expect_identical(.resultatsamling_2026(), "val2026")
  local_mocked_bindings(.resolve_val_file = function(path, ar, samling, ...) {
    expect_identical(path, "index.md5")
    expect_identical(ar, 2026)
    expect_identical(samling, "val2026")
    index_file
  })
  index <- .read_resultatindex_2026(source = "local")
  expect_identical(index$path, paths)
  expect_identical(.valresultat_paths(index, "RD", "preliminar", "D"), paths[1])
  expect_identical(.valresultat_paths(index, "RD", "slutlig", "U"), paths[2])
  expect_identical(.valresultat_paths(index, "RF", "slutlig", "O"), paths[5])
  expect_identical(.valresultat_paths(index, "KF", "slutlig", "O"), paths[6])
  individual <- .resultat_paths_2026(index, c("RD", "RF", "KF"))
  expect_identical(individual$path, paths[2:4])
})

test_that("genrep collection remains an explicit configurable choice", {
  index_file <- tempfile()
  path <- "s/rd/Genrep_2026_slutlig_00_RD.zip"
  writeLines(paste(strrep("b", 32), paste0("./", path)), index_file)
  old <- options(swelections.resultatsamling_2026 = "genrep2026")
  on.exit(options(old), add = TRUE)
  local_mocked_bindings(.resolve_val_file = function(path, ar, samling, ...) {
    expect_identical(samling, "genrep2026")
    index_file
  })
  expect_identical(.resultatsamling_2026(), "genrep2026")
  expect_identical(.read_resultatindex_2026(source = "local")$path, path)
})

test_that("live JSON names inside ZIP are recognized for all source types", {
  live <- test_path("fixtures", "val-2026-live-names.zip")
  old <- test_path("fixtures", "valresultat-rd.zip")
  for (type in c("rostfordelning", "mandatfordelning", "summering")) {
    expect_identical(read_raw_json_zip_2026(live, type = type)$valtyp, "RD")
  }
  distrikt <- .read_valresultat_raw(live, "D", "RD", "slutlig")
  expect_identical(distrikt$valtyp, "RD")
  expect_identical(distrikt$namn, "Norrmalm-Östermalm")
  expect_identical(.read_valresultat_raw(live, "M", "RD", "slutlig")$valtyp, "RD")
  expect_identical(.read_valresultat_raw(live, "U", "RD", "slutlig")$valtyp, "RD")
  # Genrepsformen utan valområdeskoden i summeringsnamnet stöds fortsatt.
  expect_identical(.read_valresultat_raw(old, "U", "RD", "slutlig")$valtyp, "RD")
  expect_s3_class(read_underordnad_summering_zip_2026(live), "data.frame")
})
