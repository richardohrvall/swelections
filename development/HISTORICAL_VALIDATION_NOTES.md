# Consolidated historical validation notes

This document preserves lasting evidence from retired working plans, early release
reviews and genrep integrations. Original work reports remain in Git history;
superseded local copies have been removed. Their old counts, API layouts and status
claims are not current contracts. The exploratory notebook is not a build input.
Frozen tests and current source-specific reports remain authoritative.

## Early 2026 source observations

The September 2026 genrep integrations used final RD 00, RF 01 and KF 0114/0180
ZIPs. RD covered its full file; RF/KF covered only those areas. Sixteen file/level
checks covered thirteen distinct combinations. Eleven cross-level party-vote
comparisons had no differences. These were test snapshots, not national RF/KF
coverage, and neither missing files nor missing OS summaries were replaced remotely.

Genrep elected rows did not always resolve to the candidate register (349 raw RD
relations versus 347 matched candidate keys). Such test-source inconsistencies
must not be hidden by changing production identity or election semantics. A control
character in one KF text field was also recorded; it was a source/decoding issue,
not evidence for relaxing numerical availability validation.

The 14 September 2026 preliminary snapshot comprised RD 00, RF 01 and KF
0114/0180. It contained D/M sources and U for RD/RF, but no final or OS files.
All 6,626 RD, 1,460 RF and 641 combined KF districts were represented. Unreported
vote objects remained uncounted with typed missing current values; known geography,
electorate and previous-election context were preserved. Reported party rows
matched their raw nodes and explicit zeros were retained. Party populations for
unreported districts came from the corresponding mandate constituency, with an
area fallback only where that source had no constituency list. The four files
had 350, 64, 1 and 21 unreported districts respectively (RD, RF, KF 0114, KF 0180).

These snapshots did not provide empirical examples of every branch: absent/null
other-party nodes, zero counted districts, final/OS sources and some mismatched
party universes still required deterministic fixtures or later source checks.
No historical integration count should be substituted for a current public schema.

## Durable parser and validation decisions

- Resolve ZIP/member names from the official index, including both genrep names
  and live summary members with the area code. Do not manufacture prefixes.
- The source count label `preliminär` and API value `preliminar` are distinct
  representations. Metadata normalization is explicitly tested.
- Explicit unreported/null result objects differ from missing keys and malformed
  structures. Preserve source zero and unknown separately. Empty results retain
  deterministic types and the request's geographic schema.
- Local requests do not silently download missing files. Invalid election/level
  combinations fail rather than returning a misleading empty data frame.
- Current seat totals are validated against complete components. Explicit historical
  totals remain authoritative; unknown components do not imply zero.
- Use official geography/codes and scope-aware joins. Other-party rows, threshold
  status and candidacy/elected geography have distinct meanings.
- Early raw percentages and the internal 83-column result schema are not the
  current public standard/full contract. Public shares use proportions; absolute
  changes such as 0.025 mean 2.5 percentage points.
- Unicode escaping of R string literals was verified by comparing parsed
  expressions; the retired conversion script is not a build dependency.
- Read-only integrations blocked network/archive writes and compared source hashes
  before and after use. These safeguards remain part of maintained validation.

## Retired material and replacement checks

Old `VALRESULTAT_*`, `RELEASE_0.1.0_*`, `STATUS.md`, and the two early
`PERSONROSTER_*` reports are historical records, not present specifications.
The genrep `integration-valresultat.R`, `integration-personroster.R` and
`integration-release-0.1.0.R` harnesses are retired from the maintained workflow.
They target earlier internal objects/contracts and must not be required by a build.
Their useful checks are represented by deterministic local-source, metadata,
public-schema, raw-reader, mandate and preference-vote tests plus the maintained
opt-in canonical/raw and source validators.

The 2010 implementation plan's lasting decisions are preserved in
[IMPLEMENTATION_2010_VALIDATION.md](IMPLEMENTATION_2010_VALIDATION.md),
[PRELIMINARY_2010_INTEGRATION.md](IMPLEMENTATION_2010_VALIDATION.md) and
[SOURCE_ID_RECONCILIATION_2010.md](SOURCE_ID_RECONCILIATION_2010.md).
The one-time 2014 metadata refresh is obsolete because a fresh builder includes
that operation. The ad hoc 2010 smoke exporter is replaced by maintained source
exports and validators. No source values, identities or assets are changed by
retiring these local workbenches.

## Verified 2026 elected-geography correction

