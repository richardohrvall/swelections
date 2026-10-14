# 2002 completeness audit

Audit date: 14 October 2026. Implementation audited:
`7254bbb0c350996b1d3aeaaebf02c304f405ae2b`.
Reference: the clean, validated 13-asset `2002-clean-7254bbb0` prototype.
The original audit was followed by the scoped official-web adapter described below.
Original sources and Git history remain unchanged. Counts describe source observations,
not distinct physical people.

**Decision: 2002 is not complete in every requested dimension.** Final vote
partitions, combined invalid/cast totals and mandate coverage are complete.
The recovered RD district preference observations are now implemented; the
complete ballot-candidacy population and person linkage are not established.
This document supersedes earlier unqualified statements about 2002 completeness.

## Classification

- **COMPLETE:** the stated population and measure have been verified.
- **COMPLETE WITH SPECIFIED EXCEPTIONS:** only the enumerated exceptions remain.
- **INCOMPLETE:** known missing units, observations or fields remain.
- **NOT VERIFIED:** coverage has not been established; a missing count cannot
  honestly be asserted. The precise unverified population is stated below.

Complete geographic coverage does not prove complete separately identified
party/candidate populations. Complete vote partitions can contain residual
other-party votes. An unidentified person is not a missing vote observation.

## Authoritative completeness matrix

