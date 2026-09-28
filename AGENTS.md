# AGENTS.md

## Project purpose

This repository contains the R package `swelections`, which downloads, archives, parses, harmonises, validates and exposes Swedish election data from Valmyndigheten.

The package covers current and historical Swedish elections. Current development includes the 2026 result-file architecture and canonical historical data, beginning with 2018.

The package is intended to be analysis-friendly for researchers and other users. Canonical datasets should also be usable independently of R and the package. Preserve information from Valmyndigheten where useful, but do not over-normalise the public datasets.

## Repository scope

- Work only inside this repository unless the user explicitly instructs otherwise.
- Do not read, modify, create, move or delete files outside the repository root unless explicitly asked.
- Do not access Dropbox, OneDrive, other project directories, the user's home directory, or unrelated repositories unless explicitly asked.
- Raw election data are kept outside this Git repository.
- The default local raw-data archive used during development is `C:/valdata`, but do not assume that path in package code.
- Do not write to, update, archive, move or delete files in `C:/valdata` unless the user explicitly asks for a task that requires it.
- If access to local raw data is explicitly needed, prefer read-only use unless the task specifically concerns downloading, updating or archiving raw files.
- Never copy raw election ZIP/JSON/CSV files into the Git repository unless explicitly instructed.

`AGENTS.md` is an instruction file, not a security boundary. Respect the actual filesystem permissions and stay within the granted scope.

## Safety and change discipline

- Do not run destructive commands outside the repository.
- Do not delete repository files unless they are clearly generated files or deletion is explicitly requested.
- Do not silently change the package data model, observations units, naming conventions or public API.
- If a task appears to require a conceptual change to the data model or public API, explain the proposed change and ask for approval before implementing it.
- Prefer small, reviewable changes over broad rewrites.
- Preserve already validated behaviour unless there is a clear bug or an approved design change.

## Language and naming

- Package code is in R.
- Use `snake_case`.
- The canonical public data schema uses English column names.
- English is the default naming language for the future public package API.
- Swedish column names may be exposed through an explicit translation layer in R, for example through a function argument or package option.
- Do not mechanically rename existing public columns or functions unless the task explicitly includes an approved schema/API migration.
- Existing Swedish public functions may remain as aliases when English API names are introduced.
- Internal parsing and build code may retain source-oriented or existing Swedish names where that reduces unnecessary churn; translate systematically at the canonical/public boundary.
- Language-dependent data values should be stored explicitly where relevant, for example `party_name_sv` and `party_name_en`, rather than changing values according to a global language setting.
- Use an English party name only when an established English name is available; otherwise use `NA`. Do not invent translations.
- Identifiers and codes must retain leading zeroes and should use stable types.
- Preserve the distinction between `NA`, zero and `FALSE`.
- Prefer compact, descriptive names and stable semantics over literal translations of source-field names.

## R style

- Prefer modern tidyverse/dplyr syntax.
- Prefer the native pipe `|>`.
- Prefer `.by =` where it makes code clearer.
- Prefer `join_by()` for joins.
- Do not use deprecated dplyr syntax.
- In `case_when()`, use `.default` rather than a final `TRUE ~ ...` branch.
- Use `recode_values()` rather than deprecated `case_match()` where appropriate.
- Use formula syntax with `recode_values()`, e.g. `"ja" ~ TRUE`.
- Avoid unnecessary namespace prefixes in analysis examples, but package/internal code may use explicit namespaces where helpful.
- Keep parentheses on the same line when practical.
- Avoid unnecessary line breaks.
- Do not create list-columns in final analysis-facing outputs unless the data model explicitly requires them.
- Use typed `NA` values consistently.

Utility helpers already exist for scalar extraction:
- `as_chr_na()`
- `as_int_na()`
- `as_dbl_na()`
- `as_lgl_na()`

Reuse them rather than inventing parallel helpers unless there is a strong reason.


## Canonical data

Canonical data are a public, language-independent data product, not merely an internal R-package cache.

