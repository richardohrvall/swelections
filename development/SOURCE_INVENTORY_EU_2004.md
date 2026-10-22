# EU 2004: source inventory and completeness assessment

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


Review date: **17 October 2026**. Election occasion: **13 June 2004**.
Source review plus implementation follow-up; see COMPLETENESS_EU_2004.md and
VALIDATION_EU_2004.md for the completed build. No commit/push/tag/release; EU 2009 is unchanged.

## Decision summary

**The preserved and recovered official sources are sufficient for complete final
results**, including all reported small-party candidate preferences and all final
voting units. All seven public views can be supported at their appropriate
geographic levels, using **candidacy/list-position keys**, not asserted person IDs.

- Final: **2,512,069 valid + 68,129 blank invalid + 4,266 other invalid =
  2,584,464 ballots cast**; **6,827,870 eligible voters**.
- Geography: national, 21 counties, 29 reused parliamentary reporting
  constituencies, 290 municipalities, 185 actual municipal constituencies,
  211 technical municipality-wide `00` branches, **5,875 ordinary districts +
  396 Wednesday units**. These are reporting subdivisions of a national EU
  election, not separate EP seat-allocation constituencies.
- All 30 local list/category files match the archived official payload SHA1
  digests. They contain **85,349 positive list/category/unit rows**.
- Complete ballot XML: **30 definitive candidate-bearing ballots, 27 parties,
  382 list-position observations**. No source person/candidate ID was found.
- **282,901 positive preference observations, 360 ballot-position keys,
  1,480,960 preferences**, with no duplicate observation keys. All 85,349
  list-total controls pass; every preference key exists in the ballot register.
- Original allocation: **19 allocated seats, 19 elected observations, zero
  unfilled seats**, 27 substitute posts in eight groups / 71 expanded relations.
- Full preliminary collection results have **not** been recovered. The preserved
  election-night aggregate is not a full preliminary result.

Two SCB presentation/coding discrepancies are documented below. Neither requires
changing the internally reconciled Valmyndigheten final result.

## 1. Source authority, preservation and provenance

Valmyndigheten is the primary result authority. SCB supplies independent official
controls; SND supplies preserved SCB-derived district data and documentation, not
an independent count of ballots. A Wayback copy preserves an official
Valmyndigheten object; Wayback is not an independent election-result authority.

Original local material: **41 files / 12,324,313 bytes**, including two duplicate
pairs of postal-voting workbooks. All originals remain byte-unchanged.
New responses, extracts, R diagnostics and evidence tables are under:

`.local-data/eu/2004/inventory-20261017/`

- `original-files.csv`: every original path, size, filesystem modification time,
  MD5 and SHA256. Original retrieval/publication times are unknown; modification
  times are not publication dates.
- `retrieval.csv`: requested and effective URL, retrieval UTC, HTTP status,
  response size, MD5, SHA256 and errors. Query JSON and response headers are also
  preserved. Some files named `.html` are actual SCB Excel responses after an
  official redirect; their format was inspected, not inferred from the suffix.
- `local-list-archive-digest-controls.csv`: **30/30** local list payloads match
  official-source archive-index SHA1 digests.
- `archive-preference-digest-controls.csv`: **20/20** complete named preference
  payloads match their archive-index digests. These are additional integrity
  controls, not substitutes for the recorded MD5/SHA256.
- SND's supplied `sha256.txt`: **5/5** extracted data objects match.

HTTP 503/access-denied responses and interrupted transfers are retained as
failed acquisitions, not accepted as data or evidence that a source never existed.
The first FP archive capture was incomplete; a **different, complete 10 November
2004 capture** was recovered and verified. Its 30,428 rows match the current
FP export exactly in every field except the redacted name field.

### Primary official sources

