# Source inventory: 2003 euro referendum

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


Assessment date: 14 October 2026. Scope: the referendum held on **14 September 2003**, not the Orsa municipal re-election in March 2003. This is an inventory and independent source assessment, not an implementation specification approved for production.

## Conclusion

**The final reported voting-option results are COMPLETE** at national, county, parliamentary-constituency, municipality, municipal-constituency, ordinary voting-district and Wednesday-unit levels. All three valid ballot categories—`JA`, `NEJ`, `BLANK`—and the combined invalid category are present throughout the inspected final XML. No missing final vote observations were found.

A complete election-night snapshot is also preserved. A separate complete preliminary snapshot including Wednesday units has **not** been recovered or verified. Election-night plus **final** Wednesday votes must not be presented as a preliminary result.

Two source/documentation gaps remain: the specifically requested SCB result publication and the external XML DTD were not recovered at the tested official locations. Neither gap removes the final vote observations already independently reconciled below. Detailed invalid-vote reasons and independent Wednesday-unit electorates are absent from the inspected published result structures.

## 1. Preserved source inventory

The original local collection contained one archive:

- `.local-data/folkomr/2003/snd/snd0240-3-2.zip`, **555,969 bytes**, local modification time 11 October 2026 14:58:43 UTC. Its modification time and ZIP member times are archive/download metadata, not proof of a 2003 source capture date.
- ZIP contains exactly two XLSX workbooks and `sha256.txt`; no hidden additional result tables were found.
- `0240_FO03_valdistr.xlsx`: **543,759 bytes**, one sheet, **6,266 data rows × 14 columns**.
- `0240_FO03_noter.xlsx`: **11,529 bytes**, one notes/example sheet, 30 non-header spreadsheet rows × 14 columns when read without treating its first note as a variable name. It is documentation, not 30 additional geographic observations.

New official objects are preserved under `.local-data/folkomr/2003/review-20261014/`. `source-manifest.json` and `source-inventory.csv` record the complete downloaded-object inventory, original/effective URL, retrieval time in UTC, byte size, MD5 and SHA256. Every object also has its own `.provenance.json` sidecar. Local audit R scripts/logs and extracted diagnostics remain outside Git. Original source files were not overwritten.

| Source / local object | Format and coverage | Purpose / authority |
|---|---|---|
| `final.xml` (also `slutresultat-national.xml`, byte-identical duplicate) | ISO-8859-1 XML; 1 nation, 21 counties, 29 parliamentary constituencies, 290 municipalities | Authoritative final aggregates |
| `final-municipal/{municipality_code}.xml`, **290/290 files** | ISO-8859-1 XML; 290 municipalities, 396 municipal-constituency reporting containers, 5,976 ordinary districts, 396 Wednesday units | Authoritative final detailed results |
| `valnatt-national.xml` | XML; national/county/parliamentary-constituency/municipality aggregates | Authoritative preserved election-night snapshot |
| `night-municipal/{municipality_code}.xml`, **290/290 files** | XML; 290 municipalities, 396 municipal-constituency reporting containers, 5,976 ordinary districts; **no Wednesday nodes** | Election-night ordinary-district observations |
| `slutresultat.html`, three `slutresultat-table_00*.html`, municipal sample HTML | Final presentation and geographic navigation | Official presentation/links; not additional votes |
| `valnatt.html`, three `valnatt-table_00*.html`, municipal sample HTML | Election-night presentation and navigation | Official stage identification/links |
| `night-sample.xml` | Duplicate sample municipality, Upplands-Väsby | Initial structure inspection; do not count twice |
| `protocol.pdf` | Official final decision protocol, Dnr 03-149/30, including county-result appendix | Fixed-result decision provenance |
| `scb-counties.xls` | Official SCB table; 21 counties + national total; electorate, valid/invalid/cast, turnout, Ja/Nej/Blank and shares | Independent tabular comparison; values originate from Valmyndigheten |
| `scb-municipalities.xls` | Official SCB 2003–1994 comparison; 2003 Ja/Nej percentages for 290 municipalities, county/national summaries and notes | Independent published share control; not a district source |
| `quality.pdf` | SCB `me0113_bs_2003.pdf`, six pages, dated 20 October 2004 | Definitions, full-count coverage and source relationship |
| `scbdok.pdf` | SCB `me0113_do_2003.pdf`, 207 pages; document timestamp 19 February 2007 | Register structure, district codes, electorate reference date and known coding issue |
| `snd-catalogue.html` | SND/researchdata catalogue metadata | Dataset provenance and version identification |
| `current-valmyndigheten.html` | Current official referendum summary | Independent presentation check of final national totals |
| Requested `ME0113_2003A01_BR_02_ME08SA0401.pdf` | **Not recovered**; former official publication URL returns HTTP 404 | Exact publication comparison **NOT VERIFIED**; do not substitute a PSU survey report with a different publication identifier |