| Dimension | RD | RF | KF | Exact scope / exception |
|---|---|---|---|---|
| Final valid votes, combined invalid votes, ballots cast | COMPLETE | COMPLETE | COMPLETE | All returned national/municipal/constituency/district units. No missing values in these measures. Ordinary Orsa 2002 is used, not the 2003 rerun. |
| Final reported party partition, including residual other parties | COMPLETE | COMPLETE | COMPLETE | All votes accounted for. RD district supplementation for 1380/1381/1384 is reconciled to Valmyndigheten. This does not mean every party inside the residual is separately identified. |
| Corrected four-party RD constituency detail | COMPLETE WITH SPECIFIED EXCEPTIONS | Not applicable | Not applicable | 107/116 disclosed cells; nine unknown cells listed below. Seven county-party projections are consequently unknown. |
| Corrected four-party RD municipality/district detail | INCOMPLETE | Not applicable | Not applicable | Positive supplement amounts for Fria Listan, Nationaldemokraterna, Ny Demokrati and Populistpartiet have no complete lower-level allocation. Existing detail is retained; unresolved amounts remain in other parties. Exact positive allocation cells cannot be enumerated from the supplement. |
| Every smaller/local party individually identified | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED | Explicit source party rows are preserved. No complete independent universe of all parties inside residual other votes has been established. The number of undisclosed parties/rows is unknown, not zero. |
| Numeric party codes for every separately reported party | INCOMPLETE | INCOMPLETE | INCOMPLETE | Missing codes in 21,854 / 8,657 / 6,318 result rows, covering 23 / 33 / 174 distinct abbreviation/designation pairs. Party labels and vote values are retained. Exact rows are in the local audit exception CSVs. |
| Separate blank and other-invalid vote counts | INCOMPLETE | INCOMPLETE | INCOMPLETE | Both fields are unknown for every returned geographic unit. Only combined OG is established. Counts of district units: 6,266 / 6,233 / 6,372; municipal units: 290 / 289 / 290. No blank category is inferred to be zero. |
| Municipal eligible voters / turnout | COMPLETE | COMPLETE | COMPLETE | 290 / 289 / 290 municipal units. Kungsbacka XML electorate 48,603 remains distinct from complementary district-source electorate 48,602. |
| Ordinary-district eligible voters / turnout | COMPLETE | COMPLETE | COMPLETE | 5,976 / 5,937 / 5,976 ordinary districts. Collection units do not have a separate meaningful electorate/turnout. |
| Collection-district eligible voters / turnout | COMPLETE WITH SPECIFIED EXCEPTIONS | COMPLETE WITH SPECIFIED EXCEPTIONS | COMPLETE WITH SPECIFIED EXCEPTIONS | Electorate absent for 287 / 296 / 396 collection units. Three complementary RD postal units explicitly report electorate zero. Turnout is NA for all 290 / 296 / 396 collection units; not a zero turnout or a missing party result. |
| Allocated mandates | COMPLETE | COMPLETE | COMPLETE | 349 / 1,656 / 13,274, respectively. |
| Filled/elected positions | COMPLETE | COMPLETE | COMPLETE | 349 / 1,656 / 13,271 original final-election observations, independently checked against XML. |
| Unfilled positions | COMPLETE | COMPLETE | COMPLETE | 0 / 0 / 3. Habo 0305 FP: one; Olofstrom 1060 FP: two. They are not elected people. |
| Complete ballot/list candidacy register | INCOMPLETE | INCOMPLETE | INCOMPLETE | No complete 2002 ballot-candidacy register is recovered. `candidacies()` is unsupported. Missing candidacy counts cannot be enumerated without that register. |
| Result-list identifiers | COMPLETE | COMPLETE | COMPLETE | Identifiers retained for all 211 / 2,541 / 3,801 area-result list nodes inspected. These are result lists, not proof of complete printed-ballot coverage. |
| Full printed-list population, including lists/candidates without result records | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED | Unverified population: all printed candidacies absent from final result/appointment structures. Unknown list/candidate count. Result-list coverage must not be substituted for this population. |
| Reported district-list ballot positions | COMPLETE WITH SPECIFIED EXCEPTIONS | NOT VERIFIED | NOT VERIFIED | RD: all 276,214 original list rows have ballot positions; exactly 5,852 recovered HTML list rows lack KANDIDAT. RF/KF list views remain blocked by source inconsistencies and exhaustive position-attribute coverage has not been verified. Complete ballot-population coverage is assessed separately. |
| `candidates()` coverage of its documented area-result/appointment source observations | COMPLETE | COMPLETE | COMPLETE | 5,615 / 20,911 / 90,922 source keys. Not a complete nominated-person or ballot-candidacy population. |
| Total preference enrichment of source candidate keys | INCOMPLETE | INCOMPLETE | INCOMPLETE | 942 / 4,075 / 24,169 keys have NA totals. Positive totals: 4,673 / 16,836 / 66,753. Appointment/substitute slots are not joined to anonymous preference rows by names. No zero totals are fabricated. |
| Original elected/substitute source relations | COMPLETE | COMPLETE | COMPLETE | Elected 349 / 1,656 / 13,271; expanded substitute-relation rows 1,593 / 9,453 / 73,926. Relationship rows are not distinct substitute persons. |
| Preference counts on elected-slot keys | INCOMPLETE | INCOMPLETE | INCOMPLETE | All 349 / 1,656 / 13,271 elected-slot totals are NA because linkage to anonymous source preference rows is unestablished. The preference rows themselves are preserved separately. |
| Individually reported area preference rows, non-list view | COMPLETE | COMPLETE | COMPLETE | 4,673 / 16,836 / 66,753 source rows; totals 1,339,888 / 1,311,675 / 1,651,675. Completeness applies to these explicit source arrays, not unobserved candidacies or unidentified other-party aggregates. |
| Allocation of other-party preference aggregates to individual observations | INCOMPLETE | INCOMPLETE | INCOMPLETE | 41,523 / 13,542 / 8,675 preference votes remain aggregate-only in 29 / 52 / 108 positive area-other-party nodes; zero individually identified records in these nodes. Number of underlying candidacies is unknown. |
| Individually reported district preference rows in current public API | COMPLETE | COMPLETE | COMPLETE | Verified source arrays: RD 280,612 total-view rows after web recovery; RF/KF 335,253 / 418,951 explicit XML rows. RD source coverage is 6,266 units, including four inspected empty arrays. |
| Identified missing RD district preference observations | COMPLETE | Not applicable | Not applicable | All 5,852 recovered observations / 26,835 votes are implemented. No remaining known unit or reported row gap in the selected verified source population. |
| District-level web-vs-XML coverage outside the targeted three municipalities | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED | No all-district HTML/XML comparison has been performed. Outside the three, 6,162 RD units remain outside the exhaustive web audit (one of these has a separate successful XML/HTML control); all 6,233 RF and 6,372 KF units lack an exhaustive web audit. This is NOT a finding that their XML observations are missing. |
| Validated public by-list preference views | COMPLETE WITH SPECIFIED EXCEPTIONS | INCOMPLETE | INCOMPLETE | RD area/list and recovered district/list views work; HTML ballot positions remain NA. RF/KF area/list and district/list calls are rejected by source inconsistency checks. Four RF and sixteen KF area-list discrepancies are enumerated below; this count is not an exhaustive district-list discrepancy count. |
| Ordinary district geography | COMPLETE | COMPLETE | COMPLETE | 5,976 / 5,937 / 5,976. RF excludes Gotland because no RF election took place there. |
| Final collection/postal geography | COMPLETE | COMPLETE | COMPLETE | 290 / 296 / 396. Collection observations included once; RD/RF and KF XML nesting differs. |
| Municipal geography | COMPLETE | COMPLETE | COMPLETE | 290 / 289 / 290. No missing municipal party results. |
| Public divided municipal constituencies | COMPLETE | COMPLETE | COMPLETE | 185 / 182 / 185 units. Undivided technical `xx00` branches are not additional public constituencies: 105 / 107 / 105 undivided municipalities. Collection votes are not allocated to municipal constituencies. |
| Electoral constituency / regional geography | COMPLETE | COMPLETE | COMPLETE | RD 29 national constituencies; RF 100 regional constituencies in 20 regions; KF 185 divided municipal constituencies plus the undivided municipalities. |
| Complete preliminary result including collection reporting | INCOMPLETE | INCOMPLETE | INCOMPLETE | Zero verified preliminary collection units recovered. Full preliminary is unsupported; no final collection value substitutes for preliminary. This is a recovery limitation, not a claim that such results never existed. |
| National election-night district microdata | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED | Preserved national presentation snapshots are not a complete district-source census. Original Orsa KF night data are separately complete for five ordinary districts, with no collection district. Current Orsa night pages describe the 2003 rerun. |
| Physical-person identity across lists/areas/election types | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED | No verified stable person ID or complete linkage. Generated keys identify source observations. This does not remove observed votes or appointment records. |
| Original national/municipal final XML files | COMPLETE WITH SPECIFIED EXCEPTIONS | COMPLETE | COMPLETE | Three national files and 287/290 RD, 289/289 RF, 290/290 KF municipal files. Only original RD exports 1380/1381/1384 are missing. Their party results are supplied independently; this source-file exception is not a party-vote gap. |

