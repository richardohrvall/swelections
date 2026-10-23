# Canonical data: operation and reproducible builds

The published [v0.4.0 record](releases/v0.4.0.md) identifies the frozen production
commit, twelve products, 190 Parquet assets, twelve manifests, approved functions
and final checks. Its [file inventory](releases/data-v0.4.0-files.csv) contains the
actual published sizes, SHA256 values and URLs. Package and data versions are
separate; old releases are immutable. Do not overwrite their files or tags.

The unpublished [v0.4.1 candidate](releases/v0.4.1.md) contains **200 assets and
16 manifests**: 188 unchanged assets, two rebuilt completed-period histories and
ten new final re-election results/seats assets. Its
[file inventory](releases/data-v0.4.1-files.csv) identifies the exact planned payload.
It must not overwrite frozen v0.4.0.

Current data use schema 3 and [value/storage contracts 1/1](VALUE_CONTRACT.md).
Canonical columns and technical values are English; Swedish output localizes
column names and technical categories. Proper names and literal source IDs are
preserved. `standard` remains a projection of `full`. See the source-specific
reports indexed in [development/README.md](README.md) for exact populations.

## Source selection

The central registration in `R/canonical_distribution.R` records family, event
kind, year, data/schema versions, manifest location and approved auto functions.
It is the approval authority; a manifest describes actual coverage, not permission
to activate new functions. English and Swedish wrappers use the same decision.

1. `auto` checks product approval and its explicit function allowlist.
2. For an allowed function it checks the requested manifest view, geography and
   counting stage, then uses canonical. Invalid selected canonical data fail;
   they do not silently switch to raw data.
3. Without approved canonical coverage, only an existing supported remote route
   can be used automatically. No user raw archive is discovered or selected.
4. If neither route exists, the request fails. Where supported, the message
   explains how to supply raw files explicitly with `source = "local"`.

`source = "canonical"` explicitly requests actual manifest coverage. For
re-elections, the central allowlist also restricts explicit canonical requests to
results/seats; a private manifest cannot enable unimplemented candidate views.
`source = "remote"` explicitly requests supported current Valmyndigheten sources,
even when canonical exists. `source = "local"` reads the user's own saved source
files in a supported layout; it does not access the network. `data_dir` and raw-root
options do not make `auto` local. Calls formerly relying on that behavior must
select `local` explicitly. Explicit raw `update`/`archive` requests retain their
supported raw semantics and cannot be combined with canonical selection.

RKL 2002 candidacies and EU 2009 preference votes are not auto-approved. A full
private prototype does not expand the central list. Unavailable views/stages are
not filled from other counts: in particular, preliminary 2018 results/mandates
are rejected instead of returning final results. Newer supported elections
without canonical retain their remote path. The five re-election events have
approved canonical results/seats in v0.4.1; their raw replay remains explicit
local. Their event/composition semantics and geographic restrictions are unchanged.

## Configuration and caching

Normal historical calls need no developer archive. `nanoparquet` must be installed
to read canonical data. For explicit testing of a build or mirror:

```r
options(swelections.canonical_manifest = "my_build/manifest.json")
results(2018, "municipal", source = "canonical")
results(2018, "municipal", source = "local", data_dir = "my_raw_archive")
```

Manifest overrides can be named by `series:ordinary:year`, `series:year`, or legacy
year keys; re-election overrides use `rkl:re_election:year` to avoid selecting an
ordinary election with the same year. `swelections.canonical_assets_dir` and `swelections.canonical_base_url`
control explicit asset locations; `swelections.canonical_cache_dir` controls the
canonical cache. Manifest keys include the family/event/year/version namespace.
Asset bytes are checked against the manifest. A local canonical cache is still
canonical, not a user's raw `local` archive. Raw-only arguments are rejected for
explicit canonical requests.

The [remote raw cache](REMOTE_RAW_CACHE.md) is separate. It stores downloaded
indexed ZIP bytes, requires a fresh current official MD5 index and checks cached
bytes before reuse. There is no stale-index fallback or persistent parsed/API
result cache. Unindexed candidate/member CSVs are fetched fresh.

## Preserved inputs and build chain

Use new output directories and immutable pinned sources with URL/retrieval/size/
checksum provenance. SCB/SND serve independent validation or source-supported,
reconciled supplementation; see [SOURCE_POLICY.md](SOURCE_POLICY.md). Do not infer
identity, unsupported zeros or final values for missing preliminary data.

From the repository root with the documented R dependencies:

