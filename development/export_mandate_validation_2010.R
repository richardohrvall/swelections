# Independent Excel export for validate_sources_2010.py (development only).
# These files are validation snapshots, never canonical build inputs.
files <- list.files(".local-data/rkl/2010", recursive = TRUE, full.names = TRUE)
output <- lapply(c("R", "L", "K"), function(letter) {
  file <- files[grepl(paste0("mandatfordelning_per_valkrets_", letter, "[.]xls$"), files)]
  stopifnot(length(file) == 1L)
  x <- readxl::read_excel(file, col_types = "text", .name_repair = "minimal")
  list(header = names(x), rows = unname(as.matrix(x)))
})
names(output) <- c("RD", "RF", "KF")
jsonlite::write_json(output, ".local-data/2010-mandate-excel.json", na = "null", auto_unbox = TRUE)
