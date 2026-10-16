# R-only unpublished EU 2009 canonical prototype.
# Rscript data-raw/build-canonical-eu-2009.R RAW_ROOT EMPTY_OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop('Specify RAW_ROOT EMPTY_OUTPUT_DIR.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('nanoparquet', quietly = TRUE)) stop('Install optional nanoparquet for builds.')
out <- args[[2]]
if (dir.exists(out) && length(list.files(out, all.files=TRUE, no..=TRUE))) stop('Use an empty output directory.')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
assets <- tables <- list()
save_asset <- function(parts, asset) {
  if (is.data.frame(parts)) x <- swelections:::.canonical_names_en(parts) else {
    tables[[length(tables)+1L]] <<- data.frame(asset=asset, table=names(parts),
      columns=vapply(parts, function(d) paste(names(swelections:::.canonical_names_en(d)), collapse=','), ''))
    x <- purrr::list_rbind(lapply(names(parts), function(n) {
      d <- swelections:::.canonical_names_en(parts[[n]]); d$.table <- rep(n,nrow(d)); d
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
roles <- swelections:::.eu2009_sources()
files <- setNames(vapply(roles$role,function(r)swelections:::.eu2009_file(r,'local',args[[1]]),''),roles$role)
sources <- transform(roles,file=basename(files),bytes=unname(file.info(files)$size),
 md5=unname(tools::md5sum(files)))
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
sources$retrieved_at_utc <- NA_character_
sources$archive_capture_utc <- c(NA_character_,'2010-02-10T20:32:52Z','2013-10-31T21:34:01Z',NA_character_,NA_character_)
sources$source_update_time <- c('20090611160957','20090607232501',NA_character_,NA_character_,NA_character_)
sources$retrieval_note <- 'Preserved original archive; original retrieval time unavailable.'
for(stage in 'final') {
 for(table in c('results','seats')) {
  levels <- if(table=='results') swelections:::.eu2024_levels else 'riket'
  parts <- setNames(lapply(levels,function(l)do.call(get(table),list(year=2009,election='E',
   level=names(swelections:::.english_argument_values$level)[match(l,swelections:::.english_argument_values$level)],
   count=stage,source='local',data_dir=args[[1]],names='sv',detail='full'))),levels)
  save_asset(parts,paste0('eu2009-',table,'-',stage))
 }
}
for(fun in c('candidacies','candidates','elected','substitutes'))
 save_asset(do.call(get(fun),list(year=2009,election='E',source='local',data_dir=args[[1]],names='sv',detail='full')),paste0('eu2009-',fun))
save_asset(candidates(2009,election='E',include_results=FALSE,source='local',data_dir=args[[1]],names='sv',detail='full'),'eu2009-candidate-base')
bundle <- swelections:::.eu2009_bundle(list(source='local',data_dir=args[[1]]))
save_asset(bundle$source_designations,'eu2009-source-designations')
short <- c(personvalsomrade='area',riket='national',lan='county',kommun='municipality',kommunvalkrets='municipal-constituency',valdistrikt='district')
for(level in names(short)) {
 b <- swelections:::.eu2009_preference_base(bundle,level)
 names(b$votes)[names(b$votes)=='kandidatnamn_lista']<-'kandidatnamn_raw'
 b$qualified <- bundle$qualified
 for(n in names(b)) {
  names(b[[n]])[names(b[[n]])=='.geo']<-'kall_enhetskod'
  names(b[[n]])[names(b[[n]])=='listnummer']<-'listnummer_raw'
 }
 save_asset(b,paste0('eu2009-preference-base-',short[[level]]))
}
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
manifest <- list(data_version='data-v0.0.0',schema_version=2L,format='parquet',valserie='eu',valar=2009L,
 release_status='unpublished_local_validation_build',auto_eligible=FALSE,
 built_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
 build_commit=trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE)),
 build_tree_dirty=length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L,
 sources=sources,assets=purrr::list_rbind(assets),tables=purrr::list_rbind(tables),
 source_selection=list(final='Pinned original named final XML, 11 June 2009; original 18 seats only.',
 preliminary='Election-night ordinary districts are provenance only; full Wednesday preliminary snapshot not verified.',
 handwritten='1127 exact designation votes plus three source-designation-unreported votes; original XML residual retained.',
 candidacies='500 ballot/list-position observations from archived June 7 XML. Generated candidacy keys are not person IDs. SCB reports488 persons; exact cross-list linkage is not verified.',
 preference_votes='Main11 parties reconcile. Small-party source-column observations are independent of ballot IDs: national2665, county/municipal2677 versus XML aggregate2655; no inferred Wednesday or constituency allocation.',
 identity='No name-only deduplication or cross-list person linkage. Two Per Johansson ballot positions18/32 are distinct; identical source columns36/47 retained.',
 electorate='Final official district electorate matches XML; Wednesday electorate/turnout remain NA.'))
jsonlite::write_json(manifest,file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
cat('PASS EU2009 prototype build:',length(assets),'assets\n')
