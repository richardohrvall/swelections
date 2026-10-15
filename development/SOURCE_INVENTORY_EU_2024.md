# Source inventory: European Parliament election 2024

Assessment date: 2026-10-15. **Inventory only: no production implementation,
API changes or canonical build.** The election occasion is 9 June 2024.

## Approved candidate-snapshot decision

The final population uses the later 11 June/December official snapshot.
Candidate 1203, `Österberg, Felix`, Folklistan 1659, is valid and consent-only
in the recovered 9 June CSV but absent later. The reason is unestablished; no
preference-vote, elected or substitute record is identified. Preserve that
historical row and its checksums as provenance only. Do not add it silently
to the final candidate population. This is a documented source/version
difference and **does not block implementation**. Final candidacy coverage is
**COMPLETE WITH SPECIFIED EXCEPTIONS**: the sole historical snapshot discrepancy
is this excluded row. There is no identified missing row in the approved later
population. The decision supersedes earlier recommendations below that awaited
clarification of the administrative reason.

## Conclusion

**The sources are sufficient for a COMPLETE final party-result implementation**
at national, county, municipality and voting-district levels, including every
separately reported collection unit. Final mandates, original elected and
substitute relations, and all reported candidate/list preference votes are also
available. No additional result-source recovery is needed before implementation.

The approved final candidate population is **COMPLETE WITH SPECIFIED
EXCEPTIONS**: use the later 11 June/December snapshot, preserving candidate
1203 from the earlier 9 June file as historical provenance only. Its removal
reason is unknown and does not block implementation. Complete mandate-period
event history remains **NOT VERIFIED**; fixed original relations are complete.

## Authoritative sources and local preservation

Primary source: Valmyndigheten. SCB is an independent publication/control, not a
replacement for the available Valmyndigheten result data. No 2024 SND source was
found under `.local-data/eu`; the older SND archives there are other elections.

Official entry points:

- [Valmyndigheten raw-data/statistics portal](https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-eu-val)
- [2024 result and original decision](https://www.val.se/valresultat-och-statistik/eu-val/valresultat-2024)
- [Public final presentation](https://resultat.val.se/euval2024/EU?r=S)
- [Official checksum index](https://resultat.val.se/resultatfiler/euval2024/index.md5)
- [Final JSON ZIP](https://resultat.val.se/resultatfiler/euval2024/s/e/EU-val_2024_slutlig_00_E.zip)
- [Preliminary JSON ZIP](https://resultat.val.se/resultatfiler/euval2024/p/e/EU-val_2024_preliminar_00_E.zip)
- [Current candidate ZIP](https://data.val.se/filer/euval2024/parti/kandidaturer.zip)
- [Participating-party CSV](https://data.val.se/filer/euval2024/parti/deltagande-partier.csv)
- [Original result protocol](https://resultat.val.se/protokoll/protokoll_EU-val_2024_00_E.pdf)
- [SCB results and downloadable tables](https://www.scb.se/ME0109?menu=open)
- [SCB regional/party database table](https://www.statistikdatabasen.scb.se/pxweb/sv/ssd/START__ME__ME0109__ME0109A/EUvalA/)

Seventeen pre-existing source files were inventoried, with MD5 and SHA256 before
inspection; all seventeen were rechecked unchanged afterwards. Extraction,
independent R diagnostics, downloaded official controls and their provenance
are kept locally in `.local-data/eu/2024/review-20261015/`, outside Git.
`source-manifest.json` records the original inventory and retrieved-source URL,
retrieval timestamp, bytes, MD5 and SHA256. `original-files.csv` and
`candidate-member-hashes.csv` additionally identify containers and extracted
candidate content separately. Existing source retrieval times are unknown;
filename dates and ZIP member times are not asserted to be retrieval dates.

The two local result ZIPs **match the current official index MD5 exactly**;
therefore downloading the same national ZIPs again was unnecessary. The current
candidate ZIP was downloaded and is byte-identical to the December local ZIP.
The original decision, protocol, official SCB district/county workbooks and
source web pages were preserved separately, with checksums. Source links from
the portal are preserved in `portal-links.tsv`; SCB links in `scb-links.tsv`.

## File inventory

Paths below are relative to `.local-data/eu/2024/`. Sizes/checksums appear in the
appendix. All ZIP members were enumerated and inspected.

| File | Structure, population and role |
| --- | --- |
| `valresultat/EU-val_2024_slutlig_00_E.zip` | Six members: national district `rostfordelning` JSON, national `mandatfordelning` JSON, hierarchical `summering` JSON, and three 256-byte `_sign.sha256` companions. 6,589 district records; national, 21 counties and 290 municipalities. Fixed final result. |
| `valresultat/EU-val_2024_preliminar_00_E.zip` | Same six-member structure; full 6,589-unit preliminary snapshot, including collection units. No final elected relation. |
| `kandidater/kandidaturer.zip` | One semicolon CSV; 11 rows, 23 fields, 11 IDs, four parties. ZIP member dated 2024-02-16: an early snapshot, **not** a complete candidate source. |
| `kandidater/kandidaturer_20240618.zip` | One CSV; 1,395 rows, 23 fields, 1,344 IDs, 74 parties, 29 printed lists. Member dated 2024-06-11 16:39. Near-election candidate/candidacy source. |
| `kandidater/kandidaturer_20241218.zip` | Same row/key/validity population; member dated 2024-12-05 04:16. Current official ZIP matches this container exactly. Later attribute snapshot. |
| `valresultat/deltagande-partier_20240618.csv`, `deltagande-partier_20241218.csv` | Byte-identical; 138 records, 16 named fields, 122 distinct party codes. Sixteen party codes have two source records; do not count 138 distinct parties. All 100 positive-result codes are present. A terminal empty seventeenth field occurs in data lines, unlike the 16-field header; a reader must handle this explicit format detail. |
| `valresultat/personroster-EU-valet-2024.xlsx` | `Information`, `Data`, `Pivot`; Data has 393,607 rows, 12 fields: candidate name/number, district/county/region/municipality, party, list and votes. Complete positive district/list preference observations; pivot is derived, not another additive source. |
| `valresultat/slutligt-valresultat-europaparlamentet-2024-vallokalernas-rostrakning.xlsx` | Five sheets; `rosterEU` has 114,934 long party/category rows and 13 columns. Final votes, county/municipality/district context and electorate; collection denominators must follow JSON null semantics rather than Excel display zero. |
| `valresultat/preliminart-valresultat-europaparlamentet-2024-vallokalernas-rostrakning.xlsx` | Four sheets, including national/county tables and `AllaDistrikt24o19` (12,580 rows including both election years, 38 fields). Earlier vallokal snapshot, dated 11 June in its information sheet; not the complete 13 June preliminary ZIP. |
| `valresultat/rostberättigade-uppdelat-pa-alder-och-kon-valdagen-den-9-juni-2024.xlsx` | Information plus 6,275 ordinary-district rows, 25 fields. Age/sex/citizenship groups and total electorate; total 7,942,272. |
| `valresultat/scb/Valresultat valdistrikt EU2024.xlsx` | `eu_valdistr`: 6,565 populated result rows, 22 columns; `Blad1`: 53-column enriched/analytical sheet including demographic, education and birthplace information. First-sheet values match all cells of the newly retrieved official SCB result table. Container and extra sheet are not byte-identical to the official one-sheet download; retain this provenance distinction. |
| `rostning/fortidsroster_20240618.csv`, `fortidsroster_20241218.csv` | 2,422 / 2,425 rows, 26 fields, daily received early-vote counts by reception location. Different reporting snapshots, not cast ballot totals by voting district. Legacy Windows-1252 encoding. |
| `rostning/rostningslokaler.csv` | 2,487 rows, 34 fields: early-voting locations, dates/opening times, accessibility and coordinates. |
| `rostning/vallokaler.csv` | 6,275 rows, 19 fields: ordinary district/local constituency context, election-day premises, coordinates and opening time. |
| `rostning/statistik-antal-utlandsrostkort-per-land-2024.xlsx` | Overseas voting cards by destination country. This measures cards sent, not final electorate or votes. |

The signature companions are binary 256-byte objects, **not plain SHA256 text
inventories**. Their cryptographic signatures were not verified in this audit.
The separate official MD5 index and locally computed SHA256s are the checksum
controls used here.

## Final results and geography

The final district JSON root reports `EU-val_2024`, election code `E`, ordinary
election, final count and 6,589/6,589 districts. District data were updated
2024-06-14T17:28:41, mandate data 17:29:06, summary data 17:29:17. These are source
update times, not independent election occasions or later membership dates.

| Level | Verified population | Meaning |
| --- | ---: | --- |
| National/election constituency | 1 | `00`, entire Sweden; one national mandate/person-vote constituency. |
| County | 21 | Administrative aggregation; not 21 EU mandate constituencies. |
| Municipality | 290 | All municipalities. |
| Ordinary voting district | 6,275 | All have votes and electorate. |
| Collection unit | 314 | Separately identified `valdistriktstyp = uppsamlingsdistrikt`; all have votes, all have null electorate/turnout. |
| Municipal-constituency context | 41 substantive constituencies in 17 divided municipalities | Plus 273 technical `00` contexts for undivided municipalities. The 314 distinct source context codes are not 314 substantive constituencies. |

Every district code is unique; all 290 municipalities and all 21 counties occur.
No missing final geographic unit was found. District party sums agree with all
5,949 published municipality-party cells, 768 county-party cells and 100
national-party cells (zero differences). All 2,030 municipality and 147 county
comparisons of cast/eligible/valid/invalid/blank/unregistered/other-invalid totals
also agree. Collection electorate is excluded from electorate summation because
it is null, not a second population.

| National final measure | Value |
| --- | ---: |
| Valid party votes | 4,198,011 |
| Invalid ballots | 42,448 |
| Of which blank | 33,733 |
| Of which votes without participation notice | 777 |
| Of which other invalid | 7,938 |
| Ballots cast | 4,240,459 |
| Eligible voters | 7,942,272 |
| Turnout from unrounded counts | 53.3910070066% |

All 6,901 published district/municipality/county/national nodes satisfy
`valid + invalid = cast` and the invalid-category decomposition. **Blank is
invalid here**, unlike the valid Blank voting option in the 2003 referendum.

The national final JSON individually identifies **100 parties with positive
votes**. Their sum is 4,198,011; the residual `rosterOvrigaPartier` is zero.
All these positive party codes reconcile through the lower-level results.
The other 22 distinct codes in the participation CSV have no positive national
party row; absence of a row is not a newly published zero-valued observation.
There is no undisclosed positive national residual requiring allocation.

## Candidate, candidacy and preference-vote coverage

The near-election and December CSVs each contain:

- 1,395 documented rows, 1,344 distinct candidate IDs, 74 parties;
- 1,390 valid rows, 1,340 valid IDs and 1,385 valid candidate-party pairs;
- 644 printed-list rows (`S`), of which 639 are valid; 751 rows without printed
  list status; 29 list numbers; no duplicate party/ID/list/position key;
- 23 valid IDs associated with multiple parties, and 28 valid IDs with multiple
  source rows. Multiple rows are not necessarily additional people.

Fields include official candidate number, ballot name, party, list/position,
validity, ballot status, consent/declaration, age/sex, registered municipality,
ballot information and number of ballots. Names are present; this is not a
2018-style redacted-name source. Valmyndigheten documents candidate number as
an election-occasion identifier shared by multiple candidacies. Name alone is
not an identity key; consent-only names and printed-ballot names have different
source semantics. Preserve these distinctions rather than normalising names.

The [8 June announcement](https://www.val.se/servicelankar/servicelankar/pressrum/nyheter--pressmeddelanden/pressmeddelande-nya/2024-06-08-1-340-kandiderar-i-arets-eu-val---har-ar-listan)
confirms 1,340 people and 23 multi-party candidates, but reports **1,391
candidacies**. That is one more than valid rows in either later snapshot.
The announcement and dated snapshots are not identical populations. The approved final population is COMPLETE WITH SPECIFIED EXCEPTIONS, using the later snapshot and explicitly excluding the historical-only record for candidate 1203. See the
[follow-up reconciliation](EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md): the
recovered 9 June snapshot has 1,391 valid rows and includes candidate 1203,
`Österberg, Felix`, Folklistan, absent from both later files. It has 1,341
valid IDs, not the announced 1,340; the reason for removal is not established. The full
published CSV snapshot itself has been inventoried completely; this does not
prove that a particular later snapshot equals the 8 June register.

Between June and December, no party/ID/list/position key or validity flag changes.
There are seven name changes, 28 party-abbreviation changes, 1,382 registered-
municipality changes and 21 ballot-quantity changes. The implementation explicitly selects the December snapshot as the approved later source, preserving its attributes without combining different snapshots. Retain all four snapshots as provenance. Candidate 1203 remains excluded from the final population; its administrative removal reason remains unknown and requires no further recovery for this implementation. See the linked follow-up for exact hashes.

### Reported preference votes: COMPLETE

- 393,607 positive district × party × list × candidate observations;
- all 6,589 districts represented, including all 314 collection units;
- 1,914,494 votes, 630 distinct IDs;
- national result contains 635 positive party/list/candidate rows, also totaling
  1,914,494; every key agrees with district aggregation;
- all 393,607 workbook records match JSON keys and values exactly, with no
  duplicate district/party/list/ID keys;
- 109,611 district-list controls and 129 national-list controls reconcile the
  reported list preference total to identified candidate votes, with zero failures;
- all 635 national positive rows match the candidate CSV on **party, list,
  candidate ID and position**, without using names; nine printed-list rows have
  no positive national preference record.

The Excel geographic notation `E-01-36-0100`, for example, corresponds to JSON
collection code `013601`, not a new eight-digit ordinary district. The audit
used an explicit existence-checked mapping; naive numeric padding gives false
missing matches. The same source distinction occurs in the final result Excel.

Five positive national rows (2,324 votes) are explicitly `[Ej valbar]` and have
invalid candidacy flags in the CSV:

| Party | Candidate ID | List | Position | Votes |
| --- | ---: | --- | ---: | ---: |
| 0003 | 451 | 0003-06367 | 42 | 26 |
| 0110 | 279 | 0110-06247 | 12 | 1,913 |
| 0110 | 304 | 0110-06247 | 37 | 359 |
| 1659 | 760 | 1659-06387 | 6 | 24 |
| 1472 | 516 | 1472-06287 | 5 | 2 |

These are reported preference observations, not missing data. Candidate 279 also
has a valid candidacy for another party. Do not drop these votes by joining only
valid candidacies, infer that they confer eligibility, or invent names from the
placeholder. The decision's list appendix independently retains the ineligible
L/SD rows. National party/list `90000` entries have zero identified preference
votes and empty candidate arrays; do not invent a candidate for those ballots.

County/municipality preference totals can be produced from disjoint district
observations. The national constituency is the EU person-election area; a county
or municipality aggregate is not a new area of legal personal qualification.

## Mandates, elected persons and term information

The original decision is dated **2024-06-14, VAL-246-2024**. Allocation and
original relations are present in national `mandatfordelning`/`valda` JSON and
the decision appendices:

| Party | Allocated seats | Original elected persons |
| --- | ---: | ---: |
| S | 5 | 5 |
| M | 4 | 4 |
| MP | 3 | 3 |
| SD | 3 | 3 |
| V | 2 | 2 |
| C | 2 | 2 |
| L | 1 | 1 |
| KD | 1 | 1 |
| Total | 21 | 21 |

All 21 elected IDs are present in the candidate CSV. There are zero unfilled
positions. There are 27 distinct original substitute IDs/party-candidate pairs;
the nested JSON repeats the groups across elected persons, yielding 77
member-substitute relation rows. These are different observation counts, not 77
distinct substitutes. Original election order, election basis, substitute order
and group are available. The decision's original list has the same 21/27 counts.

The [current-members page](https://www.val.se/valresultat-och-statistik/eu-val/nuvarande-och-avgangna-ledamoter)
was inspected and preserved. It lists 21 current members and explains the
replacement responsibility. It does not supply a verified complete dated event
history. Do not use it to redefine the June election result or infer that no
term events have occurred.

## Electorate and independent SCB comparison

The SCB result sheet has **6,275 ordinary districts plus 290 merged municipal
collection/postal rows** (codes ending `9800`): 6,565 records. This explains the
24-row difference from Valmyndigheten's 6,589 units; it is not missing votes.

The newly retrieved official SCB district table and the local workbook's result
sheet match all 22 columns after removing the local separator row. Every ordinary
district matches Valmyndigheten on eligible voters, cast/valid/invalid/blank
counts and each of M/C/L/KD/MP/S/V/SD. Municipality sums, including SCB's merged
collection rows, match all 290 municipalities on cast/valid/invalid/blank votes,
the eight parties and the residual other-party sum. The official county table
also matches all 21 counties and the nation on electorate and these ballot totals.
No substantive result discrepancy was found.

SCB additionally provides, for every ordinary district:

| Electorate group | National sum |
| --- | ---: |
| Swedish citizens resident in Sweden | 7,708,624 |
| Swedish citizens resident abroad | 190,459 |
| Foreign EU citizens resident in Sweden | 43,189 |
| Sum | 7,942,272 |

The decomposition reconciles for every ordinary district and can be aggregated
to all municipalities, counties and the nation. The Valmyndigheten age/sex/
citizenship workbook also has all 6,275 ordinary districts and agrees with SCB
on every district total. The 290 SCB collection rows have null electorate groups;
all 314 Valmyndigheten collection units have null electorate/turnout. These are
not separate voter populations and must remain null, with no downward allocation.

Earlier qualification-day electorate (7,946,261 on 10 May) differs from the final
7,942,272 and must not be substituted in final turnout. Overseas voting-card
counts are another measure. The enriched SCB `Blad1` sheet offers additional
socioeconomic context but is not a primary result/candidate source; no individual
candidate or mandate-period records were found in it.

## Preliminary counting stages

**COMPLETE:** the preserved preliminary JSON ZIP is the 13 June snapshot with
6,589/6,589 units: 6,275 ordinary plus 314 collection units, all with reported vote
categories. It totals 4,238,751 cast = 4,178,527 valid + 60,224 invalid; blank
32,474, no participation notice 1,844, other invalid 25,906. All arithmetic and
published party aggregates reconcile. Eight report parties are individually
reported; 93,382 valid votes remain in the preliminary other-party category.
Do not borrow final small-party detail or final candidate votes for this stage.

The **11 June preliminary Excel is a different snapshot**, describing
vallokal counting. Its national cast total is 4,027,533 and its electorate is
7,946,261. It is useful historical evidence but not a substitute for the later
complete preliminary JSON. Differences from final/13 June data are therefore
counting-stage/snapshot/denominator differences, not evidence of lost final votes.
A separate original election-night freeze has NOT VERIFIED coverage: the workbook
is an 11 June snapshot, not proof of a freeze on election night. No additional
recovery is required for final implementation and none was attempted broadly.

## Completeness matrix

COMPLETE means coverage of the explicitly named population has been checked;
it does not assert completeness for a different date, observation unit or field.

| Dimension | Status | Exact scope / missing information |
| --- | --- | --- |
| Final party votes, national/county/municipality | COMPLETE | 1 / 21 / 290; all positive national parties separately identified (100); zero national residual. |
| Final district party votes and ballot categories | COMPLETE | 6,275 ordinary + 314 collection units; zero missing units/categories. |
| Final invalid decomposition | COMPLETE | Blank, no participation notice, other invalid; all 6,901 geographic nodes reconcile. |
| Final electorate/turnout | COMPLETE | All ordinary districts and their national/county/municipal aggregates; not applicable to collection units (314 null denominators). |
| Three-group electorate composition | COMPLETE | All 6,275 ordinary districts, and sums to 290 municipalities/21 counties/nation; collection units have no separate electorate. |
| Age/sex/citizenship electorate table | COMPLETE | 6,275 ordinary districts, total 7,942,272; no collection-unit allocation. |
| Published June/December candidacy snapshot records | COMPLETE | All 1,395 rows and 23 fields inspected; no duplicate candidacy key. |
| Final candidacy population (approved later snapshot) | COMPLETE WITH SPECIFIED EXCEPTIONS | All 1,395 documented rows, 1,390 valid rows, 1,340 valid IDs. Historical candidate 1203/Folklistan is excluded as approved; present only in the recovered earlier snapshot. Removal reason remains unknown and is not a blocker. |
| Published 11 June valid candidate-ID population | COMPLETE | 1,340 in that dated snapshot, matching the announcement count; the recovered 9 June snapshot has 1,341. Do not equate these dated populations. |
| Reported candidate/list preference observations | COMPLETE | 393,607 positive district rows, 635 national rows, 1,914,494 votes; all 6,589 units and all list controls checked. |
| Allocated mandates / elected / unfilled | COMPLETE | 21 / 21 / 0, original final election relation. |
| Original substitute relations | COMPLETE | 27 distinct substitutes; 77 nested member-substitute relations. |
| Complete dated mandate-period changes | NOT VERIFIED | No complete event log established; current roster is not an event history. |
| Full reported preliminary snapshot | COMPLETE | 13 June JSON, all 6,589 units; eight named parties plus aggregate others. |
| Separate election-night freeze | NOT VERIFIED | 11 June workbook available; no verified original election-night freeze. |
| Original final result source files | COMPLETE | All six members of national ZIP present, official index hash match. |
| SND 2024 comparison | NOT VERIFIED | No local 2024 SND source identified; not needed to replace the completed SCB controls. |

No substantive final party-result gap was identified. Not-verified dimensions
above must not be described as missing final party or reported preference votes.

## Implementation recommendation (no implementation in this task)

1. Extend the modern JSON source registry/read adapters for `EU-val_2024` and
   source election code `E`; the presentation route `EU` is not a different vote
   population. Reuse the modern normalisation/download/checksum infrastructure.
2. One national EU mandate/person-election constituency. Keep counties as
   administrative geography, preserve real municipal constituencies only where
   appropriate, and retain collection units without invented electorate.
3. All seven functions have the required original-result inputs. `results()` and
   `seats()` are ready; `elected()`/`substitutes()` use the fixed 14 June relation;
   `preference_votes()` preserves all reported list records, including ineligible
   placeholders; candidate enrichment must not filter their votes away.
4. Pin the approved later June/December candidate content by hash. Retain the
   recovered 9 June row for candidate 1203 as provenance only. Its unexplained
   disappearance is an approved snapshot exception and does not block any
   final-result function. No administrative explanation is inferred.
5. Keep 4% national party qualification and 5% personal qualification as the
   source's EU rules; do not copy RD/RF/KF geographic qualification semantics or
   introduce geographic mandates at county/municipality level.
6. Previous-seat comparisons explicitly use the **post-Brexit allocation from
   1 February 2020**, as stated in the JSON; do not treat that baseline as the
   original 2019 election-night allocation.
7. Add independent R validations for all counts/reconciliations above when
   implementing. Do not combine the preliminary Excel and ZIP as additive data,
   duplicate substitute groups as persons, or conflate Blank with a valid option.

At the source-inventory checkpoint, only this report was intended for Git. Original sources, downloaded controls,
extractions, audit R scripts/logs and the machine-readable provenance manifest
remain local/ignored. No package tests/check or canonical validation were run during the inventory itself. Subsequent implementation and validation are documented in [VALIDATION_EU_2024.md](VALIDATION_EU_2024.md).

## Original local source checksums

| Local file (under `.local-data/eu/2024/`) | Bytes | MD5 | SHA256 |
| --- | ---: | --- | --- |
| `kandidater/kandidaturer.zip` | 701 | `bfc3e51ce8832b91de577cbb152dcea4` | `590a635683dc28db5637f3c5c3b9eceb03faa5d1cd42a3abd708cc05dceb546f` |
| `kandidater/kandidaturer_20240618.zip` | 35200 | `44d0e3b78ceac552b5c1e0474f79713d` | `086b1a6fd50b5be85010753dff236f7ed0159555a59008a5edce1b3938bb94b8` |
| `kandidater/kandidaturer_20241218.zip` | 31878 | `59083de3a9f4d5e311aff415a2a0f76a` | `e049ca03eecc19b30bc4fb8f07389434f9c55080941f4114244f2e7b90ff84a4` |
| `rostning/fortidsroster_20240618.csv` | 268392 | `17a248a58072d1bcc553251b56334652` | `8b82606993e26fc066cc37fcb722e0d1e84d16c14950654fe432e3ad7bdd8c31` |
| `rostning/fortidsroster_20241218.csv` | 268725 | `6d292ed22524de573060db031da060e1` | `e13fa584459ba38817062e95398805aac1498d3209d46632156efc613a068c40` |
| `rostning/rostningslokaler.csv` | 718753 | `c4c0bb176403d980ff486aedbac2bfe4` | `baafb3a51ee6f0975e6eabe7fe8f53652c473c9d2845707ae53c88171aa36196` |
| `rostning/statistik-antal-utlandsrostkort-per-land-2024.xlsx` | 13195 | `7872a74f8363eeb900644f9a3ecdeb3f` | `f6d2d3cbcc27b1b4dcc3cb66348ef021c91b1677ea53e7623a4f11d8b56559f7` |
| `rostning/vallokaler.csv` | 1598530 | `9fcb2dbb797758503485780fb6dcdb5b` | `27a065273e3789a1df7799aa35b324f693b5c98ecbc50f01acce353f096b0f3e` |
| `valresultat/deltagande-partier_20240618.csv` | 12425 | `72a400dc3a81ab042d574bc906e3f159` | `375fa76b91b3cd7e4898b5b1f6b46f3324fa22ce91f3379b03b97af8e150630c` |
| `valresultat/deltagande-partier_20241218.csv` | 12425 | `72a400dc3a81ab042d574bc906e3f159` | `375fa76b91b3cd7e4898b5b1f6b46f3324fa22ce91f3379b03b97af8e150630c` |
| `valresultat/EU-val_2024_preliminar_00_E.zip` | 2096352 | `975ab289844c842685258de085d2acbd` | `f5a00cbf2ffefef8c1c4d06bdd7d85dfea181743c5a06de2955568757d2d98e9` |
| `valresultat/EU-val_2024_slutlig_00_E.zip` | 11139169 | `6e1b94b06e44a32f78e471f84b6f654b` | `f7368e9d273fbd0e75d700462e4d5758b10c6cd24be8e4025c81eda27041a69d` |
| `valresultat/personroster-EU-valet-2024.xlsx` | 32253566 | `65fc12df63efae145bef015a65db8633` | `1deb148a5623e27585507c7c8a14bef032771fbeabe6b57d5f3839aecd48f102` |
| `valresultat/preliminart-valresultat-europaparlamentet-2024-vallokalernas-rostrakning.xlsx` | 3880558 | `668900566a6ceea2f33c142ed6b54336` | `75cc7887954f765fe3e20b902f4ebd82ad6970eabf94d02f5a1d3d6364311285` |
| `valresultat/rostberättigade-uppdelat-pa-alder-och-kon-valdagen-den-9-juni-2024.xlsx` | 919195 | `3c5786c656b7843361de3c92e2d4323d` | `e2b28f0a4858e3d64fca77d78773aa7edea9ff2590fa5033818b19fc0cb99ad0` |
| `valresultat/scb/Valresultat valdistrikt EU2024.xlsx` | 3295115 | `48d8793a83e3cb39c7d6c6c922e18bae` | `6d857dfb0e0647043aab72189c6ebe7fc28f92a760745c1c27433529194af37d` |
| `valresultat/slutligt-valresultat-europaparlamentet-2024-vallokalernas-rostrakning.xlsx` | 9534323 | `15fcb16f4c63962bd66da70f7f8bb753` | `a8c1eb96f6a80ba219a866631f85aad0c29e18974572f72ee450908d6ea4cecb` |

## Additional official material preserved during this audit

These are separate audit copies; they do not replace any original local file.
Retrieval timestamps are UTC. Exact URLs and hashes follow.

| Audit copy | Source URL | Retrieved UTC | Bytes | MD5 | SHA256 |
| --- | --- | --- | ---: | --- | --- |
| `candidate-announcement.html` | https://www.val.se/servicelankar/servicelankar/pressrum/nyheter--pressmeddelanden/pressmeddelande-nya/2024-06-08-1-340-kandiderar-i-arets-eu-val---har-ar-listan | 2026-10-15 08:55:59 UTC | 213759 | `3fe8a2d18c9c6029eaa32607bb07b2c1` | `15c8cf29182c48009cb0957554b7eaf731fc89a442262af9e1256b2d964395d3` |
| `candidate_current.zip` | https://data.val.se/filer/euval2024/parti/kandidaturer.zip | 2026-10-15 08:48:43 UTC | 31878 | `59083de3a9f4d5e311aff415a2a0f76a` | `e049ca03eecc19b30bc4fb8f07389434f9c55080941f4114244f2e7b90ff84a4` |
| `decision.pdf` | https://www.val.se/download/18.162047b519a91d053311500c/1718379028498/val-till-europaparlamentet-2024-beslut-och-protokollsbilagor.pdf | 2026-10-15 08:48:44 UTC | 413603 | `5cbfaee8bbc1d8d2d3da6e60678b76f9` | `984b5c2fc9f9d6f8983d1398c8fd53262d12e3b82032e396acd1eeb573259258` |
| `index.md5` | https://resultat.val.se/resultatfiler/euval2024/index.md5 | 2026-10-15 08:48:43 UTC | 141 | `3837eca42e5cfe3240d2c67a728f0b62` | `584fbdee341db94b2128e3657b908c0f42ca6afdaebc37c3d5dfb328749f2ae8` |
| `members.html` | https://www.val.se/valresultat-och-statistik/eu-val/nuvarande-och-avgangna-ledamoter | 2026-10-15 08:46:05 | 214806 | `ef9d851b1cf0e03094e290eb5b59d935` | `06b7413d6576e0351ffbe498fff826b3828411f0d578491299a71a5a3d2775b3` |
| `portal.html` | https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-eu-val | 2026-10-15 08:46:04 | 241607 | `296f71d4d1df530c2432420669b1a16c` | `c14715980e6b72c0e3138b5e4e0b72a7dad51c01438167741159939fb0bbf9d5` |
| `protocol.pdf` | https://resultat.val.se/protokoll/protokoll_EU-val_2024_00_E.pdf | 2026-10-15 08:46:06 | 413603 | `5cbfaee8bbc1d8d2d3da6e60678b76f9` | `984b5c2fc9f9d6f8983d1398c8fd53262d12e3b82032e396acd1eeb573259258` |
| `result.html` | https://www.val.se/valresultat-och-statistik/eu-val/valresultat-2024 | 2026-10-15 08:46:05 | 217174 | `ab3745d54d6b88a0b653d93eadb6abe1` | `7d8e577b3bc8604e9821361d443747b77aa11125243c1ad91e91ff09f3776727` |
| `scb.html` | https://www.scb.se/ME0109 | 2026-10-15 08:48:43 UTC | 106845 | `6418b52c710181b0c15c93aa06dbf884` | `955ff4bb0de588e7f5461f88cb04f7696d258db8dac1a89a53c886883772cfff` |
| `scb_county.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-20242/valet-till-europaparlamentet-2024-efter-lan.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-parti | 2026-10-15 08:51:35 UTC | 17139 | `5a5f4c7c33f99a9739e749439c50cf6c` | `b3650089b217c4eac5548bdb3d17b6a9f2db82e3a7baee5008e7edee3aac8e67` |
| `scb_district.xlsx` | https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/allmanna-val/europaparlamentsval-valresultat/pong/tabell-och-diagram/huvudresultat-20242/valet-till-europaparlamentet-2024-efter-valdistrikt.-rostberattigade-rostande-och-giltiga-valsedlars-fordelning-efter-partier | 2026-10-15 08:51:35 UTC | 968174 | `eac2e71abea9c1c6b76c634c43898deb` | `ef56222813c767c8eba6ce9b19ac26a783c5e015210df2ce3c97d285fc768074` |

## Follow-up: exact candidacy recovered

See [EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md](EU_2024_CANDIDACY_SNAPSHOT_RECONCILIATION.md).
The original 17-file inventory remains an inventory of the pre-existing local
material. A fourth candidate snapshot has now been recovered from an archived
official export, generated 9 June and captured 10 June 2024. It has 1,396 rows,
including 1,391 valid rows and 1,341 valid IDs. Candidate 1203/Folklistan is
the sole key absent from the later June and December snapshots. Its full
source record and archive checksum are preserved. The deletion is verified;
a withdrawal, eligibility correction or other reason is not. This follow-up
supersedes any suggestion above that the affected row could not be identified.
No final result or preference-vote completeness conclusion is weakened.
