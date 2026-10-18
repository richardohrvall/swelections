# Independent source controls plus public projection/language/Parquet checks.
# Run from the repository root:
# Rscript development/validate-re-elections.R ARCHIVE_ROOT ORSA_RERUN_XML OUTPUT_DIR
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=3L)stop('Usage: validate-re-elections.R ARCHIVE_ROOT ORSA_RERUN_XML OUTPUT_DIR')
root<-args[1];orsa<-args[2];outdir<-args[3]
if(!dir.exists(root)||!file.exists(orsa))stop('Preserved sources not found.')
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
pkgload::load_all('.')
options(swelections.re_election_sources=list(`SE-KF-2003-03-16-2034`=list(final=orsa,seats=orsa)))
controls<-data.frame(year=c(2003L,2011L,2011L,2015L,2019L),code=c('KF','RF','KF','KF','KF'),
 valid=c(4303L,545215L,17335L,7494L,27788L),cast=c(4316L,548950L,17512L,7552L,27999L),
 eligible=c(5413L,1246191L,27645L,11874L,45911L),districts=c(6L,1025L,24L,10L,37L),
 seats=c(31L,149L,17L,41L,61L))
records<-list();assets<-list();k<-0L
for(i in seq_len(nrow(controls))) {
 c<-controls[i,];cat('SOURCE EVENT',c$year,c$code,'\n');flush.console()
 e<-.re_elections();e<-e[e$election_year==c$year&e$election_code==c$code,]
 for(table in c('results','seats')) {
  levels<-if(table=='seats')list(NULL)else list(NULL,'district')
  if(table=='results'&&c$code=='RF')levels<-c(levels,list('municipality','regional_constituency'))
  for(level in levels) {
   a<-list(year=c$year,election=c$code,election_kind='re_election',source='local',data_dir=root,progress=FALSE,level=level)
   full<-do.call(get(table),c(a,list(detail='full',names='en')))
   standard<-do.call(get(table),c(a,list(detail='standard',names='en')))
   sv<-do.call(get(table),c(a,list(detail='full',names='sv')))
   svstd<-do.call(get(table),c(a,list(detail='standard',names='sv')))
   stopifnot(identical(full[names(standard)],standard),identical(.public_output_names(sv,'en'),full),
     identical(.public_output_names(svstd,'en'),standard),identical(sv[names(svstd)],svstd))
   stopifnot(all(full$election_year==c$year),all(full$election_event==e$election_event),
     all(full$event_scope_code==e$scope_code),all(full$mandate_period==e$mandate_period))
   if(table=='seats') {
    stopifnot(sum(full$seats)==c$seats);.re_verify_allocation(full,e)
   }else {
    key<-c('district_code','municipality_code','constituency_code','municipal_constituency_code')
    key<-key[key%in%names(full)]
    g<-if(identical(level,'district'))full$district_code else if(identical(level,'municipality'))full$municipality_code else if(identical(level,'regional_constituency'))full$constituency_code else rep(e$scope_code,nrow(full))
    u<-full[!duplicated(g),]
    stopifnot(sum(full$votes)==c$valid,sum(u$valid_votes)==c$valid,sum(u$total_votes)==c$cast)
    if(identical(level,'district')) {
     stopifnot(length(unique(g))==c$districts)
     ordinary<-u$district_type=='valdistrikt'
     stopifnot(sum(u$eligible_voters[ordinary])==c$eligible,all(is.na(u$eligible_voters[!ordinary])))
    }else stopifnot(sum(u$eligible_voters)==c$eligible)
    stopifnot(!anyDuplicated(full[c('election_event',key,'party_abbreviation','party_designation','other_parties')]))
   }
   for(detail in c('standard','full')) {
    x<-if(detail=='full')full else standard
    f<-file.path(outdir,paste(c$year,c$code,table,if(is.null(level))'main'else level,detail,sep='-'))
    f<-paste0(f,'.parquet');nanoparquet::write_parquet(as.data.frame(x),f)
    read<-nanoparquet::read_parquet(f);stopifnot(identical(as.data.frame(read),as.data.frame(x)))
    assets[[length(assets)+1L]]<-data.frame(file=basename(f),bytes=file.info(f)$size,sha256=unname(tools::sha256sum(f)))
   }
   k<-k+1L;records[[k]]<-data.frame(year=c$year,election=c$code,table,level=if(is.null(level))'main'else level,rows=nrow(full),status='PASS')
   cat('PASS',table,if(is.null(level))'main'else level,nrow(full),'rows\n');flush.console()
  }
 }
}
write.csv(dplyr::bind_rows(records),file.path(outdir,'public-source-checks.csv'),row.names=FALSE)
write.csv(dplyr::bind_rows(assets),file.path(outdir,'roundtrip-checksums.csv'),row.names=FALSE)
# Independent preserved-source hashes; do not change the raw archive to make a test pass.
inv<-read.csv('development/SOURCE_INVENTORY_OMVAL_FILES.csv')
stopifnot(all(unname(tools::sha256sum(inv$path))==inv$sha256))
cat('PASS all original omval source hashes; all public-source, projection, language and Parquet checks.\n')
