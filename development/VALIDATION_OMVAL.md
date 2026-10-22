# Re-election validation and review report

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


Implementation date: 17 October 2026. No commit, push, tag or release was made.
No original source or existing canonical asset was rebuilt or edited.

## Final API

```r
election_events(election_kind = "re_election")
results(year = 2011, election = "municipal", election_kind = "re_election")
seats(year = 2011, election = "municipal", election_kind = "re_election")
seats(year = 2010, election = "municipal", after_re_election = TRUE)
seats(from = 2002, to = 2022, election = "municipal", after_re_election = TRUE)
```

Preserved raw inputs must be configured; see [source setup](IMPLEMENTATION_OMVAL.md).
These municipality selections cover all selected municipal areas, not just
Örebro. Filter `municipality_code == "1880"` to inspect its composition.

Ordinary elections remain the default. `election_kind = "all"` returns distinct
polling events, with ordinary rows also receiving registry event metadata.
`after_re_election` instead anchors year/range on original ordinary elections;
replacement years can lie outside that requested range. It requires final,
ordinary allocations and one whole-area level. With no explicit level, the
composition uses municipality/region/national, avoiding simultaneous overlapping
seat views. An ordinary year without a replacement keeps its original allocations.

There is no `effective_seats()` export, no after-re-election vote/turnout view,
no arbitrary as-of query and no membership-history or physical-person linkage.

## Verified events and compositions

All five real-source public event readers and all five real-source composition
requests passed. The original ordinary-country archives were read, not replaced.

| Event | Valid votes | Event seats | Effective affected-body seats | Component years |
|---|---:|---:|---:|---|
| Orsa 2003 KF | 4303 | 31 | 31 | 2003 |
| Västra Götaland 2011 RF | 545215 | 149 | 149 | 2011 |
| Örebro Nordöstra 2011 KF | 17335 | 17 | 65 | 48 seats from 2010 + 17 from 2011 |
| Båstad 2015 KF | 7494 | 41 | 41 | 2015 |
| Falun 2019 KF | 27788 | 61 | 61 | 2019 |

The new adapter initially missed collection-node ballot accounting in the old
Orsa XML family. Source inspection established that `OG` is combined invalid
ballots, not other-invalid ballots. The adapter now preserves the combined
count and derives collection ballots cast as known valid + known invalid
(110 + 1 = 111); blank/other-invalid decomposition remains missing. The
2015/2019 adapters likewise use only complete source-reported invalid-category
partitions. A targeted regression covers these semantics and missing components.
Existing historical readers were not modified.

## Public/source validation

`development/validate-re-elections.R` independently checks official aggregate
controls and calls the public APIs for each event:

- **17 table/level combinations passed in the final run**, each checked in standard/full and English/
  Swedish, with identical shared columns and rows.
- District populations: Orsa 6, VG 1025, Nordöstra 24, Båstad 10, Falun 37,
  including the separately identified collection units.
- Party-vote sums, valid votes, ballots cast and ordinary-district electorates
  reconcile to the controls; collection electorates remain missing.
- VG municipality and all five regional-constituency aggregations reconcile.
- Event identifiers, polling years, scopes, original-event links and continuing
  mandate periods agree with the registry.
- No duplicated event/geography/party source keys.
- **34 Parquet round-trips** preserve values, types, row order and column names.
  These are temporary validation files, not a new canonical release/prototype.
- **54 original omval-file SHA256 values remain unchanged.** Reviewed input
  hashes are also enforced by the public event readers.

The final source run uses the official eight-party metadata lookup. Its source is
`https://historik.val.se/val/om2011/valsedlar/K/kommun/18/80/valsedlar.html`,
SHA256 `0283005973c0a82cf21623e624b3547119240b80afb16bcca2bc2f33fb2a2d1e`.
Only source-supported party identifiers/labels are enriched.

The registry-driven 2011 readers were additionally compared with those validated
Parquet tables after centralising scope/source metadata: RF/KF results and seats
were identical at that stage. The final implementation additionally fills eight
party IDs/labels from independently preserved official ballot anchors; this
documented metadata enrichment does not change votes or seats. Scope names/codes
and comparison-file stems are registry data,
not hard-coded Örebro/Västra Götaland branches in the readers.

