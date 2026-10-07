# RKL 2022 canonical build and validation

This report concerns the **unpublished local** `data-v0.2.0` prototype,
English Parquet schema version 2. The package version remains `0.3.0.9000`.
The build starts from commit `40af0b761c2583071bd38bc79a27783a8dcab380`
with the implementation changes in the working tree. A future distribution
requires a new build from reviewed, committed, clean code. No release,
registry entry, tag, commit or push is created here.

## Corrected elected-scope rebuild: 2026-10-07

The complete prototype has been rebuilt from the current working tree in
`.local-data/canonical-build/2022-local-v0.2.0-elected-scope`.
This section supersedes the earlier prototype's checksum/size, KF enrichment
diagnostic and package-test results below; the original investigation remains
as historical context. Source selection and the public schema are unchanged.

- Data version: `data-v0.2.0`; schema version: 2.
- Build commit: `40af0b761c2583071bd38bc79a27783a8dcab380`.
- `build_tree_dirty = true`, correctly identifying an unpublished working-tree
  prototype rather than a clean release build.
- Exactly 24 Parquet assets plus `manifest.json`; no raw or unintended files.
- Total directory size: **53,144,522 bytes**.
- Manifest SHA256:
  `f8ee437f3866e0bd17b8ebd7b18822606663dad9854c5192ebd910bf363b26df`.

All Parquet round-trips, recorded sizes/SHA256, build-code hashes, input
snapshot MD5/SHA256, and the exact directory inventory pass. Twenty-three
Parquet files are byte-identical to the previous validated prototype.
Only `rkl2022-elected.parquet` differs: three `total_preference_votes` cells
and one `preference_vote_areas_count` cell. Its row order, keys, types,
column set and all other values are unchanged.

### Complete rebuilt asset inventory

| File | Rows | Bytes |
| --- | ---: | ---: |
| `rkl2022-results-preliminar-rd.parquet` | 59,472 | 849,163 |
| `rkl2022-results-preliminar-rf.parquet` | 67,395 | 932,690 |
| `rkl2022-results-preliminar-kf.parquet` | 71,346 | 1,019,392 |
| `rkl2022-seats-preliminar.parquet` | 3,226 | 33,361 |
| `rkl2022-results-slutlig-rd.parquet` | 99,405 | 1,088,673 |
| `rkl2022-results-slutlig-rf.parquet` | 92,215 | 1,116,212 |
| `rkl2022-results-slutlig-kf.parquet` | 95,194 | 1,211,098 |
| `rkl2022-seats-slutlig.parquet` | 3,234 | 33,923 |
| `rkl2022-candidacies.parquet` | 170,781 | 1,867,436 |
| `rkl2022-candidates.parquet` | 70,813 | 952,032 |
| `rkl2022-elected.parquet` | 14,666 | 237,700 |
| `rkl2022-substitutes.parquet` | 80,420 | 455,749 |
| `rkl2022-preference-votes-base-area-rd.parquet` | 116,544 | 240,368 |
| `rkl2022-preference-votes-area-rd.parquet` | 111,118 | 587,462 |
| `rkl2022-preference-votes-base-district-rd.parquet` | 750,103 | 4,209,274 |
| `rkl2022-preference-votes-district-rd.parquet` | 662,369 | 5,038,942 |
| `rkl2022-preference-votes-base-area-rf.parquet` | 216,889 | 516,125 |
| `rkl2022-preference-votes-area-rf.parquet` | 209,557 | 1,479,563 |
| `rkl2022-preference-votes-base-district-rf.parquet` | 1,101,959 | 4,916,238 |
| `rkl2022-preference-votes-district-rf.parquet` | 894,984 | 6,807,215 |
| `rkl2022-preference-votes-base-area-kf.parquet` | 265,601 | 1,403,306 |
| `rkl2022-preference-votes-area-kf.parquet` | 246,861 | 3,909,401 |
| `rkl2022-preference-votes-base-district-kf.parquet` | 956,447 | 4,898,293 |
| `rkl2022-preference-votes-district-kf.parquet` | 990,858 | 8,191,498 |

The manifest contains each asset's SHA256 and size. The normalized-base
row counts describe packed source records, and analysis-file counts include
the stored view variants; neither is a single default public-view count.

### Corrected KF enrichment