The following is the preserved 21 October 2026 investigation of the pre-v0.4.0
reader. The correction is included in v0.4.0; references to the then-installed
0.3.0.9000 package identify the historical baseline, not the current version.

## Reproduction and exact failing source

The unmodified installed package is version 0.3.0.9000, RemoteSha 39622e7b3e2a37c4b35c272f03fb6535734d9e8f. GitHub origin HEAD was independently checked and is the same commit. This identifies the version tested here; it does not establish a different user installation version without its package metadata.

The exact public call valda(ar = 2026, val = "KF", source = "remote") reproduces the reported nested index 1 / index 9 error. The outer index selects the single year. The inner index is the ninth final municipality ZIP selected in official index order:

- Municipality: Salem, 0128.
- Official file: https://resultat.val.se/resultatfiler/val2026/s/kf/Val_2026_slutlig_0128_KF.zip
- JSON member actually read: Val_2026_slutlig_mandatfordelning_0128_KF.json.
- Party: Vänsterpartiet, code 0005.
- Candidate number: 53411. The elected node reports Pia Lindqvist Ortiz Venegas; the candidacy CSV reports Pia Ortiz-Venegas. Neither spelling nor identifier is changed.
- The candidate is elected in Salem, election order 1. The Salem party row exists: 640 party votes; its summeradePersonroster entry reports 107 preference votes.
- The CSV also contains a Värmdö candidacy (0120), list 09853, position 8. Salem uses list 09838, position 1.

The old semi-join matched candidate number + election type + party, retaining both municipal candidacies. It then required a Värmdö person-vote-area row (0120 / 0005) inside the Salem file (0128). That geographical row does not belong in this file. The error is an implementation error, not evidence that the official Salem export lacks its party row. The candidate has 107 preference votes across the supported candidacy areas, all reported in Salem.

## Official documentation and source preservation

