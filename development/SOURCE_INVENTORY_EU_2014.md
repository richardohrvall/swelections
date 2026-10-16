# Source inventory: European Parliament election 2014

Assessment date: 2026-10-15. Election occasion: **25 May 2014**.
Source inventory and independent R checks only: no production reader, public API,
canonical build, commit or push. Original files remain unchanged. Acquired raw
sources and audit evidence remain local/ignored.

## Decision summary

The preserved sources establish **COMPLETE final vote-category totals and
geography**, **COMPLETE reported candidate preference observations**,
**COMPLETE documented ballot candidacies**, and **COMPLETE original mandates,
elected and substitute relations**.

Two exact gaps must be kept separate:

1. XML reports **5,618 handwritten party votes** outside its named-party detail;
   the official handwritten file identifies **5,608**. The missing **10 labels**
   concern **05803201, Vårdsberg (Linghem S), Linköping**. All ten votes are in the
   correct final totals. Do not invent party or candidate allocations.
2. `valnatt.zip` contains **5,837 ordinary districts and no Wednesday units**.
   The linked full preliminary presentation and tested preliminary XML/ZIP URLs
   return 404. A complete preliminary collection snapshot has not been recovered.
   Do not insert final Wednesday results or relabel election night as full preliminary.

All **376 candidate-file IDs** occur in the national final preference records;
no result/elected/substitute ID is absent from the candidate file. SCB
independently reports **376 nominated and 20 elected persons**.

## 1. Sources and provenance

Valmyndigheten is authoritative for the fixed election result. SCB supplies
independent published controls and electorate composition. Unattributed local
transformed CSVs are not official primary sources. SND surveys are not
administrative result returns.

Official entry points:

- [Statistics/raw-data index](https://historik.val.se/val/ep2014/statistik/index.html).
- [Final results](https://historik.val.se/val/ep2014/slutresultat/E/rike/index.html),
  [preference votes](https://historik.val.se/val/ep2014/slutresultat/E/rike/personroster.html),
  [original elected/substitutes](https://historik.val.se/val/ep2014/slutresultat/E/rike/valda.html).
- [Final XML ZIP](https://historik.val.se/val/ep2014/slutresultat/slutresultat.zip).
- [Election night](https://historik.val.se/val/ep2014/valnatt/E/rike/index.html)
  and [XML ZIP](https://historik.val.se/val/ep2014/valnatt/valnatt.zip).
- [Candidate SKV](https://historik.val.se/val/ep2014/alkon/alkandur_E.skv),
  [handwritten detail](https://historik.val.se/val/ep2014/handskrivna/handskrivna.skv),
  [electorate](https://historik.val.se/val/ep2014/alkon/E/rostberattigade.skv).
- [SCB results](https://www.scb.se/ME0109) and
  [nominees/elected](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/).

### Complete pre-existing local inventory

All twelve files are under `.local-data/eu/2014/valresultat/`. No additional
EU2014 candidate/SND administrative archive was found in the local EU collection.
Other election years are separate sources, not evidence of 2014 coverage.
Original retrieval times are unknown; filesystem modification times in the
ledger are not claimed as retrieval dates.

| File | Structure, coverage and purpose |
| --- | --- |
| `slutresultat.zip` | 294 members: national + 290 municipal XMLs, `Filer`, `Cksum`, `Signatur`; 127,528,238 XML bytes. Complete final votes/lists/preferences/mandates/original relations. |
| `valnatt.zip` | Same 294-member organisation, 12,370,177 XML bytes; 5,837 ordinary districts, no Wednesday count. |
| `alkandur_E.skv` | **Headerless** Windows-1252 semicolon text: **376 rows x 12 fields**, 376 IDs, 21 lists/parties. Named ballot-candidate snapshot. Treating row one as a header would lose one candidate. |
| `ep2014_valresultat_per_kommun.skv` | 290 x 34: ten main parties, aggregate other, blank/other invalid, valid/cast/eligible/turnout, counts/shares. Official final control. |
| `ep2014_valresultat_per_valdistrikt.skv` | 6,227 x 38: same categories plus municipal/constituency/district geography, including Wednesday units. Official final control. |
| `handskrivna.skv` | 4,494 x 11; **890 exact labels**, 5,608 votes, 282 municipalities. Labels are not 890 verified party identities. |
| `rostberattigade.skv` | 5,837 x 28: eight geography fields plus twenty age/sex/Swedish-versus-other-citizenship counts. All district totals match XML. |
| `partier_som_anmalt_kandidater.xls` | One sheet, 18 populated rows x 3 including headings/notes; dated 3 April. Numeric party codes, abbreviations/names for notified parties; not the entire result-party population. |
| `2014_eu-medborgare_per_lan.xls` | Three sheets, two empty; main sheet 31 x 3, EU citizens registered/not registered on 15 April. Not final election-day electorate. |
| `utlandssvenskar_per_land_2014.xls` | One sheet, 187 populated rows x 2 including headings/notes; official residence-country table dated 1 April. Different reference date from final eligible voters; provenance/context, not a final denominator. |
| `valres_dist.csv` | Comma-delimited transformed table, 6,227 x 36; `eu2014_*` counts/shares and geography. Transformation/producer not established. Research/control copy, not independent official evidence. |
| `valres_dist2.csv` | Same 6,227 x 36 parsed cells as preceding CSV, different bytes/size. Not another result snapshot or independent control. |

Appendices list sizes, MD5, SHA256 and acquired-source provenance. Full local
evidence: `.local-data/eu/2014/review-20261015/`, including R scripts,
`original-files.csv`, `retrieval.csv`, ZIP inventories, census and check logs.
No raw source was added to Git.

### Current versus original snapshots

- Candidate SKV: 376 rows in both; all IDs/lists/positions/status/party/age/sex/
  ballot information identical. Only national area padding (`00` to `0`) and
  all 376 names (`Namn gallrat` currently) differ. No missing candidacy.
- Current final ZIP: **291 XML members under `slutresultat/`**, versus original
  291 XMLs plus three provenance members at root. Exhaustive attribute comparison:
  **870,420 `NAMN` changes and 291 root `FILNAMN` changes**, no other changed
  attributes or node structures. Candidate names are `Namnet gallrat`. The redaction also affects **all 7,248
  geographic `NAMN` attributes** (including repeated municipal summaries), not
  just candidate names. Original geographic names remain available in the
  preserved original and the official wide-result/geography sources.
  Root `FILNAMN` was also redacted to this string: use actual ZIP member names,
  not this metadata, to identify municipality files. Votes/IDs/relations unchanged.
- Election-night ZIP: only root `TID_RAPPORT` changes in 291 XMLs and national
  `TID_MANDAT` changes. No altered votes, mandate counts or geographic coverage.
  Current national generation time `20140602100100` does not mean Wednesday
  results were added.
- Current electorate, handwritten and both official wide-result SKVs are
  **byte-identical** to the preserved originals.

Original final root: generated `20140530162813`, `VALDAG=20140525`, previous
`VALDAG_FGVAL=20090607`. Preserve named originals privately and current redacted
sources separately. Future output should follow a consistent public redaction
contract; local names must not silently change the public name contract.

Both original `Filer` members list 291 XMLs; the total XML length equals the
length in each `Cksum`. This is not verification of the POSIX checksum algorithm
or binary signature. Whole-file SHA256 has been verified separately.

## 2. Final results and geography

| Measure | Final value |
| --- | ---: |
| Valid votes | 3,716,778 |
| Invalid blank (`BLANK`) | 38,935 |
| Other invalid (`OG`) | 3,238 |
| All invalid | 42,173 |
| Ballots cast | 3,758,951 |
| Eligible voters | 7,359,962 |
| Turnout | 3,758,951 / 7,359,962; displayed 51.07% |
| Reported candidate preference votes | 1,859,375 |

Blank is **invalid**, unlike the 2003 referendum. There is no separate modern
`OGEJ` invalid category. Do not fabricate an extra zero category.

| Source geographic role | Verified units | Meaning |
| --- | ---: | --- |
| National | 1 | Sweden `00`, actual EU election/mandate constituency. |
| County | 21 | `LÄN`, not RF elections. |
| Parliamentary reporting group | 29 | `KRETS_RIKSDAG`, not separate EU mandate constituencies. |
| Municipality | 290 | Every municipal XML exists. |
| Municipal-constituency container | 390 | **181 real constituencies in 81 divided municipalities**, plus **209 technical `00` containers** for undivided municipalities. |
| Ordinary district | 5,837 | Eight-digit codes; electorate/turnout supplied. |
| Wednesday/collection | 390 | One per container, e.g. `E-0114-01`; no separate electorate/turnout. |
| Non-overlapping final district population | **6,227** | 5,837 ordinary + 390 Wednesday. |

Keys are unique within stage/role. The final source census has **6,958** records
across all roles; adding roles together would double count votes.
Ordinary districts: 3,558,828 valid, 3,599,029 cast. Wednesday: 157,950 valid,
1,648 blank and 324 other invalid; thus **159,922 cast** are directly derivable.
Their electorate/turnout remain missing.

All 290 ordinary-plus-Wednesday municipality sums match valid/blank/other-invalid/
cast. County, parliamentary-reporting, constituency-container and municipal sums
each reproduce the national totals. Named-party counts plus handwritten residual
equal valid votes in every one of the 6,958 final geographic records.
Official wide files agree with XML at **all 6,227 district and 290 municipal
units** for ten-party counts and vote categories. All 5,837 electorate rows match.

Implementation-sensitive geography formats:

- Preserve code width: ordinary `0004` and collection `04` have different roles.
  Do not classify by a numeric threshold.
- Collection number in the result SKV comes from `VALDIST`, not inferred `KVK`.
- Municipality numeric components need padding; electorate SKV already has full
  municipality/eight-digit district IDs.
- Technical `00` containers must not become invented public constituencies.

## 3. Smaller parties and handwritten labels

XML contains **22 named categories**, **21 positive** and zero-vote `scl`.
Ten headline parties are direct children; further named parties occur under
`ÖVRIGA_GILTIGA`. Ignoring nested `GILTIGA` would discard real party detail.

| XML key | Positive party outside the headline ten | Votes |
| --- | --- | ---: |
| JL | Junilistan | 11,629 |
| 1136 | Djurens parti | 8,773 |
| KLP | Klassiskt liberala partiet | 492 |
| EAP | Europeiska Arbetarpartiet-EAP | 170 |
| SMD | Sverigesmultidemokrater | 133 |
| 1189 | Sverige ut ur EU/ Frihetliga Rättvisepartiet (FRP) | 106 |
| 1197 | Socialistiska Välfärdspartiet | 86 |
| 1169 | Äkta Demokrati | 72 |
| 0339 | Sveriges Nationella Demokratiska Parti | 49 |
| 0889 | 666 för en EU:s Super-state med frihet, jämlikhet, rättvisa, fred, kärlek och lyckan | 11 |
| rer | Republicans right | 9 |

Named-party votes total **3,711,160**, with **5,618** XML handwritten residual.
Headline other **27,148 = 21,530** for these eleven smaller parties **+ 5,618**.
Never add the aggregate and its children as additional votes.

The handwritten file contains **4,494 rows / 890 exact spellings / 5,608 votes**.
Spellings include case variants, write-in expressions and labels resembling
registered parties. No automatic merging or invented numeric party codes is
justified. Repeated source keys must be summed, not dropped. These are party
votes, not candidate preference votes.

Role-aware reconciliation:

- ordinary: 4,173 rows, 5,237 votes, 2,955 represented units;
- collection: 321 rows, 371 votes, 182 represented units;
- detailed sums match every XML unit except **05803201**, whose ten residual
  votes have no detail rows;
- municipal sums match everywhere except **0580 Linköping**, XML 94/detail 84.

The [official Vårdsberg page](https://historik.val.se/val/ep2014/slutresultat/E/valdistrikt/05/80/3201/index.html)
independently reports ten votes on parties without ordered ballots, within 13
other-party votes and 778 valid votes; its label table does not identify them.
Total party/category votes are COMPLETE; finer attribution is INCOMPLETE for
these exact ten votes. The 890 spellings are reported labels, not 890 verified
political parties. The source index allowed supplementary handwritten reporting
until 25 July. Current/local files are identical, so our snapshot difference
does not explain the ten-vote omission.

## 4. Candidates, candidacies and reported preferences

Headerless candidate fields, in order: election, area, area name, party name,
ballot status, list number, ballot position, candidate number, name, age, sex,
ballot information. These are audit descriptions, not proposed public columns.
All 376 statuses are `Skickad`. This does not supply an independent validity flag.
Separate `GILTIG`, consent, declaration, election-day eligibility, ordered-ballot
count and registered municipality are absent. Do not invent those attributes.

There are **376 ballot candidacies / 376 IDs / 21 lists / 21 parties**, all with
national geography. Result strings such as `0001-05512` encode party/list; join
the normalized list part to candidate-file `5512`. Preserve the original value.
Party codes are available from these list prefixes; names are unnecessary for joins.

Party `PERSONVAL` and list `PERSONVAL` duplicate the same votes. Use one scope.

| Scope | Positive records | Votes | IDs |
| --- | ---: | ---: | ---: |
| National list | 376 | 1,859,375 | 376 |
| County party | 6,653 | 1,859,375 | 376 |
| Ordinary district list | 381,677 | 1,782,079 | 376 |
| Wednesday list | 20,376 | 77,296 | 355 |
| All non-overlapping district list | **402,053** | **1,859,375** | **376** |

All **6,227** units have reported preferences. Every positive list record joins
candidate number + normalized list, with zero missing joins/position mismatches.
Every national candidate total equals its ordinary-plus-Wednesday sum. All
**69,419 nonmissing list preference-total controls** pass; no duplicated
district/party/list/candidate key.

Keep source roles distinct:

- `KANDNR`: candidate number;
- `KANDIDAT`: ballot position in list-level preference records;
- `ORDNING`: preference rank, possibly tied, not ballot position;
- `PERSONKRYSS`: preference count;
- `ÖVER_SPÄRR`: national threshold status, not elected status and not a local
  qualification flag to propagate to finer levels.

National XML has **42 ballot nodes: 21 named ballots and 21 `90000` party-only
ballots**. Party-only ballots have no identified candidate preferences and
missing list preference totals; do not allocate party votes to candidates.
Every documented candidate has positive national preferences. No result-only ID,
no candidate-file ID absent from national preferences, and no elected/substitute
ID missing from the candidate file was found. All national list names equal the
local candidate names, without using names as join keys.

**Documented ballot population: COMPLETE. Reported preference observations:
COMPLETE.** This is not a claim that modern consent-only/validity attributes are
available in a historical twelve-field file. A separate unprinted-consent
register is not provided by this source. SCB's 376 nominees independently agree.
Source IDs support joins within these 2014 files. Physical-person identity
across lists/elections remains **NOT VERIFIED**; no harmonisation is proposed.

## 5. Mandates, elected and substitutes

Original final result: **20 allocated / 20 elected / zero unfilled**.
Allocation: S 5, MP 4, M 3, FP 2, SD 2, C 1, KD 1, V 1, FI 1.
There are **9 elected groups, 30 distinct substitute IDs and 74 expanded
group-member/substitute relations**. Relations are not 74 substitute persons.
Preserve source group/order. All relation IDs join the candidate source.
Elected basis: **14 `P`, 6 `J`**.

Current XML preserves every original mandate, ID, order and relationship.
The public elected page is the original result view. The linked protocol PDF is
retrievable but contains only `Protokoll gallrat`: it supplies no detailed
independent control. No complete mandate-period event series was verified;
that missing history is separate from the complete fixed election result and
does not block its implementation.

## 6. Electorate

SCB's final composition table reconciles in all **22 national/county rows**:

| Component | National total |
| --- | ---: |
| Swedish citizens resident in Sweden | 7,155,202 |
| Swedish citizens resident abroad | 155,668 |
| Eligible other EU citizens resident in Sweden | 49,092 |
| Total | **7,359,962** |

Official district SKV has age/sex/two-way citizenship at all **5,837 ordinary
districts**; all totals match XML and foreign-citizen total is 49,092. The Swedish
category does not separate Sweden-resident and abroad-resident citizens.
Three-way composition is therefore **INCOMPLETE below county**: separate Swedish
resident/abroad components are unavailable for 290 municipalities, 390
constituency containers and 5,837 ordinary districts. No downward allocation.
All 390 Wednesday units lack separate electorate/turnout. Their ballots are
nevertheless fully counted. April residence/citizenship stock tables must not
replace final election-day denominators.

## 7. Counting stages

The root explicitly labels the preserved `valnatt` as `VALNATTSRAPPORTERING`.
It covers all 5,837 ordinary districts and their 290 municipalities, 390
constituency containers, 29 parliamentary reporting groups, 21 counties and
country. All geographic sums reproduce the national election-night counts,
which also match its public presentation:

| Measure | Election night |
| --- | ---: |
| Valid | 3,544,115 |
| Blank invalid | 36,656 |
| Other invalid | 17,303 |
| Cast | 3,598,074 |
| Eligible | 7,359,962 |

Eleven named parties (the ten final headline parties plus JL) and **13,308
aggregate other votes**. No final detail or preferences may be backfilled.

The linked `https://historik.val.se/val/ep2014/prelresultat/E/rike/index.html`
returns **404**, as do the targeted county-01 preliminary page,
`prelresultat/prelresultat.zip` and `prelresultat/prelresultat_00E.xml`.
No preliminary collection source is preserved locally. No broad/open-ended
archive search was undertaken.

**Full preliminary: INCOMPLETE, recovery gap.** Zero preliminary Wednesday source
units have been recovered. Final XML has 390; the exact population/reporting
status of the absent preliminary snapshot remains NOT VERIFIED. This does not
establish that preliminary collection results were never published.
Do not relabel election night as full preliminary or use final Wednesday votes.
Targeted recovery would be needed for that stage, but must not block final support.

## 8. SCB/SND reconciliation and source differences

Official SCB controls were preserved with URL/time/size/hashes:

- **22 country/county rows** match electorate, cast, valid, blank, all invalid and
  nine individually displayed party counts. SCB other includes PP:
  **109,911 = 82,763 PP + 27,148 VM headline other**; no vote discrepancy.
- All **362** disclosed small-party municipality values match XML. SCB's `Malung`
  is XML's `Malung-Sälen`, code **2023**: JL=21, PP=63. Explicit geographic
  correspondence, not a candidate-name join.
- Nominee/elected workbook: **376 nominees (201 men,175 women), 20 elected
  (9 men,11 women)**. No candidate-population discrepancy.
- All 22 electorate-component sums reconcile as above.
- [SCB ME0109T08](https://www.statistikdatabasen.scb.se/pxweb/sv/ssd/START__ME__ME0109__ME0109A/ME0109T08/):
  query 2014/both sexes, **3,783 cells = 291 areas x 13 party/total categories**.
  All **3,770 municipal cells** agree with XML-derived preferences; none missing
  or suppressed. National total agrees at **1,859,375**. SCB smaller-party
  preferences **2,956** are fully identified by XML candidate records, not an
  additional unidentified residual.

No administrative EU2014 SND file exists in the inspected local EU archive.
Identified SND material is survey/exit-poll research, not a complete
administrative result return. Independent administrative SND coverage is
**NOT VERIFIED** and was not used to fill values. The local transformed CSVs
cannot be labelled SCB/SND-authored without provenance, nor counted as
independent checks merely because they have different filenames.

| Observed difference | Classification / consequence |
| --- | --- |
| Current names/root filename redaction | Includes all 7,248 geographic name attributes as well as 863,172 person-name attributes. IDs/numerical results unchanged. Use actual ZIP filenames and preserved original geography. |
| Changed election-night generation timestamps | Metadata only, not another counting stage or changed votes. |
| Handwritten 5,618 vs detailed 5,608 | Unexplained ten-vote label omission at 05803201; preserve original residual. |
| 890 source spellings | Party identities not established; no automatic consolidation or candidate creation. |
| SCB versus VM headline other | PP grouping explains the difference exactly. |
| Malung/Malung-Sälen | Geographic label difference, same code/result. |
| Blank+other invalid versus modern extra categories | Historical reporting semantics; do not derive a modern category. |
| Preliminary endpoint 404s | Recovery/availability gap, not evidence of non-publication. |
| DTD/signature/protocol | Formal validation not completed: four 1.6 DTD endpoints 404, binary signature unchecked, protocol redacted. Actual XML and numerical controls available. |

## 9. Completeness matrix

COMPLETE refers to the stated reported population, not inferred physical identity
or unpublished administrative attributes.

| Dimension | Status | Exact coverage or exception |
| --- | --- | --- |
| Final valid/blank/other-invalid/cast | COMPLETE | All 6,227 district units, 290 municipalities and all source aggregates. |
| Named-party votes + residual categories | COMPLETE | 21 positive named parties, one zero category, 5,618 residual votes; geography balances. |
| Handwritten residual label detail | INCOMPLETE | Ten votes at 05803201 have no detailed label; 5,608 votes have exact labels. Totals/mandates unaffected. |
| Political-party identities for handwritten spellings | NOT VERIFIED | 890 spellings cannot be assumed to represent 890 parties; no supported identity lookup established. |
| Documented ballot candidacies | COMPLETE | 376 rows/IDs, 21 lists/parties; matches SCB; no result/relationship-only ID. |
| Modern candidate attributes | INCOMPLETE | Source lacks separate validity, consent, declaration, eligibility, ordered ballots and registered municipality. Missing attributes, not discarded observations. |
| Reported candidate preferences | COMPLETE | 402,053 positive list/candidate/unit records, all 6,227 units, 1,859,375 votes. |
| Smaller-party candidate preferences | COMPLETE | All reported IDs join; SCB smaller-party preference aggregate fully identified in XML. |
| Reported IDs/ballot positions | COMPLETE | Every candidate+list join/position agrees; preference rank remains distinct. |
| Physical-person linkage across lists/elections | NOT VERIFIED | No independent person linkage established. Not missing preference observations. |
| Original mandates/elected/substitutes | COMPLETE | 20 allocated,20 elected,zero unfilled;30 substitutes,9 groups,74 expanded relations. |
| Mandate-period event history | NOT VERIFIED | Complete original-to-end-of-term event series not established; original election places complete. |
| Current final ZIP geographic names | INCOMPLETE | All 7,248 geographic `NAMN` attributes are redacted in the current download. Original preserved XML retains them; overall final geographic coverage/names are complete from the full source collection. |
| Final geography | COMPLETE | 5,837 ordinary+390 Wednesday;290 municipalities;21 counties;29 reporting groups;181 real municipal constituencies+209 technical containers. |
| Eligible/turnout at reporting levels | COMPLETE | All 5,837 ordinary districts and source aggregates; district denominators match XML. |
| Wednesday electorate/turnout | INCOMPLETE | All 390 lack a separate denominator by source design; ballots available. |
| Three-way electorate national/county | COMPLETE | All 22 rows reconcile. |
| Three-way electorate below county | INCOMPLETE | Separate Swedish-resident/abroad counts not supplied for municipalities/constituency containers/ordinary districts; no allocation. |
| Election-night ordinary freeze | COMPLETE | All 5,837 ordinary units+aggregates;11 parties+other,no candidate preferences. |
| Full preliminary including Wednesday | INCOMPLETE | No recovered preliminary Wednesday snapshot; all such stage-specific observations unavailable. Final count is not a substitute. |
| Administrative SND independent comparison | NOT VERIFIED | No appropriate local EU2014 administrative file located; survey records not result controls. |
| Original raw-source integrity | COMPLETE | All 12 original SHA256 unchanged; both original ZIP populations/byte totals checked. |
| DTD/signature/detailed protocol | NOT VERIFIED | Four1.6DTD URLs404; binary signature/algorithm unchecked; detailed protocol redacted. Not missing numerical records. |

## 10. Comparison with EU 2019/2024

| Topic | EU2014 difference | Interpretation |
| --- | --- | --- |
| Raw results | XML DTD family1.6 versus 2019 family1.8 / 2024 JSON | Format, not missing data. Thin historical reader; reuse downstream normalisation. |
| ZIP layout/geographic labels | Current final has a directory prefix; all geographic `NAMN` and root filename fields are redacted | Packaging/redaction; resolve actual members and retain original verified geography rather than returning `Namnet gallrat` as a place name. |
| Candidacies | Headerless12 fields,376 rows,`Skickad` | Historical attribute reporting differs from modern status/consent schema; typed NA for absent attributes. |
| IDs/population | All 376 IDs/list positions reconcile | No EU2024-like unexplained snapshot omission; no person-linkage inference. |
| Names | Original local named/current public redacted | Publication-version difference; retain snapshots, consistent public name policy. |
| Party-only ballots | `90000` lacks identified preferences | Same role distinction as newer years; no fabricated votes. |
| Invalid | Blank+other, no separate participation-notice category | Historical semantics, not parser loss. |
| Handwritten | 890 raw spellings/ten undisclosed residual votes | Different from2019's reconciled supplementary party detail; retain source labels/residual. |
| Counting stages | Complete election night, unrecovered full preliminary | Recovery gap unlike2019 complete preliminary. No relabelling/final fill. |
| Geography | 5,837+390 units,181 real municipal constituencies | Historical geography difference; never reuse later boundaries/populations. |
| Electorate | Three-way national/county, two-way district citizenship | Level restriction; no downward allocation. |
| Elected/substitutes | Grouped XML relations,20/30 persons | Share fixed-result group logic; separate later events. |

## 11. Recommended implementation and next decisions

Use the preserved original final XML as primary input, retaining original and
redacted snapshots with
separate fingerprints. Read candidacies without headers. Reuse historical XML
geography, party/list, candidate and grouped-relation infrastructure with a thin
EU2014 adapter for archive layout, twelve candidate fields and invalid categories.
Keep implementation and independent validation in R.

| Function | Supported final source population |
| --- | --- |
| `results()` | National/county/municipality/real municipal constituency/ordinary+Wednesday districts; all XML named parties and residual categories. Exact handwritten labels need explicit identity/provenance semantics. |
| `seats()` | National original20 allocated,zero unfilled;29 parliamentary reporting groups are not EU mandate constituencies. |
| `candidacies()` | All 376 documented list records,typed NA for unsupported attributes. |
| `candidates()` | All 376 source-ID/party observations and official preference totals;no inferred physical-person link. |
| `elected()` | All 20 original final IDs/order/basis,national elected geography. |
| `substitutes()` | All 30 original substitute IDs /74group-expanded relations;preserve groups/order. |
| `preference_votes()` | All 402,053 reported district/list/candidate rows and supported geographic aggregations;no duplicate party/list counting. |

Before implementation, decide how the result view should retain raw handwritten
labels without asserting party identity, and retain the ten-vote unlabelled
residual. No further candidate recovery is indicated. Full preliminary support
requires a separate collection-source recovery decision and need not block final
results. No extensive mandate-period recovery is recommended.

Future implementation validation should preserve the exact source controls in
this report and add public canonical/raw, standard/full, English/Swedish, types,
keys/missingness and Parquet round-trip checks. These were **not** package/API
checks in this source-only inventory. No package tests or R CMD check were needed
for a documentation-only source inventory; independent source assertions ran in R.

### Explicit answers

1. **Final party results:** COMPLETE for every named party/aggregate category at
   every source level; INCOMPLETE only for the labels of ten handwritten votes
   at05803201. All ballots are accounted for.
2. **Reported preferences:** COMPLETE,402,053 positive records/6,227 units/
   1,859,375 votes;all IDs/list positions link.
3. **Candidate/candidacy population:** COMPLETE for376 documented ballot candidates
   and all reported result IDs. Unsupported attributes/person linkage are separate.
4. **Mandates/elected/substitutes:** COMPLETE for original20 allocated/20 elected/
   zero unfilled/30 substitutes/74 relations.
5. **Full preliminary:** INCOMPLETE due to unrecovered Wednesday snapshot;
   election-night ordinary freeze itself is COMPLETE.
6. **Before final implementation:** agree raw handwritten-label/unlabelled-residual
   representation; no candidate recovery required. Do not condition final support
   on preliminary or mandate-period history.

## Appendix A. Original file fingerprints

Original paths are relative to `.local-data/eu/2014/valresultat/`. Modification
metadata is in the local ledger and is not an established retrieval timestamp.

| File | Bytes | MD5 | SHA256 |
| --- | ---: | --- | --- |
| `2014_eu-medborgare_per_lan.xls` | 36352 | `d7968d20622e2562cc72be3f8b621d6c` | `f5bd7b0a117b3a3393274f058c7043b838f328d7097ba3a7c192e3ba88de283d` |
| `alkandur_E.skv` | 42871 | `e5ab7d410085b9fbf08614af3cc49ec1` | `6a647ecbe3835625aab0c0dd247b59c6b20ae290244235552e2d0cd6e7d64e61` |
| `ep2014_valresultat_per_kommun.skv` | 60959 | `ce63b02f1642ef4aeaaad9b1fdde63fa` | `018d0ba50b260ea0c3d30b7bd64063078cae98af3d2e339dfa07022064b2fe0f` |
| `ep2014_valresultat_per_valdistrikt.skv` | 1436136 | `45f9303c3fda078e324c5e8c77f97261` | `0bd580ec69b791f44a978ff84ce2411d1b62acafe8999bbe562eedb1aadb9398` |
| `handskrivna.skv` | 402919 | `3f24db5e2bd72e83eea2a1b6b2ca9752` | `df28696b65c7d2e47eb02b0fac5bf2820b07a1900dc35d5df200203fd7196dc0` |
| `partier_som_anmalt_kandidater.xls` | 24576 | `1e0e82d3fdf2cc4572dd7e99409f7408` | `d9ce16c292773bc0d3e93b1733bf76e45c45c7aa89f8aab79b89a4c78b9184cb` |
| `rostberattigade.skv` | 787181 | `5d93cb854008ae84ed994e32ecdc0489` | `8893d5e5d451352af6d361614694521a24ae2f63375294dd54452f0b190d8731` |
| `slutresultat.zip` | 12998045 | `f01526bbdac0c4b42ac26b020c65a821` | `2a90980165237c018cf5d8e56031de6e8a01ce605756d0f90ca622b7746c2cb5` |
| `utlandssvenskar_per_land_2014.xls` | 35328 | `51f816be8fb5759eb57a2177bebea6aa` | `4593f3caca81687aceb98c97ed3f389897c84283f18f5569444f859dc5abbb61` |
| `valnatt.zip` | 1766899 | `7114b9b806c9102bac4d9099694b59a2` | `f2953ae9b995ffd8d183487183c1b07f703e4ade44ce9d8d8c0291530342e922` |
| `valres_dist.csv` | 1567756 | `ea7ef52c1c80c5fb62e1d3420b6d795b` | `f2f2e3845e7b6df1de500c52c461071cd64e563ba2f5ed9bd55c365d5d1bc7bd` |
| `valres_dist2.csv` | 1678454 | `1903a0db976e41973b7e2e982d404e05` | `80f1272dae98a0ef6b2ede47faff82745b8fcc6938fc386523a954600aae742a` |

## Appendix B. Acquired sources and retrieval outcomes

All responses were retrieved sequentially on the recorded UTC timestamps. HTTP404
bodies are retained as failure evidence and are not input data. Successful
responses have original/effective URL, size, MD5 and SHA256 in the local ledger.
The SCB preference POST body is preserved as `scb-preference-query.json`.

| Audit filename | UTC retrieval | HTTP | Bytes | Source URL | SHA256 |
| --- | --- | ---: | ---: | --- | --- |
| `statistics.html` | 2026-10-15T18:12:35Z | 200 | 11087 | https://historik.val.se/val/ep2014/statistik/index.html | `9b7c55c173f21b9384e1070dc2f914fd15cade6f7d12920a224d621cb8031ce1` |
| `final.html` | 2026-10-15T18:12:35Z | 200 | 67950 | https://historik.val.se/val/ep2014/slutresultat/E/rike/index.html | `3f195c0c33236ac5fdd36ef06210bf2e651b198d2d6056e4acfae9f2bf26ad08` |
| `preliminary.html` | 2026-10-15T18:12:35Z | 404 | 196 | https://historik.val.se/val/ep2014/prelresultat/E/rike/index.html | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `election-night.html` | 2026-10-15T18:12:35Z | 200 | 66488 | https://historik.val.se/val/ep2014/valnatt/E/rike/index.html | `e460c1772896e97297a29d1f3e82412e986f1af188ef8847ad2a881c9839c396` |
| `current-candidates.skv` | 2026-10-15T18:12:35Z | 200 | 41879 | https://historik.val.se/val/ep2014/alkon/alkandur_E.skv | `f65c5697416f662f103d86558e1c59f572b88ab45cbbfc7dd66b7a2ef262cda3` |
| `current-final.zip` | 2026-10-15T18:12:35Z | 200 | 11397144 | https://historik.val.se/val/ep2014/slutresultat/slutresultat.zip | `dff2d62d5fe01b74542e86ce2c42366a8dcb2f2808263662a0fb2935c1381583` |
| `current-election-night.zip` | 2026-10-15T18:12:36Z | 200 | 1768054 | https://historik.val.se/val/ep2014/valnatt/valnatt.zip | `2930b102194ab469b2e1f06c8cd3262c349db509704a1b6280da17e0d81f0e9d` |
| `current-electorate.skv` | 2026-10-15T18:12:36Z | 200 | 787181 | https://historik.val.se/val/ep2014/alkon/E/rostberattigade.skv | `8893d5e5d451352af6d361614694521a24ae2f63375294dd54452f0b190d8731` |
| `elected.html` | 2026-10-15T18:12:36Z | 200 | 11752 | https://historik.val.se/val/ep2014/slutresultat/E/rike/valda.html | `4873db0dfba431db9a5f4fdde8ff77829454a022edbf7ebab3593e563d81e2bc` |
| `preferences.html` | 2026-10-15T18:12:36Z | 200 | 58046 | https://historik.val.se/val/ep2014/slutresultat/E/rike/personroster.html | `154b1041faeb5a363dc40f4bfa0654ccd0b24ce35fc6645e9a6ddbb1123c336c` |
| `protocol.pdf` | 2026-10-15T18:12:36Z | 200 | 7501 | https://historik.val.se/val/ep2014/slutresultat/protokoll/protokoll_00E.pdf | `3acbf2b1fca9f13d2ba4a2f679a6f416ff5ab696b5bc6e9f88e28de2a3dae465` |
| `scb-results.html` | 2026-10-15T18:12:36Z | 200 | 106845 | https://www.scb.se/ME0109 | `955ff4bb0de588e7f5461f88cb04f7696d258db8dac1a89a53c886883772cfff` |
| `scb-candidates.html` | 2026-10-15T18:12:37Z | 200 | 40892 | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/ | `3920db8ba34552286f89080a0ae0965dd78897bb5ad56c4d629b20da5778d286` |
| `scb-county.xlsx` | 2026-10-15T18:14:09Z | 200 | 17900 | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2014/valet-till-europaparlamentet-2014-efter-lan.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-parti | `1af535a0b1a9b351af50f8d54ccb6db35060edcf0bce278a4ceb7b08ad7b0517` |
| `scb-electorate.xlsx` | 2026-10-15T18:14:09Z | 200 | 14147 | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2014/valet-till-europaparlamentet-2014-efter-lan.-rostberattigade-efter-medborgarskap-och-kon | `252ee84decd8d4a46312766084a85d5fccc9b4665518c14252003037b43df014` |
| `scb-small-parties.xlsx` | 2026-10-15T18:14:09Z | 200 | 42925 | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2014/valet-till-europaparlamentet-2014-efter-kommun.-ovriga-partier-som-erhallit-05-eller-mer-av-rosterna-i-kommunen | `53c3132ab76d5232a0dd78dac879769d66c18afdaa6c225a87d9bea3848ef256` |
| `current-handwritten.skv` | 2026-10-15T18:14:10Z | 200 | 402919 | https://historik.val.se/val/ep2014/handskrivna/handskrivna.skv | `df28696b65c7d2e47eb02b0fac5bf2820b07a1900dc35d5df200203fd7196dc0` |
| `current-district.skv` | 2026-10-15T18:14:10Z | 200 | 1436136 | https://historik.val.se/val/ep2014/statistik/ep2014_valresultat_per_valdistrikt.skv | `0bd580ec69b791f44a978ff84ce2411d1b62acafe8999bbe562eedb1aadb9398` |
| `current-municipal.skv` | 2026-10-15T18:14:10Z | 200 | 60959 | https://historik.val.se/val/ep2014/statistik/ep2014_valresultat_per_kommun.skv | `018d0ba50b260ea0c3d30b7bd64063078cae98af3d2e339dfa07022064b2fe0f` |
| `preliminary.zip` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/val/ep2014/prelresultat/prelresultat.zip | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `preliminary-national.xml` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/val/ep2014/prelresultat/prelresultat_00E.xml | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `electorate.html` | 2026-10-15T18:14:10Z | 200 | 354725 | https://historik.val.se/val/ep2014/alkon/E/rike/alderkon.html | `c9818215abb513757427041aafaf645b485a8d528f183f491b06fe6e1bfbc762` |
| `parti_person_nation_1_6.dtd` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/dtd/resultat/parti_person_nation_1_6.dtd | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `parti_person_kommun_1_6.dtd` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/dtd/resultat/parti_person_kommun_1_6.dtd | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `parti_nation_1_6.dtd` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/dtd/resultat/parti_nation_1_6.dtd | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `parti_kommun_1_6.dtd` | 2026-10-15T18:14:10Z | 404 | 196 | https://historik.val.se/dtd/resultat/parti_kommun_1_6.dtd | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `scb-candidate-overview.xlsx` | 2026-10-15T18:15:12Z | 200 | 20754 | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/pong/tabell-och-diagram/nominerade-och-valda-kandidater-i-europaparlamentsval/ | `f43ba0da81ad72c6deca40d218b0a40760c1122d82b841b2fcc23b4139add26f` |
| `preliminary-verified.html` | 2026-10-15T18:15:13Z | 404 | 196 | https://historik.val.se/val/ep2014/prelresultat/E/rike/index.html | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `preliminary-county.html` | 2026-10-15T18:15:13Z | 404 | 196 | https://historik.val.se/val/ep2014/prelresultat/E/lan/01/index.html | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` |
| `scb-candidate-metadata.json` | 2026-10-15T18:15:13Z | 200 | 649 | https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0116/C1EUvalNom | `1ce37b86c1b61b6fc4f86e17008aa7f492404ed3792375409617feda81f738d4` |
| `scb-preference-metadata.json` | 2026-10-15T18:19:41Z | 200 | 6213 | https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0109/ME0109A/ME0109T08 | `1f485692b913a6c6b56d54096871c0cd682a874865ef9cc1d8f4584ce2c522b2` |
| `linkoping-3201.html` | 2026-10-15T18:19:42Z | 200 | 24743 | https://historik.val.se/val/ep2014/slutresultat/E/valdistrikt/05/80/3201/index.html | `d4b56bab8e30ef9b897489c380a73c5900d438b53e5e95b5a40f0d0981f9687e` |
| `linkoping-final.html` | 2026-10-15T18:19:42Z | 200 | 216094 | https://historik.val.se/val/ep2014/slutresultat/E/kommun/05/80/index.html | `cc10da32f20b603c6b7c9e33db93930a1b0a6d048a58ffc85ccb4004a208adcb` |
| `scb-preference-2014.json` | 2026-10-15T18:20:14Z | 200 | 197543 | https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0109/ME0109A/ME0109T08 | `e821605fd7bbebcce687cbedfc4fdc80caecec06be3015b761d112ac14f3806c` |


## Implementation follow-up

The approved final adapter retains the official handwritten residual in standard
results, without inferred party identity. Full results identify the ten
unallocated-designation votes as source metadata; a separate source-designation
asset preserves all reported labels plus the explicit ten-vote unidentified row.
See [implemented coverage](COMPLETENESS_EU_2014.md) and
[validation](VALIDATION_EU_2014.md). Full preliminary is not inferred from the
complete election-night freeze. The original inventory evidence above is retained.