## Exact RD supplement exceptions

Nine undisclosed constituency-party vote cells:

| Constituency code | Ny Demokrati | Populistpartiet |
|---|---|---|
| 0101 Stockholm municipality | NA | NA |
| 0102 Stockholm county | NA | NA |
| 0808 Kalmar | NA | NA |
| 1923 Vastmanland | NA | NA |
| 2529 Norrbotten | disclosed | NA |

Consequential county-party NAs: 01/NYD, 01/Pop, 08/NYD, 08/Pop, 19/NYD,
19/Pop and 25/Pop. National supplement totals are reported directly; no blank
cell is filled from national-minus-known-constituency arithmetic.

Four parties whose positive corrected counts cannot be fully distributed to
municipal/district observations: Fria Listan, Nationaldemokraterna, Ny Demokrati,
Populistpartiet. Complete partition totals include the unresolved allocations
inside residual other-party votes. This does not establish fully corrected
individually named party detail at every geographic level.

## Recovered district preference observations: a concrete implementation gap

Official live historical links were followed from each municipality through all
constituency/district pages, including its postal collection page. All 104 units
have result, `-totalt` and `-lista` pages: **312 responses**, **4,160,773 bytes**.
Each response is preserved with URL, retrieval UTC, bytes, MD5 and SHA256.
No existing archived source was overwritten.

| Municipality | Ordinary units | Collection unit | Positive rows in total view | Positive rows in list view | Preference votes in either view |
|---|---:|---|---:|---:|---:|
| Halmstad 1380 | 49 | R-1380-15 | 2,951 | 2,951 | 13,171 |
| Laholm 1381 | 15 | R-1381-15 | 697 | 697 | 3,195 |
| Kungsbacka 1384 | 37 | R-1384-15 | 2,204 | 2,204 | 10,469 |
| Total | 101 | 3 units | 5,852 | 5,852 | 26,835 |

