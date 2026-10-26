# English argument values are translated once, before entering the existing
# Swedish API. Geographic support and all source validation remain there.
.english_argument_values <- list(
  election = c(parliamentary = "RD", regional = "RF", municipal = "KF", european = "E", E = "E",
               RD = "RD", RF = "RF", KF = "KF"),
  count = c(final = "slutlig", preliminary = "preliminar"),
  level = c(
    district = "valdistrikt",
    municipality = "kommun",
    municipal_constituency = "kommunvalkrets",
    county = "lan",
    region = "region",
    regional_constituency = "regionvalkrets",
    parliamentary_constituency = "riksdagsvalkrets",
    national = "riket",
    preference_vote_area = "personvalsomrade"
  )
)

.english_argument_value <- function(value, argument, nullable = FALSE) {
  if (is.null(value) && nullable) return(NULL)
  choices <- .english_argument_values[[argument]]
  if (!is.character(value) || !length(value) || anyNA(value) ||
      any(!nzchar(value)) || any(!value %in% base::names(choices))) {
    stop("Invalid `", argument, "`; use: ",
         paste(base::names(choices), collapse = ", "), ".", call. = FALSE)
  }
  unname(choices[value])
}

.english_call <- function(fun, args, year, year_missing, names, detail, table) {
  finish_remote <- .remote_raw_begin()
  on.exit(finish_remote(), add = TRUE)
  language <- .english_output_language(names)
  detail <- .check_detail(detail)
  args["val"] <- list(.english_argument_value(args$val, "election", nullable = TRUE))
  if (!year_missing) {
    if (identical(year, "all")) year <- "alla"
    args$ar <- year
  }
  if (identical(args$val, "E")) {
    data <- .eu2024_dispatch(args, year, year_missing, table)
    return(.public_output(.public_detail(data, table, detail, "E"), language))
  }
  broader_preference <- identical(table, "preference_votes") &&
    !is.null(args$niva) &&
    args$niva %in% c("kommun", "region")
  if (broader_preference) {
    requested_level <- args$niva
    expected_election <- if (requested_level == "kommun") "KF" else "RF"
    if (!identical(args$val, expected_election)) {
      stop("This broader preference-vote level requires election ",
           expected_election, ".", call. = FALSE)
    }
    if (isTRUE(args$per_lista)) {
      stop("List-level preference votes are not available at this broader level.",
           call. = FALSE)
    }
    args$niva <- "personvalsomrade"
  }
  data <- do.call(fun, args)
  if (broader_preference && any(data$valar %in% c(2002L, 2006L)))
    stop(paste0(min(data$valar[data$valar %in% c(2002L, 2006L)]), " preference votes identify source observations; aggregation across preference-vote areas requires unsupported person linkage."), call. = FALSE)
  if (broader_preference) data <- .aggregate_preference_area(data, requested_level)
  elections <- if (is.null(args$val)) c("RD", "RF", "KF") else args$val
  if (table == "seats" && !is.null(args$niva))
    elections <- unique(.mandat_par_2026(args$val, args$niva)$valtyp)
  .public_output(.public_detail(data, table, detail, elections), language)
}

