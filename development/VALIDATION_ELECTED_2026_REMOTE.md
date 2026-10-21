# Validation of elected candidates from the 2026 remote sources

Audit date: 21 October 2026. No commit, push, release activation or canonical rebuild.

## Reproduction and exact failing source

The unmodified installed package is version 0.3.0.9000, RemoteSha 39622e7b3e2a37c4b35c272f03fb6535734d9e8f. GitHub origin HEAD was independently checked and is the same commit. This identifies the version tested here; it does not establish a different user installation version without its package metadata.

The exact public call valda(ar = 2026, val = "KF", source = "remote") reproduces the reported nested index 1 / index 9 error. The outer index selects the single year. The inner index is the ninth final municipality ZIP selected in official index order:

- Municipality: Salem, 0128.
- Official file: https://resultat.val.se/resultatfiler/val2026/s/kf/Val_2026_slutlig_0128_KF.zip
- JSON member actually read: Val_2026_slutlig_mandatfordelning_0128_KF.json.
- Party: Vänsterpartiet, code 0005.
- Candidate number: 53411. The elected node reports Pia Lindqvist Ortiz Venegas; the candidacy CSV reports Pia Ortiz-Venegas. Neither spelling nor identifier is changed.
- The candidate is elected in Salem, election order 1. The Salem party row exists: 640 party votes; its summeradePersonroster entry reports 107 preference votes.
- The CSV also contains a Värmdö candidacy (0120), list 09853, position 8. Salem uses list 09838, position 1.

The old semi-join matched candidate number + election type + party, retaining both municipal candidacies. It then required a Värmdö person-vote-area row (0120 / 0005) inside the Salem file (0128). That geographical row does not belong in this file. The error is an implementation error, not evidence that the official Salem export lacks its party row. The candidate has 107 preference votes across the supported candidacy areas, all reported in Salem.

## Official documentation and source preservation

