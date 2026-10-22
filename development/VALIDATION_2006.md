# 2006 validation and remaining source limitations

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


The 2006 implementation uses Valmyndigheten sources. SCB is an independent
validation source and does not supply invented candidate records or identities.
See [IMPLEMENTATION_2006.md](IMPLEMENTATION_2006.md) and
[SOURCE_INVENTORY_2006.md](SOURCE_INVENTORY_2006.md) for source selection,
observation identity and reproduction commands.

## Independent controls

| Control | RD | RF | KF |
| --- | ---: | ---: | ---: |
| Valid party votes | 5,551,278 | 5,415,740 | 5,521,566 |
| Blank votes | 96,922 | 141,637 | 112,063 |
| Other invalid votes | 2,216 | 2,372 | 2,474 |
| Total ballots | 5,650,416 | 5,559,749 | 5,636,103 |
| Eligible voters | 6,892,009 | 7,052,595 | 7,098,097 |
| Allocated mandates | 349 | 1,656 | 13,092 |
| Unfilled mandates | 0 | 0 | 14 |
| Original appointed observations | 349 | 1,656 | 13,078 |
| Expanded member/substitute relationships | 1,667 | 9,488 | 75,445 |
| Complete observed area preference votes | 1,235,601 | 1,186,237 | 1,554,153 |
| Preference votes in common area/list/district XML scope | 1,147,952 | 1,167,604 | 1,543,320 |
| Supplementary area-only preference votes | 87,649 | 18,633 | 10,833 |

The independent R SCB validator passes 8,712 municipality, major-party,
invalid-vote, national and filled-mandate checks. The RF wide table has 102
exact duplicate rows; a temporary analytical view removes duplicates for
validation, without changing the source. Original appointed names, order,
election basis and expanded substitute relationships match the final XML.
`Kunde ej utses` positions are excluded from appointed people.

## Observation populations

| Source-observation population | RD | RF | KF |
| --- | ---: | ---: | ---: |
| Geographical ballot-position candidacies | 20,926 | 46,498 | 86,398 |
| Candidate source observations across roles | 31,300 | 70,784 | 179,544 |
| Observed positive area preference-vote records | 9,429 | 20,129 | 68,814 |
| Candidate records with unknown cross-source person-vote total | 21,871 | 50,655 | 110,730 |

These are **not unique-person counts**. Ballot, area-result and appointment
observations are deliberately separate without an unsupported person linkage.
Every observed area preference-vote value is retained. Appointed slots cannot
be given preference votes by joining names. Their unknown person-vote totals
remain `NA`. Names are never identity keys.

The frozen ballot source contains 153,779 `Definitiv` and 43 `Utkast` records.
Their exact source values are preserved. Neither status is translated into
modern `S`/`B`, validity or printed-name-ballot evidence.

## Source discrepancies and unsupported requests

* The detailed RD preference source exceeds the separate official/SCB statistic
  by 4,089: constituency 11 +433, 12 +493, 13 +564, 14 +532 and 28 +2,067.
  This remains unresolved. Ordinary party votes agree independently.
* Detailed KF preference votes total 1,554,153, agreeing with the detailed SCB
  material, versus 1,554,115 in the separate Valmyndigheten statistics
  presentation. The 38-vote difference is preserved.
* Supplementary other-party area observations do not have a verified list or
  district assignment. They appear only in the complete non-list area view.
  The narrower list/district totals are therefore not complete-area controls.
* Three KF party/municipality combinations lack a safely recoverable numeric
  party code: Vänsterdemokraterna in Gnesta (0461, `Vda`) and Flen (0482, `vä`),
  and Kommunpartiet in Bengtsfors (1460, `KPT`). Counts and source designations
  remain available with `party_code = NA`, distinct from residual other parties.
* Only final results are supported. Election-night material is preserved but
  cannot replace the missing complete preliminary collection source.
* Municipality/region preference-vote aggregation cannot assert person linkage
  across source areas. Such 2006 requests fail informatively. `include_zeros`
  does not create unobserved candidate combinations.

## Package and historical regression checks

The final package suite passes 3,258 assertions, with 10 explicit opt-in
integration skips and no failures or warnings. Current package sources were
copied to an isolated package-build directory and verified file by file, to
avoid traversing ignored raw archives. `R CMD check --no-manual --no-vignettes`
passes with 0 errors, 0 warnings and 0 notes.

All 84 historical full public outputs (seven functions, three elections and
2010/2014/2018/2022) are identical to the committed implementation. All 92
protected canonical assets retain their recorded SHA256. Further integrity
checks pass for 2,497 preserved original 2022 sources and eight corrected ZIP
members, 2,546 2010 source entries, 4,475 2014 source entries, and the exact
three 2018 canonical source snapshots.

## Final local canonical validation

All executed checks pass:

| Validation | Result |
| --- | --- |
| Results, all 17 supported election/level combinations | 115 checks pass |
| Seats, RD/RF/KF | 45 checks pass |
| Preference votes, 12 area/district and list variants | 117 checks pass |
| Candidacies, candidates, candidate base, elected and substitutes | 120 checks pass |
| English/Swedish wrappers, standard/full, shared values and rows | 47 requests, 564 assertions pass |
| Original XML party and elected geography | All 15,083 appointed observations pass |
| Independent SCB comparisons | 8,712 checks pass |
| Source integrity during build | 1,446 inputs verified before and after |
| Asset sizes, SHA256 and Parquet round trips | All 15 assets pass |

The XML party/geography controls are retained in
`validate_canonical_2006.R`. For undivided RF/KF areas, technical constituency
codes ending in `00` are not asserted to be a substantive constituency. The
existing shared appointment normalisation returns `NA` for these constituency
fields in both standard and full. Original codes remain in immutable raw XML.

