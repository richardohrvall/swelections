# 2014 implementation and unpublished canonical validation

## Scope and status

The implementation adds 2014 to all seven English functions and their Swedish
counterparts. Package version remains `0.3.0.9000`. No commit, tag, push or
release was made. Published 2018 assets were checked against their original
manifest: all 20 sizes and SHA256 hashes still match.

The R adapters reuse the 2018 XML normalisers where structures agree. There is
no Python runtime dependency. Public schemas, output-name rules and the
standard/full projection are unchanged. Explicit local 2014 canonical builds
are supported; 2014 has no published or automatic canonical-release entry.
The historical raw route requires the preserved local collection and does not
implement remote/update/archive operations.

Final validation completed on 2026-10-08. All 81 single-election public API
comparisons and ten mixed-election comparisons passed.

## Authoritative inputs and provenance

All paths below are relative to `.local-data/rkl/2014/`:

* `valresultat/slutresultat_20141001/`: original final election XML, including
  national and municipal files for RD/RF/KF. These supply final vote results,
  seats, preference votes and original elected/substitute relations.
* `valresultat/valnatt/`: ordinary election-night districts only.
* `valresultat/preliminary-presentation-20261007T133824Z/`: captured official
  preliminary presentation, with its URL/time/size/MD5/SHA256 source manifest.
  It contains all 1,167 preliminary collection pages: RD 390, RF 387, KF 390.
  Captured aggregate pages independently validate the constructed result and
  supply explicit electorate/historical metadata where collection nodes have
  no electorate of their own. The 2018 pages in the capture are excluded from
  the 2014 metadata reader by the full year-specific URL path.
* `kandidater/alkandur_R.skv`, `alkandur_L.skv`, `alkandur_K.skv`: documented
  ballot candidacies. Locally preserved names are not published.
* `kandidater/official-ballot-metadata/00R.xml`: official ballot metadata,
  including identifiers for zero-vote parties not identifiable from result
  list nodes alone. Its separate provenance records URL, time and checksums.
* `kandidater/official-ballot-metadata/party-identifiers-2010-complete.csv`:
  reproducible official historical party-identity supplement, with source
  provenance. It only supplements unresolved party identities, never vote
  counts, candidates or election relationships. Current 2014 identity evidence
  takes priority.

The prototype manifest pins 4,475 input files by size, MD5 and SHA256. Checks
read sources without overwriting them. Later membership files are not build
inputs. Raw source-language values are preserved; public candidate names are
typed missing values as agreed. No name is used to identify a candidate.

## Coverage

| Function | RD | RF | KF |
|---|---|---|---|
| results, preliminary/final | district, municipality, municipal constituency, county, parliamentary constituency, national | district, municipality, municipal constituency, regional constituency, region, national | district, municipality, municipal constituency, county, national |
| seats, final | national, parliamentary constituency | region, regional constituency | municipality, municipal constituency |
| candidacies/candidates | supported | supported | supported |
| elected/substitutes | original final relationships | original final relationships | original final relationships |
| preference_votes, final | preference-vote area and district; list/zero variants | same, plus region aggregation | same, plus municipality aggregation |

No `election_night` public count value was added. Preliminary seats are not
claimed. RF excludes Gotland, which has no separate regional election.

## Preliminary construction and independent totals

The construction uses ordinary night districts plus **preliminary** collection
figures. Final collection figures are never substituted. Ordinary and collection
district keys are disjoint, and each district contributes once to geographic
totals. Collection districts do not add a second electorate.

| Election | Ordinary districts | Collection districts | Night valid votes | Collection valid votes | Preliminary valid votes |
|---|---:|---:|---:|---:|---:|
| RD | 5,837 | 390 | 6,039,526 | 175,848 | 6,215,374 |
| RF | 5,796 | 387 | 5,992,544 | 133,130 | 6,125,674 |
| KF | 5,837 | 390 | 6,074,487 | 134,533 | 6,209,020 |

Independent captured preliminary checks: RD 497 pages/4,473 party comparisons/
994 valid-or-total comparisons; RF 503/5,500/1,004; KF 493/4,823/942. All matched,
including national, constituency and municipal aggregates. No selected page was
left unmapped. Other-party aggregates are compared at a compatible scope, not
equated across presentations with different individually reported party sets.

Final SKV checks cover RD 290 municipalities/6,227 districts, RF 289/6,183,
KF 290/6,227. They compare valid votes, total votes and nine main party counts:
212,093 comparisons, zero differences. Ordinary Uppsala districts numbered 1--3
are distinguished from collection districts by the official SKV type label;
low numbers alone are not a safe district-type test.

The official KF district XLSX independently agrees with SKV for 6,227 districts
and 73,361 known count values, including party votes, valid/total votes and
electorate. The other `.xls` files were inventoried, but were not independently
read by this implementation; the full SKV checks provide the corresponding
independent result validation.

