# RKL 2018: final-stage guard and corrected Ragunda result

This records the reviewed 20 October 2026 correction. Published `data-v0.1.0`
assets and all earlier build generations remain immutable. New files are a local,
unpublished prototype; no release/registry activation is changed.

## Counting stage

Both preserved 2018 XML and the existing 20 canonical assets describe final
results only. Explicit canonical dispatch previously ignored a preliminary
request. The shared dispatch now rejects non-final `results()`/`seats()` requests,
with the same semantics as the supported raw reader. This does not create or
claim complete 2018 preliminary data. The final party-vote values are unchanged.

## Ragunda, KF 2303, SD 0110, seat 3

[VPN 877-2018, 12 December 2018](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/valprovningsnamndens-beslut/mandatfordelning-inom-parti-bifall-forordnande_h6d34c8b78/)
orders a corrected SD candidate allocation treating Pehr Häggkvist as eligible.
The preserved 2022-10-31 history/current/expanded snapshots establish candidate
534885, seat 3, list `0110-17638`, position 3 and electoral start **2018-09-09**.
The correction date **2018-12-12** is separate provenance. The county's precise
implementing-decision date remains unverified and is not invented.

`R/correction_2018.R` applies this approved, scoped rule to parsed 2018 material.
It does not rewrite the raw ZIP or candidate CSV and imports no later membership
changes. The third original SD placeholder becomes candidate 534885; its order
3, comparison-number basis `J` and group `0` are retained. Three allocated seats
remain three; the unfilled count becomes zero. KF totals therefore become
12,679 elected and 21 unfilled, with 12,700 allocated unchanged. Existing other
members and substitute relationships are preserved; no successor is inferred.

A valid result-supported candidacy is added because the older candidate snapshot
omits the eligible candidate. Its list/position are from the corrected history,
not evidence of an originally printed ballot. Printed-ballot status, demographic
attributes and public name stay typed missing. Consent/eligibility follow the
appeal decision. Public historical names remain `NA`, as before.

The decision also establishes **five preference votes in Stugubyn (23030409)**:
four handwritten name ballots and one party ballot. The candidate's area and
district observations and candidate/elected enrichment include these five votes.
It does not identify the original ballot-list numbers. Consequently the original
validated list-specific preference rows are preserved; no five-vote allocation
is fabricated for either list 15437, history list 17638 or generic list 90000.
The list-specific view is five votes lower than the corrected non-list view for
this candidate/area. This is a precisely scoped unavailable list allocation,
not a change in party votes or an inference about person identity.

## Provenance and reproduction

The manifest retains the original three source hashes and adds `corrections`
with decision URL, decision-snapshot SHA256, the three corroborating snapshot
names/hashes, electoral start, correction date, scope and unavailable list
allocation. Snapshot filenames identify preserved local official exports; a
missing original download URL is not invented. The original source archive and
redacted candidate snapshot remain the pinned build inputs.

Build into a fresh directory rather than overwriting published references:

```r
# Shell commands run with Rscript from the repository root:
# Rscript data-raw/build-canonical-2018.R RAW_ROOT OFFICIAL_CANDIDATE_FILE STAGE_DIR
# Rscript data-raw/export-canonical-parquet-2018.R STAGE_DIR OUTPUT_DIR
```

The corrected build must be compared to the frozen 20-asset reference and to
fresh raw-path outputs, including all seven public functions, geographic views,
list/zero-completion variants, English/Swedish and standard/full projections.
Checks must explicitly allow only this documented correction. The stage guard
alone must not change a final asset.

The implementation is intentionally uncommitted during review. A build including
it truthfully records `build_tree_dirty = true`; it cannot also be described as
built from a clean production commit. A clean-commit reproduction and a new data
release version remain required after review, before publication. Never replace
the existing published `data-v0.1.0` files in place.

## Completed working-tree validation

The separate prototype contains **20 Parquet assets, 40,694,236 bytes**.
Eight assets change; twelve are byte-identical to `2018-clean-aab7c87`.
All three party-result assets and the entire substitutes asset are unchanged.
Each pre-existing row in the eight changed assets is identical after removing
candidate 534885 and restoring the one original vacancy field. Row order,
column types and missingness of all other observations are preserved.

| Changed asset | Before rows | After rows |
|---|---:|---:|
| `rkl2018-seats` | 4374 | 4374 |
| `rkl2018-candidacies` | 184197 | 184198 |
| `rkl2018-candidates` | 72255 | 72256 |
| `rkl2018-elected` | 14723 | 14724 |
| `rkl2018-preference-votes-base-area-kf` | 129275 | 129276 |
| `rkl2018-preference-votes-area-kf` | 262335 | 262337 |
| `rkl2018-preference-votes-base-district-kf` | 1224345 | 1224346 |
| `rkl2018-preference-votes-district-kf` | 1006364 | 1006365 |

Preference assets contain multiple labelled views/components; their physical
row counts are not additive vote totals. The candidate-level correction is
five votes, represented once at each applicable geographic level.

- Fresh raw-path RDS outputs: all nine objects match the frozen reference
  after only the documented correction is accounted for.
- Public API: 168 exact comparisons covering all seven functions, all 17
  result geographies, RD/RF/KF, English/Swedish and standard/full, plus list
  and area-completion variants. Ragunda district completion is also checked
  separately, with and without list output.
- Existing 2018 canonical integration: 713 assertions passed, one explicit
  skip for the optional repeated direct XML sweep. The build itself already
  freshly parsed the complete XML and the staged outputs were compared.
- Full test suite: 4,539 passed; 16 explicit skips; no failures or warnings.
- `R CMD check`: zero errors, warnings or notes.
- All 20 new asset hashes, sizes, schemas, layouts and Parquet round-trips
  passed, including the build-code and correction-evidence checksums.
- Cross-year/family regressions: 840 exact comparisons passed.
- Integrity: 9,529 pinned source-hash checks passed; 1,279 pre-existing
  protected Parquet/manifest files, including all EU generations, unchanged.
- `git diff --check` passed; no raw/canonical assets were added to tracking.

The reviewed code changes are the shared 2018 stage guard, the scoped
`R/correction_2018.R` adapter, its hooks in the 2018 candidacy/XML/person-vote
readers, a targeted regression test, optional separate stage-directory support
in the existing builder and expanded exporter build-code provenance. No new
public schema, API, election identity, release or source-selection design
is introduced. Existing unrelated working-tree changes remain intact.

The new manifest records HEAD `39622e7b3e2a37c4b35c272f03fb6535734d9e8f` and
`build_tree_dirty = true`. A clean production-commit rebuild remains pending;
it was not simulated or falsely labelled clean under the no-commit constraint.