### Authoritative URLs

- Final national XML: <https://historik.val.se/val/emu2003/resultat/slutresultat/slutresultat_00F.xml>.
- Final municipality XML pattern: `https://historik.val.se/val/emu2003/resultat/slutresultat/slutresultat_{LLKK}F.xml`; all 290 codes are taken from the national XML.
- Final presentation: <https://historik.val.se/val/emu2003/resultat/slutresultat/index.html>.
- Final protocol: <https://historik.val.se/val/emu2003/resultat/slutresultat/protokoll.pdf>.
- Election-night national XML: <https://historik.val.se/val/emu2003/resultat/valnatt/valnatt_00F.xml>.
- Election-night municipality pattern: `https://historik.val.se/val/emu2003/resultat/valnatt/valnatt_{LLKK}F.xml`.
- Election-night presentation: <https://historik.val.se/val/emu2003/resultat/valnatt/index.html>.
- Current summary: <https://www.val.se/valresultat-och-statistik/folkomrostning-2003>.
- SCB source portal: <https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/folkomrostningar-valresultat/>. The two preserved Excel objects are the portal's linked county table and municipal 2003–1994 comparison; their full download/effective URLs are in the local source manifest.
- SCB quality: <https://www.scb.se/contentassets/92ac4724897944c6a5f370ad1bebb357/me0113_bs_2003.pdf>.
- SCBDOK: <https://www.scb.se/contentassets/92ac4724897944c6a5f370ad1bebb357/me0113_do_2003.pdf>.
- SND catalogue: <https://researchdata.se/sv/catalogue/dataset/snd0240-3>; version 2, DOI <https://doi.org/10.5878/xhnt-ek46>, published 30 June 2026. Metadata identifies SCB as collector and SSD/Göteborg University as processor of SCB-derived data. Version 1.0 was published 1 January 2008. The local archive corresponds to the two currently listed workbook filenames; both workbook hashes match the supplied ZIP checksum file.
- Requested SCB publication's former URL: <https://www.scb.se/statistik/ME/ME0113/2003A01/ME0113_2003A01_BR_02_ME08SA0401.pdf> (**404** during this review).

## 2. Referendum-specific structure and definitions

The XML root is `VAL`, `VALTYP="Folkomröstning"`, with occasion label `Folkomröstning 14 september 2003 om införande av euron`. Final root `TID_RAPPORT="20030918144504"`; election-night presentation was generated 14 September 2003 at 23:41. Source generation/report times must not be confused with acquisition time or election date.

The reuse of element names from election XML does **not** make these party results:

| Raw registry / result representation | Meaning | Proposed treatment |
|---|---|---|
| `PARTI FÖRKORTNING="JA" BETECKNING="Ja"`; `GILTIGA PARTI="JA"` | Affirmative response option | Voting option `JA` / `Ja` |
| `PARTI FÖRKORTNING="NEJ" BETECKNING="Nej"`; `GILTIGA PARTI="NEJ"` | Negative response option | Voting option `NEJ` / `Nej` |
| `PARTI FÖRKORTNING="BLANK" BETECKNING="Blank"`; `GILTIGA PARTI="BLANK"` | Valid blank referendum ballot | Preserve separately as valid blank category, distinguish from substantive answers |
| `PARTI FÖRKORTNING="OG"`; `OGILTIGA TEXT="OG"` | Combined invalid ballots | Invalid-ballot measure, **not** a response option or party |

The question recorded by SCB is whether Sweden should introduce the euro as currency; the substantive answers are Ja/Nej. There are no candidates, party lists, preference votes, seats, elected persons or substitutes in this referendum. Those election-specific concepts are not missing referendum records.

`RÖSTER` on a geographic node means **valid ballots**, including Blank. `VALDELTAGANDE SUMMA_RÖSTER` means ballots cast, including invalid. Option percentages use valid ballots; turnout uses ballots cast divided by eligible voters. Do not apply ordinary-election blank-as-invalid conventions.