- Canonical tabular assets use Parquet.
- Canonical public column names use English `snake_case`.
- Canonical assets must be usable independently of the R package, including from tools such as Python, DuckDB and Polars.
- The R package may translate canonical English names to Swedish names as an explicit presentation/API layer; this must not change the stored canonical schema.
- Preserve stable observation units, identifiers, types, keys and missing-value semantics.
- Do not inflate sparse structures unnecessarily. For example, small normalised person-vote bases may be preferable to storing national zero-filled panels when equivalent analysis views can be reconstructed deterministically.
- Do not include raw source files in the Git repository or canonical release assets.
- Do not expose personal names in canonical public assets unless explicitly approved for that dataset.
- Canonical build metadata and provenance should include source filenames and checksums, data/schema version, build code version or Git SHA, build date/time, and whether the build tree was dirty.
- Large generated canonical assets remain outside Git and are distributed separately, for example as versioned GitHub Release assets.
- RDS may be used as a local build intermediate but is not the canonical public format.
- Do not create duplicate CSV or DTA distributions unless explicitly requested.
- `nanoparquet` may be used as an optional dependency for Parquet I/O; do not make Parquet support a mandatory dependency for users who do not use canonical-data functionality unless explicitly approved.
- The existing public `source` API (`local`, `remote`, `auto`) is separate from canonical-data access. Do not add or change a canonical source mode without an explicit API decision.
- Do not change the canonical schema, asset partitioning or release contract without an explicit approved schema decision.

## Core data model

### `valresultat`

One row represents:

`election × geographic area × party/category`

The table may contain repeated area-level totals/context because the package prioritises analysis convenience over strict database normalisation.

The same general schema should work for preliminary and final results where possible.

Use `rakningstillfalle` to distinguish preliminary and final counting.

### `mandat`

Keep mandate data separate from `valresultat` because the observation level differs.

`antal_tomma_stolar` belongs in `mandat`, not in candidate data.

### `valdistriktskoppling`

Connections between current and previous election districts belong in a separate helper table.

Do not place list-valued previous-district links in `valresultat`.

### `kandidaturer`

Detailed source-oriented data about how a person stands for election.

Keep information such as:
- election type
- election area
- constituency
- party
- list number
- position/order on the ballot
- exact source name
- consent/status information
- validity

Preserve invalid candidacies in `kandidaturer`.

### `kandidater`

Analysis-friendly candidate table.

Current intended observation level:

`kandidatnummer × valtyp × partikod`

A person may therefore occur on multiple rows if they:
- stand at several political levels, or
- stand for more than one party.

`kandidater` is built from valid candidacies.

It may contain analysis-friendly summaries such as:
- one normalised display name
- `namn_varierar`
- sex
- age on election day
- municipality of registration
- number of electoral areas
- number of constituencies
- number of lists
- indicators for multiple parties/levels
- total personal votes
- qualification for personal election
- elected status
- elected constituency
- order of election
- basis for election (`valgrund`)
- substitute group

Do not choose a single "main party" for multi-party candidates.

### Candidate names

The exact source name belongs in `kandidaturer`.

For the analysis-facing `kandidater` table:
- normalise whitespace
- simple `"Surname, Given name"` forms may be converted to `"Given name Surname"`
- do not silently correct spelling differences
- do not replace aliases/joke names with guessed legal names
- if several normalised names remain, use a deterministic rule and retain `namn_varierar`

### `valda()`

`valda()` should be a convenient filtered view of `kandidater()` where `invald == TRUE`, not a separately maintained candidate dataset.

### `ersattare`

Substitute relationships are sufficiently special to have their own table.

Preserve the relation between:
- elected member
- substitute
- substitute order
- substitute group
- basis for election

Do not reduce this to a simple `ersattare = TRUE` flag in `kandidater`, because that would lose the relationship structure.

## Person votes

Final vote-distribution files contain three useful levels:
- `listroster`
- `personroster`
- `personroster_summerade`

Keep all three for now.

