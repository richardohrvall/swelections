# Final ordinary-election result reconciliation: 2002

This focused review concerns ordinary final election results, not candidate identity
or preference-vote linkage. No production code, raw snapshot, canonical asset,
source selection or public schema was changed. The election occasion is
15 September 2002. Orsa's 16 March 2003 re-election is a separate occasion.

## Evidence and controls

The selected 869 hash-verified XML exports were compared with all three local
SCB district-party DTA files, the three SND Swedish SAV distributions, and newly
retrieved official SCB result, mandate and eligible-voter tables for 2002.
The independent diagnostics do not call production result normalisation.
They read XML fields and the external controls separately.

- All 9,279 separately reported municipality-party XML values were matched using
  official numeric codes, list prefixes, party-registry names or exact published
  abbreviations. None remain unmapped. The only nine differences are Orsa's
  separately identified parties, explained by the re-election.
- 12,511 current SCB/primary-XML controls cover national, RD constituency,
  RF regional and municipality vote/mandate values. All are verifiable. The 32
  differences are confined to Orsa and its corresponding national KF totals.
- Direct eligible-voter controls cover all 290 RD/KF and 289 RF municipalities,
  all 29 RD constituencies and all 20 RF regions. SCB's later register explains
  the small denominator differences documented below.
- The earlier 9,529 independent XML geographic controls remain valid. No new
  evidence contradicts those valid/invalid/cast/party aggregates.

SCB uses modern code 0331 for historical Heby, whereas the 2002 XML uses 1917.
This is an explicit geographic comparison crosswalk, supported by SCB's note
about Heby's transfer to Uppsala in 2007; no package geography was changed.
SCB's Dalarna regional control is 20LG, not 20L. Neither mismatch is missing
2002 votes or a source-data error.

Newly preserved evidence is in the local, untracked
`rkl/2002/final-reconciliation-20261012/` collection. `manifest.json` records
exact request bodies, original/effective URLs, retrieval UTC, sizes, MD5 and
SHA256. Detailed derived control CSVs are alongside it, not package data.

Official SCB API base:
`https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0104/`

| Purpose | Endpoint |
|---|---|
| RD / RF / KF vote counts | ME0104C/ME0104T3; ME0104B/ME0104T2; ME0104A/ME0104T1 |
| RD / RF / KF mandates | ME0104C/Riksdagsmandat; ME0104B/Ltmandat; ME0104A/Kfmandat |
| RD / RF / KF eligible voters | ME0104C/RiksdagsvalRostb7698; ME0104B/Landstingsmed; ME0104A/Kommunmed |

