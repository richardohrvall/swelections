# EU 2019 validation

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


Validation uses the pinned official original XML and complementary official
handwritten-party and final-compatible electorate files. Sources remain unchanged.
No election-night recovery or mandate-period reconstruction is included.

## Results

- All seven functions: raw/canonical identity for 41 supported variants, each in
  English/Swedish column names and standard/full detail (164 exact table pairs).
- Standard is an exact projection of full, with identical rows, keys, types and
  shared values. All seven actual Swedish wrappers also pass four name/detail
  combinations. Multi-year/all/from-to calls pass for 2019/2024.
- Independent XML checks cover country, 21 counties, 290 municipalities, 53
  actual municipal constituencies and all 6,305 ordinary/Wednesday units in
  both counting stages, including all direct/nested XML party cells.
- All 410,308 positive district/list/candidate preference observations match
  independently parsed IDs, lists, counts and ballot positions. The 78,291
  district list totals pass; national totals are 1,634,596 preference votes.
- Original 20 elected IDs, parties, election order, basis codes and national
  elected geography match XML. The 27 substitute IDs generate exactly 74
  source-group relations with matching party/order. No later Brexit seat is added.
- Official Excel controls pass for all 6,305 districts and 290 municipalities,
  including every disclosed party column. Sparse numeric columns are read
  explicitly as numeric rather than silently inferred as logical.
- SCB controls pass for 5,984 ordinary districts, 290 merged Wednesday totals,
  country/county aggregates and electorate composition. SCB nominated/elected
  controls match 556 valid candidacies and 20 elected candidates.
- Fresh electorate SKV matches all 5,984 XML district electorates. The older
  snapshot with 983 extra voters is excluded. All 321 Wednesday units retain
  NA electorate/turnout; no downward allocation is made.
- All 15 Parquet files pass exact data/type round-trip and manifest size/SHA256
  checks. The six selected source files and the preserved inventory originals
  and acquisitions pass integrity checks.
- All seven EU 2024 APIs still match the previous clean canonical reference in
  both languages and detail levels. Protected clean historical assets remain
  unchanged; no RKL/referendum normalisation was changed.
- Package suite: 3,524 assertions passed, zero failures/warnings, 13 explicitly
  opt-in skips. The maintained 2019 validator explicitly runs its preserved-source
  regression with no skips. R CMD check --no-manual --no-vignettes: 0 errors,
  0 warnings, 0 notes. git diff --check passes.

The initial embedded test runner exposed caller-name shadowing and a relative
archive path after testthat changed directories. The test/tooling harness now
uses explicit namespace lookup, an absolute archive path and explicit error
accounting. Its affected opt-in regression was rerun against fresh raw sources;
these harness failures did not reveal or require any election-data correction.

## Source distinctions

All 7,455 preference votes reported on three invalid candidacies remain in
preference output. They are excluded from the valid candidates() population,
whose total is 1,627,141; they are never reassigned across parties sharing an ID.
Complete preliminary output preserves ten named parties and the other-party
aggregate. The final handwritten-party supplement replaces its matching XML
residual, never adds to it and never enriches the preliminary snapshot.
Public names are NA because the current official file is redacted; this is
not an absent candidacy/preference observation or a reason to infer identity.

## Reproduction and clean-build gate

```text
Rscript data-raw/build-canonical-eu-2019.R RAW_ROOT EMPTY_OUTPUT_DIR
Rscript data-raw/validate-eu-2019.R RAW_ROOT OUTPUT_DIR INDEPENDENT_CONTROL_DIR
```

The reviewed working-tree prototype is unpublished, schema version 2, data
version data-v0.0.0, and correctly records build_tree_dirty=true. After the
authorised code commit, rebuild into a new directory, require the exact HEAD SHA
and build_tree_dirty=false, and compare every Parquet SHA256 with the reviewed
prototype before pushing. Manifest build SHA/time/tree status intentionally
change; election data and all Parquet bytes must not. Clean-build logs and the
checksum comparison ledger remain local. No tag/release is created.

## Asset inventory

| Asset | Rows | Bytes |
| --- | ---: | ---: |
| eu2019-results-final.parquet | 94900 | 2411592 |
| eu2019-seats-final.parquet | 10 | 9654 |
| eu2019-results-preliminary.parquet | 73370 | 2143427 |
| eu2019-seats-preliminary.parquet | 10 | 9648 |
| eu2019-candidacies.parquet | 562 | 20723 |
| eu2019-candidates.parquet | 556 | 17941 |
| eu2019-elected.parquet | 20 | 9790 |
| eu2019-substitutes.parquet | 74 | 7035 |
| eu2019-candidate-base.parquet | 556 | 13375 |
| eu2019-preference-base-area.parquet | 701 | 8368 |
| eu2019-preference-base-national.parquet | 701 | 8368 |
| eu2019-preference-base-county.parquet | 9823 | 42981 |
| eu2019-preference-base-municipality.parquet | 72636 | 209184 |
| eu2019-preference-base-municipal-constituency.parquet | 18314 | 61702 |
| eu2019-preference-base-district.parquet | 601295 | 1179476 |

Total: 6153264 bytes across 15 Parquet files; manifest stored separately.

See [COMPLETENESS_EU_2019.md](COMPLETENESS_EU_2019.md) for exact status and
schema decisions, and [SOURCE_INVENTORY_EU_2019.md](SOURCE_INVENTORY_EU_2019.md)
for source URLs, checksums, acquisition history and scope exclusions.
