# R-only workflow migration

## Audited 2022 preparation contract

The former `prepare-canonical-2022.py` takes the preserved source root, a
derived staging root and a directory of hash-verified official corrections.
It does not overwrite raw sources. Its complete preparation contract is:

- Inventory candidate snapshots in filename order; select only
  `kandidaturer_20241218.csv`, MD5 `639daa9630a1f2554f1c6839473448ee`.
- Iterate the 622 `Val_*_mandatfordelning_*.json` files in filename order,
  pairing each with its `rostfordelning` JSON. Preserve source bytes unless
  an explicitly approved correction applies.
- Record original JSON, candidate snapshots and any `_sign.sha256` files
  with size, MD5 and SHA256. Signature files are signatures, not checksums.
- For final KF 0136/1439/1860/2506, take the two result JSON members from
  the separately verified official corrected ZIPs. Retain both generations
  in provenance, marking the selected generation.
- For final RF 25, pin original mandate/district MD5s respectively to
  `ea31f87d4172ad787258cfe5790b4ff6` and
  `8ae8a7f37467daee7c5fcd408dcaa10b`. Traverse objects in source order and
  arrays in index order. Change only typed `kandidatNummer`/`kandidatnummer`
  values 50975 to 488 under party 0110; mixed-case `kandidatNummer` additionally
  requires list 0110-03652. Preserve the original scalar type. Require exactly
  two mandate and 95 district changes; record zero-based JSON paths, original
  and derived hashes, decision 201-11278-2022 (2022-11-14), and its protocol URL.
  The original election-time elected/substitute relationships remain intact.
- Write derived result ZIPs under `2022/val2022/{p,s}/{rd,rf,kf}` with mandate
  JSON first and district JSON second, using DEFLATE and a fixed 2022-09-11
  timestamp. Write an ordered `index.md5` with `  ./` relative paths and LF.
- Put the selected candidate CSV, unchanged, in `parti/kandidaturer.zip`.
  The old script uses a **wall-clock timestamp for this ZIP member**: this
  container was not byte-reproducible even within the old workflow.
- Write source/harmonisation provenance, original-source hashes and staging
  paths. The old provenance JSON uses UTF-8, two-space indentation and no final
  newline; transformed result JSON uses compact UTF-8 JSON with unescaped
  non-ASCII characters and Python's numeric serialisation.
- Independently validate 1,234 preserved members byte-for-byte, eight corrected
  members byte-for-byte, two reconstructed members as parsed JSON, and the
  extracted candidate CSV hash. Require all 622 containers.

ZIP implementation metadata, compression and JSON serialisation are technical
representations, not electoral values. The R migration must report their
differences, demonstrate repeated R builds are deterministic, and separately
compare extracted JSON/CSV and all canonical Parquet tables to the pinned
reference. A source-generation difference is never silently accepted.

The R ZIP writer uses the R `zip` library at compression level 6. Unlike the
old writer it marks ASCII member names with the UTF-8 flag; its compressor
also produces different compressed streams. Both local and central DOS
timestamps are explicitly fixed to 2022-09-11 00:00:00, avoiding Windows
system-timezone behaviour. Candidate timestamps are now fixed too. Member
order, filenames, CRC-protected extracted content and source selection are
validated separately; new index hashes honestly describe the new containers.
The two reconstructed JSON files use `jsonlite`, preserving exact numeric
values with `digits=NA`; integral-valued doubles may be written as `1` rather
than `1.0`. JSON numeric storage is compared with zero tolerance, and canonical
column types/values must still match the previous Parquet assets exactly.

## Git-state constraint

This refactoring is explicitly not authorised for commit. Consequently a
build of the replacement code cannot truthfully have `build_tree_dirty=false`
at the current HEAD. Validation builds record the real dirty state and exact
build-code hashes. A clean committed rebuild remains required after review;
no synthetic commit or misleading clean-build metadata is created.

## Independent development tools

The reproducible workflow uses R throughout. Required development libraries
are already present in the project toolchain: `xml2`, `jsonlite`, `digest`,
`readr`, `stringr`, `curl`, `readxl`, `zip`, `pkgload`, `nanoparquet` and
`testthat`. None is a new Python or package-runtime requirement.

