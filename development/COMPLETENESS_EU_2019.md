# EU 2019 implementation and completeness

The source population is the ordinary 26 May 2019 European Parliament election.
The original allocation has 20 seats. The additional post-Brexit seat from
1 February 2020 is a later event and does not alter this fixed result.

| Dimension | Status | Verified population / exact exception |
| --- | --- | --- |
| Final party votes and ballot categories | COMPLETE | Country, 21 counties, 290 municipalities, 53 actual municipal constituencies, 5,984 ordinary districts and 321 Wednesday units. All 66 parties with positive final votes are individually represented. |
| Preliminary result | COMPLETE | Original full 29 May XML: all 6,305 units. Ten parties individually identified; all remaining valid votes are explicitly aggregated as other parties. A separate breakdown of this aggregate is not published in this snapshot and is not inferred from final data. |
| Final valid / invalid / cast totals | COMPLETE | 4,151,470 valid; 36,378 invalid (30,712 blank, 1,709 without participation notice, 3,957 other invalid); 4,187,848 cast. The party named Blankt is distinct from invalid blank ballots. |
| Final electorate | COMPLETE | 7,576,917. Fresh official SKV reconciles at all 5,984 ordinary districts. Wednesday units have no own electorate or turnout; those values remain NA, with no downward allocation. |
| Three-way electorate composition | COMPLETE at country/county; INCOMPLETE below county | SCB separately reports 7,359,384 Swedish citizens resident in Sweden, 168,461 abroad, and 49,072 other EU citizens. Residence split unavailable below county; remains validation material rather than new public fields. |
| Candidacy population | COMPLETE | 562 source rows, 556 valid candidacies, six invalid rows, 560 distinct source candidate numbers across both statuses. The valid population has 556 candidate-party keys. |
| Source names | INCOMPLETE | The current official file redacts all 562 source rows. All public candidate names are typed NA, including preferences and relations; local named snapshots are provenance only. |
| Reported preference observations | COMPLETE | 410,308 positive district/list/candidate records across all 6,305 units, totalling 1,634,596 votes; 518 national list/candidate records reconcile exactly. No duplicate counting of party-level PERSONVAL. |
| Invalid-candidacy preference observations | COMPLETE | 533186/0110: 7,452; 480136/1140: 1; 534261/1351: 2. These 7,455 votes remain in preference output. They are not added to the valid candidates() population or reassigned to another party. |
| Valid candidate preference enrichment | COMPLETE | 1,627,141 votes on 515 positive valid candidate-party keys; 41 valid keys have no reported positive votes. All reported national candidate records are covered. |
| Mandates / elected / substitutes | COMPLETE | 20 allocated, 20 elected, zero unfilled; 27 distinct substitute IDs in eight source groups, represented by 74 member-substitute relations. |
| Physical-person / longitudinal identity | NOT VERIFIED | Official numbers and party/list keys are preserved. No claim of person identity across election occasions or independent records; no name matching or identity harmonisation. |
| Separate election-night freeze | NOT VERIFIED | The separate historical page has no usable numeric freeze. Not exposed as another stage; complete preliminary XML is available and does not depend on that page. |
| Mandate-period history | NOT VERIFIED | Not an election-result requirement; not reconstructed. |
| Original final XML signature / DTD validation | NOT VERIFIED | Original ZIP and members are preserved and hashed; empirical structure and results are validated. Binary signature / unavailable referenced DTD is not formally authenticated. |

## Source and schema decisions

Valmyndigheten's preserved original final/preliminary ZIPs are primary. The
separate official handwritten-party XLS discloses 1,985 positive party-unit
records (34 parties, 2,315 votes). They replace, rather than add to, the final XML
handwritten residual at each geographic unit. All labels resolve uniquely to
numeric codes in the official party register. Preliminary other-party totals
remain aggregated; final party detail is never inserted into preliminary data.

The current redacted candidacy SKV and freshly retrieved electorate SKV are
pinned by SHA256. The older local electorate snapshot contains 983 additional
voters across 1,045 district-total differences and is rejected as a build input.
Original archive acquisition dates are unknown and are not inferred from mtime.
The manifest records that explicitly, alongside known retrieval times, official
URLs, MD5, SHA256 and file sizes. Sources are resolved by approved content,
independent of machine-specific paths. The original final ZIP is currently
unavailable from its former URL; local preserved inputs remain necessary for a
complete raw build. Explicit remote requests never silently use local sources.

No new public columns or election-stage values are introduced. English and
Swedish views reuse the existing standard/full projection and EU geography:
one national mandate/preference-vote constituency, county, municipality,
actual municipal constituency and district. The 29 RD reporting branches in the
XML are not 29 European electoral constituencies. Technical 00 municipality
These branches remain in the preserved original XML/provenance; they are not
introduced as an additional public EU level. The existing EU geographic API
and five result levels are retained.
branches are not new public geographic entities.

KANDNR is the official source candidate number; KANDIDAT is ballot position;
ORDNING on PERSONVAL is preference rank. Rank is not used as position or ID.
Candidate joins include party and list where relevant. Invalid source ID 534261
under party 1351 must not enrich its valid consent-only record under party 1140.
Valid B-status Volt list 17274 remains documented without inventing printed-list
preference records from the party's 146 handwritten votes. Zero completion only
uses documented list/candidate combinations in complete official result lists.

## R-only build and validation

```r
# Run from the repository root with documented R dependencies installed.
# Optional readxl is needed for the raw handwritten-party XLS and controls;
# nanoparquet is needed for canonical building/reading, not a mandatory dependency.
```

```text
Rscript data-raw/build-canonical-eu-2019.R RAW_ROOT EMPTY_OUTPUT_DIR
Rscript data-raw/validate-eu-2019.R RAW_ROOT OUTPUT_DIR INDEPENDENT_CONTROL_DIR
```

RAW_ROOT may be the preserved eu/2019 directory or its parent archive. Source
filenames may be retained in separate snapshot directories; approved hashes
select the correct version. INDEPENDENT_CONTROL_DIR contains the official
current-district.xlsx, current-municipal.xlsx, scb-district.xlsx,
scb-county.xlsx, scb-electorate.xlsx and scb-candidate-overview.xlsx documented in the source inventory.
No sources or generated Parquet files belong in Git.

The unpublished local prototype has 15 English-schema Parquet assets: final and
preliminary results, final and preliminary seats, candidacies, candidates,
elected, substitutes, candidate-base, and six preference bases (area, national,
county, municipality, municipal-constituency, district). Data version remains
separate from package version; schema version is 2 and auto eligibility is false.

See [SOURCE_INVENTORY_EU_2019.md](SOURCE_INVENTORY_EU_2019.md) for source evidence.
Validation outcomes are recorded in [VALIDATION_EU_2019.md](VALIDATION_EU_2019.md).
