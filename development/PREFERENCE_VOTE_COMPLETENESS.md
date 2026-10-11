# Preference-vote evidence and completeness

This is a methodological summary, not a new availability rule. The implemented
readers and their deterministic tests define the detailed year/source behaviour.
It replaces early genrep-era availability descriptions that are retained locally.

## Evidence before missing-value inference

An observed valid positive candidate count is retained. Missing candidate records
become zero only when the relevant source scope is verified complete and reconciled.
Missing or unverified evidence remains `NA`; a final URL or counting-stage label
alone is not proof of completeness. Missing fields, JSON null, explicit empty
arrays and explicit numeric zero must remain distinguishable.

For JSON list material, completeness checks include explicit candidate arrays,
valid integer counts, and reconciliation with `antalRosterMedPersonrost`.
`summeradePersonroster` and list totals are checked at their matching geographic
scope. A missing summering may be a verified zero when all relevant list evidence
is explicit, empty and zero, without contradictory detail. Observed counts must
not be masked merely by an older conservative party-availability assessment.

An explicit authoritative qualification/person-vote count can establish an area
value where supported by that reader. A candidate-wide total requires every
relevant area to be resolved. Candidate enrichment in `elected()` uses the same
candidate-wide scope as `candidates()`, while elected geography remains the
actual final elected relation. Area and district observations are alternative
geographic evidence and must never be added together.

## Sparse views and list identity

Sparse views contain observed candidate records. Zero completion adds only verified
zero combinations, not new missing-value rows. Lists with verified zero ballots
have zero list votes and zero candidate votes; a share with zero denominator is
`NA`. Candidate repetition across lists must not duplicate totals. Result list
numbers are distinct from evidence that a candidate appeared on a printed name
ballot; printed-ballot status uses the version/hash-bound candidate source.

## Historical source limits

The verified 2022 `90000` structures contribute zero officially identified
candidate preference votes; they are not ordinary candidate lists and do not
alone make a candidate total unknown. This does not redefine other `90000`
semantics. Missing party rows and other-party aggregation require the reader's
source-specific evidence rather than automatic zero or automatic completeness.
See [the 2022 report](CANONICAL_2022_BUILD_VALIDATION.md) for the preserved
14-combination / 15-vote RD area/district difference. It is not redistributed.

Historical XML can repeat `PERSONVAL` records. The relevant official records are
aggregated by identity and source scope, without name-based joins. Unsupported
attributes remain typed missing values. Historical candidate names follow the
public source contract even when local named snapshots exist.

## Validation references

- `tests/testthat/test-personroster-availability.R`: missing/null/empty, complete
  zero, invalid counts and contradictory evidence.
- `tests/testthat/test-personroster.R` and `test-personroster-listor.R`: public
  views, observed counts and zero completion.
- `tests/testthat/test-personroster-2022.R`: historical JSON/list semantics.
- `tests/testthat/test-xml-2010.R`, `test-xml-2014.R` and `test-xml-2018.R`:
  historical adapters and source limitations.
- `validate_canonical_2010.R`, `validate_canonical_2014.R`,
  `validate_canonical_2022.R`: opt-in public/raw comparisons.

The old genrep integrations cannot establish present live-file availability.
Their durable missingness and integrity checks are summarised in
[HISTORICAL_VALIDATION_NOTES.md](HISTORICAL_VALIDATION_NOTES.md).
