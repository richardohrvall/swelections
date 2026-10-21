# Mandate-period history

Implementation and validation: 19 October 2026. No release, commit or push.
The source assessment is in [MANDATE_HISTORY_FEASIBILITY.md](MANDATE_HISTORY_FEASIBILITY.md).

## Public functions

| English | Swedish | Rows |
| --- | --- | --- |
| `mandate_history()` | `mandathistorik()` | Holder and vacancy intervals |
| `members_at()` | `ledamoter_vid()` | Occupied chairs on one date |
| `vacant_seats_at()` | `tomma_stolar_vid()` | Verified vacant chairs on one date |

Supported original election years are 2014, 2018 and 2022, for RD/RF/KF.
These functions are separate from the fixed-election `elected()`/`valda()` API.
They do not change any existing election-result, candidate or canonical table.

```r
archive <- "path/to/preserved/archive"
h <- mandate_history(year = 2018, data_dir = archive, source = "local", detail = "full")
members <- ledamoter_vid(datum = "2020-01-01", ar = 2018, data_dir = archive, source = "local")
empty <- tomma_stolar_vid(datum = "2020-01-01", ar = 2018, data_dir = archive, source = "local")
empty_in_municipality <- empty[empty$kommunkod == "1880", ]
```

`year`/`ar` selects the original ordinary election and continuing period.
With `NULL` in date queries, the latest supported ordinary election on or
before the requested date is selected. Explicit year selection is preferable
around election/transition dates: these are Valmyndigheten's electoral-history
date conventions, not a reconstruction of statutory inaugural meetings.

Column names and technical-category values follow the selected language.
Swedish wrappers default to Swedish. `detail`/`detaljniva` selects standard/full.
Standard is a projection of full, with identical rows and shared values.

## Population, keys and intervals

The population is **allocated mandates**, not the people present in a history
file. Allocation geography is RD constituency, RF constituency (or undivided
region), KF municipal constituency (or undivided municipality). Whole-area and
constituency allocations are never added together.

`chair_id` is a generated allocation/event key: original year, component event
date, election, area, constituency, party code and party chair order. It is not
an official identifier for a physical seat. `interval_id` distinguishes source
intervals on that chair. Several holders and subsequent vacancies share a chair
key. Re-elections replace the affected component; they do not create additional
active mandates or a new period. Båstad 2015 and Falun 2019 allocations are
checked against the existing independently verified event/party allocations.

Intervals are `[start_date, end_date)`: the outgoing row is excluded on the
successor's start date. Zero-length source intervals remain in history but
never appear in a snapshot. Overlapping intervals, gaps, unlinked holders,
unknown starts and failed independent vacancy counts raise errors. No permanent
`unknown` state is substituted for a reconstructable chair.

Initial vacancies are created from allocated-minus-filled chairs even without
a history/person row. Later vacancies come from explicit current vacant-chair
rows, or terminal departures without a successor verified against the separate
vacancy snapshot. The 2014 sources require forward and backward succession
links; no name matching or physical-person ID harmonisation is performed.

The implementation verifies the allocated population on the initial date,
the final coverage date, and immediately before/at each supported re-election.
The per-chair checks ensure that intervening changes do not introduce gaps or
overlaps. Occupied plus vacant chairs equals the active allocated population.

## Dates and provenance

An original elected member starts on election day under the source convention.
A blank start is filled only after matching the original result by candidate
number, party, geography and chair. The original blank is retained in full.
Start-date bases distinguish:

- `reported`;
- `original_elected_match`;
- `original_unfilled_allocation`;
- `corrected_original_elected` (if a missing original start is supplied by an
  explicitly approved election-result correction);
- `departure_without_successor_verified_vacancy_control`.

End-date bases distinguish a reported departure from a verified re-election
replacement. A source snapshot date is `coverage_end`, not an invented departure.
Queries outside coverage fail rather than extending open rows indefinitely.

**Ragunda:** candidate 534885 occupies SD chair 3 from the directly reported
`2018-09-09`. The separate `correction_date` is `2018-12-12`, reference
`Valprovningsnamnden 877-2018`. That appeal decision corrected the original
election; no artificial December vacancy is created. The county's implementing
decision date remains unverified and is not conflated with either date.

Full adds reported start/end dates, source file, MD5, source snapshot date,
original source-row number and source role. `original_candidate_number` retains
the older fixed ordinary-result chair's candidate number separately from the
membership source's candidate number; it is not an identity crosswalk.

