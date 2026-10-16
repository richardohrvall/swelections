# EU 2009: source inventory and completeness assessment

Review date: 16 October 2026. Election occasion: **7 June 2009**.
Inventory only: no production/API/schema implementation, canonical build,
commit, push, tag or release. Existing uncommitted EU 2014 work is preserved.

## Decision summary

Final party/category results and the original 18-seat allocation can be
implemented from the preserved original Valmyndigheten XML. All final voting
units are present and independent SCB result workbooks reconcile.

- The official ballot register contains **500 list-position observations** on
  23 candidate-bearing ballots for 22 parties, plus two plain party ballots:
  **25 ballots / 24 parties** in total. No public person/candidate ID exists in
  the inspected ballot or final-result XML.
- Eleven main parties have **386 national list-position preference records**
  and **370,716 positive list/candidate/unit observations** across all
  **5,664 ordinary + 396 Wednesday units**, totalling **1,874,130** preferences.
  All list-position joins and 64,762 published list-total controls pass.
- XML reports another **2,655** small-party preferences, giving **1,876,785**
  overall. Below county level the inspected small-party XML nodes do not carry
  a preference-count attribute; absence must not become zero.
- A targeted archive lookup recovered the original small-party Excel export
  from **31 October 2013, 21:34:01 UTC**. All **5,976 expected national/county/
  municipality/ordinary-district rows** and 102 named candidate columns survive.
  This resolves a geographic/heading recovery gap in the current exports, but
  exposes contradictory counts in two `Per Johansson` columns. Fully reconciled
  individual small-party preferences cannot yet be claimed.

No discrepancy found changes final party votes or the original mandates.
Review conservative source-observation keys and the small-party inconsistency
before implementing all candidate/preference views. Do not merge the two columns,
redistribute votes or construct a physical-person ID.

## 1. Sources and provenance

