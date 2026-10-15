# 2003 referendum implementation and validation

Only the final 14 September 2003 euro referendum is implemented. Valmyndigheten
XML is authoritative; no SCB/SND observations replace its complete final counts.
No preliminary reconstruction, party interpretation, candidate identity change,
release or modification of preserved raw files is involved.

## Interface and observation unit

- English: `results(2003, election = "referendum")`; short form `"F"`.
- Swedish: `valresultat(2003, val = "F")`.
- Levels: national, county, parliamentary constituency, municipality, municipal
  constituency and district. The default is national.
- One row per election occasion × count stage × geographic unit × valid voting
  option. The option key is `JA`, `NEJ` or `BLANK`; `is_blank_option` identifies
  the valid blank category. `OG` remains a geographic invalid-ballot total.
- No `party_*`, candidate, mandate or elected fields occur in referendum output.
- Geographic totals repeat on three option rows; do not sum totals across options.
- Values such as `count_stage = "slutlig"` and geographic-level source values
  follow the existing name-only English/Swedish translation contract.

## Geography and denominators

District output contains **6,372** units: **5,976 ordinary + 396 Wednesday**,
with distinct codes and `district_type = "ordinary" / "wednesday"`. Wednesday
keys, e.g. `F-0114-01`, are preserved. Their electorate and turnout are typed
missing values. Ballots cast for Wednesday units are exactly valid + invalid.

Municipal constituency output has **185 actual constituencies in 79 divided
municipalities**. The 211 technical `00` containers in undivided municipalities
are not public constituencies; original codes/names remain full-only source
fields. Districts retain county, municipality, parliamentary constituency and,
where applicable, municipal constituency context. Existing RD/RF/KF outputs
are unaffected by this separate dispatch/projection.

Blank counts are part of valid votes. `vote_share` uses valid votes, including
Blank. `turnout` uses cast / published eligible voters. Source rounded
percentages are full-only; normalised proportions use exact counts. The
published electorate reference date is 15 August 2003.

## Sources and preservation

The retained inventory is [SOURCE_INVENTORY_2003.md](SOURCE_INVENTORY_2003.md),
including official URLs, source fingerprints and the explicit completeness
matrix. The local preserved source directory contains `final.xml`, the 290
files in `final-municipal/` and `source-manifest.json`. Local access verifies
recorded sizes/MD5/SHA256 when that manifest is present. Remote access uses the
existing bounded/retrying R download helper and validates final referendum
identity and ballot categories before returning observations.

`auto` uses suitable configured local raw files; otherwise it uses the official
remote final source. It does not enable automatic unpublished canonical use.
`canonical` requires an explicitly configured local manifest, uses existing
asset size/SHA256/cache validation, and remains conceptually canonical.
Historical raw input is read-only: update/archive flags are rejected with an
informative message; preservation is a separate acquisition workflow.

SND DOI: <https://doi.org/10.5878/xhnt-ek46>. The two local workbook checksums
match the supplied archive checksums. SND is SCB-derived, not an independent
original count. SCB's official county Excel and municipal share comparison are
independent publication controls. The exact requested SCB result PDF remains
unrecovered and is **not a blocker**: the counts are verified through the
alternative official tables, SCBDOK and Valmyndigheten XML. No claim is made
that those documents are the missing PDF.

## Local canonical prototype and reproducible validation

The public package and build/validation workflow are R-only. Optional
`nanoparquet` is needed for canonical preparation/reading; `readxl` is a
**development validation** dependency for the preserved workbooks, not a
package runtime dependency.

```sh
Rscript data-raw/build-canonical-2003.R SOURCE_DIRECTORY EMPTY_OUTPUT_DIRECTORY
Rscript data-raw/validate-canonical-2003.R SOURCE_DIRECTORY SND_ZIP OUTPUT_DIRECTORY
```

