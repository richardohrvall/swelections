# Canonical and public value contract

Status: implemented for local validation, 2026-10-21. No release, commit or push.

## Versions and scope

All twelve current products use `data_version = data-v0.4.0`,
`schema_version = 3`, `value_schema_version = 1` and
`storage_schema_version = 1`. The 194 Parquet assets cover RKL 2002, 2006,
2010, 2014, 2018 and 2022, referendum 2003 and EU 2004, 2009, 2014, 2019, 2024.
Only results are relevant to the referendum. Unsupported views/stages are not
created by this normalization.

The earlier [categorical audit](CATEGORICAL_VALUE_AUDIT.md) is the baseline.
The explicit subsequent decisions are: normalize all current generations,
normalize internal storage keys, use `yes`/`no`/`blank` for referendum option
names, and use the broad aggregate label `Handwritten votes`.

## Semantic values

Canonical and English output share English technical values. Swedish output
localizes them through the same field-specific dictionary. Logical properties
remain logical in both interfaces. The existing `names` language selector now
controls technical values as well as column names; function signatures do not
change. Names-only internal helpers remain available for column mapping.

| Field | Canonical / English | Swedish presentation |
| --- | --- | --- |
| `count_stage` | `final`, `preliminary` | `slutlig`, `preliminar` |
| `geographic_level` | `national`, `county`, `region`, `regional_constituency`, `parliamentary_constituency`, `municipality`, `municipal_constituency`, `district`, `preference_vote_area` | Existing Swedish level vocabulary |
| `district_type` | `ordinary`, `collection`, `wednesday` | `valdistrikt`, `uppsamlingsdistrikt`, `onsdagsdistrikt` |
| `sex` | `male`, `female` | `man`, `kvinna` |
| `ballot_status` | `final`, `draft`, literal source codes `S`/`B` | `definitiv`, `utkast`, `S`/`B` |
| `comparison_status` | Eight distinct English categories from the audit | Eight corresponding Swedish categories |
| `election_basis` | Six distinct English categories from the audit | The six Swedish source descriptions |
| `election_kind` | `ordinary`, `re_election` | `ordinarie`, `omval` |
| `voting_option_name` | `yes`, `no`, `blank` | `Ja`, `Nej`, `Blank` |
| History `status` | `occupied`, `vacant` | `besatt`, `vakant` |
| `composition_type` | `after_re_election` | `efter_omval` |

History source kinds, date bases, event-scope levels and component levels also
use the shared dictionary. Translation is one-to-one: comparable/new/modified/
aggregated states and the six election bases are not collapsed. Unknown
technical values cause an explicit error rather than an invented mapping.

Ordinary source blanks in an election-class field are not filled by guessing.
Missingness elsewhere remains typed `NA`.

## Boolean applicability

`consent` and `candidate_declaration` are logical. Their full/source-oriented
outputs and canonical tables also contain `consent_applicable` and
`candidate_declaration_applicable`. Swedish column names are
`samtycke_tillampligt` and `forklaring_tillamplig`.

| Source meaning | Value | Applicable |
| --- | --- | --- |
| Yes | TRUE | TRUE |
| No | FALSE | TRUE |
| Explicitly not applicable (`I` / `irrelevant`) | NA | FALSE |
| Unknown / missing | NA | NA |

No zero or false value substitutes for non-applicability. Existing genuine
logical flags retain their types. Standard output remains a projection of full;
these source-detail fields are not added to standard where they were absent.
Counts that happen to be zero or one remain counts.

## Referendum and aggregate labels

Blank is a valid referendum response option, never an invalid-ballot category.
Invalid ballots remain separate. The official referendum option identifiers
`JA`, `NEJ`, `BLANK` remain literal in `voting_option_code`; the normalized option
names are `yes`, `no`, `blank`. These are categories, not Boolean vote values.

