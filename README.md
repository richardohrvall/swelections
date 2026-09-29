# swelections

`swelections` is an R package for analysis-ready Swedish election data from
Valmyndigheten (the Swedish Election Authority). It reads official results and
candidate sources, preserves their important distinctions, and presents them
as tables for analysis. The public API is English-first, with a fully supported
Swedish interface.

> [!IMPORTANT]
> The package is under active development. It supports selected 2018, 2022 and
> 2026 election data, but availability depends on the election, counting stage,
> geographic level and published source files. Public interfaces may change.

## Swedish interface

The Swedish functions remain fully supported. They use Swedish arguments and
return Swedish column names by default. English functions return English
column names by default; `names = "sv"` requests Swedish column names for an
English call. Set `options(swelections.names = "sv")` to make that the default
for English calls. An explicit `names` argument always overrides the option.
Column-name selection does not translate data values.

| English | Swedish |
| --- | --- |
| `results()` | `valresultat()` |
| `seats()` | `mandat()` |
| `candidacies()` | `kandidaturer()` |
| `candidates()` | `kandidater()` |
| `elected()` | `valda()` |
| `substitutes()` | `ersattare()` |
| `preference_votes()` | `personroster()` |

```r
# English API
results(year = 2026, election = "municipal", level = "municipality")

# Swedish API: the same election and geographic level
valresultat(ar = 2026, val = "KF", niva = "kommun")

results(2026, election = "municipal", names = "sv")
options(swelections.names = "sv")
# Restore English columns for the examples below.
options(swelections.names = NULL)
```

## Installation

