# Additional public API ordering/subset checks, using preserved raw XML only.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(2L, 3L))
pkgload::load_all(".", quiet = TRUE)
options(swelections.canonical_manifest = file.path(args[[2]], "manifest.json"),
  swelections.canonical_assets_dir = args[[2]],
  swelections.canonical_cache_dir = file.path(dirname(args[[2]]), "2014-validation-cache"))
sources <- swelections:::.sources_2014("local", args[[1]], FALSE, FALSE)
testthat::local_mocked_bindings(.sources_2014 = function(...) sources,
  .package = "swelections")
original <- swelections:::.xml2014_bundle
cache <- new.env(parent = emptyenv())
testthat::local_mocked_bindings(.xml2014_bundle = function(sources, val, progress) {
  key <- paste(val, collapse = "_")
  if (!exists(key, cache, inherits = FALSE))
    assign(key, original(sources, val, progress), cache)
  get(key, cache, inherits = FALSE)
}, .package = "swelections")
functions <- if (length(args) == 3L) args[[3]] else
  c("candidacies", "candidates", "elected", "substitutes", "preference_votes")
for (values in list(c("RF", "RD"), c("KF", "RD", "RF"))) {
  for (fun in functions) {
    arguments <- list(year = 2014L, election = values, detail = "full", names = "en")
    if (fun != "candidacies") arguments$progress <- FALSE
    f <- getExportedValue("swelections", fun)
    raw <- do.call(f, c(arguments, list(source = "local", data_dir = args[[1]])))
    canonical <- do.call(f, c(arguments, list(source = "canonical")))
    if (!identical(raw, canonical)) stop(fun, " ", paste(values, collapse = "/"),
      ": ", paste(all.equal(raw, canonical), collapse = "; "))
    cat("PASS mixed", fun, paste(values, collapse = "/"), "\n"); flush.console()
  }
}