Real-source post-re-election checks used original-year readers, verified rerun
party allocations and (for Örebro) the original constituency allocations checked
against the official 2011 comparison. The resulting 32 Örebro component/party
rows sum to 65 seats, split exactly 48/17 between the source events. Other
whole-area compositions reproduce the verified replacement allocations.

The actual public `seats(from = 2002, to = 2022, election = "municipal",
after_re_election = TRUE, source = "local")` request also passed for all six
original election years. Orsa/2002, Orebro/2010, Bastad/2014 and Falun/2018
reproduce 31/65/41/61 seats, with Orebro split 48/17. The 2006 and 2022 rows
retain their original component years. The first run stopped because the 2022
prepared raw archive was not under the common archive root; the completed run
used a temporary local root linking to each existing year archive, including
the validated R-only 2022 staged inputs. No raw files or production code were
changed to address that configuration issue.

Deterministic regressions additionally cover ordinary defaults, informative
rerun-only-year errors, all-event selection, year ranges, original-year anchoring,
standard/full, Swedish wrappers, missing-source failure, wrong party allocations,
and successive replacements within one continuing mandate period.

## Reproducing the source validation

From the repository root, with the preserved archive and Orsa rerun XML:

```sh
Rscript development/validate-re-elections.R ARCHIVE_ROOT ORSA_RERUN_XML OUTPUT_DIR
```

The output directory is local build material and must not be committed. The
validator records the 17 API/source checks and checksums for its 34 temporary
Parquet round-trips. It does not create or publish a canonical release.

## Existing canonical/ordinary regression protection

Existing manifests verified **92 unchanged canonical files**:
2010 (24), 2014 (24), published 2018 (20), 2022 (24).
All recorded sizes and SHA256 values matched. No rebuild was performed.

Published 2018 RD/RF/KF `results()` and `seats()` were also compared through the
public API against the preserved raw route: **six exact full-output comparisons
passed**. The canonical cache used for these checks was isolated from the assets.

New re-election canonical/raw routing is not claimed: no re-election canonical
release/manifest exists. Explicit rerun `source = "canonical"` fails clearly;
the new output schemas were tested through local Parquet round-trips instead.

## Tests and package check

- Complete test suite: **3782 passed, 16 explicit skips, 0 failures, 0 errors,
  0 warnings**. The skips concern opt-in external integrations; they are not
  represented as passing. The separately run source/canonical checks above
  provide the relevant real-data evidence for this implementation.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**
  (`Status: OK`, exit status 0).
- The first direct package build was stopped because R attempted to copy ignored
  raw archives into its temporary staging directory. Checks use a Git-visible
  source stage containing tracked and intended new files, with the unchanged
  `.Rbuildignore` rules; raw sources and generated assets are excluded.
- An initial check warning about non-ASCII R literals was corrected using
  Unicode escapes. Parsed-code equality was verified before/after that change.
- `git diff --check` passed. Untracked intended text files are checked separately
  for trailing whitespace and conflict markers.

## Schema changes

Existing ordinary/candidate schemas and canonical assets remain unchanged.
Only the new event/all-event/composition views add metadata to both standard
and full, so provenance is not lost in the standard projection.

Event metadata: `election_event`, `election_date`, `election_kind`,
`original_election_event`, `mandate_period`, `event_scope_level`,
`event_scope_code`, `event_scope_name`, `source_file`, `source_sha256`,
`source_url`, `protocol_reference`, `electoral_roll_reference_date`.
Some of these existed in full ordinary outputs; new ordinary default outputs
are not changed to add them.

Composition metadata: `composition_id`, `composition_type`,
`component_election_event`, `component_election_year`,
`component_geographic_level`, `component_geographic_code`.
The primary `election_year` remains the original year. Components may occupy
several rows for the same party/municipality; sum `seats`, not repeated
`total_seats`. The shared name map provides the Swedish equivalents.

## Explicit remaining limitations

1. Reruns currently use preserved local final sources. Remote and canonical
   rerun routes are unavailable; no automatic download/release was introduced.
