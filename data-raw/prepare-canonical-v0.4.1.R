# Prepare a new immutable data-v0.4.1 candidate from the frozen v0.4.0 download set.
# Rscript data-raw/prepare-canonical-v0.4.1.R FROZEN_DOWNLOADS RAW_ROOT ORSA_XML EMPTY_OUTPUT
# Only history is rebuilt; 188 unchanged assets are copied with checked hashes.
prepare_canonical_v041 <- function(frozen, root, orsa, output) {
  if (dir.exists(output) && length(list.files(output,all.files=TRUE,no..=TRUE)))
    stop('Use an empty output directory.')
  frozen<-normalizePath(frozen,winslash='/');root<-normalizePath(root,winslash='/')
  orsa<-normalizePath(orsa,winslash='/')
  if(!file.exists(orsa))stop('Missing preserved Orsa source.')
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  output<-normalizePath(output,winslash='/')
  pkgload::load_all('.',quiet=TRUE)
  before<-list.files(frozen,pattern='[.](parquet|json)$',full.names=TRUE)
  hashes<-vapply(before,swelections:::.canonical_sha256,'')
  stopifnot(length(before)==202L)
  source('data-raw/build-canonical-mandate-history.R',local=TRUE)
  registry<-swelections:::.canonical_release_registry()
  ordinary<-registry[registry$event_kind=='ordinary',]
  paths<-file.path(frozen,ordinary$manifest_file)
  for(y in c(2014L,2018L)) {
    i<-which(ordinary$series=='rkl' & ordinary$year==y)
    paths[i]<-build_canonical_mandate_history(y,paths[i],root,
      file.path(output,paste0('history-',y)))
  }
  reruns<-file.path(output,'re-elections')
  status<-system2(file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe'else'Rscript'),
    c('data-raw/build-canonical-re-elections.R',shQuote(file.path(root,'omval')),
      shQuote(orsa),shQuote(reruns)))
  if(status!=0L)stop('Re-election build failed.')
  paths<-c(paths,read.csv(file.path(reruns,'manifests.csv'))$manifest)
  inputs<-file.path(output,'manifests.csv')
  write.csv(data.frame(manifest=paths),inputs,row.names=FALSE)
  source('data-raw/prepare-canonical-release.R',local=TRUE)
  inventory<-prepare_canonical_release(paths,file.path(output,'distribution'),allow_dirty=TRUE)
  stopifnot(sum(inventory$kind=='parquet')==200L,sum(inventory$kind=='manifest')==16L,
    identical(unname(hashes),unname(vapply(before,swelections:::.canonical_sha256,''))))
  old<-basename(before[endsWith(before,'.parquet')])
  changed<-vapply(old,function(f) swelections:::.canonical_sha256(file.path(frozen,f))!=
    swelections:::.canonical_sha256(file.path(output,'distribution','upload',f)),logical(1))
  stopifnot(setequal(old[changed],paste0('rkl',c(2014,2018),'-mandate-history.parquet')))
  write.csv(data.frame(file=old,changed=changed),file.path(output,'v0.4.0-comparison.csv'),row.names=FALSE)
  cat('PASS 200 assets, 16 manifests; exactly two old assets replaced, ten added; 188 byte-identical.\n')
  invisible(inputs)
}
if(sys.nframe()==0L) {
  a<-commandArgs(TRUE);if(length(a)!=4L)stop('Specify FROZEN_DOWNLOADS RAW_ROOT ORSA_XML EMPTY_OUTPUT.')
  prepare_canonical_v041(a[1],a[2],a[3],a[4])
}
