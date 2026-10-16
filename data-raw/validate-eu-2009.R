# Rscript data-raw/validate-eu-2009.R RAW_ROOT CANONICAL_DIR INDEPENDENT_CONTROL_DIR
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3L)
pkgload::load_all('.',quiet=TRUE)
options(swelections.canonical_manifest=file.path(args[2],'manifest.json'),
 swelections.canonical_cache_dir=file.path(args[2],'validation-cache'))
m<-jsonlite::read_json(file.path(args[2],'manifest.json'),simplifyVector=TRUE)
stopifnot(m$valar==2009L,m$schema_version==2L,nrow(m$assets)==14L)
for(i in seq_len(nrow(m$assets))){f<-file.path(args[2],m$assets$file[i]);stopifnot(file.info(f)$size==m$assets$bytes[i],swelections:::.canonical_sha256(f)==m$assets$sha256[i])}
files<-setNames(vapply(m$sources$role,function(r)swelections:::.eu2009_file(r,'local',args[1]),''),m$sources$role)
before<-unname(tools::sha256sum(files));stopifnot(identical(before,m$sources$sha256))
refs<-list();compares<-0L
compare<-function(fun,extra=list()){
 common<-c(list(year=2009,election='E',data_dir=args[1]),extra)
 full<-do.call(get(fun,envir=asNamespace("swelections")),c(common,list(source='local',names='en',detail='full')))
 for(lang in c('en','sv'))for(detail in c('standard','full')) {
  raw<-do.call(get(fun,envir=asNamespace("swelections")),c(common,list(source='local',names=lang,detail=detail)))
  canonical<-do.call(get(fun,envir=asNamespace("swelections")),c(common,list(source='canonical',names=lang,detail=detail)))
  stopifnot(identical(raw,canonical))
  translated<-if(lang=='en')raw else swelections:::.public_output_names(raw,'en')
  stopifnot(identical(translated,full[names(translated)]),nrow(translated)==nrow(full))
 }
 compares<<-compares+1L;cat('PASS API',fun,paste(extra,collapse='/'),nrow(full),'\n');flush.console();full
}
for(count in 'final') {
 for(level in c('national','county','municipality','municipal_constituency','district'))refs[[paste(count,level)]]<-compare('results',list(count=count,level=level))
 compare('seats',list(count=count,level='national'))
}
for(fun in c('candidacies','candidates','elected','substitutes'))assign(fun,compare(fun))
compare('candidates',list(include_results=FALSE))
for(level in c('preference_vote_area','national','county','municipality','municipal_constituency','district'))
 for(by in c(FALSE,TRUE))for(zero in c(FALSE,TRUE)) {
  x<-compare('preference_votes',list(level=level,by_list=by,include_zeros=zero))
  if(level=='district'&&by&&!zero)district<-x
 }
stopifnot(nrow(candidacies)==500L,nrow(candidates)==500L,nrow(elected)==18L,nrow(substitutes)==68L)
b<-swelections:::.eu2009_bundle(list(source='local',data_dir=args[1]))
stopifnot(sum(b$votes$antal_personroster[b$votes$.geo=='00'])==1874130L)
stopifnot(sum(b$small$antal_personroster[b$small$geografiniva=='riket'])==2665L, sum(b$small$antal_personroster[b$small$geografiniva=='lan'])==2677L, sum(b$small$antal_personroster[b$small$geografiniva=='kommun'])==2677L)
stopifnot(sum(b$small$antal_personroster[b$small$geografiniva=='valdistrikt'])==2571L)
stopifnot(sum(district$preference_votes)==1876701L,nrow(district)==372699L)
stopifnot(all(is.na(candidates$total_preference_votes[!candidates$candidate_number%in%b$votes$kandidatnummer])))
p<-b$kd[b$kd$listnummer=='04536' & b$kd$namn=='Per Johansson',];stopifnot(identical(p$ordning,c(18L,32L)),identical(p$alder_pa_valdagen,c(48L,38L)),length(unique(p$kandidatnummer))==2L)
refs<-setNames(lapply(c('national','county','municipality','municipal_constituency','district'),function(l)refs[[paste('final',l)]]),c('national','county','municipality','municipal_constituency','district'))
source('data-raw/validate-eu-2009-sources.R')
.validate_eu2009_sources(files,refs,district,elected,substitutes,candidacies,args[3])
stopifnot(identical(unname(tools::sha256sum(files)),before))
integration<-withr::with_envvar(c(SWEELECTIONS_EU2009_ROOT=normalizePath(args[1],winslash='/',mustWork=TRUE)),testthat::test_file('tests/testthat/test-eu-2009.R',reporter='summary'))
s<-as.data.frame(integration);stopifnot(sum(s$failed)==0L,!any(s$error),sum(s$warning)==0L,sum(s$skipped)==0L)
wrappers<-c(results='valresultat',seats='mandat',candidacies='kandidaturer',candidates='kandidater',elected='valda',substitutes='ersattare',preference_votes='personroster')
for(fun in names(wrappers))for(lang in c('en','sv'))for(detail in c('standard','full')){
 en<-do.call(get(fun,envir=asNamespace('swelections')),list(year=2009,election='E',source='local',data_dir=args[1],names=lang,detail=detail))
 sv<-do.call(get(wrappers[[fun]],envir=asNamespace('swelections')),list(ar=2009,val='E',source='local',data_dir=args[1],names=lang,detaljniva=detail));stopifnot(identical(en,sv))}
cat('PASS all',compares,'public variants x four language/detail combinations; all seven Swedish wrappers; source/manifest integrity\n')
