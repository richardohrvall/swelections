# valresultat

`valresultat` is an R package for downloading, parsing and analysing Swedish election data from Valmyndigheten.

The aim is to provide analysis-ready data on election results, mandates, candidates, candidacies, elected representatives and substitutes while preserving important information from the official source files.

> [!WARNING]
> `valresultat` is under active development. Development currently focuses on
> the 2026 Swedish elections, and the public API and data structures may still
> change. Testing uses deterministic fixtures, Valmyndigheten's rehearsal data
> and targeted checks against current live result files.

## Installation

Install the development version from GitHub with `pak`:

```r
install.packages("pak")
pak::pak("richardohrvall/valresultat")
```

Alternatively, using `remotes`:

```r
install.packages("remotes")
remotes::install_github("richardohrvall/valresultat")
```

Then load the package:

```r
library(valresultat)
```

## Main functions

| Function | Description |
| --- | --- |
| `valresultat()` | Party vote results at different geographic levels |
| `mandat()` | Mandate allocation by party |
| `kandidaturer()` | Detailed candidacy data across electoral areas, constituencies and lists |
| `kandidater()` | Analysis-ready candidate data |
| `personroster()` | Personal votes by candidate, party and personal-vote area |
| `valda()` | People in the official final elected-member result |
| `ersattare()` | Official final substitute relationships for elected representatives |

The main functions currently target the 2026 parliamentary (`RD`), regional
(`RF`) and municipal (`KF`) elections. `valresultat()`, `mandat()`,
`kandidaturer()`, `kandidater()`, `valda()` and `ersattare()` also support 2022 where their
official source data are available.

## Quick start

```r
library(valresultat)

# National result in the parliamentary election
valresultat(val = "RD")

# Regional election results at region level
valresultat(val = "RF")

# Municipal election results at municipality level
valresultat(val = "KF")

# Parliamentary election results by municipality
valresultat(val = "RD", niva = "kommun")

# Parliamentary election results by constituency
valresultat(val = "RD", niva = "riksdagsvalkrets")

# Mandate allocation
mandat(val = "RD")

# Candidates
kandidater(val = "RD")

# Personal votes by parliamentary constituency
personroster(val = "RD")

# Elected candidates
valda(val = "RD")

# Substitutes
ersattare(val = "RD")
```

For `valresultat()`, omitting `niva` returns the main level for the election:

- `RD` → `riket`
- `RF` → `region`
- `KF` → `kommun`

Supported geographic levels depend on the election type and on the official source data.

`valresultat()` can return several years in long format. `valar` is an integer
time variable directly after `valtillfalle`; the same result columns are
stacked by year. Specify exact years with `ar`, all supported years for the
election with `ar = "alla"`, or an inclusive range among supported years with
`fran` and/or `till`:

```r
valresultat(ar = 2026, val = "RD", niva = "riket")
valresultat(ar = c(2022, 2026), val = "RD", niva = "riket")
valresultat(ar = "alla", val = "RD", niva = "riket")
valresultat(fran = 2010, till = 2026, val = "RD", niva = "riket")

# Mandates for the same years, stacked with integer valar
mandat(ar = c(2022, 2026), val = "RD", niva = "riket")
mandat(ar = "alla", val = "RF", niva = "region")
mandat(fran = 2022, till = 2026, val = "KF", niva = "kommun")
```

Exact years retain the order supplied in `ar`; `"alla"` and ranges are
chronological. Every selected year must support the requested geographic
level. An unsupported combination or missing required source file stops the
whole call.

## Election results

`valresultat()` uses a common analysis core across geographic levels and counting
stages, while returning only the geographic columns relevant to the requested
level. Geographic identifiers appear early in the result.

For example:

```r
# Preliminary parliamentary result by voting district
valresultat(
  val = "RD",
  rakning = "preliminar",
  niva = "valdistrikt"
)

# Keep only voting districts that have reported a vote distribution
valresultat(
  val = "RD",
  rakning = "preliminar",
  niva = "valdistrikt"
) |>
  dplyr::filter(raknat)

# Final parliamentary result at national level
valresultat(
  val = "RD",
  rakning = "slutlig",
  niva = "riket"
)
```

At voting-district level, `raknat` distinguishes reported districts from valid
districts whose `rostfordelning` is still `NULL`. Unreported districts remain in
the table, with party rows from the official party universe and `NA` in current
result fields. An explicitly reported zero remains 0. Variables that are not
available are otherwise represented as typed `NA`.