The current [technical description](https://www.val.se/valresultat-och-statistik/statistik-och-data/teknisk-beskrivning-av-resultatfiler) states that final mandate files contain election-area and constituency aggregates plus the information for elected members and substitutes. The [final mandate field description](https://www.val.se/download/18.1a2972da19f159e73fd324f/1786558968669/slut-mandatfordelning.md) documents valomrade, valkretsLista, partiRoster, listRoster and summeradePersonroster. An area file is not a national catalogue of every candidacy held by its elected candidates.

The field description was preserved with URL, UTC retrieval time, bytes, MD5 and SHA256. Its SHA256 is a21f8f03127395805c307c59709b518d11f1a7a508e88a41ac5c78243681f17b. All retrieved index/CSV/ZIP responses are retained only in the ignored audit directory, with the same provenance fields. The official index MD5 is f41e800a0ee50d02cc0701837c7b0e89; candidacies CSV MD5 is c30f47a4ea28da2d926e0e186477a98b. All 290 KF ZIP checksums agree with that index.

## Extent and old versus optimized implementation

| Version tested | RD final | RF final | KF final |
| --- | ---: | ---: | --- |
| Installed published commit | 349 elected | 1,720 elected | Same error at Salem, index 9 |
| Optimized worktree before this fix | 349 elected | 1,720 elected | Same error at Salem, index 9 |
| Worktree after the targeted fix | 349 elected | 1,720 elected | 12,528 elected; all 290 files pass |

The optimization had made the same incorrect check faster. RD and RF output after the fix is exactly identical to the pre-fix worktree output, including row order, types and attributes.

Independent extraction from all KF mandate JSONs identifies seven elected candidates in seven municipalities with additional valid candidacy-geography rows outside their elected municipality. The old join pulls nine foreign geography rows into the wrong file:

| Index | Municipality | Candidate | Party | Other candidacy area incorrectly pulled into this file |
| ---: | --- | --- | --- | --- |
| 9 | Salem (0128) | 53411, Pia Lindqvist Ortiz Venegas | 0005 | Värmdö (0120) |
| 46 | Kinda (0513) | 5905, Jörgen Kalmendal | 0068 | Åtvidaberg (0561) |
| 48 | Åtvidaberg (0561) | 5183, Max Dahlgren | 0068 | Kinda (0513) |
| 68 | Eksjö (0686) | 5087, Henrik Nyberg | 0110 | Värnamo (0683), Mora (2062) |
| 168 | Lysekil (1484) | 52410, Peter Sahlberg Dahlström | 0068 | Sotenäs (1427) |
| 248 | Timrå (2262) | 53048, Robert Thunfors | 1773 | Sundsvall (2281), two candidacy constituencies |
| 288 | Boden (2582) | 45520, Nina Markström | 0110 | Luleå (2580) |

Names in this table are literal elected-node values; matching uses existing source keys. This audit does not infer or harmonize physical-person identity.

The 2026 elected API exposes final elected relations only. It has no preliminary/count argument. Existing tests confirm that a preliminary-only index fails rather than falling back to preliminary figures. RD/RF/KF final variants, both output languages and standard/full projections are covered.

## Corrective implementation

- R/valda_direkt_2026.R: restrict each mandate-file candidacy population to its own election type and election area. Return normalized per-file tables, including local candidacies needed to aggregate an elected candidate across multiple areas.
- R/valda_slutlig.R: enrich elected candidates once after collecting all requested final files, using the existing normalized-table aggregation already used for 2022. Preserve established file/candidate order and the official elected geography.
- Keep the actual missing elected-party-row error and all completion/list/sum validations. No candidate is skipped to bypass an error.
- Preserve NA if another candidacy area has no supporting party row; do not invent zero there. A verified complete reported party/list structure continues to support the existing zero-completion rule.
- tests/testthat/test-valda-geography-2026.R: deterministic KF/RF multi-area regression, genuine missing elected-party row, absent unelected-party missingness, and a public remote-call test verifying one mandate read per final file.

No public signature, schema, candidate identifier, name, source-election value, canonical asset, auto-eligibility flag or distribution manifest is changed.

## Download, parsing and construction timings

These are diagnostic timings on this machine, not a controlled hardware comparison with the user environment. Some runs overlap validation processes. Download instrumentation preserves every successful response and records inclusive nested timings; nested rows must not be summed twice.

| Public case | Elapsed seconds | Requests | Bytes represented | Actual network seconds |
| --- | ---: | ---: | ---: | ---: |
| Installed KF, stops at index 9 | 40.73 | 11 | 31,921,520 | 2.80 |
| Pre-fix optimized KF, same failure, preserved responses | 29.47 | 11 | 31,921,520 | 0 |
| Corrected KF, actual cold remote acquisition | 187.67 | 292 | 56,615,533 | 27.59 |
| Corrected KF, same public call with preserved-response replay | 123.03 | 292 replay reads | 56,615,533 | 0 |
| Corrected KF, English/full preserved-response replay | 129.75 | 292 replay reads | 56,615,533 | 0 |

The last two rows are an audit transport replay, not a new production cache. Normal source = "remote" does not persist these responses automatically and repeats the acquisitions on a later call. Explicit local source can use user-preserved files. This task introduces no caching policy change.

Cold corrected KF breakdown:

| Stage | Seconds | Meaning |
| --- | ---: | --- |
| Index network | 0.176 | One 44,667-byte index |
| Candidacy CSV network | 1.582 | One 30,728,956-byte CSV |
| ZIP network | 25.833 | 290 municipality ZIPs, 25,841,910 bytes |
| Index read/parse, including its network | 0.21 | Inclusive |
| CSV read/parse, including its network | 3.39 | About 1.81 beyond measured transfer |
| ZIP/JSON reads, including ZIP network | 43.57 | About 17.74 beyond measured transfers, including extraction and audit overhead |
| Candidate base construction | 17.04 | Existing broad candidate summary |
| Per-file validation / relation and vote table construction | 90.96 | Includes 34.89 elected/substitute parsing and 12.29 personal-election parsing |
| Final cross-area elected enrichment | 6.66 | One global aggregation |
| Other orchestration / presentation / instrumentation overhead | 25.84 | Residual; not claimed as a separately profiled production hotspot |

The complete request has 292 distinct URLs: index + candidacies + 290 final KF ZIPs. No URL is downloaded twice within that call. Only mandatfordelning JSON is parsed from each ZIP. The official bundles also contain vote-distribution JSON; transferring those bundled bytes cannot be avoided by selecting a different JSON member. No district JSON or preliminary ZIP is separately downloaded for elected candidates.

The full candidacy CSV provides published candidate attributes; the mandate files provide fixed election relations and personal-vote summaries. Later current-member files are not interchangeable with the fixed election result. The shared relation parser also constructs substitute tables that elected() does not use: that is CPU work, not extra file downloads, and has not been redesigned in this fix.

The reported eight-minute wait was not reproduced here. Before the original error only nine municipal ZIPs had been requested. The purrr municipality progress estimate covers download, parsing, validation and construction together; it is not a measurement of download time. On this connection, CPU/table construction dominates. The measurements cannot establish the actual network/CPU split on the user machine.

Installed RD took 14.91 seconds and RF 80.53 seconds. Pre-fix optimized replay took 8.50 / 16.77 seconds; corrected replay took 10.61 / 21.09 seconds. These are successful whole-election calls, unlike the KF failing prefix; timing variation and network differences are retained rather than interpreted as an additional optimization claim.

## Final validation and scope

- Full test suite: 5,098 passed, 16 explicit external-integration skips; zero failures, warnings or errors.
- R CMD check --no-manual: zero errors, warnings and notes; Status: OK.
- Independent source extraction: all 12,528 KF elected candidate/party/municipality/order keys and all elected preference-vote totals agree exactly. None is dropped or duplicated.
- Cold live and preserved-response KF outputs are exactly identical.
- All three actual English/full outputs project exactly to the independently obtained Swedish/standard outputs and round-trip between presentation languages.
- All RD/RF results remain exactly identical to the optimized pre-fix worktree.
- Actual 2022 RD/RF/KF elected raw/canonical full comparisons pass: 349 / 1,720 / 12,597 rows. The shared aggregation retains its previous behavior.
- All 292 cold-download MD5/SHA256 values verified; all 290 KF ZIPs match the official index.
- All 202 existing distribution files, comprising 190 Parquet assets and 12 manifests, remain byte-identical to the release inventory. Activation registration and upload inventory hashes are unchanged.
- Hash comparison against the start-of-task R/man/tests snapshot identifies exactly the two intended existing R files plus the new regression-test file; no other existing production/help/test file changed in this task.
- git diff --check passes. Earlier uncommitted work is preserved. No commit, push, activation change, canonical rebuild or publication.

Local evidence directory: .local-data/elected-2026-remote-audit-20261021. It contains the reproduction drivers, installed/worktree/fixed call outputs and logs, per-download and per-function timings, official field description with provenance, independent KF rows, full-test summary, package tarball/check logs and integrity results. Raw sources and generated artifacts are not added to Git.

## Closing performance assessment: no further optimization

Of the measured 187.67 seconds, 27.59 seconds were transport and 160.08 seconds were outside transport. A non-overlapping breakdown is: index/CSV reading beyond transfer 1.84 seconds; ZIP/JSON reading beyond transfer 17.74; candidate base 17.04; per-file completion/list/sum validation and relation/vote construction 90.96; global enrichment 6.66; other orchestration/presentation/instrumentation 25.84. The last category is a residual, not evidence that 25.84 seconds can be eliminated from production.

The shared relation parser constructs substitutes as well as elected rows. Its entire measured inclusive cost was 34.89 seconds; the unused substitute fraction was not separately measured. Treating that whole cost as avoidable would be incorrect. A selective relation-output mode would need changes and tests across shared consumers. No verified trivial change with a meaningful measured gain was identified, and no further optimization is made. The approximately three-minute complete cold remote call is documented as a known 2026 remote characteristic, subject to hardware, network and measurement overhead.

### Production cache verification

A targeted two-pass test uses the real index, candidacy CSV and mandate ZIP readers with only the network transport replaced by copies of preserved official responses. Each of the three URLs invokes transport once on each pass; outputs are identical. Evidence: final-performance-assessment.R/.log and production-cache-probe.csv in the ignored audit directory. No network is used in this verification.

There is no persistent production response cache for this remote path. The previous no-network replay measurements used an audit-only cache and must not be interpreted as ordinary remote repeat-call behavior. With the normal defaults, subsequent remote calls request the same inputs again. The earlier full-call trace establishes one request per URL within a call; this is different from cross-call reuse. Explicit local input avoids remote downloads, but is not an automatic remote response cache.

Therefore the request to confirm that production response caching prevents repeat downloads cannot be affirmed for the current implementation. Adding caching would require an explicit freshness/invalidation policy for changing official files; none is introduced as part of this closing assessment. Functional release validation remains passed; automatic cross-call remote caching is not a delivered feature. Production code, canonical data and release scope are unchanged in this assessment.

## Subsequent verified raw-cache implementation

The preceding no-cache finding describes the implementation before the follow-up cache task. A persistent MD5-index-verified raw ZIP cache has subsequently been implemented and tested, without changing the elected-data logic or reference outputs. See [REMOTE_RAW_CACHE.md](REMOTE_RAW_CACHE.md). Subsequent requests still fetch a current index and the unindexed candidacy CSV; unchanged result ZIPs are reused. No persistent parsed/result cache is added.