Interpretation:
- `listroster`: list-level votes
- `personroster`: candidate × list × district
- `personroster_summerade`: candidate × district, summed over lists

`personroster_summerade` is useful both analytically and for validation.

In `kandidater`, use:
- `antal_personroster_totalt` for total personal votes summed over relevant detailed result rows
- `kvalificerad_personval`
- `antal_personvalsomraden`

Do not insert a single ambiguous `andel_personroster` into `kandidater` when the percentage is constituency-specific.

## Missing versus false

This is important.

If a result field is unavailable because the result is not yet final/established, use `NA`, not `FALSE` or zero.

Examples:
- `invald = NA` if elected-member data are not yet available
- `kvalificerad_personval = NA` if qualification data are not yet available

Use `FALSE` only when the relevant result information is available and the candidate did not satisfy the condition.

This distinction is especially important in 2026 genrep/test data.

## 2026 result-file architecture

Current development uses Valmyndigheten's 2026 result files.

The result collection is currently configurable. During genrep development it is typically:

`genrep2026`

Do not hard-code the assumption that genrep is permanent. The live result collection will replace it later.

The package uses `index.md5` as the entry point for result files.

Typical result ZIP layout:
- preliminary: `p/...`
- final: `s/...`
- election types: `rd`, `rf`, `kf`

Strict file matching is important so aggregate summary ZIP files are not accidentally treated as individual election files.

## Geographic principles

Use official Valmyndigheten result data at the requested geographic level when available.

Self-aggregate only when necessary.

Relevant public geographic levels may include:
- district
- municipal constituency
- municipality
- region constituency
- region
- parliamentary constituency
- national

Not every level is meaningful for every election type. Public API functions should reject nonsensical combinations rather than silently returning misleading data.

## Preliminary versus final results

Preliminary and final result files should share parsers and schemas where feasible.

Do not build parallel systems unless source structure genuinely requires it.

Preliminary results:
- contain only parties reported individually plus aggregated "other parties"
- do not contain person-vote results

Final results:
- contain all parties individually
- may contain list votes, personal votes, elected members and substitutes

Extra final-only structures should be parsed into separate tables rather than forced into `valresultat`.

## Local raw-data archive

The package must support both remote and local raw data.

Users may specify a local archive through:
- an explicit `data_dir` argument, or
- `options(swelections.data_dir = "...")`

Never hard-code a developer-specific path in package functions.

Priority:
1. explicit `data_dir`
2. `options("swelections.data_dir")`
3. no local directory configured

Use the `swelections.` prefix for new package-scoped options. If legacy `valresultat.*` options already exist in released or user-facing code, do not remove compatibility without an explicit migration decision.

Source behaviour:
- `source = "local"`: require local file; error if missing
- `source = "remote"`: use Valmyndigheten
- `source = "auto"`: use local file if present, otherwise remote

Readers should accept either URLs or local files.

### Updating and archiving

Distinguish current working copies from historical snapshots.

Normal working behaviour:
- `update = FALSE`: reuse local copy if present
- `update = TRUE`: download current remote file and replace the working copy only if content changed

Archiving:
- `archive = TRUE` creates a dated snapshot
- do not create a new archived copy on every technical update by default
- archive analytically meaningful versions, not every transient revision
- preserve source files in original form

The local archive is separate from the Git repository.

## Mutable mandate-period data

Valmyndigheten also publishes data during the mandate period about:
- current elected members
- resignations
- vacant seats
- changes over time

These files contain `fran_datum` and `till_datum`.

Support for these data will be added later.

When implemented, model them as validity intervals rather than overwriting history.

Do not conflate mandate-period status with the fixed election result.

## Validation expectations

Run tests after changes.

Important invariants already used during development include:

### Vote results
- total votes = valid votes + invalid votes
- sum of party rows including "other parties" = valid votes
- invalid votes = sum of invalid subcategories where applicable

### Mandates
- party mandates satisfy relevant fixed/equalisation mandate identities
- constituency mandates sum to election-area mandates where applicable
- total national RD mandates = 349

