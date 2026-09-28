test_that("complete final RD 2026 has no artificial person-vote NA", {
  data_dir <- swelections_test_env("RD_DATA_DIR")
  skip_if(!nzchar(data_dir),
          "Read-only RD integration test requires SWELECTIONS_TEST_RD_DATA_DIR")
  old_option <- getOption("swelections.resultatsamling_2026")
  options(swelections.resultatsamling_2026 = "val2026")
  on.exit(options(swelections.resultatsamling_2026 = old_option), add = TRUE)

  area <- personroster(val = "RD", source = "local", data_dir = data_dir,
                       progress = FALSE)
  sparse <- personroster(val = "RD", niva = "personvalsomrade",
    per_lista = TRUE, source = "local", data_dir = data_dir, progress = FALSE)
  full <- personroster(val = "RD", niva = "personvalsomrade",
    per_lista = TRUE, komplettera_nollor = TRUE,
    source = "local", data_dir = data_dir, progress = FALSE)
  candidates <- kandidater(val = "RD", source = "local", data_dir = data_dir,
                           progress = FALSE)

  expect_equal(nrow(area), 31820L)
  expect_false(anyNA(area$antal_personroster))
  expect_equal(nrow(sparse), 14129L)
  expect_false(anyNA(sparse$antal_personroster))
  expect_equal(nrow(full), 30952L)
  expect_false(anyNA(full$antal_personroster))
  added <- dplyr::anti_join(full, sparse, by = c("valtyp", "valomradeskod",
    "personvalsomradeskod", "partikod", "listnummer", "kandidatnummer"))
  expect_equal(nrow(added), 16823L)
  expect_true(all(added$antal_personroster == 0L))
  expect_equal(sum(added$antal_listroster == 0L), 2072L)
  expect_true(all(is.na(added$andel_personroster_lista[
    added$antal_listroster == 0L])))
  expect_equal(nrow(candidates), 6326L)
  expect_false(anyNA(candidates$antal_personroster_totalt))

  file <- .resultat_file_2026("s/rd/Val_2026_slutlig_00_RD.zip",
    source = "local", data_dir = data_dir)
  rost <- read_raw_json_zip_2026(file, "rostfordelning")
  mandat <- read_raw_json_zip_2026(file, "mandatfordelning")
  omraden <- .personvalsomraden_mandat_2026(mandat)
  underlag <- .personrostomradesunderlag_2026(rost, "00", omraden)
  officiella <- .personval_officiella_2026(omraden)
  gammal_mask <- area |>
    dplyr::left_join(dplyr::select(underlag$status,
      personvalsomradeskod, partikod, personroster_available),
      by = dplyr::join_by(personvalsomradeskod, partikod),
      relationship = "many-to-one") |>
    dplyr::left_join(dplyr::mutate(officiella, officiell = TRUE) |>
      dplyr::select(personvalsomradeskod, partikod, kandidatnummer, officiell),
      by = dplyr::join_by(personvalsomradeskod, partikod, kandidatnummer),
      relationship = "one-to-one") |>
    dplyr::mutate(tidigare_na = !officiell %in% TRUE &
      !personroster_available %in% TRUE)
  tidigare_na <- dplyr::filter(gammal_mask, tidigare_na)
  expect_equal(nrow(tidigare_na), 16068L)
  expect_equal(sum(tidigare_na$antal_personroster > 0L), 2742L)
  expect_equal(sum(tidigare_na$antal_personroster == 0L), 13326L)
  liststatus <- sparse |>
    dplyr::left_join(dplyr::select(underlag$status,
      personvalsomradeskod, partikod, personroster_available),
      by = dplyr::join_by(personvalsomradeskod, partikod),
      relationship = "many-to-one")
  expect_equal(sum(!liststatus$personroster_available %in% TRUE), 3312L)

  tidigare_total <- gammal_mask |>
    dplyr::summarise(tidigare_na = any(tidigare_na),
                     .by = c(kandidatnummer, valtyp, partikod))
  jamforelse <- candidates |>
    dplyr::select(kandidatnummer, valtyp, partikod, antal_personroster_totalt) |>
    dplyr::left_join(tidigare_total,
      by = dplyr::join_by(kandidatnummer, valtyp, partikod),
      relationship = "one-to-one")
  expect_equal(sum(jamforelse$tidigare_na), 788L)
  expect_equal(sum(jamforelse$tidigare_na &
    jamforelse$antal_personroster_totalt > 0L), 625L)
  expect_equal(sum(jamforelse$tidigare_na &
    jamforelse$antal_personroster_totalt == 0L), 163L)
})
