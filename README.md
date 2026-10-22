# swelections

`swelections` is an R package for analysis-ready Swedish election data from
Valmyndigheten (the Swedish Election Authority). It reads official results and
candidate sources, preserves their important distinctions, and presents them
as tables for analysis. The public API is English-first, with a fully supported
Swedish interface.

> [!IMPORTANT]
> The package is under active development. It supports selected 2002, 2006, 2010, 2014, 2018, 2022 and
> 2026 election data, but availability depends on the election, counting stage,
> geographic level and published source files. Public interfaces may change.

## Swedish interface

The Swedish functions remain fully supported. They use Swedish arguments and
return Swedish column names by default. English functions return English
column names by default; `names = "sv"` requests Swedish column names for an
English call. Set `options(swelections.names = "sv")` to make that the default
for English calls. An explicit `names` argument always overrides the option.
Language selection also localizes technical categories. Booleans remain logical;
party, geographic and personal names retain their source spelling.

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

## European Parliament elections

All seven functions support the 2004, 2009, 2014, 2019 and 2024 elections with explicit
`election = "european"` (or `"E"`). The default EU year is 2024; select 2004, 2009, 2014 or 2019
explicitly or use `year = "all"`. Swedish calls use `val = "E"`.

EU 2004 final results preserve 27 named parties and the reported aggregate of
943 valid handwritten votes for other parties. All 1,480,960 reported preference
votes reconcile with the final decision, including 14,450 for SD; erroneous SD
zeros in the current SCB table are not used. Candidate keys identify ballot/list
positions, not physical persons. A complete preliminary Wednesday snapshot has
not been recovered. See [2004 coverage and provenance](development/COMPLETENESS_EU_2004.md).

EU 2019 final and complete preliminary results use the preserved official XML.
Raw builds require the pinned preserved archive. Approved canonical data are
the normal source after publication; preserved raw inputs remain an explicit
local alternative. See the source documentation for required inputs.
Final results include the separately reported handwritten-party votes.
Preliminary results retain ten named parties plus aggregated other parties.
The fixed 2019 allocation is 20 seats, before the subsequent Brexit change.
Public 2019 candidate names are `NA`, consistent with the official redacted file.
Candidate numbers identify official election records, not verified physical
persons across elections. Wednesday units have no independent electorate or
turnout. See [2019 coverage and provenance](development/COMPLETENESS_EU_2019.md).

```r
results(2019, election = "european", count = "final", level = "municipality",
        source = "local", data_dir = "my_archive")
preference_votes(2019, election = "european", level = "district",
                 source = "local", data_dir = "my_archive")
```


For EU 2014, final results use the preserved original XML with geographic names.
A complete preliminary Wednesday snapshot has not been recovered; election-night
data are not exposed as a full preliminary result. The final handwritten-vote
category retains all 5,618 valid votes. Source detail identifies 5,608 by their
reported designation; ten votes in Vårdsberg, Linköping, remain unidentified.
Full results include `source_votes_without_party_designation` as disclosure
metadata, never as additional votes. Candidate names are missing in public output,
and the historical source does not provide modern consent/validity attributes.


## Getting started

The English `election` values are `"parliamentary"`, `"regional"` and
`"municipal"`. The corresponding official Valmyndigheten codes `"RD"`, `"RF"`
and `"KF"` are accepted too. The output column `election_code` contains these
official codes. `election_kind` describes the kind of election, such as an
ordinary election, re-election or extra election. Technical categories use
English values in canonical/English output and Swedish equivalents in Swedish output.

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
elections where the official source provides them. Parliamentary county
results are available for some historical years; support is year-specific.
Unsupported combinations give an error.

The public tables default to `detail = "standard"`, a compact set of
analysis variables with geographic code/name pairs for the observation level.
Use `detail = "full"` for all harmonised fields available from the selected
source, including source-specific reporting metadata. This changes columns,
not observations or values. The Swedish functions use the same distinction
through `detaljniva = "standard"` or `"full"`; `names` independently selects
the column language. Historical canonical data can expose only fields stored
in that release.

The public tables default to `detail = "standard"`, a compact set of
analysis variables with geographic code/name pairs for the observation level.
Use `detail = "full"` for all harmonised fields available from the selected
source, including source-specific reporting metadata. This changes columns,
not observations or values. The Swedish functions use the same distinction
through `detaljniva = "standard"` or `"full"`; `names` independently selects
the column language. Historical canonical data can expose only fields stored
in that release.

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
For municipal elections, `level = "municipality"` combines non-overlapping
preference-vote areas within each municipality; regional elections similarly
support `level = "region"`. Shares are recalculated from the combined counts.
Qualification by preference votes is not carried to these broader views when
it is determined in a smaller preference-vote area.
For municipal elections, `level = "municipality"` combines non-overlapping
preference-vote areas within each municipality; regional elections similarly
support `level = "region"`. Shares are recalculated from the combined counts.
Qualification by preference votes is not carried to these broader views when
it is determined in a smaller preference-vote area.

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

