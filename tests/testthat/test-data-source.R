test_that("explicit data directory takes precedence over the option", {
  root <- tempdir()
  old <- options(swelections.data_dir = file.path(root, "option"),
                 valresultat.data_dir = NULL)
  on.exit(options(old), add = TRUE)
  expect_identical(val_data_dir(file.path(root, "explicit")),
                   normalizePath(file.path(root, "explicit"), winslash = "/", mustWork = FALSE))
  expect_identical(val_data_dir(),
                   normalizePath(file.path(root, "option"), winslash = "/", mustWork = FALSE))
  options(swelections.data_dir = NULL)
  expect_null(val_data_dir())
  expect_error(val_local_path("file.txt", 2026, "test"), "Ingen lokal datamapp")
})

test_that("new package options take precedence over legacy options", {
  old <- options(swelections.data_dir = "new", valresultat.data_dir = "old",
                 swelections.resultatsamling_2022 = "new2022",
                 valresultat.resultatsamling_2022 = "old2022",
                 swelections.resultatsamling_2026 = "new2026",
                 valresultat.resultatsamling_2026 = "old2026")
  on.exit(options(old), add = TRUE)
  expect_identical(basename(val_data_dir()), "new")
  expect_identical(.resultatsamling(2022), "new2022")
  expect_identical(.resultatsamling(2026), "new2026")
  options(swelections.data_dir = NULL,
          swelections.resultatsamling_2022 = NULL,
          swelections.resultatsamling_2026 = NULL)
  expect_identical(basename(val_data_dir()), "old")
  expect_identical(.resultatsamling(2022), "old2022")
  expect_identical(.resultatsamling(2026), "old2026")
})

test_that("ordinary local reads never fall back to remote sources", {
  local_mocked_bindings(val_remote_url = function(...) stop("Unexpected remote access"))
  root <- tempfile()
  dir.create(file.path(root, "2026", "test"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- file.path(root, "2026", "test", "fixture.txt")
  writeLines("synthetic fixture", path)
  expect_identical(val_file("fixture.txt", 2026, "test", "local", root),
                   val_local_path("fixture.txt", 2026, "test", root))
  expect_identical(val_file("fixture.txt", 2026, "test", "auto", root),
                   val_local_path("fixture.txt", 2026, "test", root))
  expect_error(val_file("missing.txt", 2026, "test", "local", root), "Filen finns inte")
})

test_that("remote and auto resolution return URLs without downloading", {
  root <- tempfile()
  expect_identical(val_file("missing.txt", 2026, "test", "auto", root),
                   "https://resultat.val.se/resultatfiler/test/missing.txt")
  expect_identical(val_file("fixture.txt", 2026, "test", "remote", root),
                   "https://resultat.val.se/resultatfiler/test/fixture.txt")
  expect_identical(val_remote_url("/file.txt", "test", "https://example.invalid/"),
                   "https://example.invalid/file.txt")
})

test_that("dated archives intentionally replace a different same-day snapshot", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  working <- file.path(root, "working.txt")
  writeLines("first", working)
  archive <- archive_val_file(working, "fixture.txt", 2026, "test", root, as.Date("2026-01-01"))
  expect_true(same_file_md5(working, archive))
  writeLines("second", working)
  expect_false(same_file_md5(working, archive))
  expect_identical(archive_val_file(working, "fixture.txt", 2026, "test", root,
                                    as.Date("2026-01-01")), archive)
  expect_identical(readLines(archive), "second")
  expect_false(same_file_md5(working, file.path(root, "missing.txt")))
})
