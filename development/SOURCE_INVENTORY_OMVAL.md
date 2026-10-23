# Omval source inventory and implementation assessment

> Source inventory dated 17 October 2026. Original findings below retain their
> date; they are not current activation status. Final results/seats now belong
> to the [unpublished v0.4.1 candidate](releases/v0.4.1.md). The
> [frozen v0.4.0 record](releases/v0.4.0.md) and all source limitations remain
> unchanged. Candidate/preliminary availability here does not promise API support.


Inventory date: 17 October 2026. This is a source review, not an implementation
or a canonical build. Existing production code, canonical assets and original
source collections have not been changed.

## Scope and election occasions

The [Valmyndigheten historical-election guide](https://www.val.se/valresultat-och-statistik/riksdags--region--och-kommunval/tidigare-valresultat)
identifies the following five RD/RF/KF rerun events since 2002:

| Election date | Code | Rerun scope | Preceding ordinary election |
|---|---|---|---|
| 2003-03-16 | KF | Orsa, municipality 2034 | 2002-09-15 |
| 2011-05-15 | RF | Västra Götaland, region 14; five regional constituencies and 49 municipalities | 2010-09-19 |
| 2011-05-15 | KF | Örebro Nordöstra, municipal constituency 188004, within municipality 1880 | 2010-09-19 |
| 2015-05-10 | KF | Båstad, municipality 1278 | 2014-09-14 |
| 2019-04-07 | KF | Falun, municipality 2080 | 2018-09-09 |

No RD rerun is identified in this series. This is not a statement about future
appeal decisions. A separate election series also has the
[Sameting rerun of 5 October 2025](https://www.val.se/servicelankar/servicelankar/pressrum/nyheter--pressmeddelanden/pressmeddelande-nya/2025-07-16-viktiga-datum-for-omval-till-sametinget-2025).
Its [official result](https://resultat.val.se/omvalsame2025/S?r=S) and
[raw-data catalogue](https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-sametingsval)
are identified, but their complete file/record coverage is **NOT VERIFIED** here.
Sameting elections are outside the package's current RD/RF/KF/E/F contracts and
outside the supplied local collections; they must not be misclassified as RF.

Each rerun is a distinct event. None should overwrite the ordinary result.
Örebro is a partial rerun, not a new election in all four municipal constituencies.

## Inventory, preservation and provenance

- [Local file inventory](SOURCE_INVENTORY_OMVAL_FILES.csv): all **54 original
  files, 55,318,698 bytes**, individually listed with purpose, record counts,
  format, MD5, SHA256 and exact current-official matches where established.
  There are 28 files for 2011, 19 for 2015 and seven for 2019.
- [Acquisition ledger](SOURCE_INVENTORY_OMVAL_RETRIEVAL.csv): every attempted
  URL, original linked URL where discovered, effective URL, UTC retrieval time,
  response status, local preservation path, bytes, MD5 and SHA256. It records
  **100 successful responses / 11,350,836 bytes**, plus 75 HTTP 503 and eight
  HTTP 404 responses. Failed response bodies are evidence of access failures,
  not usable election data.
- Newly preserved sources and source-only R diagnostics are isolated under
  `.local-data/omval/source-review-20261017/`. No original file was overwritten.
  The 54 original SHA256 values and all 100 successful response sizes, MD5 and
  SHA256 values were rechecked successfully.
- Existing Orsa recovery is reused under
  `.local-data/rkl/2002/orsa-review-20261012/`, with its original JSON manifest.
  It remains separate from both ordinary-2002 inputs and the new acquisition.
- Every XML member of both local final-result ZIPs was inspected: **291 members
  in each**, one national file and 290 municipality files. Most municipality
  files are placeholders outside the actual rerun. They are not additional
  election events and must not become zero-vote observations in public data.
- Local filesystem dates are not used as historical snapshot dates. Where the
  original download date is unknown, it remains unknown; XML reporting dates,
  archive capture dates and present retrieval dates are recorded separately.

The metadata CSVs contain no raw election tables, named candidate lists, Stata
data or archived objects. The local acquisition/inspection scripts use R only.
Historical `.do` files are source-provenance evidence, not workflow dependencies.

## Final-result controls and geography

These are actual rerun-scope totals, not national placeholder denominators or
Örebro's composite municipality presentation.

| Event | Ordinary districts | Collection units | Valid | Ballots cast | Invalid, including blank | Eligible | Seats | Reported preference votes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Orsa 2003 KF | 5 | 1 | 4,303 | 4,316 | 13 | 5,413 | 31 | 1,904 |
| Västra Götaland 2011 RF | 957 | 68 | 545,215 | 548,950 | 3,735 | 1,246,191 | 149 | 122,945 |
| Örebro Nordöstra 2011 KF | 23 | 1 | 17,335 | 17,512 | 177 | 27,645 | 17 | 5,280 |
| Båstad 2015 KF | 9 | 1 | 7,494 | 7,552 | 58 | 11,874 | 41 | 2,949 |
| Falun 2019 KF | 36 | 1 | 27,788 | 27,999 | 211 | 45,911 | 61 | 7,994 |

The 2011 final comparison SKVs have 1,025 RF and 24 KF rows, with no duplicate
county/municipality/reporting-unit keys. Their valid, cast and electorate sums
match the local final protocols exactly. RF blank = 3,410 and other invalid =
325; KF blank = 154 and other invalid = 23. The column `OG` in these SKVs is
**other invalid**, not all invalid ballots. Collection-unit electorates are
blank, not zero.

The Båstad and Falun XML ordinary-plus-collection valid-vote sums equal the
municipality totals exactly; their preference-vote area totals sum to 2,949 and
7,994. The local protocols independently report the same municipal controls.
Båstad has 41 `VALD` records and 28 substitute records representing 24 distinct
source IDs. Falun has 61 `VALD` records and 35 substitute records/IDs. These
match their 41/61 allocated seats: no unfilled position is indicated by these
counts. Substitute records are relationships, not necessarily distinct people.
Orsa XML has 31 `VALD` and 28 substitute records. Orsa's protocol attachment
cross-check remains outstanding, as specified below.

For 2011, the legal protocols specify 149 regional and 17 Nordöstra seats.
A complete machine-readable elected/substitute identifier reconciliation has
not yet been performed; the existence of the full protocol annexes is not
misrepresented as a completed candidate-by-candidate validation.

## 2003: Orsa is embedded in the 2002 website

Primary preserved rerun XML:

- Original URL: `http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml`.
- [Archived official file, capture 2003-04-26 22:32:58](https://web.archive.org/web/20030426223258id_/http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml).
- Recovered on 2026-10-12T09:47:01Z; **133,680 bytes**.
- MD5 `816b7a5f0ce4028dd31af9d18b259113`.
- SHA256 `2ed9f72f36cbbb2b682d42d7a299a388b2c394d9ee4e3b393c46c9cd1fe4775c`.
- Root `TILLFÄLLE="Omval 16 Mars 2003"`; report time `20030320111615`.
  This differs from the preserved ordinary-election XML, captured January 2003.

The [current Orsa result](https://historik.val.se/val/val_02/slutresultat/20K/2034/2034.html),
its text version and `203400.html`, `203400-lista.html`, `203400-totalt.html`
provide rerun result/ballot/preference structures. They are not the ordinary
September-2002 result. The result XML covers municipality, technical whole-
municipality constituency `203400`, five ordinary districts and `K-2034-00`.
The latter contributes 110 valid votes / 111 cast. Do not invent electorate or
turnout for this collection unit. The combined invalid total is available;
separate blank/other-invalid counts are not provided by this XML.

The XML has list and candidate-position/name structures, person-vote records,
31 elected and 28 substitute relations, but **no `KANDNR` person identifier**.
Its 959 `PERSONVAL` nodes repeat observations at different geographic/list
views; 959 is not a count of distinct candidates. A complete stand-alone rerun
ballot-candidacy register, including candidates without result records, has
not been recovered. Do not substitute the ordinary-2002 register or infer
identity from names. Reuse the 2002 source-observation approach.

The current election-night branch also contains the **2003 rerun**, with report
time 2003-03-16 22:44 and turnout 77.6%, distinct from final turnout 79.7%.
A complete preliminary collection snapshot is not verified. Final collection
figures cannot be used to make one. Comparison fields point to an older
ordinary election, not automatically to September 2002.

### New legal-protocol discovery

A targeted CDX query recovered the official protocol wrapper captured at
[2003-04-26 22:35:38](https://web.archive.org/web/20030426223538id_/http://www.val.se:80/val/val_02/protokoll/slutresultat/2034K.html).
It explicitly links the signed county decision and seven annexes:

`huvudprotokoll-248.pdf`, `bilaga_1-248.pdf`, `bilaga_2-248.pdf`,
`bilaga_3-248.pdf`, `bilaga_4-248.pdf`, `bilaga_5-248.pdf`,
`bilaga_6-248.pdf`, `bilaga_7-248.pdf`, under
`http://www.val.se/val/val_02/protokoll/slutresultat/`.

The wrapper is preserved. All eight attempted archive attachment requests
returned 404; current historical-mirror requests returned 503. A narrow archive
index query for those attachment names returned no captures. This establishes
**eight unrecovered protocol attachments**, not that they never existed.
Requesting these exact files from the authority is the next bounded recovery
step; the wrapper must not be described as the actual signed decision.

The 2002 statistics-index requests returned 503. No separate Orsa-2003
handwritten-designation, electorate-composition, full candidacy or advance-
voting raw file was established. Their absence from this inventory is a
recovery/verification gap, not proof that no such statistics were produced.

## 2011: detailed official statistics and partial-election scope

Start from the preserved [official statistics index](https://historik.val.se/val/om2011/statistik/index.html).
All linked SKV/XLS/XML resources were inventoried and acquisition attempted.
Successful equivalents and already-local originals are retained when another
format returned 503. Exact successful URLs and failures are in the ledger.

| Source family | Use for swelections | Boundary |
|---|---|---|
| `slutlig2011_{vg,orebro}_jmf2010_{antal,andel,mandat}.{skv,xls}` | Final party votes, denominators, district/collection coverage, seat controls | Select 2011 columns; do not import difference/2010 columns as observations |
| `valnatt2011_{vg,orebro}_jmf2010_{antal,andel,mandat}.{skv,xls}` | Separate election-night snapshot and comparison controls | Not verified as full preliminary including collection votes |
| `kandidaturer_{vg,orebro}.{skv,xls}` | Ballot/list candidacies, source candidate numbers, list positions, status, age/sex | SKV is headerless; do not lose the first candidate |
| `handskrivna.{skv,xls}` | 193 designation/location records in the local SKV; investigate smaller-party detail | Not an independent candidate register |
| `rostberattigade_{vg,orebro}.{skv,xls}` | District age/sex/citizenship and first-time-voter controls | Statistics page uses election day 2011-05-15 and comparison date 2006-09-17 |
| `vallokal.{xml,skv,xls}`, `rostlokal.{xml,skv,xls}`, `rostlokal_oppet.{skv,xls}` | Geography validation and potential future voting-place data | Opening times/RT90 and advance-voting locations are auxiliary to the seven functions |
| `mottagna_fortidsroster.{skv,xls}` | Received advance ballots per location/day | Not counted votes, turnout, or a preliminary result |
| `protokoll_14L.pdf`, `protokoll_1880K.pdf` | Authoritative final decision, party/list votes, seats, elected/substitute annexes | Local duplicates are byte-identical; recovered official PDFs match the local originals |

The XML links on the statistics page are **voting-location XML**. The format
legend also mentions ZIP, but does not itself establish a final-result XML ZIP
link. Bounded probes of the usual result/XML archive path families returned
503. No usable 2011 final-result XML archive was recovered in this review.
Do not present guessed paths as verified sources. Exact raw party results are
nevertheless available in the official comparison SKVs and protocol annexes.

VG has **7,420 candidacy rows, 1,401 distinct source candidate numbers, 52 list
numbers and 15 party labels**. Örebro has **342 rows/IDs, eight list numbers
and eight party labels**, restricted to Nordöstra. These are source-ID counts,
not independently verified physical-person counts. Electorate files have
957 RF rows and 82 Örebro district rows; Örebro includes zero-filled out-of-
scope constituency rows. Those must not become eligible-voter zeroes for
actual 2011 elections outside Nordöstra. The polling-place file has 980 rows.

**Critical composite:** Örebro's whole-municipality HTML/protocol summary is
explicitly 2010 results in Sydöstra, Sydvästra and Nordvästra plus 2011
Nordöstra. It reports 81,581 valid / 82,754 cast / 105,587 eligible / 65 seats.
Those are useful post-rerun council controls, not the 2011 rerun population.
Use 17,335 / 17,512 / 27,645 / 17 for the rerun itself. Retain constituency
188004; do not expose a misleading whole-municipality 2011 turnout of 78.38%.

Local `valdist_ko2011.dta` (5,958 rows), `valdist_lt2011.dta` (5,918), and the
long-party tables (81,187 KF / 93,909 RF rows) cover broader national geography.
The VG-only wide table has 1,006 rows, whereas official final SKV has 1,025.
The 19-row difference is explained: both contain the same 957 ordinary-district
keys and valid-vote values, but the wide file combines the 68 official collection
units into 49 municipality-level `9800` / `ÖÖ` rows. All 49 combined valid-vote
values equal the official constituent-unit sums exactly. It is useful as an
aggregate control, but cannot replace the original 68 collection observations.
The wider files' derivation and source authentication remain NOT VERIFIED;
these local derived files are not independently established SCB inputs.

## 2015: Båstad

[Statistics and raw files](https://historik.val.se/val/omval2015/statistik/index.html)
link final XML, candidate, seat, handwritten, electorate and voting-place material.
The complete local ZIP is pinned by SHA256
`efd915e8061c6673193e039214ea18dce6ae2fdee04a66b437fb7e4b3037d448`.
Use its `slutresultat_1278K.xml`, not zero-vote placeholder municipalities.
The local signed final protocol is 3,910,169 bytes. Its current official URL
now returns a 7,501-byte PDF containing only **Protokoll gallrat**. Preserve the
local complete protocol; replacing it with the newer PDF would destroy evidence.

The headerless candidacy file has **198 list-position records / 185 source IDs**.
XML person-vote records contain 163 distinct IDs. Six result IDs are absent
from that candidacy file: **1259, 1255, 1392, 1256, 1349, 1341**. ID 1259 also
appears as a substitute; all 41 elected IDs occur in the ballot file. The union
contains 191 source IDs. Preserve result-only candidates and relationships;
do not drop them in a ballot-file inner join. The cause of the file-population
difference is **NOT VERIFIED**; it is not resolved as withdrawal or a later
change merely from the filenames. Ballot coverage beyond the preserved
snapshot is therefore not certified as a complete election-result population.

The two Stata `.do` files explicitly derive local candidate/elected datasets
from Valmyndigheten material. `AV2015_kand_ko.dta` and `AV2015_valda.dta`
are useful reproduction controls (198 and 41 rows), not independent SCB evidence.
The six-row handwritten file and XML handwritten structures provide designation
information. The electorate file contains nine district rows. Received-advance-
vote and voting-place files are auxiliary, not substitutes for final vote counts.

The election-night page has a reported result, but the retrieved `prelresultat`
municipality and collection pages contain only the pre-count start message.
Thus **complete preliminary collection results are INCOMPLETE in the recovered
collection**: the one required collection-unit preliminary result is missing.
No final-count replacement is legitimate.

## 2019: Falun

[Statistics and sources](https://historik.val.se/val/omval2019/statistik/index.html)
include candidates, participating parties, locations and advance-vote files.
The complete preserved ZIP has SHA256
`702ced856dd50171b7674d16949ec6eb3746cb59e5210fe866b692065cfad314`.
Use `slutresultat_2080K.xml`. The local full protocol is 4,325,211 bytes;
the result page labels the current protocol as redacted and its retrieval
returned 503. The locally retained original is necessary for decision checks.

The candidate file has **490 rows / 300 source IDs**, with 483 `GILTIG=J`
and seven `GILTIG=N` rows. These counts are different populations: preserve
status and consent/list distinctions. XML person-vote records contain 260 IDs;
all person-vote, elected and substitute IDs occur in the candidate file.
The current candidate download also has 490 rows. A row-by-row comparison
found exactly two changing columns: all names become `Namnet gallrat`, and
`VALKRETSKOD` changes `00` to `0`. The other 22 columns agree. This is not
an extra/missing-candidate discrepancy. Pin the preserved original and document
the later redaction/formatting snapshot; apply the established public-name
policy explicitly when implementing, not through accidental file replacement.

**Preliminary recovery:** all **36 ordinary district pages plus the one
collection page** have now been preserved separately from final XML.
Their 37 reported valid-vote totals sum exactly to the preliminary municipality
page's **27,518**, including **442** in the collection unit. Reported blank
cells sum to 167 and reported other-invalid cells to 293, matching the aggregate.
One district blank-category cell and six other-invalid cells are empty; this
review has not converted them to zero. Their encoding/missingness must be
handled explicitly during implementation. This verifies the reporting-unit
population and valid-vote aggregation, not every candidate field at that stage.
The preserved collection page is the actual preliminary snapshot, not the final
collection count (477 valid).

## Cross-source limitations and discrepancies to preserve

1. **ZIP scope and denominators:** national XML nodes in the 2015/2019 ZIPs
   report only rerun votes but electorates of 7,623,640 / 7,861,671. These are
   not rerun electorates; exclude them from turnout. Non-rerun municipality
   XML files contain placeholders. Restrict all extraction to the event registry.
2. **Comparison metadata:** 2015 root `VALDAG_FGVAL=20100919`, 2019 root
   `VALDAG_FGVAL=20140914`; the 2019 HTML also labels comparisons 2014.
   These are not the preceding ordinary-election dates (2014 and 2018).
   Preserve the raw labels and do not use them to infer the parent event or
   silently relabel comparison columns. Detailed comparison populations remain
   NOT VERIFIED and are not required to construct current rerun outcomes.
3. **Candidate population:** retain the six Båstad result-only IDs; do not
   resolve their meaning through name matching. No identity harmonisation has
   been proposed or applied in this review.
4. **Current downloads versus preserved originals:** a redaction notice is
   not a replacement decision protocol; 503 is not evidence of source absence.
5. **Counting stages:** election night, preliminary collection and final
   collection are separate snapshots. A navigation tab is not proof of data.

## SCB/SND independent validation

The preserved [SCB 2011 turnout study](https://www.scb.se/publikation/18393)
confirms the two rerun scopes and approximate turnout (44.0% RF / 63.3%
Nordöstra). It is a commissioned study, not automatically an official-statistics
microdata file. SCB's result news and the VM experience report are also preserved.
These support scope/aggregate checks, not a completed independent party-by-party
or candidate-by-candidate reconciliation.

[SCB candidate documentation for 2014](https://www.scb.se/contentassets/4df37246f586465991189fc7d4f1593d/me0107_do_2014_jo_190114.pdf)
explicitly describes the Båstad 2015 candidate population and revised frames:
new ballots can introduce/remove parties and candidates. It must not be
validated against the original-2014 candidate population without scope control.
[SCB's 2018 quality declaration](https://www.scb.se/contentassets/4df37246f586465991189fc7d4f1593d/me0107_kd_2018_jo_190613.pdf)
identifies Falun's 7 April 2019 rerun and separately available ordinary/rerun
statistics. Both documents were preserved with checksums.

For Orsa, existing SCB 2002 table footnotes include the 2003 rerun in later
published 2002 totals; that convention cannot change the package's distinct
occasion model. See [the prior Orsa comparison](SOURCE_INVENTORY_2002.md).
No separately authenticated SND rerun collection was identified in the supplied
folders. Independent exact SCB/SND totals and populations are **NOT VERIFIED**
for all seven functions; obtain event-specific tables before claiming that
validation. The historical `.dta` filename alone cannot establish independence.

## Completeness matrix: sources, not current API support

**COMPLETE** means the stated source population has been counted/covered.
**INCOMPLETE** means identified source coverage is missing.
**NOT VERIFIED** means complete coverage/reconciliation has not been established.
The package does not currently route these rerun events through its year registry.

| Dimension | Orsa 2003 KF | VG 2011 RF | Nordöstra 2011 KF | Båstad 2015 KF | Falun 2019 KF |
|---|---|---|---|---|---|
| Final reported party/category votes and geographic units | COMPLETE: 5+1 | COMPLETE: 957+68, 49 municipalities, 5 constituencies | COMPLETE: 23+1, one rerun constituency | COMPLETE: 9+1 | COMPLETE: 36+1 |
| Final valid/cast/total electorate | COMPLETE | COMPLETE | COMPLETE: rerun scope only | COMPLETE | COMPLETE |
| Separate blank/other-invalid fields | INCOMPLETE: XML provides combined 13 only | COMPLETE: 3410/325 | COMPLETE: 154/23 | COMPLETE: 58/0 | COMPLETE: blank174, unregistered8, remaining29 |
| Allocated mandates | COMPLETE: 31 XML; protocol cross-check NOT VERIFIED | COMPLETE: 149 protocol | COMPLETE: 17 protocol | COMPLETE: 41 XML/protocol | COMPLETE: 61 XML/protocol |
| Ballot-candidacy register | INCOMPLETE: no complete rerun register recovered; number of absent candidacies unknown | NOT VERIFIED: 7420 rows preserved; result-ID union not checked | NOT VERIFIED: 342 rows preserved; result-ID union not checked | NOT VERIFIED: 198 rows/185 IDs, six additional result IDs | COMPLETE for preserved 490-row status-bearing snapshot; not 490 valid candidates |
| Candidate-result source coverage | NOT VERIFIED: XML records present, no full list-population reconciliation | NOT VERIFIED: detailed HTML/protocols, no result XML acquired | NOT VERIFIED: detailed HTML/protocols, no result XML acquired | COMPLETE for reported XML IDs (163 preference IDs); retain union with ballot file | COMPLETE for reported XML IDs (260 preference IDs) and ballot links |
| Elected/substitute source relations | COMPLETE XML: 31/28; legal attachment reconciliation NOT VERIFIED | NOT VERIFIED: full protocol annexes present, exact relationship extraction pending | NOT VERIFIED: full protocol annexes present, exact relationship extraction pending | COMPLETE XML: 41/28 relationship records | COMPLETE XML: 61/35 relationship records |
| Reported final preference observations | NOT VERIFIED: all six XML units present; list/area reconciliation pending | NOT VERIFIED: candidate/party pages and protocol annexes require complete extraction | NOT VERIFIED: candidate/party pages and protocol annexes require complete extraction | NOT VERIFIED: all ten units present; candidate/list aggregation checks pending | NOT VERIFIED: all 37 units present; candidate/list aggregation checks pending |
| Full preliminary, including collections | NOT VERIFIED: no complete collection snapshot identified | NOT VERIFIED: night files do not establish collection coverage | NOT VERIFIED: night files do not establish collection coverage | INCOMPLETE: one preliminary collection result unrecovered; fetched page is empty | COMPLETE reported geography/valid totals: 36+1; empty category semantics need explicit treatment |
| Independent exact SCB/SND reconciliation | NOT VERIFIED | NOT VERIFIED beyond published rounded turnout/scope | NOT VERIFIED beyond published rounded turnout/scope | NOT VERIFIED: event-specific frame established | NOT VERIFIED: event-specific frame established |

No identified party hidden within an aggregate is fabricated. COMPLETE party
results means complete **reported categories**, including residual other-party
categories; it is not a claim that all handwritten designations or candidate
preferences have already been individually disaggregated. For the 2011
handwritten file, 2015 handwritten file and XML handwritten structures, complete
category-to-designation reconciliation is **NOT VERIFIED**. For Orsa no separate
handwritten file was recovered; for Falun no separate handwritten raw file was
established from the statistics index. These are explicit extra-detail gaps.

Election-night sources are identified for all four years, with official raw
comparison tables for 2011. A complete separately preserved night-stage district
population is NOT VERIFIED for every event. No mandate-period history has been
established; the protocol election result must not be expanded with later members.

## Proposed implementation and release gates

1. **Use existing event fields.** `election_event`, `election_year`,
   `election_date`, `election_kind` and `election_code` already exist. Represent
   the five events separately, with the actual year/date and rerun kind. Store
   the link to the original ordinary event in the provenance manifest first;
   no new public argument or general event schema is needed just for these cases.
   The supported-year registry/readers still need implementation; existing fields
   do not imply the API already accepts reruns. Distinguish 2019 KF from 2019 EU
   and 2003 KF from the 2003 referendum by election code and event.
2. **Use an explicit geographic scope registry.** Örebro 2011 contains only
   municipal constituency 188004. A municipality aggregation may describe that
   rerun scope but must not imply an election of all 65 seats. Carry the specific
   constituency context and reject interpretations mixing the other three 2010
   constituencies. VG is one regional event across five constituencies, not five
   independent elections. Never ingest out-of-event ZIP placeholders.
3. **Reuse XML infrastructure conservatively.** Orsa fits the 2002 source-
   observation structures; Båstad/Falun fit the 2014/2018 XML family, including
   list positions, `KANDNR`, election order, preference qualification and
   substitute relations. Preserve their metadata differences. For 2011, build
   results/seats from verified SKV and protocols if result XML remains inaccessible;
   do not claim full candidate/preference support before complete extraction.
4. **Support all seven functions only with explicit populations.** `results()`
   and `seats()` have verified final controls for all five events. `candidacies()`
   uses documented rerun ballot records; `candidates()` additionally retains
   official result/elected/substitute records, including Båstad's six extra IDs.
   `elected()` and `substitutes()` preserve the fixed protocol relationships;
   `preference_votes()` preserves source observations/levels without deduplicating
   by names or summing multiple geographic views. No cross-election physical-
   person identity is inferred. Orsa's complete ballot population remains an
   explicit gap, not something to manufacture from result rows.
5. **Keep stages truthful.** Falun can use its preserved preliminary 36+1
   snapshot after category/key validation. Do not expose complete preliminary
   support for the other events merely because election-night or final data exist.
   Do not introduce a new public `election_night` value in this inventory task.
6. **Before building:** recover Orsa's eight exact legal attachments if possible;
   finish 2011 candidate/list/preference extraction or obtain result XML; reconcile
   Båstad's result-only IDs without dropping them; obtain event-specific SCB
   controls; validate every district/collection/constituency party total, ballot
   accounting, candidate keys/list positions, seats/filled/unfilled relationships,
   preference sums and missingness. Then exercise all seven functions, standard/
   full, English/Swedish, raw/canonical equivalence and Parquet round-trip, with
   unchanged ordinary-election references.

No production implementation, canonical build, commit, push, tag or release
was performed. The inventory is ready for review; the NOT VERIFIED entries
above must remain visible when deciding the implementation scope.