Both canonical `candidates()` and `elected()` now return:

| Candidate | Total preference votes | Preference-vote areas count | Elected municipality |
| --- | ---: | ---: | --- |
| Mikail Yüksel, `35910` | 3,575 | 9 | `0127` Botkyrka |
| Maria Gilstig, `12565` | 205 | 1 | `0481` Oxelösund |
| Sead Busuladzic, `39734` | 477 | 1 | `1282` Landskrona |

The candidate-wide enrichment includes all relevant final result areas,
while elected geography continues to identify the actual elected relation.
All shared candidate/elected result fields now agree across the complete
14,666 elected-key population, not only these three cases.

Before rebuilding, a concrete ordering regression was detected in the new
2022 global-enrichment path: a requested RF/RD order could become RD/RF.
The smallest correction in `R/valda_slutlig.R` preserves the parsed file
order when selecting the elected candidate population, while retaining
global enrichment. Two focused assertions were added in
`tests/testthat/test-valda-slutlig-2022.R`. No schema, aggregation semantics,
candidate-name rules, source values or 2018/2026 implementation changed.

### Full validation results

**PASS:** 78 public canonical/raw request comparisons, covering all seven
functions, RD/RF/KF, all supported 2022 levels, preliminary/final results
and seats, candidate views with/without results, mixed elections, and
requested RF/RD ordering. Each request checks `standard`/`full` and
English/Swedish output equivalence, strict projection, row counts, keys,
column types, missingness and absence of unintended list columns.

All 24 area/district preference-vote variants pass, including list/non-list
and sparse/completed views. Added rows are verified zeros, never new unknown
rows; common sparse/completed observations retain identical values.
Independent RF region and KF municipality aggregation reproduces the
non-overlapping area numerators and denominators, recalculates shares,
preserves unknown denominators and does not propagate area qualification
to a broader level. Candidate populations and elected/substitute references
are valid; the Norrbotten reconstruction retains the original election-time
relations (71 elected and 1,259 substitute relations) and Bo Larsson's
corrected ID `488`, with 430 preference votes. Election-time unfilled seats
remain RD 0, RF 0 and KF 17.

**Preserved source discrepancy:** exactly the same 14 RD candidate-area
combinations remain 15 votes higher in area sources than district sums.
The case-level comparison with the earlier audit is identical. No vote is
corrected, reassigned or redistributed. RF/KF person-vote area/district sums
and RD/RF/KF preliminary/final party-vote aggregates agree. No new source
discrepancies were found. All preserved raw files and all 21 files in the
published 2018 release directory retain their original checksums.

Package verification after the ordering correction:

- Full test suite: **2,982 passed, 0 failed, 0 warnings**, nine expected
  opt-in integration skips; the 2022 opt-in checks were run separately here.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**.
- `git diff --check`: passed.

Machine-readable reports under `.local-data/canonical-build/`:
`2022-rebuild-results-seats.json`, `2022-rebuild-candidate-relations.json`,
`2022-rebuild-preference-votes.json`, `2022-rebuild-mixed.json`,
`2022-aggregate-audit.json`, and `2022-rebuild-final-verification.json`.
The four public/raw reports contain no unresolved implementation diagnostics.
The aggregate audit separately preserves the known RD source discrepancy.
No release, commit, push or tag was created. Publication still requires
review of the retained source discrepancy and a clean committed rebuild.

## Source selection and provenance

The preserved source collection is `.local-data/rkl/2022`. Original files
remain unchanged. The build records MD5, SHA256, size, classification and
selection for 1,244 result JSON files, 1,244 binary RSA signature files and
five candidate CSV snapshots. The signature files are provenance records;
they are not interpreted as textual SHA256 checksums.

The verified candidate input is `kandidaturer_20241218.csv`:

- MD5: `639daa9630a1f2554f1c6839473448ee`.
- SHA256: `991d2d49c02fba8397ca1c9b2697c22925c13d35edf4d0c8623218cacb8fbb3d`.
- 170,781 candidacies, including 168,233 valid candidacies. Invalid
  candidacies are retained in `candidacies()` and excluded from candidate
  populations according to the existing API.

