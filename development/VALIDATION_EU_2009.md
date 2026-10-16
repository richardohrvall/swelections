# EU 2009 implementation and validation

See [SOURCE_INVENTORY_EU_2009.md](SOURCE_INVENTORY_EU_2009.md) for exact source
URLs, hashes, snapshots, independent SCB controls and known discrepancies, and
[COMPLETENESS_EU_2009.md](COMPLETENESS_EU_2009.md) for dimension-specific status.

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

Targeted reconciliation rerun: the current canonical public API main-party
sum was compared directly with `NATION/@PERSONKRYSS` and the
`NATION/GILTIGA[@PARTI="ÖVR"]/@PERSONKRYSS` aggregate in the preserved
original final XML, and with SCB national `TOTALT` and `ÖVRIGA` values.
All aggregate equalities passed; the candidate-column sum and unresolved
+10 difference were also asserted unchanged. This documentation clarification
does not require a rebuild or any change to canonical assets.

## R-only workflow

```sh
Rscript data-raw/build-canonical-eu-2009.R RAW_ROOT EMPTY_OUTPUT_DIR
Rscript data-raw/validate-eu-2009.R RAW_ROOT OUTPUT_DIR CONTROL_DIR
```

`RAW_ROOT` contains the preserved2009 archive; files are selected by pinned SHA256,
not newest filename. `CONTROL_DIR` contains the independent SCB workbook
`scb-district.xls` preserved during inventory. Optional `readxl` is needed only
for raw workbook parsing; canonical reading uses optional `nanoparquet`.
No Python executable or live network is needed. Sources/assets are not tracked.

The archived ballot XML actually captured10 February2010 at20:32:52 has source
update time7 June2009 at23:25:01. It has25 lists/500 positions; comparison with
the current gallrat XML shows500 candidate-description differences and no other
attribute/tree differences. HTML capture9 February2010 has source time23:25:02.
These sources describe the same final list-position structure, unlike an
unverified pre-election April capture. Retrieval URLs/times/checksums are in the
local acquisition ledger; build source pins are in `.eu2009_sources()` and manifest.

The2009 XML adapter changes category nesting in memory only. Main-party
`KANDIDAT` is ballot position; `ORDNING` is preference rank. Generated keys use
ballot position, never preference rank. Original source files remain unchanged.
Original elected relations are linked within a single explicitly identified
party ballot using exact source name and age where provided; no cross-list
physical-person identity is inferred. Small-party workbook columns remain
independent observations because explicit list-position links are absent.

The canonical prototype retains English schema2, all seven tables, candidate-base,
source-designations and six normalized preference bases:14 Parquet assets.
`source="canonical"` requires an explicitly configured local manifest; auto is
not enabled for an unpublished2009 build. Source `remote` fails explicitly when
the original named/complete pinned snapshots cannot be supplied equivalently.

Main-party aggregation uses non-overlapping ordinary/Wednesday records. Small-party
national/county/municipality records use their own published workbook scope;
ordinary-district records use their directly reported cells. Missing small-party
Wednesday/constituency observations are never inferred by subtraction. List
shares for unlinked column observations remain NA. The source-reported national
candidate sum1876795 (1874130+2665) is intentionally10 greater than the official
aggregate1876785. District candidate sum1876701 includes2571 reported small-party
ordinary votes and no invented small-party Wednesday allocation.

Validation covers originalXML party/category/geographic results, all370716
positive main-party district/list records,64762 list-total controls, original18
elected and68 expanded substitute relations; independent SCB5954 district/pooled
Wednesday units; pinned sources and Parquet hashes/round-trip; all seven APIs,
standard/full projection, English/Swedish and actual Swedish wrappers. Known
small-party discrepancies are asserted separately, never weakened away.

A build from an uncommitted working tree must truthfully record
`build_tree_dirty=true`. A clean-commit rebuild is deferred until commit approval;
no clean status or release readiness is inferred from an uncommitted build.
## Public schema: actual national/default views

The following column lists describe the implemented outputs. Other levels replace
the primary geographic columns with the corresponding county/municipality/
municipal-constituency/district fields and retain the established higher context.
No new person-ID field or person-linkage assertion is introduced.

### `results()`