2. Preliminary rerun results remain unsupported, including Falun pending a
   separately validated adapter. Final figures never fill preliminary gaps.
3. Orsa's eight signed protocol attachments remain unrecovered. Its separately
   labelled official rerun XML and reconciled historical presentation provide
   the party allocations; the missing attachments remain a provenance gap.
4. Exact annulment decision identifiers/dates not established in the source
   review remain missing. Count/report dates are not substituted for separately verified legal decision or service dates.
5. The 2011 comparison SKVs identify parties by abbreviation. Eight official
   party IDs/labels are supplied by the documented ballot-anchor lookup, with
   URL and SHA256 provenance. Other unsupported IDs remain missing. Allocated
   seats are known; unfilled counts absent from the comparison tables remain
   typed missing values.
6. Re-election support for candidacies/candidates/elected/substitutes/preference
   votes was outside the approved implementation boundary. Those readers and
   their existing observations, identities and names remain unchanged. Båstad's
   six result-only IDs remain documented rather than silently discarded.
7. Additional geographic levels beyond those listed in IMPLEMENTATION_OMVAL.md
   fail explicitly. No technical `00` constituency is invented as a substantive
   constituency. Future partial replacements require verified component inputs.
8. No full mandate-period history, effective vote composite or physical-person
   harmonisation has been implemented.

## Exact changed-file inventory

Production and mapping:
`R/re_elections.R` (new), `R/api_english.R`, `R/output_names.R`,
`R/zzz_public_wrappers.R`, `NAMESPACE`,
`inst/extdata/re-election-party-identifiers-2011.csv` (documented metadata lookup).

Roxygen source documentation only:
`R/api_mandat.R`, `R/api_valresultat.R`.

Tests:
`tests/testthat/test-re-elections.R` (new),
`tests/testthat/test-release-contract.R` (expected new discovery export).

Documentation/tooling:
`README.md`, `man/results.Rd`, `man/seats.Rd`, `man/mandat.Rd`,
`man/valresultat.Rd`, `man/election_events.Rd` (new),
`development/IMPLEMENTATION_OMVAL.md` (new),
`development/validate-re-elections.R` (new),
`development/VALIDATION_OMVAL.md` (this report).

The three untracked files from the preceding approved inventory are retained:
`development/SOURCE_INVENTORY_OMVAL.md`,
`development/SOURCE_INVENTORY_OMVAL_FILES.csv`,
`development/SOURCE_INVENTORY_OMVAL_RETRIEVAL.csv`.

No raw source files, archived source objects, SCB/SND data, generated Parquet
files or package-check outputs are intended for Git tracking.

## User-facing documentation clarification, 18 October 2026

The installed results, seats and event-discovery help now explains separate
re-election events within the original continuing mandate period. Seats help
distinguishes actual event years from original-year selections and output with
`after_re_election = TRUE`, ordinary/default levels from whole-area composition
levels, and allocated event seats from derived component rows. The general
seats description is no longer nested in an argument. Examples cover all five
events and compositions; the README explicitly filters the Örebro composition
to municipality 1880. Swedish argument descriptions use `valklass` and
`efter_omval`, with the supported ordinary-year list corrected. Preserved local
final-source requirements and unsupported source operations are explicit.

This step changes only roxygen comments in `R/api_english.R`, `R/api_mandat.R`,
`R/api_valresultat.R`, `R/re_elections.R`, their five generated help pages,
`README.md`, and this validation report. Parsed R expressions in all four files
are identical before and after the documentation change. API signatures,
ordinary-election behaviour and the approved model are unchanged.

Repeated validation after regeneration passed:

- Full tests: **3782 passed, 16 explicit skips, zero failures/errors/warnings**.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**.
- All **17** preserved-source/API variants, standard/full and English/Swedish.
- All **34** Parquet round-trips; their files are byte-identical to the approved
  implementation's validation outputs.
- All **54** original source hashes and **100** successful preserved web objects
  retain their recorded checksums; web-object sizes and MD5 also match.
- All **92** protected historical canonical files retain manifest sizes/SHA256.
- Final diff/whitespace review passed; no raw or generated assets are tracked.

No canonical build, source edit, commit, push, tag or release was performed.