#' Election results
#'
#' Read official voting results at one geographic level and counting stage.
#' The English interface returns English columns and technical categories;
#' Swedish output preserves the same observations and values. See [data_sources].
#'
#' @details
#' 2002 final results use preserved official XML; the original Orsa election
#' is separate from its 2003 rerun. Candidate keys identify source observations,
#' not persons; names are missing and full ballot candidacies are unavailable.
#' Full preliminary collection results remain unrecovered.
#' 2006 final data are available through published canonical tables or compatible
#' local raw sources; complete preliminary results are unavailable.
#' Candidate numbers in 2006 identify source observations rather than people.
#' See the repository's 2006 implementation documentation for source limitations.
#'
#' @section Re-elections:
#' A re-election is a separate election event within the original continuing
#' mandate period. It is neither a new ordinary election in a longitudinal series
#' nor the start of a new mandate period. Ordinary elections remain the default.
#' Use `election_kind = "re_election"` for the re-election event, or `"all"` for
#' separate ordinary and re-election events. `year` and `election_year` refer to
#' the actual polling year. Örebro 2011 covers Nordöstra only, not all Örebro.
#' Use [election_events()] to discover events, scopes and original-election links.
#'
#' Final re-election results and seats use published canonical data with
#' `source = "auto"` or `"canonical"`. Explicit `source = "local"` accepts
#' compatible preserved sources via `data_dir` or
#' `options(swelections.re_election_sources = ...)`. Auto never chooses local.
#' Remote, update/archive and preliminary re-election readers are unavailable.
#' No post-re-election combined vote or turnout result is provided.
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Supported years include 2002, 2006, 2010, 2014, 2018, 2022 and 2026, subject to the requested
#'   election, geographic level and count stage.
#' @param election_kind Ordinary elections (default), re-elections, or all events:
#'   `"ordinary"`, `"re_election"`, or `"all"`. Year selects the actual poll year.
#' @param election `"parliamentary"`, `"regional"` or `"municipal"`;
#'   official codes `"RD"`, `"RF"` and `"KF"` are also accepted.
#'   `results()` also accepts `"referendum"` or `"F"` for final 2003 results.
#'   Referendum rows use `voting_option_code/name`, not party fields. Blank is
#'   valid; invalid ballots are separate. District output includes ordinary and
#'   Wednesday units (`district_type`); Wednesday electorate/turnout are missing.
#'   Local 2003 input is the preserved directory containing `final.xml` and
#'   `final-municipal/`; complete preliminary results are not supported.
#'   County/national referendum results also include three Statistics Sweden (SCB) electorate groups:
#'   `eligible_swedish_citizens_in_sweden`, `eligible_swedish_citizens_abroad`
#'   and `eligible_foreign_citizens`. Their sum matches `eligible_voters`.
#'   Components are missing at finer levels; counts are never allocated downward.
#'   All seven functions also accept `"european"` / `"E"` for 2004, 2009, 2014, 2019 and 2024.
#'   EU results support national, county, municipality, municipal constituency
#'   and district levels. EU seats are national; preference votes additionally
#'   support `"preference_vote_area"` (the national election constituency).
#'   EU 2024's full preliminary JSON includes collection districts. Blank ballots
#'   are invalid. Collection units have no electorate or turnout.
#'   For EU 2024, the later approved official candidacy snapshot defines the final population;
#'   historical consent-only candidate 1203 is preserved as provenance only.
#'   Original elected/substitute relations are used, never a current roster.
#'   EU 2009 uses preserved original final XML and archived named ballot XML.
#'   Its 500 candidate keys identify list positions, not distinct physical persons.
#'   Small-party workbook columns retain separate source-observation keys and
#'   unknown list positions. National small-party candidate sums (2,665) differ
#'   from the official aggregate (2,655); county/municipal sums are 2,677.
#'   Values are preserved without name-based deduplication or inferred Wednesday
#'   allocation. Complete preliminary results are not verified and give an error.
#'   EU 2014 uses the preserved original final XML with geographic names;
#'   complete preliminary results are unavailable and give an error. Its valid
#'   handwritten-vote residual remains an other-party category with no invented
#'   party code. Full-only `source_votes_without_party_designation` identifies
#'   ten votes at district 05803201; it is metadata, not additional votes.
#'   Candidate names are missing; source validity/consent attributes are unavailable.
#'   EU 2019 uses preserved original XML, the official handwritten-party
#'   supplement and the final-compatible electorate SKV; raw XLS reading
#'   requires optional `readxl`. Public redacted candidate names are `NA`.
#'   Preliminary 2019 results retain ten named parties plus other parties.
#'   The fixed final result has 20 seats; later Brexit changes are excluded.
#'   Local EU input may be the `eu/2024` archive itself or its parent root;
#'   read-only snapshots do not support `update` or `archive`. Published canonical
#'   coverage is selected by `auto`; EU 2009 preference votes require explicit local sources.
#' @param count Official counting stage: `"final"` or `"preliminary"`.
#'   Preliminary counting includes election-night and collection/Wednesday
#'   counting where a complete source is supported. These are not separate
#'   argument values; district types are recorded separately.
#' @param level Geographic level: `"national"`, `"county"`, `"region"`,
#'   `"municipality"`, `"parliamentary_constituency"`,
#'   `"regional_constituency"`, `"municipal_constituency"` or `"district"`.
#'   `NULL` selects the main level for the election. Available combinations
#'   depend on election, year and counting stage; unsupported requests give an error.
#' @param source How data are obtained. `"auto"` selects approved canonical
#'   coverage, otherwise a supported current remote source; never local files.
#'   `"canonical"` explicitly reads canonical data. `"remote"` explicitly reads a
#'   supported official Valmyndigheten source. Neither silently falls back to
#'   another source. `"local"` reads your own compatible raw archive using
#'   `data_dir`. Canonical reading requires `nanoparquet`. See [data_sources]
#'   for source requirements, historical archives and manifest configuration.
#' @param data_dir Local root directory for raw files.
#' @param update Update the local working copy when `TRUE`.
#' @param archive Save a dated raw-data snapshot when `TRUE`.
#' @param progress Show a progress indicator.
#' @param from,to Inclusive bounds among supported election years, as an
#'   alternative to `year`.
#' @param detail `"standard"` (default) selects analysis-facing columns;
#'   `"full"` retains all available harmonised fields. This is independent
#'   of the output-name language and does not change observations or values.
#'   Standard constituency fields refer to RD/RF constituencies; KF uses
#'   `municipal_constituency_*`, including candidacy/elected role prefixes.
#'   Distinct municipal constituency context is retained for RD/RF districts.
#'   Preference-vote areas use their own primary identifiers instead of
#'   duplicate constituency aliases. Full output preserves generic KF source
#'   constituency fields as `source_*constituency_*`.
#'   Geographic column selection follows the requested election even for empty
#'   results. In substitute views, `electoral_area_*` describes RD's distinct
#'   surrounding area; RF/KF parents use region/municipality identifiers.
#'   Full output preserves the original parent fields as
#'   `source_electoral_area_*`.
#' @param names Output column language: `"en"` or `"sv"`. `NULL` uses
#'   `getOption("swelections.names", "en")`. All seven election-data functions
#'   accept `names = "sv"` for Swedish column names and technical categories.
#'   Proper names and literal source identifiers retain their source spelling.
#'   `election_events()` has no `names` argument; use [valtillfallen()] instead.
#'   Booleans are logical in both languages. Consent/declaration in full output
#'   have separate `*_applicable` flags; not applicable is not false.
#' @return A tibble with the same rows, values and types as [valresultat()].
#' @examples
#' \dontrun{
#' results(year = 2026, election = "municipal", count = "final",
#'         level = "municipality")
#' archive <- "path/to/preserved/archive"
#' # Requires preserved final inputs, including the separate Orsa 2003 XML.
#' results(year = 2003, election = "municipal", election_kind = "re_election",
#'         source = "local", data_dir = archive) # Orsa
#' results(year = 2011, election = "regional", election_kind = "re_election",
#'         source = "local", data_dir = archive) # Västra Götaland
#' results(year = 2011, election = "municipal", election_kind = "re_election",
#'         source = "local", data_dir = archive) # Örebro Nordöstra only
#' results(year = 2015, election = "municipal", election_kind = "re_election",
#'         source = "local", data_dir = archive) # Båstad
#' results(year = 2019, election = "municipal", election_kind = "re_election",
#'         source = "local", data_dir = archive) # Falun
#' }
#' @seealso [valresultat()], [seats()]
#' @export
results <- function(
    year = 2026, election = "parliamentary", count = "final", level = NULL,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL, detail = "standard",
    election_kind = "ordinary"
) {
  year_missing <- missing(year)
  election_kind <- .check_election_kind(election_kind)
  if (election_kind != "ordinary") return(.re_dispatch("results", year, year_missing, election, count, level, source, data_dir, update, archive, progress, from, to, names, detail, election_kind))
  if (!any(election %in% c("F", "referendum"))) .re_ordinary_hint(year, election, from, to)
  if (is.character(election) && length(election) == 1L &&
      !is.na(election) && election %in% c("referendum", "F"))
    return(.referendum2003_results(year, year_missing, from, to, count, level,
      source, data_dir, update, archive, progress, names, detail))
  .english_call(.raw_public_api$valresultat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names, detail, "results")
}

