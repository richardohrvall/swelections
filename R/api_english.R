# English argument values are translated once, before entering the existing
# Swedish API. Geographic support and all source validation remain there.
.english_argument_values <- list(
  election = c(parliamentary = "RD", regional = "RF", municipal = "KF",
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
  language <- .english_output_language(names)
  detail <- .check_detail(detail)
  args["val"] <- list(.english_argument_value(args$val, "election", nullable = TRUE))
  if (!year_missing) {
    if (identical(year, "all")) year <- "alla"
    args$ar <- year
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
  if (broader_preference) data <- .aggregate_preference_area(data, requested_level)
  elections <- if (is.null(args$val)) c("RD", "RF", "KF") else args$val
  if (table == "seats" && !is.null(args$niva))
    elections <- unique(.mandat_par_2026(args$val, args$niva)$valtyp)
  .public_output_names(.public_detail(data, table, detail, elections), language)
}

#' Election results
#'
#' Read official party results at one geographic level and one count stage.
#' The English interface calls [valresultat()] and translates column names
#' only; source values and data values are unchanged.
#'
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#' @param election `"parliamentary"`, `"regional"` or `"municipal"`;
#'   official codes `"RD"`, `"RF"` and `"KF"` are also accepted.
#' @param count `"final"` or `"preliminary"`.
#' @param level English geographic level. `NULL` selects the main level for
#'   the election. Supported combinations depend on election and year;
#'   unsupported combinations give an error.
#' @param source `"auto"`, `"local"`, `"remote"` or `"canonical"`.
#'   For 2018, `"auto"` prefers a complete configured local raw set, then an
#'   explicitly auto-eligible published canonical release, then the official
#'   remote raw source. Other years retain the official raw-data route.
#'   Explicit `"canonical"` resolves the published 2018 English-schema Parquet
#'   release. Unpublished 2022 builds require an explicitly configured manifest;
#'   they are not selected by `"auto"`. A local build may be selected through
#'   `options(swelections.canonical_manifest = "path/to/manifest.json")`.
#'   A named character vector of manifest paths keyed by year supports requests
#'   spanning published 2018 and configured 2022 data.
#'   Canonical Parquet reading requires optional package `nanoparquet`.
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
#'   `getOption("swelections.names", "en")`. This changes column names only.
#' @return A tibble with the same rows, values and types as [valresultat()].
#' @examples
#' \dontrun{
#' results(year = 2026, election = "municipal", count = "final",
#'         level = "municipality")
#' }
#' @seealso [valresultat()], [seats()]
#' @export
results <- function(
    year = 2026, election = "parliamentary", count = "final", level = NULL,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL, detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$valresultat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names, detail, "results")
}

#' Seats and mandates
#'
#' Read official seat allocations through [mandat()]. `election = NULL` and
#' `level = NULL` retain the Swedish function's supported combinations.
#' @inheritParams results
#' @param election One or more of `"parliamentary"`, `"regional"` and
#'   `"municipal"`, or the official codes `"RD"`, `"RF"`, `"KF"`.
#'   `NULL` selects all supported election types.
#' @param level One or more English geographic levels, or `NULL` for all
#'   relevant mandate levels.
#' @return A tibble with the same rows, values and types as [mandat()].
#' @seealso [mandat()], [results()]
#' @export
seats <- function(
    year = 2026, election = NULL, count = "final", level = NULL,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL, detail = "standard"
) {
  year_missing <- missing(year)
  .english_call(.raw_public_api$mandat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names, detail, "seats")
}

#' Candidacies
#'
#' Read source-level candidate and ballot-list records through [kandidaturer()].
#' `ballot_info` is optional candidate identification text printed on the
#' ballot, such as occupation or age. `list_ballots_ordered` records the
#' number of ballot papers ordered for the list, not votes cast. The logical
#' `candidates_registered` and `candidate_declaration` fields retain the
#' source's `NA` values. `registered_municipality_name` is a name, not a code.
#' @inheritParams results
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
#' Read one row per candidate, election type and party through [kandidater()].
#' @inheritParams results
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
#' Read the official final elected-member relation through [valda()]. No
#' preliminary elected-member result is inferred.
#' @inheritParams results
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
#' Read final elected-member–substitute relationships through [ersattare()].
#' @inheritParams results
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
#' @inheritParams results
#' @param election One or more English election values or official codes;
#'   `NULL` selects all supported election types. See [results()].
#' @param level `"preference_vote_area"` (default), `"district"`,
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
  if (!is.character(level) || length(level) != 1L || is.na(level) ||
      !level %in% c("preference_vote_area", "district", "municipality", "region")) {
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
