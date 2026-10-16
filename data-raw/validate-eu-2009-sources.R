# Independent original-XML and SCB controls. No production XML normaliser is used.
.validate_eu2009_sources <- function(files, refs, preference_district, elected, substitutes, kd, control_dir) {
 library(xml2)
 ad<-read_xml(files[['candidacies']]);bp<-xml_find_all(ad,'//PARTI')
 pd<-local({con<-unz(files[['final']],'slutresultat_00E.xml',open='rb');on.exit(close(con));read_xml(con)})
 p<-xml_find_all(pd,'./PARTI');aliases<-xml_attr(p,'FÖRKORTNING')
 codes<-xml_attr(bp,'KOD')[match(xml_attr(p,'BETECKNING'),xml_attr(bp,'BETECKNING'))]
 party_codes<-setNames(codes,aliases)
 units<-parties<-prefs<-list();i<-0L
 members<-utils::unzip(files[['final']],list=TRUE)$Name
 members<-sort(members[grepl('^slutresultat_[0-9]{2,4}E[.]xml$',members)])
 for(f in members) {
  con<-unz(files[['final']],f,open='rb');d<-read_xml(con);close(con)
  national<-f=='slutresultat_00E.xml'
  nodes<-if(national)xml_find_all(d,'./NATION|./NATION/LÄN')else xml_find_all(d,'./KOMMUN|.//KRETS_KOMMUN|.//VALDISTRIKT|.//ONSDAGSDISTRIKT')
  for(n in nodes) {
   tag<-xml_name(n);code<-xml_attr(n,'KOD')
   if(tag=='KRETS_KOMMUN'&&grepl('00$',code))next
   level<-c(NATION='national',LÄN='county',KOMMUN='municipality',KRETS_KOMMUN='municipal_constituency',VALDISTRIKT='district',ONSDAGSDISTRIKT='district')[[tag]]
   i<-i+1L;inv<-as.integer(xml_attr(xml_find_all(n,'./OGILTIGA'),'RÖSTER'))
   turnout<-xml_find_first(n,'./VALDELTAGANDE')
   units[[i]]<-data.frame(level,code,valid=as.integer(xml_attr(n,'RÖSTER')),
    invalid=sum(inv),cast=as.integer(xml_attr(n,'RÖSTER'))+sum(inv),eligible=as.integer(xml_attr(turnout,'RÖSTBERÄTTIGADE')))
   ps<-xml_find_all(n,'./GILTIGA[not(@PARTI="ÖVR")]|./GILTIGA[@PARTI="ÖVR"]/VARAV_ÖVRIGA[not(@PARTI="ÖVR")]')
   ov<-xml_find_first(n,'./GILTIGA[@PARTI="ÖVR"]')
   pp<-data.frame(level,code,party=unname(party_codes[xml_attr(ps,'PARTI')]),votes=as.integer(xml_attr(ps,'RÖSTER')),other=FALSE)
   if(!inherits(ov,'xml_missing'))pp<-rbind(pp,data.frame(level,code,party=NA_character_,votes=as.integer(xml_attr(ov,'RÖSTER'))-sum(as.integer(xml_attr(xml_find_all(ov,'./VARAV_ÖVRIGA[not(@PARTI="ÖVR")]'),'RÖSTER'))),other=TRUE))
   parties[[i]]<-pp
   if(level=='district') {
    v<-xml_find_all(n,'./GILTIGA/VALSEDEL/PERSONVAL');l<-xml_find_first(v,'..');a<-xml_attr(xml_find_first(l,'..'),'PARTI')
    prefs[[i]]<-data.frame(code=rep(code,length(v)),party=unname(party_codes[a]),
     list=sub('^[^-]+-','',xml_attr(l,'LISTNUMMER')),position=as.integer(xml_attr(v,'KANDIDAT')),votes=as.integer(xml_attr(v,'PERSONKRYSS')))
   }
  }
 }
 u<-purrr::list_rbind(units);p<-purrr::list_rbind(parties);pv<-purrr::list_rbind(prefs)
 for(level in names(refs)) {
  x<-refs[[level]];g<-switch(level,national=rep('00',nrow(x)),county=x$county_code,municipality=x$municipality_code,municipal_constituency=x$municipal_constituency_code,district=x$district_code)
  stopifnot(all(c('valid_votes','invalid_votes','total_votes','eligible_voters')%in%names(x)))
  a<-p[p$level==level,];ix<-match(paste(g,x$party_code,x$other_parties),paste(a$code,a$party,a$other))
  stopifnot(nrow(x)==nrow(a),!anyNA(ix),identical(x$votes,a$votes[ix]))
  a<-u[u$level==level,];j<-match(g,a$code)
  stopifnot(!anyNA(j),all(x$valid_votes==a$valid[j]),all(x$invalid_votes==a$invalid[j]),all(x$total_votes==a$cast[j]),identical(x$eligible_voters,a$eligible[j]))
 }
 # Public candidate keys are candidacy coordinates, not raw person IDs.
 main<-preference_district[!grepl(':source-column:',preference_district$candidate_number),]
 keys<-paste0('2009:E:ballot:',pv$list,':',pv$position)
 ix<-match(paste(main$district_code,main$party_code,main$candidate_number),paste(pv$code,pv$party,keys))
 stopifnot(nrow(main)==370716L,nrow(main)==nrow(pv),!anyNA(ix),identical(main$preference_votes,pv$votes[ix]),sum(main$preference_votes)==1874130L)
 # Every source list-level sum is controlled at its own level, not a duplicate party view.
 controls<-0L
 for(f in members){con<-unz(files[['final']],f,open='rb');d<-read_xml(con);close(con)
  for(l in xml_find_all(d,'//VALSEDEL[@PERSONKRYSS]')){
   v<-as.integer(xml_attr(xml_find_all(l,'./PERSONVAL'),'PERSONKRYSS'))
   stopifnot(sum(v)==as.integer(xml_attr(l,'PERSONKRYSS')));controls<-controls+1L
  }
 }
 stopifnot(controls==64762L)
 # All500 ballot positions and literal descriptions are independently checked.
 v<-xml_find_all(ad,'//KANDIDAT');l<-xml_find_first(v,'..');p<-xml_find_first(l,'..')
 pos<-as.integer(xml_attr(v,'ORDNING'));ln<-xml_attr(l,'LISTNUMMER');pk<-xml_attr(p,'KOD')
 j<-match(paste(kd$party_code,kd$list_number,kd$ballot_order),paste(pk,ln,pos))
 stopifnot(nrow(kd)==500L,length(v)==500L,!anyNA(j),!anyDuplicated(j))
 stopifnot(identical(kd$candidate_number,paste0('2009:E:ballot:',ln[j],':',pos[j])))
 stopifnot(identical(kd$ballot_info,xml_attr(v,'KANDIDATUPPGIFT')[j]),identical(kd$name,trimws(sub(',.*$','',xml_attr(v,'KANDIDATUPPGIFT')[j]))))
 stopifnot(identical(kd$age_on_election_day,as.integer(xml_attr(v,'ÅLDER'))[j]),identical(kd$sex,xml_attr(v,'KÖN')[j]))
 stopifnot(identical(kd$ballot_status,xml_attr(l,'STATUS')[j]),identical(kd$candidates_registered,xml_attr(l,'KANDIDATANMÄLAN')[j]=='Ja'),all(is.na(kd$valid)))
 cat('PASS all500 original ballot/list positions, descriptions, names, ages, sex, status and registration flags\n')
 # The final elected roster is matched by party + name + age and original order/basis.
 ep<-xml_find_all(pd,'./NATION/GILTIGA[GRUPP_VALDA]');expected<-rels<-list();i<-0L
 for(p in ep)for(g in xml_find_all(p,'./GRUPP_VALDA')) {
  v<-xml_find_all(g,'./VALD');s<-xml_find_all(g,'./ERSÄTTARE');i<-i+1L
  expected[[i]]<-data.frame(party=rep(unname(party_codes[xml_attr(p,'PARTI')]),length(v)),name=xml_attr(v,'NAMN'),age=as.integer(xml_attr(v,'ÅLDER')),order=as.integer(xml_attr(v,'ORDNING')),basis=xml_attr(v,'GRUND'))
  rels[[i]]<-data.frame(party=unname(party_codes[xml_attr(p,'PARTI')]),group=xml_attr(g,'ORDNING'),v=rep(xml_attr(v,'NAMN'),each=length(s)),s=rep(xml_attr(s,'NAMN'),times=length(v)),order=rep(as.integer(xml_attr(s,'ORDNING')),times=length(v)))
 }
 e<-purrr::list_rbind(expected);j<-match(paste(elected$party_code,elected$name,elected$age_on_election_day),paste(e$party,e$name,e$age))
 stopifnot(nrow(elected)==18L,!anyNA(j),identical(elected$order_of_election,e$order[j]),identical(elected$election_basis_id,e$basis[j]),nrow(substitutes)==68L)
 er<-purrr::list_rbind(rels)
 j<-match(paste(substitutes$party_code,substitutes$substitute_group,substitutes$member_name,substitutes$substitute_name,substitutes$substitute_order),paste(er$party,er$group,er$v,er$s,er$order))
 stopifnot(nrow(er)==68L,!anyNA(j),!anyDuplicated(j))
 # Independent small-party workbook source-coordinate check: no name joins.
 w<-readxl::read_excel(files[['small_preferences']],col_names=FALSE,.name_repair='minimal');w<-w[-1,]
 small<-preference_district[grepl(':source-column:',preference_district$candidate_number),]
 j<-match(small$district_code,sprintf('%08d',as.integer(w[[1]])))
 col<-as.integer(sub('^.*:','',small$candidate_number))
 stopifnot(nrow(small)==1983L,!anyNA(j),sum(small$preference_votes)==2571L)
 for(c in unique(col))stopifnot(identical(small$preference_votes[col==c],as.integer(w[[c]][j[col==c]])))
 # SCB district table has 290 pooled postal units, not 396 XML Wednesday units.
 scb<-readxl::read_excel(file.path(control_dir,'scb-district.xls'),col_names=FALSE,.name_repair='minimal')[-1,]
 names(scb)<-c('county','county_name','municipality','municipality_name','code','name','eligible','foreign','cast','invalid','blank','valid','M','C','FP','KD','MP','S','V','PP','other')
 dx<-refs$district;g<-ifelse(dx$district_type=='uppsamlingsdistrikt',paste0(dx$municipality_code,'9800'),dx$district_code)
 a<-unique(data.frame(code=g,raw=dx$district_code,valid=dx$valid_votes,invalid=dx$invalid_votes,cast=dx$total_votes,eligible=dx$eligible_voters))
 a<-a|>dplyr::summarise(valid=sum(.data$valid),invalid=sum(.data$invalid),cast=sum(.data$cast),eligible=sum(.data$eligible,na.rm=TRUE),.by='code')
 j<-match(as.character(scb$code),a$code);stopifnot(nrow(scb)==5954L,!anyNA(j))
 for(n in c('valid','invalid','cast','eligible'))stopifnot(all(as.integer(scb[[n]])==a[[n]][j]))
 for(n in c('M','C','FP','KD','MP','S','V','PP')) {
  a<-data.frame(code=g,votes=dx$votes,party=dx$party_abbreviation)
  a<-a[a$party==n & !is.na(a$party),]|>dplyr::summarise(votes=sum(.data$votes),.by='code')
  stopifnot(all(as.integer(scb[[n]])==a$votes[match(as.character(scb$code),a$code)]))
 }
 a<-data.frame(code=g,votes=dx$votes,other=!(dx$party_abbreviation%in%c('M','C','FP','KD','MP','S','V','PP')))
 a<-a[a$other,]|>dplyr::summarise(votes=sum(.data$votes),.by='code')
 stopifnot(all(as.integer(scb$other)==a$votes[match(as.character(scb$code),a$code)]))
 n<-readxl::read_excel(file.path(control_dir,'scb-nominee-overview.xlsx'),sheet='tab 1',col_names=FALSE,.name_repair='minimal')
 stopifnot(sum(as.integer(n[[5]][5:16][n[[5]][5:16]!='..']),na.rm=TRUE)==488L)
 # SCB Table12: eight mandate parties x national/21 counties =176 controls.
 t<-readxl::read_excel(file.path(control_dir,'scb-party-preferences.xls'),col_names=FALSE,.name_repair='minimal')
 for(panel in 1:2){
  rows<-if(panel==1)seq_len(38)else 39:nrow(t);a<-t[rows,];a<-a[!is.na(suppressWarnings(as.integer(a[[2]]))),]
  stopifnot(nrow(a)==22L)
  for(i in 1:4){alias<-if(panel==1)c('M','C','FP','KD')[i]else c('MP','S','V','PP')[i]
   z<-preference_district[preference_district$party_abbreviation==alias & !is.na(preference_district$party_abbreviation),]
   v<-tapply(z$preference_votes,z$county_name,sum);v<-c(v,Sverige=sum(z$preference_votes))
   geo<-as.character(a[[1]]);geo[geo=='Hela riket']<-'Sverige'
   stopifnot(!anyNA(v[geo]),all(as.integer(a[[c(2,7,12,17)[i]]])==v[geo]))
  }
 }
 cat('PASS176 independent SCB national/county preference controls\n')
 # Revised SCB disclosed smaller-party municipality controls (0.5% threshold).
 t<-readxl::read_excel(file.path(control_dir,'scb-small.xls'),col_names=FALSE,.name_repair='minimal')
 geo<-as.character(t[[1]]);for(i in seq_along(geo))if(is.na(geo[i])&&i>1L)geo[i]<-geo[i-1L]
 ok<-!is.na(suppressWarnings(as.integer(t[[4]])));geo<-geo[ok];geo[geo=='Malung']<-'Malung-Sälen'
 labels<-as.character(t[[3]][ok]);labels[labels=='Arbetarinitiativet']<-xml_attr(xml_find_first(pd,'./PARTI[@FÖRKORTNING="Ai"]'),'BETECKNING')
 alias<-xml_attr(xml_find_all(pd,'./PARTI'),'FÖRKORTNING')[match(labels,xml_attr(xml_find_all(pd,'./PARTI'),'BETECKNING'))]
 r<-refs$municipality;j<-match(paste(geo,unname(party_codes[alias])),paste(r$municipality_name,r$party_code))
 stopifnot(sum(ok)==866L,!anyNA(j),all(as.integer(t[[4]][ok])==r$votes[j]))
 e<-readr::read_delim(files[['electorate']],delim=';',col_names=FALSE,skip=1,col_types=readr::cols(.default='c'),locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
 ec<-paste0(e[[12]],e[[24]],e[[36]]);j<-match(ec,dx$district_code)
 stopifnot(nrow(e)==5664L,!anyNA(j),all(as.integer(e[[38]])==dx$eligible_voters[j]))
 stopifnot(sum(as.integer(e[[38]]))==7088303L,sum(as.integer(e[[45]]))==48413L,sum(as.integer(e[[46]]))==137536L)
 cat('PASS866 SCB small-party municipal controls and5664 independent electorate records\n')
 cat('PASS1983 small-party positive district cells; SCB488 unique-person control kept distinct from500 candidacies; all68 substitute identities/orders\n')
 cat('PASS independent original XML: all party/unit fields,370716 main preferences,64762 list controls,18 elected,68 substitute relations; SCB5954 units\n')
 invisible(list(units=u,parties=p,preferences=pv))
}
