# 2002 validation and unresolved source limitations

This report concerns the unpublished 2002 implementation and local prototype.
No source file, earlier canonical asset, release, candidate identity or schema
has been changed. See [IMPLEMENTATION_2002.md](IMPLEMENTATION_2002.md) and
[SOURCE_INVENTORY_2002.md](SOURCE_INVENTORY_2002.md).

## Selected source coverage

The hash-verified registry contains 869 original-election XML exports: three
national exports, 287 RD municipality exports, 289 RF exports and 290 KF exports.
Original URL, archive URL/capture, retrieval UTC, size, MD5, SHA256 and report time
are preserved. Indexed replay failures were checked through bounded exact-URL
alternatives. No further preliminary archive investigation was undertaken.

Three RD exports remain unrecovered: `slutresultat_1380R.xml` (Halmstad),
`slutresultat_1381R.xml` (Laholm), `slutresultat_1384R.xml` (Kungsbacka).
Final RD district and municipal-constituency party results now use the verified
SCB/SND complementary route for these three municipalities. RD district
preference views remain unavailable: candidate/list details are not reconstructed.
Municipality, county, constituency and national RD results continue to use
the complete national Valmyndigheten export.

No complete ballot-candidacy register has been recovered. `candidacies()` is
unsupported for 2002; no empty population is fabricated. The other six families
are supported where the registered sources and view-level validation permit it.

## Ordinary Orsa and final geographic aggregates

Orsa is pinned to MD5 `3249b5428225a4e6d0c77dbcd1d17340`, describing the ordinary
15 September 2002 election. The reader rejects the 16 March 2003 rerun and any
national KF export embedding its 4,303 valid / 4,316 cast votes.

The ordinary result has 4,009 valid, 61 combined invalid, 4,070 cast votes and
31 allocated/elected positions. National ordinary KF totals are 5,312,977 valid,
96,878 invalid and 5,409,855 cast votes. SCB's local KF district file instead
contains the later Orsa result; that is an explained election-occasion difference,
not a source for filling the ordinary 2002 build.

Independent XML geographic controls pass **9,529 comparisons**, with zero
differences or unverifiable fields. They cover available district/municipality
exports, municipal/national totals, combined invalid/cast votes and major parties.
Independent SCB controls pass **6,982 comparisons**, including separately coded
parties where official list prefixes/numeric aliases establish the linkage.
SCB is a validation source only.

The first geographic diagnostic exposed a 2002-specific reader issue: final
RD/RF collection nodes are direct municipality children, unlike the 2018
selector. The 2002-only selector now includes both root and constituency
collection placements exactly once. A regression test protects this distinction.
Cast totals are derived from known valid plus combined-invalid counts where a
collection has no turnout node. Missing invalid counts remain missing; turnout
for collection districts remains undefined. No final collection data are used
to create preliminary results.

Official elected observations are **349 RD / 1,656 RF / 13,271 KF**. KF has
**13,274 allocated mandates** and three explicit unfilled slots: one in Håbo
and two in Olofström. Unfilled markers are never counted as candidates/persons.

## Preference-vote source controls

These are different measures, not interchangeable totals:

| Election | XML area/party preference aggregate | Individually observed area candidate votes | Unidentified ÖVR aggregate | Cached SCB aggregate | XML minus SCB |
|---|---:|---:|---:|---:|---:|
| RD | 1,381,411 | 1,339,888 | 41,523 | 1,380,864 | +547 |
| RF | 1,325,217 | 1,311,675 | 13,542 | 1,325,189 | +28 |
| KF | 1,660,350 | 1,651,675 | 8,675 | 1,660,350 | 0 |

ÖVR aggregates have no individually identified candidate posts in these area
structures. No candidate is invented for them. The residual RD +547 / RF +28
aggregate differences remain unexplained source/control findings; no votes are
corrected, redistributed or attached to a candidate to force agreement.

RD area list totals and list candidate sums agree. RF has four lists with
aggregate-versus-candidate differences totalling 44; its identified list sum
also exceeds the direct area candidate sum by 263. KF has 16 area lists with
aggregate-versus-candidate differences totalling 458. The observed arrays have
integer counts and contain no extra child category that explains the missing
amount. The strict by-list validation is retained: failing views are recorded
as unavailable in the prototype manifest rather than silently reconciled.
Exact source filenames, area/list keys and values are emitted by
`data-raw/validate-sources-2002.R`.

Source-observation keys do not establish person identity. Area, list, district,
elected-slot and substitute-slot records are different source roles. Positive
and explicit zero counts are preserved; missing slot preference enrichment
remains NA. `include_zeros` adds no unobserved combinations. Public names remain
typed missing under the current-public-source redaction contract.

