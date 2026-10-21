# Unpublished EU build; explicit source="canonical" never changes auto eligibility.
.eu2014_canonical <- function(table, args) {
  path <- .canonical_manifest_path(2014L, "eu", auto_selected = isTRUE(args$.canonical_auto))
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop('EU 2014 canonical data require a configured local build manifest.', call. = FALSE)
  manifest <- .canonical_manifest(path)
  if (!identical(manifest$valserie, 'eu') || as.integer(manifest$valar) != 2014L ||
      as.integer(manifest$schema_version) != 3L || !identical(manifest$format, 'parquet'))
    stop('Expected EU 2014 English Parquet schema version 3.', call. = FALSE)
  fetch <- .canonical_fetcher(manifest, path)
  count <- if (is.null(args$rakning)) 'slutlig' else args$rakning
  if(count != 'slutlig') stop('EU 2014 has no recovered complete preliminary Wednesday snapshot.',call.=FALSE)
  if (table %in% c('results', 'seats')) {
    stage <- if (count == 'slutlig') 'final' else 'preliminary'
    level <- if (is.null(args$niva)) 'riket' else args$niva
    if (length(level) != 1L || !level %in% if (table == 'results') .eu2024_levels else 'riket')
      stop('Unsupported EU canonical geographic level.', call. = FALSE)
    asset <- paste0('eu2014-', table, '-', stage)
    return(.canonical_table(manifest, fetch(asset), asset, level))
  }
  if (table == 'preference_votes') {
    level <- args$niva
    short <- c(personvalsomrade='area', riket='national', lan='county',
      kommun='municipality', kommunvalkrets='municipal-constituency', valdistrikt='district')
    if (length(level) != 1L || !level %in% names(short)) stop('Unsupported EU preference level.', call. = FALSE)
    asset <- paste0('eu2014-preference-base-', short[[level]])
    data <- fetch(asset)
    components <- c('votes', 'lists', 'parties', 'context')
    base <- stats::setNames(lapply(components, function(n)
      .canonical_table(manifest, data, asset, n)), components)
    for (n in names(base)) {
      names(base[[n]])[names(base[[n]]) == 'kall_enhetskod'] <- '.geo'
      names(base[[n]])[names(base[[n]]) == 'listnummer_raw'] <- 'listnummer'
    }
    names(base$votes)[names(base$votes) == 'kandidatnamn_raw'] <- 'kandidatnamn_lista'
    q <- .canonical_table(manifest, data, asset, 'qualified')
    kd <- .canonical_names_sv(fetch('eu2014-candidacies'))
    return(.eu2024_preference_view(base, level, kd, args$per_lista,
      args$komplettera_nollor, paste(q$partikod, q$kandidatnummer), 2014L))
  }
  if (table == 'candidates' && identical(args$resultat, FALSE)) table <- 'candidate-base'
  .canonical_names_sv(fetch(paste0('eu2014-', table)))
}