#' Seats and mandates
#'
#' Read official seat allocations through [mandat()]. Ordinary elections remain
#' the default. A re-election is a separate election event within the original
#' continuing mandate period: it is neither a new ordinary election in a
#' longitudinal series nor the start of a new mandate period.
#'
#' @section Event allocation and post-re-election composition:
#' `seats(..., election_kind = "re_election")` returns only mandates allocated
#' in the re-election event. Örebro 2011 returns 17 mandates for Nordöstra,
#' not 65 mandates for the whole municipality.
#'
#' `seats(..., after_re_election = TRUE)` returns the derived composition
#' associated with the original ordinary election after verified replacement
#' events. Örebro has 48 unaffected seats from 2010 plus 17 from the 2011
#' re-election, with `election_year = 2010` in the same continuing mandate period.
#' This is not a municipality-wide 2011 election. Year bounds select original
#' ordinary elections; linked re-elections may fall outside those bounds.
#' Areas without re-elections keep their original allocations. No allocation
#' is recalculated from combined votes.
#'
#' Component rows retain `component_election_event`, `component_election_year`,
#' `component_geographic_level` and `component_geographic_code`. A party can
#' have several component rows: sum `seats`; repeated `total_seats` is not
#' additive. This is an electoral composition, not membership history.
#'
#' @section Re-election sources:
#' Final event allocations use canonical with `source = "auto"` or
#' `"canonical"`; compositions also read the original ordinary inputs
#' through that source route. Explicit `source = "local"` accepts preserved
#' files via `data_dir` or `options(swelections.re_election_sources = ...)`.
#' Auto never chooses local. Remote, update/archive and preliminary re-election
#' readers are unavailable. See [election_events()].
#' @param after_re_election If `TRUE`, derive the composition after verified
#'   linked re-elections, anchored on the original ordinary election. Requires
#'   `election_kind = "ordinary"`, `count = "final"` and a whole-area level.
#'   Selection and output `election_year` retain the original ordinary year;
#'   component metadata identifies subsequent re-election sources.
#' @inheritParams results
#' @param year Normally the actual election-event year; output `election_year`
#'   has the same meaning. Accepts supported years or `"all"`; defaults to
#'   2026 unless `from`/`to` is supplied. With `after_re_election = TRUE`,
#'   selection and output `election_year` instead refer to the original
#'   ordinary election, while incorporating its verified subsequent re-elections.
#' @param election_kind `"ordinary"` (default), `"re_election"` or `"all"`.
#'   Normally year selects actual polling years. With `after_re_election = TRUE`,
#'   only `"ordinary"` is accepted and year selection refers to original elections.
#' @param election One or more of `"parliamentary"`, `"regional"` and
#'   `"municipal"`, or the official codes `"RD"`, `"RF"`, `"KF"`.
#'   For EU 2004/2009/2014/2019/2024, explicitly select `"european"` or `"E"`; seats are national.
#'   `NULL` retains the existing RD/RF/KF selection.
#' @param level For ordinary mandate results, `NULL` retains all relevant
#'   mandate levels; one or more supported levels may be selected explicitly.
#'   For re-election events, `NULL` selects the event scope (region,
#'   municipality or municipal constituency). With `after_re_election = TRUE`,
#'   `NULL` selects one whole-area level: `"municipality"` for KF, `"region"`
#'   for RF or `"national"` for RD. An explicit composition level must be that
#'   same whole-area level.
#' @return A tibble with the same rows, values and types as [mandat()].
#'   Post-re-election compositions retain the original ordinary-election year
#'   and separate source-component rows.
#' @examples
#' \dontrun{
#' archive <- "path/to/preserved/archive"
#' # Event allocations: 31, 149, 17, 41 and 61 seats respectively.
#' seats(year = 2003, election = "municipal", election_kind = "re_election",
#'       source = "local", data_dir = archive) # Orsa
#' seats(year = 2011, election = "regional", election_kind = "re_election",
#'       source = "local", data_dir = archive) # Västra Götaland
#' seats(year = 2011, election = "municipal", election_kind = "re_election",
#'       source = "local", data_dir = archive) # Örebro Nordöstra: 17
#' seats(year = 2015, election = "municipal", election_kind = "re_election",
#'       source = "local", data_dir = archive) # Båstad
#' seats(year = 2019, election = "municipal", election_kind = "re_election",
#'       source = "local", data_dir = archive) # Falun
#'
#' # Original-year selections include other municipalities/regions as well.
#' orebro <- seats(year = 2010, election = "municipal", after_re_election = TRUE,
#'                 source = "local", data_dir = archive)
#' orebro <- orebro[orebro$municipality_code == "1880", ]
#' sum(orebro$seats) # 65 = 48 from 2010 + 17 from 2011; election_year is 2010
#' orsa <- seats(year = 2002, election = "municipal", after_re_election = TRUE,
#'               source = "local", data_dir = archive)
#' orsa <- orsa[orsa$municipality_code == "2034", ]
#' vg <- seats(year = 2010, election = "regional", after_re_election = TRUE,
#'             source = "local", data_dir = archive)
#' vg <- vg[vg$region_code == "14", ]
#' bastad <- seats(year = 2014, election = "municipal", after_re_election = TRUE,
#'                 source = "local", data_dir = archive)
#' bastad <- bastad[bastad$municipality_code == "1278", ]
#' falun <- seats(year = 2018, election = "municipal", after_re_election = TRUE,
#'                source = "local", data_dir = archive)
#' falun <- falun[falun$municipality_code == "2080", ]
#' }
#' @seealso [mandat()], [results()]
#' @export
seats <- function(
    year = 2026, election = NULL, count = "final", level = NULL,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL, detail = "standard",
    election_kind = "ordinary", after_re_election = FALSE
) {
  year_missing <- missing(year)
  election_kind <- .check_election_kind(election_kind)
  if (!is.logical(after_re_election) || length(after_re_election)!=1L || is.na(after_re_election)) stop("`after_re_election` must be TRUE or FALSE.", call.=FALSE)
  if (after_re_election) return(.re_after_seats(year, year_missing, election, count, level, source, data_dir, update, archive, progress, from, to, names, detail, election_kind))
  if (election_kind != "ordinary") return(.re_dispatch("seats", year, year_missing, election, count, level, source, data_dir, update, archive, progress, from, to, names, detail, election_kind))
  .re_ordinary_hint(year, election, from, to)
  .english_call(.raw_public_api$mandat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names, detail, "seats")
}

