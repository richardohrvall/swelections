read_underordnad_summering_zip_2026 <- function(zip_file) {

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

      summering_file <- files$Name |>
        stringr::str_subset(
          "(^|/)[^/]+_(preliminar|slutlig)_summering(?:_[0-9]{2})?_(RD|RF)\\.json$"
        )

      if (length(summering_file) != 1) {
        stop(
          "F\u00f6rv\u00e4ntade mig exakt en underordnad summeringsfil f\u00f6r RD/RF ",
          "i ZIP-filen, men hittade ",
          length(summering_file),
          ".",
          call. = FALSE
        )
      }

      tmp_dir <- tempfile()
      dir.create(tmp_dir)
      on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

      utils::unzip(
        zip_file,
        files = summering_file,
        exdir = tmp_dir
      )

      raw <- jsonlite::fromJSON(
        file.path(tmp_dir, summering_file),
        simplifyVector = FALSE
      )

      parse_underordnad_summering_2026(raw)
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
