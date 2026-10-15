# European Parliament 2019: original XML snapshots, never later membership data.
.eu2019_cache <- new.env(parent = emptyenv())
.eu2019_sources <- function() data.frame(
 role=c('final','preliminary','candidacies','parties','electorate','handwritten'),
 filename=c('slutresultat.zip','prelresultat.zip','current-candidacies.skv',
 'deltagande_partier.skv','official-current-electorate.skv','handwritten-parties.xls'),
 sha256=c('85528fda705bcb56c8c9fa7c0c926f614ad210b77c3bda781459f28c328a5f4a',
 '33cf5da0f66188bef1ad613ff7ae93347de91e11ac2011243f7437f8d722498e',
 '7b2bc1b5e8cf503f27dc857a0aaa3850cc85a6655367659f94d97dad93a67940',
 '921fa17e5044b732aef3d712919f61fc71f51f5ee738ea1acf27a7f3ad8b77a8',
 '7abb80590ff70d64f4445374d1de0a3edeed2daa271725c4eb6803319e8be660',
 '8f6c61411b50913752d4f82032ad3e46a04b1797fe8dd0e2bc14b4246a3a28da'),
 url=paste0('https://historik.val.se/val/ep2019/',c('slutresultat/slutresultat.zip',
 'prelresultat/prelresultat.zip','valsedlar/partier/kandidaturer.skv',
 'valsedlar/partier/deltagande_partier.skv','alkon/E/rostberattigade.skv',
 'handskrivna/handskrivna.xls')))

# Resolve by approved content, not a developer's archive layout or newest mtime.
.eu2019_file <- function(role, source, data_dir) {
 entry <- .eu2019_sources(); entry <- entry[match(role,entry$role),]
 if (anyNA(entry)) stop('Unknown EU 2019 source role.',call.=FALSE)
 root <- val_data_dir(data_dir)
 if (source != 'remote' && !is.null(root)) {
  roots <- unique(c(file.path(root,'eu','2019'),file.path(root,'2019'),root))
  root <- roots[dir.exists(roots)][1L]
  if (!is.na(root)) {
   candidates <- list.files(root,recursive=TRUE,full.names=TRUE)
   aliases <- c(entry$filename, switch(role,candidacies='kandidaturer.skv',
       electorate='rostberattigade.skv',handwritten='handskrivna.xls',character()))
   candidates <- sort(candidates[basename(candidates)%in%aliases])
   for (f in candidates) if (.canonical_sha256(f)==entry$sha256) return(f)
  }
 }
 if (source=='local') stop('Missing approved EU 2019 source: ',entry$filename,
   '. Preserve the pinned official snapshot; older electorate files are not equivalent.',call.=FALSE)
 if (!exists(entry$url,.eu2019_cache,inherits=FALSE)) {
  f <- tempfile(fileext=paste0('.',tools::file_ext(entry$filename)))
  .download_file(entry$url,f)
  if (.canonical_sha256(f)!=entry$sha256) {
   unlink(f)
   stop('Changed EU 2019 source snapshot: ',entry$filename,call.=FALSE)
  }
  assign(entry$url,f,.eu2019_cache)
 }
 get(entry$url,.eu2019_cache,inherits=FALSE)
}

.eu2019_doc <- function(zip, member, stage) {
 con <- unz(zip,member,open='rb');on.exit(close(con),add=TRUE)
 doc <- xml2::read_xml(con,options=c('NONET','NOBLANKS'))
 expected <- if(stage=='slutlig') 'SLUTLIG R\u00d6STR\u00c4KNING RESULTAT' else 'PRELIMIN\u00c4R R\u00d6STR\u00c4KNING'
 if (.xml2018_attr(doc,'VALDAG')!='20190526' ||
     .xml2018_attr(doc,'VALTYP')!='Europaparlamentsval' ||
     .xml2018_attr(doc,'RAPPORTERING')!=expected || .xml2018_attr(doc,'FILNAMN')!=member)
  stop('Unexpected EU 2019 XML occasion/stage/member.',call.=FALSE)
 doc
}