#' Candidacies
#'
#' Read election-specific candidacies and ballot-list positions, with available
#' candidate and list information.
#'
#' @details
#' 2002 is not supported: a complete ballot-candidacy source has not been recovered.
#' For 2006, `candidate_number` identifies a geographical ballot-position
#' observation, not a person. Unstructured `ballot_info` is retained without
#' inventing a structured name or a printed-ballot status.
#' `ballot_info` is optional candidate identification text printed on the
#' ballot, such as occupation or age. `list_ballots_ordered` records the
#' number of ballot papers ordered for the list, not votes cast. The logical
#' `candidates_registered` and `candidate_declaration` fields retain the
#' source's `NA` values. `registered_municipality_name` is a name, not a code.
#' @inheritParams results
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Availability depends on the election and source.
#'   See Details for historical coverage limitations.
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @return A tibble with the same rows, values and types as [kandidaturer()].
#' @seealso [kandidaturer()], [candidates()]
#' @export
candidacies <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    from = NULL, to = NULL, names = NULL, detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$kandidaturer, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, fran = from, till = to
  ), year, year_missing, names, detail, "candidacies")
}

#' Candidates
#'
#' Return one row per candidate within the relevant election type and party,
#' with additional candidate-level information where available. The resulting
#' data do not provide a longitudinal link between the same person across elections.
#'
#' @details
#' For 2006, a candidate number is a package-generated source-observation
#' key. Ballot, area preference-vote and appointment observations are retained
#' separately; equal names are not linked. Rows are not unique-person counts
#' and unsupported cross-source totals/attributes remain missing.
#' @inheritParams results
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Availability depends on the election and source.
#'   See Details for historical coverage limitations.
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @param include_results Include final preference-vote and elected-member
#'   results when `TRUE`; corresponds to `resultat` in [kandidater()].
#' @return A tibble with the same rows, values and types as [kandidater()].
#' @seealso [kandidater()], [elected()]
#' @export
candidates <- function(
    year = 2026, election = NULL, include_results = TRUE,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL, detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$kandidater, list(
    val = election, resultat = include_results, source = source,
    data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names, detail, "candidates")
}

