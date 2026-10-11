# Opt-in 2006 public/canonical/raw checks; no network or raw-source writes.
# Rscript development/validate_canonical_2006.R RAW_ROOT ASSETS_DIR [SECTION]
args <- commandArgs(trailingOnly=TRUE)
if (!length(args) %in% 2:3) stop('Specify RAW_ROOT ASSETS_DIR [SECTION].')
pkgload::load_all('.',quiet=TRUE)
root <- args[[1]]; dir <- normalizePath(args[[2]],winslash='/',mustWork=TRUE)
section <- if (length(args)==3L) args[[3]] else 'all'
m <- swelections:::.canonical_manifest(file.path(dir,'manifest.json'))
options(swelections.canonical_manifest=file.path(dir,'manifest.json'),swelections.canonical_assets_dir=dir,
 swelections.canonical_cache_dir=file.path(dirname(dir),'2006-validation-cache'))
count <- 0L
same <- function(a,b,label) { if (!identical(a,b)) stop(label,': ',paste(all.equal(a,b),collapse='; ')); count <<- count+1L }
for (i in seq_len(nrow(m$assets))) { a <- m$assets[i,]; f <- file.path(dir,a$file); same(unname(file.info(f)$size),as.double(a$bytes),'asset size'); same(swelections:::.canonical_sha256(f),a$sha256,'asset checksum') }
s <- swelections:::.sources_2006('local',root)
for (f in s$sources$file) swelections:::.xml2006_source(s,f)
for (f in s$municipal_sources$file) swelections:::.xml2006_source(s,paste0('official-final/',f))
# Cache actual raw parser results only inside this validation process. Each
# distinct raw table is still derived from preserved sources; immutable source
# populations are reused across public projections.
ns <- asNamespace('swelections'); cache <- new.env(parent=emptyenv())
unlockBinding('.sources_2006',ns); assign('.sources_2006',function(...) s,ns); lockBinding('.sources_2006',ns)
readers <- c('.valresultat_2006','.mandat_2006','.read_candidacies_2006','.kandidater_2006','.valda_2006','.ersattare_2006','.personroster_2006','.xml2006_population','.xml2006_relations')
original <- lapply(readers,function(n) get(n,ns)); names(original) <- readers
for (name in readers) local({ keyname <- name; fun <- original[[name]]
 memo <- function(...) { a <- list(...); a[[1]] <- NULL; if (any(vapply(a, is.list, logical(1)))) return(fun(...)); key <- paste(keyname,paste(capture.output(dput(a)),collapse=''),sep='|'); if (exists(key,cache,inherits=FALSE)) return(get(key,cache)); x <- fun(...); assign(key,x,cache); x }
 unlockBinding(name,ns); assign(name,memo,ns); lockBinding(name,ns)
})
# Script process ends; production source files/bindings are untouched.
check <- function(fun,arguments,label) {
 raw <- do.call(fun,c(list(year=2006,source='local',data_dir=root,detail='full',names='sv'),arguments))
 can <- do.call(fun,c(list(year=2006,source='canonical',detail='full',names='sv'),arguments))
 same(can,raw,paste(label,'raw full'))
 for (detail in c('standard','full')) {
  en <- do.call(fun,c(list(year=2006,source='canonical',detail=detail,names='en'),arguments))
  sv <- do.call(fun,c(list(year=2006,source='canonical',detail=detail,names='sv'),arguments))
  same(swelections:::.public_output_names(sv,'en'),en,paste(label,detail,'language'))
  same(sv,can[names(sv)],paste(label,detail,'projection'))
 }
 cat('PASS',label,nrow(raw),'rows\n'); flush.console()
 invisible(raw)
}
levels <- list(RD=c('district','municipality','municipal_constituency','county','parliamentary_constituency','national'),RF=c('district','municipality','municipal_constituency','regional_constituency','region','national'),KF=c('district','municipality','municipal_constituency','county','national'))
for (v in names(levels)) {
 if (section %in% c('all','results')) for (level in levels[[v]]) check(results,list(election=v,level=level,count='final'),paste(v,'results',level))
 if (section %in% c('all','seats')) check(seats,list(election=v),paste(v,'seats'))
 if (section %in% c('all','candidates')) {
  for (fun in c('candidacies','candidates','elected','substitutes')) check(get(fun),list(election=v),paste(v,fun))
  x <- check(candidates,list(election=v,include_results=FALSE),paste(v,'candidate base'))
 }
 if (section %in% c('all','preference_votes')) for (level in c('preference_vote_area','district')) for (by in c(FALSE,TRUE)) {
  x <- check(preference_votes,list(election=v,level=level,by_list=by),paste(v,'preference',level,by))
  z <- preference_votes(2006,election=v,level=level,by_list=by,include_zeros=TRUE,source='canonical',detail='full',names='sv')
  same(z,x,'no unsupported synthetic zero observations')
  same(anyDuplicated(x[c('valtyp','kandidatnummer','partikod','personvalsomradeskod')]),0L,'unique source observation keys')
  if (level=='preference_vote_area' && !by) same(sum(x$antal_personroster),c(RD=1235601L,RF=1186237L,KF=1554153L)[[v]],'preserved preference total')
 }
}
if (section %in% c('all','candidates','relations')) {
 for (v in names(levels)) { x <- elected(2006,election=v,source='canonical',detail='full'); same(nrow(x),c(RD=349L,RF=1656L,KF=13078L)[[v]],'appointed counts'); stopifnot(!any(x$name %in% c('Kunde ej utses','Kunde inte utses')),!anyDuplicated(x$candidate_number)) }
}
if (section %in% c('all','candidates','relations')) {
 for (v in names(levels)) {
  expected <- list(); relations <- list()
  for (file in swelections:::.xml2006_files(s,v)) {
   doc <- xml2::read_xml(swelections:::.xml2006_source(s,file),options=c('NONET','NOBLANKS'))
   key <- function(node) paste0('2006:',v,':slot:',utils::URLencode(paste(xml2::xml_attr(doc,'FILNAMN'),xml2::xml_path(node),sep='|'),reserved=TRUE))
   for (group in xml2::xml_find_all(doc,'.//GRUPP_VALDA')) {
    members <- xml2::xml_find_all(group,'./VALD[not(@NAMN="Kunde ej utses")]')
    replacements <- xml2::xml_find_all(group,'./ERSÄTTARE')
    for (member in members) {
     area <- xml2::xml_find_first(member,'ancestor::*[@TYP="Valkrets"][1]')
     if (inherits(area,'xml_missing')) area <- xml2::xml_find_first(member,'ancestor::KRETS_KOMMUN[1]')
     expected[[length(expected)+1L]] <- data.frame(id=key(member),name=xml2::xml_attr(member,'NAMN'),order=as.integer(xml2::xml_attr(member,'ORDNING')),basis=xml2::xml_attr(member,'GRUND'))
     for (replacement in replacements) relations[[length(relations)+1L]] <- data.frame(member=key(member),replacement=key(replacement),order=as.integer(xml2::xml_attr(replacement,'ORDNING')))
    }
   }
  }
  a <- elected(2006,election=v,source='canonical',detail='full'); e <- dplyr::bind_rows(expected); j <- match(e$id,a$candidate_number)
  stopifnot(!anyNA(j)); same(a$name[j],e$name,'raw appointed names'); same(a$order_of_election[j],e$order,'raw elected order'); same(a$election_basis_id[j],e$basis,'raw elected basis')
  b <- substitutes(2006,election=v,source='canonical',detail='full'); r <- dplyr::bind_rows(relations)
  signature <- function(member,replacement,order) paste(member,replacement,order,sep='|')
  same(sort(signature(b$member_candidate_number,b$substitute_candidate_number,b$substitute_order)),sort(signature(r$member,r$replacement,r$order)),'raw expanded substitute relationships')
  cat('PASS',v,'independent original elected/substitute XML controls\n')
 }
}
# Independent original XML party and elected geography controls.
if (section %in% c('all','candidates','relations')) {
for(v in c('RD','RF','KF')) {
 a <- elected(2006,election=v,source='canonical',detail='full')
 tested <- 0L
 for(file in swelections:::.xml2006_files(s,v)) {
  doc <- xml2::read_xml(swelections:::.xml2006_source(s,file),options=c('NONET','NOBLANKS'))
  nodes <- xml2::xml_find_all(doc,'.//GRUPP_VALDA/VALD[not(@NAMN="Kunde ej utses")]')
  ids <- paste0('2006:',v,':slot:',vapply(paste(xml2::xml_attr(doc,'FILNAMN'),xml2::xml_path(nodes),sep='|'),utils::URLencode,'',reserved=TRUE))
  j <- match(ids,a$candidate_number); stopifnot(!anyNA(j))
  party <- xml2::xml_find_chr(nodes,'string(ancestor::GILTIGA[1]/@PARTI)')
  expected_abbreviation <- ifelse(grepl('^[0-9]+$',party),NA_character_,party)
  stopifnot(identical(a$party_abbreviation[j],expected_abbreviation))
  if(any(grepl('^[0-9]{4}$',party))) stopifnot(identical(a$party_code[j][grepl('^[0-9]{4}$',party)],party[grepl('^[0-9]{4}$',party)]))
  geography <- xml2::xml_find_chr(nodes,'string(ancestor::*[@TYP="Valkrets"][1]/@KOD)')
  expected_area <- if(v=='RD') rep('00',length(nodes)) else xml2::xml_find_chr(nodes,if(v=='RF') 'string(ancestor::LÄN[1]/@KOD)' else 'string(ancestor::KOMMUN[1]/@KOD)')
  # Undivided RF/KF technical 00 areas are normalized to no constituency.
  # Their original codes remain in the immutable raw XML, not person geography.
  if(v %in% c('RF','KF')) geography[grepl('00$',geography)] <- NA_character_
  primary <- a[[if(v=='KF') 'elected_municipal_constituency_code' else 'elected_constituency_code']][j]
  stopifnot(identical(primary,geography),identical(a$elected_electoral_area_code[j],expected_area))
  tested <- tested+length(nodes)
 }
 cat('PASS independent XML party/elected geography',v,tested,'observations\n')
}

}
cat('PASS',count,'2006 canonical/raw/schema/language/control checks\n')
