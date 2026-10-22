# Development and maintenance

The [frozen v0.4.0 record](releases/v0.4.0.md) gives the published commit,
190 Parquet assets, twelve manifests, coverage and final verification. The
[published inventory](releases/data-v0.4.0-files.csv) records the exact public
file sizes, hashes and URLs. Raw sources, caches and generated outputs stay
outside Git. No Python executable is required.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for R dependencies and package checks.
Run tools from the repository root with an explicitly configured library/input
archive. Historical snapshots are not interchangeable with current remote files.

## Permanent contracts

- [Canonical operation, source selection, build and release procedure](CANONICAL_DATA.md).
- [English canonical/value and storage contract](VALUE_CONTRACT.md).
- [Official-result authority and independent reconciliation](SOURCE_POLICY.md).
- [Preference-vote evidence, missingness and observation identity](PREFERENCE_VOTE_COMPLETENESS.md).
- [Mandate-history population, dates, sources and verified corrections](MANDATE_HISTORY.md).
- [Current-index verified remote raw cache](REMOTE_RAW_CACHE.md).
- [R-only 2022 preparation and deterministic ZIP/JSON rules](R_ONLY_WORKFLOW.md).
- [Approved scoped 2010 identity rules](SOURCE_ID_RECONCILIATION_2010.md).
- [Ragunda 2018 fixed-result correction](CANONICAL_2018_CORRECTIONS.md).
- [2026 RF official source correction](RF_2026_SOURCE_CORRECTION.md).
- [Source format references](../references/README.md).

## Source and validation records

Dated source inventories and validation reports retain their original evidence.
Their old prototype/commit status is not the current release status.

| Election | Source record | Implementation / completeness / validation |
| --- | --- | --- |
| RKL 2002 | [inventory](SOURCE_INVENTORY_2002.md) | [implementation](IMPLEMENTATION_2002.md), [completeness](COMPLETENESS_2002.md), [validation](VALIDATION_2002.md), [final reconciliation](FINAL_RESULT_RECONCILIATION_2002.md), [official supplement](SUPPLEMENT_2002.md) |
| Referendum 2003 | [inventory](SOURCE_INVENTORY_2003.md) | [validation, schema and completeness](VALIDATION_2003.md) |
| RKL 2006 | [inventory](SOURCE_INVENTORY_2006.md) | [implementation](IMPLEMENTATION_2006.md), [validation](VALIDATION_2006.md) |
| RKL 2010 | [pinned inventory](2010_SOURCE_INVENTORY.json) | [source/implementation validation](IMPLEMENTATION_2010_VALIDATION.md), [preliminary preservation](PRELIMINARY_2010_SOURCE_RETRIEVAL.md) |
| RKL 2014 | [source/implementation validation](IMPLEMENTATION_2014_VALIDATION.md) | [source/implementation validation](IMPLEMENTATION_2014_VALIDATION.md) |
| RKL 2018 | [format reference](../references/README.md) | [fixed-result correction](CANONICAL_2018_CORRECTIONS.md), [mandate-history sources](MANDATE_HISTORY.md), [value/storage contract](VALUE_CONTRACT.md) |
| RKL 2022 | [build and independent source evidence](CANONICAL_2022_BUILD_VALIDATION.md) | [build and independent source evidence](CANONICAL_2022_BUILD_VALIDATION.md) |
| EU 2004 | [inventory](SOURCE_INVENTORY_EU_2004.md) | [completeness](COMPLETENESS_EU_2004.md), [validation](VALIDATION_EU_2004.md) |
| EU 2009 | [inventory](SOURCE_INVENTORY_EU_2009.md) | [completeness/open preference questions](COMPLETENESS_EU_2009.md), [validation](VALIDATION_EU_2009.md) |
| EU 2014 | [inventory](SOURCE_INVENTORY_EU_2014.md) | [completeness](COMPLETENESS_EU_2014.md), [validation](VALIDATION_EU_2014.md) |
| EU 2019 | [inventory](SOURCE_INVENTORY_EU_2019.md) | [completeness](COMPLETENESS_EU_2019.md), [validation](VALIDATION_EU_2019.md) |
| EU 2024 | [inventory](SOURCE_INVENTORY_EU_2024.md) | [validation/completeness](VALIDATION_EU_2024.md), [candidate snapshot exception](EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md) |
| Re-elections | [inventory](SOURCE_INVENTORY_OMVAL.md) | [implementation](IMPLEMENTATION_OMVAL.md), [validation](VALIDATION_OMVAL.md) |

[Historical validation and retained performance findings](HISTORICAL_VALIDATION_NOTES.md)
consolidate retired genrep reports, the corrected 2026 elected-geography join and
paired performance evidence. The 2006/EU 2019 inventories retain GIS/district-mapping
source links for future geography work; no GIS implementation is implied.

## Builders and acquisition

