# Municipal referendums: implementation, source policy and expansion guide

Municipal referendums extend the shared referendum schema introduced for the 2003
euro referendum (`R/referendum_2003.R`) via `R/referendum_municipal.R` without
altering ordinary `RD`/`RF`/`KF`, `EU`, or `2003` national defaults.

Currently implemented:
- **2019 Öland municipal referendum** (`SE-F-2019-05-26-0840-0885`, question
  `"Öland en kommun?"`) across Borgholm (`0885`) and Mörbylånga (`0840`).

## Event model and identification

1. **Event-keyed registry:** Each referendum is registered in `.referendum_events()`
   and exposed by `election_events(election = "referendum")` and
   `valtillfallen(val = "F")`. Default `election = NULL` remains restricted to
   `RD`/`RF`/`KF`.
2. **Event IDs (`election_event`):**
   - Single-municipality referendum: `SE-F-<YYYY-MM-DD>-<kommunkod>`.
   - Coordinated multi-municipality referendum on the same question (such as
     Öland 2019): `SE-F-<YYYY-MM-DD>-<kommunkod1>-<kommunkod2>` with
     `scope_level = "municipality"` and comma-separated `scope_code` / `scope_name`.
   - Same municipality holding multiple referendums on the same date (e.g.
     two ballot questions on an EU/general election day): append a short
     disambiguating slug or sequence suffix so `election_event` remains unique.
3. **Deduplication key:** Municipal referendum observations are uniquely keyed by
   `(election_event, source_unit_code, voting_option_code)`. Concurrent
   municipal referendums in the same year or municipality must never share an
   `election_event` key.
4. **National default preservation:** `results(election = "referendum")` without
   `year`, or with `year = "all"` and `level = NULL` / `"national"`, continues
   to dispatch to the 2003 national referendum. Municipal referendums are
   retrieved by passing `year` explicitly (e.g. `year = 2019`) or requesting
   `level = "municipality"` / `"district"`.

## Shared schema and missingness invariants

- **Voting options:** `voting_option_code` and `voting_option_name` carry the
  ballot options; `is_blank_option` identifies valid blank ballots. Blank votes
  are valid (`valid_votes = sum(votes)`, `vote_share = votes / valid_votes`).
- **Unreported invalid ballots:** Where a municipal source table does not report
  invalid ballots separately, `invalid_votes`, `total_votes`, and `turnout` stay
  strictly typed `NA` (`NA_integer_`, `NA_integer_`, `NA_real_`). Do not infer
  zero invalid ballots or compute turnout from `valid_votes / eligible_voters`.
- **Wednesday / collection units:** Late-arriving advance votes counted after
  election day (`onsdagsräkning`) are stored as municipal collection units with
  code `F-<kommunkod>-00`, `district_type = "collection"` (`"uppsamlingsdistrikt"`),
  `eligible_voters = NA_integer_`, and `turnout = NA_real_`.
- **Electorate composition:** The three 2003 SCB citizenship/residence columns
  in `.referendum2003_standard` remain `NA_integer_` for municipal referendums
  for schema compatibility.

## Source verification and preservation

- **Wayback Machine snapshots:** Always pin raw `id_` URLs
  (`https://web.archive.org/web/<timestamp>id_/<original_url>`) so Wayback
  toolbar rewrites do not alter bytes, and verify both exact `bytes` and
  `sha256` on every remote and local read.
- **Local raw layout:** `source = "local"` searches `<data_dir>/referendum/<year>/`,
  `<data_dir>/folkomrostning/<year>/`, `<data_dir>/<year>/`, and `<data_dir>`
  for SHA256-verified snapshots (supporting documented filename aliases).
- **Internal reconciliation:** Every municipal parser must verify that ordinary
  district `eligible_voters` sum to the municipality total, ordinary district
  option votes sum to election-night totals, and `ordinary + collection` votes
  sum to the reported final municipality result before returning rows.

## 2019 Öland source record

Held on 26 May 2019 alongside the European Parliament election (`2019-05-26`;
Wednesday counts completed `2019-05-29`):

- **Mörbylånga (`0840`):** 10 ordinary districts (`08400105`–`08401504`, matching
  EU 2019 district codes) + 1 collection unit (`F-0840-00`); `11,837` eligible
  voters; `3,461` Ja, `4,432` Nej, `259` Blank (`8,152` valid). Note: Mörbylånga's
  archived URL path is named `Preliminart-resultat-folkomrostningen-Oland-en-kommun`,
  but the table includes both the `2019-05-26` total (`TOTALT INKOMNA RÖSTER`)
  and the `2019-05-29` Wednesday count (`Röster onsdagsräkningen`) summing to
  `TOTALT RÖSTRESULTAT FOLKOMRÖSTNING`.
- **Borgholm (`0885`):** 9 ordinary districts (`08850101`–`08851516`, matching
  EU 2019 district codes) + 1 collection unit (`F-0885-00`); `9,106` eligible
  voters; `2,403` Ja, `3,487` Nej, `154` Blank (`6,044` valid).
- Both municipal tables omit invalid-ballot counts, so `invalid_votes`,
  `total_votes` and `turnout` remain `NA`.
- Canonical Parquet build script: `data-raw/build-canonical-referendum-2019.R`
  (currently an unpublished local build configured via
  `options(swelections.canonical_manifest = c("folkomr:ordinary:2019" = ...))`).

## Checklist for adding more local referendums

1. **Multiple events per year:** Replace any single-year guard (currently
   `.referendum_municipal_raw()` checks `2019L`) with event-level dispatch over
   all registered events matching `year` (and optionally `election_event` or
   municipality filters), combining outputs with `dplyr::bind_rows()` and
   verifying uniqueness on `(election_event, source_unit_code, voting_option_code)`.
2. **Non-binary or custom voting options:** `.value_dictionary()$voting_option_name`
   in `R/output_values.R` currently maps only `Ja -> "yes"`, `Nej -> "no"`,
   `Blank -> "blank"` under strict recoding (`VALUE_CONTRACT.md`). Before adding
   a referendum with 3+ options, custom labels, or no `BLANK` option, extend
   `.value_dictionary()` / `VALUE_CONTRACT.md` (or keep literal source option
   labels unrecoded for non-standard prompts) and avoid hardcoding
   `c("JA", "NEJ", "BLANK")` in parsers or aggregators.
3. **Canonical packaging:** Decide whether future local referendums are built
   as per-year manifests (`folkomr:ordinary:<year>`) or a consolidated local
   referendum product before adding entries to `.canonical_release_registry()`.
4. **Tests and checks:** Add unit tests covering SHA256/tamper checks, internal
   table reconciliation, English/Swedish parity (`standard`/`full`),
   `election_events()`/`valtillfallen()`, and canonical Parquet round-trip
   parity.