| Former tool | R tool / disposition | Role |
| --- | --- | --- |
| `prepare-canonical-2022.py` | `data-raw/prepare-canonical-2022.R` | Pinned staging and scoped Norrbotten reconstruction |
| `build_party_identifiers_2010.py` | `development/build_party_identifiers_2010.R` | Prior-election party identity metadata only |
| `preserve_preliminary_2010_conservative.py` | `development/preserve_preliminary_2010_conservative.R` | Sequential acquisition, immutable cache, hashes, rate-limit backoff |
| `validate_preliminary_2010_preserved.py` | `development/validate_preliminary_2010_preserved.R` | Independent HTML/XML reconstruction and published aggregate comparisons |
| `validate_sources_2010.py` | `development/validate_sources_2010.R` | Independent final XML/SKV/Excel relationships and vote validation |
| `diagnose_2022_rd_person_votes.py` | `development/diagnose_2022_rd_person_votes.R` | Independent raw traces of the retained 14-combination / 15-vote discrepancy |
| `retrieve_preliminary_2010.py` | Retired | Superseded parallel retriever; R conservative retrieval also covers its aggregate pages |
| `assess_preliminary_2010_candidate_information.py` | Retired | Completed one-off investigation, not a build input; preliminary HTML supplies party results, not additional candidate-identified votes |

`development/source_tools.R` contains independent I/O and counters only; it
does not call production XML/JSON normalisers. Existing machine-readable
reports are optional regression references, not inputs required to perform
the corresponding source checks. The R output/Excel export scripts remain
the producers of comparison data.

Run development scripts from the repository root with the project R library:

Install the listed R development packages into the R library used by the
project. When using the private `.r-lib` library, use this invocation pattern
instead of plain `Rscript SCRIPT ...`; arguments still reach the sourced script:

```sh
Rscript -e '.libPaths(c(".r-lib", .libPaths())); source("development/validate_sources_2010.R")' RAW_ROOT OUTPUT_JSON REPORT_JSON
```

```sh
Rscript development/test_r_only_preparation.R
Rscript development/test_source_retrieval.R
Rscript development/build_party_identifiers_2010.R .local-data/rkl NEW_OUTPUT_DIR
Rscript development/preserve_preliminary_2010_conservative.R RAW_RESULT_DIR NEW_OUTPUT_DIR
Rscript development/preserve_preliminary_2010_conservative.R RAW_RESULT_DIR UNUSED_OUTPUT --verify-cache
Rscript development/validate_preliminary_2010_preserved.R
Rscript development/export_mandate_validation_2010.R
Rscript development/export_source_validation_2010.R ARCHIVE_ROOT NEW_OUTPUT_JSON
Rscript development/validate_sources_2010.R RAW_ROOT NEW_OUTPUT_JSON REPORT_JSON
Rscript development/audit_canonical_2022_aggregates.R CANONICAL_DIR
Rscript development/diagnose_2022_rd_person_votes.R SOURCE_ROOT AUDIT_JSON REPORT_JSON
```

Acquisition is deliberately sequential. It reuses hash-validated cached
responses, delays requests by 1.5 seconds, uses a 90-second timeout and at
most three attempts, waits at least 120/240 seconds after rate limiting and
stops after three rate-limit responses. Existing archived responses are
never overwritten. An interrupted R acquisition can resume only its own
registered, hash-validated output directory. Completely blank preliminary
vote fields remain source missingness and are never filled from final XML.

## Migration validation

- The relevant 2022 regression reference is
  `.local-data/canonical-build/2022-local-v0.2.0-elected-scope`, documented in
  `CANONICAL_2022_BUILD_VALIDATION.md`. The older `*-final` directory predates
  the approved KF elected-enrichment correction. Its three vote-total cells
  and one area-count cell therefore differ from current code; this is not an
  R migration difference. Against the corrected reference, **all 24 rebuilt
  Parquet assets are byte-identical**, with identical values, schemas and types.
- R staging validates 623 containers / 1,245 extracted members: 1,234 original
  result members and eight corrected KF members are byte-identical; the two
  Norrbotten JSON members differ only in serialization and match as parsed
  JSON with zero numerical tolerance; the candidate CSV is unchanged. The
  scoped correction remains exactly two mandate and 95 district attributes.