| National final measure | Count |
|---|---:|
| Ja | 2,453,899 |
| Nej | 3,265,341 |
| Blank, valid | 121,073 |
| Valid ballots | 5,840,313 |
| Invalid, combined | 3,475 |
| Ballots cast | 5,843,788 |
| Eligible voters | 7,077,502 |
| Source rounded turnout | 82.6% |

The electorate is the published roll reference, **15 August 2003**, according to SCBDOK §2.1; it is not asserted to be a retrospectively perfected election-day population. Preserve published denominators. No invalid-reason subcategories were found in the result XML or inspected SCB/SND tables.

## 3. Exact final geographic coverage

| Geography | Unique units | Evidence and aggregation |
|---|---:|---|
| Nation | 1 | `NATION KOD="00"` |
| County | 21 | `LÄN`, codes retained as strings |
| Parliamentary constituency | 29 | `KRETS_RIKSDAG`; existing RD boundaries used as a reporting geography, not separate parliamentary elections |
| Municipality | 290 | National XML and each municipality XML agree in all seven count fields |
| Municipal-constituency reporting container | 396 | `KRETS_KOMMUN`: 185 constituencies in 79 divided municipalities plus 211 undivided municipality containers; all children reconcile |
| Ordinary voting district | 5,976 | `VALDISTRIKT`; all codes unique and present in SND |
| Wednesday / votes not counted in polling station | 396 | `ONSDAGSDISTRIKT`, all codes unique, all 290 municipalities represented |
| Total non-overlapping final counting units | 6,372 | 5,976 + 396; national `KLARA_VALDISTRIKT = ALLA_VALDISTRIKT = 6372` |

**The 396 `KRETS_KOMMUN` nodes must not become 396 distinct public municipal constituencies:** 211 have technical suffix `00` and represent undivided municipalities; the other 185 belong to the 79 divided municipalities. Preserve source containers for linkage and aggregation, but do not manufacture a public constituency for an undivided municipality. Wednesday records inherit the actual parent role accordingly.

Ordinary codes are eight-character strings such as `01140101`; do not lose leading zeroes from SND's numeric spreadsheet codes. Wednesday codes are separately typed strings, e.g. **`F-0114-01`**, with label `I vallokal ej räknade röster`, linked in XML to municipal constituency `011401`. Do not force them into ordinary eight-digit district codes.

Final Wednesday units have all three valid categories and combined invalid votes. They have **no own `VALDELTAGANDE` node**, eligible-voter count or turnout. Their ballots cast can be computed exactly as valid + invalid; this is arithmetic on reported source counts, not estimation. Electorate/turnout for these units must remain missing/not applicable.

Wednesday totals: Ja **55,784**; Nej **40,284**; Blank **2,259**; invalid **138**; valid **98,327**; cast **98,465**. Ordinary-district cast is **5,745,323**. Their sum is the final national **5,843,788**.

Unlike the SND municipality-only postal residual, the Valmyndigheten final XML **does identify** the 396 Wednesday units by municipal constituency. Preserve that actual source geography rather than distributing a municipality residual artificially.

## 4. SND, SCB and Valmyndigheten reconciliation

Independent local R parsing was used for inventory/validation only. No production normaliser, canonical data or public API was changed.

- **5,976/5,976 ordinary SND rows** match XML by restored eight-digit district code. Valid, Ja, Nej, Blank, invalid, cast, electorate and rounded turnout all match: **zero numeric discrepancies**.
- **290/290 SND `ÖÖsum` rows** match final municipality XML on the same eight fields: **zero discrepancies**.
- SND `Valdistriktkod=99999999` is repeated on every municipal summary. It is a summary sentinel, **not a globally unique district**. Never sum ordinary and `ÖÖsum` rows together.
- All **290** ordinary + Wednesday municipality aggregations match their source totals for Ja, Nej, Blank, invalid and cast; all **396** municipal-constituency aggregations match option/invalid counts and ordinary-district electorates.
- The national XML's **21 counties**, **29 parliamentary constituencies** and **290 municipalities** each separately sum to the same national counts and electorate.
- SCB county Excel: **21 counties + 1 nation** match XML exactly for electorate, valid, invalid, cast and all three valid categories.
- SCB municipal comparison: **290/290 Ja/Nej share pairs** match XML rounded to one decimal after removing the explicitly printed footnote suffixes on Nykvarn/Södertälje/Knivsta/Uppsala and matching `Eskilstuna` to XML `Eskilstuna kommun`. These are comparison aliases, not edits to any source.
- SND vs XML has **751 literal ordinary-district name differences** despite identical codes and numeric values. **344** remain after a diagnostic removal of whitespace/hyphens; examples include `Vallentuna Centrum` vs `Vallentuna C`, `Bällsta Västra` vs `Bällsta V`, and case/abbreviation variants. Prefer Valmyndigheten names, preserve SND source names separately; do not match by names. Full paired evidence is in local `name-differences.csv`.
- SND's note describes subtracting a district sum from `ÖÖsum` to recover postal votes, but calls that sum “röstberättigade” in the prose. The worked example actually subtracts **votes cast**: Upplands-Väsby **23,540 − 23,080 = 460**. The numeric files/XML verify 460 postal/Wednesday ballots. Do not implement the prose literally as subtraction of the electorate.
- SCBDOK §3.3 documents historical municipal-constituency/postal code treatment that inflated some recoded district counts. This explains why raw row counts from different representations cannot establish the number of ordinary districts. The observed XML unit population and non-overlapping aggregation are the relevant controls.

