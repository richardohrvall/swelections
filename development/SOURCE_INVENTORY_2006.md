# 2006 source inventory and implementation assessment

Reviewed 2026-10-11, against repository commit `5d86cb67454107049bfe526a41ddc25f30cfe9bc`.
This is a source review, not a canonical build or an approval of a candidate population.

## Findings and limits

Final party results, turnout and mandate allocation have accessible official XML sources for RD/RF/KF. Election-night XML is also accessible. A separate, complete preliminary collection-district snapshot has **not been located**; the final Wednesday-district figures must not substitute for it.

The largest local 2006 archive, `valresultat/xml.zip`, actually contains **ballot/candidacy XML**, not result XML. Every nested archive was inspected. It contains no candidate identifier. Current public result XML also lacks candidate-number attributes in the national RD/RF files and the municipal files inspected. List-level `PERSONVAL@KANDIDAT` is a ballot-position reference, not a globally unique candidate number. Thus the existing candidate-keyed APIs cannot yet be populated reliably merely by adapting the 2014 parser.

Scope: the complete local `rkl/2006` tree, project-wide filename/reference searches for 2006 material, the four derived 2006 party lookups, and the configured external archive's directory structure were checked. The external archive contains 2026 sources, not a separate 2006 collection. Unrelated archives for other years were not exhaustively unpacked. All 313 nested ZIPs in the identified 2006 source were opened. Official indexes, national files and selected municipal/constituency/district pages were inspected independently. The 872 individual files in each web result index were **not all downloaded or content-validated**. Index coverage and sampled content must not be confused with a completed national integrity sweep.

## Local source inventory

Paths below are relative to `.local-data/rkl/2006/`. Modification times are filesystem metadata, **not evidence of retrieval or publication dates**.

| Path | Bytes | Local modification time | Actual role and coverage |
|---|---:|---|---|
| `valresultat/xml.zip` | 3,312,906 | 2011-11-21 14:44:19 | Ballot/candidacy snapshot; RD/RF/KF; nested XML; not party-vote result data |
| `kandidater/avgang.xml` | 3,014,386 | 2018-01-13 18:59:03 | Aggregate mandate-period departures, report timestamp `20101108101908`; R/L/K; not original elected relations |
| `rostning/Mottagnafortidsroster_perdagochstalle_2006.xls` | 392,704 | 2011-11-21 14:45:17 | Advance ballots received by polling location/day; one worksheet, 1,792 physical rows, 23 columns including title/header rows; not election-specific counted votes |
| `rostning/oppet2006.xls` | 296,960 | 2018-04-22 13:56:19 | Advance-polling opening hours; one worksheet, 1,788 physical rows, four columns including title/header rows; operational geography, not results |
| `rostning/kommun_bestallda_valsedlar_SD_2006.txt` | 6,207 | 2011-11-21 15:55:13 | 132 data lines, county/municipality names identifying SD ballot-order municipalities; no candidate IDs or vote counts; name-only validation context |

The XML content, reporting labels and geography strongly support Valmyndigheten origin for the two XML sources. However, no original retrieval manifest or complete official-URL/checksum pairing was found for these five files. The operational spreadsheets/text have plausible official content but their filenames alone do not establish provenance. Neither spreadsheet's row count establishes national completeness of polling locations. Preserve them as historical snapshots; do not promote them to result inputs.

### Source checksums

| File | MD5 | SHA256 |
|---|---|---|
| `xml.zip` | `cdf5e7f9caa29cdf679f4b051cc79571` | `812b0f997e47cd937e3b21ef9bcffedf9c04ccc320152bba017cf616ec48e758` |
| `avgang.xml` | `d230d9111fdc9c52e95f71fe64bb85f3` | `b512484a9731b86e203b11422d8ee1afdb1180b8bb30d2d4eb47272bf9a5beff` |
| `Mottagnafortidsroster_perdagochstalle_2006.xls` | `c9c29a13f846aa0d62af5c138b57a1f1` | `9141c1efd5c33bd82bdadd9a737128480e62544f0de755c24e7ff94148db4783` |
| `oppet2006.xls` | `798a1591d8b4dbc07006dae7fb2ca5bb` | `84b35e0d4fa48b93f782dbea44d9a3400755210a73969c479fab0756f381b992` |
| `kommun_bestallda_valsedlar_SD_2006.txt` | `49870ddd3bf34bce7b00ef6467d4d86c` | `108acc035d2ea8934165cc9776c3ed4cf64c82e970b92242dfdd57c89d7c2989` |

### Ballot archive: complete structural inspection

There are **313 outer ZIP members**, each containing one XML document: one RD national file, 20 RF area files plus a national summary, and 290 KF municipality files plus a national summary. Internal timestamps are 2006-09-25; XML `TID_RAPPORT` ranges from `20060925050502` to `20060925050831`. All roots are `VAL`, with `RAPPORTERING="Valsedlar"`, `VALTYPKOD=R/L/K` and the 17 September 2006 election occasion.

| Election | XML documents | KANDIDAT occurrences | VALSEDEL occurrences |
|---|---:|---:|---:|
| RD | 1 | 20,926 | 1,076 |
| RF | 21 | 46,498 | 2,475 |
| KF | 291 | 86,398 | 4,069 |
| Total | 313 | 153,822 | 7,620 |

These are **source occurrences, not unique persons**. Repeated candidates/lists across constituencies cannot be deduplicated safely without identity evidence. The national RF/KF files contain summaries, not candidate records.

Available fields:

- Geography: `OMRÅDE`, `LÄN`, `VALKRETS`, `KOMMUN`, `LANDSTING`, with code/name attributes where present.
- Party: `PARTI@KOD`, `BETECKNING`.
- Ballot: `VALSEDEL@LISTNUMMER`, `VALKRETSNAMN`, `STATUS`, `KANDIDATANMÄLAN`.
- Candidate occurrence: `KANDIDAT@ORDNING`, `KANDIDATUPPGIFT`, `KÖN`, `ÅLDER`.
- Aggregate sex/age summaries: `SAMMANFATTNING`, `KÖN`, `ÅLDER`.

There are 7,606 `Definitiv` and 14 `Utkast` ballot occurrences. There is no `KANDNR`, `KANDIDATNUMMER`, person ID, explicit candidate validity, consent or modern `VALSEDELSSTATUS=S/B` field. `KANDIDATUPPGIFT` contains local historical names and other ballot information. Do not equate `Definitiv` with a verified modern printed-ballot contract without documentation. No public-name restoration or name-based identity join is authorised.

`avgang.xml` contains 35,046 `STAT`, 1,947 `PARTI`, 334 `VALOMRÅDE`, 44 `LÄN` and three `VALTYP` nodes. Its fields include age/sex strata, `ANTAL_AVG`, `ANTAL_LED`, `PROCENT`; it has **zero candidate records**. It cannot resolve candidate IDs, original substitutes or election-time vacancies.

### Derived sources elsewhere

Four byte-identical `previous-election-2006.csv` files occur in:

- `.local-data/rkl/2010/kandidater/official-party-identifiers/`;
- `.local-data/r-only-party-identifiers-2010/`;
- `.local-data/r-only-party-identifiers-2010-final/`;
- `.local-data/r-only-clean-2010-party-identifiers/`.

Each has 2,608 rows and 95,384 bytes; MD5 `2dd5bad47566f0bba3933501692156f1`, SHA256 `60c34cb6b1e7a2662e2cc641cbe806a3c9eefb5f0c02bbb041885d9d710635c4`. These are derived party lookups used by the 2010 workflow, built from the 2006 ballot archive, not independent 2006 result/candidate sources. Their exact election/area/party-designation matching is useful precedent, but they do not establish full 2006 party coverage or candidate identity.

## Official web inventory

The current [Valmyndigheten source guide](https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-val-2002-2022) links to the historical presentation. The following indexes/pages returned HTTP 200 in this review.

| Source | Official URL | Contents / geographic coverage |
|---|---|---|
| Final XML index | https://historik.val.se/val/val2006/slutlig/xml/index.html | 872 XML links: RD 291, RF 290, KF 291; national plus municipality files; no RF municipality file for Gotland |
| Election-night XML index | https://historik.val.se/val/val2006/valnatt/xml/index.html | Same indexed file counts; independent counting snapshot |
| Final RD national | https://historik.val.se/val/val2006/slutlig/R/rike/roster.html | Votes, invalid categories, turnout, seats, 2002 comparison; 6,177 counted districts |
| Election-night RD national | https://historik.val.se/val/val2006/valnatt/R/rike/roster.html | Election-night votes/turnout/projected mandates; 5,783 counted districts; explicitly Valnattsammanställning |
| Final RF navigation | https://historik.val.se/val/val2006/slutlig/L/rike/delar.html | Landsting/region links; regional and regional-constituency results |
| Final KF navigation | https://historik.val.se/val/val2006/slutlig/K/rike/delar.html | Municipality links and municipal constituencies/districts |
| Election-night RF/KF | https://historik.val.se/val/val2006/valnatt/L/rike/delar.html and https://historik.val.se/val/val2006/valnatt/K/rike/delar.html | Election-night regional/municipal presentation |
| RD elected national | https://historik.val.se/val/val2006/slutlig/R/rike/valda.html | Elected lists with constituency context; personal information removed |
| RD constituency persons | https://historik.val.se/val/val2006/slutlig/R/riksdagsvalkrets/01/person.html | Preference-vote numbers; names removed; navigation to votes/elected |
| RF Stockholm | https://historik.val.se/val/val2006/slutlig/L/landsting/01/roster.html | Votes, mandates; links to elected and regional constituencies |
| KF Bjurholm elected | https://historik.val.se/val/val2006/slutlig/K/kommun/24/03/valda.html | Election-result elected/substitute presentation |
| Other-party person votes | https://historik.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/index.html | Separate R/L/K navigation; constituency/municipality candidate-vote tables, personal information removed |
| Handwritten party designations | https://historik.val.se/val/val2006/slutlig_ovrigt/handskrivet/index.html | R/L/K navigation; complements reported other-party votes |
| Statistics index | https://historik.val.se/val/val2006/slutlig_ovrigt/statistik/index.html | Mandate, turnout, elected age/sex and person-vote summaries, thresholds and deviations |
| Protocol index | https://historik.val.se/val/val2006/slutlig/protokoll/index.html | Accessible shell, but **no protocol-download links** in retrieved HTML |
| GIS index | https://historik.val.se/val/val2006/slutlig_ovrigt/statistik/kartor/index.html | RD districts, Wednesday districts, municipalities, constituencies; RF district shapefile archives; **final**, not preliminary |

Actual XML filenames have a stage prefix, unlike their display labels: e.g. `slutlig/xml/slutresultat_00R.xml`, `slutlig/xml/slutresultat_0180K.xml`, `valnatt/xml/valnatt_00R.xml`. Requests for bare `00R.xml` in that directory return 404.

Official Excel validation assets linked by the statistics pages (not bulk-downloaded):

- `slutlig_ovrigt/statistik/riksdag/riksdagen_i_valdistrikt_excel.zip`;
- `slutlig_ovrigt/statistik/riksdag/riksdagen_i_kommuner_excel.zip`;
- `slutlig_ovrigt/statistik/riksdag/riksdagen_i_riksdagsvalkretsar_excel.zip`;
- `slutlig_ovrigt/statistik/landsting/landstingen_i_valdistrikt_excel.zip`;
- `slutlig_ovrigt/statistik/kommun/kommunerna_excel.zip`;
- `slutlig_ovrigt/statistik/kommun/kommunerna_i_valdistrikt_excel.zip`.

Their link inventories are established; their binary contents and checksums remain to be preserved/validated. No current download URL for the local ballot `xml.zip` was established; guessed `valsedlar` index/archive URLs returned 404. This is not proof that no official archival copy exists.

### XML contents, semantics and versions

The inspected final files have `VALDAG=20060917`, `VALDAG_FGVAL=20020915`, root `TID_RAPPORT=20061206032119`, with distinct September area/report/mandate timestamps. These show a later generated export of election-result structures, not a documented version history or proof that every correction is included.

- `GILTIGA`: party abbreviation reference, votes, percentages, previous values/changes, mandates; adjustment-seat counts where supplied.
- `VARAV_ÖVRIGA`: breakdown of other-party votes; avoid counting both it and its parent aggregate.
- `OGILTIGA`: blank/other-invalid vote categories.
- `VALDELTAGANDE`: eligible voters, eligible voters in counted districts, total ballots and previous values.
- Geography: `NATION`, `LÄN`, `KRETS_RIKSDAG`, `KRETS_LANDSTING`, `KOMMUN`, `KRETS_KOMMUN`, `VALDISTRIKT`, `ONSDAGSDISTRIKT`.
- `GILTIGA/PERSONVAL`: candidate-result totals at the current geography; `VALSEDEL/PERSONVAL`: separate list breakdown. Never sum both.
- `VALSEDEL`: party-prefixed list number, list votes, preference votes/share; `PARTISEDEL` includes `party-90000` party ballots.
- `GRUPP_VALDA/VALD`: election order, age, `GRUND=P/J`; `ERSÄTTARE`: order/age and group context. These are not current membership records.

