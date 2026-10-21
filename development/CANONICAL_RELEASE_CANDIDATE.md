> Aktuell utökning: mandatperiodshistorik 2014–2018 och 2018–2022 är nu förberedd
> som canonical. 2022–2026 använder remote och har inget canonical-historikasset.
> Kandidaten omfattar nu **190 Parquet-assets + 12 manifest = 202 filer**.
> Den äldre 188-asset-inventeringen och dess validering nedan är baslinjen;
> samtliga dessa Parquet-filer är oförändrade. Se
> [mandatperiodernas source-modell](MANDATE_HISTORY_SOURCE_SELECTION.md) för
> aktuellt tillägg och [filinventeringen](CANONICAL_RELEASE_UPLOADS.csv).

# Canonical release candidate: activated configuration

Status: local, unpublished release candidate, 21 October 2026. No commit, push,
tag or GitHub upload has been performed. This section supersedes the earlier
inactive-flag stages in the activation inventory and source-selection design.

## Actual activation and distribution

All twelve registered ordinary products now have `auto_eligible = true`.
Eleven flags changed from false; RKL 2018 was already true and now points to the
corrected `data-v0.4.0` generation rather than the old published generation.
The approved central function permissions are unchanged.

G7 denotes results, seats, candidacies, candidates, elected, substitutes and
preference_votes. Permissions apply equally to their Swedish wrappers.

| Product | Auto-approved functions | Parquet files | Distribution manifest |
| --- | --- | ---: | --- |
| RKL 2002 | G7 except candidacies | 14 | rkl2002-manifest.json |
| RKL 2006 | G7 | 15 | rkl2006-manifest.json |
| RKL 2010 | G7 | 24 | rkl2010-manifest.json |
| RKL 2014 | G7 | 24 | rkl2014-manifest.json |
| RKL 2018 | G7 | 20 | rkl2018-manifest.json |
| RKL 2022 | G7 | 24 | rkl2022-manifest.json |
| Referendum 2003 | results | 1 | referendum2003-manifest.json |
| EU 2004 | G7 | 14 | eu2004-manifest.json |
| EU 2009 | G7 except preference_votes | 8 | eu2009-manifest.json |
| EU 2014 | G7 | 14 | eu2014-manifest.json |
| EU 2019 | G7 | 15 | eu2019-manifest.json |
| EU 2024 | G7 | 15 | eu2024-manifest.json |
| **Total** | | **188** | **12 manifests** |

The 188 Parquet files occupy 253,792,235 bytes and are byte-identical to the
approved normalized references. Their asset identifiers are their filenames,
with a .parquet suffix. The six EU 2009 preference-base assets remain private
and are omitted from its distribution manifest and table declarations.
No election values, identities, geographic allocations or source limitations
have been changed during activation.

All products use the planned base URL:
`https://github.com/richardohrvall/swelections/releases/download/data-v0.4.0`.

Manifest names are unique in that flat release directory, as are asset names.
[CANONICAL_RELEASE_UPLOADS.csv](CANONICAL_RELEASE_UPLOADS.csv) specifies every
one of the **200 upload files**, including byte size, SHA256 and exact URL.
That CSV is an inventory, not an additional required release asset. Its manifest
hashes describe this working-tree candidate and must be regenerated after the
clean committed rebuild. Schema/value/storage contracts are 3/1/1.

## User-visible source selection

A normal supported call without a source argument uses the registered canonical
manifest and requested asset. The registration, central function permission and
manifest view coverage must all permit this selection. Private prototype content
cannot expand the central permissions.

EU 2009 preference_votes is never auto-canonical; its historical raw source
requires explicit local selection. A missing preference asset in the published
subset also fails explicitly for source = canonical. A complete private manifest
remains usable through explicit canonical selection, without changing auto
permissions. RKL 2002 candidacies likewise has no auto permission.

Auto never selects local files, including when matching developer/user archives
exist. Unregistered modern elections retain their supported remote route (such
as RKL 2026). Explicit local remains available for supported user-supplied files.
No new election occasion or re-election has been activated.

The configured public URLs are not live release assets yet. Normal calls in an
installation without an existing cache cannot fetch this candidate until it is
published. The actual configuration was tested by bridging only its registered
URLs to an isolated localhost HTTP server; flags, permissions and source
selection were not simulated or overridden.

## Portable provenance in distribution metadata

User-approved portability applies only to distribution copies. Original build
manifests, raw source files and every Parquet file remain unchanged.

Absolute project/archive prefixes become portable source labels such as
`rkl/2010/valresultat/slutresultat.zip`. Temporary 2022 preparation and
official-correction locations become logical labels under `rkl/2022/`.
Data-frame source row labels serialized as JSON `_row` receive the same treatment.
These labels are provenance references, never files that an end user is expected
to possess. Source SHA256, MD5, official URLs and the original manifest SHA256
are preserved. JSON field pointers beginning with / remain unchanged.

Canonical retrieval uses registered base URLs, safe asset basenames, asset sizes
and checksums. It does not open source-provenance paths. A similarly named
sources field in the historical 2002 raw-source manifest belongs to a different
raw-input contract and is untouched.

