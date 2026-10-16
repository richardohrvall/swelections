# Independent R parser: no production XML normalisers are used here.
.validate_eu2014_sources <- function(files,control_dir,api_results,pref,elected,substitutes,kd) {
 scratch<-tempfile();dir.create(scratch);on.exit(unlink(scratch,recursive=TRUE),add=TRUE)
 utils::unzip(files[['final']],exdir=scratch)
 units<-parties<-preferences<-list();i<-0L;list_controls<-0L
 tags<-c(NATION='national','LÄN'='county',KOMMUN='municipality',KRETS_KOMMUN='municipal_constituency',VALDISTRIKT='district',ONSDAGSDISTRIKT='district')
 gx<-'ancestor::*[self::NATION or self::LÄN or self::KRETS_RIKSDAG or self::KOMMUN or self::KRETS_KOMMUN or self::VALDISTRIKT or self::ONSDAGSDISTRIKT][1]'
 for(f in sort(list.files(scratch,pattern='[.]xml$',full.names=TRUE))){
  x<-xml2::read_xml(f,options=c('NONET','NOBLANKS'));national<-grepl('_00E[.]xml$',f);i<-i+1L
  g<-xml2::xml_find_all(x,paste0('//',names(tags),collapse=' | '));lev<-unname(tags[xml2::xml_name(g)])
  keep<-if(national)lev%in%c('national','county')else lev%in%c('municipality','municipal_constituency','district')
  keep<-keep&!(lev=='municipal_constituency'&grepl('00$',xml2::xml_attr(g,'KOD')));g<-g[keep];lev<-lev[keep]
  ni<-function(n,a)as.integer(xml2::xml_attr(n,a));v<-xml2::xml_find_first(g,'./VALDELTAGANDE')
  blank<-ni(xml2::xml_find_first(g,'./OGILTIGA[@TEXT="BLANK"]'),'RÖSTER');other<-ni(xml2::xml_find_first(g,'./OGILTIGA[@TEXT="OG"]'),'RÖSTER');valid<-ni(g,'RÖSTER');cast<-ni(v,'SUMMA_RÖSTER')
  cast[is.na(cast)]<-(valid+blank+other)[is.na(cast)]
  units[[i]]<-tibble::tibble(level=lev,code=xml2::xml_attr(g,'KOD'),name=xml2::xml_attr(g,'NAMN'),
   valid=valid,blank=blank,invalid=blank+other,cast=cast,eligible=ni(v,'RÖSTBERÄTTIGADE'))
  pp<-xml2::xml_find_all(x,'//GILTIGA');gg<-xml2::xml_find_first(pp,gx)
  # Subsetting an XML nodeset can deduplicate repeated ancestor nodes.
  # Preserve parallel geographic vectors before filtering individual party nodes.
  gl<-unname(tags[xml2::xml_name(gg)]);gc<-xml2::xml_attr(gg,'KOD')
  kk<-paste(gl,gc)%in%paste(lev,xml2::xml_attr(g,'KOD'))
  pp<-pp[kk]
  parties[[i]]<-tibble::tibble(level=gl[kk],code=gc[kk],
   alias=xml2::xml_attr(pp,'PARTI'),votes=ni(pp,'RÖSTER'))
  ln<-xml2::xml_find_all(x,'//VALDISTRIKT//VALSEDEL | //ONSDAGSDISTRIKT//VALSEDEL')
  pv<-xml2::xml_find_all(ln,'./PERSONVAL');parent<-xml2::xml_find_first(pv,'..');gg<-xml2::xml_find_first(pv,gx)
  preferences[[i]]<-tibble::tibble(code=xml2::xml_attr(gg,'KOD'),list=xml2::xml_attr(parent,'LISTNUMMER'),
   id=xml2::xml_attr(pv,'KANDNR'),position=ni(pv,'KANDIDAT'),votes=ni(pv,'PERSONKRYSS'))
  totals<-ni(ln,'PERSONKRYSS');actual<-vapply(ln,function(n)sum(ni(xml2::xml_find_all(n,'./PERSONVAL'),'PERSONKRYSS')),0L)
  stopifnot(all(totals[!is.na(totals)]==actual[!is.na(totals)]));list_controls<-list_controls+sum(!is.na(totals))
 }
 u<-dplyr::bind_rows(units);p<-dplyr::bind_rows(parties);pv<-dplyr::bind_rows(preferences)
 for(level in unique(u$level)){
  a<-api_results[[level]];code<-if(level=='national')rep('00',nrow(a))else a[[paste0(level,'_code')]]
  keep<-!duplicated(code);ref<-u[u$level==level,];j<-match(code[keep],ref$code)
  stopifnot(length(j)==nrow(ref),!anyNA(j))
  for(pair in list(c('valid_votes','valid'),c('invalid_votes','invalid'),c('blank_votes','blank'),c('total_votes','cast'),c('eligible_voters','eligible')))
   stopifnot(identical(as.integer(a[[pair[1]]][keep]),ref[[pair[2]]][j]))
  z<-p[p$level==level,];ix<-match(paste(z$code,z$alias),paste(code,a$party_abbreviation))
  stopifnot(!anyNA(ix),all(a$votes[ix]==z$votes))
  sums<-tapply(a$votes,code,sum);stopifnot(all(sums[code[keep]]==a$valid_votes[keep]))
  cat('PASS independent XML/API',level,nrow(ref),'units',nrow(z),'named-party cells\n');flush.console()
 }
 key<-paste(pref$district_code,paste(pref$party_code,pref$list_number,sep='-'),pref$candidate_number)
 j<-match(paste(pv$code,pv$list,pv$id),key)
 stopifnot(nrow(pv)==402053L,nrow(pref)==402053L,!anyNA(j),!anyDuplicated(j),all(pref$preference_votes[j]==pv$votes),sum(pv$votes)==1859375L)
 j<-match(paste(sub('-.*','',pv$list),sub('^[^-]+-','',pv$list),pv$id),paste(kd$party_code,kd$list_number,kd$candidate_number))
 stopifnot(!anyNA(j),all(kd$ballot_order[j]==pv$position))
 cat('PASS all402053source preference observations and',list_controls,'district list controls\n')
 original<-xml2::read_xml(file.path(scratch,'slutresultat_00E.xml'));v<-xml2::xml_find_all(original,'.//VALD');s<-xml2::xml_find_all(original,'.//ERSÄTTARE')
 j<-match(elected$candidate_number,xml2::xml_attr(v,'KANDNR'))
 stopifnot(length(v)==20L,length(s)==30L,nrow(elected)==20L,!anyNA(j),
  setequal(substitutes$substitute_candidate_number,xml2::xml_attr(s,'KANDNR')),
  all(elected$order_of_election==as.integer(xml2::xml_attr(v,'ORDNING'))[j]),
  all(elected$election_basis_id==xml2::xml_attr(v,'GRUND')[j]))
 groups<-xml2::xml_find_all(original,'.//GRUPP_VALDA');pairs<-lapply(groups,function(g){
  v<-xml2::xml_find_all(g,'./VALD');s<-xml2::xml_find_all(g,'./ERSÄTTARE');z<-expand.grid(member=xml2::xml_attr(v,'KANDNR'),sub=xml2::xml_attr(s,'KANDNR'),stringsAsFactors=FALSE)
  z$party<-xml2::xml_attr(xml2::xml_find_first(g,'..'),'PARTI');z$order<-as.integer(xml2::xml_attr(s,'ORDNING'))[match(z$sub,xml2::xml_attr(s,'KANDNR'))];z})
 pairs<-dplyr::bind_rows(pairs);stopifnot(nrow(pairs)==74L,setequal(paste(pairs$party,pairs$member,pairs$sub,pairs$order),paste(substitutes$party_abbreviation,substitutes$member_candidate_number,substitutes$substitute_candidate_number,substitutes$substitute_order)))
 cat('PASS original20elected/30substitutes/74relationships\n')
 # Independently preserved SCB API: source category TOTALT includes all candidates.
 scb<-jsonlite::fromJSON(file.path(control_dir,'scb-preference-2014.json'),simplifyVector=FALSE)
 scb<-dplyr::bind_rows(lapply(scb$data,function(z)tibble::tibble(code=z$key[[1]],party=z$key[[2]],votes=as.integer(z$values[[1]]))))
 pv$mun<-ifelse(grepl('^E-',pv$code),substring(pv$code,3,6),substring(pv$code,1,4))
 ls<-xml2::xml_find_all(original,'.//VALSEDEL');map<-unique(data.frame(list=xml2::xml_attr(ls,'LISTNUMMER'),party=xml2::xml_attr(xml2::xml_find_first(ls,'..'),'PARTI')))
 pv$party<-map$party[match(pv$list,map$list)];major<-c('M','C','FP','KD','MP','S','V','JL','PP','FI','SD');pv$party[!pv$party%in%major]<-'ÖVRIGA'
 totals<-pv|>dplyr::summarise(votes=sum(.data$votes),.by=c('mun','party'));all<-pv|>dplyr::summarise(votes=sum(.data$votes),.by='mun')|>dplyr::mutate(party='TOTALT');totals<-dplyr::bind_rows(totals,all)
 q<-scb[scb$code!='00',];j<-match(paste(q$code,q$party),paste(totals$mun,totals$party));stopifnot(nrow(q)==3770L,all(q$votes==dplyr::coalesce(totals$votes[j],0L)))
 cat('PASS all3770SCBmunicipality party/total preference controls\n')
 # SCB workbook population and county electorate: separate original files.
 x<-readxl::read_excel(file.path(control_dir,'scb-candidate-overview.xlsx'),sheet='tab 2',col_names=FALSE,.name_repair='unique_quiet')
 stopifnot(as.integer(x[[7]][7])==nrow(kd),as.integer(x[[7]][10])==nrow(elected))
 x<-readxl::read_excel(file.path(control_dir,'scb-electorate.xlsx'),col_names=FALSE,.name_repair='unique_quiet');keep<-!is.na(suppressWarnings(as.numeric(x[[16]])));x<-x[keep,]
 ref<-u[u$level%in%c('national','county'),];j<-match(ifelse(grepl('^Hela',x[[1]]),'Sverige',x[[1]]),ref$name)
 stopifnot(nrow(x)==22L,!anyNA(j),all(as.numeric(x[[4]])+as.numeric(x[[8]])+as.numeric(x[[12]])==ref$eligible[j]))
 cat('PASS SCB376nominees/20elected and22electorate controls\n')
 raw<-readr::read_delim(files[['candidacies']],delim=';',col_names=FALSE,locale=readr::locale(encoding='Windows-1252'),col_types=readr::cols(.default='c'),show_col_types=FALSE)
 j<-match(paste(raw[[8]],sprintf('%05d',as.integer(raw[[6]]))),paste(kd$candidate_number,kd$list_number))
 stopifnot(!anyNA(j),!anyDuplicated(j),nrow(raw)==nrow(kd),
  identical(as.integer(raw[[7]]),kd$ballot_order[j]),identical(as.integer(raw[[10]]),kd$age_on_election_day[j]),
  identical(raw[[11]],kd$sex[j]),identical(raw[[12]],kd$ballot_info[j]),
  all(is.na(kd$name)),all(is.na(kd$valid)),all(is.na(kd$consent)))
 cat('PASS all376candidacy keys/positions/age/sex/ballot text and source missingness\n')
 invisible(TRUE)
}
