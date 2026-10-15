# Development, validation and source documentation

This directory contains public R reproducibility tools and methodological evidence.
Generated reports, raw snapshots, named research crosswalks and workbenches stay
local and ignored. Run tools from the repository root with the configured R library.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for dependencies and package checks.

## Canonical builds

| Tool | Role / inputs |
|---|---|
| `data-raw/build-canonical-2002.R` | Hash-verified original-election XML registry and new unpublished output directory |
| `data-raw/build-canonical-2006.R` | Preserved archive root and new unpublished output directory |
| `data-raw/build-canonical-2010.R` | Raw archive root and new output directory |
| `data-raw/build-canonical-2014.R` | Raw archive root and new output directory |
| `data-raw/build-canonical-2018.R` | Raw archive and pinned official candidate file; full-schema staging |
| `data-raw/export-canonical-parquet-2018.R` | 2018 stage and new Parquet output directory |
| `data-raw/build-canonical-2022.R` | Preserved 2022 source root and new output directory |
| `data-raw/prepare-canonical-2022.R` | Pinned staging and documented Norrbotten reconstruction |
| `data-raw/build-party-identifiers-2014.R` | Scoped party metadata, not imported votes or candidate identities |
| `data-raw/build_kommunnamn.R` | Internal lookup from the tracked municipality CSV |

Follow [CANONICAL_DATA.md](CANONICAL_DATA.md) for exact build/distribution commands,
manifest validation and publication boundaries. Keep data products outside Git.
The [2018 schema](CANONICAL_SCHEMA_2018_ENGLISH.md) is version-specific.
The [R-only preparation contract](R_ONLY_WORKFLOW.md) records reproducible ZIP/JSON
selection and serialization, including differences from the retired implementation.

## Acquisition and source tools

- `data-raw/preserve-final-2002.R`: sequential, cached preservation of final XML;
  original Orsa is pinned separately from its 2003 rerun. No preliminary search.
- [2002 implementation](IMPLEMENTATION_2002.md), [source inventory](SOURCE_INVENTORY_2002.md)
  and [validation](VALIDATION_2002.md): source-observation keys, incomplete ballot
  coverage and unrecovered preliminary collections are explicit limitations.
- `validate_canonical_2002.R`, `data-raw/validate-sources-2002.R` and
  `data-raw/validate-scb-2002.R`: public equivalence and separate XML/SCB controls.
- `data-raw/validate-aggregates-2002.R`: independent district/municipality/national
  final XML controls, including the 2002 collection-node placements.

- `data-raw/preserve-final-2006.R`: sequential preservation of the official
  RD/RF municipality XML, with per-file URL, retrieval time, size and hashes.
- [2006 implementation](IMPLEMENTATION_2006.md), [validation](VALIDATION_2006.md) and [source inventory](SOURCE_INVENTORY_2006.md):
  conservative source-observation identity and documented source limitations.
- `validate_canonical_2006.R` and `data-raw/validate-scb-2006.R`: public/raw
  equivalence and independent municipality/party/mandate validation in R.

- `preserve_preliminary_2010_conservative.R`: sequential, resumable acquisition;
  immutable cached responses, provenance and rate-limit backoff. The `--verify-cache`
  mode checks existing preservation without HTTP requests.
- `source_tools.R`: shared independent R I/O, hash and parsing utilities.
- `build_party_identifiers_2010.R`: geographically scoped official party metadata.
- `install-dependencies.R`: optional partial development-library setup.
- `check.R`: documentation generation followed by package tests; it can modify manuals.

Successful retrievals and generated outputs belong in ignored directories. Use a
new destination for outputs; do not overwrite preserved sources or reference builds.

## Validation tools