The current [technical description](https://www.val.se/valresultat-och-statistik/statistik-och-data/teknisk-beskrivning-av-resultatfiler) states that final mandate files contain election-area and constituency aggregates plus the information for elected members and substitutes. The [final mandate field description](https://www.val.se/download/18.1a2972da19f159e73fd324f/1786558968669/slut-mandatfordelning.md) documents valomrade, valkretsLista, partiRoster, listRoster and summeradePersonroster. An area file is not a national catalogue of every candidacy held by its elected candidates.

The field description was preserved with URL, UTC retrieval time, bytes, MD5 and SHA256. Its SHA256 is a21f8f03127395805c307c59709b518d11f1a7a508e88a41ac5c78243681f17b. All retrieved index/CSV/ZIP responses are retained only in the ignored audit directory, with the same provenance fields. The official index MD5 is f41e800a0ee50d02cc0701837c7b0e89; candidacies CSV MD5 is c30f47a4ea28da2d926e0e186477a98b. All 290 KF ZIP checksums agree with that index.

## Extent and old versus optimized implementation

| Version tested | RD final | RF final | KF final |
| --- | ---: | ---: | --- |
| Installed published commit | 349 elected | 1,720 elected | Same error at Salem, index 9 |
| Optimized worktree before this fix | 349 elected | 1,720 elected | Same error at Salem, index 9 |
| Worktree after the targeted fix | 349 elected | 1,720 elected | 12,528 elected; all 290 files pass |

The optimization had made the same incorrect check faster. RD and RF output after the fix is exactly identical to the pre-fix worktree output, including row order, types and attributes.

Independent extraction from all KF mandate JSONs identifies seven elected candidates in seven municipalities with additional valid candidacy-geography rows outside their elected municipality. The old join pulls nine foreign geography rows into the wrong file:

| Index | Municipality | Candidate | Party | Other candidacy area incorrectly pulled into this file |
| ---: | --- | --- | --- | --- |
| 9 | Salem (0128) | 53411, Pia Lindqvist Ortiz Venegas | 0005 | Värmdö (0120) |
| 46 | Kinda (0513) | 5905, Jörgen Kalmendal | 0068 | Åtvidaberg (0561) |
| 48 | Åtvidaberg (0561) | 5183, Max Dahlgren | 0068 | Kinda (0513) |
| 68 | Eksjö (0686) | 5087, Henrik Nyberg | 0110 | Värnamo (0683), Mora (2062) |
| 168 | Lysekil (1484) | 52410, Peter Sahlberg Dahlström | 0068 | Sotenäs (1427) |
| 248 | Timrå (2262) | 53048, Robert Thunfors | 1773 | Sundsvall (2281), two candidacy constituencies |
| 288 | Boden (2582) | 45520, Nina Markström | 0110 | Luleå (2580) |

Names in this table are literal elected-node values; matching uses existing source keys. This audit does not infer or harmonize physical-person identity.

The 2026 elected API exposes final elected relations only. It has no preliminary/count argument. Existing tests confirm that a preliminary-only index fails rather than falling back to preliminary figures. RD/RF/KF final variants, both output languages and standard/full projections are covered.

## Corrective implementation

- R/valda_direkt_2026.R: restrict each mandate-file candidacy population to its own election type and election area. Return normalized per-file tables, including local candidacies needed to aggregate an elected candidate across multiple areas.
- R/valda_slutlig.R: enrich elected candidates once after collecting all requested final files, using the existing normalized-table aggregation already used for 2022. Preserve established file/candidate order and the official elected geography.
- Keep the actual missing elected-party-row error and all completion/list/sum validations. No candidate is skipped to bypass an error.
- Preserve NA if another candidacy area has no supporting party row; do not invent zero there. A verified complete reported party/list structure continues to support the existing zero-completion rule.
- tests/testthat/test-valda-geography-2026.R: deterministic KF/RF multi-area regression, genuine missing elected-party row, absent unelected-party missingness, and a public remote-call test verifying one mandate read per final file.

No public signature, schema, candidate identifier, name, source-election value, canonical asset, auto-eligibility flag or distribution manifest is changed.


## Retained performance evidence

These are dated paired measurements on preserved sources, not performance
guarantees or new benchmarks. Full iteration logs remain in the
[v0.4.0 performance report](https://github.com/richardohrvall/swelections/blob/v0.4.0/development/PERFORMANCE_AUDIT.md).
Namespace/node reuse, selected canonical candidate summaries, grouped modern
relations and request-local EU result-schema reuse were retained only after
exact public-output comparisons of values, order, types and attributes. No
persistent parsed-data cache or mandate-history optimization was introduced.

| Measured public case | Before seconds | Retained seconds | Qualification |
| --- | ---: | ---: | --- |
| 2018 canonical KF candidates | 9.85–11.03 | 0.62–0.72 | Repeated standard-English calls |
| 2018 canonical KF elected | 9.86–10.14 | 0.56–0.62 | Repeated standard-English calls |
| RF 2026 candidates | 404.19 | 87.71 | Full English, identical corrected preserved sources |
| RF 2026 elected | 129.39 | 13.61 | Same full-output panel |
| RF 2026 substitutes | 109.38 | 3.88 | Same full-output panel |
| RF 2026 preference votes | 224.08 | 88.61 | Same full-output panel |
| Raw KF 2018 district results | 176.59 | 33.22 | Fresh isolated full-output pair, not the earlier standard audit |
| Raw RF 2026 district results | 78.64 | 18.16 | Same result-path panel |

| EU first raw national result bundle | Before seconds | After seconds | Schema builds |
| --- | ---: | ---: | --- |
| 2004 final | 244.85 | 129.49 | 6,769 to 2 |
| 2009 final | 163.11 | 115.54 | 6,559 to 2 |
| 2014 final | 607.13 | 263.89 | 6,721 to 2 |
| 2019 final | 259.56 | 183.93 | 6,671 to 2 |
| 2019 preliminary | 117.32 | 57.11 | 6,671 to 2 |

EU cases used separate fresh R processes and already-local sources. The 2014
elapsed reduction was affected by host scheduling/load: CPU time fell only
from 259.58 to 245.27 seconds (5.5%), so a reproducible 56.5% algorithmic gain
is not claimed. In v0.4.0 normal approved historical calls use canonical, not
these explicit raw bundles. Unchanged comparison paths showed I/O/session
variation; theoretical changes with no material measured gain were discarded.

For KF 2026 remote elected calls, distinguish actual acquisition, XML/JSON
reading, validation/construction and enrichment. The earlier instrumented
187.67-second call is not a controlled cache-speedup baseline. The later
separate-process cache panel returned exactly the same 12,528 elected rows:
uncached 100.22 seconds (26.92 network), cold 84.19 (22.90 network), warm
60.66 (1.60 network). Warm requests download the fresh index and unindexed
candidate CSV, reusing 290 verified ZIPs. See [REMOTE_RAW_CACHE.md](REMOTE_RAW_CACHE.md)
for byte counts, verification policy and regression coverage. A response-replay
audit facility must not be confused with the production raw-byte cache.
