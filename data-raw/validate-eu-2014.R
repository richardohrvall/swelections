# Rscript data-raw/validate-eu-2014.R RAW_ROOT CANONICAL_DIR INDEPENDENT_CONTROL_DIR
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3L)
pkgload::load_all('.',quiet=TRUE)
options(swelections.canonical_manifest=file.path(args[2],'manifest.json'),
 swelections.canonical_cache_dir=file.path(args[2],'validation-cache'))
m<-jsonlite::read_json(file.path(args[2],'manifest.json'),simplifyVector=TRUE)
stopifnot(m$valar==2014L,m$schema_version==3L,nrow(m$assets)==14L)
for(i in seq_len(nrow(m$assets))){f<-file.path(args[2],m$assets$file[i]);stopifnot(file.info(f)$size==m$assets$bytes[i],swelections:::.canonical_sha256(f)==m$assets$sha256[i])}
files<-setNames(vapply(m$sources$role,function(r)swelections:::.eu2014_file(r,'local',args[1]),''),m$sources$role)
before<-unname(tools::sha256sum(files));stopifnot(identical(before,m$sources$sha256))
refs<-list();compares<-0L
compare<-function(fun,extra=list()){
 common<-c(list(year=2014,election='E',data_dir=args[1]),extra)
 full<-do.call(get(fun,envir=asNamespace("swelections")),c(common,list(source='local',names='en',detail='full')))
 for(lang in c('en','sv'))for(detail in c('standard','full')) {
  raw<-do.call(get(fun,envir=asNamespace("swelections")),c(common,list(source='local',names=lang,detail=detail)))
  canonical<-do.call(get(fun,envir=asNamespace("swelections")),c(common[setdiff(names(common),'data_dir')],list(source='canonical',names=lang,detail=detail)))
  stopifnot(identical(raw,canonical))
  translated<-if(lang=='en')raw else swelections:::.public_output(raw,'en')
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
stopifnot(nrow(candidacies)==376L,all(is.na(candidacies$valid)),nrow(candidates)==376L,
 nrow(elected)==20L,nrow(substitutes)==74L,sum(candidates$total_preference_votes)==1859375L,
 all(is.na(candidacies$name)),all(is.na(district$name)),sum(district$preference_votes)==1859375L,
 nrow(district)==402053L,length(unique(district$district_code))==6227L)
ref<-swelections:::.eu2014_bundle(list(source='local',data_dir=args[1]))
stopifnot(sum(ref$seats$antal_mandat)==20L,sum(ref$seats$antal_tomma_stolar)==0L,
 sum(ref$source_designations$antal_roster)==5618L,
 sum(ref$source_designations$antal_roster[ref$source_designations$kall_partibeteckning_saknas])==10L)
for(level in c('national','county','municipality','municipal_constituency','district')) {
 x<-refs[[paste('final',level)]]
 stopifnot(sum(x$source_votes_without_party_designation,na.rm=TRUE)==10L,all(x$other_parties[!is.na(x$source_votes_without_party_designation)]))
}
refs<-setNames(lapply(c('national','county','municipality','municipal_constituency','district'),function(l)refs[[paste('final',l)]]),c('national','county','municipality','municipal_constituency','district'))
source('data-raw/validate-eu-2014-sources.R')
.validate_eu2014_sources(files,args[3],refs,district,elected,substitutes,candidacies)
stopifnot(identical(unname(tools::sha256sum(files)),before))
cat('PASS all',compares,'public variants x 4 naming/detail combinations; source integrity; manifest and Parquet round-trip\n')

# Run the preserved-source regression with this process's already verified XML cache.
integration <- withr::with_envvar(c(SWEELECTIONS_EU2014_ROOT=normalizePath(args[1],winslash="/",mustWork=TRUE)),
 testthat::test_file('tests/testthat/test-eu-2014.R',reporter='summary'))
summary <- as.data.frame(integration)
stopifnot(sum(summary$failed)==0L,!any(summary$error),sum(summary$warning)==0L,sum(summary$skipped)==0L)
cat('PASS opt-in 2014 regression tests:',sum(summary$passed),'assertions, no skips\n')
# Exercise actual Swedish calls as well as the English API's output-name option.
wrappers<-c(results='valresultat',seats='mandat',candidacies='kandidaturer',candidates='kandidater',elected='valda',substitutes='ersattare',preference_votes='personroster')
for(fun in names(wrappers))for(lang in c('en','sv'))for(detail in c('standard','full')) {
 en<-do.call(get(fun,envir=asNamespace('swelections')),list(year=2014,election='E',source='local',data_dir=args[1],names=lang,detail=detail))
 sv<-do.call(get(wrappers[[fun]],envir=asNamespace('swelections')),list(ar=2014,val='E',source='local',data_dir=args[1],names=lang,detaljniva=detail))
 stopifnot(identical(en,sv))
}
cat('PASS all seven actual Swedish wrappers x four naming/detail combinations\n')
