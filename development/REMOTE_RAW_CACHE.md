# Verified persistent cache for remote raw result files

Published in v0.4.0. The implementation/benchmark observations below were recorded on 21 October 2026; they are not current live-source guarantees.

## Behavior and source semantics

The common downloader caches indexed official result ZIP bytes under the user-specific tools::R_user_dir("swelections", "cache") / remote-raw directory. It does not persist parsed tables or API results. No new dependency or public function parameter is introduced. The optional swelections.remote_cache_dir setting controls storage location.

Each public call that reads indexed results downloads a fresh official index.md5. A request-local context shares that snapshot among nested readers, files, count stages and election types using the same collection. Different collections receive their own current index. The context is cleared on successful return and on errors. Standalone raw reader calls outside a public request obtain a fresh index too; no parsed index survives across calls.

Cache entries use collection / expected MD5 / original basename under a v1 storage directory. Every reuse hashes the actual stored bytes; a missing or corrupt entry is downloaded again. A changed index checksum selects a new verified generation, and a newly listed file is downloaded on demand. Previous content-addressed generations may remain on disk, but cannot be selected unless a new official index again identifies that checksum. No time-to-live or stale fallback is used.

New downloads use the existing transactional downloader, including its retry, timeout, nonempty-response and optional expected-byte checks. The official index MD5 is checked before publication. An incomplete, wrong-hash or failed download never becomes an eligible cache entry. Copies into reader temporary files are verified as well. Previously valid generations remain unchanged when a new generation fails verification.

An unavailable, empty, malformed or ambiguous current index is an error even if a previous raw file is cached. A requested indexed-result file absent from the current index is an error. A mismatch between download and index is an error suggesting a fresh request; it is not permission to use old bytes.

This is still source = "remote": current official data verified against the current request index. The internal cache is not the user archive and does not participate in local or auto source selection. Explicit local reads never use the network or this cache. Auto still chooses only approved canonical or supported remote routes. Canonical downloads keep their existing distinct checksum/cache implementation.

Files not covered by a supported result index are fetched fresh. In particular, the 2026 candidacy CSV is not in the result ZIP index and is not silently cached. This is why the second full KF elected call still transfers the 30.7 MB CSV. No ETag policy or separate candidacy-snapshot cache is invented.

The current official val2022 index (622 entries) and euval2024 index (2 entries) were also checked for availability. Existing historical reader restrictions and snapshot semantics are unchanged. The cache adds no new persistent parsing layer to those readers.

## Actual public benchmark

All runs execute valda(ar = 2026, val = "KF", source = "remote") against current official responses and compare the complete result with the approved pre-cache output. Each run is a separate R process. The cold and warm runs use the same isolated subdirectory of the user cache, outside the project. The uncached control bypasses only the new cache dispatcher and uses the unchanged transport and the same parsing/data logic. No other heavy validation job was deliberately run concurrently with these measurements.

| Case | Total seconds | Network seconds | Network requests | Downloaded bytes | Elected rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| uncached | 100.22 | 26.92 | 292 | 56,615,533 | 12528 |
| cold | 84.19 | 22.90 | 292 | 56,615,533 | 12528 |
| warm | 60.66 | 1.60 | 2 | 30,773,623 | 12528 |

Cold: one index, one candidacy CSV, 290 result ZIPs. Warm: one index and one candidacy CSV; zero ZIP transfers. All 290 persistent ZIP entries independently match their MD5 content keys. No URL is requested twice within any run. All three complete outputs are exactly identical, including row order, types and attributes.

The relevant transfer comparison is 26.92 seconds without cache versus 1.60 seconds warm: 25.32 seconds (94%) removed. Cold acquisition is 22.90 seconds. Totals vary with CPU and filesystem conditions; the cache does not remove the necessary repeated parsing/validation. The earlier 187.67-second audit used detailed nested instrumentation and overlapping checks, so the full difference from 187.67 to these new totals must not be attributed to caching.

## Validation

The deterministic regression panel covers empty/warm cache, changed/new files, missing/damaged entries, unavailable/malformed index, unsafe/duplicate keys, wrong download checksum, byte-count failure, failed update preserving an earlier generation, standalone readers, actual public request boundaries, uncached candidacy files, unchanged explicit local behavior and auto never selecting local. The existing complete source-selection and download test panels run alongside it.

The completed implementation checks are recorded below; the final published release checks are in [releases/v0.4.0.md](releases/v0.4.0.md). The pre-existing R/man/tests files changed in this task are only R/download.R, R/api_english.R, R/data_sources.R and man/data_sources.Rd. New implementation/test files are R/remote_raw_cache.R and tests/testthat/test-remote-raw-cache.R. No underlying election readers, election values, candidate identities, schemas, activation registry or canonical assets are changed.

All 202 existing distribution files (190 Parquet assets and 12 manifests) match the release inventory. Activation and upload-inventory hashes remain unchanged. Source files were not overwritten. Benchmark/cache test drivers, request metadata, exact outputs and integrity logs remain local under .local-data/remote-raw-cache-20261021; persistent benchmark raw bytes are in a user cache, not .local-data.

## Completed checks

- Full test suite: 5,136 passed, 16 explicit external-integration skips; zero failures, warnings or errors.
- R CMD check --no-manual: zero errors, warnings and notes; Status: OK. Installed-package test log independently reports PASS 5136 / SKIP 16 / FAIL 0 / WARN 0.
- Final R/man/tests are byte-identical to the staged package checked above.
- All 290 cached raw files independently match their MD5 keys; all 202 release files remain unchanged.
- No index, parsed table or final API result is persisted by the new cache; its only persistent payloads in the benchmark are the 290 raw ZIPs.
- These dated implementation checks preceded publication; the frozen release record gives the final commit and published inventory.
