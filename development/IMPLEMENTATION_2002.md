# 2002 implementation and source limitations

The 2002 implementation reads preserved official final-election XML and reuses
the established historical XML normalisation and public standard/full and
English/Swedish layers. It does not modify any raw source or older canonical asset.
The source inventory and archived Orsa evidence are in
[SOURCE_INVENTORY_2002.md](SOURCE_INVENTORY_2002.md).

## Source selection and election occasions

The national `slutresultat_00R.xml`, `slutresultat_00L.xml` and
`slutresultat_00K.xml` exports were recovered from January 2003 captures. They
explicitly describe the ordinary 15 September 2002 election. Municipal exports
prefer pre-rerun captures; later captures are used only where an earlier export
was not indexed, with source occasion/stage metadata verified separately from
capture date. All selected source bytes, retrieval/capture metadata and hashes
are recorded in the local source-selection registry and build manifest.

Orsa uses the pinned original final XML (MD5
`3249b5428225a4e6d0c77dbcd1d17340`), never the March 2003 rerun. The reader rejects
a wrong Orsa municipal snapshot and any national file that embeds the rerun's
4,303 valid / 4,316 cast votes. The ordinary result is 4,009 valid / 4,070 cast.
Original national KF totals are 5,312,977 valid / 96,878 invalid / 5,409,855 cast.
The annulled original result remains distinct from the subsequent election;
no general re-election API or new election-occasion schema is introduced here.

## Supported scope and conservative missingness

- Final results retain direct party rows and the source's other-party partition.
  Smaller/local parties are retained where explicitly identified. A numeric
  party code is not invented where the source does not establish one.
- Mandates and appointed/substitute relationships come from final election
  XML. `Kunde ej utses` marks an unfilled allocated position, not a person.
  Later mandate-period membership material is not used.
- Preference-vote views retain individually observed source records. Area and
  district structures are separate views; nested list rows are not added to
  area candidate totals. Source disagreements remain validation findings.
- Combined `OG` is total invalid votes. The sources do not establish separate
  blank and other-invalid counts; those public fields remain typed missing.
- Unsupported fields, electoral registration/ballot status and candidate
  attributes are not filled from SCB or guessed from names or result lists.

A geographic view requires complete preserved source coverage. Missing municipal
exports produce an informative error, never a partial table presented as a
complete election. Build manifests record unavailable levels/views explicitly.

Final RD/RF collection districts are municipality children in the 2002 XML;
KF collections are constituency children. The year-specific selector includes
both placements exactly once. Known cast totals can be reconstructed as valid
plus combined `OG` without turning genuinely missing categories into zero.
The three unrecovered RD municipality exports are supplemented for final party
results only by independently reconciled SCB/SND district data. Aggregate RD
coverage continues to use the authoritative national Valmyndigheten export.

The partial official other-party supplement documents a technical reporting
limitation for four RD parties. Original XML detail is preserved, not described
as fully corrected and not silently reconciled with the partial supplement.
See [the validation report](VALIDATION_2002.md) for exact measures and limits.

## Candidate identity and population

No stable source person identifier has been established. Package-generated
`2002:<election>:<role>:<source/path>` keys identify XML source observations.
They must not be used to link people across lists, areas or RD/RF/KF. Equal names
are not joined. Area, list and appointed-slot records are distinct source roles.

`candidates()` represents available area preference and original appointed/
substitute observations. It is not a complete nominated-person population.
Candidacy-count attributes that cannot be established from these observations
are missing. Some source party totals include preference votes without
individually reported candidate records; no candidate is fabricated for them.
Observed candidate votes are preserved; an unknown source-observation total is
not replaced by zero. Person-linked broader area aggregation is unsupported.
`include_zeros` cannot create unsupported unobserved candidate combinations.

Current public 2002 pages redact names. Public names are therefore typed missing
even when a preserved historical XML retains names; archival names remain local
source/provenance material. No separate name lookup or name-based identifier
crosswalk is created.

A complete ballot-candidacy register has not been recovered. `candidacies()`
does not advertise 2002 support, and no empty or invented candidacy asset is
created merely to complete seven asset families. Result-list presence is not
proof of a printed name ballot or a complete ballot population.

## Counting stages

Only final 2002 results are implemented. The recovered Orsa election-night
HTML/text/XML covers its five ordinary districts and remains provenance.
No verified preliminary collection-district results have been recovered for
2002. This is a **source/recovery limitation**, not evidence that Valmyndigheten
never produced preliminary results. Final collection figures are not substituted;
election night is not silently relabelled as complete `preliminary`, and no
new public `election_night` value is introduced.

## Reproduction and validation

Run these commands from the repository with the documented R development
libraries and a configured raw archive (paths below are caller-selected):

```r
# Shell: Rscript data-raw/preserve-final-2002.R RAW_ROOT RD,RF,KF
# Shell: Rscript data-raw/build-canonical-2002.R RAW_ROOT EMPTY_OUTPUT_DIR
```

