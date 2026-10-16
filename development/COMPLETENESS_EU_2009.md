# EU 2009 completeness

This statement concerns the fixed 7 June 2009 election result, not the later
increase from 18 to 20 seats on 1 December 2011. Valmyndigheten is the primary
result source; SCB is an independent validation source.

| Dimension | Status | Verified scope / exact exception |
|---|---|---|
| Final party/category votes | COMPLETE | All source-reported parties/categories at national,21 county,290 municipality,186 real municipal-constituency and6060 district/Wednesday units. Unsplit other-party categories are retained rather than allocated. |
| Final geography | COMPLETE | 5664 ordinary districts +396 Wednesday units;210 technical municipal-constituency00 branches are not additional constituencies. |
| Final electorate | COMPLETE | 7088303 eligible voters; ordinary-district denominators are reported. Wednesday units have no electorate/turnout and remain NA. |
| Handwritten designation detail | INCOMPLETE | XML residual1130 includes1127 votes with reported source labels;2 Stockholm0180 and1 Ekerö0125 have no reported designation. They remain valid votes; original ballots' inscriptions are not inferred. |
| Documented ballot candidacies | COMPLETE | 25 ballot lists,23 candidate-bearing lists,500 candidate/list-position records. Two plain party ballots have no candidate positions. Names/descriptions restored by archived original XML. No additional consent-only register is claimed. |
| Physical-person population/linkage | NOT VERIFIED | SCB reports488 unique nominees; exact500-to488 mapping cannot be established without the non-public person identifiers used by SCB. Identical names are not collapsed. |
| Main11 parties' reported preferences | COMPLETE | 386 national ballot-position records;370716 positive district/list records;1,874,130 votes (main-party component only);64762 published list controls. All6060 district/Wednesday units are included in source coverage. |
| Total reported preference-vote count | COMPLETE | Main-party component 1,874,130 + official small-party aggregate 2,655 = 1,876,785, matching Valmyndigheten and SCB. The separate national candidate-column discrepancy is +10 votes and remains unresolved. |
| Small-party reported column cells | COMPLETE | Original archived workbook has102 named candidate columns across5976 source rows: national,21 counties,290 municipalities,5664 ordinary districts. Source zeros remain zeros. |
| Reconciled small-party preferences | INCOMPLETE | National candidate sum2665 vs official aggregate2655; county/municipal sums2677. Only Per Johansson columns36/47 fail national/county/municipal reconciliation among102 columns. Their values are preserved, not deduplicated. |
| Small-party Wednesday and municipal-constituency preferences | INCOMPLETE | No directly reported candidate cells at these levels. No subtraction/allocation from inconsistent workbook totals. Main-party records at these levels remain available. |
| Small-party source-column to ballot-position linkage | NOT VERIFIED | 102 workbook columns lack explicit ballot/position identifiers. Separate column keys preserve observations without unsupported name-only joins to114 small-party ballot slots. |
| Original mandates/elected/substitutes | COMPLETE | 18 allocated,18 elected,0 unfilled;27 substitute posts in8 groups,68 expanded elected/substitute relations. |
| Complete preliminary count | NOT VERIFIED | Complete election-night ordinary-district archive exists; no verified complete preliminary Wednesday snapshot. Preliminary requests fail explicitly; final Wednesday figures are not substituted. |
| Separate election-night source | COMPLETE | 5664 ordinary districts; preserved as provenance, not exposed as full preliminary. |
| Full mandate-period event history | NOT VERIFIED | Original relationships only; later2011 seat expansion is excluded. No complete term-event ledger is claimed. |

## National preference-vote total reconciliation

The current implementation reports **1,874,130 as the main-party component**,
not the total for all parties. The preserved final Valmyndigheten XML and
SCB historical table report the following national totals:

| Component | Preference votes |
|---|---:|
| Main 11 parties (current API candidate observations) | 1,874,130 |
| Official small-party aggregate (Valmyndigheten and SCB) | 2,655 |
| Total reported preference votes (Valmyndigheten and SCB) | **1,876,785** |

