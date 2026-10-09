# 2010 implementation and validation (unpublished working prototype)

Identity adapter committed separately: `65bdb1f8e7cc64bd066dbbfaa5eaa07af8c6d62e`. No push, tag or release. The subsequent 2010 readers and normalisers remain uncommitted.

## Sources and roles

The complete original 39-file inventory, ZIP contents, sizes, MD5 and SHA256 are recorded in `2010_SOURCE_INVENTORY.json`. All 39 original files were checked again: zero modifications.

| Source | Role |
|---|---|
| `valresultat/slutresultat.zip` | Fixed ordinary 2010 final result: 872 XML members, election date 2010-09-19, reporting snapshot 2010-10-07. Primary results, seats, person votes, elected and substitute relations. |
| `valresultat/valnatt.zip` | 872 election-night XML members; ordinary districts, not a full preliminary result. |
| `kandidater/alkandur_R/L/K.skv` | Documented ballot candidacies; 23,216 / 87,066 / 88,260 rows, positional Latin-1 layouts of 12 / 14 / 16 fields. |
| `partier_som_anmalt_kandidater.txt` | UTF-8, scoped official party codes for ballot lists with no observed result list. Not candidate validity or individual consent evidence. |
| Original elected-member SKV and byte-identical copy | Independent election-result validation. Four known KF source-ID discrepancies are retained, not harmonised. |
| Current members, departures and current unfilled-seat files | Mandate-period research/validation only; never expand the fixed election population. |
| Final district/municipality vote SKV | Independent party-vote and geographic validation. |
| `fastamandat_ri/lf/kf.csv` | Independent fixed-seat calculations. |
| Mandate Excel | Independent snapshots; RF county 14 and KF 188004 incorporate later re-election outcomes and cannot replace ordinary 2010 XML. |
| RD person-vote SKV, electorate and voting-location files | Additional independent validation material. |

Final ZIP MD5: `e758499f800cfbc49ce02c54c3d1dd79`.
SHA256: `2d598343995a387a8cd1e57520d5d39e1dd2b767ec6b837ef59f50a85485bc7b`.

### Preliminary reporting snapshot

The earlier 365-page cache has been supplemented by a complete 2,170-page preserved preliminary reporting snapshot (see PRELIMINARY_2010_SOURCE_RETRIEVAL.md). It covers 395 RD, 392 RF and 395 KF collection districts. Preliminary results combine ordinary election-night XML with these separate HTML collection reports. All collection districts remain represented: nine RF and nine KF pages have entirely blank numerical tables and remain unreported/NA; 722 otherwise reported pages contain blank category cells, retained as NA. Final collection XML supplies only the geography required to locate a page, never its preliminary vote values. `election_night` remains non-public. Aggregate results describe the published reported-vote snapshot rather than a complete eventual count.

### Supplementary official party-ID metadata

The comparison-only ASK party in Sigtuna lacks a 2010 list-prefix ID. Official 2006 ballot XML identifies it as 0340. A separate derived party-ID metadata CSV and provenance JSON pin the original 2006 ZIP and contain no imported votes, candidate records or names. The original 2006 ZIP remains unchanged.

Two other same-name party pairs require geographic identity rather than global name matching: ALT 0200 / ALTER 0510 and FKL 0533 / FRK 0079. The 2010 adapter now resolves scoped source identifiers and then unambiguous source abbreviations; dedicated tests cover all four. This fixes the discovered duplicate national result key without changing any source vote value.

## Implementation and semantics

- One R-only ZIP/read/ballot adapter, `R/xml_2010.R`; shared 2014/2018 normalisers, output projections and canonical backend reused.
- Seven functions support the 2010 final source through local raw data and an explicitly configured unpublished canonical manifest. No published auto-eligibility is added; historical remote/update/archive requests do not silently select a different snapshot.
- Candidate population = ballot candidacies plus identified final person-vote, elected and substitute evidence. No names are used for candidate joins. Public historical candidate names are typed `NA_character_`; unsupported validity/consent fields stay missing.
- Repeated official PERSONVAL records are consolidated additively by official candidate key. Area and district sources are not added together.
- Bjorn RF raw 451964 resolves to canonical 442089 before joins. The previously documented RD ballot linkage 497359 is restricted to party 0003 / constituency 03 / list 03600 / position 22. Provenance retains the original IDs. No other identity harmonisation is enabled; seven weaker pairs remain unresolved. The raw-source candidate outputs show canonical 442089 in RD/RF/KF, with person-vote totals 10 / 8 / 25; no duplicate 451964 or 497359 remains.
- Nine KF unfilled seats are preserved as unfilled; no candidate is fabricated.
- English/Swedish standard/full schemas retain the established public contracts. No Python package runtime dependency: Python scripts are development/source-validation aids only.