[CANONICAL_DATA.md](CANONICAL_DATA.md) lists the complete build sequence. Keep
all `data-raw/build-canonical-*.R` builders, `canonical-build-contract.R`,
`prepare-canonical-2022.R`, `export-canonical-parquet-2018.R` and the release
preparer/metadata validator. History uses the two combined 2014/2018 manifests.

- `data-raw/preserve-final-2002.R` and `data-raw/preserve-final-2006.R` preserve
  official sources sequentially with provenance, without replacing original files.
- `preserve_preliminary_2010_conservative.R` is resumable and rate-limit-aware;
  `--verify-cache` checks preserved bytes without HTTP requests.
- `source_tools.R` is shared independent I/O/hash/parsing support.
- `build_party_identifiers_2010.R` and `data-raw/build-party-identifiers-2014.R`
  produce scoped metadata, never imported election votes or person identities.
- `data-raw/build_kommunnamn.R` and tracked `data-raw/kommunnamn.csv` reproduce
  the installed municipality lookup in `R/sysdata.rda`.

## Maintained validation tools

| Tools | Role |
| --- | --- |
| `validate_canonical_2002.R`, `validate_canonical_2006.R`, `validate_canonical_2010.R`, `validate_canonical_2014.R`, `validate_canonical_2022.R` | Public raw/canonical equivalence and supported schema/language/detail/geography variants |
| `data-raw/validate-canonical-2003.R`, `data-raw/validate-eu-2004.R`, `data-raw/validate-eu-2009.R`, `data-raw/validate-eu-2014.R`, `data-raw/validate-eu-2019.R`, `data-raw/validate-eu-2024.R` | Referendum/EU API equivalence and separate source controls |
| `data-raw/validate-eu-2004-sources.R`, `data-raw/validate-eu-2009-sources.R`, `data-raw/validate-eu-2014-sources.R`, `data-raw/validate-eu-2019-sources.R` | Independent parsing; do not replace it with production normalization |
| `data-raw/validate-sources-2002.R`, `data-raw/validate-aggregates-2002.R`, `data-raw/validate-complement-2002.R`, `data-raw/validate-preference-web-2002.R`, `data-raw/validate-supplement-2002.R` | XML, supplementary district data, recovered web observations and official supplement |
| `data-raw/validate-scb-2002.R`, `data-raw/validate-scb-2006.R` | Independent SCB controls; local Stata inputs remain outside Git |
| `validate_sources_2010.R`, `export_source_validation_2010.R`, `export_mandate_validation_2010.R` | Independent XML/SKV/Excel reconciliation; the validator requires tracked `2010_SOURCE_INVENTORY.json` |
| `validate_preliminary_2010_preserved.R`, `validate_preliminary_2010_integration.R` | Independent reported-state reconstruction, blanks, official totals and integration |
| `validate_official_totals_2014.R`, `validate_excel_2014.R`, `validate_mixed_2014.R`, `diagnose_sources_2014.R` | Independent controls and ordering/subset checks; the diagnosis also uses package helpers |
| `audit_canonical_2022_aggregates.R`, `diagnose_2022_rd_person_votes.R`, `compare_r_only_assets.R` | Arithmetic, retained source discrepancy and fixed 24-asset reference comparison |
| `test_r_only_preparation.R`, `test_source_retrieval.R` | Deterministic ZIP/JSON and retrieval/backoff/cache regressions |
| `validate_r_only_2022.R` | Historical preparation-migration comparison; requires the preserved old staging reference, not ordinary release inputs |
| `validate-re-elections.R` | Independent omval controls; requires tracked `SOURCE_INVENTORY_OMVAL_FILES.csv` |
| `run_2022_sweep.R`, `run_mandat_2022_sweep.R`, `validate_tomma_stolar_2026.R` | Explicit opt-in official remote sweeps, distinct from pinned-source reproducibility |
| `data-raw/validate-electorate-2003.R` | Independent SCB composition checks plus a legacy prototype regression; its old physical-layout assertions are schema-specific |

Scripts describe their positional inputs in their headers. Source archives may
have a pinned layout; configure them deliberately. The electorate prototype
regression above is not a general schema-3 release validator. Source checks are
kept separate from production normalization where possible. Generated exports,
reports and cached responses belong in ignored output directories.

`install-dependencies.R` is an optional partial setup helper. `check.R` regenerates
manuals before testing, so it can modify files; see CONTRIBUTING for a read-only
test/check workflow. Live integrations are opt-in, never a silent source fallback.

## Retired v0.4.0 preparation

Readiness decisions, old asset-count comparisons, the categorical migration audit
and long performance iterations are preserved in the frozen tag, not maintained
as current specifications. The [release record](releases/v0.4.0.md) links that
history and the two retired schema-2 migration/incremental tools. Their local
copies and evidence remain ignored. No original sources or published assets are
deleted by this documentation cleanup.