The two views are alternative representations and must **not be added**.
All observed rows are positive; an absent row is not an observed zero.
Seven separately displayed parties are covered: M, C, FP, KD, S, V and MP.
No individually named other-party table was found in these 312 pages.
This verifies the completeness of the displayed seven-party candidate arrays,
not the entire ballot population or every candidate behind aggregate other votes.

**1,451 controls pass, zero differences:** 728 party-total controls and 723
numeric list-total controls. Blank list cells are excluded from numeric controls,
not coerced to zero. An additional available XML district, 13150501 in Hylte,
was checked in both HTML views: all 14 party/list arrays match XML vote counts
and source rank values exactly, in row order.

Crucially, HTML `Nr` equals XML `ORDNING` (preference-vote rank, with ties).
XML `KANDIDAT` is a separate source list position. For example, in the Hylte
control one source row has rank 2 and list position 16. HTML only displays
rank 2. It would be incorrect to put this number in a ballot-position field.
Names are redacted as `Personuppgift borttagen`; source-row keys preserve
observations without claiming person identity.

Current area-level RD observations already come from the complete national XML.
The recovery is an additional **district view**, not votes to add to national
or area candidate totals. The existing 274,760 district XML rows plus the
recovered 5,852 rows would produce **280,612 source-observation rows** in the
non-list district view. By-list XML has 276,214 rows plus the recovered 5,852,
for **282,066** rows; that is a different representation, not a second vote total.

Official entry points:
- https://historik.val.se/val/val_02/slutresultat/13R/1380/1380.html
- https://historik.val.se/val/val_02/slutresultat/13R/1381/1381.html
- https://historik.val.se/val/val_02/slutresultat/13R/1384/1384.html

Example candidate source:
`https://historik.val.se/val/val_02/slutresultat/13R/1380/13801901-totalt.html`.

## Exact area-list source discrepancies

Numbers are reported preference-vote total / sum of explicit candidate records.
Sources are unchanged. Do not weaken by-list validation to accept these arrays.

| Election | Area | Party | List | Reported | Observed |
|---|---|---|---|---:|---:|
| RF | 0107 | C | 0004-02927 | 680 | 677 |
| RF | 1901 | MP | 0055-01562 | 648 | 638 |
| RF | 1402 | KD | 0068-03063 | 6,851 | 6,821 |
| RF | 1401 | FP | 0003-03341 | 4 | 3 |
| KF | 036000 | S | 0002-02326 | 1,422 | 1,304 |
| KF | 038004 | FP | 0003-01965 | 1,378 | 1,361 |
| KF | 086000 | MP | 0055-04357 | 19 | 12 |
| KF | 086000 | MP | 0055-04362 | 2 | 1 |
| KF | 086000 | MSVO | 0044-03406 | 170 | 141 |
| KF | 086100 | S | 0002-00929 | 861 | 751 |
| KF | 086200 | MP | 0055-01565 | 48 | 44 |
| KF | 088001 | SPI | 0107-03426 | 102 | 97 |
| KF | 088200 | FP | 0003-03234 | 259 | 244 |
| KF | 088400 | S | 0002-01113 | 994 | 992 |
| KF | 196100 | SD | 0110-04358 | 1 | 0 |
| KF | 198002 | FP | 0003-00161 | 1,382 | 1,359 |
| KF | 198002 | S | 0002-01103 | 661 | 654 |
| KF | 248001 | FP | 0003-01259 | 1,400 | 1,346 |
| KF | 248002 | FP | 0003-01272 | 125 | 124 |
| KF | 248100 | S | 0002-02446 | 1,554 | 1,490 |

Area-list deficits sum to 44 RF / 458 KF. These do not explain or repair all
area-vs-direct-candidate differences: RF list-identified sum additionally exceeds
its direct area candidate sum by 263. Separate XML-minus-SCB aggregate findings
remain +547 RD / +28 RF; KF agrees. These source consistency issues are not
missing municipal party results or mandate gaps.

## Exact local audit artefacts and verification scope

