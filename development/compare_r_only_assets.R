# Rscript development/compare_r_only_assets.R REFERENCE_DIR NEW_DIR REPORT
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
reference <- jsonlite::read_json(file.path(args[[1]], "manifest.json"), simplifyVector = TRUE)
actual <- jsonlite::read_json(file.path(args[[2]], "manifest.json"), simplifyVector = TRUE)
stopifnot(identical(reference$assets$file, actual$assets$file), nrow(actual$assets) == 24L)
checks <- vector("list", nrow(actual$assets))
sha256 <- function(path) digest::digest(file = path, algo = "sha256")
for (i in seq_len(nrow(actual$assets))) {
  file <- actual$assets$file[[i]]
  a <- file.path(args[[1]], file); b <- file.path(args[[2]], file)
  stopifnot(identical(sha256(a), reference$assets$sha256[[i]]),
    identical(sha256(b), actual$assets$sha256[[i]]))
  old <- nanoparquet::read_parquet(a); new <- nanoparquet::read_parquet(b)
  stopifnot(identical(old, new), identical(names(old), names(new)))
  checks[[i]] <- list(file = file, rows = nrow(new), columns = ncol(new),
    byte_identical = identical(reference$assets$sha256[[i]], actual$assets$sha256[[i]]))
  cat("PASS canonical reference", file, "byte-identical:", checks[[i]]$byte_identical, "\n")
}
jsonlite::write_json(list(checks = checks, identical_data = TRUE,
  reference_manifest_sha256 = sha256(file.path(args[[1]], "manifest.json")),
  actual_manifest_sha256 = sha256(file.path(args[[2]], "manifest.json")),
  build_tree_dirty = actual$build_tree_dirty), args[[3]], pretty = TRUE, auto_unbox = TRUE)
