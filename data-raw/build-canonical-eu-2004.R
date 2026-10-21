# R-only unpublished EU 2004 canonical prototype.
# Rscript data-raw/build-canonical-eu-2004.R RAW_ROOT EMPTY_OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop('Specify RAW_ROOT EMPTY_OUTPUT_DIR.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('nanoparquet', quietly = TRUE)) stop('Install optional nanoparquet for builds.')
out <- args[[2]]
if (dir.exists(out) && length(list.files(out, all.files=TRUE, no..=TRUE))) stop('Use an empty output directory.')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
assets <- tables <- list()
save_asset <- function(parts, asset) {
  if (is.data.frame(parts)) x <- swelections:::.canonical_encode(parts) else {
    tables[[length(tables)+1L]] <<- data.frame(asset=asset, table=swelections:::.canonical_storage_key(names(parts)),
      columns=vapply(parts, function(d) paste(names(swelections:::.canonical_encode(d)), collapse=','), ''))
    x <- purrr::list_rbind(lapply(names(parts), function(n) {
      d <- swelections:::.canonical_encode(parts[[n]]); d$.table <- rep(swelections:::.canonical_storage_key(n),nrow(d)); d
    }))
  }
  x[] <- lapply(x, unname)
  f <- file.path(out,paste0(asset,'.parquet'))
  nanoparquet::write_parquet(x,f,compression='gzip')
  stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(f))))
  assets[[length(assets)+1L]] <<- data.frame(asset=asset,file=basename(f),rows=nrow(x),
    bytes=unname(file.info(f)$size),sha256=swelections:::.canonical_sha256(f))
  cat('PASS Parquet',asset,nrow(x),'\n');flush.console()
}
roles <- swelections:::.eu2004_sources()
files <- setNames(vapply(roles$role,function(r)swelections:::.eu2004_file(r,'local',args[[1]]),''),roles$role)
sources <- transform(roles,file=basename(files),bytes=unname(file.info(files)$size),
 md5=unname(tools::md5sum(files)))
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
sources$retrieved_at_utc <- NA_character_
sources$retrieval_note <- 'Pinned preserved official sources; archive capture and original URL retained in url. See source inventory acquisition ledger.'
for(stage in 'final') {
 for(table in c('results','seats')) {
  levels <- if(table=='results') swelections:::.eu2024_levels else 'riket'
  parts <- setNames(lapply(levels,function(l)do.call(get(table),list(year=2004,election='E',
   level=names(swelections:::.english_argument_values$level)[match(l,swelections:::.english_argument_values$level)],
   count=stage,source='local',data_dir=args[[1]],names='sv',detail='full'))),levels)
  save_asset(parts,paste0('eu2004-',table,'-',stage))
 }
}
for(fun in c('candidacies','candidates','elected','substitutes'))
 save_asset(do.call(get(fun),list(year=2004,election='E',source='local',data_dir=args[[1]],names='sv',detail='full')),paste0('eu2004-',fun))
save_asset(candidates(2004,election='E',include_results=FALSE,source='local',data_dir=args[[1]],names='sv',detail='full'),'eu2004-candidate-base')
bundle <- swelections:::.eu2004_bundle(list(source='local',data_dir=args[[1]]))
save_asset(bundle$source_designations,'eu2004-source-designations')
short <- c(personvalsomrade='area',riket='national',lan='county',kommun='municipality',kommunvalkrets='municipal-constituency',valdistrikt='district')
for(level in names(short)) {
 b <- swelections:::.eu2019_preference_base(bundle,level)
 names(b$votes)[names(b$votes)=='kandidatnamn_lista']<-'kandidatnamn_raw'
 b$qualified <- bundle$qualified
 for(n in names(b)) {
  names(b[[n]])[names(b[[n]])=='.geo']<-'kall_enhetskod'
  names(b[[n]])[names(b[[n]])=='listnummer']<-'listnummer_raw'
 }
 save_asset(b,paste0('eu2004-preference-base-',short[[level]]))
}
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
manifest <- list(data_version='data-v0.4.0',schema_version=3L,value_schema_version=1L,storage_schema_version=1L,format='parquet',valserie='eu',valar=2004L,
 release_status='unpublished_local_validation_build',auto_eligible=FALSE,
 built_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
 build_commit=trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE)),
 build_tree_dirty=length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L,
 sources=sources,assets=purrr::list_rbind(assets),tables=purrr::list_rbind(tables),
 source_selection=list(
 final='17 June 2004 legally established final result; original named XML and district exports.',
 other_parties='943 valid handwritten votes for parties which did not order ballots, reported only as an aggregate. No inferred party/candidate assignment.',
 preliminary='Complete election-night ordinary districts retained as provenance; no complete preliminary Wednesday snapshot recovered.',
 candidacies='382 source ballot/list-position observations on30 ballots for27 parties. Generated candidacy keys are not person IDs; SCB372 nominees use a different counting population.',
 preference_votes='All reported preferences reconcile:1480960, including SD14450. SCB SSD270 erroneous SD zero cells are not used; protocol appendix1 confirms the values.',
 identity='No name-only deduplication, cross-list or longitudinal person linkage.',
 electorate='Eligible6827870; Wednesday electorate and turnout remain NA.'))
source("data-raw/canonical-build-contract.R")
manifest <- canonical_build_contract(manifest)
jsonlite::write_json(manifest,file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
cat('PASS EU2004 prototype build:',length(assets),'assets\n')