The prototype has one English-schema asset,
`referendum2003-results-final.parquet`, with six level tables distinguished by
`.table` and recorded layouts in `manifest.json`. It has **20,694 rows**:
3 national, 63 county, 87 parliamentary constituency, 870 municipality,
555 municipal constituency and 19,116 district rows. The build records 291
primary XML checksums, source selection, Git SHA, dirty-tree status and asset
size/SHA256. Data version is unpublished `data-v0.0.0`, schema version 2;
this working-tree build truthfully records `build_tree_dirty = true`.
No existing canonical assets or release are replaced.

The independent validator parses XML counts separately from production
normalisation, compares every source unit/option, checks SND/SCB controls and
all six public levels × two languages × standard/full × raw/canonical. Tests
also cover blank validity, invalid separation, unsupported preliminary/year/
level requests, Swedish wrappers, option integrity and Wednesday missingness.
The opt-in complete-source test uses `SWEELECTIONS_REF2003_ROOT`; it is skipped
when preserved raw data are not configured.

## Explicit remaining source dimensions

- Final reported option votes, valid/combined-invalid/cast totals and geography:
  **COMPLETE**, with the verified unit counts above.
- Ordinary/aggregate electorates and turnout: **COMPLETE** for published values.
- Wednesday standalone electorate/turnout: no fields for all **396** units;
  not fabricated because these are extra counting roles, not extra populations.
- Invalid-reason decomposition: absent beyond combined OG at all inspected levels.
- Full preliminary stage: **NOT VERIFIED**; zero separately preliminary
  Wednesday units recovered. Election-night data remain provenance only.
- Requested SCB result publication and external DTD: **NOT VERIFIED**, as
  recorded in the source inventory; no final vote observations are missing.

These source dimensions are not silently repaired or inferred.

## Exact canonical schema

All stored columns are English. The physical Parquet file is the union of the six **full** layouts below, plus technical `.table`; the manifest records the exact columns for each view. `standard` is only a projection, with identical rows, keys, types and shared values.

### `riket`