2002 final RD/RF/KF data use preserved official election-result XML. The ordinary
Orsa election on 15 September 2002 is kept separate from the 16 March 2003 rerun;
ordinary national and geographic totals use the original Orsa result. Archived
election-night sources are retained as provenance. Full preliminary collection
results remain unrecovered, so election-night data are not exposed as a complete
`preliminary` result. This is a source/recovery limitation, not evidence that
preliminary results were never produced.

For 2002, candidate keys identify source observations, not verified persons
across lists or elections. Public names are missing; unavailable attributes and
unattributable preference votes are not fabricated. A complete ballot-candidacy
population has not been recovered, so `candidacies()` does not support 2002.
Broader person-linked preference-vote aggregation and inferred zeros are
unsupported. Final RD party-vote results have complete voting-district and
municipality coverage. They include verified SCB/SND district data for
Halmstad, Laholm and Kungsbacka, whose municipal XML exports remain unrecovered.
Their party totals reconcile with Valmyndigheten. Official historical web pages
supply the three municipalities' reported district preference observations;
HTML rank is not ballot position or person identity. XML-specific metadata and
undisclosed ballot positions remain unavailable. Some RF/KF list preference views fail
the source's own aggregate checks;
the official RD four-party supplement corrects national and disclosed constituency
values. Nine undisclosed constituency cells remain `NA`; county totals require
complete disclosure. Positive municipality/district counts are not allocated;
explicit constituency zeros correct contradicted existing lower-level counts.
See [supplement provenance and coverage](development/SUPPLEMENT_2002.md).
See [2002 implementation and limitations](development/IMPLEMENTATION_2002.md)
and [validation](development/VALIDATION_2002.md).

2006 final RD/RF/KF data use preserved local XML, ballot and supplementary
candidate sources, included in the reviewed canonical release candidate. No complete
preliminary collection source is available. For 2006, `candidate_number` is a
package-generated **source-observation/candidacy key**, not a person identifier.
Equal names are not merged across lists, source structures or elections.
Observed preference votes and available names are retained; unsupported
attributes and person-wide totals remain missing. Preference votes are exposed
at their original area/district levels; cross-area person aggregation is not
supported. `include_zeros` creates no unsupported synthetic 2006 observations.
Allocated seats remain distinct from filled positions: the 14 KF positions
labelled `Kunde ej utses` are unfilled seats, never elected candidates. See
[2006 implementation and limitations](development/IMPLEMENTATION_2006.md).

The seven data families support 2022 and 2026 where their official source
files contain the requested information. Final 2018 data are also supported
through separate XML and candidacy readers. Published 2018 candidate names
are unavailable in the public output, even if a local historical snapshot
contains names. Raw result-dependent 2018 calls require a local copy of
the official XML archive. The official 2018 candidacy source can be read
remotely.

2014 support uses preserved local ballot and final XML sources. Its full
preliminary result combines ordinary election-night districts with an official
preliminary collection-district presentation snapshot; final collection votes
are not substituted. Candidate data include identifiers documented in the final
results even when absent from the ballot files. Public candidate names and
unsupported historical attributes are missing. Later membership snapshots are
excluded. The 2014 canonical product is registered for automatic use in the release
candidate; publication remains a separate step.

2010 final results use preserved election-result XML and ballot candidacies,
with identified result-only candidates retained. Names and unsupported attributes
remain missing. Preliminary results combine ordinary election-night districts
with a separately preserved preliminary collection-district reporting snapshot.
Unreported districts and blank category fields remain missing; final collection
votes are never substituted. The reviewed canonical product is included in the release candidate.

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

- `source = "auto"` prioritizes approved canonical coverage for the requested
  election family, event, year and view. Otherwise it uses a supported remote
  source, never user-saved local raw files. If neither is available, it errors
  and points to an explicit `source = "local"` request. The release candidate
  activates the twelve reviewed products; EU 2009 excludes automatic preference
  votes, RKL 2002 excludes candidacies, and referendum 2003 supports results only.
  The new GitHub assets remain unpublished until the release is approved.
