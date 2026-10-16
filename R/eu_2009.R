# EU 2009: source/list-position observations, never inferred person identifiers.
.eu2009_cache <- new.env(parent = emptyenv())
.eu2009_sources <- function() data.frame(
 role=c('final','candidacies','small_preferences','electorate','handwritten'),
 filename=c('slutresultat.zip','user-ballots-20100209.xml','archived-preferences-ovr-20131031.xls','rostberattigade.skv','handskrivna.skv'),
 sha256=c('b10e2667b1105b7c3fb74eed762f2933f48f820bd06f560817b6cd251a00e7be',
 '45e9c669b0391143366dfe2bf71d3969117f5e8099a5a77b50486b24539dbde4',
 '1a3fb38793ed5cc7e34af96c628645c5c9c885dbe6cc72a6d4afb28ca110b7c6',
 '6f4c4d5627cf34dd9952eacd2c1b6ff41abba42defc18e8397bd4b3c7d4ea9da',
 'f2c83cc2603aa3a78a37c8f5b942f46411bcd783b2182735f1618aa4c6321e61'),
 url=c('https://historik.val.se/val/ep2009/slutresultat/slutresultat.zip',
 'https://web.archive.org/web/20100210203252id_/http://www.val.se/val/ep2009/valsedlar/00E.xml',
 'https://web.archive.org/web/20131031213401id_/http://www.val.se/val/ep2009/statistik/personroster_ovr_2009.xls',
 'https://historik.val.se/val/ep2009/statistik/rostberattigade.skv',
 'https://historik.val.se/val/ep2009/handskrivna/handskrivna.skv'))