.eu2019_candidacies <- function(file) {
 x <- readr::read_delim(file,delim=';',locale=readr::locale(encoding='Windows-1252'),
  col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE,progress=FALSE) |>
  janitor::clean_names()
 x$valkretsbeteckning_pa_valsedeln <- NA_character_
 x$anmaldakandidater <- x$anmkand
 x$folkbokforingskommun <- x$folkbokforingsort
 x$antal_valsedlar_for_den_specifika_listan <- x$ant_best_vals
 for(n in c('valomradeskod','valkretskod')) x[[n]] <- sprintf('%02d',as.integer(x[[n]]))
 x$partikod <- sprintf('%04d',as.integer(x$partikod))
 out <- parse_kandidaturer_2026(x,2019L,namnvalsedlar_kompletta=TRUE)
 if(any(out$valtyp!='E')) stop('Unexpected EU candidacy election code.',call.=FALSE)
 out$valtillfalle <- 'EU-val_2019';out$namn <- NA_character_
 out
}

.eu2019_geo <- function(node,level) {
 attr <- .xml2018_attr
 m <- xml2::xml_find_first(node,'ancestor-or-self::KOMMUN[1]')
 l <- xml2::xml_find_first(node,'ancestor-or-self::L\u00c4N[1]')
 k <- xml2::xml_find_first(node,'ancestor-or-self::KRETS_KOMMUN[1]')
 mk <- attr(m,'KOD'); lk <- attr(l,'KOD');if(is.na(lk)&&!is.na(mk))lk<-substr(mk,1,2)
 kc <- attr(k,'KOD');if(!is.na(kc)&&grepl('00$',kc))kc<-NA_character_
 tibble::tibble(.geo=attr(node,'KOD'),geografiniva=level,
  valomradeskod='00',valomradesnamn='Sverige',lankod=lk,
  lannamn=if(!is.na(lk)) .valresultat_lannamn_2026(lk) else NA_character_,
  kommunkod=mk,kommunnamn=attr(m,'NAMN'),kommunvalkretskod=kc,
  kommunvalkretsnamn=if(!is.na(kc))attr(k,'NAMN')else NA_character_,
  valdistriktskod=if(level=='valdistrikt')attr(node,'KOD')else NA_character_,
  valdistriktsnamn=if(level=='valdistrikt')attr(node,'NAMN')else NA_character_,
  valdistriktstyp=if(level=='valdistrikt')if(xml2::xml_name(node)=='ONSDAGSDISTRIKT')
    'uppsamlingsdistrikt' else 'valdistrikt' else NA_character_)
}

.eu2019_party <- function(nodes,register) {
 aliases <- xml2::xml_attr(nodes,'PARTI')
 reg <- register$data
 keys <- ifelse(is.na(reg$partiforkortning),reg$partikod,reg$partiforkortning)
 ix <- match(aliases,keys)
 if(anyNA(ix)) stop('Unidentified EU 2019 XML party: ',paste(aliases[is.na(ix)],collapse=','),call.=FALSE)
 tibble::tibble(partikod=reg$partikod[ix],partibeteckning=reg$partibeteckning[ix],
   partiforkortning=reg$partiforkortning[ix])
}

