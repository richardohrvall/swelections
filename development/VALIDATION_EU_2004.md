# EU 2004 implementation validation

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


The R-only adapter uses pinned original final XML,30 official district/list
exports,20 complete named preference exports, the definitive ballot ZIP, the
original Katrineholm municipal XML for the zero Wednesday unit, and the SCB
municipal electorate-composition workbook. Required raw-build readers `readxl`
and canonical-build writer `nanoparquet` are existing optional project
 dependencies. Independent SND validation additionally uses existing `haven`.
No Python or network download is required for a preserved-source build.

The final outcome is checked against the recovered 17 June 2004 decision and
appendices. In particular appendix1 establishes both party and preference
totals, and appendix3 independently specifies the elected/substitute roster.
Preserved protocol URLs and checksums are in
`data-raw/eu2004-validation-sources.csv`; raw PDFs remain outside Git.

## Reproduction

From the repository root, with the documented R library and preserved raw root:

```r
# Shell commands, using the project's Rscript executable:
# Rscript data-raw/build-canonical-eu-2004.R RAW_ROOT EMPTY_OUTPUT_DIR
# Rscript data-raw/validate-eu-2004.R RAW_ROOT OUTPUT_DIR RAW_ROOT/eu/2004
```

The builder creates14 English schema-version 2 Parquet assets and `manifest.json`.
They remain an unpublished prototype, are not auto-eligible and are never added
to Git. The manifest records the actual Git SHA/dirty state, source SHA256/MD5,
source URLs, sizes, selection rules and every asset's size/SHA256. Each asset is
read back and checked with `identical()` immediately after writing.

Independent validation reads the text/XML sources directly rather than using
production normalisers. It checks all85,349 list totals and282,901 reported
preference rows, source ballot positions, fixed relations, aggregate geography,
SCB workbooks and SND district/municipality controls. API validation covers all
seven functions, all supported levels, list/zero switches, standard/full,
English/Swedish, and raw/canonical equality.

## Source-specific findings

- All943 residual valid votes are retained as a single reported other-party
  category per geography. The presentation explains that these are handwritten
  votes for parties which did not order ballots; no individual designation is
  disclosed. They are not placed on an invented ballot or candidate.
- Protocol-supported SD preferences are14,450. SCB SSD ME0109T08 incorrectly
  reports zero nationally and in269 positive municipalities, while its official
  total1,480,960 is correct. No source values are changed to reproduce the zeros.
- The original FP August archive capture is truncated; the pinned complete
  November capture is used. Its non-name values match the surviving complete
  export and all list controls.
- Heby's historical code1917 is preserved. Modern SCB API code0331 is only a
  documented validation crosswalk, never substituted into the historical result.
- Wednesday electorate and turnout are missing by design. The explicit zero
  Wednesday unit E-0483-02 is retained as a reporting unit.
- Candidate/list keys do not identify physical persons. Ballot position and
  preference rank are distinct source concepts. Unsupported attributes remain NA.
- A complete preliminary Wednesday snapshot has not been recovered. Election
  night is provenance, not an exposed complete preliminary stage.

## Execution results

Completed against the current uncommitted implementation:

- **All35 public variants x 4 names/detail combinations passed** raw/canonical equality, row/value/type preservation and standard/full projection.
- All seven Swedish wrappers passed the equivalent language/detail comparisons.
- Independent checks passed for 85,349 list totals, 282,901 positive district preference observations, 382 ballot positions, 19 elected and 71 expanded substitute relations.
- SCB checks passed for 312 aggregate areas,347 small-party cells and176 national/county mandate-party preference counts. Protocol-supported national party/preference totals match exactly.
- SND checks passed for 5,875 ordinary districts and 290 municipal summary records.
- The dedicated EU2004 test file passed 54 assertions with preserved sources enabled and no skips/errors/warnings.
- Full suite: **3,657 passed, 16 explicit skips, 0 failures, 0 errors, 0 warnings**. The EU2004 opt-in skip was separately rerun with preserved inputs, as above.
- **R CMD check --no-manual --no-vignettes: 0 errors, 0 warnings,0 notes.** Windows initially failed while copying long paths inside already excluded local archives; the successful check used an exact SHA256-verified staging copy of intended package files. Package contents were checked against the current source; raw/canonical/Python material is absent.
- All 14 Parquet write/read round trips passed with `identical()`; all manifest asset sizes/SHA256 and all 54 pinned build-source hashes passed.
- All 41 original local source files and 1,090 previously existing historical Parquet files are byte-unchanged after validation. No EU2009 treatment was changed.
- `git diff --check` passed; no raw sources or generated assets are tracked.

Prototype directory: `.local-data/canonical-build/eu-2004-prototype`. Total Parquet size: **2,188,439 bytes**. Schema version 2; unpublished, not auto-eligible.

Build commit: `4dd88b156b1b78fe85801c2ea3175e8902e7363a`; **build_tree_dirty = true**, correctly recording the review-stage implementation. A clean-commit release build has not been claimed or published.

| Asset | Rows | Bytes |
|---|---:|---:|
| `eu2004-results-final.parquet` | 184841 | 932102 |
| `eu2004-seats-final.parquet` | 9 | 9649 |
| `eu2004-candidacies.parquet` | 382 | 21480 |
| `eu2004-candidates.parquet` | 382 | 17765 |
| `eu2004-elected.parquet` | 19 | 9916 |
| `eu2004-substitutes.parquet` | 71 | 7735 |
| `eu2004-candidate-base.parquet` | 382 | 13663 |
| `eu2004-source-designations.parquet` | 660 | 3346 |
| `eu2004-preference-base-area.parquet` | 464 | 7187 |
| `eu2004-preference-base-national.parquet` | 464 | 7187 |
| `eu2004-preference-base-county.parquet` | 6455 | 24141 |
| `eu2004-preference-base-municipality.parquet` | 48020 | 115725 |
| `eu2004-preference-base-municipal-constituency.parquet` | 39432 | 87843 |
| `eu2004-preference-base-district.parquet` | 540808 | 930700 |

Source URLs, available retrieval timestamps, archive captures and SHA256 are also
retained in `data-raw/eu2004-source-provenance.csv`. Unknown original local
retrieval dates are explicitly missing; source modification dates are not passed
off as retrieval dates. No commit, push, tag or release was made.