National RD XML contains 29 RD constituencies, 290 municipality occurrences, 349 elected records, 596 substitute records and 10,375 PERSONVAL occurrences. National RF XML contains 20 county branches, 98 regional-constituency occurrences, 1,656 elected records, 2,501 substitute records and 37,333 PERSONVAL occurrences. **Node counts are not deduplicated candidate totals or a verification of all municipal results.** National KF XML has aggregates but no VALD/ERSÄTTARE/PERSONVAL records: the municipal XML files are necessary.

Stockholm municipal KF/RF XML contains ordinary and Wednesday districts and list/person breakdowns. RF municipality XML is a geographic slice of a regional election, not the authoritative regional elected relation. Gotland has no separate landsting election; do not fabricate RF records from KF.

Heby is represented as `0331` under Uppsala (`03`) in both the local ballot archive and the inspected national result hierarchy. Record this source geography explicitly and check it against election-time boundaries and SCB; do not silently impose geography from another year. XML RD constituency codes also carry county context (e.g. `0303`), while HTML routes use shorter constituency identifiers: retain both source representation and a verified code mapping.

Final DTD references include `parti_person_nation_1_3.dtd` and `parti_person_kommun_1_3.dtd`; election-night references `parti_nation_1_4.dtd`. Tested corresponding HTTPS paths at `val.se`/`historik.val.se` returned 404. No local DTD was found in the nested ballot archive. Obtain definitions before relying on undocumented ordinal/reference relationships.

### Candidate identity is a genuine source gap

All 153,822 local ballot occurrences lack candidate numbers. The inspected result XML has no `KANDNR`/`KANDIDATNUMMER` attributes. For example Bjurholm list `0001-01441` has `PERSONVAL@KANDIDAT=1,3,2,...`, matching **ballot position**, whereas `PERSONVAL@ORDNING` is ranking by votes (including tied ranks). These fields must not be renamed to candidate_id. Party-level PERSONVAL, VALD and ERSÄTTARE examples have no candidate-number reference at all.

Consequently:

- List-number + position can potentially link an occurrence to the local ballot file after scoped geography/status validation.
- It does not identify one person appearing on different lists/election types.
- Gallrated party-level names cannot safely link area totals/elected/substitutes to named local occurrences.
- Cross-RD/RF/KF candidate-number consistency and identifier discrepancies are **not testable from these sources**. No conflict crosswalk or fabricated ID has been produced.
- Do not infer that IDs were removed by gallring: whether the original 2006 formats ever exported a stable ID remains unestablished.

## Counting-stage assessment

Election-night is directly evidenced by `VALNATTSRAPPORTERING`, the stage-specific XML/index and the public Valnattsammanställning. RD national election-night valid votes are 5,438,403; final valid votes are 5,551,278, with 5,650,416 total ballots and 6,892,009 eligible voters. The 112,875 valid-vote difference is **not** an estimate of preliminary Wednesday votes: final ordinary-district corrections may contribute.

Final Stockholm district navigation links to `slutlig/R/onsdagsdistrikt/01/80/06/roster.html`; that page explicitly says Slutlig sammanräkning and reports 1,331 valid votes. Bjurholm final XML contains `ONSDAGSDISTRIKT KOD=K-2403-00`, 31 valid votes. These establish final collections, not preliminary ones. The corresponding tested valnatt Stockholm Wednesday URL returns 404, and ordinary election-night navigation does not list collections.

No separate preliminary/Wednesday stage was found in the official 2006 navigation or local archive. Tested RD national paths under `preliminar`, `preliminar_onsdag`, `onsdag` and `prelresultat` return 404. Search failures and guessed-path 404s do **not** establish that the material never existed. Complete preliminary coverage is therefore **unverified for all RD/RF/KF**, and the modern preliminary reconstruction is currently blocked. Do not relabel election-night as preliminary and do not use final collection values to fill this gap.

## Local versus web

| Material | Local | Official web evidence | Comparison status |
|---|---|---|---|
| Ballot/candidacy snapshot | Full nested archive | Current matching archive URL not established | Historical snapshot, not byte-compared to a current official copy |
| Final results | Not found locally for 2006 | Full indexed national/municipal family, sampled XML accessible | Needs preservation and national sweep |
| Election-night results | Not found locally for 2006 | Full indexed family, national sample accessible | Needs separate preservation |
| Complete preliminary collections | Not found | Separate stage not located | Blocking gap; contact Valmyndigheten |
| Fixed elected/substitute structures | Not found locally | In final RD/RF national and sampled KF municipal XML | Available relations, missing shared identity linkage |
| Other-party person votes / handwritten parties | Not found locally | Accessible separate presentation trees | Preserve as supplements, check overlap |
| Excel / GIS validation | Not found locally | Linked official archives | Preserve selected tables first; GIS can wait |
| Departures / operational voting files | Present | Matching originals not established | Not election-result build inputs |

Sampled current response hashes (diagnostic fingerprints; responses read in memory, not archived):

| URL suffix after `val/val2006/` | Bytes | MD5 | SHA256 |
|---|---:|---|---|
| `slutlig/xml/slutresultat_00R.xml` | 2,155,999 | `e9c5a8e00735b5cf231bd7faa16924ec` | `d715f9d5f774b6c3681d7f6750b9e1d391477eff21c58e352b26207716043a27` |
| `slutlig/xml/slutresultat_2403K.xml` | 52,877 | `390e2fbc030eafda9a11e486d48894b0` | `54d921eefc4f71f87b64e53d8886f1de7e7932cbab6b224924758c3603f662c8` |
| `valnatt/xml/index.html` | 69,583 | `b1cfbdbb967689c0502ad6dbbcb5c4c0` | `faf2a4dc21f043e974165db070ac78d6423c46b8bf619bf2ce714583c16d3bce` |

## SCB: independent validation, not candidate reconstruction