Preliminary results use the complete preserved official generation. Final
results use that generation except for the approved corrected KF areas
0136 Haninge, 1439 Färgelanda, 1860 Laxå and 2506 Arjeplog. Their official
ZIPs are downloaded separately and MD5-verified against the reviewed
official index. They never replace the preserved snapshots.

The official index is
`https://resultat.val.se/resultatfiler/val2022/index.md5`:

- MD5: `b064f6690eb17434fb48997f7f827ae2`.
- SHA256: `a5948c31a5c2b295b78428fc0d74cea4ddd8a82f7e760772f2a8b4818788f861`.

### RF 25 Norrbotten reconstruction

Use the original October 2022 final relations, with only the documented
Bo Larsson candidate-number correction `50975 -> 488`. The transformation
is limited to typed candidate-ID fields for SD (`0110`), and to list
`0110-03652` for list preference-vote posts. It changes two mandate-file
fields and 95 district-file fields; no votes, names, order or relationships
are otherwise changed. The manifest records every changed JSON path and
the original/derived hashes, with decision `201-11278-2022` dated
2022-11-14 and the official protocol URL.

| Source | Original MD5 | Original SHA256 | Reconstructed SHA256 |
| --- | --- | --- | --- |
| RF25 mandate JSON | `ea31f87d4172ad787258cfe5790b4ff6` | `36dcfced07f3d7ee33b147a5943aefc383f45042404ca6f41df932b6326afe16` | `2fccc057a4ebc2a8b14285a79a74186d0478ace1133eb47560079fbabcd03858` |
| RF25 district JSON | `8ae8a7f37467daee7c5fcd408dcaa10b` | `bf125edce77682e1e5edf340191b22d1bcf0b2d040070a980cce0ad037c3ba36` | `e014c3dde2e2944d2f284e37bfaeb49fa4c9c3a5a7863049c2ebf7b16a738a62` |

The original Malin Viklund elected relation and original Liv Stråman,
Carina Diaz and Margareta Törelid Haapaniemi substitute relations are
retained. Later mandate-period replacements are excluded. Bo Larsson has
430 reported preference votes under corrected candidate number `488`.

### Independent input integrity audit

A separate Python audit of the derived comparison archive found:

- 1,234 JSON members byte-identical to preserved originals;
- eight JSON members byte-identical to the four verified corrected ZIPs;
- two reconstructed RF25 members with precisely the approved 2/95 leaf
  changes and no other structural/value differences;
- the candidate ZIP member with the pinned historical MD5;
- unchanged hashes for all 2,493 preserved input files and four downloaded
  corrected ZIPs (2,497 files checked).

The derived 622 ZIP containers and their derived index live in an external
temporary archive, not in the canonical distribution. Original and derived
checksums are explicitly distinguished. No mutable mandate-period CSV is
used to represent the fixed election result.

## Backend and coverage

All seven existing functions use the configured 2022 canonical manifest.
The English/Swedish name and standard/full layers are shared with the raw
route. No public argument, observation level or approved schema is changed.
An unpublished local build does not qualify for `source = "auto"`.

The prototype contains 24 Parquet assets plus `manifest.json`: six result
assets, two seat assets, four candidate/relation assets, six normalized
preference-vote bases and six preference-vote analysis assets. Analysis
area assets contain all four list/zero views; district analysis assets
contain the two sparse views. Completed district panels are reconstructed
from the normalized bases using the same verified raw presentation logic.

| Function | RD | RF | KF | Counting |
| --- | --- | --- | --- | --- |
| `results()` | district, parliamentary constituency, national | district, regional constituency, region | district, municipal constituency, municipality | preliminary and final |
| `seats()` | parliamentary constituency, national | regional constituency, region | municipal constituency, municipality | preliminary and final |
| `candidacies()` | preserved historical candidacies | same | same | snapshot, not counting stage |
| `candidates()` | candidate × election × party | same | same | final result enrichment, or no enrichment |
| `elected()` | official original/corrected final elected relation | same | same | final only |
| `substitutes()` | official original/corrected final substitute relation | same | same | final only |
| `preference_votes()` | area and district, list/zero variants | same, plus region aggregation | same, plus municipality aggregation | final only |

Unsupported 2022 levels are not synthesized from district sums. Source
language remains unchanged; all public shares use the existing proportion
scale. Missing source values remain missing. The internal normalized
official validation percentage is explicitly `source_preference_vote_percent`
on the original 0–100 scale; it is not a public share.