## Known smaller-party reporting limitation

The official local `tillagg_ovriga.pdf` documents a technical presentation failure
for Fria Listan, Nationaldemokraterna, Ny Demokrati and Populistpartiet. Its
reported national totals are 502 / 9,248 / 2,207 / 11. The original XML and local
SCB detail retain earlier reported subtotals (for example Fria Listan 274,
Nationaldemokraterna 4,122 and NyDemokrati 106). Agreement between these two
sources does not establish complete detail for the four affected parties.

The supplement explicitly distinguishes blank from zero and has incomplete
constituency cells; its original URL/date have not been established. It is
preserved unchanged and documented, but is not silently extrapolated or
overlaid on municipality/district data. All ordinary valid-vote totals and
reported partitions are preserved. A separately reviewed, scoped supplement
integration remains possible; this prototype must not be described as having
fully corrected detail for those four parties.

## Regression and final build checks

The original eleven local files retain their MD5/SHA256. All three previous
2002 preservation manifests retain their SHA256. **127 protected historical
Parquet assets** (including the published 2018 release) retain their recorded
sizes/SHA256. The 2006 public/raw candidate/elected/substitute regressions pass
121 checks; the targeted 2014 final RD results sweep also passes.

Final prototype inventory, public canonical/raw matrix, full-suite and package
check results are appended after the corrected build completes. This is an
uncommitted development build; a clean-commit rebuild is deferred until review.

The complete package suite passes **3,341 tests**, with **10 explicit opt-in
skips**, zero failures and zero warnings. The focused 2002 cases explicitly
cover positive/zero/missing enrichment, source hashes, original-Orsa rejection
guards, smaller-party partitions, collection placement and total derivation.

The final public canonical/raw sweep passes **474 comparisons** (174 results,
195 seats/candidate/elected/substitute checks, 105 preference checks). These
cover all supported result levels and available preference views, full/standard,
English/Swedish, exact shared values, row order/counts, types, missingness, unique
source keys and independent original appointment/substitute XML relationships.
An additional **78 checks** verify actual Swedish/English wrappers and each
individual mandate level. Main allocated/unfilled counts are RD 349/0,
RF 1,656/0, KF 13,274/3. All selected source checksums are verified again.