### Geography
- lower-level party vote totals should aggregate to official higher-level totals
- district-to-municipality, municipality-to-region/county and region/county-to-national checks should match where structurally applicable

### Candidates
- no duplicate rows on the intended `kandidater` key
- all source columns intended for analysis have stable types
- no unintended list-columns
- when elected-member data are available, elected candidates should match valid candidate data in live production files
- genrep/test data may contain known inconsistencies; do not distort production logic merely to make genrep internally perfect

### Person votes
- within a list, candidate personal votes should sum to `antal_roster_med_personrost`
- candidate person votes summed over lists should match Valmyndigheten's `personroster_summerade`
- candidates elected on personal votes should be marked as qualified for personal election when qualification data are available


### Canonical data
- every published asset should match its manifest filename, file size and SHA256 checksum
- canonical tables must match the validated source-built intermediate objects for their documented observation units and keys
- representative direct checks against raw source data should be retained for important structures
- zero-filled or reconstructed analysis views must be deterministically reproducible from their canonical normalised bases
- public canonical assets must satisfy the approved anonymisation rules
- full raw-to-canonical rebuild checks may be opt-in/slow integration tests when they are too expensive for the ordinary test suite

## Testing strategy

Move stable checks out of exploratory QMD files and into `tests/testthat/`.

Use the exploratory QMD only as a development workbench. It is not part of the package's production API and does not need to be polished.

When adding tests:
- prefer small deterministic fixtures or selected source files
- test schemas, keys, invariants and error handling
- avoid unnecessary network dependence in unit tests
- separate slow/integration tests from ordinary unit tests when appropriate

inlasning_valmyndigheten_2026.qmd is an exploratory development workbench and log. 
It is intentionally messy and may contain temporary objects, manual checks and obsolete experiments. 
Do not treat it as production code or user documentation, and do not refactor or clean it unless explicitly requested. 
Stable logic belongs in R/ and stable checks in tests/testthat/.

## Public API direction

The package is moving toward an English-first public API under the package name `swelections`.

Existing Swedish public functions include:

- `valresultat()`
- `mandat()`
- `kandidaturer()`
- `kandidater()`
- `valda()`
- `ersattare()`

Do not remove or rename these functions silently.

Future work may introduce English primary names with the Swedish functions retained as aliases. Exact English function names, deprecation policy and migration details require an explicit API decision before implementation.

Canonical public datasets use English column names. The R API may offer Swedish column names through an explicit naming-language mechanism, potentially both through a per-call argument and a package option. Do not implement or change that mechanism unless explicitly requested.

Language selection for column names must not silently translate data values. Multilingual values, such as party names, should use explicit fields such as `party_name_sv` and `party_name_en`.

For candidate functions:
- `val = NULL` means all political levels
- valid election types are `RD`, `RF`, `KF`

Do not silently change public defaults or argument meanings.

## Package development

The repository and package are named `swelections`. References to `valresultat` should remain only when they refer to the existing Swedish function/API, historical text, or deliberately supported legacy compatibility. Do not mechanically replace the Swedish common noun *valresultat* when it means election results rather than the former package name.

As the package matures, maintain standard package infrastructure:
- `DESCRIPTION`
- `NAMESPACE`
- roxygen2 documentation
- `tests/testthat/`
- examples/vignettes where useful
- `R CMD check`

Before large refactors:
1. inspect the current parsers and tests
2. identify the validated behaviour that must remain unchanged
3. make the smallest reasonable change
4. run relevant tests
5. report any conceptual ambiguity rather than guessing

## Working principle

The main goal is not merely to make code run.

The package should:
- preserve Valmyndigheten's information accurately
- make canonical election data usable outside R and independently of the package
- provide clear and stable analytical observation levels
- make common political-science analyses easy
- remain reproducible when source files change
- keep raw source data separate from package code
- avoid hiding genuine source ambiguity behind arbitrary transformations