## Initial prototype validation results (historical)

### Local asset inventory

Final prototype directory:
`C:/git/swelections/.local-data/canonical-build/2022-local-v0.2.0-final`.
It contains exactly 24 Parquet files plus `manifest.json`, no raw source
files. Parquet size is 51,995,098 bytes; manifest size is 1,149,408 bytes.
Manifest SHA256 is
`668812ce01701dab128b3b66e87367d9feb5a5810c54e8f4265d440703a9d40f`.
The manifest records the commit above and `build_tree_dirty = true`.
All complete per-asset SHA256 digests are recorded in the manifest and
independently checked by each equivalence sweep.

Total distribution size is **53,144,506 bytes**. The final manifest was
refreshed after the two canonical ordering fixes and records the current
build-code SHA256 values. Its build time is `2026-10-06T16:47:53Z`.
All 24 Parquet files are byte-identical to the initially validated local
build, including their stored schemas, types and table/view layouts.
No source-language value transformation was introduced. The final directory
contains only the intended assets; it is not a clean release build.

Counts below describe stored partitions/components/views, not necessarily
one default public API call.

| Parquet asset | Stored rows | Bytes |
| --- | ---: | ---: |
| `rkl2022-results-preliminar-rd` | 59,472 | 849,163 |
| `rkl2022-results-preliminar-rf` | 67,395 | 932,690 |
| `rkl2022-results-preliminar-kf` | 71,346 | 1,019,392 |
| `rkl2022-seats-preliminar` | 3,226 | 33,361 |
| `rkl2022-results-slutlig-rd` | 99,405 | 1,088,673 |
| `rkl2022-results-slutlig-rf` | 92,215 | 1,116,212 |
| `rkl2022-results-slutlig-kf` | 95,194 | 1,211,098 |
| `rkl2022-seats-slutlig` | 3,234 | 33,923 |
| `rkl2022-candidacies` | 170,781 | 1,867,436 |
| `rkl2022-candidates` | 70,813 | 952,032 |
| `rkl2022-elected` | 14,666 | 237,684 |
| `rkl2022-substitutes` | 80,420 | 455,749 |
| `rkl2022-preference-votes-base-area-rd` | 116,544 | 240,368 |
| `rkl2022-preference-votes-area-rd` | 111,118 | 587,462 |
| `rkl2022-preference-votes-base-district-rd` | 750,103 | 4,209,274 |
| `rkl2022-preference-votes-district-rd` | 662,369 | 5,038,942 |
| `rkl2022-preference-votes-base-area-rf` | 216,889 | 516,125 |
| `rkl2022-preference-votes-area-rf` | 209,557 | 1,479,563 |
| `rkl2022-preference-votes-base-district-rf` | 1,101,959 | 4,916,238 |
| `rkl2022-preference-votes-district-rf` | 894,984 | 6,807,215 |
| `rkl2022-preference-votes-base-area-kf` | 265,601 | 1,403,306 |
| `rkl2022-preference-votes-area-kf` | 246,861 | 3,909,401 |
| `rkl2022-preference-votes-base-district-kf` | 956,447 | 4,898,293 |
| `rkl2022-preference-votes-district-kf` | 990,858 | 8,191,498 |

### Initial cross-surface discrepancy: multi-area elected KF candidates (resolved above)

The independently built raw outputs reveal three differences between the
established `candidates()` and direct `elected()` paths. Their canonical
assets preserve each respective raw path, rather than silently making one
agree with the other:

| Candidate | Number | Party | Elected municipality | `elected()` total | `candidates()` total | Elected/candidate preference-area count |
| --- | --- | --- | --- | ---: | ---: | ---: |
| Mikail Yüksel | 35910 | 1439 | 0127 | 454 | 3,575 | 1 / 9 |
| Maria Gilstig | 12565 | 0110 | 0481 | 54 | 205 | 1 / 1 |
| Sead Busuladzic | 39734 | 1439 | 1282 | 324 | 477 | 1 / 1 |

These candidates have valid candidacies in several municipalities. The
direct elected raw path enriches the elected relation from its own result
file; the candidate raw path accumulates results across all relevant files.
The discrepancy therefore concerns the extent of preference-vote
enrichment, not source IDs, elected municipality, order or election basis.
No production reconciliation is made in this task. The intended semantics
and correction to this existing raw API difference must be reviewed before
publishing a data release. The validation records this as a separate FAIL
diagnostic, even if canonical/raw equivalence for each function passes.

