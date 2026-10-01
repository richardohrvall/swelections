# AGENTS.md

## Project purpose

This repository contains the R package `swelections`, which downloads, archives, parses, harmonises, validates and exposes Swedish election data from Valmyndigheten (the Swedish Election Authority).

The package is intended to provide analysis-friendly election datasets for researchers and other users. Preserve information from Valmyndigheten where useful, but do not reproduce source structures unnecessarily in the public analytical interface.

The package has two distinct but connected roles:

1. provide stable, analysis-friendly data through the public API; and
2. maintain reproducible, versioned canonical data products behind that API.

The current development focus includes:
- reliable support for current/live election data, especially 2026;
- canonical historical data, with 2018 established as the first canonical release and 2022 the next planned historical year;
- a later, separate layer for mandate-period changes such as departures, entries and vacant seats.

Do not conflate the fixed election result with changes during the subsequent mandate period.

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
- Do not silently change the package data model, observation units, naming conventions or public API.
- If a task appears to require a conceptual change to the data model or public API, explain the proposed change and ask for approval before implementing it.
- Prefer small, reviewable changes over broad rewrites.
- Preserve already validated behaviour unless there is a clear bug or an approved design change.
- Do not commit, push, tag or publish data releases unless explicitly instructed.

## Language and naming

### General code conventions

- Package code is in R.
- Use `snake_case`.
- Prefer compact, descriptive names.
- Internal/source-facing R objects may retain the established Swedish naming conventions.
- The public English API and canonical Parquet schema use English names.
- The Swedish public API remains supported and returns Swedish column names by default.
- Do not mechanically translate Swedish source values merely because column names are English.

### Established Swedish internal/public names

Where the existing Swedish API or internal data model uses Swedish names, preserve the established conventions unless a deliberate API change has been approved.

Use Swedish compounds without unnecessary underscores:
- `valkretskod`, not `valkrets_kod`
- `valkretsnamn`, not `valkrets_namn`
- `valomradeskod`
- `valdistriktskod`
- `kommunkod`
- `lankod`
- `partikod`
- `kandidatnummer`

Use `antal`, `andel` and `ovriga` written out.

Use:
- `valdel` for valdeltagande
- `_fg` for values from the previous election
- `diff_` as prefix for changes/differences
- `ovriga_partier` as a logical indicator
- `over_sparr` as a logical indicator for whether a party passes the relevant threshold for mandate allocation
- `geografiniva` as the standard Swedish variable for geographic level

Current `geografiniva` values include:
- `valdistrikt`
- `kommun`
- `kommunvalkrets`
- `lan`
- `region`
- `riket`
- `riksdagsvalkrets`
- `regionvalkrets`

### English public API

The English-first public API consists of:

- `results()`
- `seats()`
- `candidacies()`
- `candidates()`
- `elected()`
- `substitutes()`
- `preference_votes()`

The Swedish functions remain supported:

- `valresultat()`
- `mandat()`
- `kandidaturer()`
- `kandidater()`
- `valda()`
- `ersattare()`
- `personroster()`

English is the primary terminology for new public documentation and examples. Swedish remains a fully supported interface, not merely a legacy compatibility layer.

For English election arguments, use the descriptive values:
- `"parliamentary"`
- `"regional"`
- `"municipal"`

The official Valmyndigheten codes `RD`, `RF` and `KF` are also accepted directly.

The English canonical result column for these codes is `election_code`. `election_kind` describes the election class such as ordinary election, re-election or extra election. Do not conflate `election_code` with `election_kind`.

For `preference_votes()`, the English geographic argument value is `level = "preference_vote_area"`.

Do not silently change public defaults or argument meanings.

## User-facing output and detail levels

The canonical data schema and user-facing output schema are distinct.

Canonical assets provide a stable, general backend representation with English column names suitable for reproducible storage and backend processing.
### `detail = "standard"`

`detail = "standard"` is the default user-facing output.

It should contain the variables most relevant for ordinary analysis and should prioritise a useful and reasonably consistent analytical schema across election years rather than reproducing every field available in the source.

Standard output should use geographic identifiers that match the actual observation level.

For example:
- municipality-level data should normally use `municipality_code` and `municipality_name`;
- district-level data should normally use `district_code` and `district_name`;
- district-level data may and generally should also include hierarchical context such as `municipality_code`, `municipality_name`, `region_code` and `region_name` where available.

A dataset at a given level should remain at that observation level. Adding geographic context must not create additional rows.

Do not include technical source/reporting variables in standard output merely because they are available in the source.

### `detail = "full"`

`detail = "full"` should expose all information available for the requested result level in the selected source.

