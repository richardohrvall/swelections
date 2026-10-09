# 2010 implementation decisions (working build)

The identity adapter was committed separately at 65bdb1f8. The original 39-file inventory and hashes are recorded in 2010_SOURCE_INVENTORY.json.

- Final: preserved slutresultat.zip (872 XML members, 2010-10-07 reporting timestamp), not mandate-period files.
- Election night: valnatt.zip (872 members); ordinary districts only. It cannot be relabelled preliminary.
- Preliminary: official historical collection-district presentation must be preserved separately and verified before use. Final XML supplies geography only, never preliminary vote counts.
- Ballots: alkandur_R/L/K.skv, 23,216 / 87,066 / 88,260 rows, 12/14/16 positional fields. Public names are typed NA; local names are research provenance only. Unsupported validity/consent attributes remain missing.
- Candidate population: ballot candidates plus identified final preference-vote, elected and substitute evidence. Membership files are validation only.
- Repeated PERSONVAL records are additive and consolidated in memory by parent and KANDNR before the shared strict validators.
- XML list prefixes identify numeric parties. Unobserved ballots may use the official notified-party register where the designation is unambiguous.
- Bjorn Andersson: RF XML 451964 is canonical 442089; approved RD ballot linkage 497359, party 0003, constituency 03, list 03600 position 22 also links to 442089. Raw identifiers and files remain intact. No other identity rules are enabled.
- Four known KF XML/member identifiers remain distinct source IDs; final XML is authoritative. Seven weaker cross-election name pairs remain unresolved.
- Fixed mandates and original elected-member files, final vote SKV, RD person-vote SKV and Excel files are independent validation inputs. Mutable membership/vacancy files cannot redefine the election result.

The shared 2014/2018 normalisation and public projection layers will be reused. 2010-specific code is limited to ZIP reading, metadata, ballot layout/party linkage and explicitly documented identity context.

## Additional verified source differences

- Final collection district codes use R/L/K-<municipality>-<constituency>; district SKV uses 0001-style codes (RD) or VK01-style codes (RF/KF). These are source representations of the same official municipality/constituency relation, not new districts.
- The official notified-party text is UTF-8; ballot SKV files are Latin-1. Party names must be matched in their correct encodings and geographic scope.
- ASK in Sigtuna is a comparison-only 2010 party. Official 2006 ballot XML identifies it as 0340; optional provenance-backed party metadata fills only its party identifier, never its 2010 votes or candidate population.
- Preliminary sources are now complete as a reporting snapshot: 395 RD, 392 RF and 395 KF collection pages. Ordinary election-night XML supplies ordinary districts; separately preserved preliminary HTML supplies collection counts. Nine RF and nine KF collection pages have no reported vote fields and remain NA. Another 722 pages have isolated blank category cells, also retained as NA. Final XML supplies geographic relations only, never preliminary collection votes. No public election_night stage is added.
- The build is an unpublished dirty-tree prototype, not a clean release build.

- Same-name municipal parties are not a safe global identity relation: ALT 0200 / ALTER 0510 and FKL 0533 / FRK 0079 must stay separate. Comparison-only aliases use the geographically scoped official 2006 party identifiers before national abbreviation propagation. Regression tests protect this source difference.
- Independent mandate Excel differs only in RF county 14 and KF constituency 188004, the 2011 re-election scopes. It is a validation snapshot, not authority for the ordinary 2010 election.

## Preliminary snapshot: source roles and missingness

| Component | Input and meaning | Treatment |
|---|---|---|
| Ordinary election-night districts | `valnatt.zip`, ordinary `VALDISTRIKT` nodes | Preserve the reported election-night figures. |
| Preliminary collection reporting | Separate hash-pinned historical preliminary HTML | Append every collection district, using only this stage's vote fields. |
| Completely unreported collections | Nine RF and nine KF HTML pages with all vote fields blank | Keep the district and its party/category rows; `counted = FALSE`, blank vote values remain typed `NA`. |
| Partially reported collections | 722 pages with at least one blank current vote category | Keep reported counts and explicit changes; individual blanks remain `NA`, including comparison-year blanks. A blank category is not a zero. |
| Final collections | `slutresultat.zip`, `ONSDAGSDISTRIKT` nodes | Used for final results. In the preliminary reader they provide geographic relations only, never vote counts or missing-value replacements. |

Aggregate preliminary values describe the official reported/counting snapshot, not eventual totals. Known district/category values can therefore be summed for this snapshot while missing district values remain missing in the district output. A wholly unknown aggregate remains `NA`; explicit aggregate metadata are read from the preserved preliminary presentation and checked against reported sums. District totals are derived only when their required components are known. The `election_night` stage is not added to the public API.

The year-specific R HTML adapter is `R/preliminary_2010.R`. It reuses the established XML normalisation and output-name/projection layers without changing the public schema. Candidate/person-vote completeness and the approved identity adapter are unchanged; the seven unresolved identity pairs remain unresolved.
