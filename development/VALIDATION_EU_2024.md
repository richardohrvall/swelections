# EU 2024 implementation and validation

## Source decision and candidacy exception

Valmyndigheten's final and full preliminary JSON ZIPs are authoritative. The
original elected/substitute relations are taken from the final result, not a
later parliamentary-term roster. The approved December candidate ZIP is used
without combining attributes from other snapshots. Its key/validity population
is identical to the 11 June file: 1,395 candidacy rows, 1,390 valid rows,
1,340 distinct valid candidate numbers and 1,385 valid candidate/party pairs.

Final candidacy coverage is **COMPLETE WITH SPECIFIED EXCEPTIONS**: candidate
1203, Felix Österberg, Folklistan (1659), has a valid consent-only candidacy in
the recovered export generated on 9 June. This record is absent from both later
snapshots. The administrative reason is unknown. The earlier record is retained
only as historical provenance; it is not added to the approved final population.
No preference-vote, elected or substitute record has been identified for 1203.
This exception does not affect final party votes, reported preference votes,
mandates or original elected/substitute relations. No further recovery is required.

The archived ZIP SHA256 is
`e408dbdf9b96b1b075b1463d707e11854e415524f1ec88cdf9fbd187ac27b2db`;
its CSV SHA256 is
`c47cd8e967c4dbc72d3fd7293aea1199c103c005729eb1c3cd64a456768c5375`.
See [the snapshot reconciliation](EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md)
and [source inventory](SOURCE_INVENTORY_EU_2024.md) for URLs, capture timestamps,
original-source checksums and the approved selection decision.

## Public interface and geography

All seven English functions support explicit `election = "european"` or `"E"`;
Swedish functions use `val = "E"`. The supported election year is 2024.
Existing RKL defaults are unchanged: supplying year 2024 does not implicitly
select a different election. The same implementation serves both naming
languages and both detail levels. Column-name translation does not translate
source values or resolve candidate identities from names.

`results()` supports `national`, `county`, `municipality`,
`municipal_constituency` and `district`. `seats()` is national.
`preference_votes()` supports those five levels plus `preference_vote_area`
(the national personal-election area). Subnational qualification is missing.
Candidacy geography and original elected geography retain their distinct roles.

Verified coverage is one country, 21 counties, 290 municipalities, 41 actual
municipal constituencies in 17 divided municipalities, and 6,589 districts:
6,275 ordinary plus 314 collection districts. Technical `00` constituency
containers in undivided municipalities do not create new public geographies.
Collection districts have no independent eligible-voter denominator or turnout.

`local` uses preserved official sources, `remote` uses the official endpoints,
and `auto` uses suitable local sources before official remote access. EU 2024
is not registered for automatic canonical selection. Explicit `canonical` uses
an explicitly configured unpublished local manifest. This does not publish or
reclassify a canonical cache as raw local data. Updating/archiving through the
EU adapter is explicitly read-only; source acquisition is a separate operation.

## Votes, candidates and election relationships

| Quantity | Verified final value |
| --- | ---: |
| Valid party votes | 4,198,011 |
| Invalid ballots | 42,448 |
| Blank ballots (included in invalid) | 33,733 |
| No participation notification (included in invalid) | 777 |
| Other invalid ballots | 7,938 |
| Ballots cast | 4,240,459 |
| Eligible voters | 7,942,272 |
| Allocated mandates / elected persons / unfilled mandates | 21 / 21 / 0 |
| Distinct substitutes / member-substitute relations | 27 / 77 |
| Positive district/party/list/candidate preference observations | 393,607 |
| Reported preference votes, including ineligible candidacies | 1,914,494 |

Blank is invalid in this election, unlike the separately valid Blank option in
the 2003 referendum. All 100 separately reported positive parties are retained.
The final residual other-party vote total is zero.

All 635 national list/candidate preference rows match the candidate CSV by
party, list, candidate number and position. All 109,611 district list-total
controls and 129 national list-total controls reconcile. The five invalid
candidacies retain their official positive preference observations (2,324 votes)
in `preference_votes()` and source candidacies. They are not added to the valid
candidate population: `candidates()` has 1,385 candidate/party rows, with 626
positive totals, 759 zero totals and no missing totals; its preference-vote sum
is 1,912,170. This 2,324-vote population difference is explicit, not missing data.
No candidate identity harmonisation or name-based matching was introduced.

Zero completion applies only to documented candidates on observed printed lists.
It does not invent list observations for consent-only candidacies. Candidate
aggregation sums list votes while retaining the first reported source name.
National shares use party vote denominators; list shares use list denominators.
Qualification is available only in the national personal-election scope.

## Preliminary snapshot and external controls

The complete preliminary JSON snapshot (13 June) includes all 314 collection
units. It reports 4,178,527 valid votes, 60,224 invalid ballots and 4,238,751
ballots cast. It is not reconstructed by adding the earlier 11 June spreadsheet
(which is a different reporting snapshot). No `election_night` public stage was
introduced and final collection results do not fill preliminary values.

SCB uses 6,275 ordinary districts and 290 merged municipal collection/postal
units, compared with Valmyndigheten's 314 collection districts. These structures
are reconciled by municipality, without duplicating votes. SCB's ordinary
eligible-voter, ballots-cast, valid, invalid and blank counts agree with the
Valmyndigheten district source; national counts agree. The official preference
Excel independently matches all 393,607 positive district/list/candidate rows.

