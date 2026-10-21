.remote_cache_fixture <- function() {
  root <- tempfile(); dir.create(root)
  withr::local_options(list(swelections.remote_cache_dir = root), .local_envir = parent.frame())
  withr::defer(unlink(root, recursive = TRUE), envir = parent.frame())
  state <- new.env(parent = emptyenv())
  state$files <- list('s/kf/a.zip' = charToRaw('alpha'), 's/kf/b.zip' = charToRaw('beta'))
  state$calls <- character(); state$offline <- FALSE; state$bad_index <- FALSE
  state$bad_file <- FALSE
  state$hash <- function(bytes) {
    tmp <- tempfile(); on.exit(unlink(tmp)); writeBin(bytes, tmp)
    unname(tools::md5sum(tmp))
  }
  state$transport <- function(url, destfile, mode = 'wb', quiet = TRUE) {
    path <- sub('^https://resultat[.]val[.]se/resultatfiler/test/', '', url)
    state$calls <- c(state$calls, path)
    if (path == 'index.md5') {
      if (state$offline) stop('index unavailable')
      text <- if (state$bad_index) '<html>not an index</html>' else
        paste(vapply(state$files, state$hash, ''), paste0('./', names(state$files)))
      writeLines(text, destfile)
    } else {
      bytes <- if (state$bad_file) charToRaw('truncated') else state$files[[path]]
      if (is.null(bytes)) stop('missing fixture')
      writeBin(bytes, destfile)
    }
    0L
  }
  state$fetch <- function(path, expected_bytes = NULL) {
    out <- tempfile(); on.exit(unlink(out))
    .download_file(paste0('https://resultat.val.se/resultatfiler/test/', path), out,
      expected_bytes = expected_bytes, attempts = 1L, .download = state$transport)
    readBin(out, 'raw', n = file.info(out)$size)
  }
  state$request <- function(paths) {
    finish <- .remote_raw_begin(); on.exit(finish())
    lapply(paths, state$fetch)
  }
  state$root <- root
  state
}

test_that('empty and persistent raw cache use a fresh index for every request', {
  f <- .remote_cache_fixture()
  first <- f$request(c('s/kf/a.zip', 's/kf/b.zip'))
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 's/kf/b.zip'))
  expect_null(.remote_raw_state$context)
  expect_identical(f$request(c('s/kf/a.zip', 's/kf/b.zip')), first)
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 's/kf/b.zip', 'index.md5'))
  expect_true(all(grepl('[.]zip$', list.files(f$root, recursive = TRUE))))
})

test_that('only changed or newly indexed files are downloaded again', {
  f <- .remote_cache_fixture(); f$request(names(f$files)); f$calls <- character()
  f$files[['s/kf/a.zip']] <- charToRaw('new alpha')
  f$files[['s/kf/c.zip']] <- charToRaw('gamma')
  x <- f$request(names(f$files))
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 's/kf/c.zip'))
  expect_identical(x, unname(f$files))
})

test_that('missing and corrupt raw cache entries are downloaded and verified', {
  f <- .remote_cache_fixture(); f$request(names(f$files))
  paths <- list.files(f$root, full.names = TRUE, recursive = TRUE)
  unlink(paths[basename(paths) == 'a.zip'])
  writeBin(charToRaw('broken'), paths[basename(paths) == 'b.zip'])
  f$calls <- character(); f$request(names(f$files))
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 's/kf/b.zip'))
})

test_that('unavailable or invalid current index never falls back to cached bytes', {
  f <- .remote_cache_fixture(); f$request('s/kf/a.zip'); f$calls <- character()
  f$offline <- TRUE
  expect_error(f$request('s/kf/a.zip'), 'index unavailable')
  expect_identical(f$calls, 'index.md5'); expect_null(.remote_raw_state$context)
  f$offline <- FALSE; f$bad_index <- TRUE
  expect_error(f$request('s/kf/a.zip'), 'malformed or empty index')
  expect_null(.remote_raw_state$context)
  f$bad_index <- FALSE
  expect_identical(f$request('s/kf/a.zip')[[1]], charToRaw('alpha'))
})

test_that('bad new downloads never enter the raw cache', {
  f <- .remote_cache_fixture(); f$bad_file <- TRUE
  expect_error(f$request('s/kf/a.zip'), 'checksum does not match')
  expect_length(list.files(f$root, recursive = TRUE), 0L)
  f$bad_file <- FALSE
  expect_error(f$fetch('s/kf/a.zip', expected_bytes = 999L), 'incomplete download')
  expect_length(list.files(f$root, recursive = TRUE), 0L)
  expect_error(f$request('s/kf/absent.zip'), 'not listed')
})

