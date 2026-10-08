# 2010 source candidate-ID reconciliation — proposed provenance crosswalk

## Scope and fixed principle

Read-only analysis of all 39 preserved files under `.local-data/rkl/2010`, including every XML member of both ZIPs. The original audit was read-only. Subsequently approved exception H1 harmonises Björn Andersson across election types, without editing raw XML. Final election-result XML supplies the identity baseline, subject to this explicit person-specific harmonisation. A source ID remains a separate, source-specific identifier.

The accompanying `SOURCE_ID_CROSSWALK_2010_PROPOSED.csv` is a diagnostic proposal, not an activated lookup or a public/canonical asset. The original audit contained **219 source-context evidence rows, covering 177 distinct election-code × XML-ID × source-ID pairs**. The updated CSV has 220 evidence rows, including H1 XML provenance; `raw_xml_candidate_id` preserves the pre-harmonisation XML ID. The audit counts below refer to the original comparisons. Its year refers to the 2010 baseline being linked, not a claim that the later membership export is an election-day snapshot.

## Method

Parse final XML without resolving external DTDs. For every candidate-ID-bearing result record, retain election code and name. Index candidate/list records using election type, party, constituency, full result list number and ballot position. Match member rows using those structural fields first and require exact full-name agreement as corroboration. Ballot rows are matched through geography, list suffix and position; the official result-list prefix supplies the party code. Names are never used as the sole identity key.

RD matching uses the last two digits of `KRETS_RIKSDAG/@KOD`, corresponding to the ballot/member constituency code (e.g. XML 1010 → matching code 10). RF uses the full regional constituency code. KF uses county + municipality + municipal constituency; blank member constituency is matched to the explicitly present XML municipal constituency ending 00. This is a diagnostic matching key, not a new public geography or an edit to raw codes.

**E1:** unique XML candidate at the matching election/party/constituency/list/ballot-position key, with an exactly equal name. Every proposed evidence row passes this rule. There is no one-to-many mapping of a source ID to different canonical IDs within the same election code among these proposals.

**N1:** high confidence in source-record linkage, but the reason and date of the identifier change remain unverified. The crosswalk does not transfer current elected status, election order or accession date into the fixed election result. It does not prove global person identity across election types or years.

## Full-population comparisons

| Source | RD rows / IDs absent from final XML | RF rows / IDs absent | KF rows / IDs absent | Structurally linked ID-difference rows |
|---|---|---|---|---|
| alla_ursprungliga_ledamoter_RLK.skv | 349 / 0 | 1,662 / 0 | 12,969 / 4 | KF 4 |
| allaursprledRLK.skv | 349 / 0 | 1,662 / 0 | 12,969 / 4 | KF 4; byte-identical copy |
| nuvarande_ledamoter_RLK.skv | 349 / 2 | 1,662 / 87 | 12,893 / 178 | RD 2, RF 1, KF 162 |
| alkandur_R.skv | 9,425 structurally comparable result-list rows | — | — | 1 row, 1 ID pair |
| alkandur_L.skv | — | 26,939 comparable rows | — | 25 rows, 6 ID pairs |
| alkandur_K.skv | — | — | 73,475 comparable rows | 20 rows, 5 ID pairs |

The ballot comparison covers result list positions actually represented by candidate-person-vote XML, not every ballot candidate; absence of a result candidate record is not an ID discrepancy. The member comparison also scans all final XML candidate identifiers, including elected/substitute records.

Original-member source duplicates are retained as separate provenance rows but are not independent corroboration. Across member sources there are 168 distinct election-scoped ID pairs. Ballot sources contain 12 pairs, three overlapping member pairs: union 177. By election code the union is **RD 3, RF 6, KF 168**.

## Four original elected discrepancies

| Election | Canonical XML ID | Source ID | Name | Party | Constituency | List / position | Source files |
|---|---|---|---|---|---|---|---|
| KF | 517474 | 517493 | Jens Pettersson | SD / 110 | 186400 | 0110-04182 / 1 | both original-member exports; current-member export |
| KF | 518419 | 518426 | Henry Svärd | SD / 110 | 208102 | 0110-04572 / 7 | both original-member exports |
| KF | 518962 | 518969 | Stefan Kjell | SD / 110 | 176000 | 0110-04861 / 1 | both original-member exports |
| KF | 519214 | 519216 | Claes Swedenborg | SD / 110 | 198300 | 0110-04947 / 2 | both original-member exports |

