# Proposed English canonical schema for RKL 2018

This is a schema proposal, not a rebuilt data distribution. The existing
Parquet assets, asset names, manifest, exporter and reader still use the
prototype's Swedish columns. Do not publish a new canonical collection until
the open decisions below and the English export/read migration are resolved.

## Analysis-facing tables

`R/output_names.R` is the complete, executable Swedish-to-English mapping for
the seven public analysis families: `results()`, `seats()`, `candidacies()`,
`candidates()`, `elected()`, `substitutes()` and `preference_votes()`. It covers
117 explicit base names and 36 derived public names across the frozen schemas.
The established column order, types, observation units, keys, values and
`NA`/zero/`FALSE` semantics remain unchanged by the name translation.

The following names are fixed for the proposed canonical analysis tables:

| Swedish source/public field | English canonical field | Meaning |
|---|---|---|
| `valtyp` | `election_code` | Official `RD`, `RF` or `KF` value; no redundant `election_type` column. |
| `valklass` | `election_kind` | Ordinary election, re-election, extra election, etc.; the source text value is unchanged. |
| `antal_tomma_stolar` | `unfilled_seats` | Seats unfilled after the election, not later vacancies. |
| `personvalsomradeskod`, `personvalsomradesnamn` | `preference_vote_area_code`, `preference_vote_area_name` | The area in which preference votes are evaluated. |
| `antal_personroster`, `antal_personroster_totalt` | `preference_votes`, `total_preference_votes` | Area/district value and candidate total respectively. |
| `andel_personroster`, `andel_personroster_lista` | `preference_vote_share`, `list_preference_vote_share` | Proportions on the 0–1 scale, with party/list votes as the respective denominator. |
| `kvalificerad_personval`, `antal_personvalsomraden` | `qualified_by_preference_votes`, `preference_vote_areas_count` | Preference-vote qualification and count of relevant areas. |
| `invalsordning`, `ordningsnummer` | `order_of_election`, `party_order` | Official election order and party row order. |
| `anmalda_kandidater`, `forklaring` | `candidates_registered`, `candidate_declaration` | Source-derived logical candidacy fields; retain unknown/irrelevant states. |
| `valsedelsuppgift` | `ballot_info` | Optional candidate-identification text printed on the ballot, for example occupation or age. |
| `antal_valsedlar_lista` | `list_ballots_ordered` | Ballot papers ordered for the specific list, not votes cast. |
| `valkretsbeteckning_pa_valsedeln` | `ballot_constituency_label` | Constituency label on the ballot. |
| `senaste_uppdateringstid`, `senaste_uppdateringstid_omrade` | `source_last_update_time`, `area_last_update_time` | Root and area metadata respectively. |
| `antal_valdistrikt_raknade`, `antal_valdistrikt_som_ska_raknas` | `overall_districts_counted`, `overall_districts_to_count` | Root totals. |
| `antal_valdistrikt_raknade_omrade`, `antal_valdistrikt_som_ska_raknas_omrade` | `area_districts_counted`, `area_districts_to_count` | Area totals. |
| `roster_ej_anmalt_deltagande`, `andel_ej_anmalt_deltagande` | `votes_no_participation_notice`, `vote_share_no_participation_notice` | Absence of a participation notice, not necessarily absence of party registration. |
| `folkbokforingskommun` | `registered_municipality_name` | Source-supplied municipality name, never a municipality code. |

`valdel` remains `turnout`; `valgrund_text` remains `election_basis` and
`valgrund_id` remains `election_basis_id`; `pa_namnvalsedel` remains
`on_name_ballot`; `status_jamforelse` remains `comparison_status`, referring
to comparison with the preceding election. All other explicit names remain
as given in `R/output_names.R`.

The English API accepts `election = "parliamentary"`, `"regional"` or
`"municipal"` and maps these centrally to `RD`, `RF` or `KF` before calling
the Swedish implementation. It also accepts the official codes directly.
Swedish functions continue to use `val = "RD"`/`"RF"`/`"KF"`. This is an
argument-value mapping only: the canonical field is `election_code`, and
the output values remain the official codes. No `election_type` column is
added and no `election_kind` source values are translated.