The package uses official results at the requested geographic level when those
results are provided by Valmyndigheten rather than automatically reconstructing
them from lower-level data.

Public shares are proportions on the 0–1 scale. Where exact numerators and
denominators exist and their meaning has been verified, the public share is
calculated from those counts. Official source values are used otherwise.
Differences between shares use the same scale and are absolute differences,
not relative percentage changes. For example, `diff_andel_roster = 0.025`
means an increase of 2.5 percentage points.

For an ordinary reported voting district, `valdel` corresponds to
Valmyndigheten's `valdeltagandeVallokal`. It is not complete turnout among all
eligible voters attached to that district: late advance and postal votes are
reported in separate collection districts and cannot be assigned back to the
ordinary district. Collection districts therefore have `NA` in `valdel`.

In `valresultat()`, `kommunnamn` is a short analysis name looked up by
`kommunkod`, while `kommunnamn_officiellt` preserves Valmyndigheten's source
label. Candidate-related and other tables that already identify KF geography
through `valomradeskod` use the same short name directly in
`valomradesnamn`, without duplicate municipality columns.

## Candidates and candidacies

`kandidaturer()` preserves detailed source information about individual candidacies in 2022 and 2026. A person may appear several times because the same candidate can stand in several electoral areas, constituencies or lists. Exact year vectors, `ar = "alla"`, and `fran`/`till` work as in `valresultat()`; selected years are stacked in long format with integer `valar`.

`oppen_lista` describes whether the party has an open candidate list in the election area. `pa_namnvalsedel` describes whether this particular candidacy appears on a name ballot sent to print (`VALSEDELSSTATUS = S`). They are separate properties: a valid candidate need not appear on a printed name ballot. A negative ballot status is `FALSE` only for a verified complete candidate-file snapshot, identified by the CSV content hash. An older or unknown local snapshot can return `NA` for the same election year. List numbers created during vote counting do not affect `pa_namnvalsedel`.

`kandidater()` provides a more analysis-oriented candidate table for 2022 and 2026. Its observation level is candidate × election type × party. It accepts the same year selections as `kandidaturer()` and stacks years in long format. Here, `oppen_lista` is known only when all the candidate's valid candidacies agree; `pa_namnvalsedel` means the candidate appeared on **at least one** printed name ballot. This differs from `kandidaturer()`, where the field describes each candidacy. Older or unknown candidate-file snapshots can yield `NA` for a negative ballot status.

`antal_valkretsar` counts the distinct constituencies in a candidate's valid candidacies, even when several lists occur in one constituency. If a candidate stands in several constituencies, `valkretskod` and `valkretsnamn` are `NA` at candidate level; the count explains why.

`valda()` uses the official **final** elected-member relation for 2022 and 2026. It accepts exact year vectors, `ar = "alla"`, or `fran`/`till`, with 2026 as the default. Years are stacked with integer `valar` after `valtillfalle`. There is no preliminary `valda()` result: preliminary files do not identify elected people, and a missing or unfinished final source gives an error. The table omits the candidacy count `antal_valkretsar`; `valkretskod` and `valkretsnamn` instead identify where the person was elected.

`ersattare()` reads the official **final** substitute relations for RD, RF and KF in 2022 and 2026 and accepts the same year selections. One row links an elected member to a substitute at a specified order; the same substitute can appear on several rows. Its constituency fields describe the relation, and an absent or unfinished final relation gives an error. No preliminary substitute result is inferred.

```r
# Detailed candidacies
kandidaturer(val = "KF")
kandidaturer(ar = c(2022, 2026), val = "RD")

# Analysis-ready candidates
kandidater(val = "KF")
kandidater(ar = c(2022, 2026), val = "RD")

# Elected candidates
valda(val = "KF")
valda(ar = c(2022, 2026), val = "RD")

# Substitute relations
ersattare(ar = c(2022, 2026), val = "RD")
```

Candidate-result information is included when the corresponding final result data are available. For 2022, personal votes come from reconciled official area-level result lists. The total counts votes officially reported for the identified candidate: `90000` party ballots add no candidate votes, and a verified absence gives 0. An area with unverifiable result structure gives `NA`. Result-list numbers do not determine whether a candidate appeared on a printed ballot.

