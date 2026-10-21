# R-only unpublished EU 2019 canonical prototype.
# Rscript data-raw/build-canonical-eu-2019.R RAW_ROOT EMPTY_OUTPUT_DIR
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
roles <- swelections:::.eu2019_sources()
files <- setNames(vapply(roles$role,function(r)swelections:::.eu2019_file(r,'local',args[[1]]),''),roles$role)
sources <- transform(roles,file=basename(files),bytes=unname(file.info(files)$size),
 md5=unname(tools::md5sum(files)))
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
sources$retrieved_at_utc <- c(NA_character_, NA_character_, '2026-10-15T12:58:02Z',
 NA_character_, '2026-10-15T13:18:06Z', '2026-10-15T12:58:03Z')
sources$retrieval_note <- ifelse(is.na(sources$retrieved_at_utc),
 'Original preserved archive; original retrieval timestamp unavailable.',
 'Official source retrieved and hash-verified during the approved inventory.')
for(stage in c('final','preliminary')) {
 for(table in c('results','seats')) {
  levels <- if(table=='results') swelections:::.eu2024_levels else 'riket'
  parts <- setNames(lapply(levels,function(l)do.call(get(table),list(year=2019,election='E',
   level=names(swelections:::.english_argument_values$level)[match(l,swelections:::.english_argument_values$level)],
   count=stage,source='local',data_dir=args[[1]],names='sv',detail='full'))),levels)
  save_asset(parts,paste0('eu2019-',table,'-',stage))
 }
}
for(fun in c('candidacies','candidates','elected','substitutes'))
 save_asset(do.call(get(fun),list(year=2019,election='E',source='local',data_dir=args[[1]],names='sv',detail='full')),paste0('eu2019-',fun))
save_asset(candidates(2019,election='E',include_results=FALSE,source='local',data_dir=args[[1]],names='sv',detail='full'),'eu2019-candidate-base')
bundle <- swelections:::.eu2019_bundle(list(source='local',data_dir=args[[1]]))
short <- c(personvalsomrade='area',riket='national',lan='county',kommun='municipality',kommunvalkrets='municipal-constituency',valdistrikt='district')
for(level in names(short)) {
 b <- swelections:::.eu2019_preference_base(bundle,level)
 names(b$votes)[names(b$votes)=='kandidatnamn_lista']<-'kandidatnamn_raw'
 b$qualified <- bundle$qualified
 for(n in names(b)) {
  names(b[[n]])[names(b[[n]])=='.geo']<-'kall_enhetskod'
  names(b[[n]])[names(b[[n]])=='listnummer']<-'listnummer_raw'
 }
 save_asset(b,paste0('eu2019-preference-base-',short[[level]]))
}
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
manifest <- list(data_version='data-v0.4.0',schema_version=3L,value_schema_version=1L,storage_schema_version=1L,format='parquet',valserie='eu',valar=2019L,
 release_status='unpublished_local_validation_build',auto_eligible=FALSE,
 built_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
 build_commit=trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE)),
 build_tree_dirty=length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L,
 sources=sources,assets=purrr::list_rbind(assets),tables=purrr::list_rbind(tables),
 source_selection=list(final='Preserved original final XML: original 20-seat election, before Brexit/mandate-period changes.',
 preliminary='Complete 29 May preliminary XML: 5984 ordinary plus 321 Wednesday units; ten named parties and aggregated other parties. Final party detail is never inserted into preliminary data.',
 handwritten='Official handwritten-party XLS replaces the final XML residual exactly at each source unit; labels resolve uniquely through the official party registry.',
 electorate='Pinned freshly retrieved official SKV reconciles with all final XML districts. Older local snapshot (983 extra voters) excluded. Wednesday electorate and turnout remain NA.',
 candidacies='562 source rows, 556 valid candidacies. Redacted official names are public NA. Official candidate numbers are not asserted longitudinal physical-person IDs.',
 preference='All reported list/candidate records including invalid candidacies are preserved. Party-level PERSONVAL duplicates are not added. Ballot position KANDIDAT differs from preference rank ORDNING.',
 identity='Candidate joins use official candidate number plus party/list, never names. No additional identity harmonisation.',
 coverage='No separate election-night freeze or mandate-period history is asserted. EU is one national mandate/preference-vote constituency. Municipal constituency excludes technical 00 branches.'))
source("data-raw/canonical-build-contract.R")
manifest <- canonical_build_contract(manifest)
jsonlite::write_json(manifest,file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
cat('PASS EU 2019 prototype build:',length(assets),'assets\n')
