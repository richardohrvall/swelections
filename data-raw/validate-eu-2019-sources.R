# Independent XML/Excel/SCB controls: deliberately does not use package normalisers.
.validate_eu2019_sources <- function(files, control_dir, api_results, api_preferences, elected, substitutes, candidacies) {
 scratch<-tempfile();dir.create(scratch);on.exit(unlink(scratch,recursive=TRUE),add=TRUE)
 library(xml2)
 units<-parties<-list();i<-0L
 for(stage in c('final','preliminary')) {
  prefix<-if(stage=='final')'slutresultat'else'prelresultat'
  dir<-file.path(scratch,stage);dir.create(dir);utils::unzip(files[[stage]],exdir=dir)
  for(f in sort(list.files(dir,pattern='[.]xml$',full.names=TRUE))) {
   doc<-read_xml(f,options=c('NONET','NOBLANKS'))
   tags<-if(grepl('_00E.xml$',f))c(NATION='national','LÄN'='county')else
    c(KOMMUN='municipality',KRETS_KOMMUN='municipal_constituency',VALDISTRIKT='district',ONSDAGSDISTRIKT='district')
   for(tag in names(tags)) {
    nodes<-xml_find_all(doc,paste0('//',tag))
    if(tag=='KRETS_KOMMUN')nodes<-nodes[!grepl('00$',xml_attr(nodes,'KOD'))]
    for(n in nodes) {
     i<-i+1L;v<-xml_find_first(n,'./VALDELTAGANDE');inv<-xml_find_all(n,'./OGILTIGA')
     getnum<-function(node,attr)as.integer(xml_attr(node,attr))
     counts<-getnum(inv,'RÖSTER');types<-xml_attr(inv,'TEXT')
     valid<-getnum(n,'RÖSTER');cast<-getnum(v,'SUMMA_RÖSTER')
     if(is.na(cast))cast<-valid+sum(counts)
     units[[i]]<-data.frame(stage=stage,level=tags[[tag]],code=xml_attr(n,'KOD'),
      name=xml_attr(n,'NAMN'),valid=valid,cast=cast,eligible=getnum(v,'RÖSTBERÄTTIGADE'),
      invalid=sum(counts),blank=counts[match('BLANK',types)],
      municipality=xml_attr(xml_find_first(n,'ancestor-or-self::KOMMUN[1]'),'KOD'))
     p<-xml_find_all(n,'./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA')
     parties[[i]]<-data.frame(stage=stage,level=tags[[tag]],code=xml_attr(n,'KOD'),
      alias=xml_attr(p,'PARTI'),votes=getnum(p,'RÖSTER'))
    }
   }
  }
  cat('PASS independent XML geography census',stage,'\n');flush.console()
 }
 u<-dplyr::bind_rows(units);p<-dplyr::bind_rows(parties)
 for(stage in c('final','preliminary')) {
  dis<-u[u$stage==stage&u$level=='district',]
  sums<-dis|>dplyr::summarise(total=sum(.data$cast),valid=sum(.data$valid),.by='municipality')
  mun<-u[u$stage==stage&u$level=='municipality',];j<-match(mun$code,sums$municipality)
  stopifnot(nrow(dis)==6305L,sum(grepl('^E-',dis$code))==321L,nrow(mun)==290L,!anyNA(j),all(mun$cast==sums$total[j]),all(mun$valid==sums$valid[j]))
 }
 stopifnot(!anyDuplicated(u[c('stage','level','code')]))
 for(stage in c('final','preliminary'))for(level in unique(u$level)) {
  x<-api_results[[paste(stage,level)]]
  g<-if(level=='national')rep('00',nrow(x))else x[[paste0(level,'_code')]]
  unique_units<-!duplicated(g);j<-match(g[unique_units],u$code[u$stage==stage&u$level==level])
  ref<-u[u$stage==stage&u$level==level,]
  stopifnot(nrow(ref)==length(j),!anyNA(j))
  for(pair in list(c('valid_votes','valid'),c('total_votes','cast'),c('eligible_voters','eligible'),c('invalid_votes','invalid'),c('blank_votes','blank')))
   stopifnot(identical(as.integer(x[[pair[1]]][unique_units]),as.integer(ref[[pair[2]]][j])))
  expected_turnout<-x$total_votes/x$eligible_voters
  stopifnot(isTRUE(all.equal(x$turnout,expected_turnout,check.attributes=FALSE)))
  z<-p[p$stage==stage&p$level==level,]
  keys<-paste(g,x$party_abbreviation);hit<-match(paste(z$code,z$alias),keys)
  # Numeric source aliases use the official party code rather than abbreviation.
  num<-is.na(hit)&grepl('^[0-9]+$',z$alias)
  hit[num]<-match(paste(z$code[num],z$alias[num]),paste(g,x$party_code))
  stopifnot(!anyNA(hit),all(x$votes[hit]==z$votes))
  cat('PASS API / independent XML',stage,level,nrow(ref),'units',nrow(z),'party cells\n')
 }
 original<-read_xml(file.path(scratch,'final','slutresultat_00E.xml'))
 v<-xml_find_all(original,'.//VALD');s<-xml_find_all(original,'.//ERSÄTTARE')
 stopifnot(length(v)==20L,length(s)==27L,setequal(elected$candidate_number,xml_attr(v,'KANDNR')),
  setequal(substitutes$substitute_candidate_number,xml_attr(s,'KANDNR')))
 j<-match(elected$candidate_number,xml_attr(v,'KANDNR'))
 stopifnot(all(elected$order_of_election==as.integer(xml_attr(v,'ORDNING'))[j]),
  all(elected$election_basis_id==xml_attr(v,'GRUND')[j]))
 expected_party<-xml_attr(xml_find_first(v,'ancestor::GILTIGA[1]'),'PARTI')
 stopifnot(all(elected$party_abbreviation==expected_party[j]),all(elected$election_code=='E'),
  all(elected$election_year==2019L),all(elected$elected_electoral_area_code=='00'),all(elected$elected_constituency_code=='00'))
 groups<-xml_find_all(original,'.//GRUPP_VALDA');pairs<-lapply(groups,function(g) {
  a<-xml_find_all(g,'./VALD');b<-xml_find_all(g,'./ERSÄTTARE')
  pairs<-expand.grid(member=xml_attr(a,'KANDNR'),sub=xml_attr(b,'KANDNR'),stringsAsFactors=FALSE)
  pairs$party<-xml_attr(xml_find_first(g,'..'),'PARTI')
  pairs$order<-as.integer(xml_attr(b,'ORDNING'))[match(pairs$sub,xml_attr(b,'KANDNR'))]
  pairs
 });pairs<-dplyr::bind_rows(pairs)
 stopifnot(nrow(pairs)==74L,setequal(paste(pairs$member,pairs$sub),paste(substitutes$member_candidate_number,substitutes$substitute_candidate_number)))
 stopifnot(setequal(paste(pairs$party,pairs$member,pairs$sub,pairs$order),
  paste(substitutes$party_abbreviation,substitutes$member_candidate_number,substitutes$substitute_candidate_number,substitutes$substitute_order)),
  all(substitutes$electoral_area_code=='00'),all(substitutes$constituency_code=='00'))
 # Every reported list/candidate ID, ballot position and preference count.
 district<-list();controls<-0L
 for(f in list.files(file.path(scratch,'final'),pattern='_[0-9]{4}E[.]xml$',full.names=TRUE)) {
  doc<-read_xml(f);ln<-xml_find_all(doc,'//VALDISTRIKT/GILTIGA/VALSEDEL|//ONSDAGSDISTRIKT/GILTIGA/VALSEDEL|//VALDISTRIKT/ÖVRIGA_GILTIGA/GILTIGA/VALSEDEL|//ONSDAGSDISTRIKT/ÖVRIGA_GILTIGA/GILTIGA/VALSEDEL')
  v<-xml_find_all(ln,'./PERSONVAL');parent<-xml_find_first(v,'..');unit<-xml_find_first(v,'ancestor::*[self::VALDISTRIKT or self::ONSDAGSDISTRIKT][1]')
  z<-data.frame(code=xml_attr(unit,'KOD'),list=xml_attr(parent,'LISTNUMMER'),id=xml_attr(v,'KANDNR'),
   position=as.integer(xml_attr(v,'KANDIDAT')),rank=as.integer(xml_attr(v,'ORDNING')),votes=as.integer(xml_attr(v,'PERSONKRYSS')))
  district[[f]]<-z
  reported<-as.integer(xml_attr(ln,'PERSONKRYSS'));actual<-vapply(ln,function(n)sum(as.integer(xml_attr(xml_find_all(n,'./PERSONVAL'),'PERSONKRYSS'))),0L)
  stopifnot(all(reported[!is.na(reported)]==actual[!is.na(reported)]));controls<-controls+sum(!is.na(reported))
 }
 ref<-dplyr::bind_rows(district);x<-api_preferences
 key<-paste(x$district_code,paste(x$party_code,x$list_number,sep='-'),x$candidate_number)
 j<-match(paste(ref$code,ref$list,ref$id),key)
 stopifnot(nrow(ref)==410308L,nrow(x)==410308L,!anyNA(j),!anyDuplicated(j),all(x$preference_votes[j]==ref$votes),sum(ref$votes)==1634596L)
 position_key<-paste(candidacies$party_code,candidacies$list_number,candidacies$candidate_number)
 j<-match(paste(sub('-.*','',ref$list),sub('^[^-]+-','',ref$list),ref$id),position_key)
 stopifnot(!anyNA(j),all(ref$position==candidacies$ballot_order[j]))
 cat('PASS all 410308 reported preference observations and',controls,'district list controls\n')
 # Independent official Excel: specify numeric columns to avoid sparse-party type inference.
 for(level in c('district','municipality')) {
  f<-file.path(control_dir,if(level=='district')'current-district.xlsx'else'current-municipal.xlsx')
  stopifnot(file.exists(f));hdr<-readxl::read_excel(f,sheet='antal',n_max=0,.name_repair='unique_quiet')
  ct<-rep('numeric',ncol(hdr));ct[grepl('NAMN$',names(hdr))]<-'text'
  ex<-readxl::read_excel(f,sheet='antal',col_types=ct,.name_repair='unique_quiet')
  code<-paste0(sprintf('%02d',ex$LÄNSKOD),sprintf('%02d',ex$KOMMUNKOD))
  z<-u[u$stage=='final'&u$level==level,]
  if(level=='district') {ordinary<-paste0(code,sprintf('%04d',ex$VALDISTRIKTSKOD));code<-ifelse(ordinary%in%z$code,ordinary,paste0('E-',code,'-',sprintf('%02d',ex$VALDISTRIKTSKOD)))}
  j<-match(code,z$code);stopifnot(!anyNA(j),length(j)==nrow(z),all(ex[['RÖSTER GILTIGA']]==z$valid[j]),all(ex$RÖSTANDE==z$cast[j]))
  x<-api_results[[paste('final',level)]]
  key<-paste(if(level=='district')x$district_code else x$municipality_code,x$party_abbreviation)
  for(alias in intersect(unique(x$party_abbreviation),names(ex))) {
   j<-match(paste(code,alias),key);values<-x$votes[j]
   stopifnot(all(dplyr::coalesce(as.integer(ex[[alias]]),0L)==dplyr::coalesce(values,0L)))
  }
  cat('PASS official final Excel',level,nrow(z),'\n')
 }
 scb<-readxl::read_excel(file.path(control_dir,'scb-district.xlsx'),skip=2,col_names=FALSE,.name_repair='unique_quiet')
 ordinary<-!grepl('9800$',scb[[4]]);z<-u[u$stage=='final'&u$level=='district'&!grepl('^E-',u$code),]
 j<-match(scb[[4]][ordinary],z$code)
 stopifnot(sum(ordinary)==5984L,!anyNA(j),all(as.numeric(scb[[5]][ordinary])==z$eligible[j]),all(as.numeric(scb[[7]][ordinary])==z$cast[j]),all(as.numeric(scb[[11]][ordinary])==z$valid[j]),sum(as.numeric(scb[[11]]))==4151470L)
 # SCB's 290 postal rows merge the 321 official Wednesday units.
 w<-u[u$stage=='final'&u$level=='district'&grepl('^E-',u$code),]
 ws<-w|>dplyr::summarise(valid=sum(.data$valid),cast=sum(.data$cast),.by='municipality')
 j<-match(scb[[2]][!ordinary],ws$municipality)
 stopifnot(length(j)==290L,!anyNA(j),all(as.numeric(scb[[11]][!ordinary])==ws$valid[j]),all(as.numeric(scb[[7]][!ordinary])==ws$cast[j]))
 cat('PASS SCB 5984 ordinary and 290 merged postal units\n')
 county<-readxl::read_excel(file.path(control_dir,'scb-county.xlsx'),col_names=FALSE,.name_repair='unique_quiet')
 county<-county[!is.na(county[[1]])&!is.na(suppressWarnings(as.numeric(county[[2]]))),]
 z<-u[u$stage=='final'&u$level%in%c('county','national'),]
 j<-match(ifelse(grepl('^Hela',county[[1]]),'Sverige',county[[1]]),z$name)
 stopifnot(nrow(county)==22L,!anyNA(j),all(as.numeric(county[[2]])==z$eligible[j]),all(as.numeric(county[[4]])==z$cast[j]),all(as.numeric(county[[8]])==z$valid[j]))
 el<-readxl::read_excel(file.path(control_dir,'scb-electorate.xlsx'),col_names=FALSE,.name_repair='unique_quiet')
 el<-el[!is.na(el[[1]])&!is.na(suppressWarnings(as.numeric(el[[16]]))),]
 j<-match(ifelse(grepl('^Hela',el[[1]]),'Sverige',el[[1]]),z$name)
 stopifnot(nrow(el)==22L,!anyNA(j),all(as.numeric(el[[4]])+as.numeric(el[[8]])+as.numeric(el[[12]])==z$eligible[j]))
 cat('PASS SCB national/county totals and electorate components\n')
 overview<-readxl::read_excel(file.path(control_dir,'scb-candidate-overview.xlsx'),sheet='tab 1',col_names=FALSE,.name_repair='unique_quiet')
 stopifnot(overview[[7]][4]=='2019',overview[[14]][4]=='2019')
 nominated<-sum(as.integer(overview[[7]][-seq_len(4)][overview[[7]][-seq_len(4)]!='..']))
 selected<-sum(as.integer(overview[[14]][-seq_len(4)][overview[[14]][-seq_len(4)]!='..']))
 stopifnot(nominated==sum(candidacies$valid),nominated==556L,selected==nrow(elected),selected==20L)
 national<-u[u$level=='national',];j<-match(c('final','preliminary'),national$stage)
 stopifnot(identical(national$valid[j],c(4151470L,4126721L)),identical(national$cast[j],c(4187848L,4186601L)))
 cat('PASS SCB nominated/elected controls 556/20 and both national counting stages\n')
 invisible(TRUE)
}
