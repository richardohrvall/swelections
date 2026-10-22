# EU2014 validation

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


The implementation and unpublished local build use the pinned preserved original
Valmyndigheten XML, headerless ballot-candidacy file, electorate file and
handwritten-detail SKV. No original source is edited. English/Swedish use the same
implementation; only output column names differ. Schema version remains 2;
`source_votes_without_party_designation` is a source-specific full-only field.

## Reproduce

From the repository root using the documented R dependencies:

```sh
Rscript data-raw/build-canonical-eu-2014.R RAW_ROOT EMPTY_OUTPUT_DIR
Rscript data-raw/validate-eu-2014.R RAW_ROOT OUTPUT_DIR CONTROL_DIR
```

`CONTROL_DIR` contains the independently preserved SCB control files from the
inventory (`scb-preference-2014.json`,`scb-candidate-overview.xlsx`,
`scb-electorate.xlsx`). The API query and source URLs/hashes are preserved in
the source-inventory evidence ledger. No live network is needed for this sweep.
All raw files and generated assets remain outside Git.

`data-raw/validate-eu-2014-sources.R` parses the original XML independently of
production normalisers and checks every named party/geographic record and every
reported district/list/candidate observation. It checks original candidate IDs,
ballot positions, elected order/basis and group-expanded substitute relations.
It also compares all 3,770 SCB municipality preference categories/totals, 376 nominees,
20 elected and 22 electorate-composition totals.

The public sweep covers all seven functions; five result levels; national seats;
candidate result enrichment on/off; six preference levels with list/zero variants;
standard/full and English/Swedish; actual Swedish wrappers; source/asset checksums;
manifest coverage and Parquet round-trip. Unsupported full preliminary requests
must fail rather than substitute election night or final Wednesday results.

## Source controls and exact unresolved items

- Final valid 3,716,778; cast 3,758,951; blank-invalid 38,935; other-invalid 3,238;
  eligible 7,359,962.
- 5,837 ordinary+390 Wednesday units; 290 municipalities; 21 counties;
  181 real municipal constituencies.
- All 402,053 positive reported list/candidate/unit observations sum to 1,859,375.
  All 376 national candidate sums reconcile; no missing candidate/list-position join.
- 20 allocated/20 elected/zero unfilled; 30 distinct substitutes/74 expanded relations.
- Handwritten source detail 5,608 plus exactly 10 unidentified votes at 05803201
  equals the XML residual 5,618. The ten remain valid votes in the source category.
- No political-party identity is inferred from the 890 source label spellings.
- Modern unsupported candidate attributes remain missing. Physical-person
  linkage, preliminary Wednesday coverage and full term history are not asserted.
- Preserve the known current-XML redaction of geographic labels; build from the
  named-geography original. No other historical output/assets may be rebuilt.

Final executed results and build metadata are recorded below after validation.

## Local prototype inventory

Build directory: `.local-data/canonical-build/eu-2014-prototype/`.
Unpublished data version `data-v0.0.0`, English schema version 2, auto eligibility FALSE.
Build commit: `140d1da45dcb0538499f8087666af032ec0236e4`; `build_tree_dirty = true`. This is an uncommitted validation prototype, not a clean release build.
Fourteen Parquet assets, total **3,767,830 bytes**. Every file round-trips exactly; manifest records sizes, SHA256 and pinned source checksums.

| Asset | Stored rows | Bytes |
| --- | ---: | ---: |
| `eu2014-results-final.parquet` | 83879 | 2212350 |
| `eu2014-seats-final.parquet` | 10 | 9650 |
| `eu2014-candidacies.parquet` | 376 | 14924 |
| `eu2014-candidates.parquet` | 376 | 14010 |
| `eu2014-elected.parquet` | 20 | 9631 |
| `eu2014-substitutes.parquet` | 74 | 6989 |
| `eu2014-candidate-base.parquet` | 376 | 9819 |
| `eu2014-source-designations.parquet` | 4494 | 26332 |
| `eu2014-preference-base-area.parquet` | 481 | 6713 |
| `eu2014-preference-base-national.parquet` | 481 | 6713 |
| `eu2014-preference-base-county.parquet` | 7741 | 33690 |
| `eu2014-preference-base-municipality.parquet` | 62428 | 177583 |
| `eu2014-preference-base-municipal-constituency.parquet` | 47190 | 140104 |
| `eu2014-preference-base-district.parquet` | 570910 | 1099322 |