#' Elected members
#'
#' Read candidates elected in the official final election result. Use
#' [members_at()] for subsequent mandate holders on a specified date.
#'
#' @details
#' For 2006, candidate numbers identify original appointed source slots,
#' not persons linked across lists. `Kunde ej utses` positions remain unfilled
#' seats and are excluded from elected observations.
#' No preliminary elected-member result is inferred.
#' @inheritParams results
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Availability depends on the election and source.
#'   See Details for historical coverage limitations.
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @return A tibble with the same rows, values and types as [valda()].
#' @seealso [valda()], [substitutes()]
#' @export
elected <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), from = NULL, to = NULL, names = NULL,
    detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$valda, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    fran = from, till = to
  ), year, year_missing, names, detail, "elected")
}

#' Substitute relationships
#'
#' Read the final election's reported elected-member–substitute relationships.
#' These relationships do not describe later mandate holders or temporary service.
#'
#' @details
#' For 2006, member and substitute numbers identify original source slots.
#' Group relationships are expanded without name-based identity linkage or
#' later mandate-period entrants.
#' @inheritParams results
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Availability depends on the election and source.
#'   See Details for historical coverage limitations.
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @return A tibble with the same rows, values and types as [ersattare()].
#' @seealso [ersattare()], [elected()]
#' @export
substitutes <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), from = NULL, to = NULL, names = NULL,
    detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$ersattare, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    fran = from, till = to
  ), year, year_missing, names, detail, "substitutes")
}