Ignored local directory: `.local-data/2002-completeness-audit/`.
- `web-provenance.json`: 312 distinct URLs, sizes and checksums;
  SHA256 `f670943252d7fb6160f150c7e2d17f8ab3f0a001afd644a651678ef31ef42dba`.
- `web-person-observations.csv`: both representations of every recovered row.
- `web-preference-controls.csv`: all 1,451 controls, zero differences.
- `original-xml-district-coverage.csv`: every district in all 866 municipal XMLs.
- `area-list-coverage.csv`, `area-list-discrepancies.csv`,
  `other-party-preference-coverage.csv`: complete area/list controls.
- `rd/rf/kf-district-denominator-exceptions.csv`: exact affected collection units.
- `rd/rf/kf-party-code-exceptions.csv`: every retained result row without a code.

Existing XML district rows: RD 274,760, RF 335,253, KF 418,951. Six units have no
individual preference rows in their XML: RD R-0512-05, R-1492-18, R-1498-20,
R-1762-21; RF L-0512-04, L-0560-04. This is an empty source array, not evidence
of missing individuals or permission to fabricate zero-vote candidate rows.

No full package test rerun is claimed for this read-only audit: no production
code or canonical assets changed. Previous clean-commit validation remains
valid for the implementation audited. New direct XML/HTML/census controls above
are independently executed, not inferred from the prior validation.

## Implemented official-web recovery (14 October 2026)

This section supersedes the preceding audit-only RD district preference gap.
The working-tree adapter `R/preference_web_2002.R` uses hash-verified official
Valmyndigheten HTML; SCB/SND are not preference-vote sources.

| RD district measure | Before recovery | Added | After recovery |
|---|---:|---:|---:|
| Ordinary geographic units with source arrays | 5,875 | 101 | 5,976 |
| Collection/postal units with source arrays | 287 | 3 | 290 |
| All relevant geographic units | 6,162 | 104 | 6,266 |
| Individually reported total-view observations | 274,760 | 5,852 | 280,612 |
| Individually reported list-view observations | 276,214 | 5,852 | 282,066 |
| Preference votes in either separate view | 1,313,053 | 26,835 | 1,339,888 |

**Reported RD district preference observations: COMPLETE for the verified source
population of 6,266 units. No known missing geographic unit or individually
reported source observation remains in that population.** Four collection units
have empty individual arrays: R-0512-05, R-1492-18, R-1498-20 and R-1762-21.
They are present and inspected, not missing sources or fabricated zero candidates.
Thus 6,262 units have positive individual observations; all 6,266 have source
coverage. Complete source-observation coverage is not a claim of complete
candidacy population or verified physical-person linkage.

All 312 official pages are registered under the local 2002 raw archive with
unchanged response bytes and a pinned provenance manifest. Every response's
URL, retrieval UTC, bytes, MD5 and SHA256 is verified. Registered manifest SHA256:
`9cfdc50260198a04d325131090b2e2512df72cc6fe92b724768f43057b7a0801`.

The recovered rows are anonymous source-row observations keyed by source URL,
table and row. Rank `Nr` is not substituted for ballot order, candidate number
or a person ID. Actual ballot order is NA on the 5,852 new list-view rows because
HTML does not expose XML KANDIDAT. The seven individually displayed parties are
M/C/FP/KD/S/V/MP. No candidate row is fabricated for other-party aggregates or
for unobserved zero votes. Collection pages retain their municipality-level
role; their public district keys are 13809800, 13819800 and 13849800.

Independent controls establish exact agreement in both separate representations:
- 1,451 numeric party/list preference controls; no differences;
- 203 constituency-party identified-preference totals per representation
  (406 checks); no differences;
- national individually reported preference total 1,339,888 in each view,
  exactly matching the national XML area arrays.

These totals exclude 41,523 aggregate-only RD other-party preference votes.
Those unidentified observations remain **INCOMPLETE at individual level**, with
an unknown number of underlying candidacies. XML-minus-SCB RD aggregate +547
remains unchanged. Candidacy-population coverage and physical-person identity
remain separate INCOMPLETE/NOT VERIFIED dimensions as specified above. The
original three municipal XML files remain absent; their substantive district
preference observations are now recovered from official HTML.