`source = "local"`/`"auto"` require the preserved final source-selection registry.
`source = "remote"` is not a live shortcut to the current, rerun-contaminated
presentation. Explicit `source = "canonical"` requires a configured local
unpublished manifest; no 2002 release or automatic canonical eligibility is added.

Builds verify source checksums, store English canonical names, preserve typed
missingness, record Git SHA/dirty status and verify every Parquet round trip.
SCB's local district-party data and cached official statistics are independent
validation inputs; only the three missing RD municipal exports use the explicitly
verified SCB/SND complementary result route described below. SCB's current KF data include the Orsa rerun: ordinary
Orsa must be checked against its recovered original source and SND separately.
Source/control differences must be documented, not reconciled by changing votes.

Final validation results and any unresolved source differences are recorded in
`VALIDATION_2002.md` after the source-backed checks complete. No release, tag,
commit or push is part of this implementation stage.

## Official four-party supplement integration

The result reader now applies the byte-verified official RD supplement, scoped
only to national, constituency and county result breakdowns. Explicit unknown
cells remain unknown and inside the numeric residual other-party total.
See [SUPPLEMENT_2002.md](SUPPLEMENT_2002.md) for source provenance, exact coverage,
missingness, validation and the absence of lower-level allocation. This supersedes
any earlier description of the supplement as unapplied. Candidate, preference,
mandate and elected/substitute readers are unchanged.

## Verified complementary RD results: Halmstad, Laholm and Kungsbacka

Valmyndigheten remains authoritative wherever its result source is available.
Only the missing `slutresultat_1380R.xml`, `slutresultat_1381R.xml` and
`slutresultat_1384R.xml` result views use complementary SCB-derived district-party
cells and SND RD version 2.1 district controls. A recovered Valmyndigheten export
always takes priority. Every municipality's party/category, valid, invalid and
cast totals must independently reconcile with the national Valmyndigheten XML;
every district is checked against SND. Changed source bytes or failed controls
cause an error, rather than a partial or guessed result.

The local route requires the optional R package `haven` and the preserved files
`scb/valres_parti_valdistr2002_ri.dta` and `snd/snd0237-10-3.zip`. Reading canonical
Parquet does not require `haven`. Pins and build provenance distinguish providers:

| Source | MD5 | SHA256 |
| --- | --- | --- |
| SCB-derived district-party DTA | `4d914f7a4b6ed159dc0736df8b94be27` | `e834e5de6a9befe93be2183ca05f991c5758c8832b1de56b1031a5fc2365f730` |
| SND RD ZIP | `ac27fa12700498899791abb58290596f` | `47a4b1288efa238d5bc90149ff8d9e387d504484a0da37ada78f2b1e84b607d6` |

The manifest's `complementary_results` records missing exports, provider files,
sizes/checksums, extracted SND member checksum, authoritative geography sources,
reconciliation scope and both source-specific electorate counts. Original XML
provenance remains in `sources`; complementary files are not presented as XML.
No extra public schema columns are introduced.

| Municipality | Ordinary districts | Postal unit | Valid | Invalid | Cast | SCB/SND eligible | VM eligible |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1380 Halmstad | 49 | 1 | 52,342 | 1,028 | 53,370 | 66,542 | 66,542 |
| 1381 Laholm | 15 | 1 | 13,404 | 289 | 13,693 | 17,313 | 17,313 |
| 1384 Kungsbacka | 37 | 1 | 40,439 | 553 | 40,992 | 48,602 | 48,603 |

SCB postal codes `13809800`, `13819800`, `13849800` identify the returned
complementary collection units. SND's `99999997` is contextual to each
municipality, not a globally unique district. These are not asserted to be
identifiers from the missing RD XML. Postal votes remain unassigned to municipal
constituencies. Ordinary assignments come from the same-election KF XML geography
and are independently corroborated by SND. Halmstad and Kungsbacka each have two
public municipal constituencies; Laholm's technical undivided `138100` remains
outside the public municipal-constituency observation set, following the existing
geographic rule. No postal votes are distributed across those constituencies.

Turnout uses the denominator from the same source as the result observations.
Postal units have an explicitly reported electorate of zero and undefined
turnout; zero does not become a zero turnout. Kungsbacka's distinct electorate
values are preserved, never reconciled by changing either source.

Final party results have complete voting-district and municipality coverage,
including Halmstad, Laholm and Kungsbacka, supported smaller-party detail and
residual other-party votes. Combined invalid votes are reported; separate blank
and other-invalid counts remain missing. District candidate/list/person-vote
information, original RD collection XML metadata, timestamps and previous-election
comparison values are not reconstructed. Area-level observed preference-vote
records and all existing candidate/mandate relationships remain unchanged.
The absence of verified person identity never discards a source-level preference
observation. No SCB/SND candidate records are fabricated.

Independent opt-in validation:
`Rscript data-raw/validate-complement-2002.R RAW_ROOT`.