Standard (21 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (8 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`

### `lan`

Standard (23 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `county_code`, `county_name`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (8 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`

### `riksdagsvalkrets`

Standard (25 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `county_code`, `county_name`, `constituency_code`, `constituency_name`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (8 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`

### `kommun`

Standard (27 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `municipality_code`, `municipality_name`, `county_code`, `county_name`, `constituency_code`, `constituency_name`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (8 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`

### `kommunvalkrets`

Standard (29 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `municipality_code`, `municipality_name`, `county_code`, `county_name`, `constituency_code`, `constituency_name`, `municipal_constituency_code`, `municipal_constituency_name`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (10 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`, `source_municipal_constituency_code`, `source_municipal_constituency_name`

### `valdistrikt`

Standard (32 columns):

`election_event`, `election_year`, `election_date`, `election_code`, `count_stage`, `referendum_question`, `geographic_level`, `district_code`, `district_name`, `municipality_code`, `municipality_name`, `county_code`, `county_name`, `constituency_code`, `constituency_name`, `municipal_constituency_code`, `municipal_constituency_name`, `district_type`, `voting_option_code`, `voting_option_name`, `is_blank_option`, `votes`, `vote_share`, `valid_votes`, `blank_votes`, `invalid_votes`, `total_votes`, `eligible_voters`, `turnout`, `counted`, `area_districts_counted`, `area_districts_to_count`

Full-only additions (10 columns):

`source_unit_code`, `source_unit_name`, `source_node_type`, `source_file`, `source_last_update_time`, `reporting_time`, `source_vote_percent`, `source_turnout_percent`, `source_municipal_constituency_code`, `source_municipal_constituency_name`


## Final executed validation results

- Independent XML controls: all **6,372 units**, **290 municipality sums**, **396 source containers** and national/county/parliamentary-constituency totals passed. No vote discrepancies.
- SND: **5,976 ordinary district rows + 290 municipal summaries**, seven exact count fields, all passed.
- SCB: **22 county/national rows**, seven count fields, and **290 municipal Ja/Nej share pairs**, all passed.
- All **six** public levels passed raw/canonical, standard/full, English/Swedish and wrapper comparisons; source option keys/counts were independently matched.
- Canonical prototype: **20,694 rows**, **43 physical columns including `.table`**, **551,377 bytes**, SHA256 `9cc51181bc44f3db01567ed41985aaae90572ff46a8d905271cfc21a90bc0cf4`; Parquet round trip and manifest/asset checks passed.
- Full tests with the complete-source referendum test enabled: **3,458 passed, 10 explicit skips, 0 failures, 0 warnings**. Focused post-portability-fix tests: **26 passed**; actual-source national/canonical equality also passed.
- Final `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**, `Status: OK`. The check used a staging copy filtered by `.Rbuildignore` because Windows initially tried to copy excluded long-path local caches before building. An initial non-ASCII code warning was corrected using equivalent Unicode escapes; no data values changed.
- Final source integrity: **601/601** preserved HTTP objects match recorded size/MD5/SHA256; original SND ZIP MD5 unchanged. No raw or published assets changed.
- `git diff --check` passed. No raw sources, SCB/SND files, Parquet assets or Python files are tracked.

This is a validated **uncommitted working-tree prototype**, not a clean-commit data release. No commit, push, tag or publication was made.
## Electorate composition (follow-up before commit)

The three groups are now substantive standard/full variables:

| English | Swedish | Meaning |
|---|---|---|
| `eligible_swedish_citizens_in_sweden` | `antal_rostberattigade_svenska_i_sverige` | Eligible Swedish citizens in Sweden, excluding the separately reported abroad group |
| `eligible_swedish_citizens_abroad` | `antal_rostberattigade_svenska_utomlands` | Eligible Swedish citizens resident abroad |
| `eligible_foreign_citizens` | `antal_rostberattigade_utlandska` | Eligible foreign citizens |

All are nullable integers and are repeated on the valid option rows like
`eligible_voters`. They are populated for **21 counties and Sweden only**.
The source's first-time-voter column is overlapping information and is **not**
a fourth electorate component.

National values: **6,648,244 + 106,003 + 323,255 = 7,077,502**. Each of the 21
county component sums equals its Valmyndigheten electorate, and the county
components sum exactly to the corresponding published national components.

Source: SCB's previously identified official
[Röstberättigade vid folkomröstningen om euron 2003](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/folkomrostningar-valresultat/pong/tabell-och-diagram/ovriga-folkomrostningar/rostberattigade-vid-folkomrostningen-om-euron-2003/).
The preserved HTML and a separate provenance sidecar record URL, acquisition
UTC, bytes, MD5 and SHA256. Existing raw objects and their manifest were not
rewritten. The new canonical manifest records this SCB source separately from
the 291 primary Valmyndigheten result XMLs. Original result counts, electorate
totals, turnout and denominators remain authoritative Valmyndigheten values.

**Why finer-level fields remain missing:** neither the Valmyndigheten result
XML nor the two SND workbooks contains the three component columns; SND exposes
only `Total röstberättigade`. The SCBDOK register and variable descriptions document `rbrsv`, `rbrutsv`
and `rbrutl` in underlying district registers, but the documented register is
not the actual preserved SND XLSX. Its component observations have not been
recovered. The public SCB table has only counties and the country. Consequently
components remain typed `NA` for all **290 municipalities**, **29 parliamentary
constituencies**, **185 public municipal constituencies**, and **5,976 ordinary
districts**. No county values are allocated downward, including coextensive
reporting areas. For **396 Wednesday units**, electorate and all components
remain missing because these units have no independent electorate denominator.

| Composition dimension | Status | Evidence/gap |
|---|---|---|
| County and national components | **COMPLETE** | 21 counties + Sweden, exact group/total reconciliation |
| Municipality, constituency and ordinary-district components | **NOT VERIFIED** | Underlying fields documented, but no preserved component records at these levels; exact populations above |
| Wednesday standalone components | **INCOMPLETE** as standalone fields | All 396 units lack an independent electorate; no denominators/components invented |

A local raw archive without the optional SCB supplement retains typed missing
components. The extended canonical builder requires the preserved supplement
and its provenance, so the canonical county/national coverage is deterministic.
Remote nation/county requests retrieve the same SCB table using the existing
R download helper. Header order, count syntax, group sums, county coverage,
county-to-national sums and Valmyndigheten total agreement are validated before
enrichment.

**Blank semantics are unchanged and explicit:** `BLANK` is one of the three
valid referendum ballot options in 2003. `valid_votes = JA + NEJ + BLANK`;
`total_votes = valid_votes + invalid_votes`. Blank is not part of
`invalid_votes`. Electorate enrichment never changes any ballot count or share.

The earlier 43-column prototype and executed checks above are the pre-enrichment
reference. The extended physical Parquet schema has **46 columns** (three new
integer fields plus the original columns including `.table`), with the same
20,694 rows and six views. Add the three new fields to every exact standard/full
layout listed above; unavailable finer values are typed missing. New standard
column counts are 24/26/28/30/32/35 for national/county/parliamentary
constituency/municipality/municipal constituency/district respectively.

### Executed electorate follow-up validation

`data-raw/validate-electorate-2003.R SOURCE_DIRECTORY EXTENDED_BUILD ORIGINAL_BUILD`
passed: all 22 SCB group totals, county-to-national sums, agreement with the
Valmyndigheten electorate, and all 16 national/county raw/canonical × language ×
detail pairs. The entire original **43-column** asset is an identical projection
of the extended **46-column** asset across all **20,694 rows**. All finer-level
component columns remain `NA_integer_`; Blank-valid and invalid-separate
arithmetic passed for every unit in every stored view. Parquet round trip and
source/asset checksums passed.

Extended local asset: **552,678 bytes**, SHA256
`9273c0bfbe2ffdd40ab43b367aee3bbd13bd0c0466b19c36afa50bf171badceb`.
SCB HTML: **29,487 bytes**, retrieved **14 October 2026 20:46:42 UTC**, MD5
`9fb1fab7329f529eee3fadc6e51b43ee`, SHA256
`7ff1c0c41f306dd6cd93b490af3bcbe99d4dd7ec39887436a406b24c76302b8e`.

Regression suite: **3,449 passed, 11 explicit skips, zero failures/warnings**.
The complete-source geography test was not re-enabled in this narrow follow-up;
its prior successful run is retained above, and all its stored result values
are covered by the exact whole-asset projection regression. The dedicated
focused referendum tests now include group coverage, disjoint sums, header
meaning/order, and typed missingness. No commit or push was made.
Final follow-up `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings,
0 notes**, `Status: OK`, using the same package-content staging procedure.
`git diff --check` passed. Original Valmyndigheten, SND and SCB sources were not
modified; the newly preserved SCB HTML is local and separately recorded. No
published assets, tag, release, commit or push were created.

### Approved completeness scope and clean-build procedure

The three electorate components are **COMPLETE for Sweden and all 21 counties**,
but **unavailable in the preserved/implemented sources for all 290 municipalities,
5,976 ordinary districts and 396 Wednesday units** (also 29 parliamentary and
185 actual municipal constituencies). No downward allocation or zero imputation
has been made. Underlying register metadata is not evidence of recovered values.
Blank is a valid option and is excluded from `invalid_votes`.

The earlier working-tree validation is the approved reference. Finalisation
commits this implementation locally, rebuilds from that clean commit with
`build_tree_dirty = false`, compares the asset bytes to the approved extended
prototype, reruns the independent controls/public equivalence and package checks,
and pushes only after success. Generated assets and clean-run logs remain local;
no data release or tag is part of this operation.