- `source = "local"` requires local raw files and never accesses the network.
- `source = "remote"` selects Valmyndigheten where that raw route is supported.
- `source = "canonical"` explicitly reads published or configured canonical
  data. It never falls back to raw files. See `?data_sources`.

To force your own archive when canonical is available, use `source = "local"`
with `data_dir`; specifying `data_dir` alone does not override canonical.

Set `data_dir` per call or configure a local archive for the R session with
`options(swelections.data_dir = "my_archive")`. `update` and `archive`
control working-copy updates and dated raw-file snapshots where applicable.
Raw source files are kept outside the package repository. `data_dir` applies
to official raw files, not canonical Parquet assets.

Approved canonical requests resolve a product-specific GitHub Release manifest
and download only the required Parquet assets. This includes the corrected 2018
generation with Ragunda and value/storage contract 1/1, replacing the old 2018
default without overwriting its historical release. To test an unpublished build,
configure its manifest:

```r
options(swelections.canonical_manifest = "path/to/manifest.json")
results(year = 2018, election = "parliamentary", level = "national",
        source = "canonical")
```

The first distribution contains **190 Parquet assets and 12 product manifests**
under `data-v0.4.0`: RKL 2002/2006/2010/2014/2018/2022, referendum 2003, and
EU 2004/2009/2014/2019/2024. RKL 2002 excludes candidacies; EU 2009 excludes
all six preference-vote bases; the referendum has results only. The two historical
mandate-history assets are shared by their three query functions. Assets are published in data-v0.4.0. See
[the release review](development/releases/v0.4.0.md).

Canonical assets are read next to the manifest by default and cached with
checksum verification. `nanoparquet` is needed only for Parquet use. The
explicit canonical request does not fall back to raw files when an asset is
missing. `update` and `archive` keep their official raw-data meaning; they do
not select canonical data automatically.

Indexed remote result ZIPs use a persistent user cache. Every public request
checks a fresh official `index.md5` and verifies cached bytes before reuse; changed
or corrupt files are downloaded again. Failure to verify the index is an error,
not permission to use stale data. The unindexed 2026 candidacy CSV is still fetched
fresh. Only raw files persist, not parsed tables or API results. See `?data_sources`
and [remote-cache validation](development/REMOTE_RAW_CACHE.md).

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

## Development and provenance

See [CONTRIBUTING.md](CONTRIBUTING.md) for contributor setup, the
[development index](development/README.md) for reproducible validation and source
methodology, and [source references](references/README.md) for official specifications.
## Final 2003 referendum results

`results(year = 2003, election = "referendum")` reads the final euro referendum
(short code `"F"`; Swedish: `valresultat(ar = 2003, val = "F")`).
The rows describe voting options through `voting_option_code` and
`voting_option_name`, without party columns. Ja, Nej and Blank are valid ballot
categories; invalid ballots are reported separately. Geographic totals repeat
on option rows and must not be summed across options.

```r
results(2003, election = "referendum", level = "municipality")
results(2003, election = "referendum", level = "district")
```

Final coverage includes all 290 municipalities, 5,976 ordinary districts and
396 Wednesday units, plus national, county and parliamentary-constituency
aggregates. `municipal_constituency` returns the 185 actual constituencies in
79 divided municipalities; technical `00` containers in 211 undivided
municipalities do not create public constituencies. District output identifies
ordinary/Wednesday units with `district_type`. Wednesday units have no own
eligible-voter denominator or turnout.

Valmyndigheten XML is authoritative; SND and SCB tables validate the results.
The unavailable historical SCB publication does not block the verified final
counts. A full preliminary Wednesday snapshot has not been recovered, so
`count = "preliminary"` errors rather than returning election-night data.
For local sources, `data_dir` is the preserved source directory containing
`final.xml`, `final-municipal/` and, when available, `source-manifest.json`.
The reviewed canonical product is registered for `auto` in the release candidate.
Until publication, an explicit canonical manifest can be used for validation.
User raw archives always require `source = "local"`; `auto` never selects them.
See [the 2003 inventory](development/SOURCE_INVENTORY_2003.md) and
[validation documentation](development/VALIDATION_2003.md).

For the 2003 referendum, standard/full also include
`eligible_swedish_citizens_in_sweden`, `eligible_swedish_citizens_abroad` and
`eligible_foreign_citizens`. These are verified SCB counts for counties and the
country whose sum matches Valmyndigheten's `eligible_voters`. They remain typed
missing at finer levels; no county counts are distributed to districts.
Blank is a **valid** 2003 voting option and is excluded from `invalid_votes`.

## European Parliament election 2024

