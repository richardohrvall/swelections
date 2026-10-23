# Rscript data-raw/build-canonical-re-elections.R ARCHIVE_ROOT ORSA_RERUN_XML EMPTY_OUTPUT
# Final results/seats only. Five events, four manifests, ten assets.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop('Specify ARCHIVE_ROOT ORSA_RERUN_XML EMPTY_OUTPUT.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('nanoparquet', quietly = TRUE)) stop('Install nanoparquet.')
root <- args[1]; orsa <- args[2]; output <- args[3]
if (dir.exists(output) && length(list.files(output, all.files = TRUE, no.. = TRUE)))
  stop('Use an empty output directory.')
if (!dir.exists(root) || !file.exists(orsa)) stop('Missing preserved sources.')
options(swelections.re_election_sources = list(
  `SE-KF-2003-03-16-2034` = list(final = orsa, seats = orsa)))
source('data-raw/canonical-build-contract.R')
inv <- read.csv('development/SOURCE_INVENTORY_OMVAL_FILES.csv')
stopifnot(all(unname(tools::sha256sum(inv$path)) == inv$sha256))
portable <- function(p) {
  p <- gsub(intToUtf8(92L), '/', normalizePath(p, winslash = '/', mustWork = TRUE), fixed = TRUE)
  if (grepl('/omval/', p, fixed = TRUE)) return(sub('^.*?/omval/', 'omval/', p))
  if (grepl('/rkl/', p, fixed = TRUE)) return(sub('^.*?/rkl/', 'rkl/', p))
  paste0('preserved/', basename(p))
}
events <- swelections:::.re_elections()
ledger <- list(); manifests <- character()
for (year in unique(events$election_year)) {
  dest <- file.path(output, as.character(year)); dir.create(dest, recursive = TRUE)
  selected <- events[events$election_year == year, ]; assets <- layouts <- inputs <- vector_names <- list()
  for (i in seq_len(nrow(selected))) {
    e <- selected[i, ]
    for (table in c('results', 'seats')) {
      levels <- if (table == 'results') {
        if (e$election_code == 'RF') c('region','regional_constituency','municipality','district') else
          if (e$scope_level == 'municipal_constituency') c('municipality','municipal_constituency','district') else c('municipality','district')
      } else if (e$election_code == 'RF') c('region','regional_constituency') else
        if (e$scope_level == 'municipal_constituency') c('municipality','municipal_constituency') else 'municipality'
      f <- swelections:::.re_file(e, root, if (table == 'results') 'final' else 'seats')
      inputs[[length(inputs)+1L]] <- data.frame(event=e$election_event, role=table,
        file=portable(f$path), bytes=unname(file.info(f$path)$size),
        md5=unname(tools::md5sum(f$path)), sha256=f$sha256, source_url=e$source_url,
        protocol_reference=e$protocol_reference)
      asset <- swelections:::.re_canonical_asset(e, table)
      parts <- lapply(levels, function(level) {
        a <- list(year=year,election=e$election_code,election_kind='re_election',
          source='local',data_dir=root,level=level,progress=FALSE,names='en')
        full <- do.call(get(table), c(a,list(detail='full')))
        standard <- do.call(get(table), c(a,list(detail='standard')))
        stopifnot(identical(full[names(standard)],standard),all(full$event_scope_code==e$scope_code))
        full$source_file[] <- portable(f$path)
        named <- vapply(full, function(z) !is.null(names(z)), logical(1))
        vector_names[[asset]][[level]] <<- lapply(full[named], names)
        layouts[[length(layouts)+1L]] <<- data.frame(asset=asset,table=level,
          columns=paste(names(full),collapse=','),standard_columns=paste(names(standard),collapse=','))
        full$.table <- level; full
      })
      x <- dplyr::bind_rows(parts); x[] <- lapply(x, unname)
      p <- file.path(dest,paste0(asset,'.parquet'))
      nanoparquet::write_parquet(x,p,compression='gzip')
      stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(p))))
      assets[[length(assets)+1L]] <- data.frame(asset,file=basename(p),rows=nrow(x),
        bytes=unname(file.info(p)$size),sha256=swelections:::.canonical_sha256(p),
        election_event=e$election_event,role=table)
    }
    if (!is.na(e$geography_file)) {
      f <- swelections:::.re_file(e,root)
      p <- file.path(dirname(f$path),e$geography_file)
      stopifnot(swelections:::.canonical_sha256(p)==e$geography_sha256)
      inputs[[length(inputs)+1L]] <- data.frame(event=e$election_event,role='geography',
        file=portable(p),bytes=unname(file.info(p)$size),md5=unname(tools::md5sum(p)),
        sha256=e$geography_sha256,source_url=e$source_url,protocol_reference=e$protocol_reference)
    }
  }
  m <- canonical_build_contract(list(format='parquet',valserie='rkl',valar=year,
    event_kind='re_election',auto_eligible=TRUE,auto_functions=c('results','seats'),
    events=selected[setdiff(names(selected),'verified_allocation')],
    sources=dplyr::bind_rows(inputs),assets=dplyr::bind_rows(assets),tables=dplyr::bind_rows(layouts),
    column_names_attributes=vector_names,
    limitations=list(functions='results and seats only; five candidate-related readers not implemented',
      stages='final only; no preliminary substitution',
      scope='Nordostra is 17 seats, not all Orebro; national ZIP placeholders excluded',
      source_paths='portable provenance labels, not operational input paths',
      publication='unpublished data-v0.4.1 candidate; approval and clean rebuild required')))
  p <- file.path(dest,paste0('rkl',year,'-re-election-manifest.json'))
  jsonlite::write_json(m,p,pretty=TRUE,auto_unbox=TRUE,na='null')
  swelections:::.canonical_manifest(p)
  manifests <- c(manifests,p); ledger[[length(ledger)+1L]] <- m$assets
  cat('PASS',year,nrow(m$assets),'assets; dirty =',m$build_tree_dirty,'\n');flush.console()
}
stopifnot(all(unname(tools::sha256sum(inv$path))==inv$sha256))
write.csv(data.frame(manifest=manifests),file.path(output,'manifests.csv'),row.names=FALSE)
write.csv(dplyr::bind_rows(ledger),file.path(output,'asset-inventory.csv'),row.names=FALSE)
cat('PASS ten unpublished assets/four manifests; all original source hashes unchanged\n')
