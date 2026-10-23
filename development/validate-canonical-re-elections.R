# Rscript development/validate-canonical-re-elections.R ARCHIVE_ROOT ORSA_RERUN_XML BUILD OUTPUT
args<-commandArgs(TRUE)
if(length(args)!=4L)stop('Specify ARCHIVE_ROOT ORSA_RERUN_XML BUILD OUTPUT.')
root<-args[1];orsa<-args[2];build<-args[3];output<-args[4]
dir.create(output,recursive=TRUE,showWarnings=FALSE)
pkgload::load_all('.',quiet=TRUE)
paths<-read.csv(file.path(build,'manifests.csv'))$manifest
manifests<-lapply(paths,.canonical_manifest)
options(swelections.re_election_sources=list(`SE-KF-2003-03-16-2034`=list(final=orsa,seats=orsa)),
 swelections.canonical_manifest=setNames(paths,paste('rkl','re_election',vapply(manifests,function(m)m$valar,integer(1)),sep=':')),
 swelections.canonical_cache_dir=file.path(output,'cache'),swelections.data_dir=NULL)
portable<-function(x) {x$source_file<-sub('^.*?/(omval|rkl)/','\\1/',gsub(intToUtf8(92L),'/',x$source_file,fixed=TRUE));x}
controls<-data.frame(year=c(2003L,2011L,2011L,2015L,2019L),code=c('KF','RF','KF','KF','KF'),
 valid=c(4303L,545215L,17335L,7494L,27788L),cast=c(4316L,548950L,17512L,7552L,27999L),
 eligible=c(5413L,1246191L,27645L,11874L,45911L),districts=c(6L,1025L,24L,10L,37L),seats=c(31L,149L,17L,41L,61L))
checks<-list();hashes<-list();reference_outputs<-list();events<-.re_elections()
for(j in seq_along(manifests)) {
 m<-manifests[[j]];stopifnot(m$event_kind=='re_election',isTRUE(m$auto_eligible),m$data_version=='data-v0.4.1',m$schema_version==3L,m$value_schema_version==1L,m$storage_schema_version==1L,is.logical(m$build_tree_dirty))
 stopifnot(!any(grepl('^[A-Za-z]:[/\\\\]',unlist(m$sources))))
 for(k in seq_len(nrow(m$assets))) {
  asset<-m$assets[k,];p<-file.path(dirname(paths[j]),asset$file)
  stopifnot(file.info(p)$size==asset$bytes,.canonical_sha256(p)==asset$sha256)
  x<-tibble::as_tibble(nanoparquet::read_parquet(p));q<-file.path(output,paste0(asset$asset,'-roundtrip.parquet'))
  nanoparquet::write_parquet(x,q,compression='gzip');stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(q))),.canonical_sha256(q)==asset$sha256)
  e<-events[events$election_event==asset$election_event,];c<-controls[controls$year==e$election_year&controls$code==e$election_code,]
  layouts<-m$tables[m$tables$asset==asset$asset,]
  for(level in layouts$table) {
   a<-list(year=e$election_year,election=e$election_code,election_kind='re_election',level=level,progress=FALSE)
   for(detail in c('standard','full'))for(lang in c('en','sv')) {
    aa<-c(a,list(detail=detail,names=lang))
    raw<-do.call(get(asset$role),c(aa,list(source='local',data_dir=root)))
    canonical<-do.call(get(asset$role),c(aa,list(source='canonical')))
    enraw<-if(lang=='en')raw else .public_output(raw,'en');encanonical<-if(lang=='en')canonical else .public_output(canonical,'en')
    if(!identical(portable(enraw),encanonical)) {
      print(all.equal(portable(enraw),encanonical));saveRDS(list(raw=portable(enraw),canonical=encanonical),file.path(output,'difference.rds'));stop('Canonical/raw identity differs')
    }
    if(lang=='sv') {
     sw<-if(asset$role=='results')valresultat else mandat
     sv<-do.call(sw,list(ar=e$election_year,val=e$election_code,valklass='omval',niva=unname(.english_argument_values$level[level]),detaljniva=detail,source='canonical'))
     stopifnot(identical(sv,canonical))
    }
    reference_outputs[[paste(e$election_event,asset$role,level,detail,lang,sep=':')]]<-canonical
    checks[[length(checks)+1L]]<-data.frame(event=e$election_event,view=asset$role,level,detail,language=lang,rows=nrow(canonical),status='PASS')
   }
   z<-do.call(get(asset$role),c(a,list(source='canonical',detail='full')))
   if(asset$role=='seats') {stopifnot(sum(z$seats)==c$seats);.re_verify_allocation(z,e)} else {
    g<-switch(level,district=z$district_code,municipality=z$municipality_code,
     municipal_constituency=z$municipal_constituency_code,regional_constituency=z$constituency_code,rep(e$scope_code,nrow(z)))
    u<-z[!duplicated(g),];stopifnot(sum(z$votes)==c$valid,sum(u$valid_votes)==c$valid,sum(u$total_votes)==c$cast)
    key<-c('election_event','district_code','municipality_code','constituency_code','municipal_constituency_code','party_abbreviation','party_designation','other_parties');key<-intersect(key,names(z));stopifnot(!anyDuplicated(z[key]))
    if(level=='district') {stopifnot(length(unique(g))==c$districts,sum(u$eligible_voters[u$district_type=='ordinary'])==c$eligible,all(is.na(u$eligible_voters[u$district_type!='ordinary'])))} else stopifnot(sum(u$eligible_voters)==c$eligible)
   }
   cat('PASS',e$election_event,asset$role,level,'\n');flush.console()
  }
  hashes[[length(hashes)+1L]]<-asset
 }
}
# Remove raw access for a second public pass: canonical must be self-contained.
old<-.re_file
assignInNamespace('.re_file',function(...)stop('raw source access forbidden'),'swelections')
for(i in seq_len(nrow(events)))for(fn in list(results,seats)) {
 e<-events[i,];a<-list(year=e$election_year,election=e$election_code,election_kind='re_election',source='canonical')
 stopifnot(nrow(do.call(fn,a))>0L)
 stopifnot(identical(do.call(fn,utils::modifyList(a,list(source='auto'))),do.call(fn,a)))
}
assignInNamespace('.re_file',old,'swelections')
inv<-read.csv('development/SOURCE_INVENTORY_OMVAL_FILES.csv');stopifnot(all(unname(tools::sha256sum(inv$path))==inv$sha256))
ledger<-read.csv('development/SOURCE_INVENTORY_OMVAL_RETRIEVAL.csv');ok<-ledger[ledger$status==200&!is.na(ledger$status),]
stopifnot(nrow(ok)==100L,all(unname(tools::sha256sum(ok$path))==ok$sha256))
saveRDS(reference_outputs,file.path(output,'validated-public-outputs.rds'))
write.csv(dplyr::bind_rows(checks),file.path(output,'api-checks.csv'),row.names=FALSE)
write.csv(dplyr::bind_rows(hashes),file.path(output,'asset-checks.csv'),row.names=FALSE)
cat('PASS',length(checks),'canonical/raw API variants; ten byte-identical round trips; source controls and 154 source hashes\n')