All seven functions support `year = 2024, election = "european"` (official
code `"E"`); Swedish functions use `ar = 2024, val = "E"`.
`results()` provides national, county, municipality, municipal-constituency and
district results. EU seats and election qualification apply nationally.
`preference_votes()` also supports those geographic aggregates and the national
`"preference_vote_area"`. Qualification is missing in subnational views.
The preliminary JSON includes collection districts; final data preserve the
original elected/substitute relations. Blank ballots are invalid, and collection
units have no independent electorate or turnout.

Use `source = "local"` for the preserved EU archive through `data_dir` (the
`eu/2024` directory or its parent), or explicitly select the supported remote
source. Reviewed canonical data are registered for automatic use in the release
candidate, pending publication; explicit manifests remain available for validation.
The approved later candidate snapshot defines the final population. The earlier
valid consent-only record for candidate 1203 is retained as historical provenance,
not silently added to that population; its disappearance has no identified effect
on party votes, reported preference votes, seats or original elected relations.
See [the EU source inventory](development/SOURCE_INVENTORY_EU_2024.md).

### European Parliament 2009

EU 2009 has approved canonical coverage for six functions; `preference_votes()`
requires explicit `source = "local"` and the preserved original sources. Its six
preference-vote bases are deliberately excluded from the first distribution.
A private full prototype cannot enable automatic preference-vote access. Archived ballot XML
provides 500 named list positions; these are not 500 verified distinct persons.
Generated `candidate_number` keys identify ballot positions or independent
small-party preference source columns. Unlinked candidate enrichment stays missing.
The reconciled official preference-vote total is **1,876,785**: the main-party
component of 1,874,130 plus the official small-party aggregate of 2,655.
`preference_votes()` returns source-reported candidate observations, not an
official all-party total row. Its national candidate rows sum to **1,876,795**,
because the small-party candidate columns total 2,665, an unresolved ten-vote
source inconsistency. That row sum must not be described as the official total.
The small-party source reports inconsistent national/county/municipal preference
sums, which are preserved without inferred corrections. Complete preliminary
Wednesday results are not verified; election-night results are not substituted.
See the [2009 completeness statement](development/COMPLETENESS_EU_2009.md).
## Re-elections

Ordinary elections remain the default for year ranges. Re-elections are separate
polling events within the original mandate period; they do not overwrite the
original result.

```r
election_events(election_kind = "re_election")
results(year = 2011, election = "municipal",
        election_kind = "re_election", source = "local", data_dir = archive)
seats(year = 2011, election = "municipal",
      election_kind = "re_election", source = "local", data_dir = archive)
orebro <- seats(year = 2010, election = "municipal", after_re_election = TRUE,
                source = "local", data_dir = archive)
orebro <- orebro[orebro$municipality_code == "1880", ]
sum(orebro$seats) # 65: 48 from 2010 + 17 from 2011; election_year remains 2010
seats(from = 2002, to = 2022, election = "municipal",
      after_re_election = TRUE, source = "local", data_dir = archive)
```

Örebro's 2011 event contains Nordöstra and 17 seats only. The adjusted 2010
composition contains 48 unaffected seats from 2010 plus the 17 from 2011.
Composition rows retain the source event, component year and geography; sum
`seats` by party and municipality across those components. This is an electoral
allocation, not a history of who held office. No combined vote/turnout view is
provided. Orsa 2003, Västra Götaland 2011, Båstad 2015 and Falun 2019 are also
registered. `election_kind = "all"` returns distinct events, never an adjusted
series. Re-election readers currently require preserved local final sources;
there is no published re-election canonical release.

See [the implementation and source requirements](development/IMPLEMENTATION_OMVAL.md)
for archive layout, provenance, supported levels and historical source gaps.

### Mandate-period membership

`mandate_history()` / `mandathistorik()` describe holder and vacancy intervals
for the 2014 and 2018 periods through approved canonical data. The 2022 period
uses current remote member/history files; it is not a canonical history product.
Explicit local sources remain supported. No user archive is needed for the
normal canonical/remote routes.
`members_at()` / `ledamoter_vid()` and `vacant_seats_at()` /
`tomma_stolar_vid()` query the same population of allocated mandates on a date.
The three functions filter shared intervals, rather than separate duplicated
member/vacancy datasets. Requests beyond verified source-date coverage fail
explicitly; a remote source is not assumed to describe future dates.
Dates follow Valmyndigheten's electoral-history convention; temporary substitute
attendance is not included. See [source requirements, semantics and validation](development/MANDATE_HISTORY.md).