`Other parties` and `Handwritten votes` are aggregate display labels. Actual
party names are unchanged. The missing-party-designation disclosure and literal
source designations remain separate; the word "unreported" is not added to the
handwritten-vote category. Neither EU 2004's 943 aggregate votes nor EU 2014's
ten Vårdsberg votes are allocated to a party by this change.

## Source values and identity

Proper party/place/person names, printed ballot descriptions, original source
node tags and literal source designations remain unchanged. Source codes such
as `election_basis_id`, list/candidate numbers, event IDs and `S`/`B` are not
translated or interpreted as physical-person identifiers. Source identifiers
like `Val_2018` remain identifiers; this task does not invent an event-ID
crosswalk. Literal `JA`, `NEJ` or `Giltig` in a source-party-designation field
are not Boolean/status instructions.

The separate `S`/`B` ballot-status codes are retained as documented neutral
source identifiers. They are not asserted to mean `Definitiv`/`Utkast`, candidate
validity or a counting stage. No unsupported decoding is introduced.

## Storage and readers

Internal `.table` geographic values use the English level vocabulary.
`.component` uses `geography`, `party`, `list`, `votes`, `list_votes`, `areas`,
`official`, `metadata`, `candidate_population`, `list_population`,
`all_population`. Already English EU components (`votes`, `lists`, `parties`,
`context`, `qualified`) retain their roles. Election codes and serialized
`.person_view` keys remain neutral identifiers.

Readers require the current contract. There is no normal-read upgrade of old
canonical files. The selector helper translates API/internal selectors to
current English storage keys; it is not an old-file compatibility branch.
English public output reads normalized canonical values. Swedish presentation
localizes them at the end. Raw source parsers and their validations keep their
source-oriented internal contract until final presentation/export.

## Rebuild and provenance

Every maintained builder writes the same contract through the shared R helper
`data-raw/canonical-build-contract.R`. `standardize-canonical-values.R` provides
a separate deterministic re-encoding route for already validated canonical
prototypes. It verifies all input checksums and records the input manifest and
asset checksums, prior build provenance and original source inventory. It does
not pretend to reparse raw data. Independent raw/canonical validation is run
separately.

The current re-encoding uses the reviewed Ragunda-corrected 2018 prototype.
Candidate 534885 is included with the established correction provenance;
no other election relationship is recalculated. New assets have new checksums
and manifests. Old reference and published files are preserved.

## 2018 publication transition

The old `data-v0.1.0` release must not be overwritten. Its files and manifest
remain immutable historical references. The current registry uses the new
version/cache namespace and requires a configured current local manifest until
publication is separately approved. Its remote URL is deliberately unset, so
it cannot silently select the old release. Eligibility flags are unchanged:
2018 retains approval, while all EU products remain ineligible for automatic
selection. Availability and approval are separate.

A later publication must use a new version/tag and publish the new manifests
with their matching asset bytes/SHA256 values. Manifest names/locations for a
combined multi-product release must be unique by family/event/year and then
registered explicitly. Restore a remote location only for that approved
publication. No publication is performed here.

## Clean-build boundary

All current validation builds truthfully record `build_tree_dirty = true` and
the actual HEAD plus build-code checksums. After review and a separately
approved commit, repeat the clean production build, record
`build_tree_dirty = false`, verify byte-identical assets, rerun content/source/
schema/language/Parquet checks, tests and `R CMD check`, and only then approve
publication. No clean status is simulated by copying or hiding changes.

Validation evidence and exact exclusions are recorded in
[VALIDATION_VALUE_CONTRACT.md](VALIDATION_VALUE_CONTRACT.md).

Manifest table layouts use the same English selectors. Synthetic data-frame
row names are not part of that layout contract: the shared build helper clears
them before JSON serialization, avoiding redundant legacy Swedish `_row`
selectors beside the authoritative English `table` field. Original source-file
identifiers and source-inventory provenance remain literal and unchanged.