| Tool | Purpose |
|---|---|
| `validate_canonical_2010.R`, `validate_canonical_2014.R`, `validate_canonical_2022.R` | Public canonical/raw comparison, schemas, detail and language projections |
| `validate_sources_2010.R` | Independent final XML/SKV/Excel checks; requires pinned `2010_SOURCE_INVENTORY.json` |
| `export_source_validation_2010.R` | Package outputs supplied to the independent source validator |
| `export_mandate_validation_2010.R` | Excel validation export, never a canonical input |
| `validate_preliminary_2010_preserved.R` | Independent preserved HTML/XML reconstruction and published totals |
| `validate_preliminary_2010_integration.R` | Collections, blank cells, aggregates and canonical integration |
| `validate_official_totals_2014.R` | Independent SKV/HTML totals |
| `validate_excel_2014.R` | Independent OOXML/SKV cross-check |
| `validate_mixed_2014.R` | Mixed requests, ordering and subset equivalence |
| `diagnose_sources_2014.R` | Source audit using package reader helpers; not wholly independent parsing |
| `audit_canonical_2022_aggregates.R` | Arithmetic checks on assets already compared with raw APIs |
| `diagnose_2022_rd_person_votes.R` | Independent raw trace of the preserved RD area/district discrepancy |
| `compare_r_only_assets.R` | Pinned 24-asset 2022 reproducibility comparison |
| `validate_r_only_2022.R` | Detailed reference/current staging byte, JSON and provenance comparison |
| `test_r_only_preparation.R` | Deterministic ZIP/JSON preparation regressions |
| `test_source_retrieval.R` | Deterministic retrieval/backoff/cache tests without live requests |
| `run_2022_sweep.R`, `run_mandat_2022_sweep.R` | Opt-in current official result/mandate sweeps, distinct from pinned-build validation |
| `validate_tomma_stolar_2026.R` | Opt-in official explicit unfilled-seat checks |

Scripts document positional arguments in their headers. Several preserved-source
validators use a pinned archive layout: consult their header/body before execution.
Network sweeps must be selected explicitly. Changing live snapshots cannot replace
hash-pinned historical build evidence. Independent source validators use separate
R parsing logic; canonical/raw comparisons additionally test the public API path.

Examples with configured library and explicit inputs:

```sh
Rscript development/test_r_only_preparation.R
Rscript development/test_source_retrieval.R
Rscript development/validate_canonical_2010.R ARCHIVE_ROOT ASSET_DIR all
Rscript development/validate_canonical_2014.R ARCHIVE_ROOT ASSET_DIR all
Rscript development/validate_canonical_2022.R ASSET_DIR REPORT_JSON
Rscript development/validate_sources_2010.R SOURCE_ROOT OUTPUT_JSON REPORT_JSON
```

Use paths under an ignored output directory for report arguments. Do not add broad
CSV/ZIP ignore rules: intentional fixtures, source inventories and lookups are public.

## Source and methodological records

- [2010 source/implementation validation](IMPLEMENTATION_2010_VALIDATION.md) and
  [pinned inventory](2010_SOURCE_INVENTORY.json).
- [2010 preliminary retrieval](PRELIMINARY_2010_SOURCE_RETRIEVAL.md) and
  [integration](PRELIMINARY_2010_INTEGRATION.md): preserve unreported and partial pages.
- [Approved 2010 identity rules](SOURCE_ID_RECONCILIATION_2010.md): unresolved cases
  remain unresolved; detailed proposed linkages are local research material.
- [2014 validation](IMPLEMENTATION_2014_VALIDATION.md): SCB/population and snapshot differences.
- [2022 build/validation](CANONICAL_2022_BUILD_VALIDATION.md): source versions,
  Norrbotten reconstruction and the retained 15-vote RD discrepancy.
- [2026 RF correction](RF_2026_SOURCE_CORRECTION.md): corrected official source and provenance.
- [Preference-vote completeness](PREFERENCE_VOTE_COMPLETENESS.md): current evidence principles.
- [Consolidated historical checks](HISTORICAL_VALIDATION_NOTES.md): durable findings
  extracted from retired plans and genrep integrations, not current release status.
- [Source references](../references/README.md): authoritative technical documentation.

Historical checkpoint numbers and clean/dirty status are evidence of those builds,
not claims about present source availability. The retained documentation does not
activate new identity rules or reconcile official source inconsistencies.

- [EU 2024 source inventory](SOURCE_INVENTORY_EU_2024.md),
  [approved candidacy snapshot exception](EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md)
  and [implementation/validation](VALIDATION_EU_2024.md).