`R CMD check --no-manual --no-vignettes` gives **0 errors / 0 warnings / 1 known
note**: the pre-existing `valresultat_*.tar.gz` files at the repository root.
They are unchanged. Package source was staged without the ignored raw archive
to avoid Windows long-path errors during R's pre-exclusion copy. `git diff
--check` passes; no raw, Parquet, DTA or Python files are tracked.

## Final local prototype inventory

The prototype is under
`.local-data/canonical-build/2002-implementation-collections-corrected/`.
It contains **13 Parquet assets**, totalling **8,688,347 bytes**, plus the
manifest. Data version is `data-v0.0.0`, schema version 2, unpublished and
not eligible for automatic canonical use. `build_tree_dirty = true` is
correct for this uncommitted implementation.

| Asset | Rows |
|---|---:|
| `rkl2002-results-slutlig-rd.parquet` | 4,971 |
| `rkl2002-results-slutlig-rf.parquet` | 75,403 |
| `rkl2002-results-slutlig-kf.parquet` | 71,159 |
| `rkl2002-seats-slutlig.parquet` | 5,197 |
| `rkl2002-candidates.parquet` | 117,448 |
| `rkl2002-candidate-base.parquet` | 117,448 |
| `rkl2002-elected.parquet` | 15,276 |
| `rkl2002-substitutes.parquet` | 84,972 |
| `rkl2002-preference-votes-area-rd.parquet` | 9,401 |
| `rkl2002-preference-votes-area-rf.parquet` | 16,836 |
| `rkl2002-preference-votes-area-kf.parquet` | 66,753 |
| `rkl2002-preference-votes-district-rf.parquet` | 335,253 |
| `rkl2002-preference-votes-district-kf.parquet` | 418,951 |

Multi-view assets contain discriminators; their row totals must not be
interpreted as one person population or added across geographic levels.
Candidate/source-observation counts are RD 5,615, RF 20,911, KF 90,922.

Two RF assets were recomputed from verified raw XML after adding geography
supported by a unique official municipality/constituency relation. Only
constituency/preference-area code/name fields changed; all votes, row counts,
keys, order, types and other values were identical. Both recomputed files
passed exact Parquet round trip and the subsequent public raw/API sweep.
Earlier prototype copies remain locally available; no historical assets changed.

Manifest SHA256:
`5d1d9941bb6f47eee54d8ae95148e4aec3a42f4867de81a4188a130265a636a0`.
The manifest lists every selected source and asset size/SHA256, plus unavailable
views and the original-Orsa, identity, preliminary and smaller-party limitations.

The supported implementation is ready for review. A publication claim of full
2002 coverage would be inappropriate until the explicit source gaps and any
future scoped smaller-party supplement integration have been reviewed. No
commit, push, tag, release or older-election implementation was undertaken.

## Approved supplement and package-build follow-up

The official URL has now been established and a byte-identical fresh download
preserved. See [SUPPLEMENT_2002.md](SUPPLEMENT_2002.md). The result-only adapter
applies the 107 disclosed constituency cells and official reported national
sums, retains nine NA constituency cells and seven NA county cells, and does
not allocate positive aggregate counts to municipalities/districts. Explicit
constituency zeros do correct contradicted existing observations (Populistpartiet:
Gävle 1 -> 0, Hudiksvall 7 -> 0), with the votes restored to residual other.
Earlier statements that the supplement remains unapplied are superseded.

### Completed supplement validation

The final unpublished prototype is
`.local-data/canonical-build/2002-supplement-20261013/`: 13 Parquet assets,
8,689,531 Parquet bytes, schema 2, data version `data-v0.0.0`,
`build_tree_dirty = true`. The final RD result asset was refreshed after the
supported Gävle/Hudiksvall zeros were established; this is explicit in the
manifest. Only RD results differ from the previous prototype. The other 12
assets are byte-identical, including every candidate, elected, substitute,
mandate and preference-vote asset. RD result rows are 5,159 (previously 4,971):
188 rows expose corrected/disclosed or explicitly unknown aggregate detail.
Every original result key remains present, and original columns differ only
in the affected vote/share fields and corresponding residual counts. Exactly
four municipality observations change: Pop and residual other in Gävle/Hudiksvall.

- Independent PDF transcription: all 107 disclosed / 9 undisclosed cells,
  national sums and 1,229 public geographic/partition/source controls pass.
- Independent geographic controls: 9,529 pass, no discrepancies/unknown controls.
- Independent SCB controls: 6,982 pass; the Orsa election-occasion distinction
  is retained. Older minor-party source subtotals do not override the supplement.
- Public canonical/raw matrices pass: results 174 checks, with all final RD
  cases rerun (75 checks) after the zero correction; candidates/elected/substitutes
  195; preferences 105. Both languages and standard/full are covered.
- Every final build asset hash matches its equivalence-validation asset. A
  further 32 actual-final-manifest RD requests pass across all four supported
  aggregate levels, both languages and both details.
- All 13 Parquet round trips and final manifest sizes/SHA256 pass; 869 source
  checksums pass. Earlier assets/raw sources remain unchanged.
- Full suite: 3,369 pass, 10 explicit opt-in skips, 0 failures/0 warnings.
- `R CMD check --no-manual --no-vignettes`: 0 errors, 0 warnings, 0 notes.
  The targeted tar-file build exclusion removes the previous known note.
- `git diff --check` passes. No raw sources, Parquet or Python files are tracked.

Final manifest SHA256:
`304d46faba60c0117945697f69152b71c4839659ae8f1a81aa003289eb715dc1`.
The pre-existing candidate identity, preference-source and lower-level source
coverage limitations remain documented; none was silently reconciled.
Ready for review before a clean committed rebuild. No commit, push or release.

## Final check of the three missing RD exports

The unrecovered files are `slutresultat_1380R.xml` (Halmstad),
`slutresultat_1381R.xml` (Laholm) and `slutresultat_1384R.xml` (Kungsbacka).
They are municipality-specific exports needed for complete district and
municipal-constituency views, not missing municipality aggregate results.

The preserved official national `slutresultat_00R.xml` contains all 290
municipality branches, including their direct party rows and separately
reported smaller-party detail. The production municipality reader already
uses these branches. No replacement, estimate or SCB-derived input is needed.
The source is the 7 January 2003 archive capture of the official national XML,
MD5 `dbd8443a51dc20f6578a8f8f739b4e98`; its root report time is
`20021210181459`. Complete retrieval metadata and SHA256 are in the source
selection registry and canonical manifest.

| Municipality | Valid votes | Combined invalid | Ballots cast | Eligible voters |
|---|---:|---:|---:|---:|
| 1380 Halmstad | 52,342 | 1,028 | 53,370 | 66,542 |
| 1381 Laholm | 13,404 | 289 | 13,693 | 17,313 |
| 1384 Kungsbacka | 40,439 | 553 | 40,992 | 48,603 |

All returned party-vote counts for these municipalities are observed, with no
missing vote values attributable to the absent exports. Valid and combined
invalid totals agree independently with the local SCB district tables. The
existing complete municipality/party and supplement controls cover their
party partition. National, county and parliamentary-constituency results and
RD mandates likewise use complete official aggregate structures. Complete RD
district/municipal-constituency and district preference views remain unavailable
with an explicit coverage error; they are not silently presented as complete.

The RF/KF list-person-vote inconsistencies and RD/RF preference-vote aggregate
differences concern `PERSONKRYSS` and candidate/list relationships, not ordinary
`RÖSTER` or `MANDAT`. Candidate identity and incomplete ballot/source population
therefore limit candidate analyses, not the correctness of supported final
party-vote and allocated-mandate views. Smaller-party disclosure remains scoped:
the nine undisclosed RD supplement cells remain NA and inside residual other;
complete finer party breakdown is not claimed where the source lacks it.

## Complementary final RD result coverage (supersedes the earlier export limitation)

The preceding missing-export discussion described the XML-only implementation.
It does not indicate missing substantive party results. The verified SCB/SND
route now supplies all 104 missing district/postal units, with 2,496 party/category
rows and no duplicate keys. Four public municipal-constituency units contain
96 rows; collection votes remain outside their aggregation. Laholm is undivided.
All other RD result observations, mandates and candidate/preference records keep
the original Valmyndigheten route.

The independent validator checks 416 district total/denominator controls and
1,281 SCB publication controls (1,212 ordinary, 33 postal, 36 municipality):
1,697 numerical controls passed. SCB publication `Allmänna valen 2002`, tables 5
and 10, provides independent controls; official source:
https://share.scb.se/ov9993/data/publikationer/statistik/me/me0104/2003m00/me01sa0301.pdf
The preserved publication and source hashes are used without rewriting inputs.
The separate SCB/SND electorate value for Kungsbacka is retained.

Source-specific unavailable metadata and district preference data remain missing
or unsupported, rather than being fabricated from party results. Source hierarchy,
file hashes and denominator rules are documented in IMPLEMENTATION_2002.md.

### Final validation of the complementary route (2026-10-14)

- Public canonical/raw matrix: **414 comparisons passed**, covering all supported
  RD/RF/KF result levels, seats, candidates (including base), elected, substitutes
  and preference-vote views, standard/full and English/Swedish. Unsupported
  candidacies and preliminary requests retain their informative errors.
  Freshly raw-derived RD views were memoised within validation; the other views
  were read from their preserved raw sources. Independent elected/substitute
  checks passed. All 869 selected XML source checksums were verified twice.
- Complete suite: **3,399 passed, 10 explicit opt-in skips, no failures/warnings**.
  R CMD check with `--no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**.
  Diff, new-file syntax and whitespace checks passed.
