test_that("downloads succeed and restore the user's timeout", {
  dest <- tempfile()
  on.exit(unlink(dest), add = TRUE)
  old <- getOption("timeout")
  calls <- 0L
  fake <- function(url, destfile, mode, quiet) {
    calls <<- calls + 1L
    expect_identical(getOption("timeout"), 180L)
    writeBin(charToRaw("data"), destfile)
    0L
  }
  expect_identical(.download_file("https://example.test/file", dest,
                                  .download = fake, .sleep = function(x) NULL),
                   dest)
  expect_identical(readBin(dest, "raw", 4L), charToRaw("data"))
  expect_identical(calls, 1L)
  expect_identical(getOption("timeout"), old)
})

test_that("transient errors retry, while permanent HTTP errors do not", {
  dest <- tempfile()
  on.exit(unlink(dest), add = TRUE)
  calls <- 0L
  delays <- numeric()
  transient <- function(url, destfile, mode, quiet) {
    calls <<- calls + 1L
    if (calls < 3L) stop("HTTP status was '500 Internal Server Error'")
    writeBin(charToRaw("ok"), destfile)
    0L
  }
  .download_file("https://example.test/file", dest,
                 .download = transient, .sleep = function(x) delays <<- c(delays, x))
  expect_identical(calls, 3L)
  expect_identical(delays, c(1, 2))
  expect_identical(readBin(dest, "raw", 2L), charToRaw("ok"))

  unlink(dest)
  calls <- 0L
  permanent <- function(...) {
    calls <<- calls + 1L
    stop("HTTP status was '404 Not Found'")
  }
  expect_error(.download_file("https://example.test/missing", dest,
                              .download = permanent, .sleep = function(x) NULL),
               "404 Not Found")
  expect_identical(calls, 1L)
})

test_that("exhausted retries and incomplete downloads never publish a file", {
  dest <- tempfile()
  on.exit(unlink(dest), add = TRUE)
  calls <- 0L
  broken <- function(url, destfile, mode, quiet) {
    calls <<- calls + 1L
    writeBin(charToRaw("partial"), destfile)
    stop("connection timed out")
  }
  expect_error(.download_file("https://example.test/file", dest,
                              .download = broken, .sleep = function(x) NULL),
               "connection timed out")
  expect_identical(calls, 3L)
  expect_false(file.exists(dest))

  empty <- function(url, destfile, mode, quiet) {
    file.create(destfile)
    0L
  }
  expect_error(.download_file("https://example.test/file", dest,
                              .download = empty, .sleep = function(x) NULL),
               "empty or missing download")
  expect_false(file.exists(dest))

  short <- function(url, destfile, mode, quiet) {
    writeBin(charToRaw("short"), destfile)
    0L
  }
  expect_error(.download_file("https://example.test/file", dest,
                              expected_bytes = 10L, .download = short,
                              .sleep = function(x) NULL),
               "incomplete download")
  expect_false(file.exists(dest))
})

test_that("a valid existing canonical asset is not downloaded again", {
  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  asset <- file.path(work, "small.rds")
  saveRDS(1L, asset)
  manifest <- list(data_version = "data-v0.1.0",
                   assets = data.frame(asset = "small", file = "small.rds",
                                       bytes = file.info(asset)$size,
                                       sha256 = .canonical_sha256(asset)))
  url <- paste0("file:///", gsub("\\\\", "/", normalizePath(asset)))
  cache <- file.path(work, "cache")
  expect_identical(.canonical_asset(manifest, "small", cache, url), 1L)
  local_mocked_bindings(.download_file = function(...) stop("Unexpected download"))
  expect_identical(.canonical_asset(manifest, "small", cache,
                                    "https://example.test/small.rds"), 1L)
})

test_that("a failed raw update preserves the existing working copy", {
  root <- tempfile()
  dir.create(file.path(root, "2026", "val2026"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- file.path(root, "2026", "val2026", "index.md5")
  writeLines("existing", path)
  local_mocked_bindings(.download_file = function(...) stop("connection timed out"))
  expect_error(download_val_file("index.md5", 2026, "val2026",
                                 data_dir = root, update = TRUE),
               "connection timed out")
  expect_identical(readLines(path), "existing")
  expect_error(download_val_file("missing.md5", 2026, "val2026",
                                 data_dir = root), "connection timed out")
  expect_false(file.exists(file.path(root, "2026", "val2026", "missing.md5")))
})

test_that("remote result indexes use the shared download helper", {
  url <- "https://example.test/index.md5"
  calls <- 0L
  local_mocked_bindings(
    .resolve_val_file = function(...) url,
    .download_file = function(source, destfile, ...) {
      expect_identical(source, url)
      calls <<- calls + 1L
      writeLines(paste(strrep("a", 32), "./s/rd/result.zip"), destfile)
      invisible(destfile)
    }
  )
  out <- .read_resultatindex(2026L, "remote", NULL, FALSE, FALSE)
  expect_identical(out$path, "s/rd/result.zip")
  expect_identical(calls, 1L)
})