.eu2009_file <- function(role, source, data_dir) {
 entry <- .eu2009_sources(); entry <- entry[match(role,entry$role),]
 if(anyNA(entry)) stop('Unknown EU 2009 source role.',call.=FALSE)
 if(source=='remote') stop('EU 2009 requires the pinned preserved original sources; current redacted/truncated files are not equivalent. Use local or a configured canonical build.',call.=FALSE)
 root <- val_data_dir(data_dir)
 roots <- if(is.null(root)) character() else unique(c(file.path(root,'eu','2009'),file.path(root,'2009'),root))
 roots <- roots[dir.exists(roots)]
 if(length(roots)) {
  files <- sort(list.files(roots[1L],recursive=TRUE,full.names=TRUE))
  for(f in files[basename(files)==entry$filename]) if(.canonical_sha256(f)==entry$sha256)return(f)
 }
 stop('Missing approved EU 2009 source: ',entry$filename,call.=FALSE)
}
.eu2009_key <- function(list,position) if(length(list)) paste0('2009:E:ballot:',list,':',position) else character()
.eu2009_retag <- function(x) {
 x$valtillfalle<-rep('EU-val_2009',nrow(x)); x$valar<-rep(2009L,nrow(x))
 if('valdatum'%in%names(x))x$valdatum<-rep('2009-06-07',nrow(x))
 if('valdatum_fg'%in%names(x))x$valdatum_fg<-rep('2004-06-13',nrow(x))
 x
}
.eu2009_candidacies <- function(file) {
 doc<-xml2::read_xml(file,options=c('NONET','NOBLANKS'))
 if(.xml2018_attr(doc,'TID_RAPPORT')!='20090607232501')stop('Unexpected EU 2009 ballot snapshot.',call.=FALSE)
 n<-xml2::xml_find_all(doc,'//KANDIDAT'); l<-xml2::xml_find_first(n,'..'); p<-xml2::xml_find_first(l,'..')
 raw<-.xml2006_candidacy_raw(length(n))
 raw$valtyp<-'E';raw$valomradeskod<-'00';raw$valomradesnamn<-'Sverige'
 raw$valkretskod<-'00';raw$valkretsnamn<-'Sverige'
 raw$partikod<-xml2::xml_attr(p,'KOD');raw$partibeteckning<-xml2::xml_attr(p,'BETECKNING')
 raw$listnummer<-xml2::xml_attr(l,'LISTNUMMER');raw$ordning<-xml2::xml_attr(n,'ORDNING')
 raw$kandidatnummer<-.eu2009_key(raw$listnummer,raw$ordning)
 raw$valsedelsuppgift<-xml2::xml_attr(n,'KANDIDATUPPGIFT')
 raw$namn<-trimws(sub(',.*$','',raw$valsedelsuppgift))
 raw$kon<-xml2::xml_attr(n,'K\u00d6N');raw$alder_pa_valdagen<-xml2::xml_attr(n,'\u00c5LDER')
 raw$valsedelsstatus<-xml2::xml_attr(l,'STATUS')
 out<-.eu2009_retag(parse_kandidaturer_2026(raw,2009L))
 out$valsedelsstatus<-raw$valsedelsstatus
 out$anmalda_kandidater<-xml2::xml_attr(l,'KANDIDATANM\u00c4LAN')=='Ja'
 out
}
.eu2009_register <- function(doc,ballots) {
 nodes<-xml2::xml_find_all(doc,'./PARTI')
 bp<-xml2::xml_find_all(ballots,'//PARTI')
 alias<-xml2::xml_attr(nodes,'F\u00d6RKORTNING'); label<-xml2::xml_attr(nodes,'BETECKNING')
 codes<-xml2::xml_attr(bp,'KOD')[match(label,xml2::xml_attr(bp,'BETECKNING'))]
 keep<-!alias%in%c('BLANK','OG','\u00d6VR')
 if(anyNA(codes[keep]))stop('Unmatched EU 2009 ballot/result party.',call.=FALSE)
 .xml2018_reg_index(tibble::tibble(valtyp='E',valomradeskod='00',
  partiforkortning=alias[keep],partibeteckning=label[keep],partikod=codes[keep]))
}
# Adapt category nesting and explicit ballot positions in memory only.
.eu2009_adapt <- function(doc,kd) {
 ns<-xml2::xml_find_all(doc,'.//GILTIGA[@PARTI="\u00d6VR"]')
 for(n in ns) {
  children<-xml2::xml_find_all(n,'./VARAV_\u00d6VRIGA')
  total<-.xml2018_int(n,'R\u00d6STER'); rest<-total-sum(as.integer(xml2::xml_attr(children,'R\u00d6STER')))
  if(rest<0L)stop('Negative EU 2009 residual party votes.',call.=FALSE)
  xml2::xml_name(n)<-'\u00d6VRIGA_GILTIGA'
  for(z in children) {
   if(.xml2018_attr(z,'PARTI')=='\u00d6VR') {
    xml2::xml_name(z)<-'HANDSKRIVNA'; xml2::xml_set_attr(z,'R\u00d6STER',as.character(.xml2018_int(z,'R\u00d6STER')+rest));rest<-0L
   } else xml2::xml_name(z)<-'GILTIGA'
  }
  if(!length(xml2::xml_find_all(n,'./HANDSKRIVNA')))
   xml2::xml_set_attr(xml2::xml_add_child(n,'HANDSKRIVNA'),'R\u00d6STER',as.character(rest))
 }
 v<-xml2::xml_find_all(doc,'.//VALSEDEL/PERSONVAL')
 l<-xml2::xml_attr(xml2::xml_find_first(v,'..'),'LISTNUMMER')
 keys<-.eu2009_key(sub('^[^-]+-','',l),xml2::xml_attr(v,'KANDIDAT'))
 if(length(keys) && any(!keys%in%kd$kandidatnummer))stop('Unknown EU 2009 result ballot position.',call.=FALSE)
 xml2::xml_set_attr(v,'KANDNR',keys)
 # Relation/qualification linkage requires party, exact source name AND age
 # where supplied, against a single ballot in that party. Never a name-only join.
 v<-xml2::xml_find_all(doc,'.//GRUPP_VALDA/VALD|.//GRUPP_VALDA/ERS\u00c4TTARE|./NATION/GILTIGA/PERSONVAL')
 for(n in v) {
  a<-.xml2018_attr(xml2::xml_find_first(n,'ancestor::GILTIGA[1]'),'PARTI')
  pool<-kd[kd$partiforkortning==a & !is.na(kd$partiforkortning),]
  if(length(unique(pool$listnummer))!=1L)stop('EU 2009 relation requires an unambiguous party ballot.',call.=FALSE)
  pool<-pool[pool$namn==.xml2018_attr(n,'NAMN'),]
  age<-.xml2018_int(n,'\u00c5LDER')
  if(!is.na(age))pool<-pool[pool$alder_pa_valdagen==age,]
  if(nrow(pool)!=1L)stop('Unresolved EU 2009 relation/qualification linkage.',call.=FALSE)
  xml2::xml_set_attr(n,'KANDNR',pool$kandidatnummer)
 }
 doc
}
.eu2009_doc <- function(zip,member,kd) {
 con<-unz(zip,member,open='rb');on.exit(close(con),add=TRUE)
 d<-xml2::read_xml(con,options=c('NONET','NOBLANKS'))
 if(.xml2018_attr(d,'VALDAG')!='20090607'||.xml2018_attr(d,'RAPPORTERING')!='SLUTLIG R\u00d6STR\u00c4KNING RESULTAT'||.xml2018_attr(d,'FILNAMN')!=member)
  stop('Unexpected EU 2009 final XML occasion/stage/member.',call.=FALSE)
 .eu2009_adapt(d,kd)
}
.eu2009_small <- function(file,register) {
 if(!requireNamespace('readxl',quietly=TRUE))stop('EU 2009 raw small-party input requires optional readxl; canonical reading does not.',call.=FALSE)
 x<-readxl::read_excel(file,col_names=FALSE,.name_repair='minimal')
 heads<-as.character(x[1,]);x<-x[-1,]; names(x)<-paste0('c',seq_len(ncol(x)))
 if(nrow(x)!=5976L||ncol(x)!=118L)stop('Incomplete EU 2009 small-party workbook.',call.=FALSE)
 # Explicit party headings from the original workbook, not inferred from counts.
 pc<-c(3L,7L,11L,12L,14L,67L,68L,70L,89L,92L,94L,114L,116L,118L)
 codes<-c('0339','0518','0520','0889','0909','0888','0848','0029','0929','0199','0243','0930','0931',NA_character_)
 cc<-setdiff(3:118,pc); party<-codes[findInterval(cc,pc)]
 code<-as.character(x$c1);width<-nchar(code);code[width==1L]<-sprintf('%02d',as.integer(code[width==1L]))
 level<-ifelse(nchar(code)==2L,ifelse(code=='00','riket','lan'),ifelse(nchar(code)<=4L,'kommun','valdistrikt'))
 code[level=='kommun']<-sprintf('%04d',as.integer(code[level=='kommun']))
 code[level=='valdistrikt']<-sprintf('%08d',as.integer(code[level=='valdistrikt']))
 rows<-lapply(seq_along(cc),function(i) {
  j<-cc[i];v<-as.integer(x[[j]])
  if(anyNA(v)||any(v<0L))stop('Missing/invalid EU 2009 reported small-party cell.',call.=FALSE)
  tibble::tibble(.geo=code,geografiniva=level,partikod=party[i],
   listnummer=NA_character_,kandidatnummer=paste0('2009:E:source-column:',j),
   antal_personroster=v,kandidatnamn_lista=heads[j])
 })
 purrr::list_rbind(rows)
}
.eu2009_bundle <- function(args) {
 files<-stats::setNames(vapply(.eu2009_sources()$role,function(r).eu2009_file(r,args$source,args$data_dir),''),.eu2009_sources()$role)
 key<-paste(files,collapse='|');if(exists(key,.eu2009_cache,inherits=FALSE))return(get(key,.eu2009_cache))
 kd<-.eu2009_candidacies(files[['candidacies']]);bd<-xml2::read_xml(files[['candidacies']])
 con<-unz(files[['final']],'slutresultat_00E.xml',open='rb');doc<-xml2::read_xml(con);close(con)
 reg<-.eu2009_register(doc,bd)
 kd$partiforkortning<-reg$data$partiforkortning[match(kd$partikod,reg$data$partikod)]
 doc<-.eu2009_adapt(doc,kd)
 members<-sort(utils::unzip(files[['final']],list=TRUE)$Name)
 members<-members[grepl('^slutresultat_[0-9]{4}E[.]xml$',members)]
 if(length(members)!=290L)stop('Incomplete EU 2009 municipal XML archive.',call.=FALSE)
 r<-ctx<-pv<-ls<-list();i<-0L
 consume<-function(node,level,d){
  i<<-i+1L;r[[i]]<<-.eu2009_retag(.eu2014_result_node(node,d,level,reg));ctx[[i]]<<-.eu2019_geo(node,level)
  if(level%in%c('riket','valdistrikt')){p<-.eu2019_preferences_node(node,reg,.xml2018_attr(node,'KOD'));pv[[i]]<<-p$votes;ls[[i]]<<-p$lists}
 }
 consume(xml2::xml_find_first(doc,'./NATION'),'riket',doc)
 for(n in xml2::xml_find_all(doc,'./NATION/L\u00c4N'))consume(n,'lan',doc)
 for(f in members){d<-.eu2009_doc(files[['final']],f,kd);consume(xml2::xml_find_first(d,'./KOMMUN'),'kommun',d)
  for(n in .xml2018_noder(d,'kommunvalkrets','E'))consume(n,'kommunvalkrets',d)
  for(n in .xml2018_noder(d,'valdistrikt','E'))consume(n,'valdistrikt',d)
 }
 result<-purrr::list_rbind(r); result<-.valresultat_public_andelar_2026(result)
 result<-.komplettera_kommunnamn_2026(result,result$kommunnamn)
 q<-xml2::xml_find_all(doc,'./NATION/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]')
 qp<-.eu2019_party(xml2::xml_find_first(q,'..'),reg)
 out<-list(result=result,context=purrr::list_rbind(ctx),votes=purrr::list_rbind(pv),lists=purrr::list_rbind(ls),
  kd=kd,small=.eu2009_small(files[['small_preferences']],reg),
  qualified=tibble::tibble(partikod=qp$partikod,kandidatnummer=xml2::xml_attr(q,'KANDNR')),
  relations=lapply(.eu2019_relations(doc,reg),.eu2009_retag),seats=.eu2009_retag(.eu2019_seats(doc,reg,'slutlig')))
 out$source_designations<-.eu2009_designations(files[['handwritten']],out$result)
 out$result$kall_roster_utan_partibeteckning<-NA_integer_
 gap<-out$source_designations[out$source_designations$kall_partibeteckning_saknas,]
 for(level in .eu2024_levels){
  ix<-which(out$result$geografiniva==level & out$result$ovriga_partier)
  code<-switch(level,riket=rep('00',length(ix)),lan=out$result$lankod[ix],kommun=out$result$kommunkod[ix],kommunvalkrets=out$result$kommunvalkretskod[ix],valdistrikt=out$result$valdistriktskod[ix])
  if(level%in%c('riket','lan','kommun')){
   gc<-switch(level,riket=rep('00',nrow(gap)),lan=substr(gap$kall_enhetskod,1,2),kommun=gap$kall_enhetskod)
   sums<-tapply(gap$antal_roster,gc,sum)
   out$result$kall_roster_utan_partibeteckning[ix]<-as.integer(dplyr::coalesce(unname(sums[code]),0L))
  }
 }
 assign(key,out,.eu2009_cache);out
}
.eu2009_preference_base <- function(bundle,level) {
 b<-.eu2019_preference_base(bundle,level)
 target<-if(level=='personvalsomrade')'riket'else level
 s<-bundle$small[bundle$small$geografiniva==target,];s$geografiniva<-NULL
 # No Wednesday small-party cells exist: never subtract inconsistent aggregates.
 # Municipal-constituency cells are likewise not published in this workbook.
 b$votes<-dplyr::bind_rows(b$votes,s)
 extra<-unique(s[c('.geo','partikod','listnummer')]);extra$antal_listroster<-rep(NA_integer_,nrow(extra))
 b$lists<-dplyr::bind_rows(b$lists,extra)
 b
}
.eu2009_preference_view <- function(base,level,kd,by_list,zeros,ids) {
 if(!zeros)base$votes<-base$votes[base$votes$antal_personroster>0L,]
 x<-.eu2024_preference_view(base,level,kd,by_list,zeros,ids,2009L)
 x<-.eu2009_retag(x)
 # No unproven column-to-ballot/person linkage. Explicit source heading gives party.
 # Candidate names for these observations come from the workbook, not ballot joins.
 small<-grepl('^2009:E:source-column:',x$kandidatnummer)
 if(any(small)) {
  reg<-unique(kd[c('partikod','partiforkortning','partibeteckning')])
  j<-match(x$partikod[small],reg$partikod)
  x$partiforkortning[small]<-reg$partiforkortning[j];x$partibeteckning[small]<-reg$partibeteckning[j]
  x$kvalificerad_personval[small]<-NA
 }
 x
}
.eu2009_read <- function(table,args) {
 if(!is.null(args$rakning)&&args$rakning!='slutlig')stop('EU 2009 has no verified complete preliminary Wednesday snapshot. Election night is provenance only.',call.=FALSE)
 level<-if(is.null(args$niva))'riket'else args$niva
 if(table%in%c('results','preference_votes')&&(length(level)!=1L||!level%in%c(.eu2024_levels,if(table=='preference_votes')'personvalsomrade')))
  stop('Unsupported EU 2009 geographic level.',call.=FALSE)
 if(table=='seats'&&!identical(level,'riket'))stop('EU seats are national only.',call.=FALSE)
 b<-.eu2009_bundle(args);kd<-b$kd
 if(table=='candidacies')return(kd)
 if(table=='results')return(b$result[b$result$geografiniva==level,c(.valresultat_public_columns_2026(level),'kall_roster_utan_partibeteckning')])
 if(table=='seats')return(b$seats)
 if(table=='substitutes') {
  x<-b$relations$ersattare
  x$ledamot_namn<-kd$namn[match(x$ledamot_kandidatnummer,kd$kandidatnummer)]
  x$ersattare_namn<-kd$namn[match(x$ersattare_kandidatnummer,kd$kandidatnummer)]
  return(x)
 }
 if(table%in%c('candidates','elected')) {
  population<-kd;population$giltig<-TRUE
  x<-.eu2009_retag(.kandidater_bas(population,2009L))
  if(!identical(args$resultat,FALSE)) {
   v<-b$votes[b$votes$.geo=='00',];j<-match(x$kandidatnummer,v$kandidatnummer)
   # Absence of a linked small-party record is unknown, never an inferred zero.
   x$antal_personroster_totalt<-v$antal_personroster[j]
   x$kvalificerad_personval<-ifelse(is.na(j),NA,paste(x$partikod,x$kandidatnummer)%in%paste(b$qualified$partikod,b$qualified$kandidatnummer))
   x$antal_personvalsomraden<-as.integer(x$kvalificerad_personval)
   x<-add_valda_to_kandidater_2026(x,b$relations$valda)
  }
  if(table=='elected'){x<-.valda_invaldsvalkrets_2026(x);x<-x[x$invald%in%TRUE,setdiff(names(x),'antal_valkretsar')]}
  return(x)
 }
 .eu2009_preference_view(.eu2009_preference_base(b,level),level,kd,args$per_lista,args$komplettera_nollor,paste(b$qualified$partikod,b$qualified$kandidatnummer))
}