For these four, names, ages, list identities/positions, elected geography and election order agree. KF area/list/district preference votes under the XML identifiers respectively agree at 4/4/4, 3/3/3, 3/3/3 and 3/3/3. Neither identifier of these pairs is present in the local alkandur ballot files. No alternative identifier belongs to another candidate in the searched final XML.

## Broader later-member pattern

The later current-member export contains 165 high-confidence structural ID-difference rows: RD 2, RF 1, KF 162. Of the KF rows, **149 are in county 14 (Västra Götaland)**; the remaining 13 are spread across counties 01, 03, 06, 08, 12, 17, 18, 21 and 22. Exact names agree in all 165 rows.

Examples beyond the original four:

| Election | Canonical ID | Current-member ID | Name | Party | Constituency | List / position |
|---|---|---|---|---|---|---|
| RD | 466949 | 485369 | Stefan Caplan | M | 17 | 0001-00102 / 3 |
| RD | 473963 | 473981 | Penilla Gunther | KD | 18 | 0068-02855 / 1 |
| RF | 495085 | 495139 | Britt Engqvist | SD | 1704 | 0110-03606 / 2 |
| KF | 518960 | 518967 | Magnus Wallo | SD | 176000 | 0110-04860 / 1 |
| KF | 517476 | 517512 | Roger Sahlberg | SD | 186400 | 0110-04201 / 1 |

Magnus Wallo and Roger Sahlberg illustrate why this is identity linkage rather than a rewrite of election-time elected relations: the member export includes accession dates 2011-11-11 and 2013-06-03, respectively.

The geographic concentration is consistent with a later identifier/snapshot change associated with the 2011 re-election context, but the local files do not document its cause. This is **a hypothesis, not a verified correction mechanism**. Official evidence confirms the 15 May 2011 re-elections in Västra Götaland RF and Örebro’s northeastern KF constituency:
https://historik.val.se/val/om2011/statistik/index.html

## Ballot-source discrepancies and cross-election caution

Five SD candidate-ID pairs recur across KF Karlstad lists 0110-03337 and 0110-03749, constituencies 178001/178002, and RF list 0110-03606:

| Canonical ID | Ballot/source ID | Name |
|---|---|---|
| 495085 | 495139 | Britt Engqvist |
| 495088 | 495140 | Margaretha Nilsson |
| 495091 | 495141 | Ida Martinsson |
| 495101 | 495142 | Rebecca Nilsson |
| 495100 | 495143 | Marita Gustafsson |

Only XML-observed positions are proposed; repeated source contexts remain distinct evidence rows.

Two further **election-specific** FP ballot pairs concern Björn Andersson:
- RD constituency 03, list 0003-03600, position 22: source 497359 → XML 442089.
- RF constituency 0303, list 0003-03159, position 6: source 442089 → XML 451964.

These were the original source/XML comparisons. Under approved rule H1 below, RF XML 451964 is harmonised to canonical 442089; the RF ballot-source ID is already 442089. RD source 497359 remains a separately documented ballot-source linkage. Neither comparison authorises a global numeric replacement.

## Unresolved/non-comparable current-member rows

There are **102** current-member rows with an ID absent from final XML and no exact structural list-position match: **86 RF**, all county 14, and **16 KF**. No RD rows remain in this category. These are not counted as confirmed ID discrepancies and receive no canonical ID proposal.

The 86 RF rows use later lists absent from the preserved 2010 result positions and lie in the 2011 re-election region. They require the separate re-election source before an identity mapping or election-result interpretation is made. The 16 KF cases may include later entrants with no candidate-person-vote result record; their exact absence does not establish an identifier change. Ballot availability is listed below as additional evidence, not an automatic XML ID assignment.