### Source-level discrepancy: RD area versus district preference votes

An independent arithmetic audit finds **14 candidate × constituency
differences on 12 lists, totalling 15 preference votes**. The selected
mandate-file area lists report more identified candidate preference votes
than the sum of the selected district lists. A separate Python trace
reproduces every value directly from raw `listRoster$personroster` without
using the package parser. Both selected RD files have update number 371
and all 6,578 districts counted; their export update times differ:

- `Val_20220911_slutlig_mandatfordelning_00_RD.json`:
  `2022-10-20T17:14:28`, SHA256
  `87c488582dc0e062ab1733fbc7811a4f4b6c448707c888ebe3c61370258072d9`.
- `Val_20220911_slutlig_rostfordelning_00_RD.json`:
  `2022-10-20T16:34:13`, SHA256
  `9c97cd083db17f923056b93746b2ad598a208a2324585d3d1015d9ea47a0ccad`.

| Constituency | Party | Candidate | Name in area source | List | Area votes | District sum |
| --- | --- | --- | --- | --- | ---: | ---: |
| 01 | 1525 | 10809 | Lena Stark | 1525-02250 | 1 | 0 |
| 03 | 1505 | 57587 | Ulf Bejerstrand | 1505-05478 | 41 | 40 |
| 03 | 1543 | 13123 | Gudrun Schyman | 1543-05428 | 5 | 4 |
| 11 | 1296 | 916 | Ilan Sadé | 1296-00057 | 100 | 99 |
| 20 | 1011 | 42178 | Eva Holmgren | 1011-03689 | 2 | 1 |
| 20 | 1325 | 38043 | Gustav Kasselstrand | 1325-02684 | 140 | 138 |
| 28 | 0977 | 29717 | Petra Axelsson | 0977-02615 | 1 | 0 |
| 28 | 0977 | 31606 | Abe Bergegårdh | 0977-02615 | 1 | 0 |
| 28 | 1011 | 19069 | Claes Littorin | 1011-03689 | 3 | 2 |
| 28 | 1430 | 47717 | Paula Dahlberg | 1430-03407 | 1 | 0 |
| 28 | 1505 | 57587 | Ulf Bejerstrand | 1505-05478 | 26 | 25 |
| 28 | 1505 | 57593 | Robin Johansson | 1505-05478 | 1 | 0 |
| 28 | 1568 | 57555 | Mikael Cromsjö | 1568-05433 | 2 | 1 |
| 28 | 1586 | 58302 | Håkan Jönsson | 1586-05736 | 1 | 0 |

Constituencies are Stockholms kommun (01), Uppsala län (03), Malmö kommun
(11), Västra Götalands läns östra (20), Västerbottens län (28).
For every affected list, area `antalRoster` equals the district list sum.
The difference instead occurs in `antalRosterMedPersonrost` and the
identified candidate posts, with internally matching person-vote arrays
in each source. The corresponding party vote totals also match.
This is a source-level cross-level mismatch, not a Parquet, normalization
or public projection difference. The export timestamps alone do not prove
the cause. No values are reconciled, overwritten or reassigned. Area views
and candidate totals retain the area source; district views retain the
district source. A source clarification is needed before claiming exact
area/district preference-vote equivalence for these RD cases.

RF and KF identified area/district candidate preference-vote sums agree.
Official main-level party vote counts agree exactly with district sums
for all three elections and both preliminary/final counting stages.

Reproduce with `development/audit_canonical_2022_aggregates.R` and
`development/diagnose_2022_rd_person_votes.py`. The latter saves every
matching raw candidate post, list counters and geographic context in
`.local-data/canonical-build/2022-rd-person-vote-source-traces.json`.
The arithmetic report is `.local-data/canonical-build/2022-aggregate-audit.json`.

### Package verification

- Complete deterministic suite: PASS.
- Source-package `R CMD check --no-manual --no-vignettes`: **0 errors,
  0 warnings, 0 notes** (`Status: OK`). The installed-package suite reports
  **2,938 passed assertions, 0 failures, 0 warnings, 9 opt-in skips**.
  The final source build uses a temporary copy filtered by `.Rbuildignore`
  before `R CMD build`, avoiding Windows long-path copying of concurrent
  generated validation caches. Package code and included files are unchanged.
