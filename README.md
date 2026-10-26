# swelections

`swelections` is an R package for Swedish election results, candidates and mandate
histories. It brings together and harmonises data from two main official sources.
The Swedish Election Authority is responsible for planning and coordinating the
implementation of elections. Statistics Sweden (SCB) is responsible for official
election statistics. The package draws on data from both sources, making election information
easier to find and use, including historical results drawn from preserved
material whose original files or web locations have changed or disappeared.
Coverage and available detail vary by election and function.

**Development status**

`swelections` is under active development. The API and data structures may change as the package is expanded and refined.

## Coverage

The package covers Swedish electoral events from 2002 onwards: elections to
the Riksdag, regional and municipal councils and the European Parliament;
the 2003 national referendum on the euro; and five re-elections. Depending on
the event and function, data include results, seats, candidate and preference-vote
data, and mandate-period information. Geographic views range from national to
voting-district level, including counties, regions, municipalities and electoral
constituencies where applicable.

Mandate histories cover 2014–2018 and 2018–2022, with 2022–2026 available through
current official sources. Availability varies by year, function, geographic
level and counting stage; see
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

## Functions

| Use | English interface | Swedish interface |
| --- | --- | --- |
| Election results | `results()` | `valresultat()` |
| Seat allocations | `seats()` | `mandat()` |
| Candidacies and candidates | `candidacies()`, `candidates()` | `kandidaturer()`, `kandidater()` |
| Preference votes | `preference_votes()` | `personroster()` |
| Elected candidates and substitutes | `elected()`, `substitutes()` | `valda()`, `ersattare()` |
| Mandate history and changes | `mandate_history()`, `members_at()`, `vacant_seats_at()` | `mandathistorik()`, `ledamoter_vid()`, `tomma_stolar_vid()` |
| Election events | `election_events()` | `valtillfallen()` |

For the five re-elections, `results()` and `seats()` provide event results and
allocations; `election_events()` lists the events. Supported mandate histories
also describe the Båstad and Falun re-election transitions.

English and Swedish interfaces are available. The seven election-data functions
and three mandate-period functions accept `names = "sv"` for Swedish column
names and technical categories. For Swedish event metadata, use `valtillfallen()`.
Proper names and literal source identifiers retain their source spelling.

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
