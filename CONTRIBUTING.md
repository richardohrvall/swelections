# Contributing to swelections

The package, source acquisition and reproducible build/validation workflow use R.
The public English and Swedish interfaces share implementation. Contributions
should preserve source values, observation keys and documented missingness.

## Setup

Use the R version required by `DESCRIPTION`. Install package dependencies and the
R development tools needed for your task. A complete development setup includes:

```r
install.packages(c(
  "dplyr", "janitor", "jsonlite", "xml2", "purrr", "readr", "stringr", "tibble",
  "nanoparquet", "roxygen2", "testthat", "withr", "pkgload", "pkgbuild",
  "digest", "curl", "readxl", "zip"
))
```

Choose an ordinary R library or an ignored repository-local `.r-lib`. To use the
latter, set `R_LIBS_USER` before starting R, or prepend `.r-lib` to `.libPaths()`
in the R session. `development/install-dependencies.R` is an optional partial
setup helper; it does not install every dependency of the historical build tools.
No Python executable is required.

## Checks

From the repository root, using the configured R library:

```r
pkgload::load_all(".")
testthat::test_local(".", stop_on_failure = TRUE)
```

For code/documentation changes that require regenerated manuals, run
`roxygen2::roxygenise(".")` and review its diff. `development/check.R` also
regenerates documentation; it is not a read-only validation command.

Build and check a source package in an ignored output directory:

```r
dir.create(".local-data/package-check", recursive = TRUE, showWarnings = FALSE)
pkgbuild::build(".", dest_path = ".local-data/package-check", vignettes = FALSE)
```

Then run `R CMD check --no-manual --no-vignettes` on the resulting tarball and
review its complete result. Run `git diff --check` and `git diff --cached --check`.
Slow/raw-source tests are opt-in: consult their explicit environment variables
and the [development index](development/README.md). Do not enable live tests
implicitly or silently use a different source snapshot.

## Sources and reproducibility

Configure raw archives through `data_dir` or `options(swelections.data_dir = ...)`.
Keep downloaded sources, local research evidence, outputs and canonical assets
outside Git. Preserve source bytes, URLs, retrieval times, sizes and checksums.
Use new output directories rather than replacing preserved validation references.

Canonical data versions are separate from package versions. Follow the pinned
source selection and manifest procedure in [CANONICAL_DATA.md](development/CANONICAL_DATA.md).
Only published releases explicitly eligible for automatic use may be selected by
`auto`; a local canonical cache is still canonical, not a local raw archive.

Do not use mandate-period membership to redefine the fixed election result.
Document source ambiguities, historical gaps and approved scoped harmonisations;
do not force agreement between inconsistent official sources. Independent checks
use separate R parsing logic where possible. SCB material is validation evidence,
not a source for fabricating individual candidate records.

Changes to data semantics, identity rules, schemas or release publication require
explicit review. Generated Parquet assets and raw sources must not enter a code
commit. Contributor documentation and historical audit reports are excluded from
the installed R package.
