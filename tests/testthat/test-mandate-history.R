mh_fixture <- function() {
  a <- tibble::tibble(election_code = "KF", electoral_area_code = "0114",
    constituency = "", party_code = "0001", party_abbreviation = "M", seats = 3L)
  e <- a[c(1L, 1L), setdiff(names(a), "seats")]
  e$seat_number <- c(1L, 3L); e$candidate_number <- c("101", "104")
  e$name <- c("A", "D")
  row <- function(id, seat, start, end, name = id) tibble::tibble(
    election_code = "KF", electoral_area_code = "0114", constituency = "",
    party_code = "0001", party_abbreviation = "M", seat_number = as.integer(seat),
    candidate_number = id, name = name, start_date = as.Date(start),
    end_date = as.Date(end), successor_number = NA_character_,
    event_date = as.Date("2018-09-09"), election_kind = "ordinary",
    source_file = "fixture", source_md5 = "fixture-md5",
    source_as_of = as.Date("2022-10-31"), source_row = 1L, source_kind = "history")
  h <- dplyr::bind_rows(row("101", 1, NA, "2020-01-01"),
    row("102", 1, "2020-01-01", "2021-01-01"),
    row("103", 1, "2021-01-01", NA), row("104", 3, "2018-09-09", "2019-01-01"))
  u <- dplyr::bind_rows(row("103", 1, "2021-01-01", NA),
    row(NA_character_, 2, NA, NA), row(NA_character_, 3, "2019-01-01", NA))
  v <- a[1, setdiff(names(a), "seats")]; v$vacancy_count <- 2L
  list(a = a, e = e, h = h, u = u, v = v)
}

mh_fixture_build <- function(z = mh_fixture())
  .mh_build(2018, z$a, z$e, z$h, z$u, NULL, z$v)

test_that("one allocated chair supports multiple successive holders", {
  x <- mh_fixture_build()
  expect_equal(nrow(x), 6L)
  expect_equal(length(unique(x$chair_id)), 3L)
  for (day in c("2018-09-09", "2020-01-01", "2021-01-01")) {
    at <- .mh_at(x, as.Date(day))
    expect_equal(nrow(at), 3L)
    expect_false(anyDuplicated(at$chair_id) > 0L)
  }
  at <- .mh_at(x, as.Date("2020-01-01"))
  expect_equal(at$candidate_number[at$seat_number == 1], "102")
  expect_false("101" %in% at$candidate_number)
  expect_equal(x$start_date_basis[x$candidate_number %in% "101"], "original_elected_match")
  expect_true(is.na(x$reported_start_date[x$candidate_number %in% "101"]))
})

test_that("initial and later vacancies share the allocated chair population", {
  x <- mh_fixture_build()
  initial <- x[x$seat_number == 2, ]
  expect_equal(initial$status, "vacant")
  expect_equal(initial$start_date, as.Date("2018-09-09"))
  expect_equal(initial$start_date_basis, "original_unfilled_allocation")
  later <- x[x$seat_number == 3 & x$status == "vacant", ]
  expect_equal(later$start_date, as.Date("2019-01-01"))
  expect_equal(later$start_date_basis, "reported")
  expect_equal(sum(.mh_at(x, as.Date("2018-09-09"))$status == "vacant"), 1L)
  expect_equal(sum(.mh_at(x, as.Date("2019-01-01"))$status == "vacant"), 2L)
  z <- mh_fixture(); z$u <- z$u[z$u$seat_number != 2, ]
  expect_equal(mh_fixture_build(z)$status[mh_fixture_build(z)$seat_number == 2], "vacant")
})

test_that("unproven starts, overlapping chains and missing occupied chairs fail", {
  z <- mh_fixture(); z$h$start_date[2] <- as.Date(NA)
  expect_error(mh_fixture_build(z), "Unresolved membership start")
  z <- mh_fixture(); z$h$start_date[2] <- as.Date("2019-12-31")
  expect_error(mh_fixture_build(z), "Gap or overlap")
  z <- mh_fixture(); z$h <- z$h[z$h$seat_number != 1, ]; z$u <- z$u[z$u$seat_number != 1, ]
  expect_error(mh_fixture_build(z), "Original occupied chair missing")
  z <- mh_fixture(); z$v$vacancy_count <- 1L
  expect_error(mh_fixture_build(z), "vacancy control", ignore.case = TRUE)
})

test_that("standard/full and English/Swedish are projections of identical data", {
  x <- mh_fixture_build()
  en <- .mh_present(x, "en", "full"); sv <- .mh_present(x, "sv", "full")
  expect_identical(en, .values_en(stats::setNames(sv, names(en))))
  standard <- .mh_present(x, "en", "standard")
  expect_identical(standard, en[names(standard)])
  expect_s3_class(en$start_date, "Date")
  expect_type(en$seat_number, "integer")
  expect_type(en$candidate_number, "character")
})

