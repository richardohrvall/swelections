# EU 2014: preserved original final XML, never redacted geographic metadata.
.eu2014_cache <- new.env(parent = emptyenv())
.eu2014_sources <- function() data.frame(
 role=c('final','candidacies','electorate','handwritten'),
 filename=c('slutresultat.zip','alkandur_E.skv','rostberattigade.skv','handskrivna.skv'),
 sha256=c('2a90980165237c018cf5d8e56031de6e8a01ce605756d0f90ca622b7746c2cb5',
 '6a647ecbe3835625aab0c0dd247b59c6b20ae290244235552e2d0cd6e7d64e61',
 '8893d5e5d451352af6d361614694521a24ae2f63375294dd54452f0b190d8731',
 'df28696b65c7d2e47eb02b0fac5bf2820b07a1900dc35d5df200203fd7196dc0'),
 url=paste0('https://historik.val.se/val/ep2014/',c('slutresultat/slutresultat.zip',
 'alkon/alkandur_E.skv','alkon/E/rostberattigade.skv','handskrivna/handskrivna.skv')))

.eu2014_file <- function(role, source, data_dir) {
 entry <- .eu2014_sources();entry <- entry[match(role,entry$role),]
 if(nrow(entry)!=1L||anyNA(entry))stop('Unknown EU 2014 source role.',call.=FALSE)
 if(source=='remote')stop('EU 2014 requires preserved original local sources: current final XML redacts geographic names. Use local or a configured canonical build.',call.=FALSE)
 root <- val_data_dir(data_dir)
 roots <- if(is.null(root))character()else unique(c(file.path(root,'eu','2014'),file.path(root,'2014'),root))
 roots <- roots[dir.exists(roots)]
 if(length(roots)) {
  files <- sort(list.files(roots[1L],recursive=TRUE,full.names=TRUE))
  files <- files[basename(files)==entry$filename]
  for(f in files)if(.canonical_sha256(f)==entry$sha256)return(f)
 }
 stop('Missing approved original EU 2014 source: ',entry$filename,call.=FALSE)
}

.eu2014_doc <- function(zip,member) {
 con<-unz(zip,member,open='rb');on.exit(close(con),add=TRUE)
 doc<-xml2::read_xml(con,options=c('NONET','NOBLANKS'))
 if(.xml2018_attr(doc,'VALDAG')!='20140525'||
    .xml2018_attr(doc,'RAPPORTERING')!='SLUTLIG R\u00d6STR\u00c4KNING RESULTAT'||
    .xml2018_attr(doc,'VALTYP')!='Europaparlamentsval'||.xml2018_attr(doc,'FILNAMN')!=member)
  stop('Unexpected original EU 2014 XML occasion/stage/member.',call.=FALSE)
 doc
}

.eu2014_register <- function(doc) {
 nodes<-xml2::xml_find_all(doc,'./PARTI')
 lists<-xml2::xml_find_all(doc,'.//VALSEDEL | .//PARTISEDEL')
 alias<-xml2::xml_attr(xml2::xml_find_first(lists,'..'),'PARTI')
 codes<-substr(xml2::xml_attr(lists,'LISTNUMMER'),1L,4L)
 rows<-lapply(nodes,function(n){
  a<-.xml2018_attr(n,'F\u00d6RKORTNING')
  if(a%in%c('BLANK','OG'))return(NULL)
  code<-unique(codes[alias==a]);code<-code[!is.na(code)]
  if(length(code)>1L)stop('Ambiguous EU 2014 party identifier.',call.=FALSE)
  # Zero-vote Socialisterna has a source alias but no numeric code/list here.
  tibble::tibble(valtyp='E',valomradeskod='00',partiforkortning=a,
   partibeteckning=.xml2018_attr(n,'BETECKNING'),partikod=if(length(code))code else NA_character_)
 })
 .xml2018_reg_index(purrr::list_rbind(rows))
}