.eu2019_result_node <- function(node,doc,level,register,stage) {
 p <- xml2::xml_find_all(node,'./GILTIGA|./\u00d6VRIGA_GILTIGA/GILTIGA')
 other <- xml2::xml_find_first(node,if(stage=='slutlig')'./\u00d6VRIGA_GILTIGA/HANDSKRIVNA'else'./\u00d6VRIGA_GILTIGA')
 count <- length(p)+as.integer(!inherits(other,'xml_missing'))
 out <- .valresultat_schema()[rep(NA_integer_,count),]
 out$valtillfalle <- 'EU-val_2019';out$valtyp <- 'E';out$rakningstillfalle<-stage
 out$valdatum <- '2019-05-26';out$valdatum_fg<-'2014-05-25';out$test<-FALSE
 g <- .eu2019_geo(node,level);for(n in intersect(names(g),names(out)))out[[n]]<-g[[n]]
 a <- .xml2018_int; v <- xml2::xml_find_first(node,'./VALDELTAGANDE')
 out$senaste_uppdateringstid <- .xml2018_attr(doc,'TID_RAPPORT')
 out$rapporteringstid <- .xml2018_attr(node,'TID_RAPPORT')
 for(n in c('antal_valdistrikt_raknade','antal_valdistrikt_som_ska_raknas'))
  out[[n]] <- a(xml2::xml_find_first(doc,'./NATION|./KOMMUN'),if(n=='antal_valdistrikt_raknade')'KLARA_VALDISTRIKT'else'ALLA_VALDISTRIKT')
 out$antal_valdistrikt_raknade_omrade <- a(node,'KLARA_VALDISTRIKT')
 out$antal_valdistrikt_som_ska_raknas_omrade <- a(node,'ALLA_VALDISTRIKT')
 out$giltiga_roster <- a(node,'R\u00d6STER');out$giltiga_roster_fg <- a(node,'R\u00d6STER_FGVAL')
 out$antal_rostberattigade <- a(v,'R\u00d6STBER\u00c4TTIGADE')
 out$antal_rostberattigade_raknade <- a(v,'R\u00d6STBER\u00c4TTIGADE_KLARA_VALDISTRIKT')
 out$antal_rostberattigade_fg <- a(v,'R\u00d6STBER\u00c4TTIGADE_KLARA_VALDISTRIKT_FGVAL')
 out$totalt_antal_roster <- a(v,'SUMMA_R\u00d6STER');out$totalt_antal_roster_fg<-a(v,'SUMMA_R\u00d6STER_FGVAL')
 out$valdel_fg <- .xml2018_dbl(v,'PROCENT_FGVAL')
 inv<-xml2::xml_find_all(node,'./OGILTIGA');typ<-xml2::xml_attr(inv,'TEXT')
 for(pair in list(c('blanka_roster','BLANK'),c('roster_ej_anmalt_deltagande','OGEJ'),c('ovriga_ogiltiga','OG'))) {
  ix<-match(pair[2],typ)
  out[[pair[1]]]<-if(is.na(ix))NA_integer_ else a(inv[[ix]],'R\u00d6STER')
  out[[paste0(pair[1],'_fg')]]<-if(is.na(ix))NA_integer_ else a(inv[[ix]],'R\u00d6STER_FGVAL')
 }
 out$ogiltiga_roster<-out$blanka_roster+out$roster_ej_anmalt_deltagande+out$ovriga_ogiltiga
 out$ogiltiga_roster_fg<-out$blanka_roster_fg+out$roster_ej_anmalt_deltagande_fg+out$ovriga_ogiltiga_fg
 # Wednesday units publish no turnout node; ballot components are explicit.
 if(all(is.na(out$totalt_antal_roster)))out$totalt_antal_roster<-out$giltiga_roster+out$ogiltiga_roster
 info<-.eu2019_party(p,register)
 for(n in names(info))out[[n]][seq_along(p)]<-info[[n]]
 values<-function(field)c(xml2::xml_attr(p,field),if(!inherits(other,'xml_missing')).xml2018_attr(other,field))
 out$antal_roster<-as.integer(values('R\u00d6STER'))
 out$antal_roster_fg<-as.integer(values('R\u00d6STER_FGVAL'))
 out$andel_roster_fg<-as.numeric(sub(',', '.', values('PROCENT_FGVAL'), fixed=TRUE))
 out$ovriga_partier<-is.na(out$partikod)
 out$partibeteckning[out$ovriga_partier]<-if(stage=='slutlig')'Handskrivna r\u00f6ster'else'\u00d6vriga partier'
 out$diff_antal_roster<-out$antal_roster-out$antal_roster_fg
 out$status_jamforelse<-.xml2018_attr(node,'INDELNING')
 if(level=='valdistrikt')out$raknat<-TRUE
 if(sum(out$antal_roster)!=out$giltiga_roster[1])stop('EU XML party/valid totals disagree.',call.=FALSE)
 out
}

