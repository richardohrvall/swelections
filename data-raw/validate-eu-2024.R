# Rscript data-raw/validate-eu-2024.R RAW_ROOT CANONICAL_DIRECTORY
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=2L)stop('Specify RAW_ROOT CANONICAL_DIRECTORY.')
pkgload::load_all('.',quiet=TRUE)
root<-args[[1]];out<-args[[2]]
options(swelections.canonical_manifest=file.path(out,'manifest.json'),
 swelections.canonical_cache_dir=file.path(out,'validation-cache'))
sha<-swelections:::.canonical_sha256
manifest<-jsonlite::read_json(file.path(out,'manifest.json'),simplifyVector=TRUE)
stopifnot(manifest$valar==2024L,manifest$valserie=='eu',manifest$schema_version==3L,nrow(manifest$assets)==15L)
for(i in seq_len(nrow(manifest$assets))){a<-manifest$assets[i,];f<-file.path(out,a$file);stopifnot(file.info(f)$size==a$bytes,sha(f)==a$sha256)}
files<-c(swelections:::.eu2024_file('results','local',root,'slutlig'),
 swelections:::.eu2024_file('results','local',root,'preliminar'),
 swelections:::.eu2024_file('candidacies','local',root))
before<-vapply(files,sha,'')
# Independent parsing: direct JSON, no production readers/normalisation.
d<-tempfile();dir.create(d);utils::unzip(files[1],exdir=d)
r<-jsonlite::read_json(list.files(d,pattern='rostfordelning.*json$',full.names=TRUE))
m<-jsonlite::read_json(list.files(d,pattern='mandatfordelning.*json$',full.names=TRUE))
s<-jsonlite::read_json(list.files(d,pattern='summering.*json$',full.names=TRUE))
independent_party<-function(nodes,codes)purrr::list_rbind(lapply(seq_along(nodes),function(i){p<-nodes[[i]]$rostfordelning$rosterPaverkaMandat$partiRoster;tibble::tibble(code=codes[i],party=vapply(p,function(x)x$partikod,''),votes=vapply(p,function(x)x$antalRoster,0L))}))
municipalities<-unlist(lapply(s$helaLandet$lan,function(l)l$kommuner),recursive=FALSE)
ref<-list(district=independent_party(r$valdistrikt,vapply(r$valdistrikt,function(x)x$valdistriktskod,'')),
 municipality=independent_party(municipalities,vapply(municipalities,function(x)x$kommunkod,'')),
 county=independent_party(s$helaLandet$lan,vapply(s$helaLandet$lan,function(x)x$lankod,'')),
 national=independent_party(list(m$valomrade),'00'))
constituencies <- unlist(lapply(municipalities,function(x)x$kommunValkretsar),recursive=FALSE)
constituencies <- Filter(function(x)!grepl("00$",x$kod),constituencies)
stopifnot(length(constituencies)==41L)
ref$municipal_constituency <- independent_party(constituencies,vapply(constituencies,function(x)x$kod,""))
for(level in names(ref)){
 x<-results(2024,election='E',level=level,source='local',data_dir=root,detail='full')
 codes<-if(level=='national')rep('00',nrow(x))else x[[paste0(level,'_code')]]
 a<-tibble::tibble(code=codes,party=x$party_code,votes=x$votes)
 a<-a[!is.na(a$party),];j<-merge(a,ref[[level]],by=c('code','party'),all=TRUE)
 stopifnot(nrow(j)==nrow(a),!anyNA(j),all(j$votes.x==j$votes.y))
 cat('PASS independent party JSON',level,nrow(j),'\n');flush.console()
}
# All public variants: names and detail independent, full values preserved.
compare<-function(fun,extra=list()){
 common<-c(list(year=2024,election='E',data_dir=root),extra)
 full<-do.call(get(fun),c(common,list(source='local',names='en',detail='full')))
 for(lang in c('en','sv'))for(detail in c('standard','full')){
   raw<-do.call(get(fun),c(common,list(source='local',names=lang,detail=detail)))
   canonical<-do.call(get(fun),c(common[setdiff(names(common),'data_dir')],list(source='canonical',names=lang,detail=detail)))
   if(!identical(raw,canonical))stop('Canonical/raw difference: ',fun,' ',paste(extra,collapse='/'),' ',lang,' ',detail)
   translated<-if(lang=='en')raw else swelections:::.public_output(raw,'en')
   stopifnot(identical(translated,full[names(translated)]),nrow(translated)==nrow(full))
 }
 cat('PASS API',fun,paste(extra,collapse='/'),nrow(full),'\n');flush.console()
 invisible(full)
}
for(count in c('final','preliminary')){
 for(level in c('national','county','municipality','municipal_constituency','district'))compare('results',list(count=count,level=level))
 compare('seats',list(count=count,level='national'))
}
for(f in c('candidacies','candidates','elected','substitutes'))compare(f)
compare('candidates',list(include_results=FALSE))
for(level in c('preference_vote_area','national','county','municipality','municipal_constituency','district'))
 for(by in c(FALSE,TRUE))for(zero in c(FALSE,TRUE))compare('preference_votes',list(level=level,by_list=by,include_zeros=zero))