.eu2014_candidacies <- function(file,register,doc) {
 x<-readr::read_delim(file,delim=';',col_names=FALSE,
  col_types=readr::cols(.default=readr::col_character()),
  locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
 if(ncol(x)!=12L||any(x[[1]]!='E'))stop('Unexpected EU 2014 candidacy layout.',call.=FALSE)
 ls<-xml2::xml_find_all(doc,'.//VALSEDEL')
 map<-unique(data.frame(list=xml2::xml_attr(ls,'LISTNUMMER'),
  alias=xml2::xml_attr(xml2::xml_find_first(ls,'..'),'PARTI')))
 map$code<-substr(map$list,1,4);map$list<-sub('^[^-]+-','',map$list)
 if(anyDuplicated(map$list))stop('Ambiguous EU 2014 ballot number.',call.=FALSE)
 pk<-map$code[match(sprintf('%05d',as.integer(x[[6]])),map$list)]
 if(anyNA(pk))stop('EU 2014 ballot absent from original final XML.',call.=FALSE)
 reg<-register$data
 raw<-tibble::tibble(valtyp='E',valomradeskod='00',valomradesnamn='Sverige',
  valkretskod='00',valkretsnamn='Sverige',partikod=pk,
  partibeteckning=x[[4]],partiforkortning=reg$partiforkortning[match(pk,reg$partikod)],
  valsedelsstatus=ifelse(x[[5]]=='Skickad','S','B'),
  listnummer=sprintf('%05d',as.integer(x[[6]])),ordning=x[[7]],
  kandidatnummer=x[[8]],namn=NA_character_,alder_pa_valdagen=x[[10]],kon=x[[11]],
  valsedelsuppgift=x[[12]],giltig=NA_character_,anmaldakandidater=NA_character_,
  samtycke=NA_character_,forklaring=NA_character_,folkbokforingskommun=NA_character_,
  valkretsbeteckning_pa_valsedeln=NA_character_,antal_valsedlar_for_den_specifika_listan=NA_character_)
 out<-parse_kandidaturer_2026(raw,2014L);out$valtillfalle<-'EU-val_2014';out
}

.eu2014_retag <- function(x) {
 x$valtillfalle<-rep('EU-val_2014',nrow(x));x$valar<-rep(2014L,nrow(x))
 if('valdatum'%in%names(x))x$valdatum<-rep('2014-05-25',nrow(x))
 if('valdatum_fg'%in%names(x))x$valdatum_fg<-rep('2009-06-07',nrow(x))
 x
}

.eu2014_result_node <- function(node,doc,level,register) {
 out<-.eu2019_result_node(node,doc,level,register,'slutlig')
 inv<-xml2::xml_find_all(node,'./OGILTIGA')
 out$ogiltiga_roster<-sum(as.integer(xml2::xml_attr(inv,'R\u00d6STER')))
 previous<-as.integer(xml2::xml_attr(inv,'R\u00d6STER_FGVAL'))
 out$ogiltiga_roster_fg<-if(anyNA(previous))NA_integer_ else sum(previous)
 if(all(is.na(out$totalt_antal_roster)))out$totalt_antal_roster<-out$giltiga_roster+out$ogiltiga_roster
 # Missing numeric code is not the same as an aggregated other-party category.
 out$ovriga_partier<-rep(FALSE,nrow(out))
 other<-xml2::xml_find_first(node,'./\u00d6VRIGA_GILTIGA/HANDSKRIVNA')
 if(!inherits(other,'xml_missing')){
  i<-nrow(out);out$ovriga_partier[i]<-TRUE
  out$partibeteckning[i]<-'Handskrivna r\u00f6ster'
 }
 zero<-which(is.na(out$partikod)&!out$ovriga_partier)
 if(length(zero)) {
  p<-xml2::xml_find_all(node,'./GILTIGA | ./\u00d6VRIGA_GILTIGA/GILTIGA')
  info<-.eu2019_party(p,register);out$partibeteckning[zero]<-info$partibeteckning[zero]
 }
 .eu2014_retag(out)
}

# Exact reported labels, not an inferred political-party or person register.
.eu2014_source_designations <- function(file,context,residual) {
 h<-readr::read_delim(file,delim=';',locale=readr::locale(encoding='Windows-1252'),
  col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE,progress=FALSE)
 mk<-paste0(h$LAN,h$KOM)
 h$.geo<-ifelse(h$NAMN_DISTRIKT=='Uppsamlingsdistrikt',
  paste0('E-',mk,'-',sprintf('%02d',as.integer(h$DISTRIKT))),
  paste0(mk,sprintf('%04d',as.integer(h$DISTRIKT))))
 dc<-context[context$geografiniva=='valdistrikt',]
 if(!all(h$.geo%in%dc$.geo))stop('Unknown EU 2014 handwritten source unit.',call.=FALSE)
 labels<-h|>dplyr::summarise(antal_roster=as.integer(sum(as.integer(.data$ANTAL))),
  .by=c('.geo','PARTIBETECKNING'))
 sums<-labels|>dplyr::summarise(.sum=sum(.data$antal_roster),.by='.geo')
 check<-dplyr::left_join(residual,sums,by=c('valdistriktskod'='.geo'))
 check$.missing<-check$antal_roster-dplyr::coalesce(check$.sum,0L)
 gap<-check[check$.missing!=0,]
 if(nrow(gap)!=1L||gap$valdistriktskod!='05803201'||gap$.missing!=10L)
  stop('Unexpected EU 2014 handwritten disclosure gap.',call.=FALSE)
 names(labels)[names(labels)=='PARTIBETECKNING']<-'kall_partibeteckning'
 labels$kall_enhetskod<-labels$.geo;labels$.geo<-NULL
 labels$kall_partibeteckning_saknas<-FALSE
 dplyr::bind_rows(labels,tibble::tibble(kall_enhetskod='05803201',
  kall_partibeteckning=NA_character_,antal_roster=10L,kall_partibeteckning_saknas=TRUE))
}

.eu2014_bundle <- function(args) {
 zip<-.eu2014_file('final',args$source,args$data_dir)
 key<-paste(normalizePath(zip,winslash='/'),file.info(zip)$mtime)
 if(exists(key,.eu2014_cache,inherits=FALSE))return(get(key,.eu2014_cache))
 members<-sort(utils::unzip(zip,list=TRUE)$Name)
 municipal<-members[grepl('^slutresultat_[0-9]{4}E[.]xml$',members)]
 if(length(municipal)!=290L||anyDuplicated(municipal))stop('Incomplete original EU 2014 archive.',call.=FALSE)
 doc<-.eu2014_doc(zip,'slutresultat_00E.xml');reg<-.eu2014_register(doc)
 r<-ctx<-pv<-ls<-list();i<-0L
 consume<-function(node,level,d){
  i<<-i+1L;r[[i]]<<-.eu2014_result_node(node,d,level,reg)
  ctx[[i]]<<-.eu2019_geo(node,level)
  if(level%in%c('riket','valdistrikt')){
   p<-.eu2019_preferences_node(node,reg,.xml2018_attr(node,'KOD'))
   pv[[i]]<<-p$votes;ls[[i]]<<-p$lists
  }
 }
 consume(xml2::xml_find_first(doc,'./NATION'),'riket',doc)
 for(n in xml2::xml_find_all(doc,'./NATION/L\u00c4N'))consume(n,'lan',doc)
 for(f in municipal){
  d<-.eu2014_doc(zip,f);consume(xml2::xml_find_first(d,'./KOMMUN'),'kommun',d)
  for(n in .xml2018_noder(d,'kommunvalkrets','E'))consume(n,'kommunvalkrets',d)
  for(n in .xml2018_noder(d,'valdistrikt','E'))consume(n,'valdistrikt',d)
 }
 result<-purrr::list_rbind(r);context<-purrr::list_rbind(ctx)
 result<-.komplettera_kommunnamn_2026(result,result$kommunnamn)
 result<-.valresultat_public_andelar_2026(result)
 q<-xml2::xml_find_all(doc,'./NATION/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]|./NATION/\u00d6VRIGA_GILTIGA/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]')
 qp<-.eu2019_party(xml2::xml_find_first(q,'..'),reg)
 out<-list(result=result,context=context,votes=purrr::list_rbind(pv),lists=purrr::list_rbind(ls),
  relations=lapply(.eu2019_relations(doc,reg),.eu2014_retag),
  seats=.eu2014_retag(.eu2019_seats(doc,reg,'slutlig')),
  qualified=tibble::tibble(partikod=qp$partikod,kandidatnummer=xml2::xml_attr(q,'KANDNR')))
 out$source_designations<-.eu2014_source_designations(.eu2014_file('handwritten',args$source,args$data_dir),
  context,result[result$geografiniva=='valdistrikt'&result$ovriga_partier,])
 # Full-only disclosure metadata; never add these counts to the vote rows.
 gap <- out$source_designations[out$source_designations$kall_partibeteckning_saknas,]
 dc <- context[context$geografiniva=='valdistrikt',]
 geo <- dc[match(gap$kall_enhetskod,dc$.geo),]
 out$result$kall_roster_utan_partibeteckning <- NA_integer_
 for(level in .eu2024_levels){
  code <- switch(level,riket='00',lan=geo$lankod,kommun=geo$kommunkod,kommunvalkrets=geo$kommunvalkretskod,valdistrikt=geo$.geo)
  rr <- out$result
  rc <- switch(level,riket=rep('00',nrow(rr)),lan=rr$lankod,kommun=rr$kommunkod,kommunvalkrets=rr$kommunvalkretskod,valdistrikt=rr$valdistriktskod)
  ix <- which(rr$geografiniva==level & rr$ovriga_partier)
  sums <- tibble::tibble(code=code,votes=gap$antal_roster)|>dplyr::summarise(votes=as.integer(sum(.data$votes)),.by='code')
  out$result$kall_roster_utan_partibeteckning[ix] <- dplyr::coalesce(sums$votes[match(rc[ix],sums$code)],0L)
 }
 assign(key,out,.eu2014_cache);out
}

.eu2014_read <- function(table,args) {
 if(!is.null(args$rakning)&&args$rakning!='slutlig')
  stop('EU 2014 has no recovered complete preliminary Wednesday snapshot. Election-night ordinary districts are provenance only, not a full preliminary result.',call.=FALSE)
 level<-if(is.null(args$niva))'riket'else args$niva
 if(table%in%c('results','preference_votes')&&
    (length(level)!=1L||!level%in%c(.eu2024_levels,if(table=='preference_votes')'personvalsomrade')))
  stop('Unsupported EU geographic level.',call.=FALSE)
 if(table=='seats'&&!identical(level,'riket'))stop('EU seats are national only.',call.=FALSE)
 if(table%in%c('candidacies','candidates','elected','preference_votes')){
  zip<-.eu2014_file('final',args$source,args$data_dir);doc<-.eu2014_doc(zip,'slutresultat_00E.xml')
  kd<-.eu2014_candidacies(.eu2014_file('candidacies',args$source,args$data_dir),.eu2014_register(doc),doc)
  if(table=='candidacies')return(kd)
  # Internal inclusion flag, as for historical RKL: not a claimed source attribute.
  population<-kd;population$giltig<-TRUE
  if(table=='candidates'&&identical(args$resultat,FALSE))return(.eu2014_retag(.kandidater_bas(population,2014L)))
 }
 b<-.eu2014_bundle(args)
 if(table=='results')return(b$result[b$result$geografiniva==level,c(.valresultat_public_columns_2026(level),'kall_roster_utan_partibeteckning')])
 if(table=='seats')return(b$seats)
 if(table=='substitutes')return(b$relations$ersattare)
 if(table%in%c('candidates','elected')){
  out<-.eu2014_retag(.eu2019_candidates(population,b,!identical(args$resultat,FALSE)))
  if(table=='elected'){
   out<-.valda_invaldsvalkrets_2026(out)
   out<-out[out$invald%in%TRUE,setdiff(names(out),'antal_valkretsar')]
  }
  return(out)
 }
 .eu2024_preference_view(.eu2019_preference_base(b,level),level,kd,args$per_lista,
  args$komplettera_nollor,paste(b$qualified$partikod,b$qualified$kandidatnummer),2014L)
}


.eu2014_preference_base <- function(bundle, level) .eu2019_preference_base(bundle, level)