```sh
Rscript data-raw/build-canonical-2002.R RAW_ROOT OUTPUT_2002
Rscript data-raw/build-canonical-2006.R RAW_ROOT OUTPUT_2006
Rscript data-raw/build-canonical-2010.R RAW_ROOT OUTPUT_2010
Rscript data-raw/build-canonical-2014.R RAW_ROOT OUTPUT_2014_RESULTS
Rscript data-raw/build-canonical-2018.R RAW_ROOT PINNED_CANDIDATE_FILE OUTPUT_2018_STAGE
Rscript data-raw/export-canonical-parquet-2018.R OUTPUT_2018_STAGE OUTPUT_2018_RESULTS
Rscript data-raw/build-canonical-2022.R SOURCE_ROOT_2022 OUTPUT_2022
Rscript data-raw/build-canonical-2003.R REFERENDUM_SOURCE_DIRECTORY OUTPUT_REFERENDUM
Rscript data-raw/build-canonical-eu-2004.R RAW_ROOT OUTPUT_EU2004
Rscript data-raw/build-canonical-eu-2009.R RAW_ROOT OUTPUT_EU2009
Rscript data-raw/build-canonical-eu-2014.R RAW_ROOT OUTPUT_EU2014
Rscript data-raw/build-canonical-eu-2019.R RAW_ROOT OUTPUT_EU2019
Rscript data-raw/build-canonical-eu-2024.R RAW_ROOT OUTPUT_EU2024
Rscript data-raw/build-canonical-mandate-history.R 2014 OUTPUT_2014_RESULTS/manifest.json RAW_ROOT OUTPUT_2014
Rscript data-raw/build-canonical-mandate-history.R 2018 OUTPUT_2018_RESULTS/manifest.json RAW_ROOT OUTPUT_2018
Rscript data-raw/build-canonical-re-elections.R RAW_ROOT ORSA_RERUN_XML OUTPUT_RE_ELECTIONS
```

Source-root layouts and required auxiliary snapshots differ by builder; use its
header and the year-specific source/validation document. The 2018 full-schema RDS
stage is intentional and is not itself distributed. The fixed result and later
membership sources remain separate; two history assets augment the 2014/2018
products. The ongoing 2022–2026 history is remote, not a canonical build product.

2022 preparation is sourced by its builder. It selects the pinned historical
candidate CSV (MD5 `639daa9630a1f2554f1c6839473448ee`), verifies official correction
ZIPs for KF 0136/1439/1860/2506 and preserves original source bytes. RF Norrbotten's
original-election reconstruction changes only the approved typed `50975 -> 488`
fields for SD/Bo Larsson: two mandate and 95 district fields, with decision
`201-11278-2022` retained. See [R_ONLY_WORKFLOW.md](R_ONLY_WORKFLOW.md) and
[the independent build/source evidence](CANONICAL_2022_BUILD_VALIDATION.md).
No Python executable is required. RSA signature files are provenance, not textual
SHA256 checksums. Derived staging ZIP checksums are distinct from original hashes.

## Validation and distribution

Validate raw and canonical outputs through the maintained year-specific API
validators plus independent source parsers listed in [the tool index](README.md).
Check all supported counts/geographies, names/detail settings, keys, missingness,
relationships, source hashes, manifest layouts and Parquet round trips. Normalized
preference bases can reconstruct list/zero views on demand; physical base rows
are not all candidate observations. Validation must retain that distinction.

For a release, start from a reviewed clean commit. Every build must report its
actual commit/code hashes and `build_tree_dirty = false`; stop on unexpected data
or byte differences. Check the full suite, R CMD check and source integrity.
Build time, commit and corresponding JSON provenance/checksums may change on a
fresh build; they are not permission to accept changed election data.

Prepare a CSV with a `manifest` column containing the sixteen final product build
manifests (including the combined history products), then run:

```sh
Rscript data-raw/prepare-canonical-release.R MANIFESTS.csv EMPTY_DISTRIBUTION
Rscript development/validate-canonical-v0.4.1.R CANDIDATE FROZEN_V040_DOWNLOADS VALIDATION_OUTPUT
```

The second command verifies the v0.4.1 inventory and actual activated API routing
against the staged distribution. The older
`data-raw/validate-canonical-release-metadata.R` is retained for frozen v0.4.0
(190 assets/twelve products), not as the current generation validator.
Preparation never changes
Parquet bytes; source path conversion is portable provenance only. Raw/build
manifests remain preserved. Public manifest fields do not require users to have
our raw archive layout. Absolute-path detection and unchanged operational fields
have separate regression coverage.

The current preparer is explicitly scoped to the sixteen v0.4.1 products and
approved counts (200 assets). It filters EU 2009's full fourteen-asset build to eight publishable assets;
the six preference bases must not be uploaded. A future product/version change
needs review of the registry, preparer and tests, not manual additions to an
upload directory. All release filenames must be globally unique.

The preparation output `upload-inventory.csv` is the proposed upload payload.
After publication, verify every actual public file against it and preserve a
versioned final inventory. Test normal auto calls in a new R session/library/
workspace/cache against the real URLs, including exclusions, history routing and
explicit raw selection. Publishing assets, tag/release creation and activation
are separately reviewed operations; a successful build does not authorize them.

The old data-v0.1.0 2018 distribution remains frozen. v0.4.0 selects the corrected
Ragunda generation at its own URLs/cache namespace; no permanent old-format
read-time upgrade or modification of old release files is used. Reproduce a frozen
release from its tag and pinned sources. Later maintenance commits can have new
code fingerprints without changing that historical build record.

### Reproduce the v0.4.1 generation

The coordinator retains the approved 188 frozen Parquet files unchanged and
rebuilds only the two history products and ten re-election assets:

```sh
Rscript data-raw/prepare-canonical-v0.4.1.R FROZEN_V040_DOWNLOADS RAW_ROOT ORSA_RERUN_XML EMPTY_OUTPUT
```

It stages an independent v0.4.1 distribution and checks frozen input hashes.
It does not modify or republish v0.4.0. The two completed history products use
interval schema 2; the ongoing 2022 period remains remote. Model details and
source coverage are maintained in [MANDATE_HISTORY.md](MANDATE_HISTORY.md).
An uncommitted review build truthfully reports `build_tree_dirty = true`; it is
not a substitute for the clean-commit rebuild required for publication.
