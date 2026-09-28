test_that("local update is rejected before any file or remote access", {
  unexpected <- function(...) stop("Unexpected IO")
  local_mocked_bindings(
    val_file = unexpected, download_val_file = unexpected,
    val_remote_url = unexpected, archive_val_file = unexpected
  )
  for (fun in list(kandidaturer, kandidater, personroster, valda, mandat, ersattare)) {
    for (archive in c(FALSE, TRUE)) {
      expect_error(fun(source = "local", update = TRUE, archive = archive),
                   'source = "local".*update = TRUE')
    }
  }
  expect_error(kandidater(source = "local", resultat = FALSE, update = TRUE),
               'source = "local".*update = TRUE')
  expect_error(.read_resultatindex_2026(source = "local", update = TRUE),
               'source = "local".*update = TRUE')
  expect_error(.resultat_file_2026("file.zip", source = "local", update = TRUE),
               'source = "local".*update = TRUE')
})

test_that("local archival requires an existing file and never enters download logic", {
  unexpected <- function(...) stop("Unexpected network access")
  local_mocked_bindings(download_val_file = unexpected, val_remote_url = unexpected)
  root <- tempfile()
  dir.create(file.path(root, "2026", "test"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- val_local_path("fixture.txt", 2026, "test", root)
  expect_error(.resolve_val_file("fixture.txt", 2026, "test", "local", root, archive = TRUE),
               "Filen finns inte")
  expect_false(dir.exists(file.path(root, "2026", "test", "archive")))
  writeLines("first", path)
  expect_identical(.resolve_val_file("fixture.txt", 2026, "test", "local", root, archive = TRUE), path)
  archive <- val_archive_path("fixture.txt", 2026, "test", root)
  expect_identical(readLines(archive), "first")
  writeLines("second", path)
  .resolve_val_file("fixture.txt", 2026, "test", "local", root, archive = TRUE)
  expect_identical(readLines(archive), "second")
})

test_that("candidate CSV and result index use local archival", {
  unexpected <- function(...) stop("Unexpected network access")
  local_mocked_bindings(download_val_file = unexpected, val_remote_url = unexpected,
    read_kandidaturer_2026 = function(file) {
      expect_true(file.exists(file))
      expect_identical(readLines(file), "synthetic candidacies")
      fixture_kandidaturer()
    }
  )
  root <- tempfile()
  dir.create(file.path(root, "2026", "val2026", "parti"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  writeLines("synthetic candidacies", val_local_path("parti/kandidaturer.csv", 2026, "val2026", root))
  expect_equal(
    kandidaturer(source = "local", data_dir = root, archive = TRUE),
    .kort_kommunnamn_2026(fixture_kandidaturer())
  )
  expect_true(file.exists(val_archive_path("parti/kandidaturer.csv", 2026, "val2026", root)))

  old <- options(swelections.resultatsamling_2026 = "test")
  on.exit(options(old), add = TRUE)
  dir.create(file.path(root, "2026", "test"), recursive = TRUE)
  md5 <- paste(rep("a", 32), collapse = "")
  writeLines(paste(md5, "./s/rd/val_00_RD.zip"), val_local_path("index.md5", 2026, "test", root))
  index <- .read_resultatindex_2026(source = "local", data_dir = root, archive = TRUE)
  expect_identical(index$path, "s/rd/val_00_RD.zip")
  expect_true(file.exists(val_archive_path("index.md5", 2026, "test", root)))
  expect_error(.resultat_file_2026(index$path, source = "local", data_dir = root, archive = TRUE),
               "Filen finns inte")
  file <- val_local_path(index$path, 2026, "test", root)
  dir.create(dirname(file), recursive = TRUE)
  writeLines("synthetic result placeholder", file)
  expect_identical(.resultat_file_2026(index$path, "local", root, archive = TRUE), file)
  expect_true(file.exists(val_archive_path(index$path, 2026, "test", root)))
})

test_that("auto and remote retain their previous read and update routing", {
  local_mocked_bindings(
    val_file = function(path, ar, samling, source, data_dir, base_url) {
      list(route = "read", path = path, ar = ar, samling = samling,
           source = source, data_dir = data_dir, base_url = base_url)
    },
    download_val_file = function(path, ar, samling, data_dir, base_url, update, archive) {
      list(route = "download", path = path, ar = ar, samling = samling,
           data_dir = data_dir, base_url = base_url, update = update, archive = archive)
    }
  )
  for (source in c("auto", "remote")) {
    out <- .resolve_val_file("x", 2026, "test", source, "root", "base")
    expect_identical(out, list(route = "read", path = "x", ar = 2026, samling = "test",
                              source = source, data_dir = "root", base_url = "base"))
    for (flags in list(c(TRUE, FALSE), c(FALSE, TRUE), c(TRUE, TRUE))) {
      out <- .resolve_val_file("x", 2026, "test", source, "root", "base", flags[1], flags[2])
      expect_identical(out, list(route = "download", path = "x", ar = 2026, samling = "test",
                                data_dir = "root", base_url = "base", update = flags[1], archive = flags[2]))
    }
  }
})