The 2014 endpoint/departure files contain five unmatched source observations
when linked only forward from the older XML: Johan Olofsson 550343 (Överkalix),
Johan Andersson 542929 and Pär Öberg 545699 (Ludvika constituencies),
Therese Lövdahl 546574 (Skinnskatteberg), and Morgan Malmborg 517851
(RF Jönköping constituency 0601). Explicit current chair numbers resolve the
current records; Överkalix's SD allocation has exactly one chair, supporting
the otherwise unnumbered terminal departure. All candidate numbers are preserved
as reported, without claiming equivalence to the older result identifiers.
The full ordinary-result reference keeps these differences inspectable.
Party fields describe the electoral allocation, not a verified history of
subsequent party membership or political affiliation.

## Source selection

`data_dir` accepts an archive root containing `rkl/` or the `rkl/` directory.
For explicit local selection, files are read directly, preserving the final record of CR-only CSV exports.
Explicit local selection performs no network acquisition. `files` can pin exact history/current/departure/
vacancy snapshots; otherwise the newest source-header date per role is used.
Conflicting equally dated snapshots require explicit selection. Differing
snapshots are not silently reconciled when their control values disagree.

For explicit local replay of 2022, use the audited sources rather than assuming
that the preserved October 2022 early snapshot covers the whole period:

```r
sources <- list(
  history = "path/to/ledamoter_med_historik.csv",
  current = "path/to/nuvarande_ledamoter.csv",
  departures = "path/to/avgangna_ledamoter.csv",
  vacancies = "path/to/tomma_stolar.csv"
)
h <- mandate_history(2022, data_dir = archive, files = sources, source = "local")
```

Current source contract (21 October 2026): auto selects complete canonical
history for 2014/2018 and current remote history for 2022. The latter combines
fresh official membership CSVs with the validated fixed original result.
Local membership files require explicit local selection. See
[MANDATE_HISTORY_SOURCE_SELECTION.md](MANDATE_HISTORY_SOURCE_SELECTION.md).


## Real-source validation

Validated against preserved raw histories/current/departure/vacancy files and
independently validated fixed-result allocations/elected reference tables:

| Period | Intervals | Active allocated chairs | Occupied at final snapshot | Vacant at final snapshot |
| --- | ---: | ---: | ---: | ---: |
| 2014–2018 | 18,684 | 14,807 | 14,719 | 88 |
| 2018–2022 | 18,422 | 14,745 | 14,674 | 71 |
| 2022–2026 | 18,079 | 14,683 | 14,583 | 100 |

All municipality/party vacancy controls agree. Initial and pre/post-rerun chair
counts agree. Multiple-holder chains, terminal vacancies and zero-length rows
are retained. Ragunda has no artificial vacancy. Kiruna 54150 is present;
Överkalix's two later vacancies start at the export's `2025-12-15` transition.
The earlier municipal resignation notices are not treated as that source date.

English/Swedish values, standard/full projection and exact Parquet round trips
pass for all three complete period tables. Date values retain class `Date` and
use integer day storage for reproducible Parquet round trips.

Independent diagnostics, logs and source checksums remain in the ignored local
audit directory. No raw sources or generated history/Parquet assets are tracked.

Final package validation:

- **3,832 passed assertions, 16 explicit integration skips, zero failures or
  warnings**, including 50 targeted interval/source regression assertions.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**.
- Every final holder matches the corresponding current-member export:
  14,719 / 14,674 / 14,583 for the three periods respectively.
- All **68** original 2014/2018/2022 canonical assets retain their manifest
  SHA256 values; all **13** newly preserved official-source hashes also agree.
- `git diff --check` passes; no local/raw/Parquet files are tracked.

For the package check, a separate local staging tree copied the Git-visible
package files, including the new implementation/tests/manuals, with the existing
`.Rbuildignore` rules applied to ancestor directories. Tar contents were checked
to exclude raw archives, development and acquisition material. This avoids R CMD
build's initial copy of the large local archive; no repository build rules or
intended installed package contents were changed.

## Explicit boundaries

- 2010–2014 is not implemented: its individual departure linkage lacks required
  source candidate identifiers.
- Temporary substitute attendance and actual meeting service are not modelled.
- These functions report source electoral-history dates; they do not establish
  actual statutory/physical service commencement.
- A missing or inconsistent required source causes an error, not fabricated
  dates, fabricated people, or an apparently complete snapshot.
- No longitudinal physical-person identifier is inferred from names or IDs.
