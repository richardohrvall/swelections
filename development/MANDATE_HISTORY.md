# Mandate-period history

Implemented in the published v0.4.0 release. The dated validation observations below describe preserved snapshots, not live guarantees.
The verified source-role and Ragunda/Överkalix/Kiruna evidence is consolidated below.

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
[the published release record](releases/v0.4.0.md).


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

## Preserved sources and coverage

| Period | Preserved member/control inputs | Snapshot / role |
| --- | --- | --- |
| 2014–2018 | `nuvarande_ledamoter.skv`, `avgangna_ledamoter.skv`, `tommastolar.skv` under `rkl/2014/kandidater/` | 2018-11-07; current chair anchor, succession/departures, independent vacancies |
| 2018–2022 | `ledamoter_med_historik_20221031.skv`, `nuvarande_ledamoter_20221031.skv`, `avgangna_ledamoter_20221031.skv`, `tommastolar_20221031.skv` under `rkl/2018/kandidater/` | 2022-10-31; primary history and three controls |
| 2022–2026 | `ledamoter_med_historik.csv`, `nuvarande_ledamoter.csv`, `avgangna_ledamoter.csv`, `tomma_stolar.csv` | Fresh official remote sources; actual source headers determine coverage |

The `_20221031` suffix is a preserved local snapshot label, not a claim about
the official original filename. Original final allocations/elected records are
required independently of every member source, including unfilled allocations.
The 2014 canonical interval coverage is 2014-09-14 through 2018-11-07; the
2018 coverage is 2018-09-09 through 2022-10-31. These source conventions do not
extend a legal mandate period. Select the original year explicitly around a
transition if that is the intended query.

