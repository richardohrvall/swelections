# Consolidated historical validation notes

This document preserves lasting evidence from retired working plans, early release
reviews and genrep integrations. Those originals and the exploratory notebook are
retained locally; their old counts, API layouts and status claims are not current
contracts. Frozen tests and current source-specific reports remain authoritative.

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
[PRELIMINARY_2010_INTEGRATION.md](PRELIMINARY_2010_INTEGRATION.md) and
[SOURCE_ID_RECONCILIATION_2010.md](SOURCE_ID_RECONCILIATION_2010.md).
The one-time 2014 metadata refresh is obsolete because a fresh builder includes
that operation. The ad hoc 2010 smoke exporter is replaced by maintained source
exports and validators. No source values, identities or assets are changed by
retiring these local workbenches.
