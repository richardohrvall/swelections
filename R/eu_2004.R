# EU 2004: preserved official result and ballot/list-position observations.
.eu2004_cache <- new.env(parent = emptyenv())
.eu2004_key <- function(list, position) if(length(list)) paste0('2004:E:ballot:',list,':',position) else character()
.eu2004_retag <- function(x) {
 x$valtillfalle<-rep('EU-val_2004',nrow(x));x$valar<-rep(2004L,nrow(x))
 if('valdatum'%in%names(x))x$valdatum<-rep('2004-06-13',nrow(x))
 if('valdatum_fg'%in%names(x))x$valdatum_fg<-rep('1999-06-13',nrow(x))
 x
}
.eu2004_file <- function(role,source,data_dir) {
 .auto_requires_local(source, "EU 2004 raw data")
 e<-.eu2004_sources();e<-e[match(role,e$role),]
 if(nrow(e)!=1L||anyNA(e$sha256))stop('Unknown EU 2004 source role.',call.=FALSE)
 if(source=='remote')stop('EU 2004 requires pinned preserved original sources. Use local or a configured canonical build.',call.=FALSE)
 root<-val_data_dir(data_dir);roots<-if(is.null(root))character()else unique(c(file.path(root,'eu','2004'),file.path(root,'2004'),root))
 roots<-roots[dir.exists(roots)]
 if(length(roots)) {
  index_key<-paste0('source-index:',normalizePath(roots[1L],winslash='/'))
  if(!exists(index_key,.eu2004_cache,inherits=FALSE))assign(index_key,sort(list.files(roots[1L],recursive=TRUE,full.names=TRUE)),.eu2004_cache)
  candidates<-get(index_key,.eu2004_cache,inherits=FALSE);candidates<-candidates[basename(candidates)==e$filename]
  if(!length(candidates)){all<-sort(list.files(roots[1L],recursive=TRUE,full.names=TRUE));assign(index_key,all,.eu2004_cache);candidates<-all[basename(all)==e$filename]}
  for(f in candidates) {
   stamp<-file.info(f)[c('size','mtime')];verified_key<-paste0('verified:',f)
   if(exists(verified_key,.eu2004_cache,inherits=FALSE)&&identical(get(verified_key,.eu2004_cache,inherits=FALSE),stamp))return(f)
   if(.canonical_sha256(f)==e$sha256){assign(verified_key,stamp,.eu2004_cache);return(f)}
  }
 }
 stop('Missing approved EU 2004 source: ',e$filename,call.=FALSE)
}
.eu2004_candidacies <- function(file) {
 con<-unz(file,'00E.xml',open='rb');on.exit(close(con),add=TRUE)
 d<-xml2::read_xml(con,options=c('NONET','NOBLANKS'))
 n<-xml2::xml_find_all(d,'//VALSEDEL/KANDIDATER/KANDIDAT')
 l<-xml2::xml_find_first(n,'ancestor::VALSEDEL[1]');p<-xml2::xml_find_first(n,'ancestor::PARTI[1]')
 raw<-.xml2006_candidacy_raw(length(n))
 raw$valtyp<-'E';raw$valomradeskod<-'00';raw$valomradesnamn<-'Sverige';raw$valkretskod<-'00';raw$valkretsnamn<-'Sverige'
 raw$partikod<-xml2::xml_attr(p,'KOD');raw$partibeteckning<-xml2::xml_attr(p,'BETECKNING')
 raw$listnummer<-xml2::xml_attr(l,'LISTNUMMER');raw$ordning<-xml2::xml_text(xml2::xml_find_first(n,'./ORDNINGSNUMMER'))
 raw$kandidatnummer<-.eu2004_key(raw$listnummer,raw$ordning)
 raw$valsedelsuppgift<-xml2::xml_text(xml2::xml_find_first(n,'./KANDIDATUPPGIFT'))
 raw$namn<-trimws(sub(',.*$','',raw$valsedelsuppgift))
 raw$kon<-xml2::xml_text(xml2::xml_find_first(n,'./K\u00d6N'))
 raw$alder_pa_valdagen<-xml2::xml_text(xml2::xml_find_first(n,'./\u00c5LDER'))
 out<-.eu2004_retag(parse_kandidaturer_2026(raw,2004L))
 out$valsedelsstatus<-xml2::xml_attr(l,'STATUS');out$anmalda_kandidater<-xml2::xml_attr(l,'KANDIDATANM\u00c4LAN')=='Ja'
 out
}
# Strict, non-name identity: source ballot number and position only.
.eu2004_text <- function(file,preference=FALSE) {
 x<-readr::read_delim(file,delim=';',col_names=FALSE,col_types=readr::cols(.default=readr::col_character()),locale=readr::locale(encoding='Windows-1252'),show_col_types=FALSE,progress=FALSE)
 if(ncol(x)!=13L)stop('Unexpected EU 2004 district text layout.',call.=FALSE)
 names(x)<-c('alias','county','municipal_suffix','branch','district','county_name','municipality_name','branch_name','district_name',
  if(preference)c('list','name','position','preferences')else c('eligible','list','votes','preferences'))
 x$municipality<-paste0(x$county,x$municipal_suffix)
 x$.geo<-ifelse(grepl('^E',x$district),paste0('E-',x$municipality,'-',x$branch),paste0(x$municipality,x$district))
 for(n in intersect(c('votes','preferences','eligible','position'),names(x))) {
  v<-suppressWarnings(as.integer(x[[n]]));if(anyNA(v)||any(v<0L))stop('Invalid EU 2004 source count/position.',call.=FALSE);x[[n]]<-v
 }
 x
}
.eu2004_result_node <- function(node,doc,level,register, schema = .valresultat_schema()) {
 x<-.eu2004_retag(.eu2014_result_node(node,doc,level,register,schema))
 # The official final presentation defines this residual as handwritten votes
 # for parties which did not order ballots; no individual designation is given.
 x$partibeteckning[x$ovriga_partier]<-'\u00d6vriga partier'
 x
}
.eu2004_bundle <- function(args) {
 src<-.eu2004_sources();files<-stats::setNames(vapply(src$role,function(r).eu2004_file(r,args$source,args$data_dir),''),src$role)
 key<-paste(files,collapse='|');if(exists(key,.eu2004_cache,inherits=FALSE))return(get(key,.eu2004_cache))
 # Reuse the immutable empty prototype within this bundle only.
 schema <- .valresultat_schema()
 doc<-xml2::read_xml(files[['final']],options=c('NONET','NOBLANKS'))
 if(.xml2018_attr(doc,'TID_RAPPORT')!='20040617154308')stop('Unexpected EU 2004 final snapshot.',call.=FALSE)
 kd<-.eu2004_candidacies(files[['candidacies']]);con<-unz(files[['candidacies']],'00E.xml',open='rb');bd<-xml2::read_xml(con);close(con)
 reg<-.eu2004_register(doc,files);kd$partiforkortning<-reg$data$partiforkortning[match(kd$partikod,reg$data$partikod)]
 ll<-purrr::list_rbind(lapply(grep('^list_',names(files),value=TRUE),function(role){x<-.eu2004_text(files[[role]]);x$partikod<-sub('^list_','',role);x}))
 pp<-purrr::list_rbind(lapply(grep('^preferences_',names(files),value=TRUE),function(role){x<-.eu2004_text(files[[role]],TRUE);x$partikod<-sub('^preferences_','',role);x}))
 pp$kandidatnummer<-.eu2004_key(pp$list,pp$position)
 if(any(!pp$kandidatnummer%in%kd$kandidatnummer)||anyDuplicated(pp[c('.geo','partikod','list','position')]))stop('Unmatched/duplicated EU 2004 preference observation.',call.=FALSE)
 sums<-pp|>dplyr::summarise(.n=as.integer(sum(.data$preferences)),.by=c('.geo','partikod','list'))
 chk<-dplyr::left_join(ll,sums,by=c('.geo','partikod','list'),relationship='one-to-one')
 if(any(chk$preferences!=dplyr::coalesce(chk$.n,0L)))stop('EU 2004 candidate/list preference totals disagree.',call.=FALSE)
 # Same category adapter, but with explicitly scoped 2004 keys, not 2009 IDs.
 doc<-.eu2004_adapt(doc,kd)
 r<-ctx<-list();i<-0L
 consume<-function(node,level,d=doc){i<<-i+1L;r[[i]]<<-.eu2004_result_node(node,d,level,reg,schema);ctx[[i]]<<-.eu2019_geo(node,level)}
 consume(xml2::xml_find_first(doc,'./NATION'),'riket')
 for(n in xml2::xml_find_all(doc,'./NATION/L\u00c4N'))consume(n,'lan')
 for(n in xml2::xml_find_all(doc,'.//KOMMUN'))consume(n,'kommun')
 # The district exports are sparse positive cells. Geography is their union;
 # the sole absent zero unit is independently explicit in municipal final XML.
 geos<-unique(ll[c('.geo','county','municipality','branch','district','county_name','municipality_name','branch_name','district_name','eligible')])
 if(anyDuplicated(geos$.geo))stop('Inconsistent EU 2004 district context.',call.=FALSE)
 zd<-xml2::read_xml(files[['zero_unit']],options=c('NONET','NOBLANKS'))
 zn<-xml2::xml_find_first(zd,'.//ONSDAGSDISTRIKT[@KOD="E-0483-02"]')
 if(.xml2018_int(zn,'R\u00d6STER')!=0L)stop('Changed EU 2004 zero-unit source.',call.=FALSE)
 z<-geos[geos$.geo=='E-0483-01',];z$.geo<-'E-0483-02';z$branch<-'02';z$branch_name<-.xml2018_attr(xml2::xml_find_first(zn,'..'),'NAMN');z$eligible<-0L
 geos<-dplyr::bind_rows(geos,z)
 if(nrow(geos)!=6271L||sum(grepl('^E-',geos$.geo))!=396L)stop('Incomplete EU 2004 reporting geography.',call.=FALSE)
 # Synthetic XML is an in-memory adapter only. It contains the exact reported
 # sparse cells and verified zero defaults; source timestamps are not invented.
 for(mk in unique(geos$municipality)) {
  gg<-geos[geos$municipality==mk,];md<-xml2::read_xml('<VAL><KOMMUN/></VAL>');mn<-xml2::xml_find_first(md,'./KOMMUN')
  xml2::xml_set_attrs(mn,c(KOD=mk,NAMN=gg$municipality_name[1]))
  for(branch in unique(gg$branch)) {
   bg<-gg[gg$branch==branch,];bn<-xml2::xml_add_child(mn,'KRETS_KOMMUN');xml2::xml_set_attrs(bn,c(KOD=paste0(mk,branch),NAMN=bg$branch_name[1]))
   for(g in bg$.geo){dn<-xml2::xml_add_child(bn,if(grepl('^E-',g))'ONSDAGSDISTRIKT'else'VALDISTRIKT');row<-bg[bg$.geo==g,];cells<-ll[ll$.geo==g,];.eu2004_fill_node(dn,cells,row$eligible[1],g,row$district_name[1],reg)}
   cells<-ll[ll$.geo%in%bg$.geo,];eligible<-sum(bg$eligible[!grepl('^E-',bg$.geo)])
   .eu2004_fill_node(bn,cells,eligible,paste0(mk,branch),bg$branch_name[1],reg)
   if(branch!='00')consume(bn,'kommunvalkrets',md)
   for(dn in xml2::xml_find_all(bn,'./VALDISTRIKT|./ONSDAGSDISTRIKT'))consume(dn,'valdistrikt',md)
  }
 }
 votes<-tibble::tibble(.geo=pp$.geo,partikod=pp$partikod,listnummer=paste(pp$partikod,pp$list,sep='-'),kandidatnummer=pp$kandidatnummer,antal_personroster=pp$preferences,kandidatnamn_lista=pp$name)
 national<-votes|>dplyr::summarise(antal_personroster=as.integer(sum(.data$antal_personroster)),.by=c('partikod','listnummer','kandidatnummer'));national$.geo<-'00';national$kandidatnamn_lista<-NA_character_
 lists<-ll[!ll$partikod%in%c('9997','9998','9999'),]|>dplyr::summarise(antal_listroster=as.integer(sum(.data$votes)),.by=c('.geo','partikod','list'));lists$listnummer<-paste(lists$partikod,lists$list,sep='-');lists$list<-NULL
 nl<-lists|>dplyr::summarise(antal_listroster=as.integer(sum(.data$antal_listroster)),.by=c('partikod','listnummer'));nl$.geo<-'00'
 q<-xml2::xml_find_all(doc,'./NATION/GILTIGA/PERSONVAL[@\u00d6VER_SP\u00c4RR="J"]');qp<-.eu2019_party(xml2::xml_find_first(q,'..'),reg)
 out<-list(kd=kd,result=.valresultat_public_andelar_2026(purrr::list_rbind(r)),context=purrr::list_rbind(ctx),votes=dplyr::bind_rows(votes,national),lists=dplyr::bind_rows(lists,nl),qualified=tibble::tibble(partikod=qp$partikod,kandidatnummer=xml2::xml_attr(q,'KANDNR')),relations=lapply(.eu2019_relations(doc,reg),.eu2004_retag),seats=.eu2004_retag(.eu2019_seats(doc,reg,'slutlig')))
 out$source_designations<-tibble::tibble(kall_enhetskod=ll$.geo[ll$partikod=='9997'],kall_partibeteckning=rep(NA_character_,sum(ll$partikod=='9997')),antal_roster=ll$votes[ll$partikod=='9997'],kall_partibeteckning_saknas=TRUE)
 out$result<-.eu2004_municipality_names(out$result);out$context<-.eu2004_municipality_names(out$context);out$result<-.eu2004_electorate(out$result,files[['electorate']]);assign(key,out,.eu2004_cache);out
}
.eu2004_fill_node <- function(node,cells,eligible,code,name,register) {
 votes<-tapply(cells$votes,cells$partikod,sum);get<-function(k)as.integer(dplyr::coalesce(unname(votes[k]),0))
 valid<-sum(cells$votes[!cells$partikod%in%c('9998','9999')]);blank<-get('9998');other<-get('9999')
 xml2::xml_set_attrs(node,c(KOD=code,NAMN=name,'R\u00d6STER'=as.character(valid)))
 if(!grepl('^E-',code)){v<-xml2::xml_add_child(node,'VALDELTAGANDE');xml2::xml_set_attrs(v,c('R\u00d6STBER\u00c4TTIGADE'=as.character(eligible),'SUMMA_R\u00d6STER'=as.character(valid+blank+other)))}
 for(k in c('BLANK','OG')){n<-xml2::xml_add_child(node,'OGILTIGA');xml2::xml_set_attrs(n,c(TEXT=k,'R\u00d6STER'=as.character(if(k=='BLANK')blank else other)))}
 for(k in register$data$partikod){j<-match(k,register$data$partikod);n<-xml2::xml_add_child(node,'GILTIGA');xml2::xml_set_attrs(n,c(PARTI=register$data$partiforkortning[j],'R\u00d6STER'=as.character(get(k))))}
 n<-xml2::xml_add_child(xml2::xml_add_child(node,'\u00d6VRIGA_GILTIGA'),'HANDSKRIVNA');xml2::xml_set_attr(n,'R\u00d6STER',as.character(get('9997')))
 invisible(node)
}
.eu2004_preference_view <- function(base,level,kd,by_list,zeros,ids) {
 x<-.eu2004_retag(.eu2024_preference_view(base,level,kd,by_list,zeros,ids,2004L))
 # Keep historical municipality names/codes (including Heby 1917).
 if('kommunkod'%in%names(x))x$kommunnamn<-base$context$kommunnamn[match(x$kommunkod,base$context$kommunkod)]
 x
}