# Only list-level PERSONVAL is counted; the party-level view is a duplicate.
.eu2019_preferences_node <- function(node,register,geo) {
 l<-xml2::xml_find_all(node,'./GILTIGA/VALSEDEL|./GILTIGA/PARTISEDEL|./\u00d6VRIGA_GILTIGA/GILTIGA/VALSEDEL|./\u00d6VRIGA_GILTIGA/GILTIGA/PARTISEDEL')
 p<-xml2::xml_find_first(l,'..');info<-.eu2019_party(p,register)
 lists<-dplyr::mutate(info,.geo=geo,listnummer=xml2::xml_attr(l,'LISTNUMMER'),
  antal_listroster=as.integer(xml2::xml_attr(l,'R\u00d6STER')),
  .reported=as.integer(xml2::xml_attr(l,'PERSONKRYSS')))
 v<-xml2::xml_find_all(l,'./PERSONVAL')
 parent<-xml2::xml_find_first(v,'..');i<-match(xml2::xml_attr(parent,'LISTNUMMER'),lists$listnummer)
 votes<-tibble::tibble(.geo=rep(geo,length(v)),partikod=lists$partikod[i],
  listnummer=lists$listnummer[i],kandidatnummer=xml2::xml_attr(v,'KANDNR'),
  antal_personroster=as.integer(xml2::xml_attr(v,'PERSONKRYSS')),kandidatnamn_lista=rep(NA_character_,length(v)))
 sums<-votes|>dplyr::summarise(.sum=as.integer(sum(.data$antal_personroster)),.by='listnummer')
 check<-dplyr::left_join(lists,sums,by='listnummer',relationship='one-to-one')
 if(any(!is.na(check$.reported)&check$.reported!=dplyr::coalesce(check$.sum,0L))||
    anyDuplicated(votes[c('.geo','partikod','listnummer','kandidatnummer')]))
  stop('EU XML candidate/list preference totals disagree.',call.=FALSE)
 list(votes=votes,lists=lists[c('.geo','partikod','listnummer','antal_listroster')])
}

.eu2019_relations <- function(doc,register) {
 elected<-substitutes<-list();i<-0L
 for(p in xml2::xml_find_all(doc,'./NATION/GILTIGA[GRUPP_VALDA]')) {
  info<-.eu2019_party(p,register)
  for(g in xml2::xml_find_all(p,'./GRUPP_VALDA')) {
   v<-xml2::xml_find_all(g,'./VALD');s<-xml2::xml_find_all(g,'./ERS\u00c4TTARE')
   common<-tibble::tibble(valtillfalle='EU-val_2019',valar=2019L,valtyp='E',
    valklass=NA_character_,rakningstillfalle='slutlig',valdatum='2019-05-26',
    valdatum_fg='2014-05-25',test=FALSE,geografiniva='riket',
    valomradeskod='00',valomradesnamn='Sverige',valkretskod='00',valkretsnamn='Sverige',
    !!!info,ersattargrupp=.xml2018_attr(g,'ORDNING'))
   i<-i+1L
   elected[[i]]<-dplyr::mutate(common[rep(1L,length(v)),],kandidatnummer=xml2::xml_attr(v,'KANDNR'),
    namn=NA_character_,invalsordning=as.integer(xml2::xml_attr(v,'ORDNING')),
    valgrund_id=xml2::xml_attr(v,'GRUND'),valgrund_text=NA_character_)
   vi<-rep(seq_along(v),each=length(s));si<-rep(seq_along(s),times=length(v))
   substitutes[[i]]<-dplyr::mutate(common[rep(1L,length(vi)),],
    ledamot_kandidatnummer=xml2::xml_attr(v,'KANDNR')[vi],ledamot_namn=NA_character_,
    ersattare_kandidatnummer=xml2::xml_attr(s,'KANDNR')[si],ersattare_namn=NA_character_,
    ersattarordning=as.integer(xml2::xml_attr(s,'ORDNING')[si]),
    valgrund_id=NA_character_,valgrund_text=NA_character_)
  }
  if(length(xml2::xml_find_all(p,'./GRUPP_VALDA/VALD'))!=.xml2018_int(p,'MANDAT'))
   stop('EU original elected/allocated counts disagree.',call.=FALSE)
 }
 list(valda=purrr::list_rbind(elected),ersattare=purrr::list_rbind(substitutes))
}

