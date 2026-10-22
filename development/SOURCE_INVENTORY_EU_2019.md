# Source inventory: European Parliament election 2019

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


Assessment date: 2026-10-15. Election occasion: **26 May 2019**.
This is a source inventory and independent R audit only. No production reader,
public API support, canonical build, commit or push is part of this assessment.
All original files remain unchanged; newly acquired sources are local/ignored.

## Decision summary

The preserved official sources support **COMPLETE final results**, including
all separately disclosed smaller-party votes, **COMPLETE reported preference-vote
observations**, **COMPLETE documented candidacies**, and **COMPLETE original
mandates/elected/substitute relations**. The full preliminary XML snapshot is
also **COMPLETE**, including all Wednesday units. No collection-page recovery
is needed before implementation.

There is no EU-2024-style unexplained missing candidacy: local and current public
candidate files have identical candidate/party/list/position keys and validity
flags. Names are redacted in the current public file. Preserve the named local
snapshot as provenance; do not assume that source availability authorises a
different public name contract for local and remote use.

Two operational qualifications are explicit: the currently linked final XML ZIP
and original protocol return HTTP 404, although the complete final ZIP is already
preserved locally; and a full mandate-period event history has not been verified.
Neither is missing fixed-election-result data. A future remote implementation
must not silently rely on the broken final ZIP endpoint.

## 1. Sources, provenance and format

Authoritative source for election results: Valmyndigheten. SCB is an independent
control and a complementary source for electorate composition. SND survey data
must not be mistaken for administrative counts.

Official entry points:

- [Historical statistics and source documentation](https://historik.val.se/val/ep2019/statistik/index.html).
- [Final presentation](https://historik.val.se/val/ep2019/slutresultat/E/rike/index.html),
  [original elected/substitute presentation](https://historik.val.se/val/ep2019/slutresultat/E/rike/valda.html),
  [preference votes](https://historik.val.se/val/ep2019/slutresultat/E/rike/personroster.html).
- [Full preliminary presentation](https://historik.val.se/val/ep2019/prelresultat/E/rike/index.html).
- [Valnatt branch](https://historik.val.se/val/ep2019/valnatt/E/rike/index.html).
- [SCB result tables](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/)
  and [candidate statistics](https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/).

### Complete pre-existing local inventory

There are **12 original files** under `.local-data/eu/2019/`, excluding this
investigation's new audit directory. Original retrieval times are not known.
The preserved filesystem timestamps are evidence of file metadata, not invented
retrieval dates. Exact timestamps, sizes, MD5 and SHA256 are retained in the local
`review-20261015/original-files.csv`; hashes are also listed below.

| Relative path | Structure and purpose |
| --- | --- |
| `kandidater/kandidaturer.skv` | Windows-1252, semicolon-delimited; 562 rows x 24 fields. Named official historical candidate/candidacy snapshot, valid/invalid status, party, lists, position, consent/declaration, age/sex, registered municipality, ballot text and ordered ballots. Filesystem modification: 31 May 2019. |
| `rostning/mottagna_fortidsroster.skv` | 2,536 rows x 26 fields. Registered early votes by reception location/date; not an additional result-count component. |
| `rostning/rostlokal.skv` | 2,534 rows x 38 fields. Early-voting reception locations, addresses, opening times and coordinates. |
| `rostning/vallokal.skv` | 5,984 rows x 31 fields. Ordinary polling locations/district geography and premises. |
| `valresultat/deltagande_partier.skv` | 103 rows x 17 fields; 87 distinct official party codes. Registration/participation metadata; repeated source records must not be counted as additional parties. |
| `valresultat/deltagande_partier_per_valomrade.skv` | 87 rows x 7 fields. Parties participating in the national election area; labels, abbreviation and notification/registration status. |
| `valresultat/ep2019_antal_eu-medborgare_2019-03-11.xlsx` | Two sheets; county table has 21 counties plus total. Dated 11 March, with 32,941 registered and 240,574 not registered EU citizens. These are not election-day eligible-voter totals. |
| `valresultat/ep2019_rostfordelning_per_kommun.xlsx` | Metadata sheet plus counts/percentages: 290 municipalities x 44 fields. Official metadata sheet dated 5 June 2019. |
| `valresultat/ep2019_rostfordelning_per_valdistrikt.xlsx` | Metadata sheet plus counts/percentages: 6,305 units x 46 fields, including Wednesday units. Metadata dated 5 June 2019. |
| `valresultat/prelresultat.zip` | 294 members: national XML, 290 municipal XMLs, `Filer`, `Cksum`, binary `Signatur`. XML size 13,416,942 bytes. Full preliminary snapshot generated 29 May 2019. |
| `valresultat/rostberattigade.skv` | 5,984 ordinary districts x 28 fields, including 20 age/sex/citizenship counts. Older snapshot totals 7,577,900, not the final electorate. Filesystem modification: 7 May 2019. |
| `valresultat/slutresultat.zip` | 294 members: national XML, 290 municipal XMLs and the three provenance members. XML size 135,801,978 bytes. National root generated 31 May 2019 20:52:08; national vote report 13:45:19 and mandate report 13:56:45. |

All 291 XML filenames in each `Filer` member are present, with no missing
municipality. The total XML byte length equals the length recorded in `Cksum`.
The POSIX checksum value and binary signature have **not** been independently
verified; SHA256 is recorded for the preserved ZIPs. Do not describe signature
verification as completed.

### Additional official material preserved

Audit copies are under `.local-data/eu/2019/review-20261015/web/`. Each successful
retrieval has original/effective URL, UTC retrieval timestamp, response size,
MD5 and SHA256 in `retrieval.csv`; the complete record follows in the appendix.
Downloads were sequential and cached. No existing original file was overwritten.

Important additions:

- Current official candidate SKV: 562 rows, with all `NAMN` entries replaced by
  `Namnet Gallrat`, including the six invalid rows. IDs and validity remain.
- Current preliminary ZIP and municipal/district workbooks: **byte-identical**
  to their local originals.
- Current official electorate SKV, from the actual statistics-page link:
  [rostberattigade.skv](https://historik.val.se/val/ep2019/alkon/E/rostberattigade.skv).
  Its 5,984 district denominators match final XML individually.
- [Handwritten-party workbook](https://historik.val.se/val/ep2019/handskrivna/handskrivna.xls):
  1,985 rows x 11 fields, 34 party labels, 2,315 valid votes, 1,750 units in
  269 municipalities. It exactly exhausts the XML residual at every unit;
  the other 21 municipalities have no such positive residual.
- SCB county, district, small-party, national and citizenship/residence tables,
  plus the nominated/elected candidate overview and candidate-table metadata.
- National final/preliminary/valnatt/elected/preference presentations and the
  official English 2019 result summary, retained as dated page snapshots.

The final ZIP link and protocol link currently return **404**:
`https://historik.val.se/val/ep2019/slutresultat/slutresultat.zip` and
`https://historik.val.se/val/ep2019/slutresultat/protokoll/protokoll_00E.pdf`.
A direct national final XML path also returned 404. This is current recovery/
access availability, not missing substantive data in the preserved archive.

No local 2019 SCB/SND folder or SND result file was found. The located
[SND 2019 announcement](https://snd.se/sv/nyheter/nya-eu-valdata-publicerade)
concerns voter/exit-poll research data, not a district result register. No SND
administrative-result comparison has been established; SCB controls are available.
Linked GIS and 2014-2019 district-mapping ZIPs exist as additional reference
links but were not needed/downloaded to establish the result populations.

## 2. Final results and smaller parties

| Measure | Final value |
| --- | ---: |
| Valid party votes | 4,151,470 |
| Invalid ballots, total | 36,378 |
| Invalid: blank | 30,712 |
| Invalid: parties without participation notification | 1,709 |
| Invalid: other | 3,957 |
| Ballots cast | 4,187,848 |
| Eligible voters | 7,576,917 |
| Turnout | 55.2711346844634% (published 55.27%) |
| Officially disclosed positive party identities | 66 |

The final XML separately identifies 32 parties, totalling **4,149,155** votes.
Its remaining **2,315** valid votes are aggregated under `HANDSKRIVNA`; the
separate official workbook identifies them under another **34 party labels**.
All 34 labels match exactly to unique official numeric party codes in the
preserved participation register. Thus all 66 positive party identities can be
supported without an invented party crosswalk or an undisclosed residual.
Do not add these 2,315 to valid votes again: replace the already included XML
residual with its documented breakdown. They are ordinary party votes, not
candidate preference votes. The workbook includes a party called **Blankt**
(92 votes); this is distinct from invalid blank ballots (`BLANK`, 30,712).

The XML's main `ÖVRIGA_GILTIGA` total is 45,091, including the separately reported
smaller-party children and the handwritten residual. It must not be added on top
of those children. SCB's eight-major-party grouping instead has **103,760**
other-party votes = FI 32,143 + PP 26,526 + XML other parties 45,091. This is a
category-definition difference, not conflicting results.

All 6,305 rows of the official district workbook and all 290 municipal rows
match XML ballot totals and all disclosed party-count columns. A reader detail
matters: automatic `readxl` guessing classifies the very sparse `1431`, `SKÅ`
and `TRP` district columns as logical because their initial rows are blank.
That loses counts above one in 30 cells. Native sheet XML stores numeric values
correctly; explicitly reading vote columns as numeric resolves every comparison.
This is a parsing hazard, **not a difference in the official vote values**.

## 3. Geographic coverage

| Geography | Final units | Preliminary units | Interpretation |
| --- | ---: | ---: | --- |
| Country | 1 | 1 | `NATION`, code `00`, the single EU mandate area |
| Counties | 21 | 21 | `LÄN`; do not drop Gotland or call these 20 RF election areas |
| Parliamentary constituencies | 29 | 29 | `KRETS_RIKSDAG`, additional statistical reporting geography, not 29 EU constituencies |
| Municipalities | 290 | 290 | National hierarchy agrees with municipal files |
| Actual municipal constituencies | 53 | 53 | 22 divided municipalities |
| Undivided technical municipal containers | 268 | 268 | Codes ending `00`; not additional public constituencies |
| Ordinary districts | 5,984 | 5,984 | Eligible-voter denominators present |
| Wednesday units | 321 | 321 | `ONSDAGSDISTRIKT`; codes such as `E-0114-00` |
| All counted district/Wednesday units | 6,305 | 6,305 | Exactly the national declared population |

There are no missing or duplicated geographic keys in either snapshot. All
290 municipality totals match the sum of their disjoint ordinary and Wednesday
units for valid votes and ballots cast. County and parliamentary-constituency
aggregates sum to the national result. Wednesday units are explicitly nested
under the source municipal-constituency containers; retain these real source
relationships rather than inventing an allocation.

Wednesday nodes omit `VALDELTAGANDE`/electorate/turnout, but report valid votes
and each invalid category. Their ballots cast can be derived exactly as valid
plus the three invalid categories. Their lack of an independent electorate is
structural, not an uncounted election-result population. Keep their electorate
and turnout missing.

SCB has **6,274** rows: 5,984 ordinary districts plus 290 merged municipal
Wednesday/postal units. All ordinary denominators, cast/valid/invalid/blank
values match. The 321 Valmyndigheten Wednesday units reconcile exactly to the
290 SCB units by municipality. These are different reporting partitions, not
31 missing districts.

## 4. Preliminary versus election-night

The available preliminary ZIP is already the **full preliminary snapshot**:
5,984 ordinary districts plus all 321 Wednesday units. All units have reported
valid counts and all three invalid categories; there are no wholly unreported
or partially blank vote-category units in this snapshot.

| Measure | Ordinary units | Wednesday units | Full preliminary |
| --- | ---: | ---: | ---: |
| Valid votes | 3,982,868 | 143,853 | 4,126,721 |
| Ballots cast | 4,038,870 | 147,731 | 4,186,601 |

Preliminary invalid categories are blank 29,923, no participation notification
2,549 and other invalid 27,408 (total 59,880). Eligible voters are 7,576,917.
Ten parties plus an aggregate other-party category are reported. Do not copy
final detailed smaller-party votes into the preliminary stage.

The XML national totals and all **21 county x 15 count** controls agree with
the current official preliminary presentation. The same 315 county controls
also pass for final results. The preliminary ZIP is byte-identical to the
currently downloadable official file. No final Wednesday values were used.

The separate valnatt national URL responds 200 but its vote/mandate/denominator
cells are blank. The ordinary-district component of preliminary XML is available
separately, with election-night reporting timestamps, but it does not by itself
establish a separately frozen national election-night snapshot. That separate
freeze is **NOT VERIFIED**; no extensive archive recovery was attempted. It does
not block complete preliminary or final support.

## 5. Candidacies, identifiers and names

| Population / field | Exact coverage |
| --- | ---: |
| All documented candidacy rows | 562 |
| All distinct candidate numbers, including invalid rows | 560 |
| Valid candidacy rows / valid candidate numbers | 556 / 556 |
| Invalid candidacy rows | 6 |
| Valid rows on `S` ballots | 529 |
| Valid ordered-only `B` rows | 9 |
| Valid consent-only rows without list | 18 |
| Candidate-file parties / list numbers | 43 / 33 |
| SCB nominated / originally elected persons | 556 / 20 |

[Valmyndigheten's documentation](https://historik.val.se/val/ep2019/statistik/index.html)
defines candidate number as unique at this election occasion and explains
`ORDNING` as candidacy position, `S` as sent to the printer, `B` as ordered,
and the consent/declaration/validity flags. IDs support source-based joins;
names must not be used for identity. IDs alone do not establish longitudinal
person identity across election occasions.

After explicitly normalising national `0` versus `00` formatting, all 562
local/current keys match on election, geography, party, list, position and
candidate number. No candidacy, list, position, consent or validity changes
were found. Exactly three fields differ: the two national-code columns and
`NAMN` (562 redactions). No administrative-status explanation is required.
Public names must not be recovered silently from the named local file; the
historical 2018-style public `NA_character_` name contract is recommended.

Two IDs have a valid and invalid candidacy for different parties:

- 534260: invalid `1351 / 17266 / position 3`; valid consent-only 1140.
- 534261: invalid `1351 / 17266 / position 1`; valid consent-only 1140.

This is not evidence for two physical people sharing an ID. Keep the explicit
party/candidacy validity. An ID-only join would be wrong. No identity rule is
introduced by this inventory.

The only candidate-file list absent from final list-result structures is
**1433 / 17274**, Volt Sverige: nine valid `B` rows, not `S`. Volt is nevertheless
identified in the handwritten-party vote workbook (146 votes). Keep these nine
ordered candidacies and their status; do not assert a sent-to-printer ballot
or invent candidate preference observations.

## 6. Preference votes

| Source scope | Positive list/candidate observations | Votes |
| --- | ---: | ---: |
| Ordinary districts | 393,842 | 1,574,706 |
| Wednesday units | 16,466 | 59,890 |
| Complete disjoint district population | **410,308** | **1,634,596** |
| National | 518 | 1,634,596 |

All 6,305 source units have reported positive observations. National party-level
and list-level structures represent the same votes and must not be added.
The same is true of district-level party/list representations. County sources
have 8,185 positive candidate/party rows and the same 1,634,596 total. Candidate
and list detail is not directly reported at municipal or municipal-constituency
aggregate nodes, but can be aggregated from the verified disjoint district
records. This is a derivation, not missing source observations.

Every national list/candidate total equals the sum of ordinary/Wednesday
records. All **78,323 explicit list-person-vote controls**, including zero totals,
reconcile. No duplicate district/list/candidate keys occur. Every positive list
observation matches the candidate file on party, list, ID and ballot position;
there are no unmatched result-only positive candidate records.

`PERSONVAL@ORDNING` is preference-vote rank (including ties).
`PERSONVAL@KANDIDAT` in list records is ballot position and matches candidate-file
`ORDNING`. `KANDNR` is the source candidate number. Preserve all three concepts.

Three invalid candidacies have source-reported positive observations:

| Candidate ID | Party | List / position | National source votes | Historical status text |
| --- | --- | --- | ---: | --- |
| 533186 | SD / 0110 | 17248 / 4 | 7,452 | Inte lämnat förklaring |
| 480136 | KrVP / 1140 | 17264 / 43 | 1 | Inte lämnat samtycke |
| 534261 | Det nya partiet / 1351 | 17266 / 1 | 2 | Inte lämnat samtycke |

These **7,455** votes are part of the reported raw preference structures and
must not be discarded or silently reassigned. Valid candidate/party records
have 515 positive totals; 41 have no positive source record. This distinction
is separate from completeness of reported observations. Do not manufacture
zeros from a missing party row or confuse a valid candidacy of 534261 in 1140
with its invalid 1351 candidacy. The printed/source list controls and national
coverage should determine any future zero-completion rule.

The national party-level `ÖVER_SPÄRR` attribute has 56 `J` and 462 `N` flags.
This threshold flag is distinct from candidacy validity and actual election:
the 20 `VALD` records have 11 personal-vote (`P`) and nine comparison-number
(`J`) election bases. Do not interpret all threshold flags as elected persons
or propagate national qualification to subnational views.

All 1,634,596 reported preference votes are individually represented in the
verified candidate/list records. There is no additional unexplained aggregate
other-party preference-vote remainder in the national source. The 2,315
handwritten values above are party votes, not unassigned preference votes.

## 7. Mandates and the fixed election result

The original final XML has **20 allocated mandates, 20 elected persons, zero
unfilled positions, eight substitute groups and 27 distinct substitutes**.
Expanding each group's elected members against that group's ordered substitutes
would yield **74 member/substitute relations**. Preserve the original group
and substitute order; do not mistake 27 substitutes or 74 relations for mandates.
Every elected/substitute ID matches the documented candidate file.

Original allocation: S 5, M 4, SD 3, C 2, KD 2, MP 2, V 1, L 1. This agrees with
SCB's original elected-person count of 20 and the current historical presentation.
The same presentation states that Sweden gained one seat from 1 February 2020,
allocated to MP, after Brexit. That is a later mandate-period change, not a
21-seat result of the 26 May vote. The 2024 comparison baseline's post-Brexit
21 seats must not overwrite the original 2019 allocation.

Complete dated mandate-period entrants/exits and a complete post-Brexit
substitute history are **NOT VERIFIED**. The original fixed relations are
complete. No extensive membership-history recovery was undertaken.

## 8. Electorate and source-specific snapshots

Final total electorate: **7,576,917**. The freshly preserved official SKV has
5,984 rows and 20 age/sex/citizenship counts per ordinary district. Each district
sum matches final XML, not just the national sum. The older local SKV has different electorate totals
in **1,045 districts**, with a net **+983** people. It must be preserved as an
older snapshot, not combined with final denominators. The differing district
rows are enumerated in the local `electorate-snapshot-differences.csv`.

SCB separately reports, for the country and all 21 counties:

- Swedish citizens resident in Sweden: **7,359,384** nationally;
- Swedish citizens resident abroad: **168,461**;
- other EU citizens resident in Sweden and eligible here: **49,072**.

Each county's three components sum exactly to its XML electorate. Current SKV
supports age/sex and Swedish-versus-other-EU citizenship at ordinary district
level, and thus upward aggregation. It does **not** separately identify Swedish
citizens abroad within districts. The full three-way residence/citizenship split
is therefore unavailable below county level. Do not distribute SCB's county
abroad counts downward. All 321 Wednesday units lack an independent electorate
and turnout; this is not a distinct electorate to allocate.

The 11 March EU-citizen workbook is a registration-stage stock (32,941 registered,
240,574 not registered), not the final 49,072 eligible foreign citizens. Likewise,
registered early-vote counts are not additional ballots to add to results.

## 9. Reconciliation and reuse assessment

Completed independent R checks (not package tests):

- all 582 XML files and all declared geography keys;
- all 290 municipal valid/cast aggregates in both counting stages;
- all disclosed party counts in 6,305 district and 290 municipal Excel rows;
- all 410,308 positive disjoint list/candidate preference observations;
- all 78,323 explicit list preference-total controls and 518 national list totals;
- 315 public county count controls per stage, final and preliminary;
- SCB's 5,984 ordinary and 290 merged collection units;
- SCB country/county ballot/party controls and all 22 electorate-composition rows;
- SCB nominated-candidate count 556 and original elected count 20;
- all 1,985 handwritten rows against exact XML residuals;
- candidate snapshot keys/status, all preference ballot positions, and all original
  elected/substitute IDs;
- SHA256 integrity of all 12 original local sources after the audit.

No unexplained discrepancy remains in these ordinary vote/mandate controls.
The identified differences are snapshot (old electorate), category definitions
(SCB other parties), geography partitions (SCB collections), name redaction and
code formatting, a reader-inference hazard, and the explicitly dated Brexit seat
change. None requires overwriting raw data.

Compared with EU 2024, 2019 is XML/Windows-1252 SKV rather than JSON/CSV ZIP. Its
DTD family is **parti[_person]_{nation,kommun}_1_8**, the same general XML family
as 2018. `NATION`, `LÄN`, `KRETS_RIKSDAG`, `KOMMUN`, `KRETS_KOMMUN`, `VALDISTRIKT`,
`ONSDAGSDISTRIKT`, `GILTIGA`, `ÖVRIGA_GILTIGA`, `VALSEDEL`, `PARTISEDEL`, `PERSONVAL`,
`GRUPP_VALDA`, `VALD` and `ERSÄTTARE` have explicit source roles.

`R/xml_2018.R`, `R/personroster_2018.R` and
`R/personroster_xml_distrikt_2018.R` contain reusable low-level XML/geography/list
logic, but existing RKL year/type dispatch and national mandate assumptions must
not be reused blindly. EU needs a scoped year/type adapter and national original
relations, following the existing 2024 interface without changing that year's
values. Handle nested smaller parties, the handwritten supplement, collection
codes, encoding, redaction and complete preliminary XML explicitly.

The original DTD references use `http://www.val.se/dtd/resultat/` and the four
1.8 filenames for party/person nation/municipality. Tested HTTPS equivalents on
both current and historical hosts return 404. Formal DTD retrieval/validation is
**NOT VERIFIED**; empirical XML structure and all numeric controls have been
checked. This is a documentation/source-recovery qualification, not missing votes.

Both 2019 and 2024 EU elections are party elections. The referendum
`voting_option` concept belongs to the 2003 referendum, not to either EU election.
No party-to-voting-option conversion or referendum schema is appropriate here.

## 10. Explicit completeness matrix

| Dimension | Status | Exact scope / missing information and effect |
| --- | --- | --- |
| Final valid/invalid/blank/no-notice/other-invalid counts and ballots cast | COMPLETE | Country, 21 counties, 29 parliamentary reporting constituencies, 290 municipalities, source municipal containers and all 6,305 ordinary/Wednesday units. Wednesday cast is exactly derivable; no vote gaps. |
| Final party breakdown | COMPLETE | 32 XML parties plus 34 handwritten parties, all 66 codes identified. No undisclosed residual after the supplement; no duplicated votes. |
| Ordinary/Wednesday geographic population | COMPLETE | 5,984 + 321, no missing or duplicate units. |
| Municipal constituency geography | COMPLETE | 53 actual units in 22 municipalities; 268 technical `00` containers do not create new public constituencies. |
| Final electorate/turnout on applicable geographies | COMPLETE | National/aggregate/ordinary denominators reconcile. All 321 Wednesday units structurally lack their own electorate/turnout; preserve NA. |
| Documented candidacy population and IDs/status | COMPLETE | All 562 source rows, 556 valid; identical current/local keys and validity. One ordered-only Volt list is not a missing candidacy. |
| Historical valid-candidate names | COMPLETE | Named local snapshot covers all 556 valid candidacies; not a recommendation to publish these names. |
| Current public candidate names | INCOMPLETE | All 556 valid names unavailable/redacted; all 562 current rows say `Namnet Gallrat`. Publisher redaction, not a missing candidate observation. Public NA names recommended. |
| Reported positive preference observations | COMPLETE | 410,308 disjoint list/candidate/unit records, 6,305 units, 1,634,596 votes. Party/list and geographic duplicates are alternative views, not additional votes. |
| Candidate/list/position linkage for reported preference rows | COMPLETE | Every reported list row matches official candidate ID, party, list and ballot position. No name-based identity inference. |
| Original allocated/elected/unfilled mandates and substitutes | COMPLETE | 20 / 20 / 0; 27 substitutes, eight groups, 74 expanded relations. |
| Complete preliminary reporting snapshot | COMPLETE | 6,305 units, including all 321 Wednesday units, independently reconciled. No final values substituted. |
| Individually named smaller-party preliminary values | INCOMPLETE | The preliminary source reports ten named parties plus an other-party aggregate (44,107 votes nationally). Its underlying party-specific cells are not disclosed in that stage; do not substitute final detail. Final breakdown is complete. |
| Separate frozen election-night snapshot | NOT VERIFIED | Current national valnatt page has blank numerical cells. Ordinary component exists in preliminary XML but a separate freeze is not established. Recovery qualification; no effect on final/preliminary completeness. |
| Electorate age/sex and two citizenship categories | COMPLETE | Fresh official SKV, all 5,984 ordinary districts; upward aggregation supported. Older local SKV is a separate +983 snapshot. |
| Three-way electorate residence/citizenship split | COMPLETE | Country and all 21 counties, matching final denominators. |
| Same three-way split below county | INCOMPLETE | Swedish resident/abroad split not separately reported for 290 municipalities, 53 actual municipal constituencies or 5,984 ordinary districts in the examined sources. Original reporting limitation; not a missing total electorate. No downward allocation. |
| Same physical person across election occasions | NOT VERIFIED | Election-occasion candidate ID is available; longitudinal person linkage is not established. Does not imply missing candidacies or preference observations. |
| Complete mandate-period event history | NOT VERIFIED | No complete dated entry/exit and post-Brexit substitute event log established. Supplementary history only; original result unaffected. |
| Formal DTD/signature validation | NOT VERIFIED | DTD retrieval unavailable at tested hosts; binary signatures/POSIX checksum value not cryptographically/algorithmically verified. ZIP member population/length and SHA256 integrity are verified. |
| SND result comparison | NOT VERIFIED | No local 2019 result dataset or suitable SND administrative source identified; retrieved SND item concerns survey data. No final-result gap; SCB controls passed. |
| Original currently downloadable final XML/protocol | INCOMPLETE | Both official linked endpoints return 404. All 291 original final XMLs are already preserved locally, and independent official controls match. Missing live download paths, not substantive results. |

## 11. Recommendation and answers

Implement the seven functions from the **preserved original final XML**, with
current candidate keys/status, a consistent historical public name contract,
the disclosed handwritten-party supplement and the final-compatible current
electorate SKV. SCB remains a control and the source for the verified county/
national residence split, without allocating it to finer units.

Use the full preliminary ZIP directly. Pin exact input checksums for the preserved final ZIP, current redacted candidacy
SKV, final-compatible electorate SKV, handwritten-party workbook and preliminary
ZIP; retain the older named and electorate snapshots as provenance. Keep the
original 20-seat result separate
from the 2020 extra seat. Do not allow later rosters to redefine elected/substitute
relations. Preserve all original and newly acquired snapshots/checksums.

Before production implementation, settle only operational/schema choices:
(1) explicitly pin the preserved final ZIP because the live endpoint fails;
(2) confirm the historical public NA-name contract; (3) retain the 29 parliamentary
constituencies as reporting geography, not EU mandate constituencies; and (4)
apply the existing rule for invalid-candidacy reported preference votes, never
join or reassign them using candidate number alone. No further broad source
recovery is needed for final results.

1. **Final party results complete? COMPLETE**, including all 66 disclosed parties
   when the handwritten supplement replaces, rather than adds to, the residual.
2. **Reported preference observations complete? COMPLETE**, 410,308 observations
   and 1,634,596 votes over all 6,305 source units.
3. **Candidate/candidacy population complete? COMPLETE**, 562 rows / 556 valid,
   independently matched to SCB 556 and unchanged in the redacted public snapshot.
4. **Mandates/elected/substitutes complete? COMPLETE for the original result**:
   20 seats/persons, zero unfilled, 27 substitutes in eight groups.
5. **Preliminary complete? COMPLETE**, including all 321 Wednesday units. A separate
   election-night freeze is NOT VERIFIED and is not needed for this stage.
6. **Further investigation needed before final implementation?** No additional
   vote/candidate recovery is required. The explicit operational/name/geography
   choices above require review; complete mandate-period history is not a blocker.

## Original source checksums

| Local source (under `.local-data/eu/2019/`) | Bytes | MD5 | SHA256 |
| --- | ---: | --- | --- |
| `kandidater/kandidaturer.skv` | 91062 | `badad49ade8bf215b16f247af8e6a3bf` | `c1d7373990393c2fe29d2e021807846215a72c71e85e9d9b4b7f83082b543e42` |
| `rostning/mottagna_fortidsroster.skv` | 265713 | `5619bd5b4a73aa277d189c85a550844c` | `3719be1affb96d8e5896b80f0cade82f831b7d9eb8aee3162eeb02ba75687bc3` |
| `rostning/rostlokal.skv` | 703441 | `68dc6e0b34076acd89b3acd875c4608f` | `43d1f93125696ae6254b5474641f2d942d2d22d1a7f338f5a7ec606a1b15e781` |
| `rostning/vallokal.skv` | 1487609 | `99ab90692f3863d2a978d2d773a3cf33` | `8fd6f402e85162896fcde476a64d9fbb741584bbf330307314ee0f66609502d0` |
| `valresultat/deltagande_partier.skv` | 10931 | `11404d2ee707197bc0700612d00f0000` | `921fa17e5044b732aef3d712919f61fc71f51f5ee738ea1acf27a7f3ad8b77a8` |
| `valresultat/deltagande_partier_per_valomrade.skv` | 4679 | `3d8830abc61aaedb877a84d54c830259` | `5757c40516dd834c190b70f5cc92527eccf1492a7aac85644bcfb416e07d5723` |
| `valresultat/ep2019_antal_eu-medborgare_2019-03-11.xlsx` | 11129 | `abb00b3583ab7a646c9416d54c5df2b6` | `b3c9786212b96cb31d8cb8b5ed46e4f1fafcc9eaf0a2b4e79d0d7fad10c4672e` |
| `valresultat/ep2019_rostfordelning_per_kommun.xlsx` | 124024 | `d1cec60936ce6195d1aee7cf8ef0af4b` | `2c5d17610ee88f7c25bb22fa11516841cfa39049c7987d0aa4beceea52292f90` |
| `valresultat/ep2019_rostfordelning_per_valdistrikt.xlsx` | 2541030 | `bc6200287e2259b97248f1ba24d5957d` | `42a256e51ff2a52b9c4df80dc35c56ea504ba3fcc0405e8ed54490021111d169` |
| `valresultat/prelresultat.zip` | 1899732 | `665e76e704e5585f23860b550655f67b` | `33cf5da0f66188bef1ad613ff7ae93347de91e11ac2011243f7437f8d722498e` |
| `valresultat/rostberattigade.skv` | 788865 | `621b13021688d5bcc8a300fcaa2e94a6` | `019afc3861a5296e192368a68a52ca77880a700b748ba52e22ac7015ef67653b` |
| `valresultat/slutresultat.zip` | 14474869 | `026ce30070baa5cde8a5db8b31d4bc97` | `85528fda705bcb56c8c9fa7c0c926f614ad210b77c3bda781459f28c328a5f4a` |
## Acquired-source provenance

Original and effective URLs, UTC times, sizes, MD5 and SHA256 are recorded locally.
The table below records the successful acquisition URLs; `retrieval.csv` additionally
retains failed endpoint attempts. Failed guessed paths are not treated as proof that
a linked source is absent. All successful files remain local, not tracked.

| Audit file | Source URL | Retrieved UTC | Bytes | MD5 | SHA256 |
| --- | --- | --- | ---: | --- | --- |
| `statistics.html` | https://historik.val.se/val/ep2019/statistik/index.html | 2026-10-15T12:55:35Z | 13086 | `778d3da4a125f9a5008b3ae85db08a17` | `00d1574d81ca6ca7d3bb9a70ab06a51e50b98e2bd89f1825f7d558865314c237` |
| `final.html` | https://historik.val.se/val/ep2019/slutresultat/E/rike/index.html | 2026-10-15T12:55:36Z | 73344 | `edf7b0d81ced84034dd8c81a5631d1e2` | `4d9fd80109bbca7f93178a475f317d28753267c66ecba5e754268e98993f023b` |
| `preliminary.html` | https://historik.val.se/val/ep2019/prelresultat/E/rike/index.html | 2026-10-15T12:55:37Z | 65074 | `d45ba970f0f04ec5f8f3aa9524e7f75e` | `2aaf8e6765c00186f7cd5a6e020751a4f588fb9a486391517d59b3b1cd73408a` |
| `night.html` | https://historik.val.se/val/ep2019/valnatt/E/rike/index.html | 2026-10-15T12:55:38Z | 68205 | `ad2448d5d68f9e5ff79b5fffa30474ff` | `59f0e65095093994fde8e8a954420118cbe840a5ad9b5882dc08e8179407db9f` |
| `elected.html` | https://historik.val.se/val/ep2019/slutresultat/E/rike/valda.html | 2026-10-15T12:55:39Z | 10938 | `cf361eb4d2836c360e663377cf2197e2` | `a1c1c71b63e9e73abd7e95f71c73e8e7596a8239699176b3d4793320eb80c391` |
| `preference.html` | https://historik.val.se/val/ep2019/slutresultat/E/rike/personroster.html | 2026-10-15T12:55:40Z | 77267 | `98380ec7872f586b5cc8db87bafb4e19` | `4411c1edb541360c26cbef18a070e03809e871c95981ccdd1a834387e2ccf7b2` |
| `scb.html` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/ | 2026-10-15T12:55:41Z | 107303 | `e6e2f85f311eb9c6dce1dd669b153caa` | `522c52f3c9593a1eec04a8d4e23e33d635a0d2bbaf703562256a8ce04e21d70c` |
| `scb_candidates.html` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/ | 2026-10-15T12:55:42Z | 40892 | `73f84ca0012630e6b18408c0c6bc24f9` | `3920db8ba34552286f89080a0ae0965dd78897bb5ad56c4d629b20da5778d286` |
| `current-preliminary.zip` | https://historik.val.se/val/ep2019/prelresultat/prelresultat.zip | 2026-10-15T12:58:01Z | 1899732 | `665e76e704e5585f23860b550655f67b` | `33cf5da0f66188bef1ad613ff7ae93347de91e11ac2011243f7437f8d722498e` |
| `current-candidacies.skv` | https://historik.val.se/val/ep2019/valsedlar/partier/kandidaturer.skv | 2026-10-15T12:58:02Z | 90026 | `f6bc2d4acdab4fb79a9179e200bb4819` | `7b2bc1b5e8cf503f27dc857a0aaa3850cc85a6655367659f94d97dad93a67940` |
| `handwritten-parties.xls` | https://historik.val.se/val/ep2019/handskrivna/handskrivna.xls | 2026-10-15T12:58:03Z | 387584 | `68d2e7e28a098deccfdb26888f1d2ef3` | `8f6c61411b50913752d4f82032ad3e46a04b1797fe8dd0e2bc14b4246a3a28da` |
| `current-municipal.xlsx` | https://historik.val.se/val/ep2019/statistik/ep2019_rostfordelning_per_kommun.xlsx | 2026-10-15T12:58:04Z | 124024 | `d1cec60936ce6195d1aee7cf8ef0af4b` | `2c5d17610ee88f7c25bb22fa11516841cfa39049c7987d0aa4beceea52292f90` |
| `current-district.xlsx` | https://historik.val.se/val/ep2019/statistik/ep2019_rostfordelning_per_valdistrikt.xlsx | 2026-10-15T12:58:04Z | 2541030 | `bc6200287e2259b97248f1ba24d5957d` | `42a256e51ff2a52b9c4df80dc35c56ea504ba3fcc0405e8ed54490021111d169` |
| `scb-electorate.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2019/valet-till-europaparlamentet-2019-lansvis.-rostberattigade-efter-medborgarskap-och-kon | 2026-10-15T13:00:44Z | 11973 | `0a85b6c33352526dcd7d99b00920e25c` | `bfb44e6ef2d181e1f975868e0667958c536474bd0b93d4efd6ead044c80b3f24` |
| `scb-county.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2019/valet-till-europaparlamentet-2019-lansvis.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-parti | 2026-10-15T13:00:45Z | 17737 | `513f367278af9e271f8bba881f362d74` | `08378f99646c04bcf9640242d5d1709e53b2d5c7984e2a7d4f53e2c4475d456d` |
| `scb-district.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2019/valet-till-europaparlamentet-2019-efter-valdistrikt.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-partier | 2026-10-15T13:00:46Z | 858538 | `f1d04bbc22ddb4753483834d2b4acb12` | `d97654f630fc074383791d272a1c3c22eb5e2e23ce57cc8cc67ca502f115fac6` |
| `scb-small-parties.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2019/valet-till-europaparlamentet-2019-efter-kommun.-ovriga-partier-som-erhallit-05-eller-mer-av-rosterna-i-kommunen | 2026-10-15T13:00:47Z | 35854 | `34aa8c7a78f454e463b4bfbabc78a539` | `271ff964c1e09a2a8e46c018d39f7a22943eb7583a09b22c1ca9819d38149f65` |
| `scb-national.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-2019/valet-till-europaparlamentet-2014-och-2019.-giltiga-valsedlars-fordelning-efter-parti.-partier-med-mer-an-01-procent-av-totala-antalet-roster | 2026-10-15T13:00:48Z | 10349 | `34511b204608b4e1014b3e4fd299e87f` | `cfad17b01f97d4a9d8477a6ac54a6e3ca9994c3a3a5a1075675a03075378b89d` |
| `official-2019-summary.html` | https://www.val.se/english/election-results/elections-to-the-european-parliament/european-parliament-election-results-2019 | 2026-10-15T13:00:54Z | 140483 | `0ee3f6bd84e92d3906cf32a6bf3e729c` | `b5efb5d6944562b6554bbee7b782643f370206cb5682d4da53934291ca4e6ebf` |
| `scb-candidate-overview.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-nominerade-och-valda/pong/tabell-och-diagram/nominerade-och-valda-kandidater-i-europaparlamentsval/ | 2026-10-15T13:10:18Z | 20754 | `fc9798d3b906f464ce7da04cd5949e57` | `f43ba0da81ad72c6deca40d218b0a40760c1122d82b841b2fcc23b4139add26f` |
| `snd-2019-news.html` | https://snd.se/sv/nyheter/nya-eu-valdata-publicerade | 2026-10-15T13:10:20Z | 82715 | `9bedb1b076443a8a87b7312880c7c612` | `469be84672d9332971b29569c6bf77b90cad515a2614529ad3151604d85cc6db` |
| `scb-candidate-metadata.json` | https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0116/C1EUvalNom | 2026-10-15T13:10:21Z | 649 | `ffe07c54cd64d99b1f937f43347a6844` | `1ce37b86c1b61b6fc4f86e17008aa7f492404ed3792375409617feda81f738d4` |
| `official-current-electorate.skv` | https://historik.val.se/val/ep2019/alkon/E/rostberattigade.skv | 2026-10-15T13:18:06Z | 788861 | `6430a85e361d2d59f854262691a63e81` | `7abb80590ff70d64f4445374d1de0a3edeed2daa271725c4eb6803319e8be660` |
## Audit artefacts and repository scope

The complete independent R census and successful reconciliation outputs are retained
locally in `review-20261015/`: `census.rds`, `geographic-units.csv`,
`reconcile.log`, `supplementary-controls.log`, `compare-snapshots.log`,
`electorate-snapshot-differences.csv`, and workbook-native-cell inspection evidence.
These are development/source-audit artefacts, not production dependencies.
Only this Markdown report is intended as a repository change. No package tests,
`R CMD check`, canonical build, commit or push was run for this inventory.
