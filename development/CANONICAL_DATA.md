# Canonical data distribution: RKL 2018 and 2022

## RKL 2022: unpublished local build

The next collection is a local `data-v0.2.0` build, using English Parquet
schema version 2. It has **not** been published or enabled for automatic
selection. The published 2018 assets are unchanged. An explicit 2022 request
uses `options(swelections.canonical_manifest = ".../manifest.json")`;
named manifest paths keyed by year support mixed 2018/2022 requests.

Build with:

```sh
Rscript data-raw/build-canonical-2022.R SOURCE_ROOT OUTPUT_DIR
```

`SOURCE_ROOT` is the preserved `rkl/2022` collection. The script pins the
reviewed official index and the verified historical candidate CSV (MD5
`639daa9630a1f2554f1c6839473448ee`). It hashes all preserved result JSON,
RSA signature files and candidate snapshots, and checks the originals again
after building. Signatures are recorded as signatures, not interpreted as
textual SHA256 checksums. Four corrected final KF ZIPs (0136, 1439, 1860,
2506) are downloaded separately and verified against the pinned official
index. Raw files are never overwritten.

Preparation is implemented in `data-raw/prepare-canonical-2022.R`; no Python
executable is required. Build-time R dependencies include `pkgload`,
`nanoparquet`, `digest` and `zip`, in addition to package dependencies.
Derived ZIP members use a fixed UTC timestamp, including the candidate CSV.
See `R_ONLY_WORKFLOW.md` for the preparation contract and byte-level audit.

RF 25 uses the preserved October 2022 result snapshot. The documented
14 November correction `50975 -> 488` is applied only to typed candidate-ID
fields for SD/Bo Larsson: two mandate-file fields and 95 district-file fields.
The manifest records original hashes, changed JSON paths, derived hashes,
decision `201-11278-2022` and its official protocol URL. Original elected
and substitute relations are retained; later mandate-period replacements
are not imported. Counts, names, order and other source values are unchanged
by this reconstruction.

An external temporary raw comparison archive contains explicitly derived
ZIP containers. Its index checksums describe those containers, not the
original official ZIPs. Neither this archive nor original raw files form
part of the canonical asset distribution.

The 24 Parquet assets are:

- `rkl2022-results-{preliminar,slutlig}-{rd,rf,kf}.parquet` (six files);
- `rkl2022-seats-{preliminar,slutlig}.parquet` (two files);
- `rkl2022-candidacies.parquet`;
- `rkl2022-candidates.parquet`;
- `rkl2022-elected.parquet`;
- `rkl2022-substitutes.parquet`;
- `rkl2022-preference-votes-{area,district}-{rd,rf,kf}.parquet`
  (six analysis assets: all four area views and the two sparse district views);
- `rkl2022-preference-votes-base-{area,district}-{rd,rf,kf}.parquet`
  (six files).

Result, seat and preference-vote analysis assets record per-table layouts. Normalized preference-vote
bases record per-component layouts and source-area partition keys. The same
verified 2022 presentation/aggregation implementation serves raw and
canonical requests, including list views and optional verified-zero
completion. Completed panels are reconstructed on demand rather than
stored as millions of duplicate rows. Technical base fields use the same
English vocabulary for shared concepts; the source percentage used for
validation is explicitly named `source_preference_vote_percent` and remains
on its raw 0–100 scale. Public shares remain proportions.

All seven public functions retain their existing 2022 geographic matrix.
Results cover district plus parliamentary constituency/national (RD),
regional constituency/region (RF), municipal constituency/municipality (KF),
for preliminary and final counting. Seats cover the corresponding
non-district levels. Candidate-related and preference-vote data describe
final election results. Broader RF region/KF municipality preference-vote
aggregation and both detail/name settings are handled by the shared public
layer. No new unsupported geographical levels are inferred.

Validate with `development/validate_canonical_2022.R OUTPUT_DIR`. The sweep
uses public raw and canonical APIs, all supported levels/count stages,
both languages/detail settings, all list/zero preference-vote variants,
broader aggregation, keys, missingness, source/asset hashes and the
Norrbotten election-time identities. A local dirty build is only a reviewed
prototype: a future release requires a new clean-commit build, validation
and explicit publication approval. No 2022 release or registry entry is
created by these scripts.

The 2018 canonical collection is an independent Parquet data product. It uses
English public column names from `R/output_names.R`, with schema version 2
and data version `data-v0.1.0`. These versions are separate from the R package
version. The 2018 collection is published as `data-v0.1.0`; the 2022
`data-v0.2.0` collection above is an unpublished local build.

## Asset inventory

All filenames have the `.parquet` extension. The manifest records each file's
row count, byte size, SHA256 checksum, role and original table layout.

| Asset | Rows |
| --- | ---: |
| `rkl2018-results-rd` | 108,948 |
| `rkl2018-results-rf` | 87,759 |
| `rkl2018-results-kf` | 84,972 |
| `rkl2018-seats` | 4,374 |
| `rkl2018-candidacies` | 184,197 |
| `rkl2018-candidates` | 72,255 |
| `rkl2018-elected` | 14,723 |
| `rkl2018-substitutes` | 76,297 |
| `rkl2018-preference-votes-base-area-rd` | 34,253 |
| `rkl2018-preference-votes-area-rd` | 122,876 |
| `rkl2018-preference-votes-base-district-rd` | 951,606 |
| `rkl2018-preference-votes-district-rd` | 685,502 |
| `rkl2018-preference-votes-base-area-rf` | 52,968 |
| `rkl2018-preference-votes-area-rf` | 202,174 |
| `rkl2018-preference-votes-base-district-rf` | 1,143,157 |
| `rkl2018-preference-votes-district-rf` | 905,633 |
| `rkl2018-preference-votes-base-area-kf` | 129,275 |
| `rkl2018-preference-votes-area-kf` | 262,335 |
| `rkl2018-preference-votes-base-district-kf` | 1,224,345 |
| `rkl2018-preference-votes-district-kf` | 1,006,364 |