.eu2019_seats <- function(doc,register,stage) {
 n<-xml2::xml_find_first(doc,'./NATION');p<-xml2::xml_find_all(n,'./GILTIGA[@MANDAT]')
 if(!length(p))stop('EU 2019 source has no mandate allocation for this count stage.',call.=FALSE)
 out<-.mandat_schema_2026()[rep(NA_integer_,length(p)),]
 out$valtillfalle<-'EU-val_2019';out$valtyp<-'E';out$rakningstillfalle<-stage
 out$valdatum<-'2019-05-26';out$valdatum_fg<-'2014-05-25'
 out$geografiniva<-'riket';out$valomradeskod<-'00';out$valomradesnamn<-'Sverige'
 out$senaste_uppdateringstid<-.xml2018_attr(doc,'TID_RAPPORT')
 info<-.eu2019_party(p,register);for(k in names(info))out[[k]]<-info[[k]]
 out$antal_mandat<-as.integer(xml2::xml_attr(p,'MANDAT'))
 out$antal_mandat_fg<-as.integer(xml2::xml_attr(p,'MANDAT_FGVAL'))
 out$diff_antal_mandat<-as.integer(xml2::xml_attr(p,'MANDAT_\u00c4NDRING'))
 out$totalt_antal_mandat<-.xml2018_int(n,'MANDAT_VALOMR\u00c5DE')
 out$antal_tomma_stolar<-if(stage=='slutlig')vapply(p,function(x)
  .xml2018_int(x,'MANDAT')-length(xml2::xml_find_all(x,'./GRUPP_VALDA/VALD')),0L)else rep(NA_integer_,length(p))
 .mandat_public_2026(out,2019L)
}