test_that("dated queries use the same boundaries and enforce source coverage", {
  x <- .mh_present(mh_fixture_build(), "en", "full")
  local_mocked_bindings(.mh_history = function(...) x)
  en <- members_at("2020-01-01", year = 2018)
  sv <- ledamoter_vid("2020-01-01", ar = 2018)
  expect_identical(en, .values_en(stats::setNames(sv, names(en))))
  vac <- vacant_seats_at("2020-01-01", year = 2018)
  expect_equal(nrow(en) + nrow(vac), 3L)
  expect_equal(en$candidate_number, "102")
  expect_error(members_at("2023-01-01", year = 2018), "outside verified")
  expect_error(members_at("invalid"), "Invalid mandate-history date")
})

test_that("CR-only exports retain the final candidate and source hashes", {
  f <- tempfile(fileext = ".csv"); on.exit(unlink(f))
  writeBin(charToRaw(paste0(';Valmyndigheten 2026-10-15 03:51:49\r',
    'Valtyp;Kandidatnummer ledamot\rKF;54149\rKF;54150')), f)
  x <- .mh_read(f, 2022)
  expect_equal(nrow(x), 2L)
  expect_equal(tail(x$`Kandidatnummer ledamot`, 1), "54150")
  expect_identical(attr(x, "source_md5"), unname(tools::md5sum(f)))
})

test_that("wrong-period sources and unnamed overrides are rejected", {
  x <- tibble::tibble(Valtyp = "KF", Valtillfälle = "Val_20260913")
  expect_error(.mh_normalise(x, "history", 2022), "different or unknown election period")
  expect_error(.mh_files(2018, tempdir(), list("unlabelled.csv")), "named list")
})

test_that("Ragunda retains original-election start and separate correction metadata", {
  z <- mh_fixture(); z$a$electoral_area_code <- "2303"
  z$a$party_abbreviation <- "SD"; z$a$party_code <- "0110"
  for (k in c("e", "h", "u", "v")) {
    z[[k]]$electoral_area_code <- "2303"; z[[k]]$party_abbreviation <- "SD"
    z[[k]]$party_code <- "0110"
  }
  z$h <- z$h[z$h$seat_number != 3, ]
  z$h <- dplyr::bind_rows(z$h, z$u[z$u$seat_number == 3, ])
  i <- z$h$seat_number == 3; z$h$candidate_number[i] <- "534885"
  z$h$name[i] <- "Pehr Haggkvist"; z$h$start_date[i] <- as.Date("2018-09-09")
  z$u[z$u$seat_number == 3, ] <- z$h[i, ]
  z$e <- z$e[z$e$seat_number != 3, ]; z$v$vacancy_count <- 1L
  x <- mh_fixture_build(z); r <- x[x$candidate_number %in% "534885", ]
  expect_equal(r$start_date, as.Date("2018-09-09"))
  expect_equal(r$correction_date, as.Date("2018-12-12"))
  expect_equal(r$start_date_basis, "reported")
  expect_false(any(x$seat_number == 3 & x$status == "vacant"))
  z$h$start_date[z$h$candidate_number %in% "534885"] <- as.Date(NA)
  x <- mh_fixture_build(z); r <- x[x$candidate_number %in% "534885", ]
  expect_equal(r$start_date_basis, "corrected_original_elected")
  expect_true(is.na(r$reported_start_date))
})

test_that("2014 separate exports reconstruct multi-step chains and terminal vacancies", {
  z <- mh_fixture()
  for (k in c("h", "u")) z[[k]]$event_date <- as.Date("2014-09-14")
  z$h$start_date[z$h$candidate_number == "101"] <- as.Date("2014-09-14")
  z$h$start_date[z$h$candidate_number == "104"] <- as.Date("2014-09-14")
  dep <- z$h[!is.na(z$h$end_date), ]
  dep$successor_number <- c("102", "103", NA_character_)
  dep$seat_number <- NA_integer_
  current <- z$u[z$u$seat_number != 3, ]
  x <- .mh_build(2014, z$a, z$e, NULL, current, dep, z$v)
  at <- .mh_at(x, as.Date("2021-01-01"))
  expect_equal(nrow(at), 3L)
  expect_equal(at$candidate_number[at$status == "occupied"], "103")
  expect_equal(sum(at$status == "vacant"), 2L)
  expect_equal(x$start_date_basis[x$status == "vacant" & x$seat_number == 3],
    "departure_without_successor_verified_vacancy_control")
  dep$end_date[dep$candidate_number == "104"] <- as.Date("2014-09-14")
  x <- .mh_build(2014, z$a, z$e, NULL, current, dep, z$v)
  expect_equal(sum(.mh_at(x, as.Date("2014-09-14"))$status == "vacant"), 2L)
})