Publications were located through [SCB's official older-report catalogue](https://www.scb.se/hitta-statistik/sok/gammalt?Exact=true&Query=ME0104&Tab=older).
The preserved full [RD publication](https://share.scb.se/ov9993/data/publikationer/statistik/me/me0104/2003m00/me01sa0301.pdf)
and [RF publication](https://share.scb.se/ov9993/data/publikationer/statistik/me/me0104/2003m00/me02sa0301.pdf)
provide the constituency/region tables and the explanation of rounding and
register versions (printed page 5). The three catalogue-linked supplements
concern district-name changes, not corrections to vote counts.
The analogous guessed full KF publication URL returned 404; it was not treated
as inspected evidence. Bounded official-catalogue checks did not recover that
full volume. Ordinary KF is independently controlled by the recovered original
XML and SND, and current SCB explicitly documents its Orsa re-election scope.

## Established ordinary final totals

| Election | Valid | Combined invalid | Cast | XML eligible | SCB ordinary eligible | Allocated mandates |
|---|---:|---:|---:|---:|---:|---:|
| RD | 5,303,212 | 82,218 | 5,385,430 | 6,722,152 | 6,722,163 | 349 |
| RF | 5,227,376 | 116,585 | 5,343,961 | 6,897,911 | 6,897,918 | 1,656 |
| KF | 5,312,977 | 96,878 | 5,409,855 | 6,942,663 | 6,942,670 | 13,274 |

Valid plus combined-invalid equals cast for each election. XML parent-party
partitions equal valid votes. Smaller-party `VARAV_ÖVRIGA` children subdivide
other-party votes; adding them on top of their parent would double count.
SCB separately displays SD and combines other small parties differently; those
category choices are not missing votes.

KF's 13,274 allocated mandates include three unfilled positions: one in Håbo
and two in Olofström. The 13,271 elected-person observations are therefore not
an alternative mandate total. RD and RF have no corresponding unfilled slots.

## Orsa: completely explained election-occasion difference

| Field | Ordinary 2002 | Re-election 2003 | 2003 minus 2002 |
|---|---:|---:|---:|
| Valid | 4,009 | 4,303 | +294 |
| Combined invalid | 61 | 13 | -48 |
| Cast | 4,070 | 4,316 | +246 |
| Eligible | 5,389 | 5,413 | +24 |
| Allocated mandates | 31 | 31 | 0 |

| Party | Ordinary votes | Re-election votes | Ordinary mandates | Re-election mandates |
|---|---:|---:|---:|---:|
| M | 377 | 280 | 3 | 2 |
| C | 898 | 1,034 | 7 | 8 |
| FP | 237 | 170 | 2 | 1 |
| KD | 223 | 289 | 2 | 2 |
| S | 1,588 | 1,619 | 13 | 12 |
| V | 277 | 260 | 2 | 2 |
| MP | 189 | 199 | 1 | 1 |
| SPI | 88 | 274 | 0 | 2 |
| SD | 121 | 135 | 1 | 1 |
| Remaining smaller-party category (ND + residual other) | 11 | 43 | 0 | 0 |

The re-election separately reports ND 43 and residual other 0; ordinary ND is not separately reported. The combined row is comparable, but ordinary ND must not be inferred as zero.

The same differences explain the national KF changes. Current SCB/local KF
DTA totals are 5,313,271 valid / 96,830 invalid / 5,410,101 cast because they
include the re-election. The package's selected ordinary XML is correct.
The current SCB `Kommunmed` eligible-voter table explicitly retains the ordinary
2002 register, even though the current result/mandate tables use the re-election.
Thus different SCB tables must not be blended as if they shared one occasion.

Original Orsa XML MD5: `3249b5428225a4e6d0c77dbcd1d17340`.
See SOURCE_INVENTORY_2002.md section 13 for the archived original/re-election
URLs, capture dates, hashes and original elected/substitute evidence.

## Electoral-roll and turnout differences: explained, not missing ballots

SCB's publication and SCBDOK explicitly say it used a later electoral-roll
version, from election day at 20:00. XML versus SCB national denominators differ
by +11 RD / +7 RF / +7 KF (SCB minus XML). These are register-version differences,
not differences in valid, invalid or cast ballots.

The earlier claim of a 13-person SND shortfall is superseded: SND's 6,722,163
exactly equals the definitive RD publication and the current SCB register table.
The earlier quoted 6,722,176 is not the denominator in the selected final XML
or the definitive SCB control; it must not justify distributing 13 people.
SND's three missing `tot` cells are postal summary rows (01, 11 and 16), not
three identified missing voter populations. Their votes are already included.

SCB rounds percentages; Valmyndigheten truncates them. RF's displayed 77.4%
versus SCB's 77.5% is explained by this rule. The package calculates exact
turnout from cast/eligible counts, preserving the XML denominator; it does not
copy either display percentage. Register differences therefore affect exact
turnout slightly, but are not a parser or counting-stage error.

Municipalities with differing eligible counts: 28 RD / 27 RF / 27 KF.
All exact pairs follow. Zero means the two sources agree, not missing evidence.



| Municipality | RD XML -> SCB | RF XML -> SCB | KF XML -> SCB |
|---|---:|---:|---:|
| 0114 Upplands-Väsby | 26,233 -> 26,234 | 28,569 -> 28,570 | 28,569 -> 28,570 |
| 0138 Tyresö | 27,184 -> 27,183 | 28,777 -> 28,776 | 28,777 -> 28,776 |
| 0180 Stockholm | 573,936 -> 573,940 | 607,446 -> 607,451 | 607,446 -> 607,451 |
| 0182 Nacka | 53,779 -> 53,780 | 56,925 -> 56,925 | 56,925 -> 56,925 |
| 0183 Sundbyberg | 25,888 -> 25,887 | 27,422 -> 27,421 | 27,422 -> 27,421 |
| 0184 Solna | 44,931 -> 44,930 | 47,796 -> 47,795 | 47,796 -> 47,795 |
| 0482 Flen | 12,253 -> 12,252 | 12,686 -> 12,685 | 12,686 -> 12,685 |
| 0486 Strängnäs | 22,231 -> 22,232 | 22,761 -> 22,762 | 22,761 -> 22,762 |
| 0581 Norrköping | 93,034 -> 93,034 | 96,170 -> 96,171 | 96,170 -> 96,171 |
| 0781 Ljungby | 20,576 -> 20,577 | 21,050 -> 21,051 | 21,050 -> 21,051 |
| 1080 Karlskrona | 47,127 -> 47,126 | 47,707 -> 47,706 | 47,707 -> 47,706 |
| 1082 Karlshamn | 24,259 -> 24,260 | 24,510 -> 24,511 | 24,510 -> 24,511 |
| 1083 Sölvesborg | 12,760 -> 12,761 | 12,992 -> 12,992 | 12,992 -> 12,992 |
| 1261 Kävlinge | 18,540 -> 18,539 | 18,865 -> 18,864 | 18,865 -> 18,864 |
| 1277 Åstorp | 9,422 -> 9,423 | 9,818 -> 9,819 | 9,818 -> 9,819 |
| 1280 Malmö | 196,338 -> 196,339 | 208,536 -> 208,537 | 208,536 -> 208,537 |
| 1281 Lund | 76,067 -> 76,066 | 78,475 -> 78,474 | 78,475 -> 78,474 |
| 1384 Kungsbacka | 48,603 -> 48,602 | 48,931 -> 48,930 | 48,931 -> 48,930 |
| 1480 Göteborg | 357,876 -> 357,879 | 375,849 -> 375,848 | 375,849 -> 375,848 |
| 1481 Mölndal | 42,007 -> 42,008 | 43,240 -> 43,241 | 43,240 -> 43,241 |
| 1766 Sunne | 10,503 -> 10,504 | 10,594 -> 10,595 | 10,594 -> 10,595 |
| 1917 Heby | 10,189 -> 10,190 | 10,358 -> 10,359 | 10,358 -> 10,359 |
| 2021 Vansbro | 5,663 -> 5,662 | 5,717 -> 5,716 | 5,717 -> 5,716 |
| 2409 Robertsfors | 5,446 -> 5,447 | 5,515 -> 5,516 | 5,515 -> 5,516 |
| 2421 Storuman | 5,329 -> 5,331 | 5,374 -> 5,376 | 5,374 -> 5,376 |
| 2460 Vännäs | 6,317 -> 6,315 | 6,380 -> 6,378 | 6,380 -> 6,378 |
| 2462 Vilhelmina | 5,963 -> 5,962 | 5,977 -> 5,976 | 5,977 -> 5,976 |
| 2463 Åsele | 2,798 -> 2,798 | 2,818 -> 2,819 | 2,818 -> 2,819 |
| 2480 Umeå | 79,381 -> 79,382 | 81,456 -> 81,456 | 81,456 -> 81,456 |
| 2481 Lycksele | 9,901 -> 9,902 | 9,990 -> 9,991 | 9,990 -> 9,991 |

### Constituency/region denominator differences

| Election | Geography | XML | SCB | SCB minus XML |
|---|---|---:|---:|---:|
| RD | 1010 Blekinge län | 116,776 | 116,777 | 1 |
| RD | 2024 Dalarnas län | 213,691 | 213,690 | -1 |
| RD | 1315 Hallands län | 210,128 | 210,127 | -1 |
| RD | 0707 Kronobergs län | 135,126 | 135,127 | 1 |
| RD | 1211 Malmö kommun | 196,338 | 196,339 | 1 |
| RD | 1214 Skåne läns norra och östra | 222,738 | 222,739 | 1 |
| RD | 1213 Skåne läns södra | 243,795 | 243,793 | -2 |
| RD | 0101 Stockholms kommun | 573,936 | 573,940 | 4 |
| RD | 0102 Stockholms län | 770,595 | 770,594 | -1 |
| RD | 1721 Värmlands län | 210,795 | 210,796 | 1 |
| RD | 2428 Västerbottens län | 195,050 | 195,052 | 2 |
| RD | 1923 Västmanlands län | 193,665 | 193,666 | 1 |
| RD | 1416 Göteborgs kommun | 357,876 | 357,879 | 3 |
| RD | 1417 Västra Götalands läns västra | 244,764 | 244,765 | 1 |
| RF | 20 Dalarnas län | 216,754 | 216,753 | -1 |
| RF | 13 Hallands län | 213,245 | 213,244 | -1 |
| RF | 07 Kronobergs län | 137,816 | 137,817 | 1 |
| RF | 01 Stockholms län | 1,427,328 | 1,427,331 | 3 |
| RF | 17 Värmlands län | 215,855 | 215,856 | 1 |
| RF | 24 Västerbottens län | 197,991 | 197,993 | 2 |
| RF | 19 Västmanlands län | 201,073 | 201,074 | 1 |
| RF | 05 Östergötlands län | 321,501 | 321,502 | 1 |

## Four smaller RD parties: reporting correction established

The local official `valresultat/tillagg_ovriga.pdf` explicitly attributes incomplete
separate reporting to technical reasons and provides constituency figures.
Its PDF title is `Övriga partier, särred.xls`; creation/modification metadata is
13 December 2002 at 12:26:58 (Western European standard time). This establishes
file-generation metadata, not a independently verified publication date or
original download URL. MD5 is `b0094d49a33e919a9cf2d865f72fe78e`;
SHA256 is `83fa892e978ca3adac82189e8b685d262ac5e443937b9bad666ce70e56141dff`.

| Party | Selected XML / local SCB reported total | Supplement reported sum | Difference |
|---|---:|---:|---:|
| Fria Listan | 274 | 502 | +228 |
| Nationaldemokraterna | 4,122 | 9,248 | +5,126 |
| Ny Demokrati | 106 | 2,207 | +2,101 |
| Populistpartiet | 8 | 11 | +3 |

These are reallocations within the existing valid/other-party total, not new
ballots. The supplement is the explicit authority for its known corrected
party figures; the earlier XML/SCB agreement does not override it. Neither
current SCB's broad category tables nor its RD publication's broad party
breakdown supplies missing detail for these four parties.

All 29 supplement rows have been checked against the official constituency
index. There are 107 explicit values and nine missing values. Fria Listan and
ND have values in all 29 constituencies. Ny Demokrati has four blank cells;
Populistpartiet has five. The supplement's four sum rows exactly equal the sums
of their reported cells. For the latter two parties, those reported sums must
not be described as proof that all undisclosed votes have been individually
assigned to the party.

| Constituency | Blank Ny Demokrati | Blank Populistpartiet |
|---|---|---|
| 0808 Kalmar | Yes | Yes |
| 2529 Norrbotten | No | Yes |
| 0101 Stockholm municipality | Yes | Yes |
| 0102 Stockholm county | Yes | Yes |
| 1923 Västmanland | Yes | Yes |

The old XML has only seven of the 116 constituent party cells separately
reported. Their missing cells cannot be assumed to mean zero. One explicit
old cell is contradicted: Gävleborg Populistpartiet is 8 in XML versus an
explicit 0 in the supplement. Thus the correction is not a uniform positive
increment to old reported cells.

The supplement expressly says blank means the county administrative board did
not report a separate count, zero means zero votes, and no further other-party
detail will be published. It contains no municipality/district allocations.
Accordingly the known 107 constituency values and official reported national
sums are reconciled, while the nine undisclosed cells and lower-level
allocations remain source-limited. Nothing may be distributed proportionally.

**Package impact:** the current implementation still exposes the earlier
separate party figures. This is the remaining ordinary-result issue affecting
published party detail (and the corresponding residual other-party category),
not valid/invalid/cast totals or mandates. A scoped, provenance-labelled
supplement integration is needed before claiming corrected detail at national
and constituency level. No such production or asset change was made in this
reconciliation. Lower-level views must retain documented incomplete detail.

## Invalid versus blank: verified category limitation

XML `OGILTIGA/@TEXT="OG"` combines invalid ballots. All three local SCB DTA
files have code 9999 labelled `Ogiltiga`; none has a separate 9998 blank category.
Current SCB result tables also expose combined `OGILTIGA`, not separate blank
ballots for 2002. The RD SND `blank_kol` is labelled `Tom kolumn` (empty column),
not blank votes; its 39 zero entries must not be interpreted as ballot counts.
RF's `blank_kol` is labelled combined invalid votes but is entirely missing;
KF has no separate blank field. The definitive RD/RF publication tables likewise
use combined invalid (or cast minus valid), not a separate blank decomposition.

The official combined totals are reconciled. A separate blank/other-invalid
split remains unavailable in the inspected evidence, not a numerical
contradiction. Typed missing values in the package are correct. Zero cannot be
inferred. The full KF publication was not recovered and cannot be cited as
proof about a split it might or might not expose; this limitation is explicit.

## Coverage gaps, separate from contradictory results

The three missing RD municipality XML exports are Halmstad 1380, Laholm 1381
and Kungsbacka 1384. Their municipality totals are present in the national XML
and independently verified against SCB. No ordinary municipality/national
ballots are missing. Complete RD district/source-detail views remain unavailable
because the selected XML collection is incomplete at that level. The SCB DTA
and published RD district tables contain complementary district data, but
substituting them would require a separately designed source adapter/geographic
scope decision; this review did not alter the raw-source contract or assets.

## Conclusions and implementation status

| Finding | Classification | Effect on actual ordinary final output |
|---|---|---|
| Orsa and national KF differences | Explained separate election occasions | Original election correctly exposed |
| Major/local party, valid/combined-invalid/cast and mandate controls | Reconciled | No numerical correction needed |
| Eligible-voter differences | Documented electoral-roll version difference | XML denominator intentionally retained; exact turnout differs slightly from SCB |
| Apparent SND 13-person shortfall | Superseded control, not missing voters | No allocation or zero imputation justified |
| Heby 1917/0331 and Dalarna 20L/20LG | Documented geographic code presentation | Diagnostic crosswalk only; no vote correction |
| Four-party RD detail | Explicit technical reporting correction | Corrected known values established, but not yet incorporated in output |
| Nine supplement blanks/lower-level allocations | Explicit source-disclosure limitation | Full corrected party detail cannot be claimed |
| Blank versus other invalid | Source category not separately available | Correctly remains NA; combined totals verified |
| Three RD district XML exports | Recovery/coverage limitation | District views refuse incomplete output; aggregate values correct |

Candidate identity and the RD +547 / RF +28 preference-aggregate control
findings remain separate. This ordinary-result review neither changes nor
purports to resolve candidate/list linkage or those preference-vote findings.

Source integrity was reverified for every selected XML (869 MD5 and SHA256
pairs). All 13 prototype assets still match manifest size/SHA256; the manifest
SHA256 remains `5d1d9941bb6f47eee54d8ae95148e4aec3a42f4867de81a4188a130265a636a0`.
No raw file, prototype/published asset, production file, candidate rule or
source selection was modified. Only this reconciliation documentation and
local ignored diagnostics/preserved external controls were added. No broad
suite/check rerun was needed because production code and tests were unchanged.
No commit or push was made.

## Subsequent approved incorporation

The source findings above are retained as the pre-incorporation audit. The
approved supplement has now been incorporated into result output only; its
exact official URL and identical fresh-download checksum are established.
See [SUPPLEMENT_2002.md](SUPPLEMENT_2002.md). The prior statement that package
output still uses the older four-party aggregate figures is superseded.
The nine undisclosed cells and unavailable lower-level allocations remain
source limitations, not inferred zeros.