`personroster()` returns one row per candidate, party and actual personal-vote
area. Its `andel_personroster` is an unrounded proportion on the 0–1 scale.
`niva` selects the personal-vote area or voting district; `per_lista = TRUE`
keeps the ballot-list dimension. District and list views are sparse by default:
they contain observed candidate results, including any explicit source zeros.
A missing row must not be read as zero. Set `komplettera_nollor = TRUE` to add
candidate combinations with verified zeros from complete observed lists or
fully reconciled final area results.
The established default area view is unchanged by this option.

```r
personroster(val = "RD", niva = "valdistrikt", per_lista = TRUE) |>
  dplyr::select(kandidatnummer, listnummer, valdistriktskod, antal_personroster)
```

The sparse list view shows how a candidate's observed personal votes are
distributed across ballot lists. Completed district views can be large: final
RD 2026 gives roughly 3.84 million rows without list detail and 4.18 million
with it (about 0.9 GB). `NA` means the source material cannot establish the
vote count; absence from a sparse candidate array alone is not enough. Final
RD has been checked against live data; published final
RF/KF files were still partly counted at verification.

## Data access

`valresultat` reads public election data from Valmyndigheten. Source files can be accessed remotely or stored locally for reproducible analysis.

Normal calls use the live 2026 result collection, `val2026`. Rehearsal data
remain available for explicit testing or development with:

```r
options(valresultat.resultatsamling_2026 = "genrep2026")
```

The main source modes are:

- `source = "auto"` – use a local source file if it exists, otherwise use the remote source.
- `source = "local"` – use local files only; this mode never accesses the network.
- `source = "remote"` – use the remote source explicitly.

A local data directory can be supplied with `data_dir` or set for the R session:

```r
options(valresultat.data_dir = "C:/path/to/valdata")
```

Functions also support `update` and `archive` where relevant. Raw source files are deliberately kept outside the package repository.

## Geographic levels

Depending on election type and source availability, election results can be requested at geographic levels including:

- `valdistrikt`
- `kommun`
- `kommunvalkrets`
- `lan` (KF only)
- `region`
- `regionvalkrets`
- `riksdagsvalkrets`
- `riket`

RD/`lan` is not supported. RF/`lan` is documented in the source format but is
not activated until a final source has been verified; use `region` for RF.

## Current scope

The 2026 implementation currently includes support for:

- party vote results
- preliminary and final counting
- mandate allocation
- candidates and candidacies
- candidate-result and personal-vote information when available
- elected representatives
- substitutes
- local and remote source files
- optional local archiving of source files

Broader support for earlier elections is planned for later stages.

`valresultat(ar = 2022)` supports both `rakning = "preliminar"` and
`rakning = "slutlig"` at these official source levels:

| Election | District (D) | Constituency (M) | Election area (M) |
| --- | --- | --- | --- |
| RD | `valdistrikt` | `riksdagsvalkrets` | `riket` |
| RF | `valdistrikt` | `regionvalkrets` | `region` |
| KF | `valdistrikt` | `kommunvalkrets` where divided | `kommun` |

For example, `valresultat(ar = 2022, val = "RD", niva = "riket")` reads the
official national result. Other 2022 levels are unavailable because the
separate U/O summaries used in 2026 are absent from the 2022 result index.
The 2022 result JSON does not contain most previous-election comparisons, so
those columns are `NA`; the separate historical comparison files are not yet
integrated. `mandat(ar = 2022)` reads the official mandate nodes for RD
(`riket`, `riksdagsvalkrets`), RF (`region`, `regionvalkrets`) and KF
(`kommun`, `kommunvalkrets` where divided). It supports preliminary and final
files when mandate results are present. Historical mandate comparisons are
`NA`. In final results, `antal_tomma_stolar` is derived only where the same
fully counted node contains both party mandates and complete elected-member
data; otherwise it is `NA`. Candidate and personal-vote functions remain
2026-only.

## Status

The package should currently be regarded as experimental. Final RD 2026 paths,
including result, candidate and personal-vote structures, have been checked
against live files. Preliminary D, U and M paths for RD, RF and KF have been
checked against a time-stamped partial live snapshot. Turnout in preliminary
RF/KF superior summaries (O) has been checked against live files. Published
final RF/KF files have also been checked, but counting was still incomplete at
verification time. They did not yet contain established mandate, personal-
election, elected-member or substitute structures. Verifying those structures
once available remains an external source-data task, not a known package problem.

Bug reports and suggestions are welcome through the GitHub repository.

## License

MIT