**Authority:** use Valmyndigheten final XML for reported votes, eligible voters, geographic relationships, codes, names and report metadata. SCB is an official published validation source built from Valmyndigheten's counting data; SND is a documented SCB-derived dissemination/processing source. They are valuable controls, not three independent original counts. No complementary substitution is required for final 2003 results.

## 5. Counting stages and preliminary gap

**Election-night COMPLETE for its own ordinary-district snapshot:** all 290 municipality files contain exactly the same 5,976 ordinary district codes as final XML, no missing vote fields and no Wednesday nodes. Ordinary-district sums match the national election-night XML:

| Measure | Election-night |
|---|---:|
| Ja | 2,389,658 |
| Nej | 3,211,233 |
| Blank | 118,249 |
| Valid | 5,719,140 |
| Invalid | 26,892 |
| Cast | 5,746,032 |
| Eligible | 7,077,502 |
| Turnout, rounded | 81.2% |

This is **not** the complete preliminary result including Wednesday collection counts.

**Separate preliminary Wednesday snapshot INCOMPLETE in the recovered archive: 0 units recovered; a complete independently verifiable preliminary stage NOT VERIFIED.** No separate preliminary collection stage is linked by the inspected final/election-night index/navigation pages. Related historical paths `/resultat/preliminar/index.html`, `/resultat/onsdag/index.html`, `/resultat/index.html` and `/statistik/index.html` returned 404. These checks establish a recovery gap, **not** that Valmyndigheten never produced preliminary collection results. The exact separate-stage unit population and independent full preliminary totals have not been established; 396 is the verified **final** Wednesday population, not proof of a preliminary reporting snapshot.

Final ordinary counts differ from election-night: Ja **+8,457**, Nej **+13,824**, Blank **+565**, invalid **−23,555**, cast **−709**. Therefore election-night + final Wednesday counts would produce **5,844,497** cast, **709 above final**, and would mix incompatible stages. No such reconstructed dataset was saved.

## 6. Completeness matrix

Statuses concern the specified source population or measure, not whether API support has been implemented.

| Dimension | Status | Exact coverage or missing information |
|---|---|---|
| Final Ja/Nej/Blank counts, all inspected levels | **COMPLETE** | 1 nation, 21 counties, 29 parliamentary constituencies, 290 municipalities, 396 municipal-constituency reporting containers, 5,976 ordinary districts, 396 Wednesday units; all three categories present |
| Final valid and combined invalid counts | **COMPLETE** | Same full population; no missing category counts |
| Final ballots cast | **COMPLETE** | Explicit for ordinary/aggregate geography; exact valid + invalid for all 396 Wednesday units |
| Final electorate and turnout for ordinary/aggregate geography | **COMPLETE** | All 5,976 ordinary districts and all aggregate units; published roll reference preserved |
| Separate Wednesday electorate/turnout | **INCOMPLETE** as standalone fields | All 396 units lack these fields in original XML; no separate electorate belongs to this extra counting role; do not fabricate denominators |
| Invalid-vote reason decomposition beyond combined OG | **INCOMPLETE** | No reason-level decomposition at any inspected level in XML, SND or comparison Excel; limitation of inspected published structures, not missing combined totals |
| Final geographic codes and parent relationships | **COMPLETE** | All listed units represented uniquely within their role; XML Wednesday → municipal constituency links available |
| SND ordinary districts and municipal sums | **COMPLETE** | 5,976 ordinary + 290 summaries; all numeric fields reconciled |
| SND separately identified Wednesday units | **INCOMPLETE** | No 396 individual Wednesday records; municipality residuals available instead; final XML supplies all individual units |
| Election-night ordinary snapshot | **COMPLETE** | 5,976/5,976 districts, 290/290 municipality XML, all reported option/invalid/cast fields |
| Recovered preliminary collection/Wednesday observations | **INCOMPLETE** | Zero separately preliminary units recovered; expected preliminary-stage population not established; recovery gap |
| Full preliminary result including collections | **NOT VERIFIED** | Separate preliminary Wednesday snapshot and independent full preliminary controls unavailable; no relabelling of election-night |
| Numeric final comparison with SCB county Excel | **COMPLETE** | 22/22 county/nation rows, seven count fields match |
| Municipal Ja/Nej share comparison with SCB Excel | **COMPLETE** | 290/290 matched using documented footnotes and one name alias |
| Exact requested SCB result publication comparison | **NOT VERIFIED** | `ME0113_2003A01_BR_02_ME08SA0401.pdf` not recovered; current linked SCB Excel/quality/SCBDOK used, not claimed to be the same PDF |
| External DTD validation | **NOT VERIFIED** | XML references `parti_nation_1_2.dtd` / `parti_kommun_1_2.dtd`; historical national DTD request failed; XML parsing and numerical structure checks succeeded without external DTD validation |

