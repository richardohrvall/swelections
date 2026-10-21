# Independent EU 2004 checks: deliberately do not use production normalisers.
.validate_eu2004_sources <- function(files,refs,district,elected,substitutes,kd,control_dir) {
 rows<-lapply(grep('^list_',names(files),value=TRUE),function(role){
  x<-readr::read_delim(files[[role]],delim=';',col_names=FALSE,col_types=readr::cols(.default='c'),locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
  stopifnot(ncol(x)==13L)
  data.frame(code=ifelse(grepl('^E',x[[5]]),paste0('E-',x[[2]],x[[3]],'-',x[[4]]),paste0(x[[2]],x[[3]],x[[5]])),county=x[[2]],municipality=paste0(x[[2]],x[[3]]),constituency=ifelse(x[[4]]=='00',NA_character_,paste0(x[[2]],x[[3]],x[[4]])),party=sub('^list_','',role),list=x[[11]],votes=as.integer(x[[12]]),pref=as.integer(x[[13]]),eligible=as.integer(x[[10]]))
 });l<-purrr::list_rbind(rows)
 ps<-lapply(grep('^preferences_',names(files),value=TRUE),function(role){
  x<-readr::read_delim(files[[role]],delim=';',col_names=FALSE,col_types=readr::cols(.default='c'),locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
  data.frame(code=ifelse(grepl('^E',x[[5]]),paste0('E-',x[[2]],x[[3]],'-',x[[4]]),paste0(x[[2]],x[[3]],x[[5]])),party=sub('^preferences_','',role),list=x[[10]],position=as.integer(x[[12]]),votes=as.integer(x[[13]]))
 });p<-purrr::list_rbind(ps)
 stopifnot(nrow(l)==85349L,nrow(p)==282901L,sum(p$votes)==1480960L,!anyDuplicated(p[c('code','party','list','position')]))
 sum<-p|>dplyr::summarise(.n=base::sum(.data$votes),.by=c('code','party','list'))
 z<-dplyr::left_join(l,sum,by=c('code','party','list'),relationship='one-to-one');stopifnot(all(z$pref==dplyr::coalesce(z$.n,0L)))
 for(level in names(refs)) {
  source_geo<-switch(level,national=rep('00',nrow(l)),county=l$county,municipality=l$municipality,municipal_constituency=l$constituency,district=l$code)
  a<-data.frame(code=source_geo,party=l$party,votes=l$votes);a<-a[!is.na(a$code)&!a$party%in%c('9998','9999'),]
  a<-a|>dplyr::summarise(votes=as.integer(base::sum(.data$votes)),.by=c('code','party'))
  x<-refs[[level]];g<-switch(level,national=rep('00',nrow(x)),county=x$county_code,municipality=x$municipality_code,municipal_constituency=x$municipal_constituency_code,district=x$district_code)
  pk<-ifelse(x$other_parties,'9997',x$party_code);j<-match(paste(g,pk),paste(a$code,a$party));expected<-dplyr::coalesce(a$votes[j],0L)
  stopifnot(identical(x$votes,expected),!anyDuplicated(data.frame(g,pk)))
  if(level!='municipal_constituency')stopifnot(base::sum(x$votes)==2512069L)
 }
 key<-paste0('2004:E:ballot:',p$list,':',p$position);j<-match(paste(district$district_code,district$party_code,district$candidate_number),paste(p$code,p$party,key))
 stopifnot(nrow(district)==nrow(p),!anyNA(j),!anyDuplicated(j),identical(district$preference_votes,p$votes[j]))
 # Read original national result XML directly and compare every aggregate field.
 d<-xml2::read_xml(files[['final']]);ns<-xml2::xml_find_all(d,'./NATION|./NATION/LÄN|.//KOMMUN')
 for(n in ns) {
  level<-c(NATION='national',LÄN='county',KOMMUN='municipality')[[xml2::xml_name(n)]];code<-xml2::xml_attr(n,'KOD');x<-refs[[level]]
  g<-switch(level,national=rep('00',nrow(x)),county=x$county_code,municipality=x$municipality_code);x<-x[g==code,];stopifnot(nrow(x)>0L)
  v<-xml2::xml_find_first(n,'./VALDELTAGANDE');iv<-as.integer(xml2::xml_attr(xml2::xml_find_all(n,'./OGILTIGA'),'RÖSTER'))
  stopifnot(all(x$valid_votes==as.integer(xml2::xml_attr(n,'RÖSTER'))),all(x$invalid_votes==base::sum(iv)),all(x$total_votes==as.integer(xml2::xml_attr(v,'SUMMA_RÖSTER'))),all(x$eligible_voters==as.integer(xml2::xml_attr(v,'RÖSTBERÄTTIGADE'))))
 }
 con<-unz(files[['candidacies']],'00E.xml',open='rb');bd<-xml2::read_xml(con);close(con)
 n<-xml2::xml_find_all(bd,'//VALSEDEL/KANDIDATER/KANDIDAT');bl<-xml2::xml_find_first(n,'ancestor::VALSEDEL[1]');bp<-xml2::xml_find_first(n,'ancestor::PARTI[1]')
 pos<-as.integer(xml2::xml_text(xml2::xml_find_first(n,'./ORDNINGSNUMMER')));ln<-xml2::xml_attr(bl,'LISTNUMMER');pc<-xml2::xml_attr(bp,'KOD')
 j<-match(paste(kd$party_code,kd$list_number,kd$ballot_order),paste(pc,ln,pos));stopifnot(length(n)==382L,nrow(kd)==382L,!anyNA(j),!anyDuplicated(j),identical(kd$candidate_number,paste0('2004:E:ballot:',ln[j],':',pos[j])))
 stopifnot(identical(kd$ballot_info,xml2::xml_text(xml2::xml_find_first(n,'./KANDIDATUPPGIFT'))[j]),all(is.na(kd$valid)))
 # Original fixed election relationships: no later mandate-period membership.
 groups<-xml2::xml_find_all(d,'./NATION/GILTIGA/GRUPP_VALDA');expected<-relationships<-list()
 aliases<-setNames(vapply(rows,function(x)unique(x$party)[1],''),vapply(grep('^list_',names(files),value=TRUE),function(role)strsplit(readLines(files[[role]],n=1L,encoding='latin1'),';',fixed=TRUE)[[1]][1],''))
 for(i in seq_along(groups)){
  group<-groups[[i]];party<-unname(aliases[xml2::xml_attr(xml2::xml_find_first(group,'..'),'PARTI')]);v<-xml2::xml_find_all(group,'./VALD');s<-xml2::xml_find_all(group,'./ERSÄTTARE')
  expected[[i]]<-data.frame(party,name=xml2::xml_attr(v,'NAMN'),age=as.integer(xml2::xml_attr(v,'ÅLDER')),order=as.integer(xml2::xml_attr(v,'ORDNING')),basis=xml2::xml_attr(v,'GRUND'))
  relationships[[i]]<-data.frame(party,group=xml2::xml_attr(group,'ORDNING'),member=rep(xml2::xml_attr(v,'NAMN'),each=length(s)),substitute=rep(xml2::xml_attr(s,'NAMN'),times=length(v)),order=rep(as.integer(xml2::xml_attr(s,'ORDNING')),times=length(v)))
 }
 e<-purrr::list_rbind(expected);j<-match(paste(elected$party_code,elected$name,elected$age_on_election_day),paste(e$party,e$name,e$age))
 stopifnot(nrow(elected)==19L,!anyNA(j),identical(elected$order_of_election,e$order[j]),identical(elected$election_basis_id,e$basis[j]))
 e<-purrr::list_rbind(relationships);j<-match(paste(substitutes$party_code,substitutes$substitute_group,substitutes$member_name,substitutes$substitute_name,substitutes$substitute_order),paste(e$party,e$group,e$member,e$substitute,e$order));stopifnot(nrow(substitutes)==71L,!anyNA(j),!anyDuplicated(j))
 # Independent SND ordinary-district and municipality controls, not build input.
 zip<-file.path(control_dir,'snd','snd0241-3-2.zip');members<-utils::unzip(zip,list=TRUE)$Name;member<-members[grepl('_valdistr[.]dta$',members)]
 tmp<-tempfile();dir.create(tmp);on.exit(unlink(tmp,recursive=TRUE),add=TRUE);sf<-utils::unzip(zip,files=member,exdir=tmp);snd<-haven::read_dta(sf)
 for(level in c('district','municipality')) {
  sx<-snd[if(level=='district')snd$Valdistriktkod!=999999 else snd$Valdistriktkod==999999,]
  code<-if(level=='district')sprintf('%08d',sx$Valdistriktkod)else sprintf('%04d',sx$llkk)
  x<-refs[[level]];g<-if(level=='district')x$district_code else x$municipality_code;u<-x[!duplicated(g),];ug<-unique(g);j<-match(code,ug)
  stopifnot(!anyNA(j),all(u$valid_votes[j]==sx$Giltiga),all(u$invalid_votes[j]==sx$Ogiltiga),all(u$total_votes[j]==sx$Röstande),all(u$eligible_voters[j]==sx$Total_röstberättigade))
  for(party in c(m='0001',c='0004',fp='0003',kd='0068',mp='0055',s='0002',v='0005',jl='0451')){
   pc<-names(c(m='0001',c='0004',fp='0003',kd='0068',mp='0055',s='0002',v='0005',jl='0451'))[match(party,c(m='0001',c='0004',fp='0003',kd='0068',mp='0055',s='0002',v='0005',jl='0451'))]
   px<-x[x$party_code==party & !is.na(x$party_code),];pg<-if(level=='district')px$district_code else px$municipality_code
   stopifnot(all(sx[[pc]]==dplyr::coalesce(px$votes[match(code,pg)],0L)))
  }
 }
 cat('PASS independent85349 list totals,282901 preference rows,382 ballot positions,19 elected,71 relations; original XML and SND geography/results\n')
}

.validate_eu2004_scb <- function(refs,district,control_dir) {
 provenance<-utils::read.csv('data-raw/eu2004-validation-sources.csv',stringsAsFactors=FALSE)
 paths<-list.files(control_dir,recursive=TRUE,full.names=TRUE)
 for(i in seq_len(nrow(provenance))){candidates<-paths[basename(paths)==provenance$file[i]];hashes<-unname(tools::sha256sum(candidates));stopifnot(any(hashes==provenance$sha256[i]))}
 read<-function(name)as.data.frame(suppressMessages(readxl::read_xls(file.path(control_dir,'scb',name),col_names=FALSE,.name_repair='minimal')))
 normal<-function(x){x[x=='Hela riket']<-'Sverige';x[x=='Vaggeryds']<-'Vaggeryd';x[x=='Malungs']<-'Malung';x}
 units<-purrr::list_rbind(lapply(c('national','county','municipality'),function(level){
  x<-refs[[level]];code<-switch(level,national=rep('00',nrow(x)),county=x$county_code,municipality=x$municipality_code)
  name<-switch(level,national=rep('Sverige',nrow(x)),county=x$county_name,municipality=x$official_municipality_name)
  x<-data.frame(code,name=normal(name),valid=x$valid_votes,invalid=x$invalid_votes,blank=x$blank_votes,cast=x$total_votes,eligible=x$eligible_voters);x[!duplicated(code),]
 }))
 s<-read('tab-02b_eu_kommun_tab_talut.xls');keep<-!is.na(suppressWarnings(as.integer(s[[3]]))) & !is.na(s[[1]]);s<-s[keep,];j<-match(normal(s[[1]]),units$name);stopifnot(nrow(s)==312L);if(anyNA(j))stop('Unmatched SCB result areas: ',paste(s[[1]][is.na(j)],collapse=', '))
 for(pair in list(c(3,'eligible'),c(7,'cast'),c(11,'invalid'),c(12,'blank'),c(14,'valid')))stopifnot(all(as.integer(s[[as.integer(pair[1])]])==units[[pair[2]]][j]))
 all<-purrr::list_rbind(refs[c('national','county','municipality')]);g<-ifelse(all$geographic_level=='national','00',ifelse(all$geographic_level=='county',all$county_code,all$municipality_code))
 pc<-c('0001','0004','0003','0068','0055','0002','0005','0451');cols<-c(16,18,20,22,24,26,27,28)
 for(i in seq_along(pc)) {ix<-which(all$party_code==pc[i] & !is.na(all$party_code));q<-match(units$code[j],g[ix]);stopifnot(!anyNA(q),all(as.integer(s[[cols[i]]])==all$votes[ix][q]))}
 other<-data.frame(code=g[!all$party_code%in%pc],votes=all$votes[!all$party_code%in%pc]);other<-other|>dplyr::summarise(votes=sum(.data$votes),.by='code');stopifnot(all(as.integer(s[[29]])==other$votes[match(units$code[j],other$code)]))
 stopifnot(all(abs(as.numeric(s[[9]])-100*units$cast[j]/units$eligible[j])<=0.050001))
 # All347 individually named small-party threshold cells, not an exhaustive list.
 s<-read('eu_ovr_partiut_100917.xls');area<-as.character(s[[1]]);current<-NA_character_;known<-normal(refs$municipality$official_municipality_name);for(i in seq_along(area)){if(!is.na(area[i]) && normal(area[i])%in%known)current<-area[i];area[i]<-current}
 keep<-!is.na(suppressWarnings(as.integer(s[[4]])));stopifnot(sum(keep)==347L)
 m<-refs$municipality;k<-match(paste(normal(area[keep]),trimws(s[[3]][keep])),paste(normal(m$official_municipality_name),trimws(m$party_designation)))
 stopifnot(!anyNA(k),all(as.integer(s[[4]][keep])==m$votes[k]))
 # All176 county/national mandate-party preference counts from SCB table11.
 s<-read('tab-11_eu_persrost_parti_mandut.xls');keep<-!is.na(suppressWarnings(as.integer(s[[2]]))) & !is.na(s[[1]]);s<-s[keep,];stopifnot(nrow(s)==22L)
 for(i in seq_along(pc)){
  p<-district[district$party_code==pc[i],];p<-p|>dplyr::summarise(votes=sum(.data$preference_votes),.by='county_code')
  code<-units$code[match(normal(s[[1]]),units$name)];expected<-p$votes[match(code,p$county_code)];expected[code=='00']<-sum(p$votes)
  stopifnot(!anyNA(expected),all(as.integer(s[[c(2,4,6,8,10,12,14,16)[i]]])==expected))
 }
 # Protocol appendix1 is the independent legally established national control.
 n<-refs$national;expected_votes<-c(458398L,157258L,247750L,142704L,149603L,616963L,321344L,363472L,28303L)
 codes<-c(pc,'0110');stopifnot(identical(n$votes[match(codes,n$party_code)],expected_votes),sum(n$votes)==2512069L)
 p<-district|>dplyr::summarise(votes=as.integer(sum(.data$preference_votes)),.by='party_code')
 expected_preferences<-c(273132L,102751L,140876L,101587L,83785L,350721L,213127L,187282L,14450L)
 stopifnot(identical(p$votes[match(codes,p$party_code)],expected_preferences),sum(p$votes)==1480960L,sum(p$votes[!p$party_code%in%codes])==13249L)
 cat('PASS SCB312area totals/party/turnout controls,347small-party cells,176preference cells; final protocol party/preferences totals\n')
}
