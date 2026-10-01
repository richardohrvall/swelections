read_raw_json_zip_2026 <- function(
    zip_file,
    type = c(
      "rostfordelning",
      "mandatfordelning",
      "summering"
    )
) {

  type <- match.arg(type)

  is_url <- grepl("^https?://", zip_file)

  if (is_url) {
    local_zip <- tempfile(fileext = ".zip")

    on.exit(
      unlink(local_zip),
      add = TRUE
    )

    .download_file(zip_file, local_zip)
  } else {
    local_zip <- zip_file
  }

  if (!file.exists(local_zip)) {
    stop(
      "ZIP-filen finns inte: ",
      zip_file,
      call. = FALSE
    )
  }

  files <- unzip(
    local_zip,
    list = TRUE
  )$Name

  json_file <- files[
    grepl(
      paste0(type, ".*\\.json$"),
      files,
      ignore.case = TRUE
    )
  ]

  if (length(json_file) != 1) {
    stop(
      "F\u00f6rv\u00e4ntade exakt en JSON-fil av typen `",
      type,
      "`, men hittade ",
      length(json_file),
      ".",
      call. = FALSE
    )
  }

  exdir <- tempfile()
  dir.create(exdir)

  on.exit(
    unlink(exdir, recursive = TRUE),
    add = TRUE
  )

  unzip(
    local_zip,
    files = json_file,
    exdir = exdir
  )

  raw <- jsonlite::fromJSON(
    file.path(exdir, json_file),
    simplifyVector = FALSE
  )

  .normalisera_rakningsmetadata_2026(raw)
}
