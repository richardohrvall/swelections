# Canonical and public value contract

Published in data-v0.4.0. The [frozen release record](releases/v0.4.0.md) identifies its clean build and verified distribution.

## Versions and scope

The sixteen current products use `data_version = data-v0.4.1`,
`schema_version = 3`, `value_schema_version = 1` and
`storage_schema_version = 1`. The 200 published Parquet assets cover RKL 2002,
2006, 2010, 2014, 2018 and 2022, referendum 2003, EU 2004, 2009, 2014, 2019 and
2024, and five final results/seats re-elections in four additional manifests.
The two completed-period history assets use interval schema 2.
Only results are relevant to the referendum. Unsupported views/stages are not
created by this normalization.

The [archived categorical audit](https://github.com/richardohrvall/swelections/blob/v0.4.0/development/CATEGORICAL_VALUE_AUDIT.md) records the preimplementation baseline; the approved contract is stated here.
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
| `comparison_status` | Eight separate categories listed below | Eight corresponding Swedish categories |
| `election_basis` | Six separate categories listed below | The six Swedish source descriptions |
| `election_kind` | `ordinary`, `re_election` | `ordinarie`, `omval` |
| `voting_option_name` | `yes`, `no`, `blank` | `Ja`, `Nej`, `Blank` |
| History `status` | `occupied`, `vacant`, `unknown` | `besatt`, `vakant`, `okand` |
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

Maintained raw-source builders write schema 3 and value/storage contract 1/1
through `data-raw/canonical-build-contract.R`. Build manifests retain code and
source hashes, the actual commit and truthful dirty status. Distribution copies
only make provenance labels portable; they do not alter Parquet bytes or the
operational manifest fields. See [CANONICAL_DATA.md](CANONICAL_DATA.md).

The one-time schema-2 re-encoding tool is preserved at the
[frozen v0.4.0 tag](https://github.com/richardohrvall/swelections/blob/v0.4.0/data-raw/standardize-canonical-values.R).
It checked original asset hashes, preserved rows and literal source values,
recorded original/derived provenance and checked Parquet round trips. Production
release assets were then independently rebuilt from raw sources at the clean
release commit. This migration is not a required step in a new raw-source build.

The old data-v0.1.0 2018 files remain immutable. The active registry selects
data-v0.4.1, with the approved Ragunda correction and a separate version/cache
namespace. There is no normal-read conversion of older canonical formats.
All sixteen approved products are activated with their central function lists;
EU 2009 preference votes and RKL 2002 candidacies remain excluded.

All release manifests record `build_tree_dirty = false`; all 200 Parquet assets
match the approved prototype byte-for-byte. Fresh build timestamps/commit provenance change manifest
hashes; they do not justify any election-data difference. Future releases require
review, a clean committed build, schema/language/source/Parquet checks, tests and
R CMD check. The exact published inventory is versioned in the
[release record](releases/v0.4.0.md).

Manifest table layouts use English selectors. Synthetic data-frame row names
are not layout keys: the shared builder clears them before JSON serialization
to avoid legacy Swedish `_row` selectors. Original source-file identifiers and
source-inventory provenance remain literal.

## Comparison and election-basis vocabularies

| Swedish comparison category | Canonical / English |
| --- | --- |
| Kan jämföras | `comparable` |
| Ej jämförbart | `not_comparable` |
| Jämförs mot summerat | `compared_with_aggregate` |
| Summerad | `aggregated` |
| Ny | `new` |
| Modifierad | `modified` |
| ej jämförbar: Ny | `not_comparable_new` |
| ej jämförbar: Modifierad | `not_comparable_modified` |

| Swedish election-basis description | Canonical / English |
| --- | --- |
| Ledamoten är vald på jämförelsetal | `comparison_number` |
| Ledamoten är vald på personröster | `preference_votes` |
| Ledamoten är vald som listtrogen efterträdare till dubbelvalsavvecklad | `list_successor_after_dual_election` |
| Ledamoten är vald på personröster som efterträdare till dubbelvalsavvecklad | `preference_vote_successor_after_dual_election` |
| Ersättaren är utsedd listtroget | `list_substitute` |
| Ersättaren är vald på personröster | `preference_vote_substitute` |

Swedish output uses the corresponding source descriptions. Election-basis IDs
are literal, source-specific codes: matching descriptions do not authorize a
global cross-year mapping of codes such as P/J/E/PE or 1/2/5/6/10/11.
