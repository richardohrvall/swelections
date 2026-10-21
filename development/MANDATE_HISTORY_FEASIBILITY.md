# Mandate-history feasibility: start dates and vacant chairs

Follow-up audit, including targeted Ragunda/Överkalix/Kiruna reconciliation:
19 October 2026. This is a design/source assessment, not an
implementation. No production code, election data or source files were changed.

## Sources and method

The original chair population comes from the fixed final election allocations,
including unfilled mandates. It must not be inferred from the population of
people in a history export. Municipality/region totals and their constituency
components must not both be counted. Re-election replacements must be handled
through the already established event/replacement relationships.

The audit used the validated original elected and seat tables in the local
2014, 2018 and 2022 canonical reference builds, alongside preserved member,
departure and vacancy files under `.local-data/rkl/<year>/kandidater/`.
These local references are not new build inputs or public source distributions.

For 2022, the following official exports were retrieved from
`https://resultat.val.se/filer/val2022/info/`:

| File | Generation timestamp reported inside the source |
| --- | --- |
| `ledamoter_med_historik.csv` | 2026-10-15 03:51:49 |
| `nuvarande_ledamoter.csv` | 2026-10-15 03:51:28 |
| `avgangna_ledamoter.csv` | 2026-10-17 03:51:22 |
| `tomma_stolar.csv` | 2026-10-15 03:51:54 |
| `ledamoter_och_ersattare_utokad.csv` | 2026-10-14 03:51:25 |

These are source-generation timestamps, not inferred event dates. The live
exports can change; the counts below describe the versions inspected.

**Correction to the first audit:** these exports use CR-only record separators
and do not terminate their final record. The previous
`readr::read_delim(I(rawToChar(response)), skip = 1, ...)` audit path discarded
the last record. Reading the preserved files directly retains it. Independently
parsing a CR-to-LF-normalised in-memory copy with both readr and base R gives
identical values in every field for all five exports. This was an audit parsing
error, not an omission in Valmyndigheten's data. It caused both the apparent
Kiruna missing chair and the 98-versus-100 vacancy discrepancy.
The behaviour was reproduced with readr 2.2.0 / vroom 1.7.1; it is not a claim
that all CSV readers or all readr input paths discard such a record.

New evidence is preserved, without overwriting older sources, under
`.local-data/mandate-status-audit-20261019/`. Its `retrieval-manifest.json`
records official URLs, retrieval/check times, sizes, MD5 and SHA256. Raw
sources remain local and ignored. The erroneous counts below have been replaced
by the corrected file-based counts.
The local `verify_exports.R` repeats the independent parser and vacancy-group
checks. All checks passed, as did verification of all 13 newly preserved
official-source checksums and the report's whitespace check. No package tests
or canonical rebuild were needed because production code and assets were not
changed.

Matches used election type, original election, geography, party, candidate
number and election order/chair number where provided. Names were not used to
establish identity. Geographic codes were normalised for their actual roles,
including undivided regions and municipalities.

Valmyndigheten defines original elected members' entry date as election day;
for successors it is the date of the county administrative board's appointment.
Its departure date equals the successor's entry date. These are administrative
history conventions, not evidence of actual attendance or temporary service:

- [Historical raw-data documentation](https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-val-2002-2022)
- [Current member-file definitions](https://www.val.se/valresultat-och-statistik/riksdags--region--och-kommunval/nuvarande-och-avgangna-ledamoter)

## Missing start dates

### 2022–2026

The history export has 17,996 rows: 3,313 reported starts and 14,683 blank starts.

| Type | Blank starts: original elected people | Blank starts: initial vacant chairs | Total blank starts |
| --- | ---: | ---: | ---: |
| RD | 349 | 0 | 349 |
| RF | 1,720 | 0 | 1,720 |
| KF | 12,597 | 17 | 12,614 |
| Total | 14,666 | 17 | 14,683 |

All 14,666 person rows match original elected observations. Their party/chair
orders also match, with zero order mismatches. Each can therefore receive a
derived `start_date = 2022-09-11` under the documented source convention.

The remaining 17 rows have no candidate number and match the original unfilled
chair population. Their vacancy intervals can likewise begin on election day,
with a separate derivation reason. They are not unidentified people.

Thus **zero existing history rows retain an unexplained blank start** after
these two classifications. Every original elected record is represented;
Kiruna candidate 54150 is included in the final record of the history export.

### 2014–2018 and 2018–2022

The 2014 original-member file `ursprungligt_valda_ledamoter_RLK.skv` has 14,787
blank entry dates. All 14,787 match original elected records, including party
and election order, and can receive derived `2014-09-14` starts. The other three
rows have later dates and represent later RD replacements; this export must
not replace the fixed final election as the original population.

There are no blank starts in the 3,795 preserved 2014 departure rows or the
14,719 current-member rows. The 2018 history export has 18,422 rows and zero
blank starts, including its separately identified Falun re-election component.

Derived dates must preserve the original blank and record a reason such as
`original_elected_match` or `original_unfilled_allocation`. A blank alone is
never sufficient justification for assigning election day.

## Initial and later vacancies

### 2014

The final result allocates 14,807 mandates and identifies 14,790 elected people:
17 initially unfilled KF mandates. These occur in municipality/party groups
0140 SD (1), 0428 SD (1), 0560 SD (2), 0763 SD (1), 0861 SD (1),
1276 SD (2), 1438 SD (2), 1439 SD (2), 1462 SD (2), 1907 MP (1),
2417 SD (1), and 2506 SD (1).

The departure file contains 71 rows without a named/identified successor.
Initial vacancies (17) plus those departures (71) reconcile to all 88 empty
chairs in the final vacancy snapshot, with **zero municipality/party-group
count discrepancies**. This is a group-level reconciliation; the vacancy file
does not itself supply individual chair numbers or historical vacancy dates.
Individual intervals still require the original allocations and succession
chains rather than replication of the aggregate vacancy rows.

### 2018

The fixed final result has 14,745 allocated mandates, 14,723 elected people and
22 unfilled mandates. The history export instead records 21 election-day empty
chairs and 50 later vacancy intervals, totalling the 71 empty chairs reported
at its final snapshot.

The initial-state difference is **KF Ragunda 2303, SD 0110, chair 3**:
the preserved `slutresultat_2303K.xml` reports one SD vacancy and no elected
record for candidate 534885; the history export records candidate 534885,
Pehr Häggkvist, on that chair from `2018-09-09`, with no departure date.
The XML has reporting timestamp `20181002095944`; the history export was
generated on 31 October 2022. The targeted investigation establishes that this
is an official correction of the election result, not an ordinary successor
appointment: see the detailed chronology below. The old XML's 22 vacancies are
not the corrected final initial-vacancy population; the later history records
21. No canonical asset was changed in this audit.

### 2022

The fixed result allocates 14,683 mandates: RD 349, RF 1,720 and KF 12,614.
It identifies 14,666 elected people and 17 initial vacancies. All 17 vacancies
have explicit candidate-less history rows, without a start or end date.

| Municipality | Party | Chair order(s) | Constituency, if applicable |
| --- | --- | --- | --- |
| Munkfors 1762 | M | 1 | — |
| Lekeberg 1814 | SD | 4, 5 | — |
| Laxå 1860 | SD | 2, 3 | — |
| Hallsberg 1861 | KD | 2 | — |
| Gagnef 2026 | SD | 3, 4 | — |
| Örnsköldsvik 2284 | SD | 3 | 228401 |
| Nordmaling 2401 | SD | 2, 3 | — |
| Vindeln 2404 | SD | 2 | — |
| Sorsele 2422 | M | 3 | — |
| Dorotea 2425 | SD | 4, 5, 6 | — |
| Lycksele 2481 | SD | 2 | — |

All initial vacancy groups occur in the current vacancy file. That file alone
does not distinguish their initial vacancies from later vacancies.

There are also 83 departures without a successor ID. All 83 match closed
history rows by candidate, party, geography and departure date. However, the
history file does not contain their subsequent candidate-less vacancy rows.
The current-member export contains 100 empty rows (17 initial + 83 later),
and `tomma_stolar.csv` also reports **100**, in 60 rows. Överkalix's two vacant
SD chairs are the vacancy file's final row. All municipality/party vacancy
counts agree exactly between the two files.

Kiruna candidate 54150 is the final row in both the history and current-member
exports. The original chair is present, occupied, and has no reported departure.
The current-member export accounts for **14,583 occupied + 100 vacant = 14,683
allocated chairs**. There is no missing Kiruna chair or conflicting vacancy
total in these snapshots.

## Targeted reconciliation of the three cases

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

## Shared chair structure and snapshot API

Use a single chair population based on allocated mandates, keyed by original
election/continuing period, election type, allocation geography, party and
chair order. Keep source chair identifiers separate from any generated key.
Apply verified re-election replacement links without duplicating the old and
replacement chairs or starting a new mandate period.

Each chair has status intervals: `occupied`, `vacant`, or `unknown`. Preserve
source references, reported dates, derived dates, derivation reasons and
source coverage boundaries. An absent successor name alone must not establish
a vacancy unless the other source evidence supports that interpretation.

An internal all-chair snapshot can support both proposed public queries:

- `ledamoter_vid(datum, ...)`: occupied chairs and their recorded holders;
- `tomma_stolar_vid(datum, ...)`: chairs verified vacant on that date.

These are filters over the same snapshot, not separate populations. Unknown
chairs must remain visible through an all-chair view or accompanying coverage
information; neither query may imply that its complement is fully known.
The invariant is **occupied + vacant + unknown = allocated active chairs**.

Use half-open intervals `[start_date, end_date)` for source-supported changes:
the outgoing interval ends when the successor interval begins. Report explicitly
that the date convention follows appointments recorded by Valmyndigheten; it
does not reconstruct temporary substitute service or actual attendance.

Recommendation: proceed with this shared structure once the above source
conflicts have an explicit treatment. No separate vacancy data architecture is
needed, and election-day derivation is supported for the verified original
rows rather than for arbitrary missing dates.
