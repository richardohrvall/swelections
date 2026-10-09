# 2010 preliminary reporting integration

## Scope and source selection

This is an unpublished working-tree prototype. No commit, push, tag, release or published canonical asset was changed.

Preliminary results combine the ordinary `VALDISTRIKT` nodes of the preserved `valnatt.zip` with the separately preserved official preliminary collection HTML in `preliminary-collection-preservation-20261009`. Supplementary aggregate metadata use the earlier `preliminary-presentation-20261008` cache. The new source-manifest SHA256 is `576bb2c1cc2d5f88bedb4c628cc014852e0333d45670579df1db4206b3d36fd6`.

Final XML supplies collection geography and official code relations only in this reader. No final collection vote value fills a preliminary blank. All sources remain unchanged.

## Verified source-level results

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Ordinary election-night districts | 5,668 | 5,629 | 5,668 |
| Preliminary collection districts | 395 | 392 | 395 |
| Unique districts in preliminary output | 6,063 | 6,021 | 6,063 |
| Completely unreported collection districts | 0 | 9 | 9 |
| Partially reported collection pages | 179 | 292 | 251 |
| District party rows | 54,567 | 63,574 | 62,613 |
| Independent aggregate comparisons | 320 | 381 | 366 |
| National preliminary total votes | 6,027,252 | 5,927,840 | 6,007,976 |

All 1,067 aggregate comparisons match the official preliminary presentation. All ordinary district keys match the election-night XML exactly; collection districts have distinct keys, with no double counting. All 1,182 collection pages are checked against their district output.

The 18 completely unreported pages retain `counted = FALSE` and `NA` for relevant current/previous vote counts, shares and changes. Their municipality/constituency suffixes are `0604-00`, `0780-01`, `0780-02`, `0781-00`, `1784-00`, `2401-00`, `2403-00`, `2480-01` and `2480-02` in both RF and KF.

All 722 partially reported pages retain the available category counts. The source comparison also verifies 4,213 blank current/previous category-count cells as `NA`, and checks explicit party-vote changes against the HTML. Reported changes are preserved even where a comparison count is blank; a blank change is never manufactured as zero.

Aggregates are reported/counting-status totals, not estimates of eventual final totals. They sum available reported categories. Wholly unknown sums stay `NA`. At district level, totals require known components. Explicit preliminary aggregate metadata are retained and checked against reported sums.

## Implementation and unchanged behaviour

- `R/preliminary_2010.R`: year-specific R HTML adapter, snapshot aggregate metadata and geographically scoped election-night party abbreviation lookup.
- `R/valresultat_2014.R`: year-specific delegation, complete collection inventory, reported-state aggregation and `counted` handling; existing 2014 aggregation semantics are retained.
- `R/api_valresultat.R` / `man/valresultat.Rd`, README, NEWS and 2010 implementation/provenance documents describe the reporting snapshot.
- `tests/testthat/test-preliminary-2010.R`: deterministic reported/blank/explicit-zero, all-unreported, raw change and scoped party-lookup regression tests (23 assertions).
- `DESCRIPTION`: declares the test-only `withr` dependency already used by test helpers; no new runtime dependency or Python runtime.
- Build/validation tooling now includes preliminary RD/RF/KF and source-cell/aggregate checks.

Candidate/person-vote handling and candidate-ID rules are unchanged. Seven unresolved identity cases remain unresolved. All 21 previously validated final/candidate/person-vote Parquet assets are byte-identical to the previous prototype.

## Prototype and integrity

Directory: `.local-data/canonical-build/2010-prototype-preliminary-validation-v2`.

24 English-schema Parquet assets plus `manifest.json`; total Parquet size 45,573,472 bytes. The three additions are `rkl2010-results-preliminar-rd.parquet`, `rkl2010-results-preliminar-rf.parquet` and `rkl2010-results-preliminar-kf.parquet`. All 24 write/read round trips are exact.

The manifest pins 2,546 build inputs, schema version 2, unpublished data version `data-v0.0.0`, and a dirty working-tree build. Manifest SHA256: `e6e5617fcca0d407d2c10350f92742ed7a1e84864ccc5d182a3a2f1a6f741615`.

Integrity checks: 39 original source files unchanged; 2,535 preserved preliminary HTML responses have matching sizes/MD5/SHA256; all manifest input hashes and asset sizes/SHA256 match; the previous prototype's 22 files are unchanged. No published canonical assets were rebuilt.

## Package validation

- Full ordinary suite: 3,198 passing assertions, no failures or warnings, 10 explicit opt-in skips.
- `R CMD check --no-manual --no-vignettes`: 0 errors, 0 warnings, 0 notes; staged package build excludes ignored source/prototype archives.
- `git diff --check`: passes.
- Full public canonical/raw sweep: COMPLETE, 85 passing check blocks, zero discrepancies and no warnings. Covers all seven functions, RD/RF/KF, 17 result levels for both preliminary/final, all person-vote list/zero combinations and RF/KF parent aggregates, standard/full projections, English/Swedish output and Swedish wrappers, keys, types and missingness. The detailed machine-readable report is `.local-data/canonical-build/2010-validation-all.json`.

Source limitations are deliberately represented rather than repaired: the 18 unreported districts and individual blank categories remain missing. Previously documented final-source/candidate limitations are unchanged.
