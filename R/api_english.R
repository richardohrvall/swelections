# English argument values are translated once, before entering the existing
# Swedish API. Geographic support and all source validation remain there.
.english_argument_values <- list(
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
    personal_vote_area = "personvalsomrade"
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

.english_call <- function(fun, args, year, year_missing, names) {
  language <- .english_output_language(names)
  if (!year_missing) {
    if (identical(year, "all")) year <- "alla"
    args$ar <- year
  }
  .public_output_names(do.call(fun, args), language)
}

#' Election results
#'
#' Read official party results at one geographic level and one count stage.
#' The English interface calls [valresultat()] and translates column names
#' only; source values and data values are unchanged.
#'
#' @param year One or more supported election years, or `"all"`. Defaults to
#'   2026 unless `from` or `to` is supplied.
#' @param election Official election code: `"RD"`, `"RF"` or `"KF"`.
#' @param count `"final"` or `"preliminary"`.
#' @param level English geographic level. `NULL` selects the main level for
#'   the election. Supported combinations depend on election and year;
#'   unsupported combinations give an error.
#' @param source `"auto"`, `"local"` or `"remote"`.
#' @param data_dir Local root directory for raw files.
#' @param update Update the local working copy when `TRUE`.
#' @param archive Save a dated raw-data snapshot when `TRUE`.
#' @param progress Show a progress indicator.
#' @param from,to Inclusive bounds among supported election years, as an
#'   alternative to `year`.
#' @param names Output column language: `"en"` or `"sv"`. `NULL` uses
#'   `getOption("swelections.names", "en")`. This changes column names only.
#' @return A tibble with the same rows, values and types as [valresultat()].
#' @examples
#' \dontrun{
#' results(year = 2026, election = "KF", count = "final",
#'         level = "municipality")
#' }
#' @seealso [valresultat()], [seats()]
#' @export
results <- function(
    year = 2026, election = "RD", count = "final", level = NULL,
    source = c("auto", "local", "remote"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(valresultat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names)
}

#' Seats and mandates
#'
#' Read official seat allocations through [mandat()]. `election = NULL` and
#' `level = NULL` retain the Swedish function's supported combinations.
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @param level One or more English geographic levels, or `NULL` for all
#'   relevant mandate levels.
#' @return A tibble with the same rows, values and types as [mandat()].
#' @seealso [mandat()], [results()]
#' @export
seats <- function(
    year = 2026, election = NULL, count = "final", level = NULL,
    source = c("auto", "local", "remote"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(mandat, list(
    val = election, rakning = .english_argument_value(count, "count"),
    niva = .english_argument_value(level, "level", nullable = TRUE),
    source = source, data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names)
}

#' Candidacies
#'
#' Read source-level candidate and ballot-list records through [kandidaturer()].
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @return A tibble with the same rows, values and types as [kandidaturer()].
#' @seealso [kandidaturer()], [candidates()]
#' @export
candidacies <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(kandidaturer, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, fran = from, till = to
  ), year, year_missing, names)
}

#' Candidates
#'
#' Read one row per candidate, election type and party through [kandidater()].
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @param include_results Include final personal-vote and elected-member
#'   results when `TRUE`; corresponds to `resultat` in [kandidater()].
#' @return A tibble with the same rows, values and types as [kandidater()].
#' @seealso [kandidater()], [elected()]
#' @export
candidates <- function(
    year = 2026, election = NULL, include_results = TRUE,
    source = c("auto", "local", "remote"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(kandidater, list(
    val = election, resultat = include_results, source = source,
    data_dir = data_dir, update = update, archive = archive,
    progress = progress, fran = from, till = to
  ), year, year_missing, names)
}

#' Elected members
#'
#' Read the official final elected-member relation through [valda()]. No
#' preliminary elected-member result is inferred.
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @return A tibble with the same rows, values and types as [valda()].
#' @seealso [valda()], [substitutes()]
#' @export
elected <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(valda, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    fran = from, till = to
  ), year, year_missing, names)
}

#' Substitute relationships
#'
#' Read final elected-member–substitute relationships through [ersattare()].
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @return A tibble with the same rows, values and types as [ersattare()].
#' @seealso [ersattare()], [elected()]
#' @export
substitutes <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  .english_call(ersattare, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    fran = from, till = to
  ), year, year_missing, names)
}

#' Preference votes
#'
#' Read candidate preference votes by personal-vote area or district through
#' [personroster()]. `by_list` retains the observed list dimension;
#' `include_zeros` adds only verified zero combinations. The default view is
#' one candidate–party–personal-vote-area row.
#' @inheritParams results
#' @param election One or more official election codes, or `NULL` for all.
#' @param level `"personal_vote_area"` (default) or `"district"`.
#' @param by_list Retain the result-list dimension when `TRUE`.
#' @param include_zeros Add verified zero combinations to sparse views when
#'   `TRUE`; this never invents a zero from incomplete source data.
#' @return A tibble with the same rows, values and types as [personroster()].
#' @seealso [personroster()], [candidates()]
#' @export
preference_votes <- function(
    year = 2026, election = NULL, source = c("auto", "local", "remote"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    progress = interactive(), level = "personal_vote_area",
    by_list = FALSE, include_zeros = FALSE,
    from = NULL, to = NULL, names = NULL
) {
  year_missing <- missing(year)
  if (!is.character(level) || length(level) != 1L || is.na(level) ||
      !level %in% c("personal_vote_area", "district")) {
    stop("Invalid `level`; use personal_vote_area or district.", call. = FALSE)
  }
  .check_flag(by_list, "by_list")
  .check_flag(include_zeros, "include_zeros")
  .english_call(personroster, list(
    val = election, source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress,
    niva = .english_argument_value(level, "level"),
    per_lista = by_list, komplettera_nollor = include_zeros,
    fran = from, till = to
  ), year, year_missing, names)
}