[ME0104](https://www.scb.se/me0104) links 2006 Huvudresultat (Excel) and Huvudresultat efter distrikt (Excel), covering votes/mandates/eligible voters/turnout and district/geographic aggregates. These are not preserved in the identified local 2006 tree. Web extraction does not render Excel; binary content validation remains a subsequent step.

SCB preference-vote tables covering 2006:

- [RD ME0104T24](https://www.statistikdatabasen.scb.se/goto/sv/ssd/ME0104T24): constituency, party, sex;
- [RF ME0104T26](https://www.statistikdatabasen.scb.se/goto/sv/ssd/ME0104T26): region, party, sex;
- [KF ME0104T25](https://www.statistikdatabasen.scb.se/goto/sv/ssd/ME0104T25): municipality, party, sex.

Compare actual table definitions, eligible party populations and geographic coverage before equating their totals with a sum of candidate records. Valmyndigheten's [all-party person-vote summary](https://historik.val.se/val/val2006/slutlig_ovrigt/statistik/personroster_allaval.html) supplies useful final control totals: RD 1,231,512, RF 1,186,237, KF 1,554,115 ballots with a preference mark. Corresponding valid votes are 5,551,278 / 5,415,740 / 5,521,563. These are **not yet reconciled sums from a package build**.

[ME0107](https://www.scb.se/me0107) supplies nominated/elected population tables for RD/RF/KF, with party/geography/sex and background variables. The [2006 definition](https://www.scb.se/contentassets/4df37246f586465991189fc7d4f1593d/me0107_bs_2006.pdf) defines the objects as **persons**, nominated/elected according to Valmyndigheten registers, referenced to the election occasion; SCB checks source data against counting protocols. Thus compare deduplicated candidate populations, not 153,822 ballot occurrences. Aggregate SCB outputs cannot supply missing individual candidate IDs, validate cross-election identity, or recover substitute-to-member relations. Later departure statistics must remain separate.

No SCB candidate counts or person-level equivalence are claimed in this inventory; those checks need an identifiable candidate population first.

## Omval

SCB's official [2011 omval report, table 3.1 and historical review](https://www.scb.se/contentassets/9f23fe2e182a4a2d8961949f81473bc6/me0105_2011a01_br_me09br1201.pdf) records 25 appeals for 2006 (RD 5 / RF 7 / KF 13) and **no omval decision**. Its historical list covers 1979, 1985, 2002 and 2010, not 2006. No separate 2006-related rerun occasion was identified. Appeals/corrections must still be distinguished from later replacement-member appointments; absence of omval does not imply an absence of corrections.

## Coverage matrix for the existing seven APIs

**P** = source structures support a plausible implementation, pending preservation/full validation. **B** = meaningful records exist but the existing candidate-ID contract is blocked. **U** = necessary counting snapshot not located. None of these means implemented support.

| Function | RD | RF | KF | Geography / remaining requirement |
|---|---|---|---|---|
| `results()` final | P | P | P | National, county/region, RD/RF constituency, municipality, municipal constituency, district/Wednesday where represented; validate all branches and non-overlapping aggregation |
| `results()` comparable preliminary | U | U | U | Election-night available; preliminary collections and independent preliminary controls missing |
| `seats()` final | P | P | P | RD national/constituency, RF region/constituency, KF municipality/constituency; verify fixed/adjustment and unfilled-seat semantics separately |
| `candidacies()` | B | B | B | Full local ballot occurrences and positions; no stable candidate ID or modern validity/printed-status contract |
| `candidates()` | B | B | B | Ballot/result population cannot yet be deduplicated over lists/types; retain all positive source vote records pending linkage |
| `elected()` | B | B | B | Authoritative final relations exist; missing candidate linkage, not missing mandate counts |
| `substitutes()` | B | B | B | Group/order structures exist; missing person/member identity linkage; exclude later departures |
| `preference_votes()` | B | B | B | Area/list/district values exist; stable candidate attribution and cross-list aggregation unresolved |

## Recommended preservation and implementation sequence

1. Preserve both complete **final and election-night** XML families by traversing their indexes, separately. Record URL, UTC retrieval timestamp, response size, MD5/SHA256, root/area timestamps and stage. Use a conservative cached R retriever, never overwrite historical files. The indexes expose 872 files per stage; confirm every expected municipality/type and branch, including Gotland's absence of RF.
2. Preserve the supplementary other-party person-vote and handwritten-party presentations and six official Excel archives. They are necessary independent completeness/aggregate checks; their rows must not be added to XML blindly. Retain the existing named ballot snapshot unchanged and private as provenance.
3. Ask Valmyndigheten for the original **2006 candidate register/ID mapping** and definitions linking ballot position, party-level PERSONVAL and elected/substitute records. Ask whether a stable election-occasion candidate number existed/exported across R/L/K. A list-position occurrence key is not an approved replacement for the public candidate key.
4. Ask specifically for the complete **preliminary Wednesday/collection snapshot** and independent RD/RF/KF preliminary totals. Do not request or substitute final Wednesday figures. If unavailable, report preliminary as unsupported rather than silently implementing election-night under that name.
5. Obtain the referenced 1.3/1.4 DTD definitions and election-time geographic/code documentation; investigate Heby and RD route-versus-XML constituency codes before normalisation. Locate official protocols through Valmyndigheten/archives since the current protocol index is only a shell.
6. After preservation, use a thin **R-only 2006 adapter** for the shared XML concepts. Reuse downstream standard/full, English/Swedish, source/checksum and canonical infrastructure; do not assume a 2014 reader can ingest these records unchanged. Candidate/list references, unavailable IDs/validity/consent and reporting stages need year-specific handling. Unsupported attributes remain typed NA; missing identity cannot be repaired by names or positional deduplication.
7. Require national/municipal/constituency/district sums, other-party reconciliation, SCB controls, original elected/substitute comparisons, candidate identity evidence, source integrity and Parquet/schema equivalence before declaring a canonical build complete.

Recommendation: preserve and validate **results/seats first**, while resolving the two source gaps. The current evidence does **not** justify promising all seven candidate-keyed functions or a comparable preliminary stage. No data, identity, schema or API changes were made during this review; only this report was created.

## Focused follow-up: candidate identity and complete preliminary results

Checked 11 October 2026. This is a source assessment, not implementation. The five preserved 2006 files were rehashed: every MD5/SHA256 still matches the inventory above. No source, production, canonical or release file was changed. R was used for the local/HTTP/XML/Excel diagnostics; only this report was extended.

### Candidate identity: identifiers actually available

| Source | Available identifiers/references | What can be linked safely | Remaining limitation |
|---|---|---|---|
| All 313 XML documents inside local `valresultat/xml.zip` | Election code, official geographic codes, party code, `VALSEDEL@LISTNUMMER`, `KANDIDAT@ORDNING` | Candidate occurrence within the specified ballot and snapshot; ballot-position references from matching result lists | No person identifier across different lists or RD/RF/KF |
| Local `avgang.xml` | Election/area/party and demographic strata | Aggregate mandate-period departures only | No candidate or original elected-member records |
| Local advance-voting XLS and SD ballot-order TXT | Operational locations, dates, county/municipality context | Operational/ballot-order validation | No candidate identifier |
| Inspected final RD/RF national and KF municipal XML | Area/party/list; list-level `PERSONVAL@KANDIDAT`; ranking/election/substitute order | List-level vote records can refer to the numbered ballot position; supplied order/group structures describe election relations | Party-level PERSONVAL, VALD and ERSÄTTARE do not supply a demonstrated global candidate reference |
| Current historical candidate/result HTML inspected | Geographic routes, party/list context, displayed rank/order | Source occurrence/geographic context | No candidate-number field or individual identifier link found; current result names are removed |
| Archived official ballot index and RD constituency index | Election/constituency routes and ballot-navigation links | Recovering the original presentation structure | Retrieved indexes add no person ID; detailed ballot pages were not recovered in the probes below |
| SCB public ME0107 tables for 2006 | Sex, party, background category, election year, count/share measure | Aggregate nominated/elected population validation | No individual candidate, ballot, VM candidate number or person-ID dimension |
| SCB underlying nomination/election registers | Person-level registers documented by SCB; exact 2006 identifier fields not obtained | Potential future identity evidence, subject to access and mapping | Not an available public record-level crosswalk |

The exhaustive local ballot recheck again found RD **20,926**, RF **46,498**, KF **86,398** candidate occurrences. Across all **7,620** ballot occurrences there are **zero duplicate candidate positions within an individual VALSEDEL node**. The entire candidate attribute vocabulary is `ORDNING`, `KANDIDATUPPGIFT`, `KÖN`, `ÅLDER`. There is no KANDNR/KANDIDATNUMMER or person-number attribute.

`PERSONVAL@KANDIDAT` must not be interpreted as a person ID: Bjurholm's final KF list `0001-01441` uses values 1, 3, 2, etc. as ballot positions. `PERSONVAL@ORDNING` is preference-vote ranking and can repeat on tied results. Neither provides cross-list identity. Election/substitute order is also a relation/order key, not proof of identity with a ballot occurrence. No join was inferred from names, age or sex.

**Important qualification:** this is a limitation of the available public extracts, not evidence that an internal 2006 person register never existed. SCB's [2006 ME0107 description, A.12 and B.1](https://www.scb.se/contentassets/4df37246f586465991189fc7d4f1593d/me0107_bs_2006.pdf) explicitly describes Valmyndigheten person-level nomination/election registers combined with SCB demographic registers. That establishes a credible archive/contact route, but does not establish an obtainable, distributable identifier or its cross-election scope. Today's general candidate-number documentation describes later candidate exports; it cannot introduce a missing field into the 2006 files.

The SCB API metadata were checked directly, including year 2006:

- RD: [ME0107C/ME010720T01](https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0107/ME0107C/ME010720T01).
- RF: [ME0107B/ME010720T02](https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0107/ME0107B/ME010720T02).
- KF: [ME0107A/ME010720T04](https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0107/ME0107A/ME010720T04).

These are aggregate tables, not candidate microdata. SCB also documents [access to microdata](https://www.scb.se/vara-tjanster/bestall-data-och-statistik/mikrodata/), but an approved research extract would not automatically be a public package source or retain Valmyndigheten's identifier. Ask for the 2006 register variable list, available election-occasion key, scope across RD/RF/KF, and a ballot-position/result relation mapping before relying on it.

### Additional local material

The project/archive search found no additional 2006 candidate-level SCB dataset or record-level ID crosswalk. Relevant files outside the 2006 directory were inspected rather than assumed relevant from their names:

- `.local-data/validation-2014/scb-candidate-counts.json`: aggregate API responses/queries for **2014**, not a 2006 candidate register.
- `.check/compare_scb_2022.R`: independent aggregate SCB bulk-table checks for **2022**; no preserved 2006 person records.
- Four `previous-election-2006.csv` copies listed above: derived **party** identifier lookups, not candidate IDs.
- `.local-data/rkl/2022/rostning/valkretsmandat-riksdag-1988-2022.xlsx`: genuinely contains a **2006 fixed-RD-seat allocation column** (worksheet Blad1; title dates the compilation to 8 April 2022). Useful independent constituency-seat validation, not candidate identity or preliminary votes.
- Preserved 2010 preliminary presentation: includes 2006 comparison columns, but these are not a preserved 2006 preliminary snapshot. In Ekerö they reproduce the 2006 final valid total **14,937** and the displayed major-party totals; SD 195 plus other parties 32 corresponds to final XML ÖVR 227. In Uppvidinge the comparison reproduces the final total **5,563** and all displayed party totals. These examples show why previous-election columns must not be repurposed as 2006 preliminary evidence.

Other-year candidate/member sources and modern semantic-review outputs are not election-time 2006 identity sources. The search does not claim that no additional register exists outside the project/configured archives.

### Archived official presentation: new leads and limits

Internet Archive was used only as an archival carrier of **Valmyndigheten's original pages**, not as an independent election-data producer. Small pages were read in memory; no bulk acquisition or new preserved source collection was created.

| Original official page / retrieved archive | Evidence |
|---|---|
| [Ballot index, captured 26 September 2006 06:23:23](https://web.archive.org/web/20060926062323/http://www.val.se/val/val2006/valsedlar/index.html) | Accessible; footer updated 25 September; links 00R/00L/00K; says 3,853 ballot types ordered at that point. This is a page-level snapshot count, not a person count or a reconciliation with repeated geographic XML ballot occurrences. |
| [RD ballot constituency index, captured 18 October 2006 01:49:03](https://web.archive.org/web/20061018014903/http://www.val.se:80/val/val2006/valsedlar/00R.html) | Accessible; links all 29 constituency-specific `partier*R.html` pages; no person identifiers. |
| [Election index, captured 9 September 2006 13:41:04](https://web.archive.org/web/20060909134104/http://www.val.se:80/val/val2006/index.html) | Accessible pre-election landing page; no results yet. Not evidence about later collection coverage. |
| [RD election-night result, captured 20 September 2006 00:20:39](https://web.archive.org/web/20060920002039/http://www.val.se:80/val/val2006/valnatt/R/rike/roster.html) | Accessible; explicitly Valnattsammanstallning, source update 18 September 15:49:12; all 5,783 night districts; valid 5,438,403, blank 91,181, other invalid 11,748, cast 5,541,332. Links the valnatt XML index. This is not a completed Wednesday snapshot. |

Availability lookups for `valsedlar/partier24R.html`, `valsedlar/0180K.html` and `valresultat[/index.html]` returned no matching capture in the targeted probes. A direct archived `partier01R.html` request and the current historical `partier24R.html` returned 404. An archive-wide CDX discovery request timed out without a result. Therefore the ballot-detail search is **not an exhaustive negative archive result**; no new person ID was established, but more captures could exist.

### Preliminary collections: status after deeper investigation

The official [2006 experience report, section 5](https://www.val.se/download/18.162047b519a91d0533117a7e/1592299588512/erfarenhetsrapport-2006-rapport-2007-1.pdf) describes publication of preliminary election-night counting and mandate forecasts. It separately discusses increased Wednesday counting. Publication of a preliminary result therefore does not by itself prove that a complete, separately retrievable Wednesday source remains available.

| Stage | RD | RF | KF | Conclusion |
|---|---|---|---|---|
| Election-night | Current XML index/presentation; archived national page additionally checked | Current XML index/presentation | Current XML index/presentation | Identifiable official source family; full preservation/validation still needed |
| Preliminary collection/Wednesday | No verified complete source located | No verified complete source located | No verified complete source located | Cannot yet certify completeness, expected-unit coverage or comparable full preliminary totals |
| Final collection/Wednesday | Present in inspected final XML/HTML | Present in inspected final XML | Present in inspected final XML | Final values must not fill preliminary gaps |

Current historical probes for `prel`, `prelim`, `preliminar`, `preliminar_onsdag`, `onsdag`, `valnatt_onsdag` and `prelresultat` stage/index paths returned 404 in the checks described here/above. Targeted archival availability queries for the original RD `preliminar/R/rike/roster.html`, `prelresultat/R/rike/index.html` and `valnatt/R/onsdagsdistrikt/01/80/06/roster.html` returned no capture. These are bounded URL probes, **not proof that collections were never published or cannot exist at another location**.

No additional local preliminary ZIP/XML/SKV/Excel collection source was found. The 2010 comparison columns match sampled **final** 2006 data, and final Wednesday XML is explicitly final. Consequently no ordinary-night + preliminary-collection reconstruction, completeness count or independently verified full preliminary total can responsibly be reported yet. The difference between night and final totals is not a substitute for the missing collection snapshot: ordinary votes may also have changed in final counting.

### Viable representation and recommendation

| Alternative | Assessment |
|---|---|
| Documented ballot candidacy occurrences | Strongest currently supported microdata unit. Retain election, snapshot, geographic scope, party/list and ballot position, plus available attributes. Do not deduplicate persons across lists. |
| Package-generated candidacy/occurrence key | Feasible as an explicitly **record-level** key: source snapshot/document + ballot occurrence + position, with semantic election/geographic/party/list fields retained. Not an official candidate ID; would require a separately approved public contract. |
| List-position preference-vote records | Useful and linkable where the official result list/position matches a documented ballot. Preserve unmatched result occurrences separately; never discard them or aggregate to a guessed person. |
| Elected/substitute relation records | Preserve official area/party/order/group observations independently. Do not imply their person linkage to every ballot without a supplied mapping. |
| Constructed person identity | Defer. Name, age, sex, party or a repeated position is not sufficient independently verified identity. No person ID was generated. |

**Recommendation: A + C.** Proceed towards final `results()`/`seats()` after full source preservation and numerical validation. Retain the useful candidate/list/elected/preference-vote observations for a separately designed occurrence-level representation, but defer the existing person-keyed candidate API and cross-list/RD/RF/KF person linkage until an official election-occasion mapping is obtained. Do not label election-night as comparable `preliminary`; full preliminary support remains conditional on finding and validating the actual collection snapshot.

The next source requests should be narrowly defined: (1) Valmyndigheten's 2006 candidate/register export and ballot/result identity mapping; (2) SCB's 2006 register variable list and whether an accessible, reproducible linkage exists; (3) the complete RD/RF/KF Wednesday/preliminary snapshot, its expected geography and independent aggregate controls. No implementation has started.

## Archived sources – candidate/person-vote and preliminary results

This section supersedes the earlier negative archival assessment where new evidence is available. The supplied capture was inspected as original HTML, and linked raw XML was retrieved and parsed in R. Downloads and diagnostic metadata were kept in an operating-system temporary directory **outside the repository**; none was added to the raw archive or Git. Only this report was changed.

### Main finding

The archived official site preserves **named candidate-result observations for RD, RF and KF**, plus named elected/substitute relationships. More importantly, the original national RD and RF final XML files are retrievable and contain names. This substantially improves the source basis beyond the anonymised current presentation.

It does **not** resolve stable person identity. No candidate-number/person-ID field was found in the inspected original HTML or original result XML. List-position references remain list-position references. Named source observations must not be merged into persons by name alone.

The preliminary collection-district gap remains unresolved. Both an archived election-night XML index and its national RD XML are retrievable, but they describe election-night reporting, not complete Wednesday/collection reporting.

### Supplied Kronoberg candidate page: exact contents

Original: `http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html`.
Capture: [6 April 2010 20:14:56 UTC](https://web.archive.org/web/20100406201456/http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html).
Provider: Internet Archive / Wayback Machine; original producer: Valmyndigheten.

- Source heading: final counting, RD, Kronoberg; displayed source update **21 September 2006 14:26:46**. Capture time is not the election-result update time.
- **171 positive candidate-result rows**, grouped under seven parties; candidate name, integer preference-vote count and displayed percentage.
- Examples: Katarina Brännström, M, **2,005 / 7.30%**; Eskil Erlandsson, C, **2,617 / 20.83%**; Tomas Eneroth, S, **2,997 / 7.48%**.
- No candidate ID, list number, ballot position, age or sex appears in this table. Row order is a presentation order, not a person identifier or ballot position.
- All HTML attributes, anchors, inputs and scripts were inspected: only structural DOM IDs; **no scripts or input/hidden fields**, no KANDNR/KANDIDATNUMMER/candidate-ID tokens after correct ISO-8859-1 decoding, and no individual candidate-detail links.
- Links lead to the constituency vote, elected, municipality, other-party and map pages, plus common national, raw-XML, protocol and statistics indexes. They are geographic/source-navigation references, not candidate-ID references.

Against the current official page, both versions have **179 table rows**, including headings. Exactly **171 name cells** differ: current names are `Personuppgift borttagen`. Every count, percentage and other table cell is identical. The archived page restores the displayed names, not new counts or identifiers.

### Systematic URL structure and coverage

The established final routes are:

| Role | RD | RF | KF |
|---|---|---|---|
| Candidate preference-vote area | `slutlig/R/riksdagsvalkrets/{route}/person.html` | `slutlig/L/landstingsvalkrets/{county}/{constituency}/person.html` | `slutlig/K/kommun/{county}/{municipality}/person.html` when undivided; `slutlig/K/kommunvalkrets/{county}/{municipality}/{constituency}/person.html` when divided |
| Elected/substitutes at constituency | Same directory, `valda.html` | Same constituency directory, `valda.html` | Same municipal-constituency directory, `valda.html` |
| Surrounding elected summary | National/constituency navigation | `slutlig/L/landsting/{county}/valda.html` | `slutlig/K/kommun/{county}/{municipality}/valda.html` |
| Downloadable fixed result | `slutlig/xml/slutresultat_00R.xml` and municipal components | `slutlig/xml/slutresultat_00L.xml` and municipal components | `slutlig/xml/slutresultat_{municipality}K.xml`; national file is not a replacement for municipal candidate relations |

The absence of a region-level RF or divided-municipality KF `person.html` is not evidence that candidate data are absent: the analytical person-vote area is the constituency. Stockholm KF has six such constituencies. Kronoberg RF has four.

Availability metadata were checked for **all 29 RD constituency routes**, first with `www.val.se`, then with explicit `www.val.se:80` for missing matches. A capture was advertised for **24/29**: 03, 06, 07 and 09–29. No capture was advertised for **01, 02, 04, 05, 08** in those probes. The 24 capture timestamps are recorded below; only **03, 07 and 28** were fetched and content-validated as HTML in this review. This is not a completed 29-page preservation sweep. The retrieved national RD XML nevertheless covers **all 29 constituencies** and supplies named result observations across them.

Two archival discovery limitations were demonstrated:

1. Availability results can differ between original URLs with and without explicit `:80`.
2. An empty availability response is **not proof of non-retrievability**: following exact file links through the archived XML index retrieved RD/RF/KF XML and election-night XML that the availability API had not located. Record the actual final capture URL after redirects, not merely the requested timestamp.

No exhaustive crawl of 98 RF constituencies or 290 KF municipalities was undertaken. RF/KF HTML coverage below is sampled; RF national XML coverage is complete at its represented 98 constituencies. KF nationwide named-source completeness remains to be established through its municipal file family.

### Original downloadable XML versus the current official XML

| Source compared | Original capture | Elements | PERSONVAL nodes, all scopes | VALD nodes | ERSÄTTARE nodes | Differences after excluding candidate names |
|---|---|---:|---:|---:|---:|---|
| National RD | 10 February 2010 00:10:51 | 20,573 | 10,375 | 349 | 596 | **0**; identical element sequence and all remaining attributes |
| National RF | 19 March 2008 05:34:52 | 58,033 | 37,333 | 1,656 | 2,501 | **0**; identical element sequence and all remaining attributes |
| Bjurholm KF 2403 | 19 March 2008 07:03:38 | 507 | 344 | 31 | 19 | **0**; identical element sequence and all remaining attributes |

The comparisons exclude `NAMN` only on `PERSONVAL`, `VALD` and `ERSÄTTARE`; geographic/party names and all vote, order, position, age, threshold, basis and grouping attributes remain in the comparison. The common root report timestamp is **20061206032119**. Node counts are **source records**, not unique people: several geographic/list representations coexist and must not be summed indiscriminately.

The original XML preserves candidate names, `ORDNING`, counts/shares, qualification markers, and, on elected records, age and election basis. On list-level PERSONVAL, `KANDIDAT` still refers to ballot position. A scan of attribute vocabulary found no global person identifier; fields containing ID-like text were timestamps, PERSONKRYSS and the local KANDIDAT reference. No new identity rule was inferred.

An archived Stockholm municipal XML request timed out. That is an unverified retrieval attempt, not evidence that the file is absent. The small Bjurholm municipal file and the Stockholm constituency HTML provide independent KF examples without requiring a nationwide download now.

### Preference-vote completeness and reconciliation

| Archived page | Positive displayed records | Displayed vote sum | Current page comparison | Official XML comparison |
|---|---:|---:|---|---|
| RD Uppsala, route 03 | 205 | 38,556 | Same rows/counts/shares; names removed currently | Corresponding ordinary candidate table; no identity inferred |
| RD Kronoberg, route 07 | 171 | 25,533 | Same rows/counts/shares; names removed currently | All seven party sums exactly match direct `KRETS_RIKSDAG/GILTIGA/PERSONVAL` and party PERSONKRYSS |
| RD Västerbotten, route 28 | 177 | 41,180 | Same rows/counts/shares; names removed currently | Corresponding ordinary candidate table; no identity inferred |
| RF Stockholm 1 Södermalm-Enskede, 0101 | 396 | 14,690 | Same rows/counts/shares; names removed currently | All eight party sums exactly match direct `KRETS_LANDSTING/GILTIGA/PERSONVAL`; ÖVR adds 557 marks |
| KF Stockholm 3 Norrmalm-Östermalm, 018003 | 272 | 18,749 | Same rows/counts/shares; names removed currently | All seven party sums exactly match direct `KRETS_KOMMUN/GILTIGA/PERSONVAL`; ÖVR adds 718 marks |

The ordinary main-party tables alone are not a complete all-party candidate source. The archived statistics index links the separate official `slutlig_ovrigt/ovriga_personroster/` family. Its retrieved indexes cover **29 RD constituency links, 20 RF county links and 21 KF county links**, with lower geographic navigation. An index link does not establish that every child object is preserved/retrievable.

The archived **RD Kronoberg other-party page** supplies another **105 positive named records and exactly 1,606 votes**. Main plus other-party observations therefore give **276 source candidate-result rows / 27,139 votes**, exactly the constituency XML PERSONKRYSS total. The current other-party page has the same 105 counts/shares with names removed. Its HTML also has no person ID, list/position field, hidden data or candidate-detail link.

For whole-country controls, the retrieved RD XML has **5,150 direct area-level candidate PERSONVAL records summing to 1,147,952** versus **1,231,512 aggregate preference marks**; the difference is **83,560**. RF has **18,302 direct area-level candidate records summing to 1,167,604**, versus **1,186,237 aggregate marks**; difference **18,633**. These are different source scopes, not evidence of a package bug. The separate other-party material must be reconciled before claiming complete candidate-level coverage. Do not allocate residual marks to candidates or infer zero from absent rows. The Kronoberg reconciliation demonstrates that the supplementary source can close a real coverage gap; a national sweep has not been completed.

The archived family is thus a **systematic, valuable candidate-result source**, including positive records missing from the ordinary candidate tables. It supports source-native area/party candidate observations and list-position observations where available. It does not establish person uniqueness across lists, constituencies or elections, and does not on its own provide the zero-vote candidate population supplied by ballot sources.

### Elected and substitute information

Retrieved named `valda.html` pages include Kronoberg RD, Stockholm RF (region and constituency 0101), and Stockholm KF (municipality and constituency 018001). Constituency tables distinguish elected names from substitute names, group them by party and indicate `(personvald)` where applicable. Surrounding region/municipality summaries identify the constituency through geographic links. They contain no candidate-number field or candidate-detail anchors.

Do not use row order from a surrounding summary as election order: these summaries can sort names alphabetically. Use the final XML's explicit ORDNING and group/relationship structure. Named HTML is useful independent evidence of the published relationships, but a name shared with a ballot is not sufficient person linkage. The retrieved raw XML adds stronger structural evidence than HTML layout, without resolving a global candidate identifier.

### Preliminary collection investigation

The archived election-night XML index, captured **10 October 2006 11:12:34**, lists **872 unique XML file links: RD 291, RF 290, KF 291**. It contains no additional ZIP/SKV/TXT link and no separate preliminary-collection download. The archived final index likewise lists 872 final XML links, with no alternative counting-stage archive.

Following the actual night-index link retrieves national RD XML at capture **30 November 2009 17:50:16**. Its root says **VALNATTSRAPPORTERING**, report timestamp **20060919104013**; national data have **5,783/5,783 districts and 5,438,403 valid votes**, and no Wednesday nodes. This agrees with the previously retrieved election-night presentation, not a complete collection-inclusive preliminary stage.

Bounded archived queries for Wednesday/preliminary indexes did not locate a separate source. Archive-wide CDX discovery for preliminary/Wednesday/XML/ZIP/SKV URLs timed out after 22 seconds without a response. No aggressive retries or full crawl were made. Consequently this review cannot prove historical non-existence, but it has **not retrieved a complete preliminary collection source**, independent full preliminary controls, or expected collection-unit coverage. Neither final Wednesday XML nor later capture dates turn election-night values into preliminary collection values.

### Provenance and preservation status

The following inventories record original and actual archived URLs, provider/capture, bytes, hashes and content status. All listed successful objects were parsed/read, not merely inferred from availability metadata. Provider is **Internet Archive/Wayback** for every object; producer is **Valmyndigheten**. Readable capture URLs identify the original resource; the `id_` retrieval mode was used to avoid toolbar/JavaScript rewriting.

Original capture objects are reproducible source candidates **if preserved with bytes/checksums**, but archive URLs alone are not guaranteed permanent downloads. No files were added to the repository/raw-source archive. A durable, separately authorised preservation sweep should retain raw capture bytes, requested and final URLs, capture time, retrieval UTC time, response status, encoding and MD5/SHA256. Never merge captures from different dates silently or describe a page-level source as nationwide coverage.

| Object | Original URL | Actual capture (UTC) | Bytes |
|---|---|---|---:|
| `archived-other-person-K-index` | [slutlig_ovrigt/ovriga_personroster/K/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/K/index.html) | [20070106100747](https://web.archive.org/web/20070106100747id_/http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/K/index.html) | 3,949 |
| `archived-other-person-L-index` | [slutlig_ovrigt/ovriga_personroster/L/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/L/index.html) | [20070106100802](https://web.archive.org/web/20070106100802id_/http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/L/index.html) | 4,281 |
| `archived-other-person-R-index` | [slutlig_ovrigt/ovriga_personroster/R/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/R/index.html) | [20070321032617](https://web.archive.org/web/20070321032617id_/http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/R/index.html) | 5,043 |
| `archived-other-person-RD07` | [slutlig_ovrigt/ovriga_personroster/R/07/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/R/07/index.html) | [20070325020458](https://web.archive.org/web/20070325020458id_/http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/R/07/index.html) | 20,224 |
| `direct-archived-final-KF-XML` | [slutlig/xml/slutresultat_2403K.xml](http://www.val.se/val/val2006/slutlig/xml/slutresultat_2403K.xml) | [20080319070338](https://web.archive.org/web/20080319070338id_/http://www.val.se/val/val2006/slutlig/xml/slutresultat_2403K.xml) | 53,379 |
| `direct-archived-final-RD-XML` | [slutlig/xml/slutresultat_00R.xml](http://www.val.se/val/val2006/slutlig/xml/slutresultat_00R.xml) | [20100210001051](https://web.archive.org/web/20100210001051id_/http://www.val.se/val/val2006/slutlig/xml/slutresultat_00R.xml) | 2,165,655 |
| `direct-archived-final-RF-XML` | [slutlig/xml/slutresultat_00L.xml](http://www.val.se/val/val2006/slutlig/xml/slutresultat_00L.xml) | [20080319053452](https://web.archive.org/web/20080319053452id_/http://www.val.se/val/val2006/slutlig/xml/slutresultat_00L.xml) | 6,413,401 |
| `direct-archived-night-RD-XML` | [valnatt/xml/valnatt_00R.xml](http://www.val.se/val/val2006/valnatt/xml/valnatt_00R.xml) | [20091130175016](https://web.archive.org/web/20091130175016id_/http://www.val.se/val/val2006/valnatt/xml/valnatt_00R.xml) | 571,794 |
| `direct-archived-other-person-votes` | [slutlig_ovrigt/ovriga_personroster/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/index.html) | [20100701195033](https://web.archive.org/web/20100701195033id_/http://www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/index.html) | 1,519 |
| `direct-archived-statistics` | [slutlig_ovrigt/statistik/index.html](http://www.val.se/val/val2006/slutlig_ovrigt/statistik/index.html) | [20100119042752](https://web.archive.org/web/20100119042752id_/http://www.val.se/val/val2006/slutlig_ovrigt/statistik/index.html) | 5,847 |
| `final-xml-index-port` | [slutlig/xml/index.html](http://www.val.se:80/val/val2006/slutlig/xml/index.html) | [20100210001044](https://web.archive.org/web/20100210001044id_/http://www.val.se:80/val/val2006/slutlig/xml/index.html) | 73,953 |
| `KF0180-elected` | [slutlig/K/kommun/01/80/valda.html](http://www.val.se:80/val/val2006/slutlig/K/kommun/01/80/valda.html) | [20081210162827](https://web.archive.org/web/20081210162827id_/http://www.val.se:80/val/val2006/slutlig/K/kommun/01/80/valda.html) | 21,738 |
| `KF018001-elected` | [slutlig/K/kommunvalkrets/01/80/01/valda.html](http://www.val.se:80/val/val2006/slutlig/K/kommunvalkrets/01/80/01/valda.html) | [20081210162851](https://web.archive.org/web/20081210162851id_/http://www.val.se:80/val/val2006/slutlig/K/kommunvalkrets/01/80/01/valda.html) | 5,455 |
| `KF018003-person` | [slutlig/K/kommunvalkrets/01/80/03/person.html](http://www.val.se:80/val/val2006/slutlig/K/kommunvalkrets/01/80/03/person.html) | [20061115090522](https://web.archive.org/web/20061115090522id_/http://www.val.se:80/val/val2006/slutlig/K/kommunvalkrets/01/80/03/person.html) | 42,968 |
| `night-XML-index` | [valnatt/xml/index.html](http://www.val.se:80/val/val2006/valnatt/xml/index.html) | [20061010111234](https://web.archive.org/web/20061010111234id_/http://www.val.se:80/val/val2006/valnatt/xml/index.html) | 69,439 |
| `RD03-person` | [slutlig/R/riksdagsvalkrets/03/person.html](http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/03/person.html) | [20100405222247](https://web.archive.org/web/20100405222247id_/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/03/person.html) | 32,987 |
| `RD07-elected` | [slutlig/R/riksdagsvalkrets/07/valda.html](http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/07/valda.html) | [20100405222337](https://web.archive.org/web/20100405222337id_/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/07/valda.html) | 3,786 |
| `RD28-person` | [slutlig/R/riksdagsvalkrets/28/person.html](http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/28/person.html) | [20100406202314](https://web.archive.org/web/20100406202314id_/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/28/person.html) | 28,760 |
| `RF01-elected` | [slutlig/L/landsting/01/valda.html](http://www.val.se:80/val/val2006/slutlig/L/landsting/01/valda.html) | [20090522192832](https://web.archive.org/web/20090522192832id_/http://www.val.se:80/val/val2006/slutlig/L/landsting/01/valda.html) | 28,957 |
| `RF0101-elected` | [slutlig/L/landstingsvalkrets/01/01/valda.html](http://www.val.se:80/val/val2006/slutlig/L/landstingsvalkrets/01/01/valda.html) | [20090522222525](https://web.archive.org/web/20090522222525id_/http://www.val.se:80/val/val2006/slutlig/L/landstingsvalkrets/01/01/valda.html) | 5,266 |
| `RF0101-person` | [slutlig/L/landstingsvalkrets/01/01/person.html](http://www.val.se:80/val/val2006/slutlig/L/landstingsvalkrets/01/01/person.html) | [20090524000922](https://web.archive.org/web/20090524000922id_/http://www.val.se:80/val/val2006/slutlig/L/landstingsvalkrets/01/01/person.html) | 61,456 |
| `RD07-person-supplied` | [slutlig/R/riksdagsvalkrets/07/person.html](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html) | [20100406201456](https://web.archive.org/web/20100406201456id_/http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html) | 27,956 |

All 22 objects above returned HTTP 200 and their actual bodies were inspected. HTML index completeness means the listed navigation/file inventory only; it does not certify child retrieval. RD/RF national final XML covers 29/98 constituencies; KF XML is one full municipality (Bjurholm); other KF/RF HTML is sampled. The other-party RD07 page is complete for its displayed candidate table, reconciled as above. Final and night indexes belong to separate source stages. Named-source acquisition completeness for all KF and all supplementary other-party data remains unverified.

| Object | Retrieval UTC | MD5 | SHA256 |
|---|---|---|---|
| `archived-other-person-K-index` | 2026-10-11T14:18:16Z | `da0ff6679b9f397a297948f394bfb023` | `af0c74e8908c2a99b320e0ce1c410de724e3f2c47b9194624531a1daaf9a8925` |
| `archived-other-person-L-index` | 2026-10-11T14:18:14Z | `97c1dd91129a98c41898cc90160a4b34` | `8d6df2276a430e1c91b3aa56b10389eb0ec3409461d8be8a78d162d88172fabb` |
| `archived-other-person-R-index` | 2026-10-11T14:18:04Z | `4c781f265949ffdca3cf876af03431d7` | `8836a10da345e1a10e5ed4ee1fe9f79968540f81ee513a4029ffde366e2b5b38` |
| `archived-other-person-RD07` | 2026-10-11T14:18:37Z | `97ff6b6206b0ca579177e23b7e616ce1` | `7b9bf5bcfba958c1e20965cc2eefd79e3167f1baeee14e9ed48efafd30be394b` |
| `direct-archived-final-KF-XML` | 2026-10-11T14:13:23Z | `227515e1a46178ae2fe2df3de44ddaac` | `9f7e808af882026efaf2163f4b2c9c45bf85b454c2a7a607d2e67f2afec009c7` |
| `direct-archived-final-RD-XML` | 2026-10-11T14:13:17Z | `8277ee6e128c9961156875fb2e7d1feb` | `a96545cf81e27669af6ac23090ffc3097b13bcb11d0272b70a196eb818245c18` |
| `direct-archived-final-RF-XML` | 2026-10-11T14:15:05Z | `9769567d22708a83ea83d21ee2e9086b` | `451dda5e4aa89168af8b363968863e118cf40380918cb9dd2c2eca904d7b3fe9` |
| `direct-archived-night-RD-XML` | 2026-10-11T14:13:31Z | `1e9f2466f992805193c153cc87d1aa2c` | `8ea1b7ad67325a23602eec9aaf062f602deb03ab4c769d36eed77256ea820c85` |
| `direct-archived-other-person-votes` | 2026-10-11T14:16:54Z | `f3d2b0215c0af799aa69d82bf744abf0` | `995b277e86bbe3fad46e9c2e44d9aa7da14fdcdb79eb0fb9507ea676e6eabf85` |
| `direct-archived-statistics` | 2026-10-11T14:15:36Z | `746214409918ce10f85ddbc314e72a17` | `515f46d1f30a8722d2794d66d072a3d0462cf8b078376bb2b40aa3e286836659` |
| `final-xml-index-port` | 2026-10-11T14:11:12Z | `f1622302b378423ff2645de60c02c2cc` | `1b22e23052ea180be56fe303318dc2dfca80dbd3e6c6fdd1c1868181ceec4958` |
| `KF0180-elected` | 2026-10-11T14:05:02Z | `12346e5583f9f9cc1bc74fe7a242878a` | `d771fee05e8ffdc0a85c7fed24131b6d2edcf742881572bf04fc69145d4ad566` |
| `KF018001-elected` | 2026-10-11T14:07:00Z | `3f793f85693dcecbbb4a9a69232b9cce` | `fc19176f93592ef5dda7759a37b857363a30f974776fe2d9853350296ba71961` |
| `KF018003-person` | 2026-10-11T14:08:30Z | `5ada79868e69e891a677a586a78edb1b` | `b912f58c2303b5eeb88479fb23da8d976a9ada657c126e35fc88aae13c4aae5c` |
| `night-XML-index` | 2026-10-11T14:09:27Z | `ecbfc52e5ae1ae0eb963081dbccac9a6` | `a925c141813235bb45826e7edb571ca5135a9b2fdbb60ab27c8a5e8fdff8f947` |
| `RD03-person` | 2026-10-11T14:09:37Z | `e895ece4158a8f9e76b56c86427ab34b` | `28070963cb4d40319148e303aea89a169893b6bd81946ea27c293ef923e24cf4` |
| `RD07-elected` | 2026-10-11T14:02:45Z | `b2527bd4b9c747e531b01bc4a5523eb2` | `fecb3bd5de8d59cbc1dd5331ef95fd86afb26296fd17a657930d2bee961960c9` |
| `RD28-person` | 2026-10-11T14:09:39Z | `22643f963c0cc7130bd1996398e8aca9` | `5432b9ad2dc42f74e377f96b5b80c0171f0478913794fe2bd56155fb1f98acde` |
| `RF01-elected` | 2026-10-11T14:07:09Z | `aa7f872d76c30f651fa589c73d986f33` | `43f4b6c4a0efa53e28b7f298a3592fa54e2d29a5b395ad6f35762f6a71fd584f` |
| `RF0101-elected` | 2026-10-11T14:08:34Z | `288e88ef31ea9e87b8405086fdbbffb4` | `837f188d38d16c36b8e2c06836427bcbe61f9b80afd713e3c5e1fd027cbe5fa1` |
| `RF0101-person` | 2026-10-11T14:07:04Z | `7c35c0a0ac0ad5dcb9fc8dbb480d71f5` | `2f6dbad9a8d6d7bd110c392b04765c65fb3054b61e0d825acba92badb6c797c5` |
| `RD07-person-supplied` | 2026-10-11T14:01:38Z | `fdd60446929f96293cbb92feb325d721` | `b894379fc2274b5f29be64169f657130950b759a6c777d0274d334a5a6ac8b9a` |

RD HTML availability inventory (metadata only unless marked fetched; an empty lookup is not proof of absence):

| Original RD page | Advertised capture UTC / URL | Actual HTML fetched in this review |
|---|---|---|
| [01](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/01/person.html) | No capture located | No |
| [02](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/02/person.html) | No capture located | No |
| [03](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/03/person.html) | [20100405222247](https://web.archive.org/web/20100405222247/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/03/person.html) | Yes |
| [04](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/04/person.html) | No capture located | No |
| [05](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/05/person.html) | No capture located | No |
| [06](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/06/person.html) | [20100406200429](https://web.archive.org/web/20100406200429/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/06/person.html) | No |
| [07](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html) | [20100406201456](https://web.archive.org/web/20100406201456/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/07/person.html) | Yes |
| [08](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/08/person.html) | No capture located | No |
| [09](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/09/person.html) | [20100406201508](https://web.archive.org/web/20100406201508/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/09/person.html) | No |
| [10](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/10/person.html) | [20100406202513](https://web.archive.org/web/20100406202513/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/10/person.html) | No |
| [11](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/11/person.html) | [20100406202528](https://web.archive.org/web/20100406202528/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/11/person.html) | No |
| [12](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/12/person.html) | [20100406201538](https://web.archive.org/web/20100406201538/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/12/person.html) | No |
| [13](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/13/person.html) | [20100406201554](https://web.archive.org/web/20100406201554/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/13/person.html) | No |
| [14](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/14/person.html) | [20100406202549](https://web.archive.org/web/20100406202549/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/14/person.html) | No |
| [15](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/15/person.html) | [20100406201615](https://web.archive.org/web/20100406201615/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/15/person.html) | No |
| [16](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/16/person.html) | [20100406202127](https://web.archive.org/web/20100406202127/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/16/person.html) | No |
| [17](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/17/person.html) | [20100406202137](https://web.archive.org/web/20100406202137/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/17/person.html) | No |
| [18](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/18/person.html) | [20100406202634](https://web.archive.org/web/20100406202634/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/18/person.html) | No |
| [19](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/19/person.html) | [20100406202153](https://web.archive.org/web/20100406202153/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/19/person.html) | No |
| [20](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/20/person.html) | [20100406202650](https://web.archive.org/web/20100406202650/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/20/person.html) | No |
| [21](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/21/person.html) | [20100406202219](https://web.archive.org/web/20100406202219/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/21/person.html) | No |
| [22](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/22/person.html) | [20100406202705](https://web.archive.org/web/20100406202705/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/22/person.html) | No |
| [23](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/23/person.html) | [20100411205203](https://web.archive.org/web/20100411205203/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/23/person.html) | No |
| [24](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/24/person.html) | [20100406202732](https://web.archive.org/web/20100406202732/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/24/person.html) | No |
| [25](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/25/person.html) | [20100406202748](https://web.archive.org/web/20100406202748/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/25/person.html) | No |
| [26](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/26/person.html) | [20100406202259](https://web.archive.org/web/20100406202259/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/26/person.html) | No |
| [27](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/27/person.html) | [20100406202821](https://web.archive.org/web/20100406202821/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/27/person.html) | No |
| [28](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/28/person.html) | [20100406202314](https://web.archive.org/web/20100406202314/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/28/person.html) | Yes |
| [29](http://www.val.se/val/val2006/slutlig/R/riksdagsvalkrets/29/person.html) | [20100406202334](https://web.archive.org/web/20100406202334/http://www.val.se:80/val/val2006/slutlig/R/riksdagsvalkrets/29/person.html) | No |

### Revised implementation recommendation and preservation priorities

The earlier recommendation should be narrowed: **person-level identity remains blocked, but candidate-result observations are demonstrably available**. This review does not recommend discarding named/list-position/result observations merely because a global candidate ID is missing. No public-name policy or candidate-key schema change is approved by this investigation.

| Component | Recommendation |
|---|---|
| Party/results data | Proceed to an implementation decision for final RD/RF/KF using the official XML family; preserve/validate all required components. Archived XML agrees numerically/structurally with current XML in the complete RD/RF files and sampled KF file. |
| Preference votes | Preserve candidate-result microdata from the original final XML and supplementary other-party pages. Reuse official area-level totals rather than reconstructing persons by name. List-specific observations can use documented list/position references. Nationwide candidate-level completeness, especially other parties and KF, must be validated before promising full coverage. |
| Candidacy data | Existing ballot XML supports documented ballot/list/position occurrences and available attributes. An explicit occurrence key is defensible; it must not masquerade as a person ID. Archived result pages do not supply ballot position or zero-vote candidacy populations. |
| Person-level candidate identity | Still defer cross-list/cross-RD/RF/KF linkage. Ask for an original election-occasion ID/register mapping from Valmyndigheten or an independently linkable SCB register. Names, rankings and ballot positions are not substitutes. |
| Elected candidates | Preserve the original final XML relations, with archived named elected HTML as supporting evidence. Area/party/election order supplies relation-level observations; ballot/person joins remain conditional on verified identity. Do not use later membership files. |
| Substitutes | Preserve explicit final XML order/group relations and supporting archived constituency tables. Do not flatten groups or infer member identity from a repeated name or summary-page row order. |
| Comparable preliminary results | Still unsupported by the sources established here. Keep election-night and final distinct; seek the actual Wednesday/collection snapshot and independent controls. The retrieved night XML is not that snapshot. |

Recommended next preservation actions, before production implementation:

1. Preserve the original named **national RD/RF final XML**, the final/night indexes, and required **KF municipal final XML**, recording exact capture bytes/URLs/checksums. National KF aggregation does not replace the municipal candidate files. Do not infer archive absence from availability metadata alone.
2. Preserve the supplementary **other-party** hierarchy for RD/RF/KF and validate candidate-record totals against its displayed party/area aggregates and main XML controls. Start with the already reconciled Kronoberg example; do not sum area and municipal breakdowns together.
3. Preserve the named elected/substitute constituency pages and ballot sources as independent supporting evidence. Prefer structured XML for relation order; retain HTML snapshot/source timestamps and distinguish capture date from election update time.
4. Keep useful HTML captures as provenance and cross-checks; missing individual RD person pages need not prevent RD named-result preservation because the national XML covers all 29 constituencies. A full acquisition sweep must still distinguish positive records, documented zero occurrences and unresolved coverage.
5. Request the original candidate identity mapping and complete preliminary collection snapshot. Do not generate person IDs, restore public names, infer zero, or substitute final Wednesday results without a separately reviewed decision.

No production implementation, candidate-ID/name change, canonical build, commit or push was made. The five existing local 2006 source MD5 values were checked again and remain unchanged. The additional archived bytes/diagnostic cache remain outside the Git repository; the only repository change is this report.

## Implementation readiness

Final completeness and identity assessment, 2026-10-11. This section supersedes the earlier provisional acquisition/completeness recommendations above. It is an assessment, not an implementation or a decision to change the public candidate schema.

### Scope and counting units

The review parsed every ballot XML document in the preserved nested `xml.zip`, the complete archived national RD/RF final XML, and archived final XML for **all 290 municipalities**. Three large municipal responses initially timed out (0180, 0380, 1480); one bounded retry recovered all three. No expected municipal XML remains missing. All 290 archived municipal XML roots declare `TID_RAPPORT="20061206032119"`; archive capture dates are separate from that election-result reporting timestamp.

The supplementary official other-party presentation was enumerated at **29 RD constituencies, 98 RF constituencies and 394 KF municipal constituencies/undivided areas**, with successful HTTP 200 responses for all 521 analytical pages. Parent/index pages and municipality breakdowns of RD/RF areas were excluded from the analytical sums. For undivided KF, the municipality index links to `00/index.html`: that child contains the candidate table. A parent page is not evidence of zero candidates. These technical source paths do not establish a new public geographic unit.

Counts below are source observations, **not unique people**. Main XML area `PERSONVAL` and main XML list `PERSONVAL` are alternative views and must never be added together. Ballot observations include repeated applicability of the same physical list in different constituencies.

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Ballot/list-position observations, including geography | 20,926 | 46,498 | 86,398 |
| Distinct party × list × position within election type | 6,417 | 13,412 | 52,277 |
| Distinct source list numbers | 309 | 689 | 2,668 |
| Distinct ballot party codes | 43 | 42 | 219 |
| Ballot geographical units | 29 constituencies | 98 constituencies in 20 regions | 394 areas in 290 municipalities |
| Named main XML area-level candidate-result observations | 5,150 | 18,302 | 67,529 |
| Main XML list-position person-vote observations | 5,225 | 19,031 | 69,379 |
| Supplementary other-party candidate-result observations | 4,279 | 1,827 | 1,285 |
| Main area + supplementary candidate-result observations | **9,429** | **20,129** | **68,814** |
| Archived names recovered for supplementary observations | 4,279 | Not established | Not established |
| Explicit zero-valued candidate `PERSONVAL`/supplementary rows | 0 | 0 | 0 |

Every counted candidate-result row is positive. This does **not** mean every ballot candidate received a person vote: the ballot files document many additional list positions, whereas these result structures publish positive candidate records. There is no stable source person ID or comprehensive explicit zero-valued person population in these sources.

The ballot observation key `election occasion × election type × applicability geography × party code × list number × position` has no duplicates in the complete 153,822-row occurrence collection. Across repeated geography copies, all 72,106 distinct election-type/party/list/position keys have consistent ballot information, sex and age. This establishes source list-position identity, not identity across different lists.

The sources also retain **14 `Utkast` ballot occurrences containing 43 candidate occurrences**, all in KF; 7,606 ballot occurrences are `Definitiv`. Keep that source distinction. Neither status is automatically equated here to modern `VALSEDELSSTATUS = S`, candidate validity or an exhaustive election-person population. The 2006 ballot source does not supply the modern stable candidate-number/validity contract.

### Geographic and party completeness

- **RD:** complete named main XML for all 29 constituencies and all seven separately represented main-party aliases. All 29 archived supplementary area pages have also been retrieved; they contain 31 distinct other-party labels. Their candidate counts, votes and displayed shares exactly match the corresponding current official pages after ignoring names. Other-party candidate rows are therefore available individually by source table/party/row, although they have no list number, ballot position or source person ID.
- **RF:** complete named main XML for all 98 constituencies in 20 regions, including smaller parties separately represented in that source (25 main-party aliases). All 98 current supplementary pages were retrieved: 73 contain positive candidate rows, with 21 distinct party labels. They supply the remaining 1,827 candidate-result observations, but their names read `Personuppgift borttagen`. Named supplementary RF candidate pages have not been recovered.
- **KF:** all 290 archived municipal final XML files were retrieved and parsed, covering all 394 source constituency/undivided areas. All 67,529 main area candidate rows contain real archived names; the main source represents 185 party aliases, including local parties. All 394 current supplementary pages were retrieved, of which 114 contain positive candidate rows, with 36 distinct party labels. The remaining 1,285 supplementary rows are individually observable but anonymised, and their archived names have not been recovered.

These party-label/alias counts must **not** be added to obtain a unified number of parties: the same party can be separately represented in one area and grouped under `ÖVR` in another, and abbreviation/name/code representations differ. The ballot party-code counts are a separate measure. No small/local-party or `ÖVR` source category was discarded in the diagnostic.

One successful archive CDX query for the complete `www.val.se/val/val2006/slutlig_ovrigt/ovriga_personroster/*` family returned 738 collapsed URL records: 734 RD objects, the RF and KF navigation indexes, the common index and CSS. It includes all 29 RD analytical area pages, but no RF/KF candidate-page children. This corroborates the observed named supplementary gap in the examined archive family; it is **not proof that no other archive or host could ever contain them**. Current anonymised RF/KF rows cannot be matched to ballot people simply by their vote totals or table order.

Consequently, geographic source coverage is complete, and the available positive source rows can be enumerated. **An exhaustive person-level candidate population, including all zero-vote/write-in/unlisted candidates, has not been established.** In particular, a ballot-only population would lose official result-only records.

### List-position reconciliation and result-only observations

All result list-position keys `election type × result area × party-prefixed list number × KANDIDAT position` are unique; none has a missing position. `PERSONVAL@KANDIDAT` refers to the position on that list, not a person number.

| Match to preserved ballot position | RD | RF | KF |
|---|---:|---:|---:|
| Same result/candidacy constituency | 5,225 | 18,503 | 69,115 |
| Additional match elsewhere in the same region/municipality | 0 | 502 | 0 |
| No match anywhere in that election's ballot files | 0 | 26 | 264 |
| Person votes on unmatched result positions | 0 | 105 | 636 |

The RF 502 cases demonstrate use of a documented list outside its nominal ballot constituency; they are not 502 missing ballot candidates. The remaining RF 26 records span 17 result lists, and KF 264 records span 255 result lists. Preserve them as official **result-only list-position observations**, not inferred ballot candidacies or invented people. Examples include RF Jacob Dencker/Åsa Öckerman at position 28, and KF Jacqueline Esso (0055-04089, position 1, 013900). This review does not claim that every unmatched record is a handwritten-name list: the source position/export discrepancy is established, but its administrative cause is not universally documented.

All observed main XML list totals reconcile exactly with their child candidate votes: RD 233 lists, RF 2,086 lists, and every observed KF list. Main party candidate aggregates also reconcile wherever their non-`ÖVR` source control is explicit. This validates the **published main list records**, not completeness of unseen lists or a source person roster.

For illustration, RD has 627 documented ballot occurrences without a positive candidate row within an observed result list; RF has 17,610 under the same strict applicability rule. These are evidence about source list positions, not additional verified zero-person totals. Missing result lists, missing validity information and other-party rows without list references must not be converted indiscriminately to zero. No zero inference or population completion was implemented in this review.

### Reconciliation beyond Kronoberg: successes and source differences

Combining the main **area** candidate records with the appropriate supplementary area table gives:

| Election | Main candidate votes | Supplementary candidate votes | Combined candidate votes | Independent area XML control |
|---|---:|---:|---:|---:|
| RD | 1,147,952 | 87,649 | **1,235,601** | 1,231,512 |
| RF | 1,167,604 | 18,633 | **1,186,237** | 1,186,237 |
| KF | 1,543,320 | 10,833 | **1,554,153** | 1,554,153 |

- **RF:** exact reconciliation in all 98 constituencies, not merely national aggregation.
- **KF:** exact reconciliation in all 394 areas after following the undivided-area `00` links, not merely national aggregation.
- **RD:** exact reconciliation in 24 of 29 constituencies, including Kronoberg. Five source differences remain:

| RD code / constituency | Main XML candidate votes | Supplementary candidate votes | Combined | XML area control | Difference |
|---|---:|---:|---:|---:|---:|
| 11 Malmö kommun | 28,503 | 4,006 | 32,509 | 32,076 | +433 |
| 12 Skåne läns västra | 30,939 | 4,460 | 35,399 | 34,906 | +493 |
| 13 Skåne läns södra | 29,963 | 4,431 | 34,394 | 33,830 | +564 |
| 14 Skåne läns norra och östra | 36,534 | 4,036 | 40,570 | 40,038 | +532 |
| 28 Västerbottens län | 41,180 | 2,067 | 43,247 | 41,180 | +2,067 |
| **Total** | | | | | **+4,089** |

The archived named and current anonymised supplementary tables have identical party/vote/share vectors in all 29 RD areas. The RD discrepancy is therefore **not introduced by removing names, a stale local ballot snapshot, or mixing area and district levels**. The extra observations are ordinary candidate table rows, not header/total rows accidentally parsed as candidates. The definitive source/definition explanation remains unresolved. In Västerbotten the main XML `ÖVR` node has no `PERSONKRYSS` attribute, while the supplementary table contains 2,067 positive candidate votes. Retain both source values; do not invent a reconciliation.

The official national statistics page [`personroster_allaval.html`](https://historik.val.se/val/val2006/slutlig_ovrigt/statistik/personroster_allaval.html) reports **1,554,115 KF preference-marked votes**, which is **38 fewer** than the reconciled detailed municipal candidate/area total of 1,554,153. It also reports 5,521,563 KF valid votes, versus 5,521,566 in the current national XML. These independently published controls are not silently equated. This assessment has not established a correction history or a definitional explanation for these small national-statistics differences. They do not demonstrate a missing candidate record in the retrieved detailed area/list structures.

Matching aggregates is useful evidence but does not prove zero-vote candidate completeness, person identity, validity, or successful linkage of anonymous supplementary records. Conversely, these control differences do not justify dropping positive official candidate observations.

### Identity: what is and is not supported

| Concept | Evidence / safe interpretation |
|---|---|
| Ballot candidacy / list-position occurrence | Supported by election, party code, list, position and applicability geography. No name-based identity inference is required. |
| Same physical ballot position repeated across areas | Supported: its source key and all candidate attributes are consistent across copies. Keep source applicability separate from person identity. |
| List-specific result observation | Supported where `LISTNUMMER` and `PERSONVAL@KANDIDAT` are explicit, including result-only positions. |
| Main area candidate-result observation | Supported as an official source row. Preserve source XPath/row provenance; name or vote rank alone is not a universal unique key. |
| Supplementary other-party observation | Supported as party/area/source-table row. RD archived names exist; RF/KF names and list positions cannot currently be recovered for these rows. |
| Candidate × election × party as one deduplicated person | Not generally established. The same person may have multiple lists/areas, while homonyms can exist within one party/area. |
| Person across different lists | Some plausible matches exist, but no general independently validated linkage or stable person identifier exists. No automatic merge. |
| Person across RD/RF/KF | Plausible multi-election appearances exist; no complete source person-ID linkage has been established. No automatic merge. |

Concrete examples show why both repetition and homonymy matter:

- Aase Jönsson has identical ballot information (`Aase Jönsson, Skolassistent, Billeberga`) under KD/0068 in RD list 01142 position 20, KF 1214 list 01632 position 1, and RF 1203 list 01369 position 10. This is strong contextual evidence for a shared person, but it is not a source person identifier or independently validated universal cross-election rule. It remains three documented candidacies here.
- Rickard Falkvinge's exact ballot information (`Rickard Falkvinge, 34 år`) occurs on many RD Piratpartiet lists, including 02424 and 03271. Across all ballot data, **897 KF, 763 RF and 225 RD exact information/party groups** recur on more than one distinct list. **5,270** exact information/party groups span multiple election types, **531** span all three. These are diagnostic text groups, not deduplicated people.
- RF 0803, KD: `Åke Nilsson` is represented by list 01207 position 20 (Musikmästare, Högsby, age 51, two votes) and list 01219 position 20 (Partiombudsman, Silverdalen, age 55, one vote). The ballot attributes support **different people with the same name**, not an automatic merge.
- RF 1403, S: list 02031 contains `Mikael Andersson` at position 15 (Ombudsman, Vänersborg, age 44, 134 votes) and position 27 (Livsmedelsarbetare, Stenkullen, age 40, 98 votes). Even name + party + constituency + list is insufficient without position.
- Main area result data contain two such repeated name/party/area keys in RF and 22 in KF (44 KF rows); RD main area records have none. Absence of a collision in RD is not proof of a globally unique person-name key.

The same list/position can be linked through official source keys. Different list positions must not be collapsed by text equality. No manufactured person ID, numeric replacement, candidate merge or cross-election linkage was created.

### Local preservation and reproducibility

The retrieved objects are now preserved separately under ignored `.local-data/rkl/2006/archived-assessment-20261011/`. **No existing source file was overwritten.** The exact object-by-object preservation list is `source_objects.csv` (also `source_objects.json`): **866 objects, 157,138,828 bytes**, including **339 archived source responses** and the current official comparison/supplementary responses. Each entry records:

- original URL;
- actual archived response URL and capture timestamp, where applicable;
- retrieval timestamp;
- source type and election/geographic coverage;
- byte size, MD5 and SHA256;
- local object filename and why it is needed.

CSV manifest MD5: `dcc6c527e33335c37c6381280a89699b`.
CSV manifest SHA256: `249f0b0da7ec9da599cfccefee4cc51d7e209d0d110f5dc8065f4078bb511f47`.

Preservation priorities are:

| Object family | Coverage / purpose |
|---|---|
| Existing ballot `xml.zip` | All documented RD/RF/KF list-position candidacies, including non-positive/unknown-result positions and source ballot statuses. Preserve its existing bytes/hash. |
| Archived `slutresultat_00R.xml` | All 29 RD constituencies; named main candidate, list-position, elected and substitute records. Capture 20100210001051; MD5 `8277ee6e128c9961156875fb2e7d1feb`; SHA256 `a96545cf81e27669af6ac23090ffc3097b13bcb11d0272b70a196eb818245c18`. |
| Archived `slutresultat_00L.xml` | All 98 RF constituencies; named main candidate/list/elected/substitute records. Capture 20080319053452; MD5 `9769567d22708a83ea83d21ee2e9086b`; SHA256 `451dda5e4aa89168af8b363968863e118cf40380918cb9dd2c2eca904d7b3fe9`. |
| Archived 290 municipal final XML files | All 394 KF areas and named main candidate/list/election relationships; exact individual capture URLs/hashes in the manifest. A national aggregate file is not a replacement. |
| Archived 29 RD supplementary area tables | All 4,279 named other-party observations; preserve the source/control differences as well as the reconciled areas. |
| Current 521 supplementary analytical tables | Positive other-party records and empty source tables at all expected areas; especially necessary for the anonymised RF/KF observations not recovered with names. |
| Final/night indexes, archived night RD XML and selected named HTML relation/result pages | Independent source-structure, stage, name and relation evidence; do not confuse an index capture with retrieval of every linked object. |
| Current national/statistical and sampled municipal comparison controls | Demonstrate unchanged source values where checked and preserve independently published control differences. |

All preserved objects were checked against their recorded size/SHA256 when copied. They are raw source/provenance objects, **not canonical assets**. The existing five-file source collection was preserved unchanged; no archived object or local manifest was added to Git. The report remains the only repository-visible change.

### Additional local SND archives checked before closing the assessment

The final local-tree check found three additional ZIP files under `snd/`, beyond the five-file collection recorded earlier. They were inspected read-only, with extraction to the external diagnostic cache. All 19 packaged SHA256 checks (5 + 7 + 7) pass. SPSS/Stata and Excel schemas were examined using existing R tooling; none supplies candidate names, person IDs, candidacies, candidate preference votes or election relationships.

| Local file | Actual contents | Identification/validation implication |
|---|---|---|
| `snd/snd0237-11-3.zip` | `0241_EuP04_*` Stata/SPSS/Excel: **European Parliament 2004**, 6,165 geographic rows × 21 fields, plus notes | Filename/folder is misleading for 2006. Do not use as RD 2006 without resolving provenance. No candidate records. |
| `snd/snd0238-10-3.zip` | RF 2006 Swedish/English SPSS/Excel, codebooks and variable mapping: 6,044 geographic rows × 26 fields | Independent aggregate validation. 5,415,740 valid votes, 5,559,749 voters, 144,009 invalid votes. No candidate/person-vote microdata. |
| `snd/snd0239-10-3.zip` | KF 2006 Swedish/English SPSS/Excel, codebooks and variable mapping: 6,177 geographic rows × 26 fields | Independent aggregate validation. 5,521,566 valid votes, 5,636,103 voters, 114,537 invalid votes. The valid-vote total agrees with the current final XML, rather than the statistics page's 5,521,563. No candidate/person-vote microdata. |

Exact ZIP hashes:

- `snd0237-11-3.zip`: MD5 `15a87e6913c245bb0eec3c6f23d9846d`; SHA256 `bae2bcd7b8176dccd24d9a4147c32524372ec17145508f34e66ca6cf9469ec7f`.
- `snd0238-10-3.zip`: MD5 `15971f2311efda09dc7c76c160808d02`; SHA256 `eddf4c09d888ed54712462af09b94012d2f86769e85e189e0b8bc285fd7816a8`.
- `snd0239-10-3.zip`: MD5 `94ca1aff1d24e2cffe9a1311a267a792`; SHA256 `987293616c8aea8717aff3a1be0cbb702421e7d18a4422d9c108d6470d782de5`.

The authoritative [RF version-3 catalogue](https://researchdata.se/en/catalogue/dataset/snd0238-10/3) and [KF version-3 catalogue](https://researchdata.se/sv/catalogue/dataset/snd0239-10/3) describe SCB-derived geographic election statistics adapted by SSD. Their data are useful independent controls, not candidate-record sources. The [RD 2006 catalogue](https://researchdata.se/en/catalogue/dataset/snd0237-11/2.0) describes a different subject from the actual local `0241_EuP04_*` contents; the local filename does not establish that these bytes came from that RD dataset. No original download URL was inferred for the mismatched local ZIP.

ZIP entry/modified dates on 2026-10-11 are packaging/local-file metadata, not dates of election-result reporting. The RF/KF datasets contain `Poströster` rows, but their verified totals are final-result controls; this is not evidence for a separate preliminary collection snapshot. They therefore do not change either the candidate-identity conclusion or the preliminary-source limitation. Preserve all three originals locally, with the first explicitly marked as a provenance mismatch; do not rename, replace or incorporate them into a canonical input silently.

### Final bounded preliminary-source check

The final check used the already retrieved final/night indexes and made four direct archived requests for the previously plausible `preliminar_onsdag`, `onsdag/xml`, `preliminar` and `valnatt/.../onsdagsdistrikt` routes. All four returned archive HTTP 404. One final bounded archive-index query for non-final `prel|onsdag|uppsaml` URLs returned HTTP 503 (`Internet Archive: Temporarily Offline`); it was **not** treated as proof of source absence or retried indefinitely.

**Conclusion: no complete 2006 preliminary collection/Wednesday source has been established. Stop archive searching for this issue at this stage.** This is a retrieval/evidence limitation, not proof that preliminary figures were never published. The preserved election-night XML remains election-night data; final Wednesday figures must not fill the gap. No preliminary candidate data were recovered that could resolve candidate zero/identity questions.

### Recommendation by public function

| Function | 2006 recommendation |
|---|---|
| `results()` | Ready to implement fixed final RD/RF/KF from official structured sources after review. Comparable preliminary remains unavailable; do not relabel election-night. Retain source missingness and independently published differences. |
| `seats()` | Ready to implement final source mandate allocations for RD/RF/KF, using official codes and original election relationships rather than later membership. |
| `preference_votes()` | Source candidate-result and list-position observations are now usable across all areas, including result-only positive positions and anonymised other-party observations. An explicit **source-observation/candidacy-level contract** is needed before fitting these to a person-ID-based API. Do not promise unified people, universal list attribution, synthetic zeros or reconciled RD national totals. |
| `candidacies()` | Complete documented ballot/list-position source occurrences can be represented conservatively, including available attributes and separate status. Agree a source candidacy key and unsupported typed missing fields first; do not present that key as a person ID. |
| `candidates()` | Defer the ordinary person × election × party deduplication contract. A source-observation representation is possible, but neither a person roster nor cross-list/cross-election identity has been established. Preserve result-only positive observations in any eventual population. |
| `elected()` | Original final XML relation observations are available: RD 349, RF 1,656, KF 13,092. Source election order/party/geography/basis can be preserved; identity-dependent candidate enrichment/linkage remains conditional and must not be manufactured. |
| `substitutes()` | Original final XML relation observations are available: RD 596, RF 2,501, KF 11,254. These are ordered/grouped relations, not unique substitute persons. Preserve group/order and defer unsupported person joins. |

**Final recommendation: B, with an explicit candidacy/source-observation qualification.** Begin with final results and seats; approve a conservative list-position/source-row representation for person votes and candidacies rather than inventing a person ID. Do not implement all seven unchanged person-key APIs on the assumption that names are identities. Person-deduplicated `candidates()` and identity-dependent enrichment should remain deferred until separately resolved. Elected/substitute relation data can be retained without losing their source semantics, but their API identity contract also needs review.

Before candidate microdata publication, review the RD +4,089 source/control difference, KF's detailed-versus-statistics difference of 38, the absent named RF/KF supplementary pages, zero/validity rules, and the candidate-observation key/name contract. Aggregate agreement in RF/KF is not a substitute for these decisions. No production implementation, canonical-data change, public name restoration, candidate identity change, commit or push was performed.

## Dedicated SCB validation assessment (2026-10-11)

Valmyndigheten remains the primary build source; SCB is a separately processed,
official validation/reference source. It is not an independent vote count:
SCB's 2006 quality documentation describes processing and reviewing material
supplied by Valmyndigheten, including occasional corrections. This assessment
changed no production code, raw sources, canonical assets or package data.

### Local files and their validation roles

All seven unchanged files under `.local-data/rkl/2006/scb/` were inspected in R.
Their original export dates/URLs are not established from filenames alone.

| File | Approximate size; rows x columns | Role |
|---|---|---|
| mandat2006.dta | 0.082 MB; 394 x 14 | KF municipal constituency seats, seven major parties and pooled others; filled-seat control as established below |
| valdist_ri2006.dta | 1.057 MB; 6,073 x 28 | RD district records; eligible voters, voters, valid/blank/other invalid votes, turnout, party counts/shares, calculated bloc shares |
| valdist_lt2006.dta | 1.068 MB; 6,135 x 28 | RF equivalent, with 102 exact duplicate rows |
| valdist_ko2006.dta | 1.057 MB; 6,073 x 28 | KF equivalent |
| valres_parti_valdistr2006_ri.dta | 45.890 MB; 215,405 x 12 | RD party x district, 29 constituencies/290 municipalities; 43 separate party codes plus categories |
| valres_parti_valdistr2006_lt.dta | 18.147 MB; 98,048 x 11 | RF party x district x constituency, 20 regions/98 constituencies/289 municipalities; 43 separate party codes plus categories |
| valres_parti_valdistr2006_ko.dta | 14.502 MB; 86,277 x 11 | KF party x district, 290 municipalities; 221 separate party codes plus categories and mandatparti indicator |

Prefer long tables and `partikod`, not `pnamn_kort`, which collapses smaller
parties. Code 9997 is residual valid other-party votes; 9998/9999 are blank/other
invalid ballots. The mandate-party indicator is not a mandate count. None of
these files contains candidate identifiers or preference votes.

RF wide duplication is material: naive sums are 5,682,281 voters and 5,534,115
valid votes. Explicitly comparing distinct complete rows leaves 6,033 records
and totals 5,559,749 and 5,415,740. The source was not deduplicated on disk.
Long RF district x party keys repeat 137 times, but the complete district x
region x constituency x party key is unique; those records must not be dropped.

Eligible voters/turnout are missing on source collection records ending 9800:
290 RD, 290 KF and 391 RF rows before exact-row deduplication. Preserve these
missing values. These files are final-result controls, not preliminary snapshots.

### Completed result comparisons

| Measure | RD | RF | KF |
|---|---:|---:|---:|
| Valid votes | 5,551,278 | 5,415,740 | 5,521,566 |
| Blank ballots | 96,922 | 141,637 | 112,063 |
| Other invalid ballots | 2,216 | 2,372 | 2,474 |
| All votes/voters | 5,650,416 | 5,559,749 | 5,636,103 |
| Eligible voters | 6,892,009 | 7,052,595 | 7,098,097 |
| Recalculated turnout (%) | 81.98504 | 78.83267 | 79.40301 |

All counts match preserved final XML. Eligible counts sum ordinary records
without filling collection NAs; RF uses the disclosed distinct-row diagnostic.
Successful online SCB queries also confirm the denominators and rounded
national turnout 82.0 / 78.8 / 79.4. Blank plus other invalid votes matches the
online database's combined invalid category.

Party checks use official codes for the seven major parties and pool every
remaining valid party. XML sometimes gives local parties separate GILTIGA
nodes, so comparing only its OVR node would omit them. This is not a claim
that every individual small-party code has been exhaustively cross-checked.

| Geography | Areas | Party-group comparisons | Differences |
|---|---:|---:|---:|
| RD municipality | 290 | 2,320 | 0 |
| RD constituency | 29 | 232 | 0 |
| RF municipality | 289 | 2,312 | 0 |
| RF region | 20 | 160 | 0 |
| RF constituency | 98 | 784 | 0 |
| KF municipality | 290 | 2,320 | 0 |

Total: 8,128 matched party-group comparisons. RF municipality comparisons use
KRETS_RIKSDAG/KOMMUN; parallel KRETS_LANDSTING municipality branches overlap and
must not be concatenated. Gotland is outside RF coverage. A further 4,345
municipality count comparisons (valid votes, voters, blank/other invalid,
eligible voters) give zero differences: RD 1,450, RF 1,445, KF 1,450.
District observation units were not asserted to match XML one-to-one.

### Preference-vote discrepancies

Local DTA cannot explain preference-vote discrepancies. The online SCB tables
ME0104T24/T26/T25 can provide aggregate evidence; R/pxweb queries succeeded.

| RD constituency | SCB / XML control | Main plus supplementary candidate votes | Difference |
|---|---:|---:|---:|
| 11 Malmo | 32,076 | 32,509 | +433 |
| 12 Skane western | 34,906 | 35,399 | +493 |
| 13 Skane southern | 33,830 | 34,394 | +564 |
| 14 Skane northern/eastern | 40,038 | 40,570 | +532 |
| 28 Vasterbotten | 41,180 | 43,247 | +2,067 |
| National RD | 1,231,512 | 1,235,601 | +4,089 |

Ordinary valid votes agree in all five constituencies and broader geography.
SCB narrows the problem to preference-vote source/control semantics, not
ordinary party counts or missing geographic votes. VR28 has zero SD/other-party
preference votes in SCB, reproducing the XML control omission; supplementary
candidate records have 2,067. The cause remains unresolved. Preserve both.

RF SCB online total 1,186,237 matches reconciled detailed sources. KF SCB online
reports **1,554,153**, matching detailed candidate/area sources, whereas the
separate Valmyndigheten statistics page reports 1,554,115 (38 fewer). SCB
supports the detailed total; it does not establish the date/cause of the stale
or different presentation. Likewise valid KF votes are 5,521,566, three above
that page's 5,521,563. Do not conflate those differences or overwrite values.
Classification: RD unresolved source/control discrepancy; KF unresolved
presentation/version discrepancy with detailed aggregates corroborated.

### Mandates: the 14-seat difference is explained

Every one of the 394 local mandate rows equals XML allocated mandates minus
explicit `VALD NAMN="Kunde ej utses"` positions. These are unfilled seats, not
appointed people. All 14 are SD, across these 13 areas:

| Area | Municipality/constituency | Unfilled |
|---|---|---:|
| 018102 | Sodertalje Andra | 1 |
| 038200 | Osthammar | 1 |
| 076000 | Uppvidinge | 1 |
| 086000 | Hultsfred | 1 |
| 088500 | Borgholm | 1 |
| 126300 | Svedala | 1 |
| 127000 | Tomelilla | 2 |
| 143000 | Munkedal | 1 |
| 149500 | Skara | 1 |
| 181400 | Lekeberg | 1 |
| 188400 | Nora | 1 |
| 190700 | Surahammar | 1 |
| 196000 | Kungsor | 1 |

13,092 allocated - 14 unfilled = 13,078 filled. Major-party totals match;
pooled others are 885 allocated versus 871 filled. The DTA has no explicit
unfilled definition: its filled-seat interpretation follows from complete
reconciliation, not an assumed label. Current online Kfmandat reports allocated
seats: SD 280 + others 605 = 885; total 13,092. Queried Uppvidinge SD=1 and
Tomelilla SD=4 agree with allocated XML values.

Valmyndigheten's [experience report 2007:1](https://www.val.se/download/18.20a88e661721ad9571e107f/1592299588512/erfarenhetsrapport-2006-rapport-2007-1.pdf)
also identifies 14 initially unfilled seats. The earlier inventory's 13,092
KF VALD positions must not be interpreted as 13,092 appointed people: 14 are
placeholders. Future elected validation should distinguish these from candidates.
No implementation or candidate-identity rule was changed in this assessment.

### Statistics Database table inventory

API base: `https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/`.
Paths below are appended to this base. Metadata/queries were inspected with
installed pxweb 0.19.2. No runtime or DESCRIPTION dependency was added.

| Table path | Geography/variables | Validation |
|---|---|---|
| ME0104/ME0104C/ME0104T3 | RD municipalities/constituencies; party votes/shares, invalid/nonvoters | results; no national Region=00 cell, sum non-overlapping municipalities |
| ME0104/ME0104B/ME0104T2 | RF municipality/region; votes/shares | results; national Region=00L queried |
| ME0104/ME0104A/ME0104T1 | KF municipality/national; votes/shares | results; national queried |
| ME0104/ME0104C/Riksdagsmandat | RD constituency/aggregate, party mandates | seats; identified |
| ME0104/ME0104B/Ltmandat | RF region, party mandates | seats; identified |
| ME0104/ME0104A/Kfmandat | KF municipality/national, party mandates | allocated seats; national and two municipalities queried |
| ME0104/ME0104C/RiksdagsvalRostb7698 | RD eligible voters by region | denominator; national queried |
| ME0104/ME0104B/Landstingsmed | RF region/municipality, citizenship | denominator; national queried |
| ME0104/ME0104A/Kommunmed | KF municipality, citizenship | denominator; national queried |
| ME0104/ME0104D/ME0104T4 | Municipality/national turnout, all three elections | turnout; national queried |
| ME0104/ME0104D/ME0104T5 | RF turnout by published region | identified |
| ME0104/ME0104C/ME0104T24 | RD constituency/national, party/sex preference counts/shares | national and five affected constituencies queried |
| ME0104/ME0104B/ME0104T26 | RF region/national equivalent | national queried |
| ME0104/ME0104A/ME0104T25 | KF municipality/national equivalent | national queried |
| ME0107/ME0107C/Riksdagsledamoter; ME0107/ME0107B/Ltledamoter; ME0107/ME0107A/Kfledamoter | Region, party, sex; elected counts | population controls, not identity/substitute linkage |
| ME0107/ME0107C/ME010720T01; ME0107/ME0107B/ME010720T02; ME0107/ME0107A/ME010720T04 | Nominated/elected populations, party/sex/background | definitions/counts, not individual candidate filling |
| ME0107/ME0107B/ME010720T03; ME0107/ME0107A/ME010720T05 | Geographic nominated/elected populations | regional/municipal counts |

Result series generally cover 1973-2022; preference series 2002-2022; nominated
series 1991-2022. Check year-specific missing cells and definitions before using
candidate counts. Candidate valgrund tables begin in 2010. Mandate-period
avhopp/dropout tables are not controls for original elected relationships.

Examined database tables lack voting-district observations, lists/positions,
individual candidate IDs/preferences, substitute ordering and counting stages.
Use local DTA/historical publications for district checks. Modernised labels
(e.g. FP displayed as Liberalerna) must not replace historical code matching.
Online percentages require conversion/rounding-aware comparison with proportions.

Successful reproducible query:

```r
base <- "https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/"
x <- pxweb::pxweb_get(
  paste0(base, "ME0104/ME0104C/ME0104T24"),
  query = list(Region = c("00", "VR11", "VR12", "VR13", "VR14", "VR28"),
               Parti = "TOTALT", Kon = "1+2",
               ContentsCode = "ME0104AV", Tid = "2006")
)
as.data.frame(x, column.name.type = "code", variable.value.type = "code")
```

Read metadata first: region codes differ by table. These named dimension lists
work with this installed pxweb version. Queries were bounded to relevant cells.

### Publications and definitions

- [Allmanna val, valresultat 2006: Beskrivning av statistiken](https://www.scb.se/contentassets/0306ea5d06f34dfab00ef2ca653a5284/me0104_bs_2006.pdf), dated 2008-04-08: election-occasion reference time, SCB processing/review and possible database corrections.
- [Allmanna valen 2006 Del 1: Riksdagen den 17 september 2006](https://share.scb.se/ov9993/data/publikationer/statistik/_publikationer/me0104_2006a01_br_me01sa0701.pdf), 2007: authoritative SCB catalogue identified; PDF retrieval through web tool failed, so no uninspected numerical table is used as evidence here.
- [Allmanna valen 2006 Del 2: Landstingsfullmaktige den 17 september 2006](https://share.scb.se/ov9993/data/publikationer/statistik/_publikationer/me0104_2006a01_br_me02sa0701.pdf), April 2007: inspected official text. Contains region/constituency/municipality/district results; some preference tables restrict coverage to mandate-winning parties. Late advance votes may be represented at municipality rather than ordinary district level. Allocated RF seats 1,656 and rounded turnout 78.8% agree.
- [Allmanna valen 2006 Del 3: Kommunfullmaktige den 17 september 2006](https://share.scb.se/ov9993/data/publikationer/statistik/_publikationer/me0104_2006a01_br_me03sa0701.pdf), 2007: official catalogue identified; PDF retrieval through web tool failed. Read actual definitions before using individual tables.

See [SCB valresultat](https://www.scb.se/me0104) and the [historical publication catalogue](https://www.scb.se/hitta-statistik/sok/gammalt?Exact=true&Query=ME0104&Tab=older).
No complete publication collection was downloaded or added to the repository.

### General validation framework

Use Valmyndigheten for construction and SCB for official reference checks.
Freeze checksum/retrieval time, table metadata and exact queries; match election
occasion (including re-elections), counting stage, source version and historical
geography before totals. Use official codes, explicit party pooling and only
non-overlapping geographical branches. Check coverage/keys, then counts, then
aggregates, then rounding-aware shares. Keep blanks, verified zeros and NA
separate. Distinguish allocated seats, filled seats, elected people and later
membership. Validate preference votes at documented party/sex/geographic scope;
aggregate agreement never establishes person identity or candidate completeness.
Classify differences as definition, aggregation, party grouping, geography,
counting stage, source version or unresolved; preserve both sources.

Apply this to 2002/2010/2014/2018/2022 after checking each year's geography,
re-elections and cells. For 2006, long party tables plus online mandate and
preference controls should support independent R validation. RD +4,089 remains
unexplained; KF detailed preference totals are corroborated but the separate
statistics-page difference has no established correction date/cause. Candidate
identity and preliminary-source limitations remain unchanged. No build started.