- en standard: `election_year`, `election_code`, `count_stage`, `geographic_level`, `party_code`, `party_designation`, `party_abbreviation`, `other_parties`, `votes`, `vote_share`, `total_votes`, `valid_votes`, `invalid_votes`, `blank_votes`, `eligible_voters`, `turnout`, `previous_votes`, `previous_vote_share`, `previous_turnout`, `votes_change`, `vote_share_change`, `turnout_change`, `comparison_status`, `overall_districts_counted`, `overall_districts_to_count`, `eligible_voters_in_counted_districts`.
- en full adds: `election_event`, `election_kind`, `election_date`, `previous_election_date`, `is_test`, `reporting_time`, `source_last_update_time`, `update_count`, `color_code`, `party_order`, `above_threshold`, `electoral_area_threshold`, `constituency_threshold`, `invalid_vote_share`, `votes_no_participation_notice`, `vote_share_no_participation_notice`, `blank_vote_share`, `other_invalid_votes`, `other_invalid_vote_share`, `previous_total_votes`, `previous_eligible_voters`, `previous_valid_votes`, `previous_invalid_votes`, `previous_invalid_vote_share`, `previous_votes_no_participation_notice`, `previous_vote_share_no_participation_notice`, `previous_blank_votes`, `previous_blank_vote_share`, `previous_other_invalid_votes`, `previous_other_invalid_vote_share`, `total_votes_change`, `eligible_voters_change`, `valid_votes_change`, `invalid_votes_change`, `invalid_vote_share_change`, `votes_no_participation_notice_change`, `vote_share_no_participation_notice_change`, `blank_votes_change`, `blank_vote_share_change`, `other_invalid_votes_change`, `other_invalid_vote_share_change`, `source_votes_without_party_designation`.

- sv standard: `valar`, `valtyp`, `rakningstillfalle`, `geografiniva`, `partikod`, `partibeteckning`, `partiforkortning`, `ovriga_partier`, `antal_roster`, `andel_roster`, `totalt_antal_roster`, `giltiga_roster`, `ogiltiga_roster`, `blanka_roster`, `antal_rostberattigade`, `valdel`, `antal_roster_fg`, `andel_roster_fg`, `valdel_fg`, `diff_antal_roster`, `diff_andel_roster`, `diff_valdel`, `status_jamforelse`, `antal_valdistrikt_raknade`, `antal_valdistrikt_som_ska_raknas`, `antal_rostberattigade_raknade`.
- sv full adds: `valtillfalle`, `valklass`, `valdatum`, `valdatum_fg`, `test`, `rapporteringstid`, `senaste_uppdateringstid`, `antal_uppdateringar`, `fargkod`, `ordningsnummer`, `over_sparr`, `valomradessparr`, `valkretssparr`, `andel_ogiltiga`, `roster_ej_anmalt_deltagande`, `andel_ej_anmalt_deltagande`, `andel_blanka`, `ovriga_ogiltiga`, `andel_ovriga_ogiltiga`, `totalt_antal_roster_fg`, `antal_rostberattigade_fg`, `giltiga_roster_fg`, `ogiltiga_roster_fg`, `andel_ogiltiga_fg`, `roster_ej_anmalt_deltagande_fg`, `andel_ej_anmalt_deltagande_fg`, `blanka_roster_fg`, `andel_blanka_fg`, `ovriga_ogiltiga_fg`, `andel_ovriga_ogiltiga_fg`, `diff_totalt_antal_roster`, `diff_antal_rostberattigade`, `diff_giltiga_roster`, `diff_ogiltiga_roster`, `diff_andel_ogiltiga`, `diff_roster_ej_anmalt_deltagande`, `diff_andel_ej_anmalt_deltagande`, `diff_blanka_roster`, `diff_andel_blanka`, `diff_ovriga_ogiltiga`, `diff_andel_ovriga_ogiltiga`, `kall_roster_utan_partibeteckning`.

### `seats()`

- en standard: `election_year`, `election_code`, `count_stage`, `geographic_level`, `constituency_code`, `constituency_name`, `party_code`, `party_designation`, `party_abbreviation`, `seats`, `previous_seats`, `seats_change`, `total_seats`, `unfilled_seats`, `fixed_seats`, `adjustment_seats`, `comparison_status`.
- en full adds: `election_event`, `election_kind`, `election_date`, `previous_election_date`, `is_test`, `source_last_update_time`, `update_count`, `reporting_time`, `overall_districts_counted`, `overall_districts_to_count`, `electoral_area_name`, `electoral_area_code`, `electoral_area_threshold`, `constituency_threshold`, `total_fixed_seats`, `total_adjustment_seats`, `previous_fixed_seats`, `previous_adjustment_seats`, `previous_total_seats`, `previous_total_fixed_seats`, `previous_total_adjustment_seats`.

