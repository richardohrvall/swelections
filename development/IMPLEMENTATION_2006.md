## 2006 implementation and validation

2006 is available from the preserved, hash-verified local source collection,
or from an explicitly configured unpublished canonical prototype. It is not
canonical-auto-eligible and has no published data release. The R-only workflow
uses the existing XML, output-language and standard/full infrastructure.

### Sources and stages

The fixed final election result uses archived named national RD/RF XML and
290 named KF municipality XML files from the preservation documented in
[SOURCE_INVENTORY_2006.md](SOURCE_INVENTORY_2006.md). District-level RD/RF
results additionally use 290/289 official municipality files preserved
separately by `data-raw/preserve-final-2006.R`. Every file records its official
URL, retrieval time, size, MD5 and SHA256 in an ignored source manifest.
The root metadata must identify the final 17 September 2006 election.

Ballot observations come from the preserved nested `valresultat/xml.zip`.
Supplementary other-party preference-vote pages are necessary: the XML's
other-party aggregation alone does not preserve the individual candidate
observations. Archived RD pages retain names; anonymised RF/KF pages do not.
No later membership file is used to redefine the election result.

Only `final` is supported. Preserved election-night material remains source
provenance, not a complete `preliminary` result. The complete preliminary
collection source has not been found. Final collection counts never fill that
gap. No new public count stage is introduced.

### Observation identity and missingness

There is no stable source person identifier. `candidate_number` (Swedish
`kandidatnummer`) for 2006 is a deterministic **package-generated source
observation key**, beginning `2006:<election>:<role>:`. It is not a person ID.
The encoded key preserves official ballot geography, party, list and position,
or the source file and XML path/page row. It is independent of candidate names.

* `candidacies()` contains 153,822 documented geographical ballot-position
  occurrences. Structured candidate names are not fabricated by parsing the
  free-text `ballot_info`; that text is preserved separately.
* `candidates()` retains those ballot observations plus separate official area
  preference-vote, elected-slot and substitute-slot observations. Equal names
  do not imply identity. Its row count is not a count of unique people and is
  not directly comparable with SCB's nominated-person population.
* `elected()` identifies the original appointed slots. `substitutes()` expands
  official group relations into member-by-substitute rows; a raw substitute
  node may therefore occur in several relationship rows.
* `preference_votes()` preserves observed area or district records, with list
  position in full list output. IDs in different source roles/views do not
  assert cross-view person linkage. Non-list and list counts are alternative
  source representations and must not be added together.
* `include_zeros` does not create unobserved 2006 candidate combinations: the
  sources do not verify the required candidate population/linkage. Explicit
  source zeros are retained. Unknown denominators and zero denominators give
  missing shares. Unsupported attributes, person-wide counts and statuses
  remain typed `NA`; positive observed counts are never masked.
* Municipality/region preference-vote aggregation is unavailable for 2006:
  combining the same person's observations across areas would require an
  unsupported identity assertion. Use the original preference-vote areas.

Historical `Definitiv`/`Utkast` ballot status is retained and is not silently
translated to modern printed-ballot `S`/`B`. `on_name_ballot` remains missing.
Candidate registration is recorded at its historical ballot scope; this is
not evidence for a single modern party-area `open_list` status.

RD/RF constituency keys combine the official county/electoral-area and local
constituency codes. KF uses municipality plus municipal constituency code.
Short municipality names are joined using official codes only. Three explicit
KF result-party rows lack a safely recoverable numeric party code; they are
retained with their source designation/abbreviation and `party_code = NA`.
They must not be pooled with the residual other-party category.

### Mandates and known source differences

Allocated mandates are RD 349, RF 1,656, KF 13,092. KF includes 14 explicit
`Kunde ej utses` positions: 13,078 people were appointed. The placeholders
have no candidate key and never appear as elected people. SCB's local mandate
table counts the filled positions, so it is not an allocated-mandate control.

Final detailed preference totals are RD 1,235,601, RF 1,186,237 and KF
1,554,153. The RD detailed source is 4,089 above the separate official/SCB
preference statistic in five constituencies (11: +433; 12: +493; 13: +564;
14: +532; 28: +2,067). The discrepancy is unresolved and does not affect
ordinary party votes. KF's detailed total agrees with SCB but exceeds the
separate Valmyndigheten statistics presentation (1,554,115) by 38. Neither
source is overwritten. The RF SCB wide district table has 102 exact duplicate
rows; the independent validator uses a temporary distinct analytical view,
without modifying the source file.

### Reproduction

From the repository root, with the documented R project dependencies:

```sh
Rscript data-raw/build-canonical-2006.R RAW_ROOT EMPTY_OUTPUT_DIR
Rscript development/validate_canonical_2006.R RAW_ROOT OUTPUT_DIR
Rscript data-raw/validate-scb-2006.R RAW_ROOT
```

`RAW_ROOT` contains `2006/`. The build verifies preserved input hashes before
and after, writes 15 English-schema Parquet assets and `manifest.json`, and
checks lossless Parquet round trips. The manifest records source objects,
source-selection rules, dirty/clean status and Git SHA; data version is the
unpublished prototype identifier `data-v0.0.0`, not a package release.
Source archives, SCB DTA files, caches and generated assets remain outside Git.
See [VALIDATION_2006.md](VALIDATION_2006.md) for executed checks and outstanding limitations.

### Coverage of list and district preference votes

The direct area XML, list XML and district XML agree for their common
candidate coverage: RD 1,147,952; RF 1,167,604; KF 1,543,320 preference votes.
The supplementary other-party pages add RD 87,649, RF 18,633 and KF 10,833
at area level. They do not expose a verified list/district assignment. These
observations therefore appear only in the non-list area view, not as invented
list/district rows or zeros. Summing the complete area view and the narrower
list/district view is not a meaningful equivalence test without restricting
to the common source scope. This differs from the separately documented
RD +4,089 / KF +38 external-statistics discrepancies.
For original appointed relations, the shared historical normalisation treats
RF/KF technical constituency codes ending in `00` as undivided areas. Their
public constituency fields are `NA` in standard and full; the original code
is preserved in the raw XML. No new geographic unit is created from that code.
