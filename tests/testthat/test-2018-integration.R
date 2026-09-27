test_that("official 2018 XML, party register and candidacies agree", {
  root <- Sys.getenv("VALRESULTAT_TEST_2018_DATA_DIR", unset = "")
  skip_if(!nzchar(root), "Read-only 2018 integration needs VALRESULTAT_TEST_2018_DATA_DIR")
  zip <- file.path(root, "2018", "valresultat", "slutresultat.zip")
  expect_length(.xml2018_members(zip, "RD", "kommun"), 290L)
  expect_length(.xml2018_members(zip, "RF", "kommun"), 289L)
  expect_length(.xml2018_members(zip, "KF", "kommun"), 290L)
  for (val in c("RD", "RF", "KF")) {
    niva <- switch(val, RD = "riket", RF = "region", KF = "kommun")
    votes <- valresultat(ar = 2018, val = val, niva = niva,
                        source = "local", data_dir = root, progress = FALSE)
    expect_identical(names(votes), .valresultat_public_columns_2026(niva))
    .valresultat_check_key(votes, niva)
    expect_true(all(votes$valar == 2018L))
    expect_true(all(votes$rakningstillfalle == "slutlig"))
    expect_true(all(votes$antal_roster >= 0L))
    expect_true(all(votes$andel_roster >= 0 & votes$andel_roster <= 1))
    expect_identical(sum(votes$antal_roster), switch(val,
      RD = 6476725L, RF = 6439523L, KF = 6532135L))
    seats <- mandat(ar = 2018, val = val, niva = niva,
                    source = "local", data_dir = root, progress = FALSE)
    expect_identical(anyDuplicated(seats[c("valtyp", "geografiniva",
                                           "valomradeskod", "valkretskod", "partikod")]), 0L)
    expect_true(all(seats$antal_mandat >= 0L))
  }
  candidates <- kandidaturer(ar = 2018, source = "local", data_dir = root)
  expect_identical(nrow(candidates), 184197L)
  expect_true(all(is.na(candidates$namn)))
  expect_identical(anyDuplicated(candidates[c("valtyp", "valomradeskod",
    "valkretskod", "partikod", "listnummer", "ordning", "kandidatnummer")]), 0L)
})