- Two complete R preparations produce byte-identical 623-container archives.
  The tools used here are R 4.6.1, `zip` 3.0.2 and `jsonlite` 2.0.0.
- The 2010 party lookup has 2,608 rows and is byte-identical to the preserved
  lookup: SHA256 `60c34cb6b1e7a2662e2cc641cbe806a3c9eefb5f0c02bbb041885d9d710635c4`.
- Independent final XML/SKV/Excel checks reproduce the previous 2010 report
  for RD/RF/KF, including the documented later re-election Excel differences.
  A new R export reproduces all checked actual-output relations, vote posts
  and counts, so the validator does not require an undocumented old export.
- Independent preliminary checks reproduce all 1,067 comparisons; immutable
  cache checks cover 395 RD / 392 RF / 395 KF collections without HTTP calls.
  The 18 unreported districts, 722 partial pages and 4,213 blank count cells
  remain unchanged. Final-count collection values are not substituted.
- The R-only 2022 diagnostic reproduces the known 14-combination / 15-vote
  area/district discrepancy exactly, without reconciliation.
- All seven 2022 functions pass direct public/raw checks, including the
  preliminary/final result and seat levels, all 24 preference-vote views,
  broader RF/KF aggregation, standard/full and English/Swedish projections.
  Mixed elected/substitute requests, reversed RF/RD order and mixed
  preference-vote ordering pass. Candidate identity-only views match for
  6,168 RD / 12,644 RF / 52,001 KF keys (70,813 combined); mixed candidacies
  have 170,781 rows. Valid-candidacy coverage and elected/substitute references
  agree. Public main-level unfilled-seat totals remain RD 0 / RF 0 / KF 17;
  the multi-level stored seat asset must not be summed across levels.
- Sixteen preparation assertions and 14 simulated HTTP-policy assertions
  pass, without network access. The package suite has 3,198 passes, zero
  failures/warnings and ten explicit opt-in skips. The current package sources
  match the isolated check source tree byte-for-byte (156 files);
  `R CMD check --no-manual --no-vignettes` has zero errors, warnings or notes.
- The protected 2010/2014/2018/2022 reference assets/manifests remain unchanged.
  Final integrity checks also verify all 2,497 original-source SHA256 entries
  and the build-code hashes in the new 2022 lineage. The split public/raw
  reports contain 41, 44 and four PASS blocks, with no unresolved diagnostics;
  five additional identity-only/mixed-candidacy checks also pass.
  No production `R/` code, public schema, election value or candidate-identity
  rule is modified. No commit, push or release is made.

Detailed ignored audit outputs and logs use `.local-data/r-only-*`; the new
unpublished prototype is `.local-data/canonical-build/2022-r-only-validation`.
Its manifest records HEAD `09048a6c3a28ff10d4d74cc0b7a9b95fffff9a3d`, real
`build_tree_dirty=true`, the R staging lineage and exact build-code checksums.

## Reviewed change inventory

No files in production `R/`, installed-package tests, `DESCRIPTION` or
`NAMESPACE` change. No raw source or published canonical asset is changed.

Updated paths:

- `AGENTS.md`
- `data-raw/build-canonical-2022.R`
- `development/CANONICAL_DATA.md`
- `development/CANONICAL_2022_BUILD_VALIDATION.md`
- `development/IMPLEMENTATION_2010_VALIDATION.md`
- `development/PRELIMINARY_2010_SOURCE_RETRIEVAL.md`
- `development/export_mandate_validation_2010.R`
- `development/validate_canonical_2022.R`

New paths:

- `data-raw/prepare-canonical-2022.R`
- `development/R_ONLY_WORKFLOW.md`
- `development/source_tools.R`
- `development/build_party_identifiers_2010.R`
- `development/preserve_preliminary_2010_conservative.R`
- `development/validate_preliminary_2010_preserved.R`
- `development/validate_sources_2010.R`
- `development/export_source_validation_2010.R`
- `development/diagnose_2022_rd_person_votes.R`
- `development/test_r_only_preparation.R`
- `development/test_source_retrieval.R`
- `development/validate_r_only_2022.R`
- `development/compare_r_only_assets.R`

The eight former `.py` paths listed in the tool table are removed. Six have
validated R replacements and two are deliberately retired. Historical report
references retain their provenance meaning; none is an executable dependency.
