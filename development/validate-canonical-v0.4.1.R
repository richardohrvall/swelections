# Validate the unpublished v0.4.1 distribution; no live publication is performed.
# Rscript development/validate-canonical-v0.4.1.R CANDIDATE FROZEN_DOWNLOADS EMPTY_OUTPUT
args<-commandArgs(TRUE);if(length(args)!=3L)stop('Specify CANDIDATE FROZEN_DOWNLOADS EMPTY_OUTPUT.')
root<-args[1];frozen<-args[2];out<-args[3]
if(dir.exists(out)&&length(list.files(out,all.files=TRUE,no..=TRUE)))stop('Use empty validation output.')
dir.create(out,recursive=TRUE)
pkgload::load_all('.',quiet=TRUE)
source('data-raw/prepare-canonical-release.R')
upload<-file.path(root,'distribution','upload');inv<-read.csv(file.path(root,'distribution','upload-inventory.csv'))
stopifnot(nrow(inv)==216L,sum(inv$kind=='parquet')==200L,sum(inv$kind=='manifest')==16L,
 !anyDuplicated(inv$file),all(file.exists(file.path(upload,inv$file))))
reg<-.canonical_release_registry();stopifnot(nrow(reg)==16L,all(reg$auto_eligible),
 all(reg$data_version=='data-v0.4.1'),sum(reg$event_kind=='re_election')==4L)
for(i in seq_len(nrow(inv)))stopifnot(file.info(file.path(upload,inv$file[i]))$size==inv$bytes[i],
 .canonical_sha256(file.path(upload,inv$file[i]))==inv$sha256[i])
roundtrip<-file.path(out,'roundtrip');dir.create(roundtrip)
for(f in inv$file[inv$kind=='parquet']) {
 p<-file.path(upload,f);x<-tibble::as_tibble(nanoparquet::read_parquet(p));q<-file.path(roundtrip,f)
 nanoparquet::write_parquet(x,q,compression='gzip')
 stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(q))))
 # Older files may use a different writer/compression; content roundtrip is required.
 if(grepl('re-election|mandate-history',f))stopifnot(.canonical_sha256(q)==.canonical_sha256(p))
}
for(f in inv$file[inv$kind=='manifest']) {
 m<-.canonical_manifest(file.path(upload,f))
 stopifnot(m$data_version=='data-v0.4.1',m$schema_version==3L,
 m$value_schema_version==1L,m$storage_schema_version==1L,length(.release_absolute_paths(m))==0L,
 all(m$assets$file %in% inv$file),all(m$tables$asset %in% m$assets$asset))
 if(!is.null(m$mandate_history))stopifnot(m$mandate_history$interval_schema_version==2L)
}
old<-list.files(frozen,pattern='[.]parquet$',full.names=TRUE)
changed<-vapply(old,function(p).canonical_sha256(p)!=.canonical_sha256(file.path(upload,basename(p))),logical(1))
stopifnot(length(old)==190L,setequal(basename(old[changed]),paste0('rkl',c(2014,2018),'-mandate-history.parquet')))
write.csv(data.frame(file=basename(old),changed=changed),file.path(out,'old-asset-comparison.csv'),row.names=FALSE)
cat('PASS 200 assets, 16 portable manifests, schema/checksums/roundtrips; 188 original assets byte-identical\n');flush.console()
# Exercise the real activated registry with no configured manifests or raw archive.
# Only transport is replayed from the unpublished upload set, never routing decisions.
options(swelections.canonical_manifest=NULL,swelections.canonical_assets_dir=NULL,
 swelections.canonical_base_url=NULL,swelections.canonical_cache_dir=file.path(out,'fresh-cache'),
 swelections.data_dir=NULL,valresultat.data_dir=NULL)