This does not claim that every historical web representation outside the three
municipalities has been compared against XML. Such an exhaustive additional
cross-source presentation comparison remains NOT VERIFIED; the complete verified
population above is the selected official final XML arrays plus the recovered
missing-municipality HTML arrays.

### Final validation outcome

The completed 14-asset prototype is in
`.local-data/canonical-build/2002-web-recovery-20261014/`, schema 2, unpublished
`data-v0.0.0`, with `build_tree_dirty = true`. All thirteen preceding assets are
byte-identical. The new RD district asset contains both separately selected
views, 562,678 stored rows in total; users must not add the two representations.

Independent raw/canonical, all recovered controls, sixteen language/detail/source
projection checks, eight actual language-wrapper checks and 152 unchanged public
outputs pass. Full suite: 3,409 PASS, ten explicit skips, no failures/warnings.
Final package check: zero errors/warnings/notes. Source integrity and diff checks
pass. No source/canonical objects are tracked; no commit/push has been made.

The four empty collection arrays are independently corroborated by twelve
additional official presentation pages and 28 explicit zero-list preference
counts. Overall/party-level blank fields remain blank; no individual zero rows
are invented. All 276,214 original district-list rows have reported ballot order;
exactly 5,852 recovered list-view rows lack it. Names and person linkage are not
inferred from rank or row order.

## Other-party, small-party and candidacy follow-up (14 October 2026)

This investigation changes the interpretation of the exceptions, not production
values. No additional individually identified preference observation was recovered.
The 41,523 RD votes remain **aggregate-only in the inspected official sources**;
this is not proof that the original administration lacked individual records or
that an inaccessible archive/restricted register could never supply them.

### Separate completeness dimensions

| Dimension | Status | Verified population / exact missing information |
|---|---|---|
| Reported RD district preference observations | COMPLETE | All 6,266 selected-source units: 5,976 ordinary and 290 collection/postal. 280,612 total-view rows, 1,339,888 individually reported votes. Four covered empty arrays remain empty. No known missing reported row/unit. Unknown ballot positions and person linkage do not change this status. |
| Individually identified small-party area preference observations | COMPLETE for explicit direct source arrays | RD: Norrbottenspartiet, 34 rows / 6,258 votes; RF: 17 source party labels, 2,064 rows / 71,096 votes; KF: 157 labels, 5,187 rows / 88,466 votes. These are included in existing area outputs; they are not additional votes to add to district/area totals. Completeness does not extend to individuals behind the residual other-party category. |
| Attribution of aggregate-only other-party preference votes | INCOMPLETE | RD 41,523 in all 29 constituencies; RF 13,542 in 52 positive area nodes; KF 8,675 in 108. Party, candidate/list and row allocation are absent from these nodes. The number of underlying individual observations is unknown. Zero additional attributable votes were recovered. |
| Recoverability of that attribution beyond inspected sources | NOT VERIFIED | No verified open candidate/party crosswalk for the residual totals was recovered. Preserved archive metadata includes rate-limited queries and replay wrappers, not verified candidate content. Those failures do not establish non-existence. |
| Full ballot-candidacy population | INCOMPLETE | Zero complete ballot-register datasets recovered. Missing records are all candidacies not recoverable as ballot records from the selected sources, including candidacies without a result/appointment observation. Exact missing count and geography cannot be computed without the register; it is not the count of anonymous preference rows or unknown ballot positions. |
| Physical-person linkage | NOT VERIFIED | No verified stable public person ID/cross-list or cross-election linkage. Generated result/appointment keys identify source observations. No reported vote or candidacy is removed on this ground. |

### Evidence for the other-party classification

An independent census inspected all **869 selected final XML files**. Across
**22,229 other-party GILTIGA nodes** at the various nested geographic levels,
there are **zero descendant PERSONVAL records** and no nested attributes that
allocate PERSONKRYSS to individually named smaller parties. These nested nodes
must not be summed across levels; the 41,523 is the sum of the 29 RD area nodes.
Their VARAV_ÖVRIGA children disclose **ordinary party votes**, not candidate
preference votes. Ordinary-vote party shares cannot allocate preference votes.

