# swelections

`swelections` is an R package for Swedish election results, candidates and mandate
histories. It brings together and harmonises data from two main official sources.
The Swedish Election Authority is responsible for planning and coordinating the
implementation of elections. Statistics Sweden (SCB) is responsible for official
election statistics. The package draws on data from both sources, making election information
easier to find and use, including historical results drawn from preserved
material whose original files or web locations have changed or disappeared.
Coverage and available detail vary by election and function.

## Coverage

Version 0.4.1 covers parliamentary, regional and municipal elections from
2002 to 2026; European Parliament elections from 2004 to 2024; the 2003 euro
referendum; and five re-elections. Mandate histories are available for 2014–2018,
2018–2022 and, through current official sources, 2022–2026. Availability varies
by function, geographic level and counting stage; see
[Coverage](https://richardohrvall.github.io/swelections/articles/coverage.html).

## Installation

Install the current package release, v0.4.1, from GitHub.
`nanoparquet` is needed to read canonical data.

```r
install.packages(c("remotes", "nanoparquet"))
remotes::install_github("richardohrvall/swelections", ref = "v0.4.1")
```

The version tag also makes the installation reproducible. For the development
version, use `ref = "main"` instead.

## Quick start

```r
library(swelections)

results(year = 2022, election = "parliamentary", level = "national")
```

English and Swedish interfaces are available. The package returns election
results, seat allocations, candidacies, candidate summaries, preference votes,
elected candidates, substitute relationships and mandate histories.

The default `source = "auto"` is recommended for most users. It chooses approved
canonical data first, otherwise a supported current Swedish Election Authority
source; it never selects your local raw files.
See [Get started](https://richardohrvall.github.io/swelections/articles/swelections.html)
for examples and [Accessing the data](https://richardohrvall.github.io/swelections/articles/accessing-data.html)
for source choices and use outside R.

## Documentation

The [package website](https://richardohrvall.github.io/swelections/) provides
[Reference](https://richardohrvall.github.io/swelections/reference/index.html),
[Coverage](https://richardohrvall.github.io/swelections/articles/coverage.html) and
[Sources & methodology](https://richardohrvall.github.io/swelections/articles/sources-methodology.html).
To report a problem or contribute, use the
[issue tracker](https://github.com/richardohrvall/swelections/issues) or read
[CONTRIBUTING.md](CONTRIBUTING.md).

## Citation

If you use swelections in research, cite the package and the version used.
For v0.4.1:

> Öhrvall, R. (2026). *swelections: Swedish Election Data*
> (R package version 0.4.1). [GitHub release](https://github.com/richardohrvall/swelections/releases/tag/v0.4.1).

Use `citation("swelections")` for citation information.

Code license: MIT.