For `source = "remote"`, this may closely reflect the information in the current Valmyndigheten source structures, including reporting/status metadata.

For `source = "canonical"`, `full` is limited to the fields represented in the canonical data product for that request. Older canonical data may therefore provide less information than current remote source files.

`detail = "full"` does not mean "return the raw source file unchanged". It remains a harmonised `swelections` output.

Do not imply that historical data contain information that cannot be recovered from their historical sources.

Differences in available `full` fields across election years should be documented where relevant, while `standard` should remain as consistent as reasonably possible.

## Core data model

### `valresultat` / `results`

One row represents:

`election × geographic area × party/category`

The table may contain repeated area-level totals/context because the package prioritises analysis convenience over strict database normalisation.

The same general schema should work for preliminary and final results where possible.

Use rakningstillfalle in the Swedish layer and count in the English layer to distinguish preliminary and final counting.

### `mandat` / `seats`

Keep mandate data separate from vote results because the observation level differs.

`antal_tomma_stolar` in the election-result context refers to seats that could not be filled after the election. In the English canonical schema, keep this distinct from later mandate-period vacancies; the agreed English concept is `unfilled_seats` where that distinction is required.

Do not put mandate-period vacancies into the fixed election-result seat field.

### `valdistriktskoppling`

Connections between current and previous election districts belong in a separate helper table.

Do not place list-valued previous-district links in vote-result tables.

### `kandidaturer` / `candidacies`

Detailed source-oriented data about how a person stands for election.

Keep information such as:
- election type/code
- election area
- constituency
- party
- list number
- position/order on the ballot
- exact source name
- consent/status information
- validity

Preserve invalid candidacies in `kandidaturer` / `candidacies`.

### `kandidater` / `candidates`

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
- total preference votes
- qualification for election by preference votes
- elected status
- elected constituency
- order of election
- basis for election
- substitute group

Do not choose a single "main party" for multi-party candidates.

### Candidate names

The exact source name belongs in `kandidaturer` / `candidacies`.

For the analysis-facing candidate table:
- normalise whitespace;
- simple `"Surname, Given name"` forms may be converted to `"Given name Surname"`;
- do not silently correct spelling differences;
- do not replace aliases/joke names with guessed legal names;
- if several normalised names remain, use a deterministic rule and retain `namn_varierar`.

### `valda()` / `elected()`

`valda()` / `elected()` should be a convenient filtered view of the candidate data where elected status is true, not a separately maintained candidate dataset.

The fixed election result represented by `elected()` must not be conflated with subsequent mandate-period membership.

### `ersattare` / `substitutes`

Substitute relationships are sufficiently special to have their own table.

Preserve the relation between:
- elected member
- substitute
- substitute order
- substitute group
- basis for election

Do not reduce this to a simple substitute flag in the candidate table, because that would lose the relationship structure.

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

The English public terminology is **preference votes**, not "personal votes".

In `kandidater`, use:
- `antal_personroster_totalt` / corresponding English `total_preference_votes` for total preference votes summed over relevant detailed result rows;
- `kvalificerad_personval` / corresponding English qualification field;
- `antal_personvalsomraden` / corresponding English count field.

Do not insert a single ambiguous personal/preference-vote share into the candidate table when the percentage is constituency-specific.

## Missing versus false

This is important.

If a result field is unavailable because the result is not yet final/established, use `NA`, not `FALSE` or zero.

Examples:
- `invald = NA` / corresponding English elected field = `NA` if elected-member data are not yet available;
- `kvalificerad_personval = NA` / corresponding English qualification field = `NA` if qualification data are not yet available.

Use `FALSE` only when the relevant result information is available and the candidate did not satisfy the condition.

This distinction is especially important in 2026 test/preliminary data.

## Canonical data

Canonical data are a versioned, harmonised distribution layer behind the public API.

Current canonical principles:
- canonical Parquet files use the approved English column schema;
- Swedish source-language values are not translated merely because column names are English;
- canonical assets are distributed outside Git, with a manifest containing data version, schema version, provenance, asset sizes and SHA256 checksums;
- canonical data versioning is separate from the R package version;
- the manifest is the entry point for a canonical release;
- downloaded canonical assets remain conceptually `source = "canonical"` even when cached locally;
- canonical assets should not contain raw source files.

The canonical schema should be stable and general enough to support the public API, but it does not need to be identical to the standard user-facing analysis schema.

### Canonical releases

A canonical release is explicitly versioned and may be marked as eligible for automatic selection.

Do not infer canonical eligibility merely from election year or age.

The current `source = "auto"` priority is:

1. complete suitable official raw data available locally;
2. a published canonical release explicitly marked as eligible for `auto`;
3. the official remote source.