- sv standard: `valar`, `valtyp`, `rakningstillfalle`, `geografiniva`, `valkretskod`, `valkretsnamn`, `partikod`, `partibeteckning`, `partiforkortning`, `antal_mandat`, `antal_mandat_fg`, `diff_antal_mandat`, `totalt_antal_mandat`, `antal_tomma_stolar`, `antal_fasta_mandat`, `antal_utjamningsmandat`, `status_jamforelse`.
- sv full adds: `valtillfalle`, `valklass`, `valdatum`, `valdatum_fg`, `test`, `senaste_uppdateringstid`, `antal_uppdateringar`, `rapporteringstid`, `antal_valdistrikt_raknade`, `antal_valdistrikt_som_ska_raknas`, `valomradesnamn`, `valomradeskod`, `valomradessparr`, `valkretssparr`, `totalt_antal_fasta_mandat`, `totalt_antal_utjamningsmandat`, `antal_fasta_mandat_fg`, `antal_utjamningsmandat_fg`, `totalt_antal_mandat_fg`, `totalt_antal_fasta_mandat_fg`, `totalt_antal_utjamningsmandat_fg`.

### `candidacies()`

- en standard: `election_year`, `election_code`, `candidate_number`, `name`, `party_code`, `party_designation`, `party_abbreviation`, `candidacy_electoral_area_code`, `candidacy_electoral_area_name`, `candidacy_constituency_code`, `candidacy_constituency_name`, `list_number`, `ballot_order`, `valid`, `open_list`, `on_name_ballot`, `registered_municipality_name`.
- en full adds: `election_event`, `electoral_area_code`, `electoral_area_name`, `constituency_code`, `constituency_name`, `ballot_status`, `ballot_constituency_label`, `candidates_registered`, `consent`, `candidate_declaration`, `age_on_election_day`, `sex`, `ballot_info`, `list_ballots_ordered`.

- sv standard: `valar`, `valtyp`, `kandidatnummer`, `namn`, `partikod`, `partibeteckning`, `partiforkortning`, `kandidatur_valomradeskod`, `kandidatur_valomradesnamn`, `kandidatur_valkretskod`, `kandidatur_valkretsnamn`, `listnummer`, `ordning`, `giltig`, `oppen_lista`, `pa_namnvalsedel`, `folkbokforingskommun`.
- sv full adds: `valtillfalle`, `valomradeskod`, `valomradesnamn`, `valkretskod`, `valkretsnamn`, `valsedelsstatus`, `valkretsbeteckning_pa_valsedeln`, `anmalda_kandidater`, `samtycke`, `forklaring`, `alder_pa_valdagen`, `kon`, `valsedelsuppgift`, `antal_valsedlar_lista`.

### `candidates()`

- en standard: `election_year`, `election_code`, `candidate_number`, `name`, `party_code`, `party_designation`, `party_abbreviation`, `total_preference_votes`, `qualified_by_preference_votes`, `elected`, `elected_electoral_area_code`, `elected_electoral_area_name`, `elected_constituency_code`, `elected_constituency_name`, `order_of_election`, `election_basis`, `substitute_group`, `sex`, `age_on_election_day`, `registered_municipality_name`, `candidacy_electoral_area_code`, `candidacy_electoral_area_name`, `candidacy_constituency_code`, `candidacy_constituency_name`, `electoral_areas_count`, `constituencies_count`, `lists_count`, `open_list`, `on_name_ballot`.
- en full adds: `election_event`, `electoral_area_code`, `electoral_area_name`, `constituency_code`, `constituency_name`, `name_varies`, `name_variants_count`, `multiple_electoral_areas`, `multiple_constituencies`, `multiple_lists`, `parties_count`, `multiple_parties`, `election_types_count`, `multiple_election_types`, `preference_vote_areas_count`, `election_basis_id`.

