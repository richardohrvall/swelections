read_kandidaturer_2022 <- function(file) {
  if (grepl("^https?://", file)) {
    tmp <- tempfile(fileext = ".zip")
    on.exit(unlink(tmp), add = TRUE)
    .download_file(file, tmp)
    file <- tmp
  }
  if (!"kandidaturer.csv" %in% utils::unzip(file, list = TRUE)$Name) {
    stop("2022 \u00e5rs kandidatur-ZIP saknar kandidaturer.csv.", call. = FALSE)
  }
  extracted <- tempfile()
  dir.create(extracted)
  on.exit(unlink(extracted, recursive = TRUE), add = TRUE)
  csv_file <- utils::unzip(file, "kandidaturer.csv", exdir = extracted)
  readr::read_delim(
    csv_file,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    na = "",
    trim_ws = FALSE,
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    janitor::clean_names() |>
    parse_kandidaturer_2026(
      ar = 2022L,
      namnvalsedlar_kompletta = .namnvalsedlar_kompletta(csv_file, 2022L)
    )
}