test_that('duplicate, unsafe and malformed index keys fail closed', {
  f <- .remote_cache_fixture()
  transport <- function(url, destfile, ...) {
    writeLines(rep(paste(strrep('a', 32), './s/kf/a.zip'), 2), destfile); 0L
  }
  expect_error(.download_file('https://resultat.val.se/resultatfiler/test/s/kf/a.zip',
    tempfile(), .download = transport), 'invalid file keys')
  expect_error(.remote_raw_url('https://resultat.val.se/resultatfiler/test/../a.zip'), 'Unsafe')
})

test_that('standalone raw reads also refresh the index and isolate collections', {
  f <- .remote_cache_fixture()
  f$fetch('s/kf/a.zip'); f$fetch('s/kf/a.zip')
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 'index.md5'))
  expect_null(.remote_raw_url('https://other.test/resultatfiler/test/s/kf/a.zip'))
  expect_null(.remote_raw_url('https://resultat.val.se/resultatfiler/test/s/kf/a.zip?x=1'))
})

test_that('unindexed candidacy sources are always fetched fresh', {
  calls <- 0L
  fake <- function(url, destfile, ...) { calls <<- calls + 1L; writeBin(charToRaw('csv'), destfile); 0L }
  for (i in 1:2) {
    file <- tempfile()
    .download_file('https://data.val.se/filer/val2026/parti/kandidaturer.csv', file, .download = fake)
    unlink(file)
  }
  expect_identical(calls, 2L)
})

test_that('public requests share only a current index and clean up on failure', {
  f <- .remote_cache_fixture()
  local_mocked_bindings(
    .kandidatur_kalla = function(...) list(path = 's/kf/a.zip', samling = 'test',
      base_url = 'https://resultat.val.se/resultatfiler/test'),
    read_kandidaturer_2026 = function(file) {
      tmp <- tempfile(); on.exit(unlink(tmp))
      .download_file(file, tmp)
      fixture_kandidaturer()
    },
    .download_file_uncached = function(url, destfile, ...) {
      f$transport(url, destfile); invisible(destfile)
    }
  )
  first <- candidacies(2026, 'KF', source = 'remote')
  expect_identical(candidacies(2026, 'KF', source = 'remote'), first)
  expect_identical(f$calls, c('index.md5', 's/kf/a.zip', 'index.md5'))
  f$offline <- TRUE
  expect_error(candidacies(2026, 'KF', source = 'remote'), 'index unavailable')
  expect_null(.remote_raw_state$context)
})

test_that('the internal remote cache is never a local archive or an auto local fallback', {
  f <- .remote_cache_fixture(); f$request('s/kf/a.zip')
  local_mocked_bindings(.download_file_uncached = function(...) stop('Unexpected network'))
  root <- tempfile(); dir.create(file.path(root, '2026', 'test'), recursive = TRUE)
  withr::defer(unlink(root, recursive = TRUE))
  writeLines('user file', file.path(root, '2026', 'test', 'owned.txt'))
  expect_identical(readLines(.resolve_val_file('owned.txt', 2026L, 'test',
    source = 'local', data_dir = root)), 'user file')
  expect_error(.resolve_val_file('s/kf/a.zip', 2026L, 'test', source = 'local', data_dir = root),
    'Filen finns inte')
  expect_identical(.resolve_val_file('s/kf/a.zip', 2026L, 'test', source = 'auto', data_dir = root),
    'https://resultat.val.se/resultatfiler/test/s/kf/a.zip')
})
test_that('index byte constraints and tabs preserve the existing downloader contract', {
  f <- .remote_cache_fixture()
  tabbed <- function(url, destfile, ...) {
    writeLines(paste(f$hash(charToRaw('alpha')), './s/kf/a.zip', sep = '\t'), destfile)
    0L
  }
  dest <- tempfile(); withr::defer(unlink(dest))
  expect_error(.download_file('https://resultat.val.se/resultatfiler/test/index.md5', dest,
    expected_bytes = 1L, .download = tabbed), 'index size')
  expect_false(file.exists(dest))
  expect_silent(.download_file('https://resultat.val.se/resultatfiler/test/index.md5', dest,
    .download = tabbed))
})

test_that('a failed changed download preserves the previous verified cache generation', {
  f <- .remote_cache_fixture(); f$request('s/kf/a.zip')
  old <- list.files(f$root, recursive = TRUE, full.names = TRUE)
  old_md5 <- unname(tools::md5sum(old))
  f$files[['s/kf/a.zip']] <- charToRaw('changed alpha'); f$bad_file <- TRUE
  expect_error(f$request('s/kf/a.zip'), 'checksum does not match')
  expect_identical(unname(tools::md5sum(old)), old_md5)
  expect_identical(list.files(f$root, recursive = TRUE, full.names = TRUE), old)
})