.eu2019_bundle <- function(args,stage='slutlig') {
 role<-if(stage=='slutlig')'final'else'preliminary'
 zip<-.eu2019_file(role,args$source,args$data_dir)
 key<-paste(normalizePath(zip,winslash='/'),file.info(zip)$mtime,stage)
 if(exists(key,.eu2019_cache,inherits=FALSE))return(get(key,.eu2019_cache))
 register<-.xml2018_partiregister(.eu2019_file('parties',args$source,args$data_dir))
 prefix<-if(stage=='slutlig')'slutresultat'else'prelresultat'
 members<-sort(utils::unzip(zip,list=TRUE)$Name)
 municipal<-members[grepl(paste0('^',prefix,'_[0-9]{4}E[.]xml$'),members)]
 if(length(municipal)!=290L||anyDuplicated(municipal))stop('Incomplete EU 2019 XML municipal archive.',call.=FALSE)
 doc<-.eu2019_doc(zip,paste0(prefix,'_00E.xml'),stage)
 r<-ctx<-pv<-ls<-list();index<-0L
 consume<-function(node,level,document) {
  index<<-index+1L
  r[[index]]<<-.eu2019_result_node(node,document,level,register,stage)
  ctx[[index]]<<-.eu2019_geo(node,level)
  if(stage=='slutlig'&&level%in%c('riket','valdistrikt')) {
   b<-.eu2019_preferences_node(node,register,.xml2018_attr(node,'KOD'))
   pv[[index]]<<-b$votes;ls[[index]]<<-b$lists
  }
 }
 consume(xml2::xml_find_first(doc,'./NATION'),'riket',doc)
 for(n in xml2::xml_find_all(doc,'./NATION/L\u00c4N'))consume(n,'lan',doc)
 # Municipality roots supply full context; country summary has no district data.
 for(f in municipal) {
  d<-.eu2019_doc(zip,f,stage)
  consume(xml2::xml_find_first(d,'./KOMMUN'),'kommun',d)
  for(n in .xml2018_noder(d,'kommunvalkrets','E'))consume(n,'kommunvalkrets',d)
  for(n in .xml2018_noder(d,'valdistrikt','E'))consume(n,'valdistrikt',d)
 }
 context<-purrr::list_rbind(ctx);result<-purrr::list_rbind(r)
 if(stage=='slutlig') {
  if(!requireNamespace('readxl',quietly=TRUE))stop('EU 2019 raw handwritten-party input requires optional package readxl; canonical reading does not.',call.=FALSE)
  h<-readxl::read_excel(.eu2019_file('handwritten',args$source,args$data_dir),.name_repair='unique_quiet')
  mk<-paste0(sprintf('%02d',h$LAN),sprintf('%02d',h$KOM))
  ordinary<-paste0(mk,sprintf('%04d',h$DISTRIKT))
  h$.geo<-ifelse(ordinary%in%context$valdistriktskod,ordinary,paste0('E-',mk,'-',sprintf('%02d',h$DISTRIKT)))
  reg<-unique(register$data[c('partibeteckning','partikod','partiforkortning')])
  h<-dplyr::left_join(h,reg,by=c('PARTIBETECKNING'='partibeteckning'),relationship='many-to-one')
  if(anyNA(h$partikod))stop('Unidentified handwritten-party label.',call.=FALSE)
  dc<-context[context$geografiniva=='valdistrikt',]
  if(!all(h$.geo%in%dc$.geo))stop('Unknown handwritten source district.',call.=FALSE)
  parts<-lapply(.eu2024_levels,function(level) {
   z<-dplyr::left_join(h,dc[c('.geo','lankod','kommunkod','kommunvalkretskod')],by='.geo',relationship='many-to-one')
   z$.code<-switch(level,riket=rep('00',nrow(z)),lan=z$lankod,kommun=z$kommunkod,
     kommunvalkrets=z$kommunvalkretskod,valdistrikt=z$.geo)
   z<-z[!is.na(z$.code),]
   totals<-z|>dplyr::summarise(antal_roster=as.integer(sum(.data$ANTAL)),
     .by=c('.code','partikod','PARTIBETECKNING','partiforkortning'))
   rr<-result[result$geografiniva==level,]
   rr$.code<-switch(level,riket=rep('00',nrow(rr)),lan=rr$lankod,kommun=rr$kommunkod,
     kommunvalkrets=rr$kommunvalkretskod,valdistrikt=rr$valdistriktskod)
   residual<-rr[rr$ovriga_partier,]
   sums<-totals|>dplyr::summarise(.sum=sum(.data$antal_roster),.by='.code')
   ch<-dplyr::left_join(residual,sums,by='.code')
   if(any(ch$antal_roster!=dplyr::coalesce(ch$.sum,0L)))stop('Handwritten supplement disagrees with XML residual.',call.=FALSE)
   # Replace the residual, retaining source totals and metadata.
   add<-dplyr::inner_join(totals,residual[setdiff(names(residual),c('partikod','partibeteckning','partiforkortning','antal_roster'))],by='.code',relationship='many-to-one')
   add$partibeteckning<-add$PARTIBETECKNING;add$PARTIBETECKNING<-NULL
   add$ovriga_partier<-FALSE
   for(n in c('antal_roster_fg','andel_roster_fg','diff_antal_roster'))add[[n]]<-NA
   out<-dplyr::bind_rows(rr[!rr$ovriga_partier,],add);out$.code<-NULL;out
  })
  result<-purrr::list_rbind(parts)
  # Fresh official electorate is an independent, exact district control.
  ef<-readr::read_delim(.eu2019_file('electorate',args$source,args$data_dir),delim=';',
   locale=readr::locale(encoding='Windows-1252'),col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE,progress=FALSE)
  ec<-sprintf('%08d',as.integer(ef$valdistrikt_id));ev<-rowSums(as.matrix(sapply(ef[9:28],as.integer)))
  er<-unique(result[result$geografiniva=='valdistrikt',c('valdistriktskod','antal_rostberattigade')])
  j<-match(ec,er$valdistriktskod)
  if(length(ec)!=5984L||anyNA(j)||any(ev!=er$antal_rostberattigade[j]))stop('EU 2019 electorate snapshot disagrees with final XML.',call.=FALSE)
 }
 result$valar<-2019L
 result<-.komplettera_kommunnamn_2026(result,result$kommunnamn)
 result<-.valresultat_public_andelar_2026(result)
 out<-list(result=result,context=context,votes=purrr::list_rbind(pv),lists=purrr::list_rbind(ls))
 if(stage=='slutlig') {
  out$relations<-.eu2019_relations(doc,register)
  q<-xml2::xml_find_all(doc,'./NATION/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]|./NATION/\u00d6VRIGA_GILTIGA/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]')
  qp<-.eu2019_party(xml2::xml_find_first(q,'..'),register)
  out$qualified<-tibble::tibble(partikod=qp$partikod,kandidatnummer=xml2::xml_attr(q,'KANDNR'))
 }
 # Some preliminary XMLs do not publish mandates; never infer an allocation.
 if(length(xml2::xml_find_all(doc,'./NATION/GILTIGA[@MANDAT]')))
  out$seats<-.eu2019_seats(doc,register,stage)
 assign(key,out,.eu2019_cache);out
}

