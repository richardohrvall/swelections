# Run from the repository root after installing the current package and pkgdown.
# Only public documentation inputs enter the staging tree; no raw archive is used.
build_documentation <- function() {
  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  stopifnot(read.dcf(file.path(root, "DESCRIPTION"))[1, "Package"] == "swelections")
  destination <- file.path(root, "docs")
  if (dir.exists(destination)) {
    resolved <- normalizePath(destination, winslash = "/", mustWork = TRUE)
    if (!identical(dirname(resolved), root) || basename(resolved) != "docs")
      stop("Refusing to clean a site destination outside this repository.")
    unlink(resolved, recursive = TRUE)
  }
  stage <- tempfile("swelections-pkgdown-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  files <- c("DESCRIPTION", "NAMESPACE", "README.md", "NEWS.md", "LICENSE",
             "LICENSE.md", "CONTRIBUTING.md", "CITATION.cff", "_pkgdown.yml",
             "pkgdown/index.md")
  files <- files[file.exists(file.path(root, files))]
  for (directory in c("R", "man", "inst", "vignettes/articles")) {
    if (dir.exists(file.path(root, directory)))
      files <- c(files, paste0(directory, "/", list.files(file.path(root, directory),
                  recursive = TRUE, all.files = TRUE, no.. = TRUE)))
  }
  for (file in files) {
    target <- file.path(stage, file)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(file.path(root, file), target)) stop("Cannot stage ", file)
  }
  stopifnot(!file.exists(file.path(stage, "AGENTS.md")),
            !dir.exists(file.path(stage, ".local-data")))
  # Generate standard favicons only in the temporary site source tree.
  if (file.exists(file.path(stage, "man", "figures", "logo.png")))
    pkgdown::build_favicons(stage)
  # Keep generated app-icon URLs relative to this GitHub Pages project site.
  webmanifest <- file.path(stage, "pkgdown", "favicon", "site.webmanifest")
  if (file.exists(webmanifest)) {
    metadata <- jsonlite::read_json(webmanifest)
    metadata$icons <- lapply(metadata$icons, function(icon) {
      icon$src <- basename(icon$src)
      icon
    })
    jsonlite::write_json(metadata, webmanifest, auto_unbox = TRUE, pretty = TRUE)
  }
  pkgdown::build_site(pkg = stage, override = list(destination = destination),
                     examples = FALSE, new_process = FALSE, install = FALSE,
                     preview = FALSE)
  invisible(destination)
}
build_documentation()