# Original relations, candidate scope and ineligible preference rows.
kd<-candidacies(2024,election='E',source='local',data_dir=root,detail='full')
stopifnot(nrow(kd)==1395L,sum(kd$valid)==1390L,!any(kd$candidate_number=='1203'))
c<-candidates(2024,election='E',source='local',data_dir=root)
e<-elected(2024,election='E',source='local',data_dir=root)
u<-substitutes(2024,election='E',source='local',data_dir=root)
stopifnot(length(unique(c$candidate_number))==1340L,nrow(e)==21L,nrow(u)==77L,length(unique(u$substitute_candidate_number))==27L)
# Strict independent original elected/mandate/substitute keys and ordering.
original_e <- purrr::list_rbind(lapply(m$valomrade$valda$partiLedamoterLista,function(p)
 purrr::list_rbind(lapply(p$ledamoter,function(x)tibble::tibble(party=p$partikod,id=as.character(x$kandidatnummer),order=x$invalsordning,basis=as.character(x$valgrundId))))))
ef <- elected(2024,election='E',source='local',data_dir=root,detail='full')
j <- match(paste(ef$party_code,ef$candidate_number),paste(original_e$party,original_e$id))
stopifnot(!anyNA(j),all(ef$order_of_election==original_e$order[j]),all(ef$election_basis_id==original_e$basis[j]),
 all(ef$elected_electoral_area_code=='00'),identical(ef$constituency_code,ef$elected_constituency_code))
original_u <- purrr::list_rbind(lapply(m$valomrade$valda$partiLedamoterLista, function(p) {
 purrr::list_rbind(lapply(p$ledamoter, function(x) {
  purrr::list_rbind(lapply(x$ersattare, function(q) {
   tibble::tibble(party=p$partikod, member=as.character(x$kandidatnummer),
    substitute=as.character(q$kandidatnummer), order=q$ersattarordning)
  }))
 }))
}))
stopifnot(setequal(paste(u$party_code,u$member_candidate_number,u$substitute_candidate_number,u$substitute_order),
 paste(original_u$party,original_u$member,original_u$substitute,original_u$order)))
seat <- seats(2024,election='E',source='local',data_dir=root)
allocated <- m$valomrade$mandatfordelning$partiLista
j<-match(seat$party_code,vapply(allocated,function(x)x$partikod,''))
stopifnot(all(seat$seats==vapply(allocated,function(x)x$antalMandat,0L)[j]),sum(seat$unfilled_seats)==0L)
p<-preference_votes(2024,election='E',level='district',by_list=TRUE,source='local',data_dir=root,detail='full')
stopifnot(nrow(p)==393607L,sum(p$preference_votes)==1914494L,!anyDuplicated(p[c('district_code','party_code','list_number','candidate_number')]))
# Official Excel is an independent extract, with explicit collection code mapping.
if(requireNamespace('readxl',quietly=TRUE)){
 f<-file.path(root,'valresultat','personroster-EU-valet-2024.xlsx')
 excel<-readxl::read_excel(f,sheet='Data',.name_repair='unique_quiet')
 code<-gsub('^E-|-','',excel[[4]]);valid_codes<-vapply(r$valdistrikt,function(x)x$valdistriktskod,'')
 code<-ifelse(!code%in%valid_codes & substr(code,1,6)%in%valid_codes,substr(code,1,6),code)
 key<-function(geo,list,id)paste(geo,list,id,sep='\r')
 idx<-match(key(p$district_code,paste(p$party_code,p$list_number,sep='-'),p$candidate_number),key(code,excel[[11]],excel[[2]]))
 stopifnot(nrow(excel)==nrow(p),!anyNA(idx),!anyDuplicated(idx),all(p$preference_votes==excel[[12]][idx]))
 scb<-readxl::read_excel(file.path(root,'valresultat/scb/Valresultat valdistrikt EU2024.xlsx'),.name_repair='unique_quiet')
 scb<-scb[!is.na(scb[[4]]),];x<-results(2024,election='E',level='district',source='local',data_dir=root,detail='full');x<-x[!duplicated(x$district_code),]
 ordinary<-!grepl('9800$',scb[[4]]);j<-match(scb[[4]][ordinary],x$district_code)
 stopifnot(sum(ordinary)==6275L,!anyNA(j),nrow(scb)==6565L)
 for(pair in list(c(5,'eligible_voters'),c(9,'total_votes'),c(11,'invalid_votes'),c(12,'blank_votes'),c(13,'valid_votes')))
  stopifnot(all(as.numeric(scb[[as.integer(pair[1])]][ordinary])==x[[pair[2]]][j]))
 stopifnot(sum(as.numeric(scb[[9]]))==4240459L,sum(as.numeric(scb[[13]]))==4198011L)
 cat('PASS independent Excel: 393607 preference rows; SCB: 6275 districts and merged collection controls\n')
}else stop('Validation requires the documented readxl development dependency.')
stopifnot(identical(vapply(files,sha,''),before))
unlink(d,recursive=TRUE)
cat('PASS source integrity; all seven APIs, counts, projections, languages, Parquet and manifest checks\n')