- sv standard: `valar`, `valtyp`, `kandidatnummer`, `namn`, `partikod`, `partibeteckning`, `partiforkortning`, `antal_personroster_totalt`, `kvalificerad_personval`, `invald`, `invald_valomradeskod`, `invald_valomradesnamn`, `invald_valkretskod`, `invald_valkretsnamn`, `invalsordning`, `valgrund_text`, `ersattargrupp`, `kon`, `alder_pa_valdagen`, `folkbokforingskommun`, `kandidatur_valomradeskod`, `kandidatur_valomradesnamn`, `kandidatur_valkretskod`, `kandidatur_valkretsnamn`, `antal_valomraden`, `antal_valkretsar`, `antal_listor`, `oppen_lista`, `pa_namnvalsedel`.
- sv full adds: `valtillfalle`, `valomradeskod`, `valomradesnamn`, `valkretskod`, `valkretsnamn`, `namn_varierar`, `antal_namn`, `flera_valomraden`, `flera_valkretsar`, `flera_listor`, `antal_partier`, `flera_partier`, `antal_valtyper`, `flera_valtyper`, `antal_personvalsomraden`, `valgrund_id`.

### `elected()`

- en standard: `election_year`, `election_code`, `candidate_number`, `name`, `party_code`, `party_designation`, `party_abbreviation`, `total_preference_votes`, `qualified_by_preference_votes`, `elected`, `elected_electoral_area_code`, `elected_electoral_area_name`, `elected_constituency_code`, `elected_constituency_name`, `order_of_election`, `election_basis`, `substitute_group`, `sex`, `age_on_election_day`, `registered_municipality_name`.
- en full adds: `election_event`, `electoral_area_code`, `electoral_area_name`, `constituency_code`, `constituency_name`, `name_varies`, `name_variants_count`, `electoral_areas_count`, `multiple_electoral_areas`, `multiple_constituencies`, `lists_count`, `multiple_lists`, `parties_count`, `multiple_parties`, `election_types_count`, `multiple_election_types`, `open_list`, `on_name_ballot`, `preference_vote_areas_count`, `election_basis_id`.

- sv standard: `valar`, `valtyp`, `kandidatnummer`, `namn`, `partikod`, `partibeteckning`, `partiforkortning`, `antal_personroster_totalt`, `kvalificerad_personval`, `invald`, `invald_valomradeskod`, `invald_valomradesnamn`, `invald_valkretskod`, `invald_valkretsnamn`, `invalsordning`, `valgrund_text`, `ersattargrupp`, `kon`, `alder_pa_valdagen`, `folkbokforingskommun`.
- sv full adds: `valtillfalle`, `valomradeskod`, `valomradesnamn`, `valkretskod`, `valkretsnamn`, `namn_varierar`, `antal_namn`, `antal_valomraden`, `flera_valomraden`, `flera_valkretsar`, `antal_listor`, `flera_listor`, `antal_partier`, `flera_partier`, `antal_valtyper`, `flera_valtyper`, `oppen_lista`, `pa_namnvalsedel`, `antal_personvalsomraden`, `valgrund_id`.

### `substitutes()`

- en standard: `election_year`, `election_code`, `geographic_level`, `party_code`, `party_designation`, `party_abbreviation`, `member_candidate_number`, `member_name`, `substitute_candidate_number`, `substitute_name`, `substitute_order`, `substitute_group`, `election_basis`, `electoral_area_code`, `electoral_area_name`, `constituency_code`, `constituency_name`.
- en full adds: `election_event`, `election_kind`, `count_stage`, `election_date`, `previous_election_date`, `is_test`, `election_basis_id`, `source_electoral_area_code`, `source_electoral_area_name`.

- sv standard: `valar`, `valtyp`, `geografiniva`, `partikod`, `partibeteckning`, `partiforkortning`, `ledamot_kandidatnummer`, `ledamot_namn`, `ersattare_kandidatnummer`, `ersattare_namn`, `ersattarordning`, `ersattargrupp`, `valgrund_text`, `valomradeskod`, `valomradesnamn`, `valkretskod`, `valkretsnamn`.
- sv full adds: `valtillfalle`, `valklass`, `rakningstillfalle`, `valdatum`, `valdatum_fg`, `test`, `valgrund_id`, `kall_valomradeskod`, `kall_valomradesnamn`.

### `preference_votes()`