base<-'https://github.com/richardohrvall/swelections/releases/download/data-v0.4.1/'
requests<-character();checks<-list()
bridge<-function(url,destfile,...) {
 stopifnot(startsWith(url,base),basename(url)%in%inv$file)
 requests<<-c(requests,url);stopifnot(file.copy(file.path(upload,basename(url)),destfile))
 invisible(destfile)
}
record<-function(product,view,lang,detail,rows) {
 checks[[length(checks)+1L]]<<-data.frame(product,view,language=lang,detail,rows,status='PASS')
}
testthat::with_mocked_bindings({
 for(i in seq_len(nrow(reg))) {
  e<-reg[i,];views<-setdiff(e$auto_functions[[1]],c('mandate_history','members_at','vacant_seats_at'))
  if(e$event_kind=='re_election') {
   events<-.re_elections();events<-events[events$election_year==e$year,]
   for(j in seq_len(nrow(events)))for(view in views)for(lang in c('en','sv'))for(detail in c('standard','full')) {
    a<-list(year=e$year,election=events$election_code[j],election_kind='re_election',names=lang,detail=detail)
    x<-do.call(get(view),a);z<-do.call(get(view),c(a,list(source='canonical')))
    stopifnot(identical(x,z),all(x[[if(lang=='en')'event_scope_code'else'valhandelse_omfattningskod']]==events$scope_code[j]))
    record(events$election_event[j],view,lang,detail,nrow(x))
   }
  } else for(view in views)for(ec in if(e$series=='rkl')c('RD','RF','KF')else if(e$series=='eu')'E'else'F')
  for(lang in c('en','sv'))for(detail in c('standard','full')) {
   a<-list(year=e$year,names=lang,detail=detail)
   a$election<-ec
   x<-do.call(get(view),a);z<-do.call(get(view),c(a,list(source='canonical')))
   stopifnot(identical(x,z))
   if(lang=='sv') {
    aliases<-c(results='valresultat',seats='mandat',candidacies='kandidaturer',candidates='kandidater',
      elected='valda',substitutes='ersattare',preference_votes='personroster')
    sv<-do.call(get(aliases[[view]]),list(ar=e$year,val=ec,names='sv',detaljniva=detail))
    stopifnot(identical(x,sv))
   }
   record(paste(e$series,e$year,ec,sep=':'),view,lang,detail,nrow(x))
  }
 }
 for(y in c(2014L,2018L))for(ec in c('ALL','RD','RF','KF'))for(view in c('mandate_history','members_at','vacant_seats_at'))
 for(lang in c('en','sv'))for(detail in c('standard','full')) {
  a<-list(year=y,names=lang,detail=detail)
  if(ec!='ALL')a$election<-ec
  if(view!='mandate_history')a$date<-if(y==2014L)'2016-01-01'else'2020-01-01'
  x<-do.call(get(view),a);stopifnot(identical(x,do.call(get(view),c(a,list(source='canonical')))))
  if(lang=='sv') {
   aliases<-c(mandate_history='mandathistorik',members_at='ledamoter_vid',vacant_seats_at='tomma_stolar_vid')
   b<-list(ar=y,names='sv',detaljniva=detail);if(ec!='ALL')b$val<-ec
   if(view!='mandate_history')b$datum<-a$date
   stopifnot(identical(x,do.call(get(aliases[[view]]),b)))
  }
  record(paste('history',y,ec,sep=':'),view,lang,detail,nrow(x))
 }
 for(i in seq_len(nrow(.re_elections()))) {
  e<-.re_elections()[i,];x<-seats(e$original_year,e$election_code,after_re_election=TRUE)
  key<-if(e$election_code=='RF')'region_code'else'municipality_code'
  z<-x[x[[key]]==e$electoral_area_code,];stopifnot(sum(z$seats)==if(e$scope_code=='188004')65L else e$seats_expected)
  if(e$scope_code=='188004')stopifnot(sum(z$seats[z$component_election_year==2010])==48L,
    sum(z$seats[z$component_election_year==2011])==17L)
 }
 for(y in c(2002L,2010L))stopifnot(inherits(tryCatch(mandate_history(y),error=identity),'error'))
 stopifnot(.select_public_source('auto',2022,'mandate_history')=='auto',
 .select_public_source('auto',2026,'results',val='KF')=='auto',
 .select_public_source('auto',2009,'preference_votes',series='eu',val='E')=='auto',
 .select_public_source('auto',2002,'candidacies')=='auto')
 for(y in c(2003L,2011L,2015L,2019L))for(view in c('candidacies','candidates','elected','substitutes','preference_votes')) {
  stopifnot(.select_public_source('auto',y,view,event_kind='re_election')=='auto',
   inherits(tryCatch(.select_public_source('canonical',y,view,event_kind='re_election'),error=identity),'error'))
 }
},.download_file=bridge,.re_file=function(...)stop('raw source access forbidden'),
 .mh_files=function(...)stop('raw source access forbidden'),.package='swelections')
stopifnot(length(unique(requests[endsWith(requests,'.json')]))==16L)
write.csv(dplyr::bind_rows(checks),file.path(out,'actual-auto-api.csv'),row.names=FALSE)
write.csv(data.frame(url=requests),file.path(out,'actual-transport.csv'),row.names=FALSE)
cat('PASS',length(checks),'actual auto/canonical API combinations; all 16 manifest URLs; no local source access\n')
