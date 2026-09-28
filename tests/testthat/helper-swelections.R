swelections_test_env <- function(name) {
  Sys.getenv(paste0("SWELECTIONS_TEST_", name),
             unset = Sys.getenv(paste0("VALRESULTAT_TEST_", name), unset = ""))
}
