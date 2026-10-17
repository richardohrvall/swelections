# EU 2004 completeness

This statement concerns the fixed 13 June 2004 election result, established by
Valmyndigheten's 17 June decision (Dnr 04-139/4), rather than later membership.
See [source inventory](SOURCE_INVENTORY_EU_2004.md),
[source policy](SOURCE_POLICY.md) and [validation](VALIDATION_EU_2004.md).

| Dimension | Status | Exact population or exception |
|---|---|---|
| Final valid party/category votes | COMPLETE | 27 individually identified parties plus the reported 943-vote handwritten/other-party aggregate; 2,512,069 valid votes |
| Final invalid and cast votes | COMPLETE | 68,129 blank invalid + 4,266 other invalid; 2,584,464 ballots |
| Public result geography | COMPLETE | National 1, counties 21, municipalities 290, real municipal constituencies 185 in 79 municipalities, ordinary districts 5,875, Wednesday units 396 |
| Zero Wednesday unit | COMPLETE | E-0483-02 explicitly zero in original Katrineholm XML; retained despite absence from sparse positive district exports |
| RD reporting constituencies | COMPLETE in source; outside existing EU public levels | 29 reporting branches in national XML; no new public constituency-level contract introduced |
| Electorate/turnout totals | COMPLETE | 6,827,870 eligible voters; electorate and turnout not assigned to 396 Wednesday units |
| Electorate composition | COMPLETE at national/county/municipality levels | Three SCB components reconcile in all 312 areas; typed NA at municipal-constituency/district levels; no downward allocation. SND's ordinary-district foreign-EU count remains independent validation material, not a build input |
| Identified party breakdown inside the 943 residual | INCOMPLETE | No checked source reports individual party designations for these 943 valid handwritten votes; no allocation invented |
| Documented ballot candidacies | COMPLETE | 382 list-position observations on 30 definitive ballots for 27 parties |
| Source-reported person identifier | INCOMPLETE | No stable source person identifier in these sources; generated candidate numbers identify ballot/list positions only |
| Physical-person linkage across ballots/elections | NOT VERIFIED | No cross-list/name-only or longitudinal linkage is asserted |
| Reported preference observations | COMPLETE | 282,901 positive district/list-position rows; 1,480,960 votes; 360 ballot positions with positive votes, 22 verified zero positions |
| Allocated/filled/unfilled seats | COMPLETE | 19 allocated, 19 elected persons, zero unfilled; SD/other parties have no seats |
| Fixed elected/substitute relations | COMPLETE | 19 elected, 27 substitute posts, 71 expanded member/substitute relations from original result |
| Complete preliminary result | INCOMPLETE | Full preliminary Wednesday snapshot not recovered; final Wednesday values are not substituted |
| Election-night higher aggregates | COMPLETE | Preserved national 1/county 21/reporting-constituency 29/municipality 290 aggregates; source reports 5,875/5,875 districts counted; not exposed as complete preliminary |
| Election-night individual district payloads | NOT VERIFIED | A full census of individual district payloads has not been recovered/audited; the reported district count is not proof of payload coverage |
| Mandate-period history | NOT VERIFIED | No complete term-event history established or implemented |

Blank is **invalid** in this election, unlike the valid Blank voting option in
the 2003 referendum. The 943 handwritten votes are valid and remain included
once in every relevant aggregation. They generate no candidate observations.

SCB reports 372 nominated candidates under its counting population. The ballot
archive supplies 382 observations: repeated FRP list positions account for six
extra observations relative to source party-summary counts, while five separately
reported parties share the same Bosse Persson description. Counting that common
description once accounts arithmetically for the remaining four. This comparison
does not establish a person-identity crosswalk and no records are merged.

SCB SSD's270 SD zero cells are contradicted by the final protocol and detailed
source counts. The implementation retains the protocol-supported14,450 SD
preferences; SCB's all-party total1,480,960 already agrees.

## Public schema

The existing English/Swedish result, seat, candidacy, candidate, elected,
substitute and preference schemas are reused. Canonical columns are English;
source-language values are preserved. `standard` remains a projection of `full`.
The existing electorate-composition fields are included in full results where
SCB supplies them, without estimating finer geography.

`candidate_number` values such as `2004:E:ballot:00001:1` are generated
**candidacy keys**, not person IDs. `ballot_order` comes from the ballot XML's
`ORDNINGSNUMMER`; person-vote rank is not used as ballot order. The source
`valid` candidacy attribute remains typed missing because the source does not
supply the later administrative validity field. Internal inclusion of the
verified ballot population does not assert that unsupported attribute.

The public EU levels remain national, county, municipality,
municipal_constituency and district (plus preference_vote_area for national
candidate preference analysis). The default EU year remains2024. EU2009's
existing observations and unresolved issues are unchanged.
