# Validation of the English value and storage contract

Validation date: 21 October 2026. Local worktree builds only; no publication,
commit, push or eligibility change. See [the contract](VALUE_CONTRACT.md) for
vocabularies, Boolean applicability, source-value exceptions and release migration.

## Built products

| Product | Parquet assets |
| --- | ---: |
| RKL 2002 | 14 |
| RKL 2006 | 15 |
| RKL 2010 | 24 |
| RKL 2014 | 24 |
| RKL 2018, reviewed Ragunda correction included | 20 |
| RKL 2022 | 24 |
| Referendum 2003 | 1 |
| EU 2004 | 14 |
| EU 2009 | 14 |
| EU 2014 | 14 |
| EU 2019 | 15 |
| EU 2024 | 15 |
| **Total** | **194** |

Every manifest uses schema 3, value schema 1, storage schema 1 and
`data-v0.4.0`. All builds truthfully have `build_tree_dirty = true`.
The final local generation is recorded in the ignored validation directory's
`reviewed-refs.rds`; its asset bytes match the first new-contract generation
exactly. The 194 assets total 255,341,797 bytes.

This was verified re-encoding of already validated prototypes, not a claim that
all raw sources were reparsed by the re-encoding tool. Input manifest and asset
checksums, original source inventories and prior build provenance are retained.
The maintained raw builders/exporter now write the same new contract.

## Completed checks

- All 194 assets: exact preservation of non-authorized columns, quantities,
  identifiers, proper names, missingness and row order against approved inputs.
  Changes are restricted to the approved technical values/storage keys and the
  two applicability columns. Typed categories and logical applicability were
  checked separately.
- Repeated preparation: all 194 Parquet assets are byte-identical across local
  generations. Final code hashes, manifest sizes/SHA256 and Parquet round trips
  pass for every asset.
- Public canonical matrix: 856 actual calls, English/Swedish wrappers and
  standard/full, with supported views, stages and geographic levels. Standard
  is an exact full-output projection; language variants have identical meaning.
- Mandate histories and both snapshot functions: 2014, 2018 and 2022, both
  interfaces and detail levels. All five re-elections and effective composition
  checks pass. The separately preserved old composition control is not counted
  as a current new-contract output.
- Full tests: **4,633 passed, 16 explicit skips, 0 failures, 0 warnings**.
  External integration skips are not claimed as live tests.
- `R CMD check --no-manual`: **0 errors, 0 warnings, 0 notes**.
- Source integrity: **12,213 manifest checksum records**, covering **11,923
  unique preserved files/ZIP members**, pass. Renamed local copies and JSON
  members inside original ZIPs were verified against their recorded checksums;
  no source checksum was replaced to accommodate a different snapshot.
- All **1,300 protected prior assets/manifests** remain byte-identical. The
  historical published 2018 files are included in the preserved references.
- All twelve registry eligibility flags are unchanged; all five EU flags remain
  false. No release asset was uploaded. The package archive contains no Python,
  Parquet, Stata or local-source archive files.

The raw/canonical family validators and the current 2026 raw-output checks are
recorded separately below, with exact exclusions.

## Specific semantic checks

`consent` and `candidate_declaration` are logical; non-applicable means a missing
logical value with applicability false, never false consent/declaration. Unknown
means both values missing. Full output appends the new applicability fields
consistently after source/geography fields in both raw and canonical paths.
A targeted regression covers the column-order difference found during validation.

Referendum names are `yes`, `no`, `blank` in English/canonical, and `Ja`, `Nej`,
`Blank` in Swedish. Blank remains a valid voting option; invalid ballots are
separate. Literal official option IDs `JA`/`NEJ`/`BLANK` are retained.

`Handwritten votes` is the broad aggregate label. Missing party designation is
separate information. Party, person and geographic names, original node tags,
source identifiers and opaque view keys are not translated.

Ragunda candidate 534885 remains elected for SD, seat 3, from 2018-09-09 with
correction provenance 2018-12-12. Allocated seats remain unchanged. Unsupported
2018 canonical preliminary requests cannot silently return final results.

## Deferred clean production build

A clean committed production rebuild remains required after review and explicit
commit approval. Repeat manifest/code/source checks, byte comparison, language/
API checks, tests and package check with `build_tree_dirty = false` before any
publication decision. The old 2018 release must not be overwritten. Its successor
requires a separate version and matching new manifests/assets/checksums; current
configuration does not point to the old release as the new value contract.

No EU 2009 preference-vote allocation, candidate identity or election quantity
was changed. Its open source questions, EU 2004's aggregate limitation and EU
2024's candidate-1203 snapshot difference remain as previously documented.

## Reproducible validation evidence

Ignored local evidence is under `.local-data/value-standardization-20261020/`:
`asset-validation.csv`, `validate-reviewed.log`, `public-reviewed.log`,
`public-requests.csv`, `public-domains.log`, `extras-new.log`,
`source-checksums.csv`, `source-members.log`, `tests-final.log`, and
`package-check/swelections.Rcheck/00check.log`. The task-specific file list is
`this-task-files.txt`; it separates this work from the pre-existing uncommitted
performance, source-selection, history and 2018-correction changes.

## Existing 2026 source-validation boundaries

The preserved 2026 audit configuration has no complete RD/KF preliminary ZIP
collection. Those two raw selections are not claimed as executed. RF preliminary
is available. The existing KF elected-source check stops on Salem (0128), where
candidate 53411 has candidacy area 0120 but is joined into the 0128 allocation
context. This is the previously recorded source/scope question, not a category
translation error. No identifier was harmonised and no source check bypassed.
The current audit therefore checks elected RD/RF separately and leaves that KF
selection explicitly unverified. These boundaries do not concern the rebuilt
historical canonical products or justify changing their populations.