| Election | Source ID | Source name | Party | Matching constituency | Source list / position | Present in local ballot file | Accession date |
|---|---|---|---|---|---|---|---|
| RF | 523009 | Johnny Magnusson | M | 1401 | 0001-05325 / 1 | no | not supplied |
| RF | 523010 | Lisbeth Sundén Andersson | M | 1401 | 0001-05325 / 2 | no | not supplied |
| RF | 523011 | Agneta Granberg | M | 1401 | 0001-05325 / 3 | no | not supplied |
| RF | 523012 | Johnny Bröndt | M | 1401 | 0001-05325 / 4 | no | not supplied |
| RF | 523013 | Mimmi von Troil | M | 1401 | 0001-05325 / 5 | no | not supplied |
| RF | 523014 | Peter Hermansson | M | 1401 | 0001-05325 / 6 | no | not supplied |
| RF | 523015 | Henrik Ekelund | M | 1401 | 0001-05325 / 7 | no | not supplied |
| RF | 523016 | Johan Fält | M | 1401 | 0001-05325 / 8 | no | not supplied |
| RF | 523017 | Kristina Holmgren | M | 1401 | 0001-05325 / 9 | no | not supplied |
| RF | 523018 | Magnus Palmlöf | M | 1401 | 0001-05325 / 10 | no | not supplied |
| RF | 523019 | Erland Lundell | M | 1401 | 0001-05325 / 11 | no | not supplied |
| RF | 523023 | Börje Olsson | M | 1401 | 0001-05325 / 15 | no | 2014-04-15 |
| RF | 523021 | Nils-Erik Wangler | M | 1401 | 0001-05325 / 13 | no | not supplied |
| RF | 523022 | Susanna Cassberg | M | 1401 | 0001-05325 / 14 | no | not supplied |
| RF | 527247 | Roland Norlén | C | 1401 | 0004-05344 / 2 | no | 2013-09-24 |
| RF | 526865 | Helena Holmberg | FP | 1401 | 0003-05380 / 3 | no | not supplied |
| RF | 526863 | Rosie Rothstein | FP | 1401 | 0003-05380 / 1 | no | not supplied |
| RF | 526864 | Lars Nordström | FP | 1401 | 0003-05380 / 2 | no | not supplied |
| RF | 526866 | Mariella Olsson | FP | 1401 | 0003-05380 / 4 | no | not supplied |
| RF | 530088 | Magnus Berntsson | KD | 1401 | 0068-05357 / 1 | no | not supplied |
| RF | 531141 | Kerstin Brunnström | S | 1401 | 0002-05334 / 1 | no | not supplied |
| RF | 531142 | Leif Blomqvist | S | 1401 | 0002-05334 / 2 | no | not supplied |
| RF | 531143 | Ulla Y Gustafsson | S | 1401 | 0002-05334 / 3 | no | not supplied |
| RF | 531145 | Vivi-Ann Nilsson | S | 1401 | 0002-05334 / 5 | no | not supplied |
| RF | 531146 | Håkan Werner Linnarsson | S | 1401 | 0002-05334 / 6 | no | not supplied |
| RF | 531147 | Gladys Yannelli | S | 1401 | 0002-05334 / 7 | no | not supplied |
| RF | 531150 | Henrik Johansson | S | 1401 | 0002-05334 / 10 | no | not supplied |
| RF | 531151 | Beatrice Toll | S | 1401 | 0002-05334 / 11 | no | not supplied |
| RF | 531156 | Dragan Dobromirovic | S | 1401 | 0002-05334 / 16 | no | 2013-02-05 |
| RF | 531155 | Shilan Majid Abdulrahman | S | 1401 | 0002-05334 / 15 | no | not supplied |
| RF | 450493 | Elise Norberg Pilhem | V | 1401 | 0005-05349 / 1 | no | not supplied |
| RF | 530433 | Sören Kviberg | V | 1401 | 0005-05349 / 2 | no | not supplied |
| RF | 530437 | Nadia Mousa | V | 1401 | 0005-05349 / 6 | no | 2012-02-07 |
| RF | 530438 | Lars-Erik Hansson | V | 1401 | 0005-05349 / 7 | no | 2013-01-01 |
| RF | 530436 | Lars Engen | V | 1401 | 0005-05349 / 5 | no | not supplied |
| RF | 480809 | Birgitta Losman | MP | 1401 | 0055-05350 / 1 | no | not supplied |
| RF | 530856 | Joakim Larsson | MP | 1401 | 0055-05350 / 2 | no | not supplied |
| RF | 227788 | Max Andersson | MP | 1401 | 0055-05350 / 4 | no | not supplied |
| RF | 248656 | Monica von Martens | MP | 1401 | 0055-05350 / 5 | no | not supplied |
| RF | 530860 | Elias Ytterbrink | MP | 1401 | 0055-05350 / 6 | no | not supplied |
| RF | 479138 | Patrik Ehn | SD | 1401 | 0110-05376 / 1 | no | not supplied |
| RF | 479148 | Daniel Rondslätt | SD | 1401 | 0110-05376 / 2 | no | not supplied |
| RF | 479145 | Thomas Åvall | SD | 1401 | 0110-05376 / 3 | no | not supplied |
| RF | 523046 | Annika Tännström | M | 1402 | 0001-05326 / 1 | no | not supplied |
| RF | 485404 | Arne Lernhag | M | 1402 | 0001-05326 / 7 | no | not supplied |
| RF | 245768 | Clas-Åke Sörkvist | C | 1402 | 0004-05343 / 4 | no | not supplied |
| RF | 245770 | Kristina Jonäng | C | 1402 | 0004-05343 / 1 | no | not supplied |
| RF | 488069 | Jonas Andersson | FP | 1402 | 0003-05336 / 1 | no | not supplied |
| RF | 486425 | Birgitta Adolfsson | FP | 1402 | 0003-05336 / 2 | no | not supplied |
| RF | 473635 | Benny Strandberg | KD | 1402 | 0068-05359 / 1 | no | 2011-11-29 |
| RF | 530364 | Karin Engdahl | S | 1402 | 0002-05333 / 1 | no | not supplied |
| RF | 530367 | Evert Svenningsson | S | 1402 | 0002-05333 / 4 | no | not supplied |
| RF | 472807 | Anders Nilsson | S | 1402 | 0002-05333 / 8 | no | not supplied |
| RF | 530372 | Birgitta Evans | S | 1402 | 0002-05333 / 9 | no | not supplied |
| RF | 484538 | Jan Alexandersson | V | 1402 | 0005-05348 / 1 | no | not supplied |
| RF | 529819 | Matz Dovstrand | SD | 1402 | 0110-05377 / 3 | no | 2014-02-12 |
| RF | 487813 | Birgit Martinsson | SD | 1402 | 0110-05377 / 2 | no | not supplied |
| RF | 527675 | Stig-Olov Tingbratt | C | 1403 | 0004-05340 / 1 | no | not supplied |
| RF | 449744 | Bo Carlsson | C | 1403 | 0004-05340 / 3 | no | 2013-02-05 |
| RF | 508952 | Kristina Grapenholm | FP | 1403 | 0003-05338 / 2 | no | not supplied |
| RF | 474822 | Ulrik Hammar | FP | 1403 | 0003-05338 / 1 | no | not supplied |
| RF | 473983 | Gunilla Gomér | KD | 1403 | 0068-05358 / 3 | no | not supplied |
| RF | 473987 | Monica Selin | KD | 1403 | 0068-05358 / 1 | no | not supplied |
| RF | 526585 | Gert-Inge Andersson | S | 1403 | 0002-05331 / 1 | no | not supplied |
| RF | 486496 | Jim Aleberg | S | 1403 | 0002-05331 / 3 | no | not supplied |
| RF | 526591 | Bijan Zainali | S | 1403 | 0002-05331 / 7 | no | not supplied |
| RF | 526594 | Christin Slättmyr | S | 1403 | 0002-05331 / 10 | no | not supplied |
| RF | 484014 | Helen Persgren | MP | 1403 | 0055-05353 / 1 | no | not supplied |
| RF | 483997 | Lars-Erik Strömbergson | MP | 1403 | 0055-05353 / 2 | no | not supplied |
| RF | 525664 | Christina Brandt | M | 1404 | 0001-05327 / 3 | no | not supplied |
| RF | 525665 | Berndt Andersson | M | 1404 | 0001-05327 / 4 | no | not supplied |
| RF | 476193 | Patric Cerny | FP | 1404 | 0003-05335 / 2 | no | not supplied |
| RF | 483474 | Helén Eliasson | S | 1404 | 0002-05332 / 1 | no | not supplied |
| RF | 529159 | Krister Andersson | S | 1404 | 0002-05332 / 2 | no | not supplied |
| RF | 529160 | Hanne Jensen | S | 1404 | 0002-05332 / 3 | no | not supplied |
| RF | 466279 | Gunnel Brandt | S | 1404 | 0002-05332 / 5 | no | not supplied |
| RF | 483499 | Per-Åke Magnusson | S | 1404 | 0002-05332 / 6 | no | not supplied |
| RF | 480906 | Staffan Falk | MP | 1404 | 0055-05354 / 2 | no | not supplied |
| RF | 487780 | Fredrik Lind | SD | 1404 | 0110-05381 / 4 | no | 2013-02-05 |
| RF | 525767 | Tord Gustafsson | M | 1405 | 0001-05329 / 4 | no | not supplied |
| RF | 442338 | Linnéa Hultmark | C | 1405 | 0004-05341 / 2 | no | not supplied |
| RF | 495637 | Conny Brännberg | KD | 1405 | 0068-05356 / 1 | no | not supplied |
| RF | 495475 | Dan Hovskär | KD | 1405 | 0068-05356 / 3 | no | not supplied |
| RF | 525968 | Hasse Andersson | S | 1405 | 0002-05330 / 7 | no | not supplied |
| RF | 183484 | Claes-Göran Borg | V | 1405 | 0005-05345 / 1 | no | not supplied |
| RF | 487785 | Hanna Wigh | SD | 1405 | 0110-05379 / 2 | no | not supplied |
| KF | 499037 | Jan Rundqvist | M | 019200 | 0001-03608 / 22 | yes | 2013-10-15 |
| KF | 433959 | Bo Grennhag | M | 068003 | 0001-01169 / 33 | yes | 2014-06-03 |
| KF | 109136 | Alve Larsson | SPI | 128400 | 0107-01058 / 9 | yes | 2014-03-03 |
| KF | 417388 | Regina Hermansson | S | 186000 | 0002-02569 / 23 | yes | 2013-04-26 |
| KF | 417392 | Ingegerd Magnusson | S | 186000 | 0002-02569 / 27 | yes | 2014-06-05 |
| KF | 488101 | Thomas Eklund | V | 186300 | 0005-01566 / 7 | yes | 2014-06-19 |
| KF | 436157 | Olof Fernquist | S | 190400 | 0002-00266 / 22 | yes | 2014-05-13 |
| KF | 434705 | Martti Narkiniemi | V | 198200 | 0005-02765 / 36 | yes | 2014-01-02 |
| KF | 520547 | Åsa Berg | MP | 206200 | 0055-05306 / 7 | no | 2012-07-20 |
| KF | 518389 | Ann-Katrin Löfwenhamn | SD | 208102 | 0110-04555 / 1 | no | 2010-12-03 |
| KF | 520561 | Kjell Hedman | SD | 210400 | 0110-05310 / 1 | no | 2012-10-09 |
| KF | 520566 | Nicklas Danielsson | SD | 210400 | 0110-05311 / 5 | no | 2012-10-09 |
| KF | 517873 | Mikael Hamrén | SD | 218200 | 0110-04324 / 8 | no | 2014-04-09 |
| KF | 517872 | Peter Andersson | SD | 218200 | 0110-04324 / 7 | no | 2013-06-17 |
| KF | 262284 | Erling Sandström | S | 240300 | 0002-00166 / 16 | yes | 2014-06-24 |
| KF | 135587 | Sven-Anders Holmström | C | 250600 | 0004-00699 / 9 | yes | 2012-12-05 |