| Source | Preserved coverage / provenance |
| --- | --- |
| [Final result index](https://historik.val.se/val/ep2004/resultat/slutresultat/index.html) | Final tables, person results, national XML and district raw-data links. Current page says the final protocol has been removed. |
| [National final XML](https://historik.val.se/val/ep2004/resultat/slutresultat/slutresultat_00E.xml) | ISO-8859-1; national + 21 counties + 29 reporting constituencies + 290 municipalities; mandates, original elected/substitute groups and nine main-party candidate/list summaries. Current candidate names are `Personuppgift borttagen`. |
| [Original national XML, capture 19 June 2004 15:42:51 UTC](https://web.archive.org/web/20040619154251id_/http://www.val.se:80/val/ep2004/resultat/slutresultat/slutresultat_00E.xml) | Original names survive. Same element sequence and all attributes other than `NAMN` as the local/current national XML. Root report timestamp `20040617154308`; national timestamp `20040616224138`. |
| [District raw-data index](https://historik.val.se/val/ep2004/resultat_distrikt/radata.html) | Links all 30 list/category text files and 20 candidate-preference text files; official column documentation. |
| [List format](https://historik.val.se/val/ep2004/resultat_distrikt/listroster.html) | Thirteen fields: party; county; municipality suffix; municipal constituency; district; geographic names; electorate; list number; votes; preferences. Wednesday district is `E` + constituency suffix. |
| [Preference format](https://historik.val.se/val/ep2004/resultat_distrikt/personroster.html) | Thirteen fields: same nine geography/party fields, list number, candidate name, **candidate number on the list**, preferences. This number is a ballot position, not a person ID. |
| `resultat_distrikt/E_listrost_<code>.txt` | Complete local collection, byte-verified against archived originals. Includes ordinary and Wednesday results and explicit blank/other-invalid categories. |
| `resultat_distrikt/E_persrost_<code>.txt` | All 20 linked positive-preference party files preserved as complete named originals; current versions retain numeric data but redact candidate names. Files for the seven zero-preference parties are not linked and are not needed to account for any preference vote. |
| [Ballot XML ZIP, capture 12 September 2014 11:33:45 UTC](https://web.archive.org/web/20140912113345id_/http://www.val.se/val/ep2004/valsedlar/from_portal/xml/00E.zip) | One `00E.xml`, 118,747 extracted bytes; ZIP member timestamp **13 June 2004 05:10**, timezone unspecified. Complete definitive ballot register. Archive capture date is not the election/snapshot date. |
| [Ballot presentation, capture 2 June 2004 22:08:25 UTC](https://web.archive.org/web/20040602220825id_/http://www.val.se:80/val/ep2004/valsedlar/from_portal/E.html) | 30 ballot panels. Earlier 4 April capture has 23 panels and is an earlier population, not the preferred build snapshot. |
| [Original small-party national preferences](https://web.archive.org/web/20040830001812id_/http://www.val.se:80/val/ep2004/resultat/slutresultat/person_ovr_00E.html) | Additional named published presentation; detailed text/list controls supply the reproducible complete preference counts. |
| [Katrineholm final XML, capture 23 August 2004 11:51:24 UTC](https://web.archive.org/web/20040823115124id_/http://www.val.se:80/val/ep2004/resultat/slutresultat/slutresultat_0483E.xml) | Establishes the zero-vote Wednesday unit omitted from the positive-only text rows. |

Key frozen source SHA256 values:

| Object | SHA256 |
| --- | --- |
| Local/current national XML | `c59194b5b7599424abb22d8fbbd0bfa2f3dbd133fde61fa0ad6dad2603d045eb` |
| Original named national XML | `4e15bad1c590ff6a27e2c0b5ab640bb1f3cae70a3326943bb898e34d21b20157` |
| Original ballot ZIP | `9e85bb5377e39d4434370de39f9e1e06760d876b0005362bc2a35b8327c6ba8c` |
| Complete original FP preference file | `8bef2be2fd38ceb6c3318ab584a5d7dc88345d24cf60d112e7012a8ea6575fbe` |

### SCB and SND

[SCB's official result product](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/)
links the historical workbooks and current Statistics Database tables.

| Local/retrieved material | Structure and use |
| --- | --- |
| Local `scb/tab-02b_eu_kommun_tab_talut.xls` | 433 x 29 sheet including headings; **312** national/county/municipal records. Electorate, foreign EU electorate, cast, turnout, valid, invalid, blank and eight mandate parties + other. |
| Local `scb/tab-04-eu_kommun_tab_procut.xls` | 432 x 31 including headings; percentage presentation and repeated count controls, not a second election snapshot. |
| Local `scb/eu_ovr_partiut_100917.xls` | 443 x 6 including headings; **347 disclosed municipality-party counts** for parties with at least 0.5% locally. Official page identifies revision **17 September 2010**. This threshold is not a complete small-party census. |
| Local `scb/tab-10-eu_persrost_parti_procut.xls` | 34 x 18; national + 21 counties, preference shares for the eight mandate parties. |
| Local `scb/tab-11_eu_persrost_parti_mandut.xls` | 34 x 18; national + 21 counties, preference counts for eight mandate parties. Byte-identical to freshly retrieved official workbook. |
| Fresh SCB `tab-01a_eu_rbr_ma_kv.xls` | 29 x 16 including headings; national + 21 counties; electorate by sex and Swedish residence/abroad/other EU citizenship. |
| Fresh SCB `tab-02a-eu_rbr_ma_kv_kommun.xls` | 404 x 16 including headings; **312** national/county/municipal component records. |
| Fresh SCB parish electorate workbook | Three large cities, sex/residence/citizenship; supplementary historical geography, not needed to fill municipal totals. Full parish-code linkage is **NOT VERIFIED**. |
| Fresh SCB mandate-party preference/sex workbook | National + 21 counties; counts by sex and aggregate shares. |
| Current SSD `EUvalA`, `ME0109T08`, `ME0109T02`, `ME0109T01`, `ME0109T07` | Preserved metadata, 2004 query JSON and responses: results, preferences, electorate composition, mandates and turnout. Exact controls and a source coding discrepancy are below. |
| [SND: Svenska valdata, Europaparlamentsvalet 2004](https://researchdata.se/sv/catalogue/dataset/snd0241-3) | SCB-derived administrative results, not an exit poll. Local `snd0241-3-2.zip`: DTA + SAV + XLSX and notes; **6,165 x 21** result data = 5,875 districts + 290 municipal totals. |

The SND archive contains `0241_EuP04_valdistr.dta/.sav`,
`0241_EuP04_noter.dta/.sav`, `0241_EuP04.xlsx`, and `sha256.txt`.
The workbook has `NOTER` and `EU04_valddistr`; DTA/SAV are alternate formats,
not independent result sources. The notes explicitly say postal votes are
included only in municipal `ÖÖsum` totals. Those rows must not be added to the
ordinary districts. One notes sentence incorrectly calls the subtracted quantity
eligible voters although its column-I example is **voters/ballots cast**; read the
actual column definition and the numeric example, not that word in isolation.
SND has no candidate/person-vote data.

The two `oppet2004.xls` copies (1,393 x 9 main sheet, plus empty sheet) describe
postal-voting locations/opening hours. The two `post2004.xls` copies (1,254 x 24
main sheet plus empty sheets) describe received advance/postal votes by site/date.
They are operational material, **not final Wednesday-unit party results**, and
must not be used to fill a preliminary count. Both duplicate pairs are byte-identical.

## 2. Final results and geographic coverage

| Component | Ordinary districts | Wednesday units | National total |
| --- | ---: | ---: | ---: |
| Valid votes | 2,466,805 | 45,264 | **2,512,069** |
| Blank invalid | 66,810 | 1,319 | **68,129** |
| Other invalid | 4,087 | 179 | **4,266** |
| Ballots cast | 2,537,702 | 46,762 | **2,584,464** |
| Preferences | 1,456,844 | 24,116 | **1,480,960** |

The 30 text files contain 5,875 ordinary and **395 positive Wednesday units**.
The remaining final unit is **`E-0483-02`, Katrineholm's second municipal
constituency**. Its preserved final XML reports zero valid votes and zero in every
party/blank/other-invalid category. It is a **verified zero unit**, not missing
substantive results. Retain it in a complete geographic frame.

All 5,875 ordinary codes occur in SND exactly once and reconcile with the
Valmyndigheten text rows. The 396 reporting branches consist of 185 actual
municipal constituencies in 79 divided municipalities and 211 technical `00`
branches in undivided municipalities. Wednesday suffix `E01`, for example,
identifies the corresponding constituency branch. District identifiers must
include the municipality; list and candidate identifiers require party/list scope.

Ordinary-district electorate sums to **6,827,870**. The list files put structural
`0` in the electorate field for Wednesday units. Do not present this as a genuine
zero electorate or calculate Wednesday turnout; the Wednesday count has no
separate electorate denominator.

Geography discrepancies are labels/coding, not missing votes: Valmyndigheten
uses `Vaggeryds` / `Malungs`, SCB uses `Vaggeryd` / `Malung`. The current SSD uses
**0331 for Heby**, whereas the 2004 sources use **1917**. Diagnostic comparisons
used an explicit 0331-to-1917 historical crosswalk; they did not drop unmatched rows.
Do not silently change the historical source geography in an eventual adapter.

## 3. Parties, small parties and handwritten designations

Nine parties are separate top-level `GILTIGA` in Valmyndigheten XML: M, C, FP,
KD, S, V, MP, JL and SD. XML `ÖVR` has **26,274** votes. The detailed source
separately identifies **18 further parties with 25,331 votes** and leaves **943**
in an unnamed other-party category (`E_listrost_9997`, list marker `99997`).
Thus there are **27 separately identified parties plus the residual category**.
Their district/Wednesday sums preserve all geographic totals without double counting.

Do not keep the parent 26,274 `ÖVR` row and add its named subparties again.
SCB's main result workbooks instead group **SD + Valmyndigheten ÖVR = 54,577**
as other parties; this is an explained category definition, not a vote discrepancy.

The remaining 943 are explicitly aggregated. The targeted implementation check
established from the official final presentation that these are handwritten
votes for parties which did not order ballots. Individual written designations
are not disclosed in the checked sources. Preserve the aggregate; do not invent
parties or distribute it using the SCB threshold table. Individual party identity
for these 943 votes is **INCOMPLETE due to aggregate publication**.
The residual list file explicitly reports zero preferences.

## 4. Candidacies, names, identifiers and preferences

The preferred ballot source is the preserved definitive XML ZIP, corroborated by
the later 30-panel ballot presentation. The April 23-panel presentation is an
older snapshot and must not replace it. All 30 ballots are `Definitiv`.

Fields include party code/name, list number, candidate registration flag,
`ORDNINGSNUMMER`, candidate description/name, sex and age. There is **no stable
source person/candidate ID**. In district preference text, `kandidatnummer på
listan` means position on that list. In result XML, `ORDNING` is preference rank;
`VALSEDEL/PERSONVAL/@KANDIDAT` is the ballot-position link. Do not conflate them.

- 382 documented party/list/position candidacies; no duplicate source keys.
- 360 have positive preferences; **22 have no positive preference record**.
- All 282,901 positive unit records have a valid party/list/position key in the
  ballot XML. Zero orphan records and zero duplicate unit/party/list/position keys.
- The 20 preference files cover all parties with positive source list-preference
  totals. The seven remaining registered parties have zero list-preference totals.
- **85,349/85,349** list/category controls reconcile. All ordinary districts and
  all 395 nonzero Wednesday units have positive preference observations; the
  additional zero Wednesday unit is identified above.
- Source totals are **1,453,261 for the eight mandate parties + 14,450 SD +
  13,249 other identified small parties = 1,480,960**. No aggregate-only
  preference remainder like the EU 2009 issue was found.

All 20 original named exports are preserved. Earlier incomplete FP responses are
excluded; the complete November FP capture matches current data outside names.
Named source availability does not itself decide the future public name policy.

SCB reports **372 nominated persons** (215 men, 157 women), 19 elected (8 men,
11 women). The register has 382 list positions. Its own party summaries total
**376**: the FRP party has nine list positions on four ballots but an explicit
summary of **three** nominees. A further five ballots for five parties carry the
same full `Bosse Persson, Processpedagog - Sveriges Jultomte` description, sex
and age 62. Counting that repeated nomination once yields **382 - 6 - 4 = 372**,
consistent with SCB's person-level population. This is population-reconciliation
evidence, **not a person-ID crosswalk**. No source records were merged, and no
physical-person identifier is proposed. Retain all 382 candidacies.

## 5. Mandates, elected candidates and substitutes

Original national XML allocates M 4, C 1, FP 2, KD 1, S 5, V 2, MP 1, JL 3;
SD and other parties zero. SCB's seat table agrees exactly. All **19** positions
have elected records: **zero unfilled**. Eight original `GRUPP_VALDA` structures
contain 27 substitute posts and yield 71 elected-substitute relation expansions.
Keep the group/order relation; 71 expanded rows are not 71 distinct substitutes.

The [archived 7 January 2007 current-members page](https://web.archive.org/web/20070107004305id_/http://www.val.se:80/val/ep2004/valdaled/index.html)
exists and records, for example, Jens Holm's accession on 26 September 2006 and
Olle Schmidt's on 19 October 2006. It is a later membership snapshot, **not the
fixed election result or a complete event history**. Its generic text also refers
to the September 2006 election; do not use that boilerplate as EU-election metadata.
No broad mandate-period recovery was undertaken.

## 6. Electorate

Fresh SCB workbooks and SSD provide complete components at **national, county
and municipality** level (312 workbook records; 291 national/municipal SSD regions):

| Group | National eligible voters |
| --- | ---: |
| Swedish citizens resident in Sweden | 6,670,406 |
| Swedish citizens abroad | 109,688 |
| Other EU citizens eligible in Sweden | 47,776 |
| **Total** | **6,827,870** |

Components and male/female totals reconcile exactly for all 312 workbook areas
and all 2,328 selected SSD group/sex cells. SND additionally reports foreign-EU
eligible voters for **all 5,875 ordinary districts**, summing to 47,776.
Separate Swedish-resident/abroad district components were **not recovered**;
full three-way composition is therefore **INCOMPLETE at ordinary-district level**.
No downward allocation is justified. Wednesday electorate/turnout are unavailable
as separate measures and must remain missing rather than fabricated.

## 7. SCB reconciliation and source discrepancies

All controls were independent R extractions, not production normalisers.
Evidence tables/logs are in the local inventory directory.

| Control | Result |
| --- | --- |
| Core workbook/SND controls (electorate, vote accounting, parties, invalid/blank, turnout, preference sex etc.) | **27,396 passed, zero failures** in `independent-controls.csv`. Separate earlier SND valid/eight-party district checks also passed. |
| SCB disclosed small-party counts | **347/347** match official detailed list results, including repeated printed-page headings handled explicitly. |
| SSD ordinary results | All **3,201 numeric count cells** match after grouping SD with other and applying historical Heby coding. Another 873 cells (`PP`, `FI`, `SD`) are explicitly `..`, not missing source votes. |
| SSD electorate | **2,328/2,328** match the historical composition workbook. |
| SCB county mandate-party preferences | **176/176** national/county/party counts match; 44 female/male aggregate controls match. |
| SCB mandates | Exact match: 19, with the original party allocation. |
| SCB nominee population | 372 persons versus 382 candidacy slots; repeated within/across-party candidacies explain the count distinction above. |

### A. Non-additive SD coding in the current SSD preference table

`ME0109T08`, year 2004, reports SD as **0**, including nationally, while the
Valmyndigheten detailed source reports **14,450**. The SSD national `TOTALT`
nonetheless correctly reports **1,480,960**, and `ÖVRIGA` reports **13,249**;
those displayed party components are therefore short of `TOTALT` by 14,450.
All other comparable party/total cells match. **270 cells** differ: national SD
and SD in **269 municipalities** with positive source preferences. The national
and municipal differences must not be added as distinct missing votes.

This is a **located SCB historical category/coding inconsistency**, not a
Valmyndigheten aggregation discrepancy or package implementation error. Its
administrative cause is not established. Preserve the SD source records; do not
replace them with the SSD zero or move them into another party. Detailed evidence:
`scb-api-preference-differences.csv`. The eight-party printed tables expressly
cover mandate parties and correctly omit SD from that population.

### B. SCB electorate HTML transcription/arithmetic inconsistency

The [SCB county HTML table](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2004/valet-till-europaparlamentet-2004-lansvis2.-rostberattigade)
prints resident Swedish citizens as **6,670,405** nationally and **211,879** in
Dalarna. Its own sex components sum to **6,670,406** and **211,880**.
The official Excel/SSD give those latter values and reconcile with total
electorate. Preserve the HTML difference in provenance; use the internally
consistent Excel/SSD controls, not a silent edit to the HTML source.

### C. Explained source-structure differences

- SD is separate in Valmyndigheten but grouped with other in SCB ordinary result tables.
- Turnout is 37.85% in Valmyndigheten and 37.9% in one-decimal SCB tables: rounding.
- SND postal votes are pooled in municipal summaries; Valmyndigheten separately
  identifies the 396 final Wednesday units.
- `E-0483-02` is an explicitly zero final unit absent from positive-only raw rows.
- Historical geography names and Heby coding differ as documented above.
- Current versus original national XML: names differ; element layout and all
  non-name attributes are identical. No numerical result revision was found there.

## 8. Election night and full preliminary results

The [original election-night XML, capture 21 August 2004 00:46:23 UTC](https://web.archive.org/web/20040821004623id_/http://www.val.se:80/val/ep2004/resultat/valnatt/valnatt_00E.xml)
reports `VALNATTSRAPPORTERING`, timestamp **13 June 2004 23:22:01**, and
**5,875/5,875** counted ordinary districts; valid votes **2,457,304**.
It preserves national, 21 county, 29 reporting-constituency and 290 municipal
aggregate rows. It contains no Wednesday results or candidate preferences.

The archived result index (actual capture **27 June 2006 12:24:49 UTC**, despite
an earlier requested replay date) links final and election-night results only.
This is not evidence that a complete preliminary collection count was never
produced. **No complete preliminary Wednesday snapshot has been recovered.**
Its historical unit population and values are **NOT VERIFIED**. Final collection
figures must not fill this gap, and election-night must not be relabelled full
`preliminary`. Individual election-night district coverage is also **NOT VERIFIED**:
linked/archived municipal presentations exist, but a complete district census
was not retrieved or audited in this final-result-focused inventory.

## 9. Completeness matrix

`COMPLETE` refers to the specified source population, not an assertion that
unpublished categories or physical-person linkage have been recovered.

| Dimension | Status | Exact scope / missing information |
| --- | --- | --- |
| Final party/category votes, national/county/reporting constituency/municipality | **COMPLETE** | All 1/21/29/290 units; 27 identified parties + reported residual. |
| Final ordinary-district party/category votes | **COMPLETE** | All 5,875 units, independently reconciled with SND. |
| Final Wednesday-unit votes | **COMPLETE** | 395 positive units + verified all-zero `E-0483-02`; 396 total. |
| Municipal constituency geography/results | **COMPLETE** | 185 real constituencies; 211 technical `00` branches kept distinct. |
| Valid/blank/other-invalid/cast | **COMPLETE** | All final levels, including zero collection unit; additive source controls. |
| Eligible voters/turnout | **COMPLETE** | National/counties/reporting constituencies/municipalities and 5,875 ordinary districts; no separate Wednesday denominator. |
| Exact designation of residual other-party votes | **INCOMPLETE** | 943 votes are aggregate-only; no individual party designation/handwritten breakdown recovered. All remain counted. |
| Documented ballot candidacies/list positions | **COMPLETE** | 382 observations on 30 definitive ballots for 27 parties; no orphan positive result positions. |
| Reported preference observations | **COMPLETE** | 282,901 positive rows; 360 positive candidacies; all 1,480,960 votes; 22 ballot positions without positives. |
| Preference geography including Wednesday | **COMPLETE** | 5,875 ordinary + 395 positive Wednesday units; additional verified-zero Wednesday unit. No 2009-like fine-geography remainder found. |
| Person identity across lists/elections | **INCOMPLETE** | No stable source person ID on any of the 382 candidacy rows. Do not deduplicate/merge from names. This does not make result observations incomplete. |
| Original allocated/elected/unfilled seats | **COMPLETE** | 19 / 19 / 0, with original party allocation. |
| Original substitute relationships | **COMPLETE** | Eight groups, 27 substitute posts, 71 expanded relations. |
| Electorate three-way composition, nation/counties/municipalities | **COMPLETE** | All 312 workbook areas; sex and category controls reconcile. |
| District foreign-EU electorate | **COMPLETE** | All 5,875 ordinary districts; total 47,776. |
| District full three-way electorate composition | **INCOMPLETE** | Swedish-resident/abroad components not recovered for the 5,875 ordinary districts; do not allocate downward. |
| Full preliminary including collection count | **NOT VERIFIED** | Preliminary collection snapshot and its expected unit population not established; no final substitution. |
| Election-night higher aggregates | **COMPLETE** | Preserved 1/21/29/290 aggregate rows; 5,875/5,875 district count reported. |
| Election-night individual districts | **NOT VERIFIED** | Full district payload census not retrieved/audited; not needed to implement final results. |
| Mandate-period history | **NOT VERIFIED** | One later membership snapshot exists; no complete event ledger assessed. |

## 10. Implementation recommendation

Proceed with **final EU 2004** using the original named national XML, local
hash-verified district list files, all 20 complete named preference exports and
the definitive ballot XML. Use the Katrineholm XML to preserve the zero unit.
SCB/SND remain independent controls; supplementation is justified for electorate
composition/foreign-EU district counts, with explicit provenance.

| Public function | Supported source scope |
| --- | --- |
| `results()` | Final, national/county/municipality/reporting and municipal constituencies/ordinary + Wednesday districts; preserve residual 943. |
| `seats()` | Original national party allocation, filled and unfilled explicitly distinguished. |
| `candidacies()` | 382 source party/list/position observations and supported ballot attributes. |
| `candidates()` | Source/candidacy observations with clearly documented key semantics, not 382 asserted unique persons. |
| `elected()` | Original 19 election-result observations; do not replace with the 2007 membership snapshot. |
| `substitutes()` | Original groups/order/relations; avoid mistaking expanded relations for distinct persons. |
| `preference_votes()` | All reported positive source observations, with explicit list-position keys; verified-zero completion only from the fully reconciled source population. |

Reuse the EU XML/result infrastructure where semantics match, but adapt the
**version-1.2** result XML, element-based ballot candidate fields and the distinct
text formats explicitly. Candidate rank and ballot position are separate.
Existing historical candidacy-level key conventions can be reused without
inventing person IDs. Unsupported attributes remain typed missing.

Before an implementation is accepted, repeat the preserved independent checks,
validate lower/higher geography aggregation and source-specific denominators,
the 382/372 population distinction, original elected/substitute relations,
English/Swedish and standard/full projection, schema/Parquet round-trip and
raw-source integrity. No package tests or canonical build were run for this
inventory-only task.

**No further broad source recovery is necessary to start final-result
implementation.** The source-coded SD zeros and the HTML electorate errors
should be documented, not propagated into the authoritative result. Full
preliminary support and physical-person linkage remain separate decisions.

## Appendix: every original local file

The following inventory covers the 41 files that existed before this review.
Complete MD5/SHA256 and filesystem times are in the preserved `original-files.csv`.

| Relative local path | Bytes | Format / inspected records |
| --- | ---: | --- |
| `röstning/oppet2004.xls` | 246272 | XLS; 1,393 x 9 main sheet; one empty sheet |
| `röstning/post2004.xls` | 410624 | XLS; 1,254 x 24 main sheet; two empty sheets |
| `scb/eu_ovr_partiut_100917.xls` | 69120 | XLS; 443 x 6 incl. headings |
| `scb/tab-02b_eu_kommun_tab_talut.xls` | 143872 | XLS; 433 x 29 incl. headings |
| `scb/tab-04-eu_kommun_tab_procut.xls` | 154624 | XLS; 432 x 31 incl. headings |
| `scb/tab-10-eu_persrost_parti_procut.xls` | 20992 | XLS; 34 x 18 incl. headings |
| `scb/tab-11_eu_persrost_parti_mandut.xls` | 20480 | XLS; 34 x 18 incl. headings |
| `snd/snd0241-3-2.zip` | 2317678 | SND ZIP; six members, five data objects + hashes |
| `valres/E_listrost_0001.txt` | 644818 | Semicolon text; 7755 x 13 list/category rows |
| `valres/E_listrost_0002.txt` | 732942 | Semicolon text; 8806 x 13 list/category rows |
| `valres/E_listrost_0003.txt` | 591935 | Semicolon text; 7067 x 13 list/category rows |
| `valres/E_listrost_0004.txt` | 547596 | Semicolon text; 6653 x 13 list/category rows |
| `valres/E_listrost_0005.txt` | 593422 | Semicolon text; 7150 x 13 list/category rows |
| `valres/E_listrost_0029.txt` | 10289 | Semicolon text; 116 x 13 list/category rows |
| `valres/E_listrost_0055.txt` | 586195 | Semicolon text; 7009 x 13 list/category rows |
| `valres/E_listrost_0068.txt` | 552890 | Semicolon text; 6612 x 13 list/category rows |
| `valres/E_listrost_0110.txt` | 503038 | Semicolon text; 6053 x 13 list/category rows |
| `valres/E_listrost_0199.txt` | 169 | Semicolon text; 2 x 13 list/category rows |
| `valres/E_listrost_0243.txt` | 240584 | Semicolon text; 2876 x 13 list/category rows |
| `valres/E_listrost_0339.txt` | 4468 | Semicolon text; 57 x 13 list/category rows |
| `valres/E_listrost_0451.txt` | 920121 | Semicolon text; 11048 x 13 list/category rows |
| `valres/E_listrost_0452.txt` | 1784 | Semicolon text; 20 x 13 list/category rows |
| `valres/E_listrost_0453.txt` | 2602 | Semicolon text; 30 x 13 list/category rows |
| `valres/E_listrost_0454.txt` | 83 | Semicolon text; 1 x 13 list/category rows |
| `valres/E_listrost_0455.txt` | 592 | Semicolon text; 8 x 13 list/category rows |
| `valres/E_listrost_0456.txt` | 378 | Semicolon text; 5 x 13 list/category rows |
| `valres/E_listrost_0457.txt` | 145 | Semicolon text; 2 x 13 list/category rows |
| `valres/E_listrost_0458.txt` | 229 | Semicolon text; 3 x 13 list/category rows |
| `valres/E_listrost_0459.txt` | 856 | Semicolon text; 11 x 13 list/category rows |
| `valres/E_listrost_0460.txt` | 92501 | Semicolon text; 1044 x 13 list/category rows |
| `valres/E_listrost_0461.txt` | 2735 | Semicolon text; 29 x 13 list/category rows |
| `valres/E_listrost_0462.txt` | 958 | Semicolon text; 12 x 13 list/category rows |
| `valres/E_listrost_0463.txt` | 299611 | Semicolon text; 3515 x 13 list/category rows |
| `valres/E_listrost_0464.txt` | 12194 | Semicolon text; 135 x 13 list/category rows |
| `valres/E_listrost_0466.txt` | 690 | Semicolon text; 8 x 13 list/category rows |
| `valres/E_listrost_9997.txt` | 54768 | Semicolon text; 660 x 13 list/category rows |
| `valres/E_listrost_9998.txt` | 526596 | Semicolon text; 6137 x 13 list/category rows |
| `valres/E_listrost_9999.txt` | 210846 | Semicolon text; 2525 x 13 list/category rows |
| `valres/oppet2004.xls` | 246272 | XLS; 1,393 x 9 main sheet; one empty sheet |
| `valres/post2004.xls` | 410624 | XLS; 1,254 x 24 main sheet; two empty sheets |
| `valres/slutresultat_00E.xml` | 1147720 | Result XML; 341 geographic aggregate nodes |

## Appendix: complete party/category controls

Votes and preferences are direct sums of the official list files. The table
keeps identified parties separate from the unidentified residual; it is not
a reconstructed allocation of residual votes.

| Party code | Source designation | Votes | Preferences |
| --- | --- | ---: | ---: |
| `0001` | Moderata Samlingspartiet | 458398 | 273132 |
| `0002` | Arbetarepartiet-Socialdemokraterna | 616963 | 350721 |
| `0003` | Folkpartiet liberalerna | 247750 | 140876 |
| `0004` | Centerpartiet | 157258 | 102751 |
| `0005` | Vänsterpartiet | 321344 | 213127 |
| `0029` | Europeiska Arbetarpartiet-EAP | 137 | 57 |
| `0055` | Miljöpartiet de gröna | 149603 | 83785 |
| `0068` | Kristdemokraterna | 142704 | 101587 |
| `0110` | Sverigedemokraterna | 28303 | 14450 |
| `0199` | Kommunistiska förbundet | 2 | 0 |
| `0243` | Nationaldemokraterna | 7209 | 3698 |
| `0339` | Sveriges Nationella Demokratiska Parti | 66 | 0 |
| `0451` | Junilistan | 363472 | 187282 |
| `0452` | Högerpartiet de konservativa | 29 | 4 |
| `0453` | Insynspartiet | 37 | 25 |
| `0454` | Republicans right | 1 | 0 |
| `0455` | VIKINGAPARTIET - SVERIGE UT UR EU | 9 | 0 |
| `0456` | MOTBOKSPARTIET - SVERIGE UT UR EU | 8 | 0 |
| `0457` | EU-Kritiska Partiet: Ryssland Ja - Turkiet Nej | 2 | 0 |
| `0458` | EU UT UR SVERIGE-PARTIET - NEJ TILL NATO - ALLIANSFRIHET: JA | 4 | 0 |
| `0459` | EU-KRITISKA TOMTEPARTIET - BARNENS OCH DJURENS BÄSTA VÄN | 19 | 1 |
| `0460` | Rättvisepartiet Socialisterna - EU-motståndare mot nedskärningar | 2087 | 1094 |
| `0461` | Unionens medborgares kamp för en EU:s Super-State | 36 | 21 |
| `0462` | VISION EUROPA PARTIET | 25 | 11 |
| `0463` | EU-motståndarna | 15505 | 8277 |
| `0464` | Sverige ut ur EU (UT) / Frihetliga rättvisepartiet (FRP) | 147 | 57 |
| `0466` | IIP: Internationella IntegrationsPartiet | 8 | 4 |
| `9997` | Unidentified other-party category | 943 | 0 |
| `9998` | Blank invalid | 68129 | 0 |
| `9999` | Other invalid | 4266 | 0 |

Additional percentage controls: **2,808 result-share cells and 176 mandate-party
preference-share cells passed**, allowing only the published one-decimal rounding.
The SND SAV and DTA result tables have identical values in all 21 columns.

## Implementation checks: residual votes and SCB preference cells

The official final-result presentation explicitly defines the nested residual
“Övriga partier” as handwritten votes for parties that did not order ballots:
<https://historik.val.se/val/ep2004/resultat/slutresultat/index.html>.
The 943 votes are therefore a reported aggregate of valid handwritten votes,
not 943 votes assignable to any identified party. The original XML places them
inside the larger 26,274-vote other-party group alongside 18 named parties
(25,331 votes). The district export `E_listrost_9997.txt` preserves the residual
separately. Its synthetic list marker 99997 is not a candidate-bearing ballot.
No checked source discloses the individual designations behind these 943 votes.
The public result retains the label “Övriga partier” and `other_parties = TRUE`;
it does not create candidate/preference observations for this aggregate.

The archived legally established decision is dated 17 June 2004, Dnr 04-139/4.
Its main protocol and all six appendices have now been preserved locally, with
URLs, capture times, retrieval timestamps, sizes and checksums in the acquisition
ledger. Original source directory:
`http://www.val.se/val/ep2004/resultat/protokoll/`.
Appendix 1 explicitly reports SD 28,303 party votes and **14,450 preference
votes**, all-party preference total **1,480,960**, valid votes **2,512,069**,
invalid votes **72,395**, blank invalid votes **68,129**, ballots **2,584,464**,
and eligible voters **6,827,870**. These agree with the original final XML and
independently summed district exports.

SCB SSD table ME0109T08 instead returns zero for SD nationally and in 269
municipalities where the official source has positive values: 270 incorrect
cells. The other 3,513 comparable preference cells agree. SCB's all-party total
remains 1,480,960; its other-party preference count 13,249 does not include SD.
The zero cells are inconsistent with the legally established protocol and with
SCB's own total. Their administrative cause is not established. The build uses
the protocol-supported Valmyndigheten values, without changing source files or
redistributing votes. There is no detected inconsistency in the corresponding
Valmyndigheten preference data.

See [SOURCE_POLICY.md](SOURCE_POLICY.md) for the general reconciliation rule.