## Candidate population and independent SCB check

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Documented candidacy rows | 26,414 | 84,497 | 89,275 |
| Distinct ballot candidate IDs | 5,905 | 12,535 | 52,156 |
| Additional positive-result IDs | 1 | 74 | 1,292 |
| Additional nonpositive relationship IDs | 0 | 0 | 43 |
| Union candidate IDs | 5,906 | 12,609 | 53,491 |
| Public candidate keys (candidate × election × party) | 5,906 | 12,616 | 53,535 |
| SCB nominated persons | 5,905 | 12,627 | 53,668 |
| Union IDs minus SCB | +1 | −18 | −177 |

The 43 additional KF relationship IDs include two elected candidates and 41
substitutes. They are not fabricated ballot candidacies. Unknown attributes and
ballot/list/geographic counts for result-only candidates remain typed `NA`.

SCB counts deduplicated nominated persons using its nominated/elected population
rules; this is not identical to the union of ballot and final-result evidence.
SCB metadata also describe revised Båstad 2015 re-election statistics. We have
not reconciled every person behind the RF/KF differences. These remain explicit
population/definition differences, not missing records filled from SCB.
Official references: SCB tables ME010720T01/T02/T04 and
https://www.scb.se/contentassets/4df37246f586465991189fc7d4f1593d/me0107_do_2014_jo_190114.pdf.
The retrieved API responses are preserved in the private validation directory.

## Preference votes and missingness

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Raw area PERSONVAL records | 11,435 | 26,656 | 72,336 |
| Distinct candidate/area/party keys | 11,435 | 26,656 | 72,302 |
| Additive repeated records | 0 | 0 | 34 |
| Area preference-vote sum | 1,531,582 | 1,392,824 | 1,802,915 |
| District preference-vote sum | 1,531,582 | 1,392,824 | 1,802,915 |
| Candidate/area differences | 0 | 0 | 0 |
| Candidate totals: positive / zero / NA | 5,685 / 95 / 126 | 12,311 / 192 / 113 | 49,045 / 4,450 / 40 |

Repeated KANDNR records are added within their source parent, not discarded and
not added across area and district representations. Every positive official
candidate ID is represented. Observed values are retained; missing candidates
become zero only where the shared XML availability checks verify the relevant
underlying material. The remaining candidate-total `NA`s preserve incomplete
candidate-area evidence rather than treating it as zero. More specifically,
all 1,345 RD, 264 RF and 52 KF missing default area counts correspond to an
absent party-specific node; none corresponds to an observed but incomplete
party/list node. The shared 2018 rule does not interpret that absence as an
explicit zero. The independent district comparison found no additional
candidate-identified votes. Thus these are retained source-coverage/negative-
evidence limitations, not observed positive votes discarded by the parser.
Qualification and broader-area aggregation use the existing source/availability
rules. Any future change to the meaning of absence would need a separate
availability decision; this implementation does not silently change 2018 rules.

## Original elected and substitute relationships

| Election | Mandates | Elected | Unfilled seats | Substitute relations |
|---|---:|---:|---:|---:|
| RD | 349 | 349 | 0 | 1,419 |
| RF | 1,678 | 1,678 | 0 | 9,394 |
| KF | 12,780 | 12,763 | 17 | 65,016 |

Positive KF unfilled-seat rows: Nykvarn/SD 1; Vingåker/SD 1; Boxholm/SD 2;
Tingsryd/SD 1; Mönsterås/SD 1; Klippan/SD 2; Dals-Ed/SD 2; Färgelanda/SD 2;
Lilla Edet/SD 2; Surahammar/party 0055 1; Norsjö/SD 1; Arjeplog/SD 1.
The raw `Kunde ej utses` placeholder is recognised in memory. No candidate is
invented for an unfilled seat, and raw XML is not rewritten.

## Local canonical prototype

Directory: `.local-data/canonical-build/2014-prototype-20261008/`.
Exactly 24 Parquet assets plus `manifest.json`; total Parquet size 48,238,729
bytes. Stored columns use the approved English mapping; Swedish names are an
output transformation. The provisional data version is `data-v0.3.0`, schema 2,
`release_status = unpublished_local_validation_build`, `auto_eligible = false`.
The recorded base Git commit is `705b2b61d32dc91d3cbfe1b404e064bce79a6cb3`,
with `build_tree_dirty = true`. This is not a release-ready clean build.
The final validation/provenance manifest SHA256 is
`5829549ea4e9a256d442de831947a3dc4e56c42b92a16fd3fdf7c45c31233713`.

Asset inventory:

* `rkl2014-results-preliminar-{rd,rf,kf}.parquet`
* `rkl2014-results-slutlig-{rd,rf,kf}.parquet`
* `rkl2014-seats-slutlig.parquet`
* `rkl2014-candidacies.parquet`
* `rkl2014-candidate-population.parquet` (internal population evidence)
* `rkl2014-candidates.parquet`
* `rkl2014-elected.parquet`
* `rkl2014-substitutes.parquet`
* `rkl2014-preference-votes-base-area-{rd,rf,kf}.parquet`
* `rkl2014-preference-votes-area-{rd,rf,kf}.parquet`
* `rkl2014-preference-votes-base-district-{rd,rf,kf}.parquet`
* `rkl2014-preference-votes-district-{rd,rf,kf}.parquet`

The initial unpublished build was refreshed after validation identified missing
aggregate metadata. The refresh is restricted to dirty unpublished 2014 builds,
checks original hashes, preserves vote counts/keys/row counts and round-trips
the updated assets. The initial long build wrote the complete manifest/assets
but exited with a trailing parse error after its completion message because the
running script had been edited. The current build script parses successfully;
the retained prototype is validated independently after the refresh. This is
not reported as a successful clean release-build command. A future release
must be rebuilt normally from committed
clean code, rather than published from this prototype.

## Validation findings corrected internally

1. Collection XML can omit VALDELTAGANDE while containing explicit valid and
   BLANK/OG components. The 2014 adapter now derives invalid and total votes
   from complete components and rejects contradictions. No missing component
   is assumed zero. This removed 1,167 collection-total gaps against SKV.
2. Collection districts have no independent electorate. Aggregation uses the
   ordinary electorate once, supplemented by hash-pinned explicit presentation
   metadata; it does not lose aggregate turnout merely because collection
   electorate fields are absent.
3. Internal population-evidence attributes and incidental list-vector names
   are removed from the 2014 public preference table. Parquet does not preserve
   these R-only attributes; no substantive value was changed.
4. Mixed-election canonical calls reproduce raw row ordering, including the
   ballot/result-only population union and preference-view global ordering.
   Candidate cross-election summary counts remain request-specific.

These are 2014 adapter/backend corrections. Existing 2018 parsers, 2022 source
corrections, 2026 RF inconsistency rules, download helpers and published assets
were not modified.

## Validation procedure and remaining work

R development scripts:

* `validate_canonical_2014.R`: all supported result/seat levels, candidate
  functions, list/zero variants, full/standard projection, English/Swedish
  names and Swedish wrappers, keys/types/missingness. It compares public raw
  outputs directly, caching only parsed raw-reader objects within the run.
* `validate_mixed_2014.R`: requested-election ordering and enrichment scope.
* `diagnose_sources_2014.R`: independent raw KANDNR population and area/district
  vote checks.
* `validate_official_totals_2014.R`: independent SKV and captured HTML checks.
* `validate_excel_2014.R`: official XLSX/SKV comparison.

Current completed package checks: 3,072 passing assertions, zero failures,
errors or warnings; nine pre-existing opt-in integrations skipped because
their external paths were not configured. The separate 2014 sweeps are not
part of those skips. Source-only package build/install and
`R CMD check --no-manual --no-vignettes` pass with zero errors/warnings/notes.
Final `git diff --check` passed.

Completed public API comparisons: 34 result requests (all 17 supported
election/level combinations, preliminary and final), six seat levels,
15 candidate-family requests (the four functions plus candidates without
results, per election), and 26 preference requests (eight area/district/list/
zero combinations per election plus RF-region and KF-municipality aggregation).
Each compares the actual full raw-path output with canonical output, verifies
standard as a projection, both column-name languages, Swedish wrappers, keys,
types and missingness. Reader outputs are cached only within the validation run;
raw comparisons never read Parquet data. English/Swedish output names change
neither values nor observation units.

Ten additional mixed-election comparisons passed: all five candidate/person-
relation functions with RF/RD and KF/RD/RF requested orders. All 24 current
Parquet assets passed write/read round-trips and reversible English/Swedish
column mapping; recorded sizes and SHA256 hashes match. The build directory
contains exactly those assets plus the manifest, no raw files. Final MD5 and
SHA256 checks confirm all 4,475 source files unchanged.

No unresolved canonical/raw value or structural differences remain. The SCB
population differences and absent party-node missingness described above are
retained explicitly. No source values were forced to agree with an external
population total, and no later mandate-period relationships were imported.

Before publication: review the residual historical population/missingness
limitations, commit approved code, choose the final data-release inventory and
version, then rebuild and validate from the clean commit. No release is implied
by the provisional manifest version.

## Changed repository files

New production files: `R/xml_2014.R`, `R/valresultat_2014.R`,
`R/mandat_2014.R`, `R/personroster_2014.R`, `R/canonical_2014.R`.