## Other files

All three alkandur files, both original exports, current-member export, RD candidate-preference-vote SKVs, both full ZIPs and other local text/XML sources were considered. Departure file `avgang.skv` has no candidate-number field; it can corroborate party/geography/event names and dates but cannot establish an ID crosswalk using names alone. Mandate/result Excel/SKV files are party/geography aggregate tables and supply no additional person-ID crosswalk. Voting-location/electorate/handwritten-party files likewise cannot adjudicate candidate identity.

## Provenance

Final result ZIP MD5: `e758499f800cfbc49ce02c54c3d1dd79`.
Final result ZIP SHA256: `2d598343995a387a8cd1e57520d5d39e1dd2b767ec6b837ef59f50a85485bc7b`.
Both original-member exports MD5: `0e7bd5917429979906d92adf7203a3fe`.
Current-member export MD5: `2b5b6f22d5ebe1aa57af8629f63cf5ae`.
Each crosswalk row also records its actual source-file MD5. File modification dates do not establish correction dates or canonical source priority.

## Recommendation

Keep raw XML IDs immutable in the source files. Use one canonical person ID per election occasion across RD/RF/KF, with the explicitly approved H1 exception below. Retain each source’s own ID with source hash, election occasion and provenance. The 219 proposed evidence rows can support later linkage after review; they are not active package mappings. Preserve unresolved rows separately. Ask Valmyndigheten about the identifier-update mechanism, particularly the large county-14 cluster and election-specific Björn Andersson chain. Do not import later membership or re-election relations into the fixed 2010 result.