Candidate/person identity, candidacies, preference votes, mandates, elected/substitute relations are **not applicable to this referendum**; no missing population is implied.

## 7. Implementation recommendation, for approval

1. **Proceed with complete final-result support from Valmyndigheten XML.** No further vote-source recovery is needed for the verified final dimensions. Preserve SND and SCB as controls/provenance. Recovery of the exact SCB publication would improve the documentary archive, but is not a prerequisite for these already reconciled final observations.
2. **Defer a complete preliminary stage** until a separately identified preliminary collection snapshot and controls are recovered. Election-night is fully documented and can be preserved without adding a new public count-stage contract now.
3. **Use a small referendum-specific result extension**, sharing geography, totals, provenance, name translation and standard/full machinery. Current English election mappings accept RD/RF/KF and the public result schema uses party fields; passing referendum options through `party_code` would misrepresent them.
4. Proposed observation: referendum occasion × counting stage × geographic unit/role × **voting option**. Preserve official identifiers `JA` / `NEJ` / `BLANK` in `voting_option_code` and labels in `voting_option_name`; distinguish substantive answers from valid blank ballots. Keep invalid counts in geographic totals, not as a fourth voting option. These are proposed names, not implemented schema changes.
5. Record occasion/date (14 September 2003), referendum question, official source election type and unit role. Do not classify it as RD merely because parliamentary constituency boundaries are used for reporting.
6. Preserve source valid-ballot denominators and source rounded percentages; blanks are valid. Keep Wednesday electorates/turnout missing and Wednesday keys separately typed. Reuse XML traversal where appropriate, but make the `GILTIGA/PARTI` interpretation referendum-aware rather than reusing party semantics blindly.
7. Require the established all-unit arithmetic, XML/SND/SCB comparisons, code uniqueness, non-overlapping aggregation and language/detail equivalence checks before any future canonical build. No production implementation, package check, canonical build, commit or push was performed in this inventory stage.

## 8. Local reproducibility evidence

The local audit scripts are `review.R`, `inspect.R`, `linked.R`, `municipal.R`, `compare.R`, `validate.R`, `final-audit.R`, `night.R`, `night-check.R`, `scb-share-check.R`, `share-structure.R` and `finish.R` under `.local-data/folkomr/2003/`; logs are alongside them. They are inventory tools, not package/build dependencies. Some early logs record failed exploratory URL or diagnostic-script attempts; the completed checks and explicit corrected scope above are the assessment evidence.

`review-20261014/source-inventory.csv` lists all successful raw downloads and their individual checksums; `unavailable-urls.txt` records the unsuccessful tested official locations. `xml-geographies.csv` and `name-differences.csv` are local diagnostics, not canonical assets. Existing raw/SND files were preserved unchanged.

## 9. Key source fingerprints

All **601** preserved HTTP objects were rechecked against their recorded byte sizes, MD5 and SHA256: **601/601 passed**. Raw-download bytes total **8,642,680**, including explicitly identified duplicate/sample objects. The original SND ZIP is additional. Full per-object metadata stays in the local source manifest.

