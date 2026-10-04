# Opt-in: VALRESULTAT_2022_INTEGRATION_DIR points to unchanged official ZIPs.
test_that("2022 mandate results match eight official preliminary/final ZIPs", {
  root <- Sys.getenv("VALRESULTAT_2022_INTEGRATION_DIR", "")
  skip_if(!nzchar(root), "External 2022 ZIPs not configured")
  files <- c(
    "p/rd/Val_20220911_preliminar_00_RD.zip" = "078e4911d8706c9bdcd8f24c85de7200",
    "s/rd/Val_20220911_slutlig_00_RD.zip" = "a0f843ffb9a305e7bc84ecea5e57023a",
    "p/rf/Val_20220911_preliminar_01_RF.zip" = "94cb94e46dd295cbdf6ee85d834d8453",
    "s/rf/Val_20220911_slutlig_01_RF.zip" = "88178411c6c5f31514bed9416eb7beaf",
    "p/kf/Val_20220911_preliminar_0180_KF.zip" = "714ddd9bf194d0ee024c3c6213d9f317",
    "s/kf/Val_20220911_slutlig_0180_KF.zip" = "1534f4310d6a068260efedca6d26d001",
    "p/kf/Val_20220911_preliminar_0980_KF.zip" = "97a93c0f20fd8d08b4db2bfaed424b67",
    "s/kf/Val_20220911_slutlig_0980_KF.zip" = "d396bbcd319540acf134279e46b0775a"
  )
  expect_true(all(file.exists(file.path(root, names(files)))))
  expect_identical(unname(tools::md5sum(file.path(root, names(files)))),
                   unname(files))
  local_mocked_bindings(
    .read_resultatindex = function(...) tibble::tibble(path = names(files)),
    .resultat_file = function(ar, path, ...) file.path(root, path)
  )
  contract <- readLines(test_path("fixtures", "mandat-public-columns.txt"),
                        encoding = "UTF-8")
  for (val in c("RD", "RF", "KF")) for (rakning in c("preliminar", "slutlig")) {
    huvud <- switch(val, RD = "riket", RF = "region", KF = "kommun")
    krets <- switch(val, RD = "riksdagsvalkrets", RF = "regionvalkrets",
                    KF = "kommunvalkrets")
    for (niva in c(huvud, krets)) {
      out <- mandat(detaljniva = "full", ar = 2022, val = val, rakning = rakning,
                    niva = niva, progress = FALSE)
      expect_identical(names(out), contract, info = paste(val, rakning, niva))
      expect_identical(unique(out$valar), 2022L)
      expect_false(anyDuplicated(out[c("valar", "valtyp", "rakningstillfalle",
                                      "geografiniva", "valomradeskod",
                                      "valkretskod", "partikod")]) > 0L)
      expect_true(all(is.na(out$antal_mandat) | out$antal_mandat >= 0L))
      expect_true(all(is.na(out$antal_mandat_fg)))
      if (rakning == "preliminar") expect_true(all(is.na(out$antal_tomma_stolar)))
      if (rakning == "slutlig") {
        expect_true(all(is.na(out$antal_tomma_stolar) |
                        out$antal_tomma_stolar >= 0L))
      }
      for (group in split(out, paste(out$valomradeskod, out$valkretskod))) {
        expect_identical(unique(group$totalt_antal_mandat),
                         as.integer(sum(group$antal_mandat)))
      }
    }
  }
  expect_equal(nrow(mandat(detaljniva = "full", ar = 2022, val = "KF", niva = "kommunvalkrets",
                            progress = FALSE)), 45L)
  for (rakning in c("preliminar", "slutlig")) {
    prefix <- if (rakning == "slutlig") "s" else "p"
    for (code in c("0180", "0980")) {
      path <- names(files)[grepl(paste0("^", prefix, "/kf/.*_", code,
                                        "_KF\\.zip$"), names(files))]
      raw <- .read_valresultat_raw(file.path(root, path), "M", "KF",
                                   rakning, ar = 2022L)
      expected <- if (code == "0180") 6L else 0L
      expect_length(raw$valomrade$valkretsLista, expected)
      actual <- parse_mandat_2026(raw)
      expect_equal(length(unique(actual$valkretskod[!is.na(actual$valkretskod)])),
                   expected)
    }
  }
})