Stored preference-base row counts combine component tables identified by `.table`
and are not counts of candidate preference observations. The latter are exactly
402,053 reported positive district/list/candidate observations. Source-designation
rows are provenance detail, not additional result rows to add to the main totals.

## Executed validation results

- All **35 public request variants x 4 English/Swedish and standard/full combinations**
  passed exact canonical/raw equality (140 paired comparisons), including all seven
  functions, five result levels, six preference levels, by-list and zero completion.
- The largest zero-completed district output has **2,049,898 rows**. Both list
  variants pass; the positive-only source population remains 402,053 records.
- Standard is a projection of full with identical shared values, types, keys and
  row counts; output naming is independent of detail.
- Independent XML checks pass at all public geographic levels and for every
  reported preference observation,69,398 district list controls, and all original
  elected/substitute relationships. National list controls also pass in the reader.
- All 3,770 SCBmunicipal preference cells,376 nominees/20 elected and 22 electorate
  controls pass. Every candidate key, ballot position, age, sex and ballot text is
  verified against the original file; unsupported validity/consent stay missing.
- The monolithic sweep completed with no warnings or value differences;
  the opt-in EU2014 test file passed **56 assertions, zero skips**. All seven
  actual Swedish wrappers match their English counterparts in all four modes.
- Actual three-year 2014/2019/2024 calls, all/from-to selection and EN/SV projection
  pass for all seven functions. 2019/2024 slices equal separate frozen-reference
  calls. Raw multi-year candidacies total 2,333 records.
- Full package suite: **3,571 passed,14 explicit opt-in skips, zero failures,
  errors or warnings**. The targeted EU2014 source suite above runs without skips.
- Final `R CMD check --no-manual --no-vignettes`: **0 errors,0 warnings,0 notes**.
- All 14 Parquet assets round-trip exactly; manifest sizes/SHA256 agree.
- All 12 original EU2014 source hashes and protected historical/EU assets remain
  unchanged, including the published 2018 release. No raw/canonical files are tracked.
- Independent-validator node-vector/ancestor-role errors found during development
  were corrected without changing production values or relaxing comparisons.

The ten-vote party-designation gap in the inspected source material concerns the valid
Vårdsberg votes. All other specified missing attributes, unverified identity and
unrecovered preliminary/term-history coverage remain explicit in
[COMPLETENESS_EU_2014.md](COMPLETENESS_EU_2014.md). No commit, push, tag or release.


## Approved-scope rebuild (16 October 2026)

A fresh build in `.local-data/canonical-build/eu-2014-reviewed-20261016/`
reproduces all 14 prototype Parquet assets byte-for-byte: 3,767,830 bytes,
identical filenames, schemas, rows and SHA256 checksums. No historical asset
was replaced. The per-file comparison is retained locally as
`reviewed-asset-comparison.csv` with the implementation validation logs.

The build uses commit `140d1da45dcb0538499f8087666af032ec0236e4` plus the
uncommitted implementation and truthfully records `build_tree_dirty = true`.
A clean output directory is not a clean Git commit. A clean-commit release
rebuild remains a subsequent step after approval to commit; this task makes
no clean-tree claim and publishes nothing.

The full test suite again passes 3,571 assertions, with 14 explicit opt-in skips
and no errors, failures or warnings. `R CMD check --no-manual --no-vignettes`
again reports Status: OK (0 errors, 0 warnings, 0 notes). Protected historical
assets and all 12 original EU2014 source hashes are unchanged. The separate
SCB controls again pass for all 22 national/county rows (including the correctly
grouped other-party residual) and all 362 disclosed municipal small-party values.
SCB's 0.5% municipal publication threshold does not identify the ten Vardsberg
votes. All seven multi-year APIs and unchanged 2019/2024 slices pass again.

The fresh-build monolithic validation also passed all 140 paired public
canonical/raw comparisons, the independent XML/SCB checks, all 56 opt-in
regression assertions and all seven actual Swedish wrappers in four modes,
without warnings or value differences. Manifest sizes/SHA256 and exact Parquet
round-trips pass. No further source recovery or production-code changes were
needed for this finalization. No commit, push, tag or release was made.