All **29 RD constituency main pages and their total/list candidate views** were
retrieved sequentially: 87 official responses, individually recorded with URL,
UTC retrieval time, bytes, MD5 and SHA256 in the ignored local audit directory.
The candidate views show M/C/FP/KD/S/V/MP and, in Norrbotten 2529, NBP. The main
pages disclose other-party ordinary-vote detail but link no corresponding
individual other-party preference table. NBP's 6,258 identified votes are already
in the 1,339,888 and are **not** part of the 41,523.

The previously preserved 312 district pages for Halmstad/Laholm/Kungsbacka and
the municipal/district XML census likewise supply no candidate attribution for
these residuals. No additional archived candidate object was found in the
preserved source manifests. Earlier Wayback 429/503 responses and Arquivo replay
wrappers are access/recovery limitations, not negative evidence about an
unseen historical register. No further broad archive search is claimed here.

Official examples:
- [RD national presentation](https://historik.val.se/val/val_02/slutresultat/00R/00.html)
- [Halland candidate totals](https://historik.val.se/val/val_02/slutresultat/13R/1315KR-totalt.html)
- [Norrbotten candidate totals, including NBP](https://historik.val.se/val/val_02/slutresultat/25R/2529KR-totalt.html)

All six local SCB DTA files were assessed. The three large district-party files
contain ordinary antrost counts and party/geography labels, not candidate
preference counts. The three smaller files are SD ballot/district/mandate
indicators, not a preference or nomination register (despite val02_nom's name).
All three SND ZIP member inventories and Swedish SAV schemas were checked:
RD 6,266 units / 23 variables; RF 6,233 / 27; KF 6,372 / 25. Their paired
language/spreadsheet distributions do not introduce a candidate/preference
measure; the SAVs contain ordinary votes/turnout and residual other-party votes.
They cannot identify individuals behind the preference aggregates.

SCB's preserved RD publication reports preference tables for parties receiving
mandates and a selected candidate table (elected or above the stated threshold),
not an exhaustive other-party candidacy register. No NBP/SD/SPI/ND/NYD/Skånepartiet
candidate block was found in its candidate table. Published aggregate statistics
and the preserved Statistics Database metadata do not provide a candidate-level
allocation of the residual. The official four-party supplement concerns ordinary
votes only; it cannot supply preference-vote attribution.

### Precisely identified smaller-party ordinary results

[SMALL_PARTY_COVERAGE_2002.csv](SMALL_PARTY_COVERAGE_2002.csv) lists **every
non-major source party label** encountered in the selected final XML:
47 RD, 48 RF and 196 KF labels, excluding residual ÖVR. It gives the designation,
source geographic node types and observed unit counts for each label, plus the
levels containing direct individual preference records. Labels are not asserted
to be globally unique organisations. This is documentary coverage metadata, not
a replacement election dataset or new package lookup.

The CSV describes **unmodified XML coverage**. Source node names describe source
nesting (including generic KRETS_RIKSDAG branches in KF); they must not be read
as a change to the harmonised public geographic contract. Unit counts are
observed source coverage, not evidence that omitted units have zero votes.
The three complementary RD municipal district sources and the corrected
four-party supplement are separately documented in IMPLEMENTATION_2002.md and
SUPPLEMENT_2002.md; the CSV does not override their provenance or corrections.

Every listed RD small-party label has municipal ordinary-vote detail somewhere;
45 also occur in district detail. Crisis (0365) and DUST-ONLINE (0367) have no
separately identified district row in the selected XML. No label in the XML
inventory exists solely as a national/constituency observation. This does not
supply the missing lower-level **corrected allocations** for Fria Listan, ND,
NYD or Populistpartiet. Those four parties have additional official national and
constituency disclosure, as documented in SUPPLEMENT_2002.md: 107/116 cells,
nine expressly undisclosed cells and seven consequential county-party NAs.
Their positive corrected amounts lack a complete municipal/district allocation.

The remaining national ordinary-vote residual after the supplement is **3,403**.
Its unreported party membership cannot be enumerated from the residual itself.
Do not confuse those 3,403 ordinary votes with 41,523 preference votes, or infer
that all residual preference votes belong to the unknown ordinary-vote residual:
the source aggregates have different disclosure scopes.

Thus final **reported vote partitions are COMPLETE**; every-party attribution
is **NOT VERIFIED**, with an unknown number of residual parties/rows. Corrected
four-party constituency detail is COMPLETE WITH THE NINE SPECIFIED EXCEPTIONS;
its fully corrected lower-level attribution is INCOMPLETE. Only the supplement's
nine cells are established as explicitly undisclosed; missing detail elsewhere
must not be called deliberately unpublished solely because it was not recovered.

### The candidacy register existed; it is not recovered

[SCBDOK ME0104 2002](https://www.scb.se/contentassets/0306ea5d06f34dfab00ef2ca653a5284/me0104_do_2002.pdf),
internal footer 9 January 2007, documents Valmyndigheten-supplied nomination
files with person number, list number, real list position and preference counts:

| Election | Documented nomination-file rows | Scope |
|---|---:|---|
| RD | 14,028 | Multiple rows per person; distinct from the documented 5,239-row person file |
| RF | 48,279 | Multiple rows per person |
| KF | 83,451 | Before Orsa rerun; 83,466 after rerun is a different snapshot/occasion scope |

These are metadata counts, **not recovered records**, and cannot be subtracted
from the package's 5,615/20,911/90,922 result/appointment source keys to calculate
missing candidacies. The latter are a different observation unit and population.
The 211/2,541/3,801 area-result list nodes are likewise not a full ballot register.
The known full-register row count available to the build is zero; the true
missing-register count relative to recovered partial ballot information remains
unquantified. Positive preference rows and elected/substitute relations are
retained independently; unavailable nomination files do not erase them.

The next useful action is a specific Valmyndigheten/SCB request for the original
2002 nomination/list records and the attribution underlying the 29 RD residual
PERSONKRYSS totals. No redistribution/access approval or recoverability is assumed.
There is no evidence-supported production allocation to implement from this
investigation. Preserve the current values and separate completeness statuses.

Local independent audit artefacts (ignored):
`.local-data/2002-small-party-review/other-xml-census.csv`,
`web-provenance.json`, `web-candidate-table-coverage.csv`,
`identified-area-small-party-preferences.csv`, and `scb-register.txt`.

### Exact RD aggregate-only area values

These 29 non-overlapping source areas sum to 41,523. No candidate/list allocation is supplied by these nodes.

| Source constituency code | Aggregate-only preference votes |
|---|---:|
| 0101 | 2,245 |
| 0102 | 3,772 |
| 0303 | 1,160 |
| 0404 | 714 |
| 0505 | 1,430 |
| 0606 | 1,321 |
| 0707 | 773 |
| 0808 | 668 |
| 0909 | 133 |
| 1010 | 1,154 |
| 1211 | 3,476 |
| 1212 | 2,807 |
| 1213 | 3,208 |
| 1214 | 2,035 |
| 1315 | 1,875 |
| 1416 | 2,148 |
| 1417 | 1,588 |
| 1418 | 1,040 |
| 1419 | 732 |
| 1420 | 899 |
| 1721 | 1,329 |
| 1822 | 1,417 |
| 1923 | 961 |
| 2024 | 1,563 |
| 2125 | 974 |
| 2226 | 858 |
| 2327 | 433 |
| 2428 | 547 |
| 2529 | 263 |

## Final status of the approved implementation

The separate classifications in the follow-up above remain authoritative.
Reported RD district preference observations are COMPLETE for the verified
6,266-unit source population. The original 5,852-row recovery gap is closed;
there is no known missing reported individual preference observation in it.
Unknown list positions, aggregate-only other-party values, unrecovered full
ballot-register coverage and unverified physical-person linkage are different
questions and do not weaken that finding. The missing three original municipal
XML files are source-file exceptions, not missing final party results or reported
RD district preference observations. Complete preliminary collection reporting
remains unrecovered and unsupported. No additional recovery or allocation is
undertaken as part of finalisation.

The preceding dirty-build validation describes the historical approval build.
The final clean-commit prototype uses the same fourteen assets, with fresh build
provenance rather than altered election values. See VALIDATION_2002.md for the
required clean-rebuild checks; the exact build SHA and clean/dirty flag are recorded
in the local manifest. No prototype or raw source is distributed through Git.