Existing production routing/year registration/documentation updated:
`R/api_english.R`, `R/api_valresultat.R`, `R/api_mandat.R`,
`R/api_kandidaturer.R`, `R/api_kandidater.R`, `R/api_personroster.R`,
`R/api_validation.R`, `R/valar.R`, `R/valda_slutlig.R`,
`R/ersattare_slutlig.R`, `R/canonical_2022.R` (2014 dispatch only).

New build/development files: `data-raw/build-canonical-2014.R`,
`data-raw/build-party-identifiers-2014.R`, the five validation/diagnostic scripts
listed above, `development/refresh_preliminary_metadata_2014.R`, and this report.

New tests: `tests/testthat/test-xml-2014.R` (90 passing assertions).
Supported-year/mock expectations updated in `test-2018-stage2.R`,
`test-2018-xml.R`, `test-canonical-backend.R`, `test-ersattare-flerar.R`,
`test-kandidater-2022.R`, `test-personroster-2022.R`, `test-valda-flerar.R`,
`test-valresultat-flerar.R`. These do not change historical result expectations.

User documentation: `README.md`, `NEWS.md`, and generated Rd pages for the
seven English functions plus `kandidater`, `kandidaturer`, `personroster`,
`valda` and `valresultat`. No public function or argument was renamed.

## Final external review and elected-party enrichment (2026-10-08)

The accepted population remains the union of documented ballot candidates and
original final-result candidate evidence. No SCB records are used to fabricate
candidates or force agreement. Distinct candidate identifiers are 5,906 RD,
12,609 RF and 53,491 KF, compared with SCB's nominated-person counts of 5,905,
12,627 and 53,668: differences +1, -18 and -177. The RD excess is a result-only
candidate with one preference vote. The small RF/KF residuals are retained as
source/population differences; public SCB aggregates do not allow individual
reconciliation. Package candidate/party rows remain 5,906 / 12,616 / 53,535.

Area preference-vote totals are 1,531,582 RD and 1,392,824 RF, matching SCB.
KF totals are 1,802,915 in the preserved XML versus 1,802,521 in SCB. This +394
is fully localised: Båstad +403 (2014 election versus 2015 re-election), Nacka
-3, Sigtuna -3, Bjuv -1 and Älvdalen -2 (later official source versions).
No votes are redistributed or changed to match SCB. The candidate-total
missingness remains 126 / 113 / 40; observed area votes remain available.

The separate member SKV differs from original RD XML in three representatives:
Christoffer Dulny, Kristina Winberg and Peter Lundgren were replaced by Robert
Stenkvist, Nina Kain and Cassandra Sundin on 30 September 2014. Riksdag protocol
2014/15:3 confirms these mandate-period replacements. Original XML election
relations are therefore retained rather than replaced by member-file records.

The elected-output fix is limited to 2014 KF `partiforkortning` /
`party_abbreviation`. `.valda_2014()` reuses the parsed elected relations and
matches election, numeric party identifier, candidate identifier and elected
area to obtain the municipal XML abbreviation. Other elected fields, row order,
candidate population and preference-vote values are unchanged. A deterministic
XML regression also checks that the RD row and all other fields are unchanged.

Existing canonical prototype assets are intentionally not rewritten. They
still contain the pre-fix KF elected abbreviations. Validation uses an explicit
one-field expected correction **in memory only**, sourced from official XML
relations, and compares every other value unchanged. A clean rebuild is needed
after the implementation is committed to put this correction into Parquet.

Final verification after this correction passed:

- Independent final-XML elected checks: 349 RD, 1,678 RF and 12,763 KF
  (14,790 total), including candidate/party identifiers, elected geography,
  election order, basis and group. KF missing abbreviations fell from 12,761
  to zero; every other full elected column remains identical to the pre-fix
  output.
- All 81 public request comparisons and ten mixed-election comparisons passed,
  including standard/full projection, English/Swedish equivalence, keys,
  types and missingness. The unchanged prototype's one corrected elected
  field was compared using the explicit XML-derived in-memory expectation
  described above, rather than by modifying any stored asset.
- Independent preliminary/final official totals: zero differences across
  RD/RF/KF. Official Excel/SKV validation: 6,227 districts and 73,361 counts
  passed. All 24 Parquet assets passed temporary-copy round-trips.
- Full ordinary test suite: 3,076 passing assertions, zero failures or warnings,
  nine opt-in integration skips. The targeted 2014 fixture suite now has
  94 passing assertions. `R CMD check --no-manual --no-vignettes`: zero errors,
  warnings or notes. `git diff --check` passed.
- Final MD5/SHA256 validation confirms all 4,475 recorded raw source files
  unchanged. All 24 original assets, their sizes/SHA256 and the original
  manifest remain unchanged.

The accepted SCB population residuals (+1 RD, -18 RF, -177 KF), preference-vote
totals and snapshot explanations above are unchanged. The implementation is
ready for review/commit followed by a clean canonical rebuild; no commit, push
or asset rebuild was performed during this correction.