- The opt-in 2022 sweep completed **75 public/raw requests**: 30 result/seat
  requests, 19 candidacy/candidate/relation requests and 26 preference-vote
  requests. All per-function canonical/raw comparisons passed, including
  English/Swedish names, standard/full projection, row order, types,
  observation keys and missingness. Separate cross-surface/source arithmetic
  diagnostics retain the two unresolved discrepancies described above.
- Six completed district-panel audits passed: sparse rows and positive
  counts are unchanged and every added row is a verified zero, never `NA`.
- Norrbotten corrected IDs and original election-time relations passed.
  Valid-candidacy populations, elected keys and substitute references passed.
- Two warnings in the development harness accessed an intentionally absent
  qualification column in broader aggregation views. The assertion now
  verifies column absence; a targeted RF/KF rerun checks that exact contract.
  Both raw/canonical aggregation comparisons and independent arithmetic
  checks passed again **without warnings** against the final manifest.
  No production or source-data change was needed.
- Final-manifest smoke verification passed all 21 default function/election
  requests (seven functions × RD/RF/KF), with English/Swedish and
  standard/full equivalence against the initially validated assets.
  The final manifest's asset hashes, sizes, exact directory inventory and
  recorded production/build-code hashes match the actual files.
- `git diff --check`: PASS. Git's informational LF/CRLF messages are not
  whitespace errors.
- The 20 published 2018 asset checksums are unchanged. The preserved 2018
  manifest SHA256 remains
  `21bde9c2545d1c25d99c7ef7b30a2168b955059b58b78d7c06b2c5717959f89f`.

### Completed result and seat comparisons

All 18 result requests and all 12 seat requests passed exact public
canonical/raw comparison, including row order, types and missingness.
For each request the full English output equals the raw API output, the
Swedish output differs only in column names, and standard is an identical
row-preserving projection of full. No source warnings were recorded in
these 30 comparisons.

| Election | Count | District result rows | Constituency result rows | Main-level result rows | Constituency seat rows | Main-level seat rows |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| RD | preliminary | 59,202 | 261 | 9 | 166 | 8 |
| RD | final | 98,194 | 1,122 | 89 | 166 | 8 |
| RF | preliminary | 66,635 | 549 | 211 | 364 | 147 |
| RF | final | 90,066 | 1,491 | 658 | 365 | 147 |
| KF | preliminary | 68,028 | 416 | 2,902 | 314 | 2,227 |
| KF | final | 88,648 | 1,007 | 5,539 | 314 | 2,234 |

Main level means national (RD), region (RF), municipality (KF).
Constituency means parliamentary (RD), regional (RF), municipal (KF).
The independently checked election-time unfilled seat totals are
**RD 0, RF 0, KF 17**, with no unknown values at the main mandate levels.

### Candidate and area-level preference-vote missingness

These are default full public views, not the combined stored partitions.

| Candidate election | Candidate keys | Positive totals | Zero totals | Unknown totals |
| --- | ---: | ---: | ---: | ---: |
| RD | 6,168 | 5,905 | 263 | 0 |
| RF | 12,644 | 12,267 | 377 | 0 |
| KF | 52,001 | 47,325 | 4,676 | 0 |

| Preference-vote election | Area rows | Positive votes | Zero votes | Unknown votes | Unknown party denominator |
| --- | ---: | ---: | ---: | ---: | ---: |
| RD | 32,409 | 13,583 | 18,826 | 0 | 1,771 |
| RF | 58,596 | 22,988 | 35,608 | 0 | 399 |
| KF | 63,098 | 54,485 | 8,613 | 0 | 385 |

A known candidate vote count does not invent a party denominator. Shares
remain `NA` where the official party denominator cannot be established,
including parties not separately enumerated in the relevant vote table.

### Completed preference-vote variants and aggregation

Every row below passed exact raw/canonical comparison for both output
languages and detail levels. All listed person-vote counts have zero `NA`;
unknown denominators remain `NA` and are not replaced by synthetic totals.
The non-list area default already includes verified zero candidates;
`include_zeros` does not change that established default view.