SCB's ordinary-district electorate decomposition sums to 7,942,272:
7,708,624 Swedish citizens resident in Sweden, 190,459 Swedish citizens abroad
and 43,189 eligible foreign EU citizens. These breakdowns remain independent
validation material in this implementation; no new EU electorate-composition
columns have been added. `eligible_voters` comes from Valmyndigheten.

## Unpublished canonical prototype

All assets use English canonical names and schema version 2, preserving source
values and types. Normalised preference components use the same vocabulary as
analysis outputs. Source-only unit/list/name representations have explicit
`source_*` fields. Each file passed an exact Parquet write/read round-trip.

| Asset (`.parquet`) | Rows | Bytes |
| --- | ---: | ---: |
| eu2024-results-final | 103,348 | 2,377,642 |
| eu2024-seats-final | 8 | 9,858 |
| eu2024-results-preliminary | 62,478 | 1,911,835 |
| eu2024-seats-preliminary | 8 | 9,852 |
| eu2024-candidacies | 1,395 | 35,717 |
| eu2024-candidates | 1,385 | 31,720 |
| eu2024-elected | 21 | 9,950 |
| eu2024-substitutes | 77 | 8,035 |
| eu2024-candidate-base | 1,385 | 26,250 |
| eu2024-preference-base-area | 915 | 12,300 |
| eu2024-preference-base-national | 915 | 12,300 |
| eu2024-preference-base-county | 11,219 | 39,253 |
| eu2024-preference-base-municipality | 76,250 | 182,577 |
| eu2024-preference-base-municipal-constituency | 15,328 | 49,484 |
| eu2024-preference-base-district | 598,435 | 1,492,163 |

Total Parquet size: **6,208,936 bytes**, 15 assets. Component row counts include
list denominators, party denominators, geography and qualification records;
they are not counts of positive preference observations.

The local prototype is under `.local-data/canonical-build/eu-2024-prototype-final`.
Its manifest records base commit `c65242a2108b0c74379c73881af8e11923fb1cfb`,
`build_tree_dirty = true`, unpublished `data-v0.0.0`, and `auto_eligible = false`.
Manifest SHA256:
`1a52b65c5fa4cd877f132491e4c88366860251c7c4f99662666b3b7fbccd4730`.
This is a working-tree validation build, not a clean release build.

## Reproduction and checks

Run with the documented R development dependencies (including optional
`nanoparquet` for builds and `readxl` for independent spreadsheet checks):

```sh
Rscript data-raw/build-canonical-eu-2024.R RAW_ROOT EMPTY_OUTPUT_DIRECTORY
Rscript data-raw/validate-eu-2024.R RAW_ROOT OUTPUT_DIRECTORY
```

Set `SWEELECTIONS_EU2024_ROOT` to the preserved EU archive to enable the targeted
integration tests, then run `devtools::test()`. No Python is required.

The full test suite passed **3,510 assertions**, with **11 explicit skips**,
**zero failures and zero warnings**. `R CMD check --no-manual --no-vignettes`
completed with **zero errors, warnings or notes**. The checked source tarball
was assembled from 181 checksum-verified intended package files, excluding the
raw archive, canonical assets and development-only material.

Independent source checks verify all 17 original EU files remain unchanged.
All 112 protected Parquet assets from the validated 2010, 2014, 2018 and 2022
builds, including the published 2018 release, retain their recorded checksums.
The archived candidate ZIP also retains its recorded checksum.

The exhaustive public canonical/raw sweep passed all **41 variants**: ten
result level/count combinations, two seat snapshots, four candidate/relation
functions, the candidate base without result enrichment, and 24 preference
level/list/zero combinations. Each compares English/Swedish and standard/full
outputs, preserving row counts, column types, shared values and projection.
The largest views contain 3,092,601 candidate/district rows and 3,093,041
list/candidate/district rows after verified zero completion.

The independent JSON checks passed district (88,578 party rows), municipality
(5,949), county (768), national (100) and municipal constituency (1,011)
comparisons. Strict original elected/substitute ordering, party, identifier,
basis and geography checks passed, as did mandate counts and Excel/SCB controls.

During validation, an extra closing parenthesis was found in the new independent
substitute-reference expression. It was corrected in the development validator,
without a production change. The original long-running sweep had already read
the earlier expression: it passed all 41 API variants before stopping at that
syntax error. The corrected original-relations/Excel/integrity section was
therefore rerun separately and completed successfully. The maintained full
validator parses successfully with that correction; no comparison was weakened.

## Explicit completeness statement

- **COMPLETE:** final party/ballot totals, all named geographic populations,
  reported positive district/list/candidate preference observations, national
  mandates, original elected persons and substitute relations.
- **COMPLETE WITH SPECIFIED EXCEPTIONS:** approved later final candidacy
  population; the sole documented earlier-only record is candidate 1203/1659,
  excluded as decided above. No other final source row is dropped.
- **COMPLETE:** the full preliminary JSON reporting snapshot, including its
  collection units; a separate original election-night freeze is **NOT VERIFIED**.
- **NOT VERIFIED:** a complete dated mandate-period event history. The original
  21 elected persons and 77 substitute relations are complete; a current roster
  is not a substitute for an event log.
- **NOT VERIFIED:** a 2024 SND comparison, because no local SND source was
  identified. The independently completed SCB and Valmyndigheten controls do
  not require an SND replacement source.

No source, historical canonical asset or published release was modified. No
commit, push, tag or release is part of this implementation task.
