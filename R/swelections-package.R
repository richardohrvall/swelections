#' Swedish election data in R
#'
#' swelections brings together election information across source files, years,
#' formats and geographic levels. Public interfaces cover [results()], [seats()],
#' [candidacies()], [candidates()], [elected()], [substitutes()] and
#' [preference_votes()]. [election_events()] discovers election occasions;
#' [mandate_history()], [members_at()] and [vacant_seats_at()] describe supported
#' mandate periods. Swedish counterparts include [valtillfallen()],
#' [valresultat()] and [mandathistorik()].
#'
#' English functions return English columns and technical categories. The seven
#' election-data functions and three mandate-period functions accept `names = "sv"`.
#' Event metadata use [valtillfallen()] instead of a `names` argument. Proper names and
#' literal source identifiers retain their source spelling. Boolean properties
#' remain logical. The 2003 referendum options are `yes`, `no` and `blank` in
#' English and `Ja`, `Nej` and `Blank` in Swedish; Blank is valid and separate
#' from invalid ballots.
#'
#' `source = "auto"` selects approved canonical coverage for the requested
#' election family, event, year and view; otherwise it uses a supported remote
#' source. It never discovers local raw files. Explicit `canonical`, `remote`
#' and `local` choices are described in [data_sources]. Historical canonical
#' data need no developer archive. `local` requires the user's own compatible
#' sources, selected through `data_dir` or the documented raw-root options.
#'
#' The published data-v0.4.1 generation covers ordinary RKL 2002--2022, EU
#' 2004--2024, the final 2003 referendum, five re-election results/seats events
#' and completed-period histories for 2014/2018. Coverage varies by function,
#' geography and counting stage; RKL 2002 candidacies and EU 2009 canonical
#' preference votes are excluded. Supported 2026 election data and current
#' 2022 mandate history use their separate remote sources.
#'
#' `update` and `archive` apply only to supported raw-source operations, not
#' canonical data. They do not make automatic selection choose a local archive.
#' See [data_sources] and the function help for requirements and restrictions.
#' @importFrom utils download.file unzip
#' @keywords internal
"_PACKAGE"
