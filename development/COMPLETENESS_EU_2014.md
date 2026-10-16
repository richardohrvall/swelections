# EU2014: completeness of the implemented final-result source population

Election occasion: 25 May 2014. Valmyndigheten's preserved original final XML
with geographic names is the primary build source. Current redacted XML is not
substituted for it. [Inventory](SOURCE_INVENTORY_EU_2014.md) records all sources.

| Dimension | Status | Verified population / exact exception |
| --- | --- | --- |
| Final party/category vote accounting | COMPLETE | 290 municipalities, 5,837 ordinary districts, 390 Wednesday units, 21 counties and national aggregates; 3,716,778 valid votes. |
| Named-party results | COMPLETE | 21 positive XML parties plus source zero-vote Socialisterna; numeric code for the zero category is unavailable and remains NA. |
| Handwritten valid-vote category | COMPLETE | All 5,618 votes retained as the XML's other-party category; never added twice. |
| Handwritten label detail | INCOMPLETE | Exactly 10 votes at 05803201, Vårdsberg (Linghem S), Linköping have no party designation reported in the preserved result material; this does not describe what was written on the original ballots. The other 5,608 have raw reported labels. |
| Identity of handwritten political parties | NOT VERIFIED | 890 exact spellings are not assumed to be 890 independently identified parties. Raw labels are separate source-oriented data, not fabricated party IDs. |
| Numeric XML party codes | INCOMPLETE | Exactly one source zero-vote category, Socialisterna (alias `scl`), has no numeric code in the inspected result/list source. All 21 positive named parties have codes. Raw handwritten spellings are not assigned invented codes. |
| Documented ballot candidacies | COMPLETE | 376 records/376 source IDs, 21 lists and parties; independently matches SCB. |
| Source candidate-result preferences | COMPLETE | 402,053 positive list/candidate/unit records, 1,859,375 votes, all 6,227 district units. Every ID/list/position joins the candidacy source. |
| Original mandates/elected/substitutes | COMPLETE | 20 allocated, 20 elected, zero unfilled; 30 substitute IDs, 9 groups, 74 expanded relations. |
| Final geographic population | COMPLETE | All 6,227 district units and 290 municipalities; 181 real municipal constituencies in 81 divided municipalities; 209 technical containers do not become extra public constituencies. |
| Eligible voters and turnout at reported levels | COMPLETE | 7,359,962 eligible; all 5,837 ordinary-district denominators available. |
| Wednesday electorate/turnout | INCOMPLETE | All 390 units lack separate electorate/turnout denominators by source design. Their ballot/vote totals are complete. |
| Modern candidate administrative attributes | INCOMPLETE | Source does not provide separate validity, consent, declaration, election-day eligibility, registered municipality or ordered-ballot counts for 376 records. Unsupported fields remain typed NA. Internal population inclusion is not an asserted validity value. |
| Public candidate names | INCOMPLETE | All 376 public names intentionally NA, consistent with current official redaction. Names are not join keys. |
| Physical-person linkage | NOT VERIFIED | No identity assertion across lists/election occasions. This is not missing preference/candidacy observations. |
| Full preliminary result | INCOMPLETE | No recovered preliminary Wednesday snapshot. Complete 5,837 ordinary-district election-night archive is preserved as provenance only; preliminary calls fail explicitly. |
| Full mandate-period history | NOT VERIFIED | No complete term-event series established; fixed election relations are complete. |
| SCB three-way electorate composition | COMPLETE | Available as validation evidence for country+21 counties; components reconcile. Separate Swedish-resident/abroad counts below county are unavailable, no downward allocation. These supplementary composition fields are not added to EU public output. |

## The ten Vårdsberg votes

Original XML: district 05803201,`ÖVRIGA_GILTIGA/HANDSKRIVNA/@RÖSTER=10`.
The whole other-party aggregate is 13: **3 reported Junilistan votes + 10
HANDSKRIVNA votes**. Its one reported candidate preference vote belongs to the
Junilistan branch; the handwritten branch reports no identified candidate.
Valid votes are 778. The public Valmyndigheten
page independently displays the ten votes as votes on parties without ordered
ballots. Neither that page nor the detailed handwritten SKV identifies their
party designations. SCB's county table reports 5,948 other-party votes in Östergötland (including
Piratpartiet), without a district/designation split for these ten. The preserved
transformed local CSV also reports only grouped other=13 at 05803201 and has no
established SCB/SND provenance. These controls cannot assign the ten to a party;
no administrative SND source with a more detailed allocation has been established.

Standard output retains the official handwritten residual with `other_parties`
TRUE, `party_code` NA and its source category label. It does not assert that this
is one political party. Full output adds `source_votes_without_party_designation`
(`kall_roster_utan_partibeteckning`), 10 on the affected residual and its aggregates,
0 on fully designated residuals, and NA on named-party rows. This is disclosure
metadata, not votes to add to `votes`.

The source-oriented canonical asset `eu2014-source-designations.parquet` retains
exact reported labels and their unit-level sums, plus one explicitly unidentified
record:unit 05803201, designation NA, 10 votes, missing-designation TRUE. Those source
rows sum to 5,618 and replace no candidate or preference-vote observation.
No value is assigned to a named party or candidate without source evidence.

This implementation does not interpret preference rank as ballot position,
make further identity harmonisations or use final Wednesday votes as preliminary.

The missing-designation indicator means that the inspected published sources
do not disclose the party label. It does not mean that the physical ballot was
blank or invalid, nor that the original count never identified a designation.

The targeted follow-up also checked the separate official handwritten-label HTML
fragments and the alternative handwritten Excel export. The district fragment
returns HTTP 200 with an empty body; neither Excel nor SKV contains a row for
05803201. SCB Table 6 discloses only parties reaching 0.5% in a municipality;
its Linkoping entry is Piratpartiet (2,609 votes), so it cannot identify these
ten votes. These are reported-source disclosure limits, not evidence of ballots
without a party designation. No indirect party attribution is made.
