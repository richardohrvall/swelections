# 2010 preliminary source preservation and validation — 2026-10-09

The current acquisition and independent validation tools are R-only; see
[R_ONLY_WORKFLOW.md](R_ONLY_WORKFLOW.md). Script names in the historical
inventory below refer to the original, now replaced or retired tools.

## Conclusion

The complete official preliminary collection-page population is available and is now preserved: RD 395, RF 392, KF 395. Election-night ordinary districts plus the **reported preliminary** collection figures reproduce the published preliminary aggregates exactly. There are no missing collection URLs and no numerical reconciliation, redistribution or substitution of final votes.

Source completeness is not the same as completed counting. The historical presentation leaves nine RF and nine KF collection pages without numerical vote results. Those units remain in the inventory with unknown results, not verified zeros. The reconstructed sums describe the same partial reporting state as the published preliminary presentation. They are not the final result.

This supersedes the earlier retrieval-based limitation in IMPLEMENTATION_2010_VALIDATION.md; it does not activate preliminary support in production code.

## Why the earlier attempt failed

The old development retriever retained the election letter when flattening XML codes: `R-0180-01` became `R018001`, producing a malformed path such as `/R0/18/00/` instead of `/01/80/01/`. It also used parallel requests without a deliberate inter-request delay. The recorded 429 failures therefore did not establish that the correct official pages were unavailable. Both the correct route and conservative retrieval are used here; no production reader was changed.

## Retrieval and provenance

Snapshot: `.local-data/rkl/2010/valresultat/preliminary-collection-preservation-20261009/`.

Official root: https://historik.val.se/val/val2010/prelresultat/

Expected collection keys were enumerated from the municipal final XML's `KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT` geography only. The exact election/municipality/constituency components form the URL, e.g. `R/onsdagsdistrikt/01/80/01/index.html`. No final vote attributes enter reconstruction.

The sequential development retriever uses a 1.5-second minimum delay before network attempts, a 90-second request timeout, at most three attempts for transient failures, 120/240-second minimum 429 backoff (honouring a longer numeric Retry-After), and stops after the third 429. Permanent 404s are not retried. No 429 or transient failure occurred in this run. Every successful preservation request has its response body cached with URL, final URL, retrieval timestamp, byte size, MD5 and SHA256. Successfully cached responses are not requested again.

The preservation run contains 2,170 successful response records: 1,880 fresh downloads and 290 byte-verified cached municipality pages reused from the earlier snapshot. It made 1,907 network requests (1,880 successes, 27 permanent 404s), excluding the initial diagnostic connectivity probe. Another 75 already preserved KF municipal-constituency pages are used as independent validation without new requests or modification.

Fresh preservation retrievals ran from `2026-10-09T06:43:09.784147+00:00` to `2026-10-09T07:43:06.863373+00:00`. This is a retrieval date, not an election-time source version. Source response headers and displayed historical reporting status are retained separately.

The 2,170 response bodies occupy 68,318,028 bytes. Individual filenames, URLs, dates, sizes and hashes are in `source-manifest.json`; the complete request plan is in `expected-sources.json`, and the append-only request journal is `retrieval.jsonl`.

Manifest SHA256: `576bb2c1cc2d5f88bedb4c628cc014852e0333d45670579df1db4206b3d36fd6`.

| Election | Expected collections | Preserved | Numerical results | Empty result pages | Ordinary night districts | Published counted/all |
|---|---:|---:|---:|---:|---:|---:|
| RD | 395 | 395 | 395 | 0 | 5668 | 6063/6063 |
| RF | 392 | 392 | 383 | 9 | 5629 | 6012/6021 |
| KF | 395 | 395 | 386 | 9 | 5668 | 6054/6063 |

### Preserved response inventory

| Election | Role | Files | Bytes |
|---|---|---:|---:|
| RD | collection_district | 395 | 6,003,889 |
| RD | constituency | 29 | 1,154,783 |
| RD | municipality | 286 | 13,651,730 |
| RD | national | 1 | 72,398 |
| RF | collection_district | 392 | 6,505,653 |
| RF | municipality | 266 | 12,985,739 |
| RF | national | 1 | 43,898 |
| RF | region | 20 | 605,996 |
| RF | regional_constituency | 94 | 5,115,094 |
| KF | collection_district | 395 | 6,277,711 |
| KF | municipality | 290 | 15,419,065 |
| KF | national | 1 | 482,072 |

## Independent reconstruction

Only ordinary `VALDISTRIKT` nodes from `valnatt.zip` provide ordinary votes. Only preliminary HTML's current 2010 party/category counts provide collection votes. Final XML provides code relations, municipal/constituency membership and the expected collection inventory; it supplies no vote fields. All 1,182 collection responses retain their exact preliminary URL without a final-result redirect and contain preliminary headings.

Collection keys are unique within election. Their normalized district codes are disjoint from the ordinary district codes. Municipal source files are used once; national XML is never added as another vote source. Area/constituency and national totals are sums of these non-overlapping components.

| Election | Valid votes | Blank invalid | Other invalid | Total votes | Difference from published national source |
|---|---:|---:|---:|---:|---:|
| RD | 5,944,506 | 64,568 | 18,178 | 6,027,252 | 0 |
| RF | 5,798,143 | 111,110 | 18,587 | 5,927,840 | 0 |
| KF | 5,898,796 | 83,801 | 25,379 | 6,007,976 | 0 |