| Election | Area list sparse | Area list completed | District sparse | District completed | District list sparse | District list completed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RD | 13,971 | 32,329 | 330,009 | 4,781,269 | 332,360 | 5,088,979 |
| RF | 24,580 | 67,785 | 446,224 | 6,696,302 | 448,760 | 7,694,165 |
| KF | 55,715 | 64,950 | 492,913 | 2,082,352 | 497,945 | 2,243,008 |

Added district zeros without/with list dimension are RD
4,451,260 / 4,756,619; RF 6,250,078 / 7,245,405; KF
1,589,439 / 1,745,063. Area-list completed views add RD 18,358,
RF 43,205 and KF 9,235 verified zeros. No additional unknown rows are added.

RF region aggregation has 12,689 rows (12,291 positive, 398 zero),
with 139 unknown party denominators. KF municipality aggregation has
52,518 rows (47,532 positive, 4,986 zero), with 326 unknown denominators.
Independent non-overlapping area sums reproduce both numerators and
denominators exactly, shares use the aggregated ratio, keys are unique,
and person-area qualification is not propagated to the broader view.
No unknown candidate numerator occurs in these selected complete sources;
deterministic tests separately cover incomplete sources.

Mixed-election candidacy/candidate/elected/substitute outputs passed exact
raw comparison, including requested-order and subset-count semantics.
Combined populations contain 170,781 candidacies, 70,813 candidate keys,
14,666 elected keys and 80,420 substitute relations. Candidate/elected
identity keys agree even for the three enrichment discrepancies above.

Machine-readable checks are retained locally as
`2022-validation-results-seats.json`,
`2022-validation-candidates-relations.json`,
`2022-validation-preference-votes.json` and
`2022-validation-mixed.json` under `.local-data/canonical-build/`.
The final warning-free aggregation check is
`2022-validation-final-aggregation.json` in the same directory.

## Review required before publication

The local backend/build and the corrected KF enrichment pass full raw
equivalence. The remaining 14 RD source-level area/district differences
are preserved and documented above; they require review of release
provenance, not silent reconciliation. The 2022 manifest is configured
explicitly for local use; no unpublished release is automatically selected.
After review, commit the implementation and rebuild from clean code before
any publication. This task creates no release, tag, commit or push.

## Changed files and implementation boundary

Production files:

- New `R/canonical_2022.R` (year-aware configured backend, stored view
  selection and normalized-base reconstruction).
- `R/api_english.R`, `R/api_ersattare.R`, `R/api_kandidater.R`,
  `R/api_kandidaturer.R`, `R/api_mandat.R`, `R/api_personroster.R`,
  `R/api_validation.R`, `R/api_valresultat.R`, `R/ersattare_slutlig.R`,
  `R/valda_slutlig.R` (2022 canonical routing and source documentation).
- `R/personroster_2022.R` (extract the existing pure public presentation
  helper for shared raw/canonical use; no changed availability semantics).
- `R/output_names.R` (English names for normalized-base-only fields;
  no public column rename).

Build and diagnostics:

- `data-raw/prepare-canonical-2022.py`.
- `data-raw/build-canonical-2022.R`.
- `development/validate_canonical_2022.R`.
- `development/audit_canonical_2022_aggregates.R`.
- `development/diagnose_2022_rd_person_votes.py`.

Tests:

- `tests/testthat/test-canonical-2022.R`.
- `tests/testthat/test-canonical-backend.R`.
- `tests/testthat/test-personroster-2022.R`.

Documentation: `README.md`, `NEWS.md`, `development/CANONICAL_DATA.md`,
this report, and the regenerated `man/{candidacies,candidates,elected,
substitutes,preference_votes,results,seats,kandidaturer,kandidater,valda,
ersattare,personroster,valresultat,mandat}.Rd` files.

During the initial prototype's equivalence testing, requested election
ordering for canonical elected/substitute views and global mixed-election
sorting for canonical preference views were corrected. The subsequent
raw elected-order correction is documented in the rebuild section above. Targeted
raw comparisons and deterministic regressions passed after those fixes.
Validation checkpoint parsing, memory lifetime and temporary-cache handling
were improved in the development harness only. No published asset, raw
snapshot, candidate-name rule, 2026 RF validation or download helper changed.