Primary authority: [official raw-data index](https://historik.val.se/val/ep2009/statistik/radata.html)
and [official final presentation](https://historik.val.se/val/ep2009/slutresultat/rike/index.html).
SCB supplies independent controls. No administrative SND result dataset was
found in the inspected EU 2009 local collection. Survey/exit-poll material is
not a substitute administrative return.

Original files remain unchanged in `.local-data/eu/2009/`. New responses,
extraction copies, diagnostic R scripts and evidence tables are preserved under
`.local-data/eu/2009/inventory-20261016/`, outside Git. `original-files.csv`
records original sizes, modification times, MD5 and SHA256. `retrieval.csv`
records requested/effective URL, retrieval UTC, HTTP status, size, MD5 and SHA256.
Archive capture dates differ from 2026 retrieval dates. Original local retrieval
times are unknown; modification times are not asserted publication dates.

### All original local files

There were **13 files**, including one byte-identical duplicate workbook.
The `kandidater/` directory was empty; no local EU 2009 `snd/` archive was present.

| Source | Format / coverage | Role and limits |
| --- | --- | --- |
| `valresultat/slutresultat.zip` | 11,000,383 bytes;291 XML + `Filer`,`Cksum`,`Signatur` | Original final national +290 municipal sources. Geography/candidate names survive. |
| `valresultat/handskrivna.skv` | Headerless 728 x 6 | Municipality/exact handwritten label/count;1,127 votes,436 exact spellings,187 represented municipalities. No district/list/candidate fields. |
| `valresultat/rostberattigade.skv` | 5,664 data rows x 46 | Final district electorate, age/sex, foreign EU voters, Swedish citizens abroad; repeated higher-geography columns must not be summed repeatedly. |
| `scb/eu_valres_distrikt_tal.xls` | 5,954 data rows x 21 | 5,664 ordinary districts +290 pooled municipal postal rows; electorate, foreign EU voters, cast, invalid/blank/valid, eight parties and other. |
| `scb/tab5aeu_kommun_tab_talut.xls` | Sheet 437 x 23 including headings;312 geographic records | Country+21 counties+290 municipalities; electorate, foreign EU, cast, turnout, invalid/blank/valid, party votes. |
| `scb/tab8-eu_ovr_partiut_revidering_2010-07-13.xls` | Sheet 1,052 x 6 including headings;866 disclosed values | Only parties reaching 0.5% in a municipality. Revised 13 July 2010 to restore municipalities in Jämtland, Västerbotten, Norrbotten omitted from the 2009 release. |
| Same filename with ` (1)` | Byte-identical | Duplicate, not independent evidence or a different snapshot. |
| `scb/tab13eu_persrost_persut.xls` | Sheet 1,437 x 13 including headings | Threshold-selected nominees (2% criterion in title), county/national preferences. Not a complete candidacy register; no VM candidate ID. |
| `rostning/vallokal.skv` | 5,664 data rows x 24 | Polling-place/district names, contact/location/opening metadata. Not a separate result source. |
| `rostning/rostlokal.skv` | 1,872 data rows x 20 | Advance-voting locations and metadata, not final counted ballots. |
| `rostning/institution.skv` | Headerless;1,388 date-prefixed physical records | Institutional voting locations/contact/opening data; no results or candidate variables. |
| `rostning/utlmynd.skv` | Headerless;1,879 date-prefixed physical records | Foreign voting/contact/opening data. These records are not a verified count of unique missions; careful field parsing needed. No results. |
| `rostning/mottagna_fortidsroster.skv` | 1,874 data rows x 26 | Daily received advance ballots,20 May-7 June, plus totals. Receipt activity is not final ballots cast. |

### Additional sources preserved

| Official source | Role / coverage |
| --- | --- |
| `valsedlar/00E.xml` | Report time 20090607232501; current names redacted;25 definitive ballots,500 candidate slots, party/list/position, age/sex, candidate-notification status. |
| Current `slutresultat/slutresultat.zip` | 7,997,563 bytes. All 291 XML trees compared: **zero non-name attribute changes**,808,664 changed `NAMN` occurrences. Original geography remains preferable. |
| Current `handskrivna.skv`,`rostberattigade.skv` | Byte-identical to local originals. |
| `statistik/valresultat_slutligt_2009.skv` | 6,162 rows:country+21 counties+290 municipalities+186 real municipal constituencies+5,664 ordinary districts. No Wednesday rows. |
| `valnatt/valnatt.zip` | Complete ordinary-only night freeze;291 XML+3 auxiliary members,5,664 districts, no Wednesday nodes. |
| `statistik/valresultat_valnatt_2009.skv` | Same 6,162 keys, night values. Not a full preliminary result including Wednesday. |
| Eleven `statistik/personroster_{m,c,fp,kd,s,v,mp,jl,sd,pp,fi}_2009.skv` | Additional preference exports; current headers redacted. Original XML gives stronger list-position semantics. |
| Current `statistik/personroster_ovr_2009.skv` and `.xls` | 115 of 118 headings redacted;5,439 data rows,537 fewer than complete archived Excel. SKV has a partial last record (89 instead of 118 fields). Do not use as complete source. |
| Archived `personroster_ovr_2009.xls`, capture 20131031213401 | Full 5,976 x 118 data grid plus header; all expected keys, no missing numeric cells. Explicit party/candidate headings, with numerical inconsistencies below. |
| Archived `personroster_ovr_2009.skv`, capture 20131031220930 | Headings restored, but shorter than archived Excel. Retain provenance; prefer complete Excel. |
| Current SCB district, municipal, small-party, selected-preference workbooks | All four byte-identical to local counterparts. |
| SCB nominee overview,`tab 1`/`tab 2` | 488 nominees (285 men,203 women),18 elected (8 men,10 women); person-based definition. |
| SCB Table 12 county preferences | Eight mandate parties x 22 country/county rows; all 176 count controls match XML. |
| SCB ME0109T08,2009 | Total 1,876,785 and other 2,655 agree with VM; FI/SDhistorical zero-component issue below. |
| Original final/elected/preference pages | Corroborate 18 original seats and 2011 expansion note. |
| Linked `protokoll_00E.pdf` | HTTP404HTML, not a recovered PDF; formal-document recovery gap, not missing numerical XML. |
| `Beslut_med_bilagor_signerat.pdf` | Genuine 2011 expansion PDF; secondary provenance, not replacement 2009 result. |
| EU-citizen county, Swedish-abroad country, enrolled-EU-citizen country workbooks | Dated March/May populations, not replacement final electorate. |
| DTD 1.4 national/municipal URLs | Both 404; numerical/tree validation used.Signature authentication not asserted. |

Recovered archive URLs:

- [Original small-party Excel](https://web.archive.org/web/20131031213401id_/http://www.val.se/val/ep2009/statistik/personroster_ovr_2009.xls), SHA256 `1a3fb38793ed5cc7e34af96c628645c5c9c885dbe6cc72a6d4afb28ca110b7c6`.
- [Original small-party SKV](https://web.archive.org/web/20131031220930id_/http://www.val.se/val/ep2009/statistik/personroster_ovr_2009.skv), SHA256 `b468b83f480f3514ae74dbaa8f68a2c0aeaf040994a7141dfa0aed162facdf6e`.

An exact ballot-register archive lookup returned 503. This does not prove no
unredacted snapshot exists. No broad archive search or fabricated candidate file.

## 2. Final result and geography

| National measure | Official final value |
| --- | ---: |
| Valid votes | 3,168,546 |
| Invalid blank | 54,509 |
| Invalid other | 4,506 |
| All invalid (sum of reported categories) | 59,015 |
| Ballots cast | 3,227,561 |
| Eligible voters | 7,088,303 |
| Turnout | 45.53% (source rounded) |
| Preferences including other aggregate | 1,876,785 |

No modern invalid-vote subtype is invented. Blank is invalid here, unlike the
2003 referendum's valid Blank option.

| Geography | Exact population / meaning |
| --- | --- |
| National | One EU election/mandate area |
| County | 21 reporting counties, not mandate constituencies |
| Municipality | 290 |
| Ordinary district | 5,664 |
| Wednesday | 396, with `E-municipality-constituency` XML codes |
| Municipal constituency | 186 real constituencies in 80 divided municipalities;210 technical 00 containers are not additional public constituencies |
| Parliamentary grouping | 29 XML `KRETS_RIKSDAG` reporting groups, not EU mandate constituencies |

Ordinary valid votes 3,051,060 +Wednesday 117,486 =3,168,546.
Wednesday blank/other-invalid 1,924/252 imply 119,662 ballots cast by category sum.
No separate Wednesday electorate/turnout denominator is provided.

All 290 municipalities reconcile to ordinary+Wednesday valid/blank/invalid counts;
all 3,480 municipality xheadline-party/category vote controls agree.
SCB pools 396 Wednesday units into 290 municipal `9800`postal rows: the count
difference is not missing 106 units. Do not distribute pooled votes among
municipal constituencies.

## 3. Small parties and handwritten designations

XML has 24 positive named parties:11 headline parties and 13 `VARAV_ÖVRIGA`
children of `GILTIGA PARTI="ÖVR"`. The latter **5,799 =4,669 named smaller-party
votes +1,130 residual votes on parties without ordered ballots**. Never add the
parent and children as independent votes.

| Smaller-party alias | National votes |
| --- | ---: |
| 0339 - Sveriges Nationella Demokratiska Parti | 57 |
| 0518 - Nordisk Union | 11 |
| 0520 - Partiet.se | 32 |
| 0889 - 666... | 28 |
| Ai - ArbetarInitiativet... | 2,862 |
| Bl - Blankledamöterna | 13 |
| DNP - Democratic National Party | 15 |
| EAP | 196 |
| FRP | 28 |
| KommF | 18 |
| ND | 1,329 |
| rer - Republicans right | 2 |
| scl - Socialisterna | 78 |
| Residual OVR, no ordered ballots | 1,130 |

Full source spellings remain unmerged; they are not invented party identities.
Blankledamöterna and Partiet.se have plain 90000 ballots and party votes but no
printed candidate slots.

An unsplit OVR node need not have VARAVchildren. There are 280 positive such nodes:
239 ordinary districts (327 votes),28 Wednesday units (34),7 municipal-constituency
containers (26),6 municipalities (24). These are overlapping views, not extra votes
or missing units. Preserve the unsplit category. The six municipalities are
0643,2514,1730,1763,1762,1461; local `other-party-detail-gaps.csv`lists all nodes
(the name denotes absent child structure, not missing ballots).

The handwritten file gives 728 observations/436 exact labels/1,127 votes, at
municipality level only. The three-vote gap is **Stockholm 0180:XML 110/detail 108;
Ekerö 0125:XML 2/detail 1**. Separate official label HTML fragments also total 108/1.
Current/local SKV hashes agree. No inspected source identifies the two Stockholm
or one Ekerö designations. This is missing designation detail, not missing valid
votes, and does not describe what was written on the original ballots.

The archived wide small-party Excel's residual column reports 0 instead of the
unsplit category at those six municipalities and 239 ordinary districts. Its 13 named
smaller-party vote columns match XML throughout 5,976 units. Use XML for residual
accounting; this preference-oriented workbook is not a replacement result source.

SCB groups JL, SD, FI into other: **292,172 =112,355 +103,584 +70,434 +5,799**.
All 866 disclosed municipal small-party counts agree after explicit label matching.
Its 0.5% municipal threshold is not a full decomposition of every other vote.
The short SCBlabel `Arbetarinitiativet` maps to the explicitly named VMparty Ai;
no candidate identity or vote redistribution is inferred.

## 4. Candidacies, identifiers and original relationships

`00E.xml` is a ballot/list register, not a unique-person register. All 25 ballots
are `Definitiv`. Candidate fields are `ORDNING`, `KANDIDATUPPGIFT`, `KÖN`, `ÅLDER`.
Ballot fields include party code, `LISTNUMMER`, `VALKRETSNAMN`,
`KANDIDATANMÄLAN`, `STATUS`. No public person/candidate ID, separate candidate
validity/consent or election-day eligibility field was found. List-level
candidate notification is not individual validity. All 500 current name fields
are redacted.

In result XML, `PERSONVAL/@KANDIDAT` is **ballot position** and `ORDNING` is
preference rank. Neither is a person ID. Combine party and list number: plain
`90000` is not globally unique. All 370,716 main-party district/Wednesday list
observations join to the ballot register by official list and position without
names; no duplicate unit/list/position keys were found.

SCB counts 488 unique nominees (285 men, 203 women), versus 500 ballot slots
(291 men, 209 women). Ballot-file party summaries total 498 (289 men, 209 women),
including Ai summary 53 versus 55 list slots. These are not equivalent units.
[SCB's 2009 documentation](https://www.scb.se/contentassets/9ad4806466f142079cfc428f8823e172/me0116_do_2009.pdf)
describes person-based deduplication across lists/parties; its underlying
person-number register is not this public XML. The exact 500-to-488 crosswalk
cannot be proved from the ID-free/redacted register. Do not infer twelve missing
persons or silently merge twelve slots. The difference between summary 498 and
500 slots is confined to Ai's two ballots; the individual duplicated identities
are not established here.

The source preference populations contain 386 main-party list positions plus
102 small-party named columns: 488 observations, numerically matching SCB's
unique-nominee count. This is coverage evidence, **not proof of 488 linked
physical persons**. The 114 small-party ballot slots cannot all be crosswalked
to those 102 columns through an official ID or position field. This is a linkage
limitation, not an identified list of missing candidacies. Preserve the separate
source-column/list-position observations and do not treat column order as
ballot position.

The fixed election has **18 VALD records, 27 ERSATTARE records, 8 groups,
68 expanded elected/substitute relations**. The source gives name/age/order and
13 preference-based (P) / 5 comparison/list-based (J) election bases. There are
18 allocated, 18 filled and zero unfilled seats. No candidate-ID attributes are
available on these relationship records; source completeness is separate from
cross-source physical-person linkage.

The official page and recovered 2011 PDF distinguish the increase from 18 to 20
members effective **1 December 2011**. This is not the original 2009 allocation.
No complete mandate-period event series was assembled; that dimension remains
NOT VERIFIED and is not needed for the fixed original result.

## 5. Preference-vote coverage and the Per Johansson inconsistency

### Main eleven parties: complete reported list-position observations

Country/county and district/Wednesday source structures are available. Ordinary
and Wednesday results must be combined without also adding the duplicate party-
and list-level presentations. Municipality/constituency aggregates must use
actual XML ancestry, not district-code guesses.

| Main-party quantity | Records | Preferences |
| --- | ---: | ---: |
| National list positions | 386 | 1,874,130 |
| Ordinary positive list/position observations | 353,303 | 1,807,621 |
| Wednesday positive list/position observations | 17,413 | 66,509 |
| All non-overlapping district units | 370,716 | 1,874,130 |

All 6,060 units are represented. All 386 national list-position sums and all
64,762 published named list-total controls agree. Unknown person identity does
not make these observations missing.

### Small parties: complete recovered ordinary grid, inconsistent fine counts

The archived Excel contains **5,976 rows: country +21 counties +290 municipalities
+5,664 ordinary districts**. There are no duplicate geography keys or missing
numeric payload cells. It explicitly identifies 102 candidate columns, with
**1,983 positive ordinary-district cells and 2,571 preferences**. No Wednesday
or municipal-constituency candidate rows are supplied by this export.

The current workbook has 537 fewer geographic rows and 115 redacted headings;
the current SKV also ends with a partial record. The archived SKV is itself
shorter than the complete archived Excel. These are concrete source/version
coverage differences, not a reason to invent missing zeros. The complete archived
Excel resolves the ordinary-grid recovery gap, but not the following inconsistency.

| Small-party preferences | Original XML / SCB aggregate | Sum of archived candidate columns |
| --- | ---: | ---: |
| National | 2,655 | 2,665 (+10) |
| County sums | 2,655 | 2,677 (+22) |
| Municipality sums | SCB:2,655 | 2,677 (+22) |

All inter-level differences inside the candidate export are confined to two
columns explicitly labelled **Per Johansson, Ai / ArbetarInitiativet**:

| Source column (KOD/NAMN included) | National | County sum | Municipality sum | Ordinary-district sum |
| --- | ---: | ---: | ---: | ---: |
| 36 | 22 | 28 | 28 | 32 |
| 47 | 22 | 28 | 28 | 32 |

The two entire numeric vectors are identical. That does **not** prove one person
or justify deduplicating them. The other 100 candidate columns reconcile between
country/county/municipality sums. Neither an official candidate ID nor ballot
position distinguishes the two column observations.

Municipality-minus-ordinary subtraction is -1 for each of these columns in
**0180 Stockholm, 0484 Eskilstuna, 1480 Göteborg, 2281 Sundsvall, 2480 Umeå**:
ten negative cells. The all-column residual sum 106 is therefore **not a verified
Wednesday dataset**. No individual small-party source rows were recovered for
any of the 396 original Wednesday units. The 186 real municipal-constituency
views likewise lack a complete supplied small-party candidate source.

Classification: **unresolved inconsistency in official supplementary data**,
not a package-normalisation bug. The original XML/SCB aggregate 2,655 is supported;
individual Per Johansson counts need official clarification or additional source
evidence. No raw values are corrected, dropped or redistributed. Party votes,
ballot totals, electorate and mandates are unaffected. Local evidence:
`small-preference-column-controls.csv`,
`small-pref-negative-wednesday-residuals.csv` and archived source checksums.

## 6. Election-night versus full preliminary

The recovered `valnatt.zip` has all 291 XML members and all **5,664 ordinary
districts**, with **3,039,760 valid / 3,107,343 cast** nationally. No Wednesday
nodes occur. The night wide table covers the same ordinary geography and the
186 real constituencies. It is an election-night freeze.

A bounded check of the linked presentation, a preliminary national URL and one
Wednesday URL under each counting branch found no full preliminary Wednesday
source; the probes return 404. This does not establish that such results were
never produced or published. **No complete preliminary Wednesday snapshot has
been recovered or verified.** No broad preliminary archive search was performed.

Retain night material as provenance; do not expose it as complete `preliminary`.
Do not substitute final Wednesday values. This recovery gap does not delay final
party results.

## 7. Electorate composition

The original register has every ordinary-district denominator and matches final
XML and SCB in all 5,664 units. It directly reports eligible foreign EU citizens
and Swedish citizens abroad. Swedish residents are the remainder of the same
source total; no geographic allocation is needed.

| Final electorate component | Count |
| --- | ---: |
| Eligible Swedish citizens resident in Sweden | 6,902,354 |
| Eligible Swedish citizens abroad | 137,536 |
| Eligible non-Swedish EU citizens | 48,413 |
| Total | 7,088,303 |

District components can be aggregated to municipality/county/country and to
real municipal constituencies using district ancestry. Repeated higher-level
columns in the register must not be added per row. All 396 Wednesday units lack
separate electorate/turnout denominators. SCB postal-row denominators of zero
are not verified zero electorates to copy.

Other official workbooks have earlier reference dates/populations: Swedish
abroad by country 26 March; resident EU citizens enrolled/not enrolled by county
31 March; enrolled EU citizens by citizenship country (link refers to 8 May;
workbook says statistics produced 12 May). Preserve as dated auxiliary snapshots,
not replacement election-day denominators or additional eligible voters.

## 8. Independent reconciliation and exact remaining exceptions

Verified controls:

- All **5,954** SCB ordinary/pooled-postal rows match valid, cast, blank, total
  invalid, electorate, eight named parties and appropriately grouped other.
- All **312** SCB country/county/municipality records match final electorate,
  cast, valid, blank, invalid and eight named parties.
- All **866** disclosed small-party municipality values agree after explicit
  party-label and geographic-name correspondence. The short label
  `Arbetarinitiativet` is matched to official Ai; `Malung` to source municipal
  code 2023 / Malung-Sälen. These are explicit geographic/party labels, not
  candidate-name identity matches.
- All four comparable local SCB workbooks equal their currently published copies
  byte-for-byte. All **176** SCB mandate-party country/county preference counts
  match original XML.
- SCB reports 488 unique nominees /18 elected. It does not define 488 ballot slots.
- All **13** original local-file SHA256 values are unchanged. The full 291-member
  original/current final-XML comparison finds no non-name attribute changes.

Additional SCB database limitation: the 2009 ME0109T08 response gives FI=0 and
SD=0 nationally, whereas original VM list results give **43,457 /51,046**.
The API's total remains 1,876,785 and its other aggregate 2,655; components fail
to sum to the total by 94,503. There are 263 positive FI municipality cases and
290 SD cases versus APIzero. The inspected metadata does not explain those
historical component values. They cannot validate absence of votes and must not
replace VM. Other aggregate 2,655 is independently supported at national/county
level; XML municipal attributes are absent, not zero. The local API comparison
preserves these differences, without production-data changes.

| Exception | Exact classification / effect |
| --- | --- |
| Three handwritten designation votes | INCOMPLETE label detail:Stockholm 2, Ekerö 1; no missing valid votes. |
| Current small-party preference exports | INCOMPLETE current snapshot:537 missing geographic rows,115 redacted headers; complete archived Excel recovered. |
| Two Per Johansson columns | NOT VERIFIED reconciled individual counts/identity:+10 national,+22 county/municipal, ten negative residual cells; no safe correction. |
| Small-party Wednesday/constituency detail | INCOMPLETE direct source:all 396 Wednesday units/no complete small-party candidate view for 186 real municipal constituencies. |
| Person-ID crosswalk | NOT VERIFIED:500 slots versus 488 SCB persons; no public stable person/candidate IDs. Not evidence of missing candidacies. |
| Original election PDF | INCOMPLETE recovery:linked PDF404; numeric XML/elected/SCB controls available. |
| DTD/signature authentication | NOT VERIFIED:DTD URLs 404; archive auxiliary checksum/signature retained, not cryptographically authenticated. MD5/SHA256 are recorded. |
| Full preliminary | INCOMPLETE recovery:complete Wednesday snapshot not recovered; no claim of original non-publication. |
| Mandate-period history | NOT VERIFIED:original 18 and 2011 expansion documented, no complete event sequence. |
| SND administrative comparison | NOT VERIFIED:no suitable local EU 2009 administrative dataset found; not a missing VM result. |

## 9. Authoritative completeness matrix

| Dimension | Status | Exact population or exception |
| --- | --- | --- |
| Final valid/invalid/blank/cast | COMPLETE | Country,21 counties,290 municipalities,5,664 ordinary+396 Wednesday; no missing final voting units. |
| Final reported electorate/turnout | COMPLETE | Ordinary/aggregate denominators verified; separate Wednesday denominators unavailable for all 396 by source design. |
| Final party/category accounting | COMPLETE | Eleven headline parties,13 named smaller parties and retained residual; parent/children never double-counted. |
| Separately reported named-party detail | COMPLETE | Preserve all named entries and unsplit residual nodes. This does not identify all handwritten designations. |
| Handwritten exact-label detail | INCOMPLETE | 1,127 of 1,130 votes; Stockholm 2/Ekerö 1 exception. Municipality-level detail only, no district designation file verified. |
| Ballot/list candidacy source population | COMPLETE | 500 slots,23 candidate-bearing lists/22 parties, plus 2 plain ballots;25 ballots/24 parties total. No duplicate party/list/position keys. |
| Unique-person population/linkage | NOT VERIFIED | No public ID crosswalk from 500 slots to 488 SCB persons; no inferred mergers. |
| Main-eleven candidate preferences | COMPLETE | 386 national list positions;370,716 positive observations across 6,060 units,1,874,130 preferences. |
| Small-party ordinary source grid | COMPLETE | Archived Excel has all 5,664 ordinary units plus country/21 counties/290 municipalities,102 candidate columns,1,983 positive ordinary cells. Grid completeness does not resolve count inconsistency. |
| Reconciled individual small-party counts | NOT VERIFIED | Two Per Johansson columns;2,665 versus 2,655 nationally,2,677 versus 2,655 in county/municipality sums. |
| Individual small-party Wednesday data | INCOMPLETE | No direct rows for 396 Wednesday units; subtraction yields ten negative cells. No complete corresponding 186-real-constituency source. |
| Aggregate small-party preferences | COMPLETE | Official 2,655 national and county total, independently corroborated by SCB; not an invented candidate allocation. |
| Original mandates/elected/substitutes | COMPLETE | 18 allocated/18 elected/0 unfilled;27 substitute source records,8 groups,68 expanded relations. ID-free records. |
| Electorate composition | COMPLETE | All 5,664 ordinary districts and supported aggregates; direct foreign/abroad fields plus same-total resident remainder. No Wednesday allocation. |
| Ordinary election-night snapshot | COMPLETE | All 5,664 districts; remains distinct from full preliminary. |
| Full preliminary result | INCOMPLETE | Complete preliminary Wednesday snapshot not recovered/verified. No final substitution. |
| Full mandate-period history | NOT VERIFIED | No complete sequence of later events established. |

### Coverage of the seven prospective public functions

| Function | Available 2009 source support / decision before coding |
| --- | --- |
| `results()` | Final country/county/municipality/real municipal constituency/ordinary district/Wednesday counts; retain residual categories. Final numerical coverage COMPLETE. |
| `seats()` | Original 18 national mandates and zero unfilled; COMPLETE. Keep later 2011 expansion separate. |
| `candidacies()` | All 500 official list-position records; COMPLETE documented source population. Needs candidacy-level key, no claimed person ID. |
| `candidates()` | Source-observation representation possible; unique-person projection NOT VERIFIED. Do not collapse 500 slots into 488 people from names/statistical totals. |
| `elected()` | All 18 original source relationships; COMPLETE as records. Safe relation-to-candidacy linkage/key policy must be agreed because no source ID exists. |
| `substitutes()` | All 27 source substitute posts/68 expanded relations; COMPLETE as records. Same linkage limitation; not a mandate-period roster. |
| `preference_votes()` | Main 11:COMPLETE district/list coverage. Small parties:full ordinary source grid recovered, aggregate 2,655 established, but two individual columns inconsistent and direct Wednesday detail absent. Do not certify all individual views yet. |

## 10. Comparison with later EU elections and implementation recommendation

2009 uses DTD 1.4 XML and older/headerless statistical tables. The other-party
hierarchy is `GILTIGA PARTI="ÖVR"/VARAV_ÖVRIGA`, rather than the later
`ÖVRIGA_GILTIGA/GILTIGA/HANDSKRIVNA`. An unsplit OVR node is a legitimate source
category. These are format/structural differences, not missing ballots.

Reuse shared R geography/count infrastructure after a thin year-specific reader
normalises those roles. Reuse standard/full and EN/SV projection machinery.
Do not assume later candidate IDs, consent/validity fields, municipal aggregate
preference attributes or a modern invalid-vote decomposition existed. County
and parliamentary reporting geographies must not become EU mandate areas.

The substantive difference from 2014/2019/2024 is ID-free candidate information.
Design a conservative candidacy or source-observation key, explicitly not a
physical-person identifier. A statistical source-column key may preserve a
reported preference observation without falsely claiming its ballot position.
No public schema/API decision is implemented in this review. Follow the approved
historical-redaction name policy; archive names may document semantics without
automatically restoring public names.

Recommended source selection:

1. Pin original final ZIP for geography, party/category votes, main-party list
   preferences and original 18-seat relationships.
2. Use recovered official `00E.xml` for all documented lists/positions and source
   demographic/status fields; unsupported fields remain missing.
3. Use original electorate SKV, including its finer composition coverage. Keep
   Wednesday denominators absent.
4. Use unchanged handwritten SKV, with the explicit three-vote designation gap.
5. Preserve complete archived small-party Excel as separate source evidence.
   Do not replace it with the incomplete current SKV/XLS or silently correct its
   two Per Johansson columns.
6. Use SCB for independent controls. Any future supplementation must be separately
   justified and independently reconciled; never fabricate individual records.
7. Preserve complete night ZIP as provenance; do not relabel it full preliminary.
   Further preliminary archive recovery is not a prerequisite for final results.

Before a full seven-function implementation, review the source-key model and
small-party preference exception. Final party results and seats need no further
source recovery. No canonical assets have been built or altered.

### Six explicit answers

1. **Final party results complete? YES**, under the reported party/category model,
   for all final units. Three handwritten designations remain undisclosed in
   inspected detail; their valid votes are present.
2. **Reported preferences complete? Main 11:YES.** The small-party ordinary grid
   is recovered, but internally reconciled individual coverage is **NOT VERIFIED**
   (two columns), and direct individual Wednesday coverage is **INCOMPLETE**
   (396 units). Reported observations are not discarded for lack of person IDs.
3. **Candidate/candidacy population complete? Documented ballots:YES**,500 slots/
   25 ballots. Unique-person linkage is **NOT VERIFIED**; SCB 488 is a different
   unit and does not supply missing public identifiers.
4. **Mandates/elected/substitutes complete? YES**, fixed 18/18/0,27 substitute posts,
   68 relations. Full subsequent term history:NOT VERIFIED.
5. **Preliminary complete? NO.** Ordinary night freeze complete; full Wednesday
   snapshot not recovered. Do not expose the night freeze as full preliminary.
6. **What before final implementation?** No new party-result recovery is needed.
   Agree ID-free source keys and clarify the two contradictory small-party columns
   before certifying a fully reconciled individual preference product. Never
   resolve those differences by changing raw source values.

## 11. Reproduction and evidence

The inventory is reproducible with R and existing project dependencies. All new
code is diagnostic and stays local. `pdftotext` was invoked from R solely to read
already downloaded metadata PDFs; no Python/runtime dependency was introduced.
No package tests or package checks were rerun:production code was not changed.

Key local evidence files:

- `original-files.csv`, `retrieval.csv`: preserved sources/checksums/HTTP provenance.
- `census.rds`, `geographic-units.csv`: all 291 original final XML members.
- `reconcile.log`: all SCB result controls and final electorate checks.
- `final-snapshot-comparison.csv`: all 291 old/current XML comparisons.
- `archived-controls.log`: complete 5,976-row small-party source coverage and counts.
- `small-preference-column-controls.csv`: all 102 source-column totals by level.
- `small-pref-negative-wednesday-residuals.csv`: exact ten negative cells.
- `small-wide-other-differences.csv`: six municipality/239 district residual-column exceptions.
- `scb-api-preference-differences.csv`: FI/SD historical component exceptions.
- `night-units.rds`, `night-zip-members.csv`: complete ordinary-only night population.

The hash appendices below record source provenance without distributing raw files.

## Appendix A: original local source checksums

| File | Bytes | MD5 | SHA256 |
| --- | ---: | --- | --- |
| `rostning/institution.skv` | 245240 | `353836cea6affd57d249ff423fb86911` | `12420ef4cfb87590290ea00d035162395f6d9edecf4f30eed1611cb0dc780f4d` |
| `rostning/mottagna_fortidsroster.skv` | 197433 | `f0f091c1db11c1a3aac7d4da1d67fa44` | `4bf3896b56ff5ee1283621b35491bcaa65111c3a6b9c96935e40e038f582d371` |
| `rostning/rostlokal.skv` | 458246 | `7f6957f0b1d3b246108f6f6142692baa` | `11b77dc9268ec38adbd220922eb15e46687956e0574aa22e0e69517846fb21be` |
| `rostning/utlmynd.skv` | 440730 | `080a38c5bc73d8600421fa6ab4e5a833` | `ee5c8626203366238a12c5dc690717c69465a30c0afcc34fa192a8699fa5242e` |
| `rostning/vallokal.skv` | 1279970 | `569ea4c5d215803f6c484c52af3e5c2a` | `0476f52dd28ec542ef19523a6e98d88388c3fd2337a1bdbe4d40b9e17ec55ca9` |
| `scb/eu_valres_distrikt_tal.xls` | 1428992 | `667c148a253818a82a63f72429da35f4` | `ab94c27d7b036bdff7973317da7cda330bff8b740310830ebfb2cb90e206a4e5` |
| `scb/tab13eu_persrost_persut.xls` | 187392 | `b60286717a1fbb4cdc74fdd19a252e55` | `14f621eae520aaddf8885573ee40dfe5113251dbf6bf3cd009ba95f4bb06bd3c` |
| `scb/tab5aeu_kommun_tab_talut.xls` | 117760 | `5ec3a2b6e945a359b15345795ce6b342` | `99b8abe0882d6fd2e5b4e49dcda37d47042f504e76c2dee5f9f62866bdb22032` |
| `scb/tab8-eu_ovr_partiut_revidering_2010-07-13 (1).xls` | 130048 | `d61c6ed748cb5c3cfbff34b64d9b51eb` | `56f800fecd23cbdd7bab7d1c18fa3fa72ba3925ac7b01c4d480edf098ad63cc4` |
| `scb/tab8-eu_ovr_partiut_revidering_2010-07-13.xls` | 130048 | `d61c6ed748cb5c3cfbff34b64d9b51eb` | `56f800fecd23cbdd7bab7d1c18fa3fa72ba3925ac7b01c4d480edf098ad63cc4` |
| `valresultat/handskrivna.skv` | 35809 | `d46a5f88a44eca94302e4f434c1a4ee1` | `f2c83cc2603aa3a78a37c8f5b942f46411bcd783b2182735f1618aa4c6321e61` |
| `valresultat/rostberattigade.skv` | 1517276 | `abb205b7e720df70eabb4ebb5f714edb` | `6f4c4d5627cf34dd9952eacd2c1b6ff41abba42defc18e8397bd4b3c7d4ea9da` |
| `valresultat/slutresultat.zip` | 11000383 | `eab8e8c0b1fb5c74ffdfba3c4edcb37e` | `b10e2667b1105b7c3fb74eed762f2933f48f820bd06f560817b6cd251a00e7be` |

## Appendix B: retrieved official/archive response ledger

HTTP status is recorded even for failed probes. A 404 HTML body with a PDF or
ZIP filename is not a usable PDF or ZIP. Archive capture time is encoded in the
archive URL; the UTC column below is retrieval time in 2026. Raw files remain
local. Effective URLs are separately retained in `retrieval.csv`.

| Local response | UTC retrieved | HTTP | Bytes | MD5 | SHA256 | Source |
| --- | --- | ---: | ---: | --- | --- | --- |
| `raw-index.html` | 2026-10-16T07:16:43Z | 200 | 5883 | `56c20ec08ad839f5602f11e714ee443a` | `8a0c8a7601c27029641d98d4721937b3ae170dc2781214333dc6dce28b02f863` | [source](https://historik.val.se/val/ep2009/statistik/radata.html) |
| `final.html` | 2026-10-16T07:16:44Z | 200 | 67514 | `9089456f2b9cdb811d0e2f460fcfcdd1` | `534e5f26ebc60d49827e2efd67b2c30d96ba6e87261aabdf130c870349a6b567` | [source](https://historik.val.se/val/ep2009/slutresultat/rike/index.html) |
| `elected.html` | 2026-10-16T07:16:45Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/slutresultat/rike/valda.html) |
| `preferences.html` | 2026-10-16T07:16:45Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/slutresultat/rike/personroster.html) |
| `election-night.html` | 2026-10-16T07:16:46Z | 200 | 63064 | `19814534ebe6adbe2c4cb5d72acf6161` | `65de5a3d72be38aefd717a07092aeabdc1dbd013f0bd4de1deefcf923c2a6773` | [source](https://historik.val.se/val/ep2009/valnatt/rike/index.html) |
| `other-statistics.html` | 2026-10-16T07:16:47Z | 200 | 11912 | `c43dbb2071a8ca9d70fd3fe2187b789e` | `dfb6a0119811567e288506e7dada5bebcafdaf65a11c482270177ffa7f1c1aec` | [source](https://historik.val.se/val/ep2009/statistik/ovrigt.html) |
| `ballots-index.html` | 2026-10-16T07:16:47Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/valsedlar/rike/index.html) |
| `ballots.xml` | 2026-10-16T07:17:52Z | 200 | 60840 | `e4247f6ab3ef51a5ad592c32052a25e6` | `3f3cd4574b3b1721fb56f19521c01097e684d77c59855c7d115e6af7e284ed42` | [source](https://historik.val.se/val/ep2009/valsedlar/00E.xml) |
| `ballots.html` | 2026-10-16T07:17:52Z | 200 | 31405 | `fac48e333b6b892dff35aecbdb50fcd7` | `6203b2789007b4920c1ab5d764c180a5c8c9148ecf73d54262494081d2d6b569` | [source](https://historik.val.se/val/ep2009/valsedlar/index.html) |
| `elected-correct.html` | 2026-10-16T07:17:53Z | 200 | 7940 | `842131c89b55d7542512a67288d0cc23` | `8fd40f46df7afc8d90dc355d9bd2347b50c3a0af4f948024bf619d4a5942d5ac` | [source](https://historik.val.se/val/ep2009/slutresultat/valda/index.html) |
| `preferences-correct.html` | 2026-10-16T07:17:54Z | 200 | 52054 | `53b3f3061859ac8c26aae525aef4438a` | `e26c0b9010ae26870237399517c92cfec69ee6f8126169dd4fa47219d801c429` | [source](https://historik.val.se/val/ep2009/slutresultat/personroster.html) |
| `current-final.zip` | 2026-10-16T07:17:54Z | 200 | 7997563 | `26d4ae457f0764c96e839e8382256d4d` | `23062b0864f18a0bd00fabb2f3d0eccb8f166777e9cab2977984fd05aaa76665` | [source](https://historik.val.se/val/ep2009/slutresultat/slutresultat.zip) |
| `current-handwritten.skv` | 2026-10-16T07:17:55Z | 200 | 35809 | `d46a5f88a44eca94302e4f434c1a4ee1` | `f2c83cc2603aa3a78a37c8f5b942f46411bcd783b2182735f1618aa4c6321e61` | [source](https://historik.val.se/val/ep2009/handskrivna/handskrivna.skv) |
| `current-electorate.skv` | 2026-10-16T07:17:56Z | 200 | 1517276 | `abb205b7e720df70eabb4ebb5f714edb` | `6f4c4d5627cf34dd9952eacd2c1b6ff41abba42defc18e8397bd4b3c7d4ea9da` | [source](https://historik.val.se/val/ep2009/statistik/rostberattigade.skv) |
| `final-wide.skv` | 2026-10-16T07:17:56Z | 200 | 850655 | `530e94ab58389224dc9bc0493e8251c3` | `da841aa09341d29c4e8c6d9f8b486ede075bb4c67c0bf14b191eae07bc30df09` | [source](https://historik.val.se/val/ep2009/statistik/valresultat_slutligt_2009.skv) |
| `night-wide.skv` | 2026-10-16T07:17:57Z | 200 | 770522 | `eb5fa4bf22d78d2f3a08f524e9f18b7c` | `caaaa8854148944e01ac3ed79ca2de13449af369ad97caf80739e9835e99a738` | [source](https://historik.val.se/val/ep2009/statistik/valresultat_valnatt_2009.skv) |
| `electorate.html` | 2026-10-16T07:17:57Z | 200 | 59899 | `593a2bafc15c34f255b668d2e50d9f2e` | `bb6d7669f5535741c8f13f59b78983c55b8bbbb35e9a63dcdd7c22d573ab6aa6` | [source](https://historik.val.se/val/ep2009/statistik/rike/index.html) |
| `original-protocol.pdf` | 2026-10-16T07:17:58Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/slutresultat/protokoll_00E.pdf) |
| `2011-seats-protocol.pdf` | 2026-10-16T07:17:59Z | 200 | 1328943 | `4612d3eb4dcd9881e47ed0a6616085b6` | `2a40080e2a2407a84e6aecf6cb13a18448805d607b23f5a5c258d2427b4a2d1e` | [source](https://historik.val.se/val/ep2009/slutresultat/Beslut_med_bilagor_signerat.pdf) |
| `preferences-m.skv` | 2026-10-16T07:17:59Z | 200 | 688377 | `f2c8226164665be986f362604288fe0b` | `8871bcec5dd2b85af787916759f112ca892d5271566c36e2d41ef0951f029ea9` | [source](https://historik.val.se/val/ep2009/statistik/personroster_m_2009.skv) |
| `preferences-c.skv` | 2026-10-16T07:18:00Z | 200 | 701024 | `d045e289d37180feab5f57f27b40cd40` | `ce9e2a94a8ed179877cf171be02f8c5bf9042c5a502feed4c4fb6702e0fa33b3` | [source](https://historik.val.se/val/ep2009/statistik/personroster_c_2009.skv) |
| `preferences-fp.skv` | 2026-10-16T07:18:00Z | 200 | 671268 | `204afbd0c1ca305f70b012cf2e8cc4bc` | `57e583c3a9286571a3db3ec26170526a3a30c5c510b5e91a3a4afbc630364513` | [source](https://historik.val.se/val/ep2009/statistik/personroster_fp_2009.skv) |
| `preferences-kd.skv` | 2026-10-16T07:18:01Z | 200 | 808676 | `e0351c01843b5a682c735946ddf21754` | `1d5f9d204a624999cd71eb0368dd0f6ee2301f02c7f8f09374d0c7e67e89e19b` | [source](https://historik.val.se/val/ep2009/statistik/personroster_kd_2009.skv) |
| `preferences-s.skv` | 2026-10-16T07:18:02Z | 200 | 538237 | `3855d5b54fedbbfd882e4a0937c628f2` | `c8ae78325b7aa86ca1c503a3f9dc4a69ccfbfa176f0e4f7f9bbcc82696e0c3c6` | [source](https://historik.val.se/val/ep2009/statistik/personroster_s_2009.skv) |
| `preferences-v.skv` | 2026-10-16T07:18:02Z | 200 | 664442 | `50da1be3d53afccfa0a0dca1badc0261` | `6f1af9d62fe823786ff2186b44aaa7c3a5fa2ebe509a542a63bd145d3af6e06e` | [source](https://historik.val.se/val/ep2009/statistik/personroster_v_2009.skv) |
| `preferences-mp.skv` | 2026-10-16T07:18:03Z | 200 | 526801 | `ee497046c89f656d4830dc9520aee82c` | `f202b0a0b2953eb1f17ccaa276d33c187cdf637b13d85303841ec0ce6c71d542` | [source](https://historik.val.se/val/ep2009/statistik/personroster_mp_2009.skv) |
| `preferences-jl.skv` | 2026-10-16T07:18:03Z | 200 | 710207 | `ba764f2ebc42605be72f4d72a6ed9c9b` | `56b2de71c5a604f38856d0eee1bcf63ff7f14b9cca520f5bb05fa1c37da02fda` | [source](https://historik.val.se/val/ep2009/statistik/personroster_jl_2009.skv) |
| `preferences-sd.skv` | 2026-10-16T07:18:04Z | 200 | 506150 | `fa4a012fecf8454580e9e79e90d97fec` | `9fd30f7bff68bcccc74da518fef7d350162ec604f8eb78760326757d2cd8deb8` | [source](https://historik.val.se/val/ep2009/statistik/personroster_sd_2009.skv) |
| `preferences-pp.skv` | 2026-10-16T07:18:04Z | 200 | 402889 | `23776816fe74f4ecf2667c14f4752977` | `353af00d760d64db645f3384b37fce327e2a83392d42444f6566157a65dfc9aa` | [source](https://historik.val.se/val/ep2009/statistik/personroster_pp_2009.skv) |
| `preferences-fi.skv` | 2026-10-16T07:18:05Z | 200 | 217202 | `cc6fd5d2873ebab78a7ca9872a70e62b` | `ce7a694fe8b5b8798d093b73dc7f6ade29519a041fa3cdbd674d7013308aa564` | [source](https://historik.val.se/val/ep2009/statistik/personroster_fi_2009.skv) |
| `preferences-ovr.skv` | 2026-10-16T07:18:06Z | 200 | 1392344 | `8750f651687357872cb65d5bd0e76831` | `879687775e7e9a92f6dd86a3a193594840de0ef1cbaa29f347bfcad16b45d1ae` | [source](https://historik.val.se/val/ep2009/statistik/personroster_ovr_2009.skv) |
| `parti_person_nation_1_4.dtd` | 2026-10-16T07:18:06Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/dtd/resultat/parti_person_nation_1_4.dtd) |
| `parti_person_kommun_1_4.dtd` | 2026-10-16T07:18:07Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/dtd/resultat/parti_person_kommun_1_4.dtd) |
| `eu-citizens-county.xls` | 2026-10-16T07:18:07Z | 200 | 20480 | `61fff764937198a7d0f065cc5af5ae00` | `c68d918731bc57254c1b2a8ca40c94c5f8a81f5a39b155110cf9672137f8483a` | [source](https://historik.val.se/val/ep2009/statistik/eu-medborgare_per_lan_2009.xls) |
| `swedish-abroad.xls` | 2026-10-16T07:18:08Z | 200 | 29696 | `c0fc610466afa950c432e3ee4bca4c10` | `6dfc3d171e36090c4f12812b64f57ef61c115fc452cab89c841c82875b37713f` | [source](https://historik.val.se/val/ep2009/statistik/utlandssvenskar_per_land_2009.xls) |
| `scb-municipal.xls` | 2026-10-16T07:20:58Z | 200 | 117760 | `5ec3a2b6e945a359b15345795ce6b342` | `99b8abe0882d6fd2e5b4e49dcda37d47042f504e76c2dee5f9f62866bdb22032` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2009/valet-till-europaparlamentet-2009-kommunvis.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-parti.-antal) |
| `scb-district.xls` | 2026-10-16T07:21:04Z | 200 | 1428992 | `667c148a253818a82a63f72429da35f4` | `ab94c27d7b036bdff7973317da7cda330bff8b740310830ebfb2cb90e206a4e5` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2009/valet-till-europaparlamentet-2009-valdistriktsvis.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-parti.-antal) |
| `scb-small.xls` | 2026-10-16T07:21:28Z | 200 | 130048 | `d61c6ed748cb5c3cfbff34b64d9b51eb` | `56f800fecd23cbdd7bab7d1c18fa3fa72ba3925ac7b01c4d480edf098ad63cc4` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2009/valet-till-europaparlamentet-2009-kommunvis.-ovriga-partier-som-erhallit-05--eller-mer-av-rosterna-i-kommunen-revidering-2010-07-13) |
| `scb-nominee-preferences.xls` | 2026-10-16T07:21:32Z | 200 | 187392 | `b60286717a1fbb4cdc74fdd19a252e55` | `14f621eae520aaddf8885573ee40dfe5113251dbf6bf3cd009ba95f4bb06bd3c` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2009/valet-till-europaparlamentet-2009.-nominerade-som-fatt-2--eller-mer-av-sitt-partis-personroster-per-lan-med-uppgift-om-antalandel-personroster) |
| `scb-party-preferences.xls` | 2026-10-16T07:21:38Z | 200 | 38912 | `f1123be41f849007810c3cd78432c77b` | `0ae4c18959255909ce9dae7d3a792588257ce514cb3e8762a8bbd94c290739f2` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2009/valet-till-europaparlamentet-2009-lansvis.-antal-personroster-per-parti-andel-efter-kon) |
| `scb-nominee-overview.xlsx` | 2026-10-16T07:21:43Z | 200 | 20754 | `fc9798d3b906f464ce7da04cd5949e57` | `f43ba0da81ad72c6deca40d218b0a40760c1122d82b841b2fcc23b4139add26f` | [source](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/pong/tabell-och-diagram/nominerade-och-valda-kandidater-i-europaparlamentsval/) |
| `preferences-ovr.xls` | 2026-10-16T07:21:44Z | 200 | 11719168 | `b79185fb4a0e1caa6b5af0850f8c0d2f` | `d9ce732aa877cd2407864cdbd50ab7151129ff1d180c6504d4315ff33ad36975` | [source](https://historik.val.se/val/ep2009/statistik/personroster_ovr_2009.xls) |
| `preliminary-probe.html` | 2026-10-16T07:21:45Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/prelresultat/rike/index.html) |
| `night-zip-probe.zip` | 2026-10-16T07:21:46Z | 200 | 1594729 | `45d11a73383f743328f0686f87be891b` | `0aa23ebfacfb85f026b6ac3572069a2e84badbd7be33199dae55d5d8a700bc33` | [source](https://historik.val.se/val/ep2009/valnatt/valnatt.zip) |
| `night-wednesday-probe.html` | 2026-10-16T07:21:46Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/valnatt/onsdagsdistrikt/01/14/02/index.html) |
| `preliminary-wednesday-probe.html` | 2026-10-16T07:21:47Z | 404 | 196 | `62962daa1b19bbcc2db10b7bfd531ea6` | `80c3fe2ae1062abf56456f52518bd670f9ec3917b7f85e152b347ac6b6faf880` | [source](https://historik.val.se/val/ep2009/prelresultat/onsdagsdistrikt/01/14/02/index.html) |
| `stockholm-labels.html` | 2026-10-16T07:26:22Z | 200 | 6721 | `92074772e8a8867bb1d26a70c9159992` | `339afe3a06a3f1e3f06bf757a1b70d0a61392fed51612aec8d5eaa1af83b66b3` | [source](https://historik.val.se/val/ep2009/handskrivna/kommun/01/80/index.html) |
| `ekero-labels.html` | 2026-10-16T07:26:23Z | 200 | 240 | `1e902966736a14b9e952908f2790e83f` | `8b58042586af6adacbc992531efafb44b7b2f2ea15a33b568533916f045953e9` | [source](https://historik.val.se/val/ep2009/handskrivna/kommun/01/25/index.html) |
| `national-labels.html` | 2026-10-16T07:26:24Z | 200 | 38445 | `5aad141bc4a5cea01246e644dd536271` | `2f4bf8c9596af2bc2de9a528139e509c757c1e8721bc461927c0f9c777635dcc` | [source](https://historik.val.se/val/ep2009/handskrivna/rike/index.html) |
| `stockholm-result.html` | 2026-10-16T07:26:24Z | 200 | 879668 | `8958d5889f52c54702dec4e2086f2a47` | `dae67529cd0de5d9eca07a35335d7939b433d5f5789dcc370ccc741fc8a0d274` | [source](https://historik.val.se/val/ep2009/slutresultat/kommun/01/80/index.html) |
| `ekero-result.html` | 2026-10-16T07:26:25Z | 200 | 55546 | `0eed3a2e94c9fde84ef51d70b22f5813` | `185e098a6e1c111d04857011ae0693d649303d050da687b6f60e9b1d6d65f889` | [source](https://historik.val.se/val/ep2009/slutresultat/kommun/01/25/index.html) |
| `scb-nominees-2009-1.pdf` | 2026-10-16T07:26:25Z | 200 | 72772 | `30c803bb1af382a16f7811b96b49e911` | `4fc234296db8e72b28986505e0d0d2d4e3b5b186657a81e0289b7ad1c77952bf` | [source](https://www.scb.se/contentassets/9ad4806466f142079cfc428f8823e172/me0116_bs_2009.pdf) |
| `scb-nominees-2009-2.pdf` | 2026-10-16T07:26:27Z | 200 | 76469 | `38a06c6d48d6d1aedad49a3d2eab76cc` | `ddf2ba0dd1b23e6ed360c14b8383209bfbe11cdbc35ef9e7e02efae07f0d5275` | [source](https://www.scb.se/contentassets/9ad4806466f142079cfc428f8823e172/me0116_do_2009.pdf) |
| `archive-small-pref-1.json` | 2026-10-16T07:32:34Z | 200 | 284 | `9416f0a56c61a2dbdee84bab4f20d6c2` | `af5ee9ac89245fcfe60ebac63e76e562e39817982a99809506cbe8eefd9289f8` | [source](https://web.archive.org/cdx/search/cdx?url=www.val.se%2Fval%2Fep2009%2Fstatistik%2Fpersonroster_ovr_2009.skv&output=json&filter=statuscode%3A200&collapse=digest&limit=5) |
| `archive-small-pref-2.json` | 2026-10-16T07:32:48Z | 200 | 299 | `f2650c4f0326ab3e490e7c1346f95959` | `7016d1265974698b7704e40601740791d462b817c66dd63ec8660f0c9ce62935` | [source](https://web.archive.org/cdx/search/cdx?url=www.val.se%2Fval%2Fep2009%2Fstatistik%2Fpersonroster_ovr_2009.xls&output=json&filter=statuscode%3A200&collapse=digest&limit=5) |
| `archived-preferences-ovr-20131031.skv` | 2026-10-16T07:35:40Z | 200 | 1392640 | `a5202c2186e843fdc0290b1101348bfd` | `b468b83f480f3514ae74dbaa8f68a2c0aeaf040994a7141dfa0aed162facdf6e` | [source](https://web.archive.org/web/20131031220930id_/http://www.val.se/val/ep2009/statistik/personroster_ovr_2009.skv) |
| `archived-preferences-ovr-20131031.xls` | 2026-10-16T07:35:42Z | 200 | 4685824 | `a6bbcfcc510da0843cf0c155456f9e80` | `1a3fb38793ed5cc7e34af96c628645c5c9c885dbe6cc72a6d4afb28ca110b7c6` | [source](https://web.archive.org/web/20131031213401id_/http://www.val.se/val/ep2009/statistik/personroster_ovr_2009.xls) |
| `scb-preferences-2009.json` | 2026-10-16T07:41:58Z | 200 | 197031 | `d29766d27504c26acbbebc671b0fe240` | `98e1ba192da891f73b62798e311dbff12b664fffd08f994fa2a8ce8bba2a955b` | [source](https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0109/ME0109A/ME0109T08) |
| `eu-citizens-enrolled-may8.xls` | 2026-10-16T07:49:59Z | 200 | 29184 | `5dc668e32cb2dda574ae7f11d75b3617` | `332d1a98b7edb5afe5ffddc570309a8e8bf114c43b6e9362f562fd4a6d24ab3f` | [source](https://historik.val.se/val/ep2009/statistik/antal_eu-medb_som_valt_att_rosta_i_sverige.xls) |

## Appendix C: current small-party export coverage difference

The complete archived Excel restores the current export's missing 537 rows:
**2 county rows,29 municipality rows,506 ordinary-district rows**. Exact keys
and names are retained locally in `current-small-pref-missing-units.csv`.
All 630895 available numeric cells in overlapping current/archived Excel rows
agree; no missing cell is interpreted as zero. Use the complete original Excel,
not a patched current export.

## Appendix D: SND scope check

[SND VALU2009 EUP](https://researchdata.se/sv/catalogue/dataset/snd0874-1),
DOI10.5878/002163, is a voter exit-poll dataset rather than an administrative
result or candidate register. The catalogue reports7,773 respondents and49
variables. No survey responses were downloaded or used to fill voting returns
or candidate identities. Catalogue HTML is preserved locally with provenance.

| Local response | UTC retrieved | HTTP | Bytes | MD5 | SHA256 | Source |
| --- | --- | ---: | ---: | --- | --- | --- |
| `snd-valu-2009-catalogue.html` | 2026-10-16T08:02:43Z | 200 | 360520 | `fd47ce4a9d28dd579d00ed38ad357cfe` | `3269de7eeb8ee3425d69a3838694da818a77648f2f3a5a144dabce1951cad8b7` | [source](https://researchdata.se/sv/catalogue/dataset/snd0874-1) |

## Post-election archive follow-up and implementation source selection

The user-identified ballot HTML capture9 February2010 at20:55:53 was recovered,
along with its XML link (actual capture10 February2010 at20:32:52):

- https://web.archive.org/web/20100209205553/http://www.val.se/val/ep2009/valsedlar/index.html
- https://web.archive.org/web/20100210203252id_/http://www.val.se/val/ep2009/valsedlar/00E.xml

XML size74728 bytes; SHA256
`45e9c669b0391143366dfe2bf71d3969117f5e8099a5a77b50486b24539dbde4`.
Its own update time is20090607232501. The tree and all non-description attributes
match the current2009 ballot XML exactly;500 candidate-description attributes
are restored. This is now the primary ballot-position/name source, rather than
the redacted current XML. It contains no stable candidate/person ID.

The source establishes that the two Per Johansson entries on list04536 are
distinct: position18 tågförare, Stockholm,48; position32 sjuksköterska, Sundsvall,38.
It does not establish which workbook homonym column belongs to each ballot
position, and does not explain the numerical preference discrepancy. No name-only
linkage or deduplication is approved. The two source columns are retained.

The archived final preference HTML capture10 February2010 at00:08:02 provides
names/votes for the386 main-party positions and links other-party preferences to
separate statistics. It supplies no stable IDs or additional small-party
candidate-level resolution. HTML size53407; SHA256
`168841d09514da7c124f3a8f9637a1431f3938e53468c7dbea552e4bc5ec3ae2`.
The April17 ballot capture returned503 in this bounded follow-up; that response
is not treated as evidence that the source did not exist.

The exact500-to488 physical-person crosswalk is NOT VERIFIED. SCB's PNR-based
person deduplication cannot be reproduced from names alone;500 ballot positions
remain COMPLETE independently of person linkage. See the separate
[completeness](COMPLETENESS_EU_2009.md) and [implementation/validation](VALIDATION_EU_2009.md)
statements for the approved conservative model.

## Confirmed national preference-total reconciliation

The current implementation’s 1,874,130 is the main-11-party component.
Adding the official small-party aggregate of 2,655 gives 1,876,785, exactly
matching both the original final XML and SCB. The apparent large discrepancy
is resolved. The separate national small-party candidate-column sum is 2,665:
its unexplained +10 relative to the official 2,655 remains unresolved and
source values remain unchanged. See [COMPLETENESS_EU_2009.md](COMPLETENESS_EU_2009.md)
and [VALIDATION_EU_2009.md](VALIDATION_EU_2009.md) for the explicit accounting.