**1,874,130 + 2,655 = 1,876,785**: the apparent large discrepancy is resolved.
This aggregate reconciliation is separate from the unresolved **10-vote**
small-party discrepancy: national candidate columns sum to **2,665**, whereas
the official small-party aggregate is **2,655**. No source establishes its
cause. Candidate values are preserved without correction or deduplication.
Consequently, summing the national candidate rows returned by
`preference_votes()` gives **1,876,795**, not the official aggregate total.
No allocation or change to candidate-level values is made to force agreement.

## Identity and observation keys

`candidate_number` for2009 is an explicitly generated source-coordinate key:
`2009:E:ballot:LIST:POSITION` for ballot candidacies and main-party preferences;
`2009:E:source-column:COLUMN` for independent small-party preference observations.
Neither denotes an official candidate/person ID or a longitudinal person key.
`candidates()` contains the500 documented ballot positions, not488 verified
physical persons. Unlinked small-party preference totals in that view are NA,
not zero. Those preference observations remain available through
`preference_votes()` under their source-column keys, with unknown list/position.

ArbetarInitiativet ballot04536 position18 is Per Johansson, tågförare, Stockholm,
age48; position32 is Per Johansson, sjuksköterska, Sundsvall, age38. These are
different candidates. Workbook columns36 and47 both say Per Johansson and have
identical numeric vectors, each22 nationally,28 over counties/municipalities,
32 over ordinary districts. The workbook does not identify which ballot position
a column belongs to. No assignment based solely on repeated name/column order
is made. Ten negative municipality-minus-ordinary cells are not Wednesday data.

The other100 columns reconcile nationally/county/municipally. This localises
that particular summation inconsistency, without proving that every column is
correct or linked to a particular physical person. Ballot-party summary498 and
SCB unique-person488 are separate source counts; neither replaces500 positions.
### What500 versus488 establishes

The restored source contains496 exact name strings and498 distinct
name/sex/XML-age tuples across500 list positions. Within Ai, Christer Lindsjö
appears on04536/10 and04576/2 (age53), and Anders Svensson on04536/26 and04576/5
(age52), with compatible occupation descriptions. These are possible cross-list
links, not a published person-ID crosswalk. The two Per Johansson positions are
explicitly distinguishable by age, occupation and locality. Magnus Johansson
also occurs in two parties with different XML ages and different descriptions.
None of these name groupings is used to deduplicate public observations.

Thus simple exact-name/age grouping yields498, not SCB488. The remaining
10-person difference after that grouping cannot be assigned to identified
candidacies from the available public evidence. Nor is498 itself asserted to
be a verified person count. SCB's488 is retained as an independent person-level
control with a different, non-reproducible-publicly identity procedure.
XML age and an age embedded in free-form ballot description can differ; both
source fields are preserved without correcting one from the other.
SCB's preserved nominee overview (`scb-nominee-overview.xlsx`, `tab 1`,2009 column)
reports352 candidates for the nine separately tabulated parties plus136 for its
broader other-party group (including FI/SD), total488. The corresponding nine
ballot-party counts match exactly. The ballot source has148 slots in that broader
group, hence the12-observation difference is confined to that group. Equivalently,
the eleven main ballot parties have386 positions; the remaining114 ballot positions
compare with102 named small-party preference columns. Numerical equality between
386+102 and488 is not an individual identity reconciliation, and no zero-vote
ballot positions are discarded on that basis. All500 have XML ages18–79 and none
has missing age; an under18/missing-age exclusion does not explain the difference.
### Public geographic scope

The COMPLETE final-geography status refers to the five supported EU result levels:
national,county,municipality,real municipal constituency anddistrict/Wednesday unit.
The XML also preserves29 RD reporting groups. These are not EU mandate
constituencies and are not exposed as an additional EU constituency API level;
the raw source remains preserved. This does not remove any ordinary/Wednesday
unit or change the supported geographic totals.