## EU 2009 validator follow-up

All 35 raw/canonical API variants passed before an independent validator
assertion stopped on its sex mapping. The original candidate XML reports
`Man`/`Kvinna` (291/209), not only `M`/`K`; current public `male`/`female` values
were correct. The independent mapping and its pooled-collection geography
comparison were updated for the new contract, without changing production data.
The remaining source checks, integration tests and all wrappers then passed:
500 ballot positions, 370,716 main-party district preference observations,
64,762 list controls, 18 elected and 68 substitute relations, 5,954 SCB units,
176 national/county preference controls, 866 small-party municipal controls and
5,664 electorate controls. The 1,983 small-party district cells and known
aggregate/candidate-column inconsistencies remain exactly source-reported.

A separate all-asset comparison also verified party labels in 136 assets:
all real party names are unchanged; only the two approved aggregate labels
were translated.

## Completed-panel and manifest checks

Sixteen representative nought-completed district panels were compared exactly
against the preserved pre-contract bases, with both languages. They cover
RD/RF/KF in 2010 and 2014, with/without list breakdown, plus the actual normalized
2022 component adapter for RF 01 and KF 0114. The largest tested 2022 panel has
2,812,016 rows. Values, row/column order, types and attributes match exactly after
the approved value presentation. These are representative completed panels,
not a claim that every nationwide zero-expanded Cartesian product was rebuilt.

The final manifest-only pass removes redundant JSON table `_row` selectors and
records current build-code checksums. It does not rewrite Parquet assets or
source inventories. The subsequent complete 194-asset checksum/size/round-trip
validation passes, and the current assets remain byte-identical to the first
normalized generation. Original approved references remain immutable.

## Mixed-year and source-snapshot checks

Multi-year unions normalize Boolean/applicability pairs before combining
canonical logical columns with raw character status fields. Single-year raw
intermediates and nested raw algorithms retain their existing contract until
presentation. Actual combined RD candidacy calls for canonical 2018 plus raw
2022 return 77,792 rows and match the separate-year outputs exactly, including
both languages. All seven EU functions also pass 28 actual multi-year checks
(five EU years together, both languages and detail levels).

The historical RKL comparison initially selected the older named 2018 research
candidate snapshot. Ten KF `ballot_info` strings there have trailing commas
(e.g. `19,` versus `19` in the official redacted snapshot used by the approved
canonical build). The old approved and newly normalized canonical values match
exactly. The continuation uses the build's official candidate snapshot, MD5
`9855ac4280c2a5165389a88c647ae49f`, in a separate validation root; neither original
snapshot is modified. This is a source-version difference, not a value-contract
translation or a justification for changing ballot text.

## EU 2024 validation continuation

All 41 raw/canonical API variants passed, together with primary JSON and mandate
checks. The Excel stage of the combined driver initially received an incorrect
local validation-root argument; the controls are under the preserved EU source
collection. Rerunning that independent stage with the correct root passes:
393,607 preference observations, 1,914,494 preference votes, and SCB controls for
6,275 ordinary districts and 6,565 ordinary/pooled collection units. Ballots cast
are 4,240,459 and valid votes 4,198,011. Control-file checksums remain unchanged.
This required no production-data change.

## Historical RKL raw/canonical matrix

All 600 comparisons pass: 2002 (84), 2006 (96), 2010 (108), 2014 (108),
2018 (96) and 2022 (108). These are 150 supported year/election/view selections,
each with four actual canonical calls (English/Swedish, standard/full), compared
with a full raw read and its detail/language projections. All applicable seven
public functions, district results and supported preliminary stages are covered;
unsupported 2002 candidacies and unsupported canonical 2018 preliminary requests
are not counted as successful data calls. Results, row/column order, types and
attributes match after the approved value presentation. The 2018 continuation
uses the exact official candidate snapshot described above.

Evidence: `rkl-raw-canonical.csv`, `validate-rkl-resume3.log`,
`official2018-source.log`. Earlier checkpoint logs are retained; they are not
misrepresented as uninterrupted passing runs.

## Current 2026 raw presentation checks

Eleven actual full raw selections pass, with English/Swedish and standard/full
projection and round-trip checks: candidacies (178,693 rows), seats (3,471),
substitutes (78,251), candidates (71,576), preference votes (153,537), elected RD
(349) and RF (1,720), district results for RD (95,759), RF (85,426) and KF
(84,764), and RF preliminary municipality results (3,228). These are eleven
source reads plus four presentation checks per selection, not 44 independent
source reads. The final domain scan also includes these current raw profiles.

The previously stated KF elected and RD/KF preliminary source boundaries remain
excluded. No source check was bypassed, identifier harmonised or election value
changed to obtain a pass. The implementation does not claim that unavailable or
source-rejected selections were successfully validated.

The final full test run is 4,633 passed, 16 skipped, zero failures/errors/warnings.
The checked package's R sources match all 102 current R files byte-for-byte;
`R CMD check --no-manual` finishes with zero errors, warnings and notes.
The complete source/protected-reference integrity checks, package-content check,
tracked and newly added file whitespace checks pass. No generated assets or raw
sources are tracked, no eligibility flag changed, and nothing was published,
committed or pushed. A clean committed production rebuild remains deferred.