An explicit `source` argument always overrides this rule.

The canonical distribution registry should make eligibility explicit per election year/data release.

Do not treat a locally cached canonical file as `source = "local"`.

Do not publish or tag a canonical release without explicit instruction.

## 2026 result-file architecture

Current development uses Valmyndigheten's 2026 result files.

The result collection is configurable. During development it may be `genrep2026`; do not hard-code the assumption that genrep is permanent.

The package uses `index.md5` as the entry point for result files.

Typical result ZIP layout:
- preliminary: `p/...`
- final: `s/...`
- election types: `rd`, `rf`, `kf`

Strict file matching is important so aggregate summary ZIP files are not accidentally treated as individual election files.

For current/live elections, `source = "remote"` must remain a reliable path even before canonical data are available.

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

The user-facing output should describe the actual observation level. Geographic hierarchy may be repeated as context for analysis convenience.

## Preliminary versus final results

Preliminary and final result files should share parsers and schemas where feasible.

Do not build parallel systems unless source structure genuinely requires it.

Preliminary results:
- contain only parties reported individually plus aggregated "other parties";
- do not contain person-vote results.

Final results:
- contain all parties individually;
- may contain list votes, preference votes, elected members and substitutes.

Extra final-only structures should be parsed into separate tables rather than forced into `valresultat` / `results`.

## Local raw-data archive and source behaviour

The package must support local, remote and canonical data sources.

Users may specify a local archive through:
- an explicit `data_dir` argument; or
- the package's current `swelections.data_dir` option.

The older `valresultat.data_dir` option may remain as compatibility support where already implemented, but new documentation and code should use `swelections.*` options.

Never hard-code a developer-specific path in package functions.

Source semantics:
- `source = "local"`: require suitable local official raw data; error if unavailable.
- `source = "remote"`: use the official Valmyndigheten source.
- `source = "canonical"`: use a published/configured canonical release.
- `source = "auto"`: use the priority rule defined in the Canonical data section above.

Readers should accept either URLs or local files where the relevant source path supports both.

### Updating and archiving

Distinguish current working copies from historical snapshots.

Normal working behaviour:
- `update = FALSE`: reuse an appropriate local copy if present;
- `update = TRUE`: download current remote data and replace the working copy only if content changed.

Archiving:
- `archive = TRUE` creates a dated snapshot;
- do not create a new archived copy on every technical update by default;
- archive analytically meaningful versions, not every transient revision;
- preserve source files in original form.

The local archive is separate from the Git repository.

## Remote download robustness

Remote access is particularly important for current/live elections, where canonical data may not yet exist.

Remote download code should:
- avoid unnecessary repeated downloads;
- handle transient individual download failures robustly;
- avoid treating incomplete or zero-byte files as valid;
- preserve successfully downloaded files when a later request fails;
- provide informative errors identifying the failed source file;
- not silently serve stale data when current remote data were requested.

Do not introduce aggressive parallel downloading merely to improve speed without measuring the current bottleneck and considering effects on reliability and the Valmyndigheten source.

For requests requiring many small official files, such as KF data at municipality or district level, performance should be assessed separately from parsing performance.

## Mutable mandate-period data

Valmyndigheten also publishes data during the mandate period about:
- current elected members;
- resignations;
- entries/replacements;
- vacant seats;
- changes over time.

These files contain `fran_datum` and `till_datum`.

Support for these data will be added as a separate layer and must not overwrite the fixed election result.

The preferred underlying model is a validity-interval/history table based on the source's start and end dates.

The user-facing purpose is primarily to compare:
- the fixed election result at the start of the mandate period;
- the current/latest situation during an ongoing mandate period;
- the final situation at the end of a completed mandate period.

For a completed mandate period, the default user-facing status should represent the situation at the end of the mandate period. For an ongoing mandate period, the default should represent the latest available situation.

Users should also be able to request a historical reference date where the implementation supports it.

The analysis-facing layer should make it possible to identify:
- originally elected members who remained;
- members who left;
- members who entered during the mandate period;
- seats that became vacant.

Vacant/unfilled seats are an area-level concept, not a candidate-level property. Do not add mandate-period `vacant_seats` as a candidate attribute.

If the source explicitly identifies vacant seats, preserve that information and use derived counts as appropriate. Keep election-time unfilled seats conceptually separate from later mandate-period vacancies.

Do not conflate mandate-period status with the fixed election result.

## Validation expectations

Run tests after changes.

Important invariants already used during development include:

### Vote results
- total votes = valid votes + invalid votes;
- sum of party rows including "other parties" = valid votes;
- invalid votes = sum of invalid subcategories where applicable.