## H1 — approved Björn Andersson identity harmonisation

Canonical identity for the 19 September 2010 election occasion: **442089**, shared
across RD/RF/KF. The RF final XML contains raw ID **451964**. This is an explicit,
user-approved identity harmonisation, not an official correction notice and not
a global number substitution. The seven weaker name-based cases remain unmerged.

Evidence:

| Election | Ballot source ID | Raw final XML ID | Canonical ID | Geography | List / position | Area preference votes |
|---|---|---|---|---|---|---|
| RD | 497359 | 442089 | 442089 | Uppsala RD constituency 03 | 0003-03600 / 22 | 10 |
| RF | 442089 | 451964 | 442089 | Uppsala läns norra 0303 | 0003-03159 / 6 | 8 |
| KF | 442089 | 442089 | 442089 | Tierp 036000 | 0003-03118 / 1 | 25 |

RF/KF ballot rows share the source candidate ID, party and compatible geography;
list numbers and positions independently connect those rows to the XML. RD/KF
XML already uses 442089. No name-only join is used. RF 451964 occurs only in RF;
442089 does not already occur in RF XML, so the mapping creates no within-file
candidate collision. Demographic snapshot variations are not silently corrected.

### Implementation boundary and impact

`R/candidate_identity_2010.R` provides `.xml2010_candidate_identity()`. It copies
the parsed document before changing `KANDNR` and returns per-node provenance
(source file, XPath, raw source ID, canonical ID, occasion and rule). It requires
the exact election date, final RF report, FP party and constituency 0303; list
records also require 0003-03159 / position 6. Unexpected contexts or candidate
collisions fail instead of silently applying a broader replacement.