The preparation tool refuses unknown absolute local paths. The independent
[data-raw metadata regression](../data-raw/validate-canonical-release-metadata.R)
checks all twelve serialized JSON files, including row labels, against the
original staged copies. It verifies no absolute machine paths remain, all
operational fields are identical, official source hash/URL information is
preserved, and all 188 asset inventory entries are identical. Tests distinguish
HTTP URLs and JSON field pointers from filesystem paths.

Preparation:
`Rscript data-raw/prepare-canonical-release.R MANIFESTS.csv EMPTY_OUTPUT_DIR --allow-dirty`

Metadata regression:
`Rscript data-raw/validate-canonical-release-metadata.R ORIGINAL_STAGE PORTABLE_STAGE INPUTS.csv`

The input CSV and original/staged files are local; no raw sources are added to Git.
The preparation tool refuses dirty build manifests by default. --allow-dirty is
solely for the current local review; it does not change their build status.

## Validation and remaining publication gates

Validation evidence is under the ignored local directory
`.local-data/canonical-release-candidate-20261021/`. The final portable staging
directory is `distribution-portable-complete/`; earlier staging attempts are not
release inputs.

The actual activated configuration is checked through normal public calls and
explicit canonical reference calls across all registered products, language and
detail variants, plus requested geographic/count-stage views. This also checks
all 188 files through the real URL/cache path, schema metadata, SHA256 and
Parquet round-trip. Ragunda KF candidate 534885 appears in the corrected 2018
elected output; the old published generation is not selected.

Nine fresh raw/canonical comparisons cover final national RD for all six RKL
years, 2018 KF seats, the 2003 referendum and EU 2024. These supplement the
earlier full source validation; they are not a claim that every historical
raw/SCB validator was rerun during distribution preparation.

The 206 current reference files/manifests and 1,300 protected historical
references retain identical checksums. No raw or generated assets are tracked.

All input build manifests truthfully retain `build_tree_dirty = true`.
Final release preparation still requires:
1. Approval, commit, then clean canonical rebuild from that committed code.
2. Revalidation with `build_tree_dirty = false`, updated code provenance,
   manifest checksums and upload inventory.
3. Separate permission for GitHub publication, then checks against live URLs.

Known data limitations remain those in the readiness reports, including EU 2004's
943-vote aggregate, EU 2009's open preference-vote questions, EU 2014's ten
handwritten votes without reported party designation and incomplete preliminary
collection snapshot, and EU 2024's candidate 1203 snapshot difference.
No additional data recovery or correction has been attempted.


### Completed validation results for this candidate

- Complete package suite: **5,000 passed, 16 explicit skips, zero failures,
  warnings or errors**. Skips require external integrations/configuration.
- Repeated `R CMD check --no-manual`: **0 errors, 0 warnings, 0 notes**.
- Final metadata regression: all twelve serialized manifests free of absolute
  local paths; all operational fields and all 188 Parquet inventory entries
  unchanged. Source-path metadata changes are confined to RKL 2010, 2014 and
  2022, including serialized source row labels. JSON serialization is repeatable
  and path conversion is idempotent.
- Total distribution sizes: **253,792,235 Parquet bytes** and **6,430,696 JSON
  manifest bytes** for this working-tree candidate.
- `git diff --check` passes. Git tracks no .local-data, .parquet, .dta or .py
  files. Package source/code/tests match the isolated checked package exactly;
  preparation and metadata-validation tools are excluded from installation.

The independent metadata regression is additional to the package suite and does
not rely on production source-normalisation code. Local path-change evidence is
retained in the staging receipt; it is not part of the public upload inventory.


### Final transport and integrity evidence

Before the metadata-only portability step, the complete activated API matrix
passed **1,040 normal calls without source overrides plus 1,040 explicit reference
calls**, covering the approved functions, geographic/count views, English/Swedish
and standard/full. The original full-matrix log is `actual-validation.log`.

After portability, an additional **48 normal calls plus 48 reference calls**
exercise all twelve final manifests in English/Swedish and standard/full, with
identical order, types and attributes. The final `portable-smoke.log` also verifies
EU 2009 permission/subset errors and the full private-manifest guard, Ragunda,
exactly **200 configured-URL HTTP fetches** (12 manifests + 188 assets), zero raw
source requests, and fresh schema/checksum/Parquet round-trip checks for all 188.
The URL bridge changes transport only; the production registry is used as-is.
A redundant second full matrix was stopped in favour of this targeted recheck,
because the independent comparison proves all operational manifest fields equal.

**9,514 locally available manifest-listed raw source files** additionally match
their recorded SHA256. This count concerns source files actually available at
manifest-listed paths; it is not a claim that temporary historical build paths
remain available. Source hashes and original manifest hashes themselves are
preserved unchanged in the distribution metadata.

No additional election data or API changes are required by these checks. The
remaining gates are approval, commit, clean rebuild, final validation and separately
authorised publication. All staged builds remain truthfully dirty.