Install the development version from [GitHub](https://github.com/richardohrvall/swelections)
and load it:

```r
install.packages("pak")
pak::pak("richardohrvall/swelections")
library(swelections)
```

`remotes::install_github("richardohrvall/swelections")` is another option if
you use `remotes`.

## Getting started

The English `election` values are `"parliamentary"`, `"regional"` and
`"municipal"`. The corresponding official Valmyndigheten codes `"RD"`, `"RF"`
and `"KF"` are accepted too. The output column `election_code` contains these
official codes. `election_kind` describes the kind of election, such as an
ordinary election, re-election or extra election; its source values are not
translated.

```r
# Official party results at each election's main geographic level
results(election = "parliamentary")   # national
results(election = "regional")        # region
results(election = "municipal")       # municipality

# Choose a geographic level and counting stage
results(election = "parliamentary", level = "parliamentary_constituency")
results(election = "parliamentary", count = "preliminary", level = "district")

# Other analysis tables
seats(election = "parliamentary")
candidacies(election = "municipal")
candidates(election = "municipal")
elected(election = "parliamentary")
substitutes(election = "parliamentary")
preference_votes(election = "parliamentary", level = "preference_vote_area")
```

`results()` returns official results at the requested level, rather than
reconstructing an available official total from voting districts. A call
selects one election, one counting stage (`"preliminary"` or `"final"`) and one
geographic level. If `level` is omitted, the main level is national for
parliamentary elections, region for regional elections and municipality for
municipal elections. Other supported level values include `"district"`,
`"municipal_constituency"` and `"regional_constituency"`; availability varies
by election and year. For example, county results are supported for municipal
elections where the official source provides them, but parliamentary county
results are not supported. Regional county results are not yet activated.
Unsupported combinations give an error.

At district level, `counted` distinguishes reported districts from districts
whose vote distribution is not yet available. Unreported districts remain in
the public table with `NA` in current result fields; an explicit reported zero
remains `0`. Public vote shares and turnout use proportions on the 0–1 scale.
Share changes are absolute differences between proportions: `0.025` means an
increase of 2.5 percentage points. District `turnout` follows the official
polling-station measure, which does not assign late advance or postal votes
back to an ordinary district.

## Candidates, elected members and preference votes

`candidacies()` retains detailed candidate and ballot-list records, including
invalid candidacies. `candidates()` has one row per candidate, election code
and party, built from valid candidacies. A candidate standing in several
constituencies has no single candidate-level constituency code or name;
`constituencies_count` records how many there are.

`open_list` describes the party's candidate-list status. `on_name_ballot`
describes whether a candidacy appeared on a name ballot sent to print. These
are different from appearing on a result list created during vote counting.
A negative `on_name_ballot` value is `FALSE` only when the actual candidate-file
snapshot is verified as complete for that question. An older or unknown
snapshot may instead yield `NA`. Result lists such as `90000` do not by
themselves identify printed name ballots.

`elected()` and `substitutes()` use the official **final** elected-member and
substitute relations. They do not infer elected members from preliminary
results. An absent or unfinished final relation gives an error. In `elected()`,
constituency fields identify where the person was elected.

`preference_votes()` defaults to one candidate–party–preference-vote-area row.
Use `level = "district"` for district results and `by_list = TRUE` to retain
the result-list dimension. District and list views are sparse by default:
they contain observed candidate results, including explicit source zeros.
`include_zeros = TRUE` adds only combinations whose zero is verified from
complete source information. A missing row is not automatically zero, and
`NA` means the available source cannot establish the value. Preference-vote
shares are proportions on the 0–1 scale.

```r
# Preference votes for candidates on observed result lists by district
preference_votes(
  election = "parliamentary",
  level = "district",
  by_list = TRUE
) |>
  dplyr::select(candidate_number, list_number, district_code,
                preference_votes)
```

Completed district views with `include_zeros = TRUE` can be large. For final
parliamentary results in 2026, the completed district view has about 3.84
million rows without list detail and 4.18 million with it.

## Years and source coverage

The seven data families support 2022 and 2026 where their official source
files contain the requested information. Final 2018 data are also supported
through separate XML and candidacy readers. Published 2018 candidate names
are unavailable in the public output, even if a local historical snapshot
contains names. Result-dependent 2018 calls currently require a local copy of
the official XML archive. The official 2018 candidacy source can be read
remotely.

For supported combinations, exact year vectors, `year = "all"`, and inclusive
`from`/`to` ranges return years stacked in long format with integer
`election_year`. Every selected year must support the requested data and level;
a missing required source stops the call.

```r
results(year = c(2022, 2026), election = "parliamentary", level = "national")
seats(from = 2022, to = 2026, election = "municipal", level = "municipality")
candidates(year = c(2022, 2026), election = "parliamentary")
```

For 2022, `results()` supports preliminary and final official district,
constituency and election-area results where available: parliamentary
`"district"`, `"parliamentary_constituency"`, `"national"`; regional
`"district"`, `"regional_constituency"`, `"region"`; and municipal
`"district"`, `"municipal_constituency"` (where divided), `"municipality"`.
The 2022 result sources lack most previous-election comparisons, which
therefore remain `NA`. Final candidate and mandate fields also remain `NA`
where the official source cannot establish them. `seats()` reads the official
2022 parliamentary national and constituency allocations, regional region
and constituency allocations, and municipal municipality and divided-
constituency allocations when present. Historical seat comparisons are `NA`.

## Data access

The 2026 default is Valmyndigheten's live `val2026` result collection.
Rehearsal files can be selected explicitly for development with
`options(swelections.resultatsamling_2026 = "genrep2026")`.

All main functions accept `source` and `data_dir`:

- `source = "auto"` prefers the required official raw files in the configured
  local archive. If they are unavailable, it uses a published canonical
  release only when that election and release are explicitly approved for
  automatic use; otherwise it uses the official remote source. The 2022 and
  2026 elections stay on the raw-data route until separately approved.
- `source = "local"` requires local files and never accesses the network.
- `source = "remote"` selects the remote source.
- `source = "canonical"` explicitly reads the versioned `swelections` Parquet
  collection, currently for 2018 only. It is separate from locally stored
  official raw files.

Set `data_dir` per call or configure a local archive for the R session with
`options(swelections.data_dir = "C:/path/to/valdata")`. `update` and `archive`
control working-copy updates and dated raw-file snapshots where applicable.
Raw source files are kept outside the package repository. `data_dir` applies
to official raw files, not canonical Parquet assets.

For 2018, an explicit canonical request resolves the versioned GitHub Release
manifest and downloads only the required Parquet assets. To use a local build
instead, configure its manifest:

```r
options(swelections.canonical_manifest = "path/to/manifest.json")
results(year = 2018, election = "parliamentary", level = "national",
        source = "canonical")
```

Canonical assets are read next to the manifest by default and cached with
checksum verification. `nanoparquet` is needed only for Parquet use. The
explicit canonical request does not fall back to raw files when an asset is
missing. `update` and `archive` keep their official raw-data meaning; they do
not select canonical data automatically.

## Development status

Coverage depends on the structures present in the requested official source
files. Seat allocations and preference votes require their respective result
structures; `elected()` and `substitutes()` require official final relations.
The package does not infer final elected members or substitutes from
preliminary results. Source-data availability may change as counting
progresses.

Bug reports and suggestions are welcome in the
[GitHub issue tracker](https://github.com/richardohrvall/swelections/issues).

## License

MIT