- Original XML geographic controls: **9,529**, no differences/unverifiable values.
  SCB controls: **6,982**, with original Orsa separate from the rerun.
  Four-party supplement: **1,229** controls passed; no undisclosed cells inferred.
- Complementary/publication controls: **1,697** passed. Actual normalized
  production outputs passed another **624** count/share/denominator checks and
  national district-key uniqueness. All four public municipal constituencies
  matched ordinary-district party sums; postal votes were not allocated.
- A new ignored incremental validation prototype contains 13 Parquet assets and
  its manifest. Only the RD result asset was rebuilt (76,729 rows across six
  levels); the other **12 assets are byte-identical** to the approved reference.
  Existing RD aggregate views are exactly identical. English Parquet round-trip,
  asset sizes/SHA256 and complementary provenance checks passed. The manifest
  truthfully records `build_tree_dirty = true`; this is not a release build.
- Protected historical baselines: **92 assets** unchanged; both preserved 2006
  references (15 assets each), **2,497 protected 2022 sources**, and all selected
  2002 XML source sizes/MD5/SHA256 remained unchanged.

Changed implementation/dependency files: `R/results_complement_2002.R`,
`R/xml_2002.R`, `DESCRIPTION` (optional `haven`, for local complementary imports).
Tests: `tests/testthat/test-results-complement-2002.R`.
Build/validation: `data-raw/build-canonical-2002.R`,
`data-raw/validate-complement-2002.R`, `development/rebuild_complement_2002.R`.
Documentation: `R/api_valresultat.R`, `man/valresultat.Rd`, `README.md`, `NEWS.md`,
`development/IMPLEMENTATION_2002.md`, `development/SOURCE_INVENTORY_2002.md`,
`development/VALIDATION_2002.md`.

No public column/identity change, source rewrite, published-asset change,
preliminary reconstruction, commit, push or release was made. District-level
candidate/list/preference and XML-specific metadata remain unavailable for the
three missing exports; observed area/list preference records are preserved.
The nine undisclosed RD supplement cells and the existing list/person-vote source
inconsistencies remain documented and unchanged.
