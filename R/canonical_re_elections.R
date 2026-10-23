# Canonical reader for approved final re-election results and seats.
# Several events may share a year, so assets are keyed by scope, not year alone.
.re_canonical_asset <- function(event, table) {
  if (!table %in% c('results', 'seats'))
    stop('No canonical re-election coverage for this function.', call. = FALSE)
  paste0('rkl', event$election_year, '-re-election-', tolower(event$election_code),
         '-', event$scope_code, '-', table, '-final')
}

.re_canonical_covered <- function(manifest, surface, val, niva, rakning) {
  table <- c(valresultat = 'results', mandat = 'seats')[surface]
  if (length(table) != 1L || is.na(table) || rakning != 'slutlig') return(FALSE)
  events <- .re_elections()
  events <- events[events$election_year == as.integer(manifest$valar) &
                     events$election_code %in% val, ]
  if (!nrow(events)) return(FALSE)
  all(vapply(seq_len(nrow(events)), function(i) {
    e <- events[i, ]; asset <- .re_canonical_asset(e, unname(table))
    levels <- if (is.null(niva)) .canonical_storage_key(e$scope_level) else
      .canonical_storage_key(niva)
    asset %in% manifest$assets$asset &&
      all(levels %in% manifest$tables$table[manifest$tables$asset == asset])
  }, logical(1)))
}

.re_canonical_read <- function(event, table, level, detail, language,
                               auto_selected = FALSE) {
  .canonical_require_reader()
  path <- .canonical_manifest_path(event$election_year, 'rkl', 're_election',
                                   auto_selected = auto_selected)
  manifest <- .canonical_manifest(path)
  asset <- .re_canonical_asset(event, table)
  if (!identical(manifest$event_kind, 're_election') ||
      !.re_canonical_covered(manifest, if (table == 'results') 'valresultat' else 'mandat',
                            event$election_code, level, 'slutlig'))
    stop('Canonical re-election view is unavailable for the requested scope.', call. = FALSE)
  entry <- manifest$tables[manifest$tables$asset == asset &
                            manifest$tables$table == .canonical_storage_key(level), , drop = FALSE]
  if (nrow(entry) != 1L || !'standard_columns' %in% names(entry))
    stop('Canonical re-election table layout is invalid.', call. = FALSE)
  fetch <- .canonical_fetcher(manifest, path)
  data <- fetch(asset)
  columns <- strsplit(entry[[if (detail == 'full') 'columns' else 'standard_columns']],
                       ',', fixed = TRUE)[[1L]]
  out <- data[data$.table == entry$table, columns, drop = FALSE]
  if (!nrow(out) || !all(out$election_event == event$election_event) ||
      !all(out$event_scope_code == event$scope_code) ||
      !all(out$election_year == event$election_year) ||
      !all(out$election_code == event$election_code) ||
      !all(out$election_date == event$election_date) ||
      !all(out$original_election_event == event$original_election_event) ||
      !all(out$mandate_period == event$mandate_period) ||
      !all(out$count_stage == 'final'))
    stop('Canonical re-election rows do not match the verified event.', call. = FALSE)
  if (table == 'seats') .re_verify_allocation(out, event)
  attributes <- manifest$column_names_attributes[[asset]][[entry$table]]
  for (column in intersect(names(attributes), names(out))) {
    labels <- unname(attributes[[column]])
    if (length(labels) != nrow(out)) stop('Invalid canonical vector names.', call. = FALSE)
    names(out[[column]]) <- labels
  }
  .public_output(.canonical_names_sv(out), language)
}