| Object | Bytes | MD5 | SHA256 |
|---|---:|---|---|
| `final.xml` | 183619 | `75ae8b7777cc2151973c8b5028d0f239` | `4bccb9ff3b4177c74c08e2b1c69a768800e2f7c9bff2ec3daa8cdfe81edc31a8` |
| `protocol.pdf` | 178166 | `86aca77ca0ec72b5a9de55ef1e6b5c93` | `2dc8d25106023ad2669efbf5f6ca8c56a63b7c66c5d256a613692a3056450346` |
| `quality.pdf` | 36359 | `3e772b76dfc5aad658b73599ce7944e6` | `355017d000f199affbcdca7fc679013f43b5b2b5de04a7f65dfe233e8c6000e0` |
| `scb-counties.xls` | 17408 | `5399a175fea512ba3c2cf4d6e904269e` | `9ce6de6193555f2f61f36ae1ee46a91679dba7cff4bf92ad9f493867e80a0e28` |
| `scb-municipalities.xls` | 78336 | `ed6e529808ae679732222587885e3c12` | `57945d662946073489d6f8d13ed675541c5d946841024aba41028fc81d9d09c9` |
| `scbdok.pdf` | 730339 | `eeeb864c14e2aa7e63bf9b2a691d7595` | `75f1f347f3adacc318a39a35874d4fd12232ab921f56abd0289b05e58b860d7c` |
| `valnatt-national.xml` | 183803 | `e341c30c0a09ef19d2a6131d01b16dc8` | `d7a3465771296005deb3c0caf96bb42edafe3f00f83b4da6eeaf830fda312b0d` |
| Original SND ZIP | 555969 | `b2b907ab8a9a575eb10ee28e07799d38` | `f6ef0d81dffd1a496abf87dc907c8ad065934f3e7e0b9697540bf6db15fb6919` |
| `0240_FO03_valdistr.xlsx` | 543759 | `f88c73b78cf47fbda0d79a74b49febd7` | `30690a75759d927a749dddf367b0c1de694fb3c05e3afff872da4ec2615cb747` |
| `0240_FO03_noter.xlsx` | 11529 | `d67c5e096bdef11f8f85ee4bcda1c54b` | `c75335300cc1a1d63071c6f2bf6859a0946e0ca159bd20dd3c2a50548a8e04da` |


## 10. Electorate-composition follow-up

The previously identified SCB electorate page publishes three disjoint groups
for every county and Sweden. They were subsequently preserved as
`scb-electorate-composition.html` with a separate URL/time/size/MD5/SHA256
sidecar. This is an additional official supplementary source; the original
601-object inventory and all original objects remain unchanged.

SCBDOK's `rbrsv`, `rbrutsv`, `rbrutl` are register metadata; they are **not actual
columns** in the preserved SND XLSX (which has only total eligible voters).
The public SCB page provides 21 county rows and one national row. The three
national counts are 6,648,244 Swedish citizens in Sweden, 106,003 Swedish
citizens abroad and 323,255 foreign citizens, summing to 7,077,502. All 21 county
sums match Valmyndigheten exactly; county sums also match all national groups.

County/national composition is **COMPLETE**. Components for 290 municipalities,
29 parliamentary constituencies, 185 actual municipal constituencies and 5,976
ordinary districts are **NOT VERIFIED**: detailed underlying fields are
mentioned in documentation, but actual group observations are absent from our
preserved district data. All 396 Wednesday units lack a standalone electorate.
No finer counts are allocated or inferred. These gaps do not alter the COMPLETE
status of the verified final voting-option results.

See [VALIDATION_2003.md](VALIDATION_2003.md) for the extended schema and source
semantics. Blank remains a **valid voting option**, outside combined invalid
ballots.

## Final completeness statement for the approved implementation

The three electorate-composition variables are **COMPLETE at national and
county level**: Sweden and all 21 counties have verified component values whose
sum equals the published `eligible_voters`.

They are **unavailable in the implemented/preserved sources at municipality,
ordinary voting-district and Wednesday-unit level**: all 290 municipalities,
5,976 ordinary districts and 396 Wednesday units retain typed missing component
values. Components are likewise unavailable for the 29 parliamentary and 185
actual municipal constituencies. Documentation of underlying register fields
is not a recovered component dataset. Wednesday units have no independent
electorate or turnout denominator.

**No downward allocation has been made.** No county/national component counts
have been distributed to municipalities, constituencies or districts, and no
missing component has been inferred as zero. This does not reduce the verified
completeness of final voting-option results. Blank is a **valid** option;
`invalid_votes` remains separate.