.eu2004_adapt <- function(doc,kd) {
 ns<-xml2::xml_find_all(doc,'.//GILTIGA[@PARTI="\u00d6VR"]')
 for(n in ns) {
  children<-xml2::xml_find_all(n,'./VARAV_\u00d6VRIGA')
  total<-.xml2018_int(n,'R\u00d6STER'); rest<-total-sum(as.integer(xml2::xml_attr(children,'R\u00d6STER')))
  if(rest<0L)stop('Negative EU 2004 residual party votes.',call.=FALSE)
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
 keys<-.eu2004_key(sub('^[^-]+-','',l),xml2::xml_attr(v,'KANDIDAT'))
 if(length(keys) && any(!keys%in%kd$kandidatnummer))stop('Unknown EU 2004 result ballot position.',call.=FALSE)
 xml2::xml_set_attr(v,'KANDNR',keys)
 # Relation/qualification linkage requires party, exact source name AND age
 # where supplied, against a single ballot in that party. Never a name-only join.
 v<-xml2::xml_find_all(doc,'.//GRUPP_VALDA/VALD|.//GRUPP_VALDA/ERS\u00c4TTARE|./NATION/GILTIGA/PERSONVAL')
 for(n in v) {
  a<-.xml2018_attr(xml2::xml_find_first(n,'ancestor::GILTIGA[1]'),'PARTI')
  pool<-kd[kd$partiforkortning==a & !is.na(kd$partiforkortning),]
  if(length(unique(pool$listnummer))!=1L)stop('EU 2004 relation requires an unambiguous party ballot.',call.=FALSE)
  pool<-pool[pool$namn==.xml2018_attr(n,'NAMN'),]
  age<-.xml2018_int(n,'\u00c5LDER')
  if(!is.na(age))pool<-pool[pool$alder_pa_valdagen==age,]
  if(nrow(pool)!=1L)stop('Unresolved EU 2004 relation/qualification linkage.',call.=FALSE)
  xml2::xml_set_attr(n,'KANDNR',pool$kandidatnummer)
 }
 doc
}
.eu2004_read <- function(table,args) {
 if(!is.null(args$rakning)&&args$rakning!='slutlig')stop('EU 2004 has no verified complete preliminary Wednesday snapshot. Election night is provenance only.',call.=FALSE)
 level<-if(is.null(args$niva))'riket'else args$niva
 if(table%in%c('results','preference_votes')&&(length(level)!=1L||!level%in%c(.eu2024_levels,if(table=='preference_votes')'personvalsomrade')))
  stop('Unsupported EU 2004 geographic level.',call.=FALSE)
 if(table=='seats'&&!identical(level,'riket'))stop('EU seats are national only.',call.=FALSE)
 b<-.eu2004_bundle(args);kd<-b$kd
 if(table=='candidacies')return(kd)
 if(table=='results')return(b$result[b$result$geografiniva==level,c(.valresultat_public_columns_2026(level),'antal_rostberattigade_svenska_i_sverige','antal_rostberattigade_svenska_utomlands','antal_rostberattigade_utlandska')])
 if(table=='seats')return(b$seats)
 if(table=='substitutes') {
  x<-b$relations$ersattare
  x$ledamot_namn<-kd$namn[match(x$ledamot_kandidatnummer,kd$kandidatnummer)]
  x$ersattare_namn<-kd$namn[match(x$ersattare_kandidatnummer,kd$kandidatnummer)]
  return(x)
 }
 if(table%in%c('candidates','elected')) {
  population<-kd;population$giltig<-TRUE
  x<-.eu2004_retag(.kandidater_bas(population,2004L))
  if(!identical(args$resultat,FALSE)) {
   v<-b$votes[b$votes$.geo=='00',];j<-match(x$kandidatnummer,v$kandidatnummer)
   # Complete positive-vote exports verify zero for the remaining ballot positions.
   x$antal_personroster_totalt<-dplyr::coalesce(v$antal_personroster[j],0L)
   x$kvalificerad_personval<-ifelse(is.na(j),FALSE,paste(x$partikod,x$kandidatnummer)%in%paste(b$qualified$partikod,b$qualified$kandidatnummer))
   x$antal_personvalsomraden<-as.integer(x$kvalificerad_personval)
   x<-add_valda_to_kandidater_2026(x,b$relations$valda)
  }
  if(table=='elected'){x<-.valda_invaldsvalkrets_2026(x);x<-x[x$invald%in%TRUE,setdiff(names(x),'antal_valkretsar')]}
  return(x)
 }
 .eu2004_preference_view(.eu2019_preference_base(b,level),level,kd,args$per_lista,args$komplettera_nollor,paste(b$qualified$partikod,b$qualified$kandidatnummer))
}

.eu2004_register <- function(doc,files) {
 roles<-grep('^list_',names(files),value=TRUE);roles<-roles[!roles%in%c('list_9997','list_9998','list_9999')]
 aliases<-vapply(files[roles],function(f)strsplit(readLines(f,n=1L,encoding='latin1'),';',fixed=TRUE)[[1L]][1L],'')
 nodes<-xml2::xml_find_all(doc,'./PARTI');labels<-xml2::xml_attr(nodes,'BETECKNING')[match(aliases,xml2::xml_attr(nodes,'F\u00d6RKORTNING'))]
 if(anyNA(labels)||anyDuplicated(aliases))stop('Unmatched EU 2004 party alias.',call.=FALSE)
 .xml2018_reg_index(tibble::tibble(valtyp='E',valomradeskod='00',partiforkortning=unname(aliases),partibeteckning=labels,partikod=sub('^list_','',roles)))
}
.eu2004_electorate <- function(result,file) {
 if(!requireNamespace('readxl',quietly=TRUE))stop('EU 2004 raw electorate input requires optional readxl; canonical reading does not.',call.=FALSE)
 x<-suppressMessages(readxl::read_xls(file,col_names=FALSE,.name_repair='minimal'))
 keep<-!is.na(suppressWarnings(as.integer(x[[16]]))) & !is.na(x[[1]])
 x<-x[keep,];if(nrow(x)!=312L)stop('Incomplete EU 2004 SCB electorate composition.',call.=FALSE)
 label<-as.character(x[[1]]);label[label=='Hela riket']<-'Sverige';label[label=='Vaggeryds']<-'Vaggeryd';label[label=='Malungs']<-'Malung'
 values<-c('antal_rostberattigade_svenska_i_sverige','antal_rostberattigade_svenska_utomlands','antal_rostberattigade_utlandska')
 for(n in values)result[[n]]<-NA_integer_
 for(level in c('riket','lan','kommun')) {
  ix<-which(result$geografiniva==level)
  name<-switch(level,riket=rep('Sverige',length(ix)),lan=result$lannamn[ix],kommun=result$kommunnamn_officiellt[ix])
  name[name=='Vaggeryds']<-'Vaggeryd';name[name=='Malungs']<-'Malung'
  j<-match(name,label)
  if(anyNA(j)||any(result$antal_rostberattigade[ix]!=as.integer(x[[16]][j])))stop('EU 2004 SCB/XML electorate context mismatch.',call.=FALSE)
  for(k in seq_along(values))result[[values[k]]][ix]<-as.integer(x[[c(4,8,12)[k]]][j])
  if(any(rowSums(result[ix,values])!=result$antal_rostberattigade[ix]))stop('EU 2004 electorate components do not reconcile.',call.=FALSE)
 }
 result
}

.eu2004_municipality_names <- function(x) {
 x$kommunnamn_officiellt<-x$kommunnamn
 j<-match(x$kommunkod,kommunnamn_2026$kommunkod)
 x$kommunnamn<-dplyr::coalesce(kommunnamn_2026$kommunnamn[j],x$kommunnamn)
 x
}