### Mandates
- party mandates satisfy relevant fixed/equalisation mandate identities;
- constituency mandates sum to election-area mandates where applicable;
- total national RD mandates = 349.

### Geography
- lower-level party vote totals should aggregate to official higher-level totals;
- district-to-municipality, municipality-to-region/county and region/county-to-national checks should match where structurally applicable.

### Candidates
- no duplicate rows on the intended candidate key;
- all source columns intended for analysis have stable types;
- no unintended list-columns;
- when elected-member data are available, elected candidates should match valid candidate data in live production files;
- test/genrep data may contain known inconsistencies; do not distort production logic merely to make test data internally perfect.

### Person votes
- within a list, candidate preference votes should sum to the relevant list total with preference votes;
- candidate preference votes summed over lists should match Valmyndigheten's `personroster_summerade`;
- candidates elected on preference votes should be marked as qualified for election by preference votes when qualification data are available.

## Testing strategy

Move stable checks out of exploratory QMD files and into `tests/testthat/`.

Use exploratory QMD files only as development workbenches. They are not part of the package's production API and do not need to be polished.

When adding tests:
- prefer small deterministic fixtures or selected source files;
- test schemas, keys, invariants and error handling;
- avoid unnecessary network dependence in unit tests;
- separate slow/integration tests from ordinary unit tests when appropriate.

`inlasning_valmyndigheten_2026.qmd` is an exploratory development workbench and log. It is intentionally messy and may contain temporary objects, manual checks and obsolete experiments. Do not treat it as production code or user documentation, and do not refactor or clean it unless explicitly requested. Stable logic belongs in `R/` and stable checks in `tests/testthat/`.

## Public API direction

The current English-first public functions are:

- `results()`
- `seats()`
- `candidacies()`
- `candidates()`
- `elected()`
- `substitutes()`
- `preference_votes()`

The Swedish functions remain supported:

- `valresultat()`
- `mandat()`
- `kandidaturer()`
- `kandidater()`
- `valda()`
- `ersattare()`
- `personroster()`

Likely future public functionality includes mandate-period/status helpers.

For English candidate functions:
- the relevant `election` argument may use `"parliamentary"`, `"regional"`, `"municipal"` or the official `RD`, `RF`, `KF` codes where supported.

Do not silently change public defaults or argument meanings.

### English/Swedish output names

The English API uses English column names by default.

The Swedish API returns Swedish column names by default.

For English API calls:
- `names = "en"` gives English names;
- `names = "sv"` gives Swedish names;
- `options(swelections.names = "sv")` sets the Swedish default for English API calls;
- an explicit `names` argument overrides the option.

The stored canonical Parquet schema remains English. Swedish output names are an API-level transformation, not a second canonical storage schema.

## Package documentation

The README should remain a concise GitHub landing page rather than a complete manual.

The package should have a fuller documentation site, preferably generated with pkgdown, covering:
- getting started;
- election results;
- seats and representation;
- candidates, elected members and substitutes;
- preference votes;
- geographic levels;
- local, remote and canonical sources;
- standard versus full detail;
- the Swedish interface;
- canonical data and reproducibility;
- later, mandate-period changes;
- function reference.

Prefer task-oriented examples as well as function-oriented reference pages.

Do not expand the README into a full manual merely to compensate for missing package-site documentation.

## Package development

As the package matures, maintain standard package infrastructure:
- `DESCRIPTION`
- `NAMESPACE`
- roxygen2 documentation
- `tests/testthat/`
- examples/vignettes where useful
- `R CMD check`

Before large refactors:
1. inspect the current parsers and tests;
2. identify the validated behaviour that must remain unchanged;
3. make the smallest reasonable change;
4. run relevant tests;
5. report any conceptual ambiguity rather than guessing.

Before a canonical release:
1. ensure the release code is committed and the worktree is clean;
2. rebuild canonical assets from that exact commit;
3. verify manifest SHA, `build_tree_dirty`, asset sizes and checksums;
4. run canonical/raw equivalence checks;
5. run the full test suite and `R CMD check`;
6. publish only after explicit instruction.

Do not commit canonical Parquet release assets to Git.

## Working principle

The main goal is not merely to make code run.

The package should:
- preserve Valmyndigheten's information accurately;
- provide clear and stable analytical observation levels;
- make common political-science analyses easy;
- provide analysis-friendly standard output rather than simply mirroring source files;
- make fuller source information available where the selected source supports it;
- keep the canonical storage schema distinct from user-facing analytical schemas;
- remain reproducible when source files change;
- keep raw source data separate from package code;
- avoid hiding genuine source ambiguity behind arbitrary transformations;
- support current/live election data reliably before canonical data are available;
- provide versioned canonical data for stable historical use.