- en standard: `election_year`, `election_code`, `geographic_level`, `district_code`, `district_name`, `municipality_code`, `municipality_name`, `county_code`, `county_name`, `municipal_constituency_code`, `municipal_constituency_name`, `preference_vote_area_code`, `preference_vote_area_name`, `party_code`, `party_designation`, `party_abbreviation`, `candidate_number`, `name`, `preference_votes`, `party_votes`, `preference_vote_share`, `qualified_by_preference_votes`, `district_type`.
- en full adds: `election_event`, `count_stage`, `election_date`.

- sv standard: `valar`, `valtyp`, `geografiniva`, `valdistriktskod`, `valdistriktsnamn`, `kommunkod`, `kommunnamn`, `lankod`, `lannamn`, `kommunvalkretskod`, `kommunvalkretsnamn`, `personvalsomradeskod`, `personvalsomradesnamn`, `partikod`, `partibeteckning`, `partiforkortning`, `kandidatnummer`, `namn`, `antal_personroster`, `antal_partiroster`, `andel_personroster`, `kvalificerad_personval`, `valdistriktstyp`.
- sv full adds: `valtillfalle`, `rakningstillfalle`, `valdatum`.


## Qualification-area semantics

`preference_vote_areas_count` retains the established package meaning: count of
areas in which the source reports qualification for person votes. For the single
EU constituency this is1 when qualified and0 when not qualified, independently
of the presence of positive preference votes. It is NA for unlinked small-party
ballot candidates. The initial2009-only implementation erroneously counted all
linked result areas; a targeted regression now checks1/0/NA while retaining the
same vote values. No other year's code or data is changed by this correction.
## Independent control coverage

The executable source validator additionally checks176 SCB national/county
preference controls for the eight mandate parties,866 revised SCB small-party
municipality disclosures,5664 original electorate rows and1983 positive
small-party ordinary-district workbook cells. All68 expanded substitute links
are compared by party, source group, member/substitute names and substitute order,
not merely by total row count.

The separately inventoried SCB historical API's FI/SD preference series contain
zeros where Valmyndigheten reports positive values (553 municipality/category
comparisons). Their interpretation is not established; they are not used as
verified zero controls or to overwrite Valmyndigheten's values. This source
comparison issue is separate from the complete eleven-party Valmyndigheten
preference observations. The source inventory retains the exact API evidence.
## Completed validation run (16 October 2026)

- Final prototype: `.local-data/canonical-build/eu-2009-final-validation-20261016`.
  Fourteen Parquet assets,3,588,007 bytes in total; schema2; all size/SHA256 and
  Parquet round-trip checks pass. Manifest SHA256:
  `412a6f7135ce0a96e747c814ea1765d621a70a55c4adac5ea1c55eb6ac586a22`.
-35 public variants x4 actual language/detail combinations pass canonical/raw
  equality and standard/full projection. All seven actual Swedish wrappers pass.
  District variants contain372699 positive observations or2900988 with source-
  supported zero completion; positive candidate votes sum1876701.
- All500 ballot-position attributes were independently compared with original XML:
  coordinates,generated keys,names/descriptions,age,sex,status and registration.
  Unsupported validity remains NA. The opt-in2009 regression has65 passing
  assertions,zero skips/failures/warnings.
- Original XML,64762 list controls,370716 main-party district records,1983 small-
  party positive district cells,18 elected and68 expanded substitute relations
  pass. SCB5954 district/pooled-collection controls,176 preference controls,
  866 small-party disclosures and5664 electorate records pass.
- Full package suite:3620 passed,15 explicit external-data skips,zero failures,
  errors or warnings. `R CMD check --no-manual --no-vignettes`:0 errors,0 warnings,
  0 notes. Package staging applies `.Rbuildignore` before copying, avoiding Windows
  long-path failures from ignored local archives; installed contents exclude them.
- All1037 protected historical canonical files and all13 original local2009 source
  files remain byte-identical. No raw,SCB,Parquet or Python files are tracked or
  included in the package. `git diff --check` passes.
- A validation-found2009-only qualification-area-count error was corrected. Twelve
  assets remain byte-identical to the earlier prototype. Only the count column in
  candidates (366 rows) andelected (5 rows) changes1 to0; every other column,
  including votes and election relationships,is identical.

The build records base commit `140d1da45dcb0538499f8087666af032ec0236e4` and
`build_tree_dirty=true`, truthfully reflecting the uncommitted implementation.
A clean-commit rebuild remains after review/commit approval; it cannot be claimed
while committing is prohibited. No commit,push,tag or release was made. Existing
uncommitted EU2014 work was preserved.