The generative naming rule is unchanged: each `*_fg` field uses `previous_`
before its translated base name, and each `diff_*` field uses `_change` after
the translated base name. For example,
`roster_ej_anmalt_deltagande_fg` becomes
`previous_votes_no_participation_notice`, and
`diff_roster_ej_anmalt_deltagande` becomes
`votes_no_participation_notice_change`. Share changes are arithmetic
differences between proportions, not relative percentage changes.

All identifier codes remain character fields so leading zeroes survive.
Changing column language never translates party or geographic name values.

## Normalised preference-vote bases

The five current components are `geo`, `parti`, `lista`, `roster` and
`listroster`. Their **shared concepts** must use precisely the same English
fields as the analysis tables: for example `valtyp` → `election_code`,
`personvalsomradeskod` → `preference_vote_area_code`, `partikod` →
`party_code`, `kandidatnummer` → `candidate_number`,
`antal_personroster` → `preference_votes`, `antal_partiroster` →
`party_votes`, `antal_listroster` → `list_votes`, and all geographic pairs
through the same central map. No separate English vocabulary is introduced
for a concept merely because it occurs in a base component.

Only these current base-specific fields need their own definitions:

| Current field | Proposed English field | Definition |
|---|---|---|
| `node_id` | `node_id` | Build-generated integer that links components of one parsed XML node; not an official geographic code or source identifier. |
| `parti_complete` | `party_complete` | Boolean used by the verified-zero reconstruction for a party node. |
| `list_complete` | `list_complete` | Boolean used by the verified-zero reconstruction for a list node. |

The technical discriminator columns `.table`, `.component` and
`.person_view` are separate from analysis columns. Their column names are
already English; the `.component` **values** are currently Swedish and need
an explicit migration/compatibility decision before rebuilding. Asset
filenames are unchanged in this proposal.

## Evidence and outstanding decision

The archived local 2018 candidate snapshot has 184,197 rows. Its
`FOLKBOKFÖRINGSORT` has 180,945 nonempty values, none numeric. The 291
distinct text values comprise municipality names and the source marker
`[saknas i folkbokföringen]`. The inspected 2022 candidate snapshot and
2026 candidate CSV likewise have municipality names, not four-digit codes
(169,985 and 175,236 nonempty values respectively). The parser copies the
2018 source field directly to the Swedish `folkbokforingskommun` column.
Preserving the literal missing-value marker versus normalising it to `NA`
is a separate data-value decision; this naming proposal does not alter it.

The inspected local 2026 candidate CSV has the field `ANTAL VALSEDLAR FÖR
DEN SPECIFIKA LISTAN`. All 173,196 rows with printed-ballot status `S`
contain a positive integer count; it is constant within each of 7,174
observed election-area/constituency/party/list keys. The 5,134 rows without
ballot status have no count. Valmyndigheten's 2018 description explicitly
calls the corresponding field the number of *ordered* ballot papers, and
the 2026 description presents the same field in the ballot-order context.
Together these support `list_ballots_ordered`; this is an inference from the
official descriptions and the inspected source structure, not a new vote
measure.

Valmyndigheten defines `valklass` as ordinary election, re-election or
extra election. Each of the four inspected preliminary 2026 snapshot ZIPs
has `valklass = "ordinarie val"`; the fixtures also use `"ordinarie"` or
`"Ordinarie"`. The approved `election_kind` name distinguishes this
classification from the official `election_code`. Source values are not
translated. The English `preference_votes()` API now uses
`level = "preference_vote_area"` for the unchanged Swedish level
`"personvalsomrade"`; the unreleased `"personal_vote_area"` spelling is
not supported.

Official source descriptions:
- https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-val-2026
- https://historik.val.se/val/val2018/statistik/
- https://www.val.se/english/running-in-elections/running-for-office

The existing prototype export script writes Swedish columns to Parquet and
to the manifest; its reader expects them. Rebuilding the canonical assets
therefore requires a coordinated exporter, manifest, base-component and
reader migration. This document does not
perform that migration or modify any existing Parquet file.