The final prototype is local and unpublished:

- directory relative to the repository: `.local-data/canonical-build/2006-implementation-final`;
- exactly 15 Parquet files and `manifest.json`, no unintended files;
- total size including the manifest: 33,440,528 bytes;
- data version `data-v0.0.0`, schema version 2;
- build Git SHA `5d86cb67454107049bfe526a41ddc25f30cfe9bc`;
- `build_tree_dirty = true`; this is an uncommitted implementation review build;
- manifest SHA256 `d9b57e87dbf378d078504da921970f5b960856dab07b27e446c89af7da239ce2`;
- no public release or canonical automatic eligibility has been added.

| Parquet filename | Rows | Bytes |
| --- | ---: | ---: |
| rkl2006-results-slutlig-rd.parquet | 92,345 | 2,112,085 |
| rkl2006-results-slutlig-rf.parquet | 77,954 | 2,113,055 |
| rkl2006-results-slutlig-kf.parquet | 72,977 | 2,096,437 |
| rkl2006-seats-slutlig.parquet | 5,339 | 46,804 |
| rkl2006-candidacies.parquet | 153,822 | 1,584,443 |
| rkl2006-candidates.parquet | 281,628 | 1,794,483 |
| rkl2006-candidate-base.parquet | 281,628 | 1,686,816 |
| rkl2006-elected.parquet | 15,083 | 199,436 |
| rkl2006-substitutes.parquet | 86,600 | 495,419 |
| rkl2006-preference-votes-area-rd.parquet | 14,654 | 289,243 |
| rkl2006-preference-votes-area-rf.parquet | 39,160 | 721,221 |
| rkl2006-preference-votes-area-kf.parquet | 138,193 | 2,187,238 |
| rkl2006-preference-votes-district-rd.parquet | 526,882 | 4,156,751 |
| rkl2006-preference-votes-district-rf.parquet | 668,601 | 5,174,781 |
| rkl2006-preference-votes-district-kf.parquet | 814,355 | 7,891,386 |

Results assets include alternative analytical geographic levels. Preference
assets include list and non-list views. Their row counts are not additive
populations to be summed across views.

Compared with the first local review prototype, 12 Parquet files are
byte-identical. The three candidate assets have only the reviewed geographic
code completion and exact source ballot-status preservation:

- candidacies: `constituency_code` and `ballot_status`; sorting changes with
  the completed code, but source-observation keys and all other values agree;
- candidates and candidate base: `constituency_code` only; key order and all
  other values agree.

The final candidacy asset was re-exported from the current raw reader after
restoring the exact `Definitiv`/`Utkast` source values. Its lossless round trip,
updated manifest entry and final public/raw comparisons pass. No historical
or published canonical asset was replaced. A clean committed rebuild remains
necessary after review; this prototype must not be represented as a clean
release build.

## Implementation file inventory

New R implementation and tooling:

- `R/xml_2006.R`, `R/candidates_2006.R`, `R/canonical_2006.R`;
- `data-raw/build-canonical-2006.R`, `data-raw/preserve-final-2006.R`,
  `data-raw/validate-scb-2006.R`;
- `development/validate_canonical_2006.R`;
- `tests/testthat/test-xml-2006.R`.

Existing production dispatch and supported-year registration:

- `R/api_english.R`, `R/api_ersattare.R`, `R/api_kandidater.R`,
  `R/api_kandidaturer.R`, `R/api_mandat.R`, `R/api_personroster.R`,
  `R/api_validation.R`, `R/api_valresultat.R`;
- `R/canonical_2022.R`, `R/ersattare_slutlig.R`, `R/valar.R`,
  `R/valda_slutlig.R`.

Existing tests updated for the additional supported year and dispatch:

- `tests/testthat/test-2018-stage2.R`, `test-2018-xml.R`,
  `test-ersattare-flerar.R`, `test-kandidater-2022.R`,
  `test-personroster-2022.R`, `test-valda-flerar.R`,
  `test-valresultat-flerar.R`.

Documentation:

- `README.md`, `NEWS.md`, `development/README.md`;
- `development/IMPLEMENTATION_2006.md`, this validation report and the
  pre-existing source review `development/SOURCE_INVENTORY_2006.md`;
- generated `man/candidacies.Rd`, `candidates.Rd`, `elected.Rd`,
  `ersattare.Rd`, `kandidater.Rd`, `kandidaturer.Rd`, `personroster.Rd`,
  `preference_votes.Rd`, `results.Rd`, `seats.Rd`, `substitutes.Rd`,
  `valda.Rd`.

Package version, dependencies and public column schemas are unchanged.
No raw source, SCB DTA, Python or generated Parquet file is tracked.
No commit, push, tag or release has been made. The implementation is ready
for review with the source limitations above retained, rather than concealed.

## Clean-build candidacy ordering control

The first clean rebuild reproduced 14 of the 15 approved Parquet files
byte-identically. Candidacy values, types, keys and within-election row order
were all identical, but the builder concatenated RD/RF/KF subsets while the
approved prototype's final candidacy export retained the joint ballot-source
order. A diagnostic export through the existing all-election raw reader
reproduced the approved file byte-identically (SHA256
`ab39024e5c57263574f765415037fb8b948c62df9a09506a342fa10156a3aa96`).
The builder now uses that same reader for the candidacy asset. The independent
validator compares the entire candidacy file with that raw output, including
cross-election row order. This is a build reproducibility correction; no
source, identifier, data value, schema or public output semantics change.

The earlier prototype's one-off manifest rewrite also serialized missing
`capture_utc` values as empty arrays instead of null. The clean builder
retains null for missing capture dates. All known timestamps and source
checksums remain unchanged; empty arrays never establish a capture date.