.eu2009_designations <- function(file,result) {
 h<-readr::read_delim(file,delim=';',col_names=FALSE,col_types=readr::cols(.default=readr::col_character()),
  locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
 if(ncol(h)!=6L)stop('Unexpected EU 2009 handwritten layout.',call.=FALSE)
 z<-tibble::tibble(kall_enhetskod=paste0(h[[1]],sprintf('%02d',as.integer(h[[3]]))),kall_partibeteckning=h[[5]],antal_roster=as.integer(h[[6]]),kall_partibeteckning_saknas=FALSE)
 sums<-z|>dplyr::summarise(.n=sum(.data$antal_roster),.by='kall_enhetskod')
 r<-result[result$geografiniva=='kommun' & result$ovriga_partier,]
 gap<-r$antal_roster-dplyr::coalesce(sums$.n[match(r$kommunkod,sums$kall_enhetskod)],0L)
 if(any(gap<0L)||!identical(sort(gap[gap>0L]),c(1L,2L)))stop('Unexpected EU 2009 handwritten disclosure gap.',call.=FALSE)
 dplyr::bind_rows(z,tibble::tibble(kall_enhetskod=r$kommunkod[gap>0L],kall_partibeteckning=NA_character_,antal_roster=gap[gap>0L],kall_partibeteckning_saknas=TRUE))
}