#' Preference votes
#'
#' Read candidate preference votes by preference-vote area, district or a
#' supported broader election area. `by_list` retains the observed list dimension;
#' `include_zeros` adds only verified zero combinations. The default view is
#' one candidate–party–preference-vote-area row.
#'
#' @details
#' For EU 2009, this function returns preserved candidate/source observations,
#' not an official all-party aggregate row. The reconciled official total is
#' 1,876,785: 1,874,130 for the main eleven parties plus the official small-party
#' aggregate of 2,655. The national candidate rows instead sum to 1,876,795:
#' small-party source columns report 2,665, an unresolved source inconsistency
#' of ten votes. Do not label that candidate-row sum as the official total.
#' Values remain source-reported and are not adjusted to force agreement.
#'
#' For 2006, rows identify observed source records, not linked persons.
#' `include_zeros` adds no unsupported combinations; explicit zeros remain.
#' Area and list views are alternative representations, not additive totals.
#' Cross-area municipality/region person aggregation is unavailable.
#' @inheritParams results
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#'   Availability depends on the election, geographic level and source.
#'   See Details for historical coverage limitations.
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @param level EU 2004/2009/2014/2019/2024 also supports `"national"`, `"county"`,
#'   `"municipality"` and `"municipal_constituency"`; qualification is only
#'   meaningful at the national preference-vote area. Otherwise:
#'   `"preference_vote_area"` (default), `"district"`,
#'   `"municipality"` for municipal elections, or `"region"` for regional
#'   elections. Broader areas aggregate non-overlapping area results and do
#'   not currently support `by_list = TRUE`.
#' @param by_list Retain the result-list dimension when `TRUE`.
#' @param include_zeros Add verified zero combinations to sparse views when
#'   `TRUE`; this never invents a zero from incomplete source data.
#' @return A tibble with the same rows, values and types as [personroster()].
#' @seealso [personroster()], [candidates()]
#' @export
preference_votes <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), level = "preference_vote_area",
    by_list = FALSE, include_zeros = FALSE,
    from = NULL, to = NULL, names = NULL, detail = "standard"
) {
  year_missing <- missing(year)
  allowed_levels <- c("preference_vote_area", "district", "municipality", "region")
  if (length(election) == 1L && !is.na(election) && election %in% c("european", "E"))
    allowed_levels <- c(allowed_levels, "county", "national", "municipal_constituency")
  if (!is.character(level) || length(level) != 1L || is.na(level) ||
      !level %in% allowed_levels) {
    stop("Invalid `level`; use preference_vote_area, district, municipality or region.", call. = FALSE)
  }
  .check_flag(by_list, "by_list")
  .check_flag(include_zeros, "include_zeros")
  .english_call(.raw_public_api$personroster, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    niva = .english_argument_value(level, "level"),
    per_lista = by_list, komplettera_nollor = include_zeros,
    fran = from, till = to
  ), year, year_missing, names, detail, "preference_votes")
}