## Independent results

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Documented ballot candidacy rows | 23,216 | 87,066 | 88,260 |
| Extended population rows | 23,216 | 87,225 | 89,144 |
| Candidate keys | 5,677 | 12,068 | 52,015 |
| Positive candidate person-vote totals | 5,438 | 11,923 | 48,513 |
| Zero candidate totals | 68 | 92 | 3,492 |
| Missing candidate totals | 171 | 53 | 10 |
| Elected observations | 349 | 1,662 | 12,969 |
| Substitute relations | 1,493 | 9,519 | 73,722 |
| Unfilled seats | 0 | 0 | 9 |
| Official area candidate person-vote sum | 1,494,924 | 1,422,296 | 1,848,627 |
| Matching district SKV party cells | 64,844 | 64,749 | 60,306 |
| Matching fixed-mandate areas | 29 | 94 | 395 |

Elected IDs, party, election geography, order, election basis/group and all substitute relation keys match independently extracted final XML exactly. District party-vote comparisons have zero numerical differences. Collection codes are matched through the official municipality/constituency relation: XML R/L/K-<municipality>-<constituency>, SKV 0001 (RD) or VK01 (RF/KF). Numeric SKV party codes are zero-padded, never name-guessed.

SCB ordinary-election person-vote totals match all three elections exactly: [RD, table 11](https://www.scb.se/contentassets/b485269e93864392b0640b8b8c6b1c28/me0104_2010a01_br_me01br1101.pdf), [RF, table 10](https://www.scb.se/contentassets/a00250031a1543a4ae0512101861df9b/me0104_2010a01_br_me02br1101.pdf), [KF, table 9](https://www.scb.se/contentassets/35b0b096633d414e818d0bac3d02d396/me0104_2010a01_br_me03br1101.pdf). SCB is validation only. Modern SCB tables may include 2011 re-elections; no individual records are manufactured to force population agreement.

The mandate Excel has zero RD differences, 16 RF cells in county 14, and two KF cells in 188004 (M 3 versus XML 4; S 8 versus XML 7). These are the 2011 re-election scopes. SCB Del 3, table 14, confirms the exact KF change (M 4 to 3, S 7 to 8). The RF cell pattern is recorded as a later snapshot difference in the corresponding re-election scope; no original votes or seats are overwritten. The files have later filesystem timestamps, not authoritative election-time version metadata. Detailed cells are retained in `.local-data/2010-source-validation.json`; the ordinary final XML is unchanged.

Candidate `NA` totals (171/53/10) retain the shared conservative rule where relevant party/candidate coverage cannot be verified; positive observed source records remain present in preference-vote views. No absent party node is silently converted to zero. The known four KF XML/member ID pairs and seven weak cross-election pairs remain documented source-identity limitations.

## Validation completion

- Standard suite after party/prefix fixes: 3,175 passes, zero failures/warnings, 10 explicit opt-in skips.
- Preserved-source identity audit: 930 passes, zero failures/warnings/skips. All 16 RF transformations are 451964 to 442089 only.
- `R CMD check --no-manual --no-vignettes`: 0 errors, 0 warnings, 0 notes (staged source build excludes ignored raw/prototype archives).
- `git diff --check`: passes.
- Original raw-source integrity: 39/39 MD5 and SHA256 unchanged; build also hashes supplementary inputs.
- A retained 2014 asset prefix in candidate canonical loading was changed to the year-specific prefix; a dedicated 2010 asset-name test passes.
- Full prototype Parquet/public canonical/raw validation: COMPLETE, 68 passing check blocks, zero discrepancies and no warnings. All 21 Parquet write/read round trips are exact.

The identity adapter was committed separately at `65bdb1f8e7cc64bd066dbbfaa5eaa07af8c6d62e`. No 2010 reader/build implementation commit, push, tag or release has been created; published assets are unchanged.

## Files and change classification

Production:
- New `R/xml_2010.R`: ZIP/source/ballot/party-ID adapter and historical dispatch.
- `R/xml_2014.R`, `R/valresultat_2014.R`, `R/personroster_2014.R`, `R/mandat_2014.R`: small year-parameter/shared-reader extensions; empty result-only population type fix.
- `R/api_valresultat.R`, `R/api_mandat.R`, `R/api_kandidaturer.R`, `R/api_kandidater.R`, `R/api_personroster.R`, `R/valda_slutlig.R`, `R/ersattare_slutlig.R`: 2010 dispatch through the shared historical reader.
- `R/api_validation.R`, `R/valar.R`: the same year-selector model now includes 2010.
- `R/canonical_2014.R`, `R/canonical_2022.R`: configured unpublished 2010 schema-2 manifest, with existing 2014 defaults unchanged.

Tests:
- New `tests/testthat/test-xml-2010.R` and a tiny synthetic ZIP in `tests/testthat/fixtures/2010/metadata-fixture.zip` (not an official raw source).
- Existing year-selection regression expectations/mocks updated in `test-2018-stage2.R`, `test-2018-xml.R`, `test-ersattare-flerar.R`, `test-kandidater-2022.R`, `test-personroster-2022.R`, `test-valda-flerar.R`, `test-valresultat-flerar.R`.

Documentation: README, NEWS, six generated man pages, source inventory, implementation decisions and this validation report.

Development/build aids: `data-raw/build-canonical-2010.R`; `development/validate_canonical_2010.R`, `validate_sources_2010.py`, `export_mandate_validation_2010.R`, `build_party_identifiers_2010.py`, `retrieve_preliminary_2010.py`, `smoke_2010.R`.

The separately committed identity adapter/provenance files are not part of the new reader diff. Original `.local-data` sources and canonical prototype outputs are ignored, not Git changes. Python is confined to optional development tooling.

## Prototype inventory and additional aggregation checks

The unpublished validation prototype is in `.local-data/canonical-build/2010-prototype-final-validation-v2`. It contains exactly 21 Parquet files plus `manifest.json`; Parquet size is 39,438,803 bytes. Its data version is the unpublished sentinel `data-v0.0.0`, schema version 2, build SHA `65bdb1f8e7cc64bd066dbbfaa5eaa07af8c6d62e`, and `build_tree_dirty = true`. A publication version has not been chosen. The initial development-only version string was rejected by the existing manifest validator; only build metadata was corrected to the accepted sentinel, without changing any Parquet values or relaxing validation.

Manifest SHA256: `e9a18d7f7c71ff301cb72764c05e422c1d467566aa83e21338642de1e0603568`.

Independent area-versus-district candidate-key aggregation matches exactly in RD, RF and KF: 1,494,924 / 1,422,296 / 1,848,627 person votes, with zero candidate-party-person-vote-area differences. This is an additional cross-level check, not an addition of the two sources.

| Asset | Rows | Bytes | SHA256 |
|---|---:|---:|---|
| rkl2010-results-slutlig-rd.parquet | 89,101 | 2,391,826 | `3f47c903dc72d85b3635d495978db4c2905ed1dba15bd2ad1ba51a5f95ec54f1` |
| rkl2010-preference-votes-base-area-rd.parquet | 20,583 | 80,457 | `bd60d3026f7390314087ba3e62160a3d4246737e7da0fdd1f149de7a56228128` |
| rkl2010-preference-votes-area-rd.parquet | 71,987 | 302,356 | `139ff0243d83bae13bec07c795d00d4606b1a4b1a29db628fd16169e5b6a9bf0` |
| rkl2010-preference-votes-base-district-rd.parquet | 866,496 | 1,626,258 | `f890869ff7f074bfb631b36b860af7322a5a0dcd7c6bd766044efd445c294699` |
| rkl2010-preference-votes-district-rd.parquet | 663,326 | 4,771,266 | `a444308932035fbe7be4cbf2ab528d0c26c513a7058c37efdcffe61e166a5761` |
| rkl2010-results-slutlig-rf.parquet | 78,748 | 2,269,793 | `e457a5ee70a358001798287adaf1710e422f6c366621f76024cd7b5135ad7d85` |
| rkl2010-preference-votes-base-area-rf.parquet | 57,209 | 199,872 | `acad82a3e9c933ede106dde4721a1b3af955c7165bf46ae498f94c90fb8b4220` |
| rkl2010-preference-votes-area-rf.parquet | 234,283 | 1,225,087 | `1058da1cb03e7fed0b4c7acede638002baf3ac2c5cfae59e001a07a85cb1b7e3` |
| rkl2010-preference-votes-base-district-rf.parquet | 1,006,490 | 2,133,253 | `29d68881e92d349e29911ebac8397bfb4661c102b0de7bc729b44b889747132f` |
| rkl2010-preference-votes-district-rf.parquet | 794,781 | 5,755,767 | `16749056800c4f5a46f71e1005f58402c3bd1451d59a989e4e11d0a17d24996a` |
| rkl2010-results-slutlig-kf.parquet | 75,903 | 2,221,133 | `0d42ab9b3636a217834a93583a3c04929fd4d093a887d0ba50004545bd1f3099` |
| rkl2010-preference-votes-base-area-kf.parquet | 160,085 | 655,230 | `a25b3b41ea6c63136fae9c30d60f93bbeef53b1f3561c9569dac42d74f807269` |
| rkl2010-preference-votes-area-kf.parquet | 331,079 | 2,917,978 | `5927d8865bb1d7387a28e08254d36890ff28a8d660dd91c3401130901bddf957` |
| rkl2010-preference-votes-base-district-kf.parquet | 1,116,455 | 2,644,749 | `a787f03f4850bd3b2c91cd0e2e5c60daf35f7c19eb897a592fb7063f1e9227de` |
| rkl2010-preference-votes-district-kf.parquet | 921,746 | 6,871,287 | `d4e684e4a470bc3fc84f726220b77f46a58aed5fa05850b8300f9670926e5088` |
| rkl2010-seats-slutlig.parquet | 5,304 | 45,785 | `d98e2bc078d6d997411fc1486986c33f53fb7ebf91561144137116d1973ebd99` |
| rkl2010-candidacies.parquet | 198,542 | 1,261,109 | `636518f15b20d94a9ea6fe656af79465e25909fe78b5b7169c925812955198c7` |
| rkl2010-candidates.parquet | 69,760 | 445,766 | `dd1b18eae211fbe2c69c4cd1ffa715c0342b42d79dcfb2eea66d9f50aeeb6d44` |
| rkl2010-elected.parquet | 14,980 | 150,741 | `afdfa4354643d0272fd383226610f51f481af317153f217b379451246eda65fa` |
| rkl2010-substitutes.parquet | 84,734 | 198,698 | `ecfa36becb14e5b73371dd4de9bf4f8faee49f62a385430421eea89deface10f` |
| rkl2010-candidate-population.parquet | 199,585 | 1,270,392 | `bbc1cc74326b941bc89211de6c85c06001e618f369911668cbefe16c8e1763ba` |

## Final public validation coverage and readiness

The monolithic `validate_canonical_2010.R` run completed with `COMPLETE all`, no warnings and no value/type/order differences:

- 17 final result election/level combinations, with unique observation keys and three independent cross-level geographic-total checks.
- Six final seats combinations, including strict main-level seat and unfilled-seat totals.
- All three elections for candidacies, candidates with/without result enrichment, elected and substitutes.
- All 24 election/level/list/zero combinations for preference votes, plus RF region and KF municipality aggregation. District sparse and completed views have unique keys; observed shares equal their numerator divided by the known positive party denominator.
- Each public comparison checks exact full raw-versus-canonical equality (including row order, types and missingness), standard projection of full, English/Swedish name equivalence, and both Swedish-wrapper detail values. No comparisons are weakened to accommodate the sources.
- All nine manifest source files, 21 asset sizes/SHA256 and exact directory inventory checked. Final independent recheck confirms all 39 original source hashes and all asset checksums unchanged.

Machine-readable detailed row counts, column types and missingness are in the ignored `.local-data/canonical-build/2010-validation-all.json`; independent source relationships and Excel differences are in `.local-data/2010-source-validation.json`. Area-versus-district person-vote equality is recorded in `.local-data/2010-person-vote-level-validation.json`.

Final 2010 support is ready for review and a separate implementation commit. It is not a complete preliminary-data release: preliminary remains explicitly unsupported until a complete official collection-district snapshot can be preserved and validated. The 171/53/10 unknown candidate totals and unresolved source-ID pairs remain transparent historical-source limitations. No further identity changes, source rewrites, published asset changes, push, tag or release were made.

## Exact uncommitted content-change inventory

The following list is the union of Git content differences and new non-ignored files. Some additional `git status` entries have no content diff (line-ending/stat metadata); they do not represent functional changes.

- `NEWS.md`
- `R/api_kandidater.R`
- `R/api_kandidaturer.R`
- `R/api_mandat.R`
- `R/api_personroster.R`
- `R/api_validation.R`
- `R/api_valresultat.R`
- `R/canonical_2014.R`
- `R/canonical_2022.R`
- `R/ersattare_slutlig.R`
- `R/mandat_2014.R`
- `R/personroster_2014.R`
- `R/valar.R`
- `R/valda_slutlig.R`
- `R/valresultat_2014.R`
- `R/xml_2014.R`
- `README.md`
- `man/kandidater.Rd`
- `man/kandidaturer.Rd`
- `man/mandat.Rd`
- `man/personroster.Rd`
- `man/valda.Rd`
- `man/valresultat.Rd`
- `tests/testthat/test-2018-stage2.R`
- `tests/testthat/test-2018-xml.R`
- `tests/testthat/test-ersattare-flerar.R`
- `tests/testthat/test-kandidater-2022.R`
- `tests/testthat/test-personroster-2022.R`
- `tests/testthat/test-valda-flerar.R`
- `tests/testthat/test-valresultat-flerar.R`
- `R/xml_2010.R`
- `data-raw/build-canonical-2010.R`
- `development/2010_SOURCE_INVENTORY.json`
- `development/IMPLEMENTATION_2010_PLAN.md`
- `development/IMPLEMENTATION_2010_VALIDATION.md`
- `development/build_party_identifiers_2010.py`
- `development/export_mandate_validation_2010.R`
- `development/retrieve_preliminary_2010.py`
- `development/smoke_2010.R`
- `development/validate_canonical_2010.R`
- `development/validate_sources_2010.py`
- `tests/testthat/fixtures/2010/metadata-fixture.zip`
- `tests/testthat/test-xml-2010.R`

## Completed preliminary integration validation

See [PRELIMINARY_2010_INTEGRATION.md](PRELIMINARY_2010_INTEGRATION.md) for the full source-role/missingness report and prototype provenance.

- Collection coverage: RD 395/395, RF 392/392, KF 395/395; no duplicate district keys or overlap with ordinary election-night districts.
- All 1,067 independent preliminary aggregate comparisons pass. National totals are RD 6,027,252; RF 5,927,840; KF 6,007,976.
- Eighteen unreported collections remain `NA`; all 722 partially reported pages and 4,213 blank current/previous category-count cells match the source. Explicit HTML party-vote changes are preserved even when a comparison count is unavailable.
- Full public canonical/raw sweep: 85 passing check blocks, zero discrepancies or warnings; all seven functions and preliminary/final level variants, standard/full, English/Swedish, Swedish wrappers, keys, types and missingness.
- The new prototype has 24 Parquet assets plus a manifest. All round trips and English schema checks pass. All 21 previously validated Parquet assets are byte-identical; candidate/person-vote handling and identity rules are unchanged.
- Full suite: 3,198 passes, zero failures/warnings, 10 explicit opt-in skips. `R CMD check --no-manual --no-vignettes`: 0 errors, 0 warnings, 0 notes. `git diff --check` passes.
- Original 39 sources and all 2,535 preserved preliminary HTML responses have unchanged checksums. The previous prototype's 22 files are unchanged. No commit, push, tag or release has been created.

This is an unpublished working-tree prototype, not a clean release build. Intentional snapshot missingness and the previously documented final-source/candidate limitations remain preserved.
