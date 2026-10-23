# swelections

`swelections` provides analysis-ready Swedish election data in R. It brings
together information otherwise scattered across source files, election years,
geographic levels and formats, and provides consistent tables for analysis.

The package draws on data from the Swedish Election Authority and
Statistics Sweden. English and Swedish interfaces are available.

## Installation

Install v0.4.1 from GitHub. `nanoparquet` is needed to read canonical data.

```r
install.packages(c("remotes", "nanoparquet"))
remotes::install_github("richardohrvall/swelections", ref = "v0.4.1")
```

## Quick start

Get historical parliamentary results using the default source selection:

```r
library(swelections)

results(year = 2022, election = "parliamentary", level = "national")

# Results by voting district
results(year = 2022, election = "parliamentary", level = "district")
```

For 2026, `auto` uses the supported current Swedish Election Authority source:

```r
results(year = 2026, election = "parliamentary", level = "national")
```

Discover re-elections, then request Falun's 2019 result:

```r
election_events(election_kind = "re_election")

results(
  year = 2019,
  election = "municipal",
  election_kind = "re_election"
)
```

The `election` argument also accepts the official codes `"RD"`, `"RF"`, `"KF"`, `"E"`
(European Parliament) and `"F"` (referendum). Use `detail = "full"` for additional
source detail, or `names = "sv"` for Swedish columns and technical categories.

## Functions

| Function | Swedish interface | Returns |
| --- | --- | --- |
| `results()` | `valresultat()` | Votes and election totals at the requested geographic level. |
| `seats()` | `mandat()` | Electoral mandate allocations by party. |
| `candidacies()` | `kandidaturer()` | Detailed candidacy and ballot-list records. |
| `candidates()` | `kandidater()` | Candidate summaries within an election and party. |
| `elected()` | `valda()` | Candidates elected in the final result. |
| `substitutes()` | `ersattare()` | Final elected-member–substitute relationships. |
| `preference_votes()` | `personroster()` | Reported candidate preference-vote observations. |
| `mandate_history()` | `mandathistorik()` | Holder and vacancy intervals for allocated mandates. |
| `members_at()` | `ledamoter_vid()` | Verified mandate holders on a specified date. |
| `vacant_seats_at()` | `tomma_stolar_vid()` | Verified vacant mandates on a specified date. |
| `election_events()` | `valtillfallen()` | Election-event metadata, including re-elections and their scope. |

Candidate identifiers describe the records supported by each source; they are
not necessarily identifiers for the same physical person across elections.
Use `election_events()` or `valtillfallen()` to discover available election
events without downloading results. Discovery is optional when requesting data.
See each function's help page for arguments and output definitions.

## Data and sources

Depending on the election and function, data are available as validated canonical
tables or can be read directly from supported Swedish Election Authority sources.

The `source` argument controls how data are obtained.

- `source = "auto"` (default) chooses approved canonical coverage for the requested
  function and election event, otherwise a supported remote source. It **never
  selects your local raw files**. If neither source is supported, the call errors.
- `source = "canonical"` explicitly selects canonical data, without raw fallback.
- `source = "remote"` explicitly reads supported current files from the Swedish
  Election Authority, even when canonical data exist.
- `source = "local"` explicitly reads your own compatible saved raw archive,
  selected with `data_dir`.

See `?data_sources` for supported source options and their requirements.

## Coverage in v0.4.1

| Election or period | Coverage |
| --- | --- |
| Parliamentary (RD), regional (RF) and municipal (KF) elections | 2002, 2006, 2010, 2014, 2018 and 2022 through canonical data; 2026 through remote sources. |
| European Parliament elections | 2004, 2009, 2014, 2019 and 2024. |
| Referendum | Final 2003 euro referendum results. |
| Re-elections | Orsa 2003, Västra Götaland and Örebro 2011, Båstad 2015 and Falun 2019. Canonical `results()` and `seats()` are available for these events. |
| Mandate-period history | Canonical 2014–2018 and 2018–2022; 2022–2026 uses remote sources, subject to verified source-date coverage. |

The histories include the Båstad 2015 and Falun 2019 re-elections within their
original mandate periods. Dated queries require verified holder continuity.

Coverage varies by function, geographic level and counting stage. In particular,
2002 candidacies are not supported, and EU 2009 preference votes require explicit
`source = "local"` with compatible raw material. Candidate-related functions are
not yet enabled for re-elections.

A re-election is an election event where an earlier election is rerun. It remains
within the original mandate period, rather than starting a new one. Ordinary
elections remain the default for year ranges.
`seats(..., after_re_election = TRUE)` returns the effective mandate composition
after a re-election while retaining the original election year.

## Documentation and development

Start with the function help pages for arguments and coverage, such as `?results`
and `?mandate_history`. Further information on sources and coverage is available
in the [package documentation](development/README.md).

Development takes place on [GitHub](https://github.com/richardohrvall/swelections).
See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute, or use the
[issue tracker](https://github.com/richardohrvall/swelections/issues) to report problems.

License: MIT.
