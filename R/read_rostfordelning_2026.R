read_rostfordelning_zip_2026 <- function(zip_file) {

  source <- zip_file

  tryCatch(
    {
      is_url <- grepl("^https?://", zip_file)

      if (is_url) {
        tmp_zip <- tempfile(fileext = ".zip")
        .download_file(zip_file, tmp_zip)
        zip_file <- tmp_zip
        on.exit(unlink(tmp_zip), add = TRUE)
      }

      files <- utils::unzip(zip_file, list = TRUE)

      rost_file <- files$Name |>
        stringr::str_subset("rostfordelning.*\\.json$")

      if (length(rost_file) != 1) {
        stop(
          "F\u00f6rv\u00e4ntade mig exakt en r\u00f6stf\u00f6rdelningsfil i ZIP-filen, men hittade ",
          length(rost_file),
          ".",
          call. = FALSE
        )
      }

      tmp_dir <- tempfile()
      dir.create(tmp_dir)
      on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

      utils::unzip(
        zip_file,
        files = rost_file,
        exdir = tmp_dir
      )

      raw <- jsonlite::fromJSON(
        file.path(tmp_dir, rost_file),
        simplifyVector = FALSE
      )

      parse_rostfordelning_2026(raw)
    },
    error = \(e) {
      stop(
        "Fel vid l\u00e4sning av:\n",
        source,
        "\n\n",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
}