Official national references: [RD](https://historik.val.se/val/val2010/prelresultat/R/rike/index.html), [RF](https://historik.val.se/val/val2010/prelresultat/L/rike/index.html), [KF](https://historik.val.se/val/val2010/prelresultat/K/rike/index.html).

All 1,067 independent geographic/party comparison blocks pass, including party/category integers and valid/invalid/total vote identities. The published national counted/all district figures match the preserved numerical/empty result population exactly. Comparisons use official party abbreviations within the relevant geographic unit; the national RF/KF overview groups non-main parties into its published other-party category. No numeric party IDs or candidate records are invented.

| Election | Independent comparisons | Breakdown | Numerical differences |
|---|---:|---|---:|
| RD | 320 | 290 municipalities, 29 constituencies, national | 0 |
| RF | 381 | 266 direct municipalities, 20 regions, 94 regional constituencies, national | 0 |
| KF | 366 | 290 municipalities, 75 previously preserved municipal constituencies, national | 0 |

RD's four absent municipal aliases are validated against their official constituency page only after checking that the constituency consists of precisely that municipality by official XML codes: Stockholm 0180, Gotland 0980, Malmö 1280 and Göteborg 1480. This is geographic equivalence, not guessed name matching or replacement of source votes.

Reconstructed electorate totals are not treated as independently complete just because collection-page electorate fields are absent; the audit validates current vote counts and reporting status. It does not freeze a new public turnout/schema rule.

## Empty preliminary result pages

All the following pages returned HTTP 200 and are preserved. Their current vote fields are blank; absence of numerical results is not an inaccessible source or an explicit zero. RF and KF have the same geographic set:

| Municipality | Official municipality name | Collection suffixes | Elections |
|---|---|---|---|
| 0604 | Aneby | 00 | RF/KF |
| 0780 | Växjö | 01, 02 | RF/KF |
| 0781 | Ljungby | 00 | RF/KF |
| 1784 | Arvika | 00 | RF/KF |
| 2401 | Nordmaling | 00 | RF/KF |
| 2403 | Bjurholm | 00 | RF/KF |
| 2480 | Umeå | 01, 02 | RF/KF |

These 18 units must retain unknown district results in any eventual public preliminary implementation. They may be excluded from a tally of **reported** votes, matching the published aggregates, but must not be assigned zero result rows. Existing strict 2014 HTML handling assumes numerical collection results and will need a separately reviewed treatment of these empty 2010 pages before activation. No production changes are made here.

## Other URLs returning 404

No required collection page is missing. The 27 failures below are direct aggregate URL candidates, each attempted once. They do not prevent complete collection-source coverage. RF's 23 direct municipal comparisons remain unavailable through these paths; RF region/constituency/national comparisons pass. The four RD municipalities have the exact constituency counterpart described above.

| Election | Geographic code | Role | URL |
|---|---|---|---|
| L | 0180 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/01/80/index.html |
| L | 0484 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/04/84/index.html |
| L | 0580 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/05/80/index.html |
| L | 0581 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/05/81/index.html |
| L | 0680 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/06/80/index.html |
| L | 0682 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/06/82/index.html |
| L | 0880 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/08/80/index.html |
| L | 0883 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/08/83/index.html |
| L | 1080 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/10/80/index.html |
| L | 1081 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/10/81/index.html |
| L | 1082 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/10/82/index.html |
| L | 1280 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/12/80/index.html |
| L | 1383 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/13/83/index.html |
| L | 1384 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/13/84/index.html |
| L | 1480 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/14/80/index.html |
| L | 2080 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/20/80/index.html |
| L | 2081 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/20/81/index.html |
| L | 2180 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/21/80/index.html |
| L | 2281 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/22/81/index.html |
| L | 2284 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/22/84/index.html |
| L | 2380 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/23/80/index.html |
| L | 2482 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/24/82/index.html |
| L | 2580 | municipality | https://historik.val.se/val/val2010/prelresultat/L/kommun/25/80/index.html |
| R | 0180 | municipality | https://historik.val.se/val/val2010/prelresultat/R/kommun/01/80/index.html |
| R | 0980 | municipality | https://historik.val.se/val/val2010/prelresultat/R/kommun/09/80/index.html |
| R | 1280 | municipality | https://historik.val.se/val/val2010/prelresultat/R/kommun/12/80/index.html |
| R | 1480 | municipality | https://historik.val.se/val/val2010/prelresultat/R/kommun/14/80/index.html |

## Candidate preference-vote assessment

All 2,170 preserved preliminary presentation pages were inspected: no candidate-specific table headers or `KANDNR` data fields were found. Every preference-vote navigation link targets `/slutresultat/`, not a preliminary candidate result. The preliminary pages contain party/category votes, not identified candidate preference-vote counts or a completeness certificate for final candidate totals.

Consequently these preliminary sources do not by themselves resolve the previously documented 171 RD / 53 RF / 10 KF candidate-total NAs. Following the final-presentation links would be a separate final-source investigation; this audit does not assert that such a future investigation could never help. No candidate missingness/identity/name logic is changed.

## Integrity, files and stopping point

- All 39 original 2010 source-file MD5/SHA256 values remain unchanged.
- All 365 older preserved HTML source hashes remain unchanged.
- All 96 pinned production-R/prototype files remain byte-identical. No production code, tests, package documentation, canonical assets, release, version, commit or push is changed.
- New development-only scripts: `preserve_preliminary_2010_conservative.py`, `validate_preliminary_2010_preserved.py`, `assess_preliminary_2010_candidate_information.py`.
- New report: this file. New ignored snapshot contains immutable response bodies and provenance/validation metadata. No public or canonical preliminary dataset is constructed.
- Detailed local audits: snapshot `validation.json` and `candidate-information-assessment.json`; logs `.local-data/2010-preliminary-conservative.log` and `.local-data/2010-preliminary-source-validation-final.log`.

The retrieval limitation is resolved. The source evidence supports constructing the published 2010 preliminary reporting state for RD/RF/KF from election-night ordinary votes plus preliminary collection votes. Stop here before selecting/activating the new snapshot or changing production handling of the 18 empty result pages.
