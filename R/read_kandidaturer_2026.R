read_kandidaturer_2026 <- function(file) {
  if (grepl("^https?://", file)) {
    tmp <- tempfile(fileext = ".csv")
    on.exit(unlink(tmp), add = TRUE)
    .download_file(file, tmp)
    file <- tmp
  }
  readr::read_delim(
    file,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    na = "",
    trim_ws = FALSE,
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    janitor::clean_names() |>
    parse_kandidaturer_2026(
      namnvalsedlar_kompletta = .namnvalsedlar_kompletta(file, 2026L)
    )
}