There is **no public 2010 reader/API yet**. The future 2010 reader must apply this
adapter before normalised candidate joins, preference-vote aggregation and
relationship extraction, retaining its provenance separately. This change does
not claim to enable 2010 public support, activate the other proposed source-ID
mappings, or modify any existing 2014/2018/2022/2026 reader.

In the preserved ZIP, affected RF nodes are preference-vote nodes, not elected
or substitute nodes. Their votes and every non-ID attribute remain unchanged;
no geographic/list/area records are dropped or merged. Area and district counts
remain separate: 8 RF area votes are not added again to the district/list copies.
RD/KF records are unchanged. Björn's KF elected relationship retains its existing
442089 ID. If a future source introduces an affected relation in the verified
context, its ID must be harmonised through the same boundary, not separately.

The updated diagnostic CSV records RF canonical 442089 and raw XML 451964, and
adds an XML provenance row. Raw sources and canonical assets remain untouched.

### Preserved-source verification

All 872 final XML members were checked through the adapter. Only 16 candidate-ID
attributes change: 2 in `slutresultat_00L.xml`, 12 in `slutresultat_0360L.xml`, and
2 in `slutresultat_0382L.xml`. All are `PERSONVAL` records. Reverting those IDs
reproduces each entire input XML document exactly; no other attributes, nodes,
votes, ordering or relationships change. The area values remain RD 10, RF 8 and
KF 25 (district/list copies are not added to those area observations).

The ZIP MD5 remains `e758499f800cfbc49ce02c54c3d1dd79`. A reproducible opt-in
regression is included in `test-candidate-identity-2010.R`; set
`SWELECTIONS_2010_IDENTITY_ZIP` to the preserved final ZIP. Ordinary unit tests
use deterministic fixtures and need neither local raw data nor network access.
