# Deterministic HTTP-policy checks; no network requests or archived-source writes.
options(swelections.source_tools_only = TRUE)
source("development/preserve_preliminary_2010_conservative.R")
response <- function(status, content = charToRaw("ok")) list(status_code = status,
  content = content, headers = charToRaw("HTTP/1.1 200 OK\r\n\r\n"), url = "https://historik.val.se/prelresultat/x")
run <- function(replies) {
  calls <- 0L; delays <- numeric()
  result <- tryCatch(preliminary2010_request("fixture", fetch = function(url) {
    calls <<- calls + 1L; value <- replies[[calls]]
    if (inherits(value, "error")) stop(value)
    value
  }, sleep = function(x) delays <<- c(delays, x), clock = function() "fixed"), error = identity)
  list(result = result, calls = calls, delays = delays)
}
testthat::test_that("successful, transient, permanent and empty responses are handled", {
  x <- run(list(response(200L)))
  testthat::expect_equal(x$calls, 1L)
  testthat::expect_identical(x$result$retrieved_at_utc, "fixed")
  x <- run(list(response(503L), response(200L)))
  testthat::expect_equal(x$calls, 2L)
  x <- run(list(simpleError("connection failed"), response(200L)))
  testthat::expect_equal(x$calls, 2L)
  x <- run(list(response(404L)))
  testthat::expect_equal(x$calls, 1L)
  testthat::expect_match(conditionMessage(x$result), "404")
  x <- run(rep(list(response(200L, raw())), 3))
  testthat::expect_equal(x$calls, 3L)
  testthat::expect_match(conditionMessage(x$result), "Empty response")
  x <- run(list(response(429L), response(200L)))
  testthat::expect_equal(x$calls, 2L)
  testthat::expect_true(120 %in% x$delays)
})
testthat::test_that("blank collection rows remain valid and final redirects are distinguishable", {
  page <- charToRaw(paste0('<table class="sorteringsbar_tabell"><tbody><tr>',
    paste(rep("<td></td>", 8), collapse = ""), "</tr></tbody></table>"))
  testthat::expect_true(preliminary2010_valid(page, list(role = "collection_district", election = "R")))
  testthat::expect_false(preliminary2010_valid(raw(), list(role = "collection_district", election = "R")))
  x <- response(200L, page)
  testthat::expect_true(preliminary2010_accept(x, list(role = "collection_district", election = "R")))
  x$url <- "https://historik.val.se/slutresultat/x"
  testthat::expect_false(preliminary2010_accept(x, list(role = "collection_district", election = "R")))
})