Results are partitioned by election code. Seat allocations and candidate
tables each have one asset. Preference-vote data have a public sparse view
and five small normalized components (`geo`, `parti`, `lista`, `roster`,
`listroster`) per election and level. Completed district panels are
reconstructed from those bases, avoiding millions of prewritten zero rows.
The technical `.component` values remain source-oriented Swedish labels;
their data values have not been translated. The English names of shared
columns are identical in bases and public analysis tables.

## Explicit package backend

The distribution is a GitHub Release with tag `data-v0.1.0` in
`richardohrvall/swelections`. `manifest.json` and the 20 Parquet files above
are release assets, **not Git files**. The manifest is the canonical entry
point at
`https://github.com/richardohrvall/swelections/releases/download/data-v0.1.0/manifest.json`.
It records every asset filename, byte size and SHA256 digest. The package
downloads and validates the manifest, then downloads only needed assets and
validates their sizes and SHA256 digests before use. The manifest and assets
are cached under the separate canonical data version and checksums. A cached
Parquet asset remains `source = "canonical"`, never raw `"local"`.

Explicit `source = "canonical"` resolves that release by default. For a
local build or mirror, set `swelections.canonical_manifest` to its manifest;
assets are then looked up beside it. `swelections.canonical_assets_dir` and
`swelections.canonical_base_url` may override the asset location for explicit
canonical requests. `swelections.canonical_cache_dir` changes the cache root.
`nanoparquet` remains optional. Canonical mode rejects raw `data_dir`,
`update` and `archive` and never falls back to raw files on a missing or
invalid asset. Explicit `"local"` and `"remote"` always use official raw data.

## Automatic source selection

The central registry in `R/canonical_distribution.R` names each approved
year, series, data version, schema version, release URL and `auto_eligible`
flag. Its initial row explicitly enables 2018 / `data-v0.1.0`; no 2022 or
2026 row exists. A calendar-year threshold is never used. For each requested
year and public table, `source = "auto"` follows this order:

1. If all raw files required by that table exist with nonzero size in the
   configured local archive, use `local`. The parser still validates their
   contents; a malformed local source errors rather than silently falling
   back. Results and seats require the 2018 result ZIP and party register;
   candidacies require the candidacy file; result-enriched candidate, elected,
   substitute and preference-vote tables require all three. Candidates with
   `include_results = FALSE` require only candidacies.
2. Otherwise, if the registry marks coverage eligible **and** the versioned
   published release manifest can be retrieved and validated (or was already
   retrieved into the release cache), use `canonical` when optional
   `nanoparquet` is installed. A local build selected with
   `swelections.canonical_manifest` does not by itself qualify for auto.
3. Otherwise use `remote`, the official raw source. Some 2018 raw URLs are no
   longer available, so this route may give the existing informative error.

`update = TRUE` or `archive = TRUE` retains the existing raw-data path and
does not select canonical. Explicit `source` always overrides `auto`. Each
year in a multi-year call is resolved separately. A later 2022 release needs
its own reviewed registry row; the current 2026 election remains on the raw
path until explicitly approved.

## Build and provenance

`data-raw/build-canonical-2018.R` rebuilds RDS intermediates from the
verified official 2018 result ZIP, participating-party file and currently
published redacted candidacy file. They are technical build inputs, not
distribution assets. `data-raw/export-canonical-parquet-2018.R` writes
the 20 English-schema Parquet files and `manifest.json`. The named local
research snapshot is not a build input and candidate names are never
released in this collection.

The manifest contains the independent data and schema versions, UTC build
time, package version, build Git SHA, clean/dirty tree flag, build-code
checksums, source identities and MD5/SHA256 values, and per-asset sizes and
SHA256 checksums. Assets are gzip-compressed Parquet, usable from R, Python,
DuckDB, Polars and other Parquet readers. No CSV, DTA or public RDS duplicate
is built. The local build artifacts are Git-ignored.

## Validation and release boundary

The exporter round-trips every Parquet file and validates values, order,
types and missingness. Integration tests verify manifest checksums,
English column names, normalized components and equivalence to raw-built
2018 intermediates. A separate opt-in test can reparse the official raw
archive and compare public outputs. The public `source = "canonical"` route
must agree for both `names = "en"` and `names = "sv"`.

No `data-v0.1.0` Git tag, GitHub release or asset publication is created by
this work. The release procedure is:

1. Commit and review the package code, schema, tests and this document while
   leaving generated assets outside Git.
2. From that clean commit, rebuild the raw RDS intermediates and export the
   20 Parquet assets and manifest. Confirm the manifest's build Git SHA equals
   the reviewed commit and `build_tree_dirty` is `false`.
3. Validate the schema, source hashes, every asset's size and SHA256, the
   direct raw/public API equivalence sweep, the full tests and `R CMD check`.
4. Create the `data-v0.1.0` tag/release from the reviewed code commit and
   upload `manifest.json` plus exactly the 20 listed Parquet files. Do not
   replace published assets in place; a change requires a new data version.
5. Test explicit canonical and `auto` with no local raw archive against the
   published release, then record the release URL and checksums.
