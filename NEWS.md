# valresultat 0.3.0.9000

* Extends `personroster()` to official final RD, RF and KF results for 2022.
  Exact year vectors, `"alla"` and `fran`/`till` return long-format results
  with integer `valar`. The 2022 area view uses official area-level result
  lists; district views use district lists. Those levels are not forced to
  sum identically. List numbers are result identifiers, not proof of printed
  name ballots; verified `90000` rows do not generate candidate votes.
* `ersattare()` now reads verified final substitute relations for RD, RF and KF
  in 2022 and 2026. It supports exact year vectors, `"alla"` and `fran`/`till`
  with integer `valar`, preserves each member–substitute relation and its
  constituency, and does not infer substitutes from preliminary results.
* `valda()` reads the official final elected-member relation for RD, RF and KF
  in 2022 and 2026. It supports exact year vectors, `"alla"` and `fran`/`till`
  in long format. Missing or unfinished final relations give an error; no
  preliminary elected-member result is inferred. The direct mandate-file path
  retains the actual elected constituency and avoids district vote parsing.
* Places `antal_valkretsar` beside the candidate-level constituency fields in
  `kandidater()`. It counts distinct constituencies across valid candidacies,
  including all actual constituencies reached by nationwide RD lists; several
  lists in one constituency count once. Insufficient geography gives `NA`.
  `valda()` no longer includes this candidacy count; its constituency fields
  describe where the member was elected. This removes a column present in 0.2.0.
* Adds 2022 candidates to `kandidater()` and the same exact-year, `"alla"`
  and `fran`/`till` selection used by the other multi-year functions.
  Candidate rows retain their candidate × election × party key, gain integer
  `valar`, and add candidate-level `oppen_lista` and `pa_namnvalsedel`.
  The latter means at least one valid candidacy appeared on a printed name
  ballot; unknown older snapshots do not create negative statuses.
* Derives 2022 candidate personal-vote totals from reconciled official final
  area-level list results, counting observed result lists independently of
  printed-ballot status. `90000` party ballots add no reported candidate votes;
  an absent party row in a verified final area gives zero reported candidate
  votes. Unverifiable area structures remain `NA`.
  Elected status uses the final election result, excluding official empty-seat
  placeholders.
* Adds 2022 candidacies and shared multi-year selection to `kandidaturer()`.
  Its long-format result includes integer `valar`, party-area `oppen_lista`
  and candidacy-list `pa_namnvalsedel`. Negative printed-ballot status is
  verified against the candidate CSV's content hash for both years. Older
  or unknown snapshots retain `NA` where the status is not `S`.
* Adds official 2022 mandate results for RD, RF and KF at election-area and
  constituency levels where present. `mandat()` uses the shared exact-year,
  `"alla"` and `fran`/`till` selection, returns years in long format, and adds
  integer `valar` after `valtillfalle`. Missing historical comparisons remain
  `NA`; final 2022 empty seats are mandates minus distinct elected members.
  Valmyndigheten's "Kunde inte utses" placeholders are excluded and checked;
  divided electoral areas use complete constituency lists.
* `valresultat()` now accepts exact year vectors, `ar = "alla"`, and inclusive
  `fran`/`till` ranges over supported election years. Multi-year results are
  returned in long format with integer `valar` directly after `valtillfalle`.
  All selected years must support the requested election, count and level.
* Adds `valresultat(ar = 2022)` for official preliminary and final district
  and mandate-file vote results (RD: districts, constituencies, nation;
  RF: districts, region constituencies, regions; KF: districts, municipal
  constituencies where present, municipalities). Source paths come from the
  `val2022` index. The existing public schemas and 0–1 shares are retained;
  unavailable previous-election comparisons remain `NA`.
* Extends `personroster()` with independent geographic, ballot-list and
  verified-zero controls. District and list views are sparse by default;
  `komplettera_nollor = TRUE` adds verified zeros. Its established default
  area result keeps the full candidate population, and official area-level
  list totals are checked against districts.
* Corrects an overly cautious personal-vote availability rule in 0.2.0 that
  could return `NA` even when a vote count was verifiable from complete final
  results. Official qualified-candidate counts retain priority; reconciled
  area summaries and lists provide other observed counts and verified zeros.
* Keeps incomplete final-path and preliminary material unknown where votes
  cannot yet be established. Sparse list views retain observed rows, while
  completed views add zeros only after the source material is fully reconciled.
* Candidate personal-vote totals now use the corrected area results.

# valresultat 0.2.0

* Standardizes public vote shares, turnout rates, share differences and mandate
  thresholds as proportions on the 0–1 scale. Verified shares are calculated
  exactly from count fields; `0.025` means an increase of 2.5 percentage points,
  not a relative 2.5 percent change. Public threshold columns are now
  `valomradessparr` and `valkretssparr`.
* Adds authoritative short municipality names by municipality code. Election
  results preserve a separate official municipality label, while tables that
  already identify KF municipalities as electoral areas use the short name in
  `valomradesnamn` without duplicate geography columns.
* Adds `personroster()` with one row per candidate, party and official
  personal-vote area. Official qualified-candidate totals take precedence,
  other totals require verified complete district material, and personal-vote
  shares are unrounded proportions on the 0–1 scale.
* Gives `valresultat()` an analysis-oriented, level-specific public column
  contract while retaining the internal 83-column harmonised schema.
* Retains unreported voting districts with `raknat = FALSE`, official
  constituency-specific party rows and typed missing result values.
* Completes unambiguous district geography from official 2026 structures in
  the same ZIP and a fixed 2026 county-code lookup.
* Keeps only analytically distinct reporting scopes in each public level's
  column contract and places district reporting status next to its geography.
* Preserves authoritative historical mandate totals even when the current
  party list is not a complete historical party universe.
* Separates unambiguous candidacy geography from election geography and keeps
  the elected area available for candidates who stood in several areas.
* Distinguishes verified zero personal votes from missing, partial or unclear
  person-vote material with stricter availability checks.

# valresultat 0.1.1

* Normalizes Valmyndigheten's live preliminary-count metadata
  `"preliminär"` to the package value `"preliminar"`. The unaccented form
  used by older test data remains supported.
* Skips geographic result objects whose existing `rostfordelning` key is
  explicitly `NULL` while counting is in progress. Explicit zero results are
  retained, and a missing key or malformed result structure remains an error.

# valresultat 0.1.0

* Adds the first public API for harmonised 2026 election results: `valresultat()`,
  `mandat()`, `kandidaturer()`, `kandidater()`, `valda()` and `ersattare()`.
* Supports local and remote Valmyndigheten raw data with strict offline behavior
  for `source = "local"`.
* Uses Valmyndigheten's live `val2026` result collection by default while
  retaining explicit access to `genrep2026` for tests and development. File
  paths come from `index.md5`, with support for the corrected `Val_2026_*`
  names.
* Distinguishes verified zero/false results from missing, partial or unclear
  candidate-result data with typed `NA` values.
* Final D, U and M source files have been integration-tested against selected
  2026 rehearsal files. Preliminary and O sources remain fixture-tested only.

This is an experimental first release focused on the 2026 election.