.eu2019_preference_base <- function(bundle,level) {
 target<-if(level=='personvalsomrade')'riket'else level
 ctx<-bundle$context[bundle$context$geografiniva==target,]
 if(target=='riket') {
  votes<-bundle$votes[bundle$votes$.geo=='00',];lists<-bundle$lists[bundle$lists$.geo=='00',]
 } else {
  dc<-bundle$context[bundle$context$geografiniva=='valdistrikt',]
  map<-switch(target,valdistrikt=dc$.geo,kommun=dc$kommunkod,lan=dc$lankod,kommunvalkrets=dc$kommunvalkretskod)
  recode<-function(x) {
   x<-x[x$.geo!='00',];x$.geo<-map[match(x$.geo,dc$.geo)];x[!is.na(x$.geo),]
  }
  votes<-recode(bundle$votes);lists<-recode(bundle$lists)
  votes<-votes|>dplyr::summarise(antal_personroster=as.integer(sum(.data$antal_personroster)),
   .by=c('.geo','partikod','listnummer','kandidatnummer'))
  votes$kandidatnamn_lista<-NA_character_
  lists<-lists|>dplyr::summarise(antal_listroster=as.integer(sum(.data$antal_listroster)),
   .by=c('.geo','partikod','listnummer'))
 }
 rr<-bundle$result[bundle$result$geografiniva==target,]
 geo<-switch(target,riket=rep('00',nrow(rr)),lan=rr$lankod,kommun=rr$kommunkod,
  kommunvalkrets=rr$kommunvalkretskod,valdistrikt=rr$valdistriktskod)
 parties<-tibble::tibble(.geo=geo,partikod=rr$partikod,antal_partiroster=rr$antal_roster)
 # Do not duplicate level/area fields inserted by the common public view.
 ctx<-ctx[setdiff(names(ctx),c('geografiniva','valomradeskod','valomradesnamn'))]
 list(votes=votes,lists=lists,parties=parties,context=ctx)
}

.eu2019_candidates <- function(kd,bundle,include_results=TRUE) {
 out<-.kandidater_bas(kd,2019L)
 if(!include_results)return(out)
 base<-.eu2019_preference_base(bundle,'personvalsomrade')
 pref<-.eu2024_preference_view(base,'personvalsomrade',kd,FALSE,FALSE,
  paste(bundle$qualified$partikod,bundle$qualified$kandidatnummer),2019L)
 totals<-pref[c('kandidatnummer','partikod','antal_personroster','kvalificerad_personval')]
 out<-dplyr::left_join(out,totals,by=c('kandidatnummer','partikod'),relationship='one-to-one')
 out$antal_personroster_totalt<-dplyr::coalesce(out$antal_personroster,0L);out$antal_personroster<-NULL
 out$kvalificerad_personval<-dplyr::coalesce(out$kvalificerad_personval,FALSE)
 out$antal_personvalsomraden<-as.integer(out$kvalificerad_personval)
 add_valda_to_kandidater_2026(out,bundle$relations$valda)
}

.eu2019_read <- function(table,args) {
 kd<-if(table%in%c('candidacies','candidates','elected','preference_votes'))
  .eu2019_candidacies(.eu2019_file('candidacies',args$source,args$data_dir))else NULL
 if(table=='candidacies')return(kd)
 if(table=='candidates'&&identical(args$resultat,FALSE))return(.kandidater_bas(kd,2019L))
 stage<-if(is.null(args$rakning))'slutlig'else args$rakning
 level<-if(is.null(args$niva))'riket'else args$niva
 if(table%in%c('results','preference_votes') && (length(level)!=1L||!level%in%c(.eu2024_levels,if(table=='preference_votes')'personvalsomrade')))
  stop('Unsupported EU geographic level.',call.=FALSE)
 if(table=='seats'&&!identical(level,'riket'))stop('EU seats are national only.',call.=FALSE)
 b<-.eu2019_bundle(args,stage)
 if(table=='results')return(b$result[b$result$geografiniva==level,.valresultat_public_columns_2026(level)])
 if(table=='seats') {
  if(is.null(b$seats))stop('Official EU 2019 preliminary XML does not report a mandate allocation.',call.=FALSE)
  return(b$seats)
 }
 if(table=='substitutes')return(b$relations$ersattare)
 if(table%in%c('candidates','elected')) {
  out<-.eu2019_candidates(kd,b,!identical(args$resultat,FALSE))
  if(table=='elected') {
   out<-.valda_invaldsvalkrets_2026(out)
   out<-out[out$invald%in%TRUE,setdiff(names(out),'antal_valkretsar')]
  }
  return(out)
 }
 .eu2024_preference_view(.eu2019_preference_base(b,level),level,kd,args$per_lista,
  args$komplettera_nollor,paste(b$qualified$partikod,b$qualified$kandidatnummer),2019L)
}
