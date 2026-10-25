#' Select canonical or official raw election sources
#'
#' Source selection is shared across ordinary RKL elections, European Parliament
#' elections and the 2003 referendum. It does not change their schemas or coverage.
#'
#' @section Selection:
#' * `source = "auto"` first selects canonical coverage explicitly approved in the
#'   registry for the requested family, event, year and view. This takes precedence
#'   over `data_dir` and `options(swelections.data_dir = ...)`.
#'   Automatic permission requires both the event activation flag and its central
#'   `auto_functions` list. Only then is actual manifest coverage checked. A full
#'   or locally configured manifest cannot grant permission for another function.
#' * `source = "canonical"` explicitly selects a registered canonical reader and
#'   configured/published manifest. Unpublished builds remain available this way.
#'   This explicit choice is independent of auto permission and still requires
#'   the requested asset/view to exist in the selected manifest.
#' * `source = "local"` uses the user's preserved raw sources, never the network.
#' * `source = "remote"` explicitly uses a current, official and supported
#'   Valmyndigheten source, regardless of format or canonical availability.
#'   It never falls back to canonical or local sources. A new presentation
#'   format does not automatically replace an older supported export contract.
#'
#' Without approved canonical coverage, `auto` uses a supported remote source,
#' never user-saved local raw files, even when a raw archive is configured. If
#' neither source is available, select `source = "local"` explicitly for saved
#' raw files. Remote download caches remain separate from user raw archives.
#' A missing or incomplete
#' preliminary source is never replaced by final data.
#'
#' Published canonical coverage enables RKL 2002--2022, EU 2004--2024 and the
#' 2003 referendum under data-v0.4.1. RKL 2002 excludes candidacies; the referendum
#' supports results only. EU 2009 excludes automatic preference votes even if a
#' configured private manifest contains those assets. Use explicit local sources
#' for that historical preference-vote archive. RKL 2018 selects the corrected
#' generation, never the former data-v0.1.0 files. Re-elections in 2003, 2011,
#' 2015 and 2019 enable final results/seats only, preserving their actual scope.
#' These use four manifests such as `rkl2011-re-election-manifest.json`.
#'
#' Each product has a unique manifest filename such as `rkl2018-manifest.json`,
#' `eu2009-manifest.json` or `referendum2003-manifest.json`, alongside the uniquely
#' named Parquet assets in the published data-v0.4.1 GitHub release. Configured
#' unpublished builds can be used explicitly for validation. A missing selected
#' canonical file gives an error, without silent raw fallback. Local manifest overrides
#' cannot extend the central auto permission.
#'
#' Once selected, canonical download, checksum or schema failures are errors, not
#' reasons to silently change source. Parquet reading requires optional package
#' `nanoparquet`; a missing reader gives installation guidance. SHA256 verification
#' also requires `tools::sha256sum()` on the running R installation.
#'
#' Mandate-period history uses canonical intervals for 2014/2018 and current
#' remote member/history exports for 2022. The two date queries filter the same
#' population of allocated mandates. 2022 history is not made canonical merely because its fixed
#' election results are canonical. See [mandate_history()] for source coverage.
#'
#' @section 2022 remote coverage:
#' The former indexed 2022 result JSON distribution is no longer publicly
#' available. Explicit remote requests that require it fail with source guidance;
#' they do not use presentation JSON, old raw caches or saved archives instead.
#' Approved canonical results and explicit compatible local archives are unchanged.
#' The separately supported current candidacy ZIP/CSV and mandate-period
#' member/history exports remain remote sources under their existing contracts.
#' Source formats and coverage differ by election and function.
#'
#' @section Verified remote raw-file cache:
#' Structured result ZIPs indexed by Valmyndigheten's `index.md5` are stored in
#' a user-specific `remote-raw` subdirectory of `tools::R_user_dir("swelections", "cache")`.
#' Each public request for indexed results retrieves a fresh index. Readers share it
#' only for the duration of the request. A stored file is reused only after its
#' actual MD5 matches the current index; missing, corrupt or changed files are
#' downloaded transactionally and verified before caching. Index or checksum
#' failures are errors, never permission to use stale remote data.
#' Files outside that index, including the 2026 candidacy CSV, are still fetched
#' fresh. Only raw bytes persist: parsed tables and API results are not cached
#' by this mechanism. A later request still repeats parsing and validation.
#' The cache does not change source selection and is separate from `data_dir`
#' and the user's explicit local archive. `update`/`archive` can copy freshly
#' verified remote bytes into that archive under their existing semantics.
#' `options(swelections.remote_cache_dir = "path")` overrides the internal raw
#' cache location. Removing this cache only causes verified files to be fetched
#' again; it does not remove a user's local archive or canonical cache.
#'
#' @section Local archives and manifests:
#' `data_dir` identifies a supported raw-source archive, not canonical Parquet
#' files or arbitrary tables. The archive can be stored anywhere; no development
#' `.local-data` location is required. Historical adapters retain their documented
#' snapshot layouts, manifests and integrity requirements. To force an archive
#' when canonical coverage exists, use `source = "local"` explicitly.
#'
#' For a compatible 2014 local archive, final XML is under
#' `2014/valresultat/slutresultat_20141001`, election-night XML under
#' `2014/valresultat/valnatt`, and ballot files under `2014/kandidater`.
#' Preliminary results also require an independently captured preliminary
#' collection-district presentation; final collection votes cannot fill that gap.
#' These historical archives are read-only: remote, update and archive operations
#' are unavailable. Final election files, not later membership exports, supply
#' elected/substitute and preference-vote results. Missing historical names and
#' unsupported attributes remain missing.
#'
#' Configure a canonical build using `options(swelections.canonical_manifest =
#' "my-build/manifest.json")`. Multi-product configurations can use a named
#' character vector with keys `rkl:ordinary:2014`, `eu:ordinary:2014` or
#' `folkomr:ordinary:2003`. Shorter `series:year` keys and legacy year-only keys
#' remain supported; family/event keys take precedence. Every selected manifest
#' is checked against the requested family, year and schema. Canonical assets,
#' cache and URL options retain their existing meanings.
#'
#' @section Value contract:
#' Current canonical data use schema version 3, value version 1 and storage
#' version 1. English output uses English technical categories; Swedish output
#' localizes them, including counting stages, geography, status and election basis.
#' Proper names and literal source identifiers are never translated generically.
#' Referendum option names are `yes`, `no`, `blank` in English and `Ja`, `Nej`,
#' `Blank` in Swedish; blank is valid and invalid ballots remain separate.
#' Consent and candidate declaration are logical with separate applicability:
#' not applicable has value `NA` and applicability `FALSE`; an unknown source
#' value has both `NA`. A negative answer is `FALSE` with applicability `TRUE`.
#' Both fields are source detail in full output. `S`/`B` ballot-status identifiers
#' remain source codes; no meaning is inferred from them. `Other parties` and
#' `Handwritten votes` are aggregate labels, not translated political-party names.
#'
#' @section Compatibility and boundaries:
#' Explicit `update`/`archive` with `auto` requests a fresh remote download and
#' bypasses canonical selection. `canonical` cannot be combined with `data_dir`,
#' `update` or `archive`. Read-only historical snapshot restrictions still apply.
#'
#' Remote sources may contain names absent from a frozen canonical product, but
#' may also contain corrections or mandate-period updates. No source generations
#' are silently blended. Re-election events, their derived mandate compositions,
#' and mandate-period history retain their separate existing source support;
#' ordinary canonical coverage does not enable those products automatically.
#'
#' @examples
#' \dontrun{
#' options(swelections.canonical_manifest = "my-rkl2018-build/manifest.json")
#' results(2018, "parliamentary") # approved, configured current canonical
#' results(2018, "parliamentary", source = "local", data_dir = "my-archive")
#' results(2026, "regional", source = "remote")
#' options(swelections.canonical_manifest = c(
#'   `eu:ordinary:2024` = "my-eu-build/manifest.json"))
#' results(2024, "european", source = "canonical")
#' }
#' @name data_sources
#' @seealso [results()], [seats()], [candidacies()], [candidates()], [elected()],
#'   [substitutes()], [preference_votes()]
NULL