Remote CSVs are fetched sequentially from
[the official 2022 export directory](https://resultat.val.se/filer/val2022/info/).
A newer departure/vacancy export does not extend an older history/current-member
coverage boundary. The reader rejects inconsistent snapshots and later dates;
it never silently falls back to a local archive. Canonical 2014/2018 and remote
2022 retain the same source-specific interval semantics.

## Verified source reconciliation

### Ragunda 2018: corrected election result

Relevant preserved sources are `rkl/2018/valresultat/slutresultat.zip`
(`slutresultat_2303K.xml`), the December 2018 `kandidaturer.skv` snapshot,
and all six member/history/departure/relation/vacancy SKV files dated
20221031 under `rkl/2018/kandidater/`. Candidate 534885 is absent from the
preserved candidacy snapshot and early final XML, but appears in the later
history, current-member and expanded member/substitute files. No departure
or successor event for that candidate occurs in the departure file.

The official explanation is
[Valprövningsnämnden 877-2018, decided 12 December 2018](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/valprovningsnamndens-beslut/mandatfordelning-inom-parti-bifall-forordnande_h6d34c8b78/).
It establishes a timely candidacy consent, five wrongly disregarded personal
votes, and orders a new SD candidate allocation treating Häggkvist as eligible.
The old two-person/three-seat result therefore precedes an election-result
correction. This is not a re-election or evidence of a routine mid-term vacancy.

The [official final presentation](https://historik.val.se/val/val2018/slutresultat/K/kommun/23/03/valda.html)
has update timestamp `2019-01-17 13:38:11`; names and its protocol link are now
redacted. The 2022 history/current files explicitly place candidate 534885 on
SD chair 3 from `2018-09-09`, without an end date. The history/current files
give list `0110-17638`, position 3; the expanded file confirms the candidate and
chair. No Ragunda vacancy
is reported in the end-of-period vacancy file.

**Conclusion:** the corrected electoral composition has Häggkvist occupying
chair 3, with the source's election-day start convention. The old XML vacancy
must not be carried forward as an actual continuing empty chair. The precise
date of the implementing county decision and any period of actual non-service
before correction remain unverified. Obtain the county's revised Ragunda SD
allocation protocol following decision 877-2018 to date that administrative
transition. The linked `slutresultat/protokoll/protokoll_2303K.pdf` could not be
retrieved (HTTP 503/cache failure); that failure is not evidence of absence.
Do not substitute the appeal decision date or web update timestamp for the
missing implementing-decision date.

Approved implementation interpretation: `start_date = 2018-09-09`, directly
reported in the history/current files, describes the corrected original
electoral composition. The separate `correction_date = 2018-12-12` dates the
appeal decision. The unverified county implementation date is provenance only;
it does not make the corrected electoral start unknown or create a vacancy.
An actual re-election instead has its own polling-event start, while remaining
in the original mandate period. The existing RF Norrbotten 2022 ID correction
likewise leaves the original electoral start unchanged and retains its
14 November correction provenance in the canonical build manifest. The 2026
RF counting/election-basis correction is outside these three history periods;
it is not a new appointment or a new election event.

### Överkalix 2022: two later vacancies, no source conflict

The original preserved
`Val_20220911_slutlig_mandatfordelning_2513_KF.json` elects SD candidate 4759
(Tord Roland Andersson) to chair 2 and 4760 (Ethel Elise Landström) to chair 3.
Their ballot names in the same source are Roland Andersson and Ethel Landström;
the matching uses the candidate numbers, not a name inference. The corresponding
vote JSON supports their result records. Both appear as occupied chairs in
the 12 October 2022 current/history snapshots and the 13 November 2022 expanded
relation snapshot, with no listed substitutes for these chairs.

The [municipal protocol of 1 December 2025, section 67](https://www.overkalix.se/media/vcpfcde3/kf-2025-12-01-61-74.pdf)
records both council resignations. Section 74 concerns Andersson's separate
municipal-executive substitute role and must not be used as the council-seat
transition date. The [23 February 2026 protocol, section 6](https://www.overkalix.se/media/iylbfxz1/kf-2026-02-23-1-10.pdf)
and its [agenda/registration list](https://www.overkalix.se/media/yikdzwe5/kallelse-samt-kungorelse-till-kommunfullmaktiges-sammantrade-20260223-samt-bilaga-1.pdf)
identify resignation/recount-request records dated 26 November 2025, municipal
cases 2025-000791 and 2025-000792, and county closure decisions 18915-2025-4
and 18914-2025-4 received on 16 December 2025.

The current history/departure exports both give `2025-12-15` departures and no
successor IDs. The current-member export has candidate-less chairs 2 and 3
starting on that same date; the expanded relation file labels both
`Kunde inte utses`. The final row of `tomma_stolar.csv` confirms two empty SD
chairs in Överkalix.

**Conclusion:** the source-defined intervals are occupied from the original
election until `2025-12-15`, then vacant through the inspected final snapshots.
Both vacancies are real later vacancies, not initial vacancies. The vacancy
count conflict was solely the audit's discarded final record. The council
resignations were already documented earlier; `2025-12-15` is the export's
administrative transition, not proof that the people actually served until
that day. If exact legal resignation effectiveness is required, inspect the
original resignation documents and the two identified county decisions.

### Kiruna 2022: occupied chair; history record was not missing

The original preserved
`Val_20220911_slutlig_mandatfordelning_2584_KF.json` elects candidate 54150,
Nils Per Olof Nutti (ballot/result name Per Olof Nutti), for party 1073,
chair 2, on personal votes. Its original substitute order is 54152 then 54153.
The corresponding vote JSON, both 12 October 2022 current/history files, and
the 13 November 2022 expanded relation snapshot confirm this candidate/seat.

The full October 2026 history and current-member exports retain candidate
54150 on the same chair, with blank original entry date and no departure date.
The 14 October expanded relation export also retains him, now with substitutes
54152 then 54154. That change is in the substitute relations, not evidence of
a change of the chair's holder; its intervening appointment date is not
established by these endpoint snapshots. No departure row for Nutti was found.

Independent municipal corroboration includes the
[24 October 2022 attendance/member list](https://kiruna.se/download/18.4e03e69b18418a04c9f7ca5/1667555242597/Kommunfullm%C3%A4ktiges%20protokoll%202022-10-24.pdf),
the [11 March 2024 protocol](https://kiruna.se/download/18.17baa4b618e0dbf1076a773/1710745583920/Protokoll%20kommunfullm%C3%A4ktige%202024-03-11.pdf),
and the [29 September 2025 member list](https://kiruna.se/download/18.25216a2b19a0f615ad938b0/1761749794335/Protokoll%20kommunfullm%C3%A4ktige%202025-09-29.pdf).
These corroborate the ID-based source chain; they are not name-based ID mappings.

**Conclusion:** occupied by candidate 54150 from the derived original-election
start `2022-09-11`, with no reported holder transition through the inspected
2026 snapshots. No vacancy interval or unknown chair is supported. The prior
missing-row conclusion was entirely an audit parsing error. Temporary meeting
substitution, if any, is not a departure from the electoral chair.
