# Independent preserved HTML/XML controls plus public canonical/raw equivalence.
# Rscript data-raw/validate-preference-web-2002.R RAW_ROOT ASSET_DIRECTORY REFERENCE_DIRECTORY
args <- commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3L)
pkgload::load_all('.',quiet=TRUE)
s <- swelections:::.sources_2002('local',args[1]);directory<-normalizePath(args[2],winslash='/')
p <- jsonlite::read_json(file.path(s$root,'district-preference-web/manifest.json'),simplifyVector=TRUE)
stopifnot(nrow(p)==312L,!anyDuplicated(p$url))
for(i in seq_len(nrow(p))){f<-file.path(s$root,p$file[i]);stopifnot(file.info(f)$size==p$bytes[i],unname(tools::md5sum(f))==p$md5[i],swelections:::.canonical_sha256(f)==p$sha256[i])}
# This parser deliberately does not call the production HTML table parser.
rows<-list();controls<-list()
for(i in which(p$view!='')){
 d<-xml2::read_html(file.path(s$root,p$file[i]));for(a in xml2::xml_find_all(d,'.//a[@name]')){
 key<-xml2::xml_attr(a,'name');t<-xml2::xml_find_first(a,'following-sibling::table[1]');tr<-xml2::xml_find_all(t,'./tr|./tbody/tr');cells<-lapply(tr,function(r)trimws(xml2::xml_text(xml2::xml_find_all(r,'./td'))));cells<-Filter(function(z)length(z)==5&&grepl('^[0-9]+$',z[2])&&grepl('^[0-9]+$',z[3]),cells)
 for(j in seq_along(cells)){z<-cells[[j]];path<-if(length(cells)==1L)'/ROWS/PERSONVAL'else paste0('/ROWS/PERSONVAL[',j,']');id<-paste0('2002:RD:',if(p$view[i]=='-lista')'list:'else'area:',utils::URLencode(paste0(p$url[i],'#',key,'|',path),reserved=TRUE));rows[[length(rows)+1L]]<-data.frame(id=id,municipality=p$municipality[i],district=p$district[i],view=p$view[i],key=key,rank=as.integer(z[2]),votes=as.integer(z[3]))}
 }}
x<-dplyr::bind_rows(rows);stopifnot(!anyDuplicated(x$id),all(x$votes>0))
for(i in which(p$view=='')){
 d<-xml2::read_html(file.path(s$root,p$file[i]));for(a in xml2::xml_find_all(d,'.//a[starts-with(@name,"personval-")]')){
 party<-sub('^personval-','',xml2::xml_attr(a,'name'));t<-xml2::xml_find_first(a,'ancestor::table[1]');for(tr in xml2::xml_find_all(t,'./tr|./tbody/tr')){z<-trimws(xml2::xml_text(xml2::xml_find_all(tr,'./td')));if(length(z)!=5L||!grepl('^(Totalt|[0-9]{4}-[0-9]{5})$',z[1]))next;number<-suppressWarnings(as.integer(z[3]));if(is.na(number))next;key<-paste0(party,'-',if(z[1]=='Totalt')'totalt'else z[1]);observed<-sum(x$votes[x$district==p$district[i]&x$key==key]);stopifnot(number==observed);controls[[length(controls)+1L]]<-data.frame(district=p$district[i],key=key,reported=number)}
 }}
stopifnot(length(controls)==1451L)
for(view in c('-totalt','-lista')){z<-x[x$view==view,];stopifnot(nrow(z)==5852L,sum(z$votes)==26835L,length(unique(z$district))==104L)}
# Independent pre-recovery XML totals and all original source-array keys/counts.
expected<-list();units<-character()
national<-xml2::read_xml(swelections:::.xml2002_source(s,'slutresultat_00R.xml'))
municipalities<-xml2::xml_find_all(national,'.//KRETS_RIKSDAG/KOMMUN')
parents<-xml2::xml_find_first(municipalities,'parent::*')
area_map<-stats::setNames(xml2::xml_attr(parents,'KOD'),xml2::xml_attr(municipalities,'KOD'))
area_expected<-list()
for(a in xml2::xml_find_all(national,'.//KRETS_RIKSDAG'))for(party in xml2::xml_find_all(a,'./GILTIGA')) {
 alias<-xml2::xml_attr(party,'PARTI');if(!alias%in%c('M','C','FP','KD','S','V','MP'))next
 area_expected[[length(area_expected)+1L]]<-data.frame(area=xml2::xml_attr(a,'KOD'),party=alias,votes=sum(as.double(xml2::xml_attr(xml2::xml_find_all(party,'./PERSONVAL'),'PERSONKRYSS'))))
}
area_expected<-dplyr::bind_rows(area_expected)
r<-s$sources[grepl('_[0-9]{4}R[.]xml$',s$sources$export),]
for(i in seq_len(nrow(r))){d<-xml2::read_xml(swelections:::.xml2002_source(s,r$export[i]));ns<-xml2::xml_find_all(d,'./KOMMUN/KRETS_KOMMUN/VALDISTRIKT|./KOMMUN/ONSDAGSDISTRIKT|./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT');units<-c(units,xml2::xml_attr(ns,'KOD'));for(by in c(FALSE,TRUE)){records<-xml2::xml_find_all(ns,if(by)'./GILTIGA/VALSEDEL/PERSONVAL'else'./GILTIGA/PERSONVAL',flatten=TRUE);ids<-paste0('2002:RD:',if(by)'list:'else'area:',vapply(paste(r$export[i],xml2::xml_path(records),sep='|'),utils::URLencode,'',reserved=TRUE));expected[[length(expected)+1L]]<-data.frame(id=ids,view=by,votes=as.integer(xml2::xml_attr(records,'PERSONKRYSS')),area=rep(unname(area_map[substr(r$export[i],14,17)]),length(ids)),party=xml2::xml_attr(xml2::xml_find_first(records,'ancestor::GILTIGA[1]'),'PARTI'))}}
e<-dplyr::bind_rows(expected);stopifnot(length(unique(units))==6162L)
options(swelections.canonical_manifest=file.path(directory,'manifest.json'),swelections.canonical_assets_dir=directory,swelections.canonical_cache_dir=file.path(dirname(directory),'2002-web-validation-cache'))
# Process-local memoisation avoids rereading the same raw view for name/projection checks.
# The first call for each by-list variant executes the production raw reader.
ns<-asNamespace('swelections');reader<-get('.personroster_2002',ns);cache<-new.env(parent=emptyenv())
memo<-function(sources,...) {
 key<-paste(capture.output(dput(list(...))),collapse='')
 if(!exists(key,cache,inherits=FALSE))assign(key,reader(sources,...),cache)
 get(key,cache)
}
unlockBinding('.personroster_2002',ns);assign('.personroster_2002',memo,ns);lockBinding('.personroster_2002',ns)
checks<-0L
for(by in c(FALSE,TRUE)){
 cat('CHECK RAW RD district by_list=',by,'\n');flush.console()
 raw<-preference_votes(2002,election='RD',level='district',by_list=by,source='local',data_dir=args[1],detail='full',names='en')
  old<-e[e$view==by,];web<-x[x$view==if(by)'-lista'else'-totalt',]
 web$area<-unname(area_map[web$municipality]);web$party<-sub('-.*','',web$key)
 sums<-aggregate(votes~area+party,rbind(old[c('area','party','votes')],web[c('area','party','votes')]),sum)
 k<-match(paste(area_expected$area,area_expected$party),paste(sums$area,sums$party))
 stopifnot(!anyNA(k),identical(as.double(area_expected$votes),as.double(sums$votes[k])))
 stopifnot(nrow(raw)==nrow(old)+5852L,!anyDuplicated(raw$candidate_number),identical(raw$preference_votes[match(old$id,raw$candidate_number)],old$votes),identical(raw$preference_votes[match(web$id,raw$candidate_number)],web$votes))
 j<-match(web$id,raw$candidate_number);stopifnot(!anyNA(j),all(is.na(raw$name[j])),all(raw$municipality_code[j]==web$municipality),all(raw$party_abbreviation[j]==web$party),all(raw$district_code[j]==ifelse(grepl('^R-',web$district),paste0(web$municipality,'9800'),web$district)))
 if(by)stopifnot(all(is.na(raw$ballot_order[j])),all(raw$list_number[j]==sub('^[^-]+-','',web$key)))
 can<-preference_votes(2002,election='RD',level='district',by_list=by,source='canonical',detail='full',names='en');stopifnot(identical(raw,can))
 for(source in c('local','canonical'))for(detail in c('standard','full'))for(lang in c('en','sv')){
  z<-preference_votes(2002,election='RD',level='district',by_list=by,source=source,data_dir=if(source=='local')args[1]else NULL,detail=detail,names=lang)
  en<-if(lang=='en')z else swelections:::.public_output_names(z,'en');stopifnot(identical(en,raw[names(en)]));checks<-checks+1L
 }
 cat('PASS RD district',by,'before rows/votes',nrow(old),sum(old$votes),'after',nrow(raw),sum(raw$preference_votes),'\n');flush.console()
}
m<-jsonlite::read_json(file.path(directory,'manifest.json'),simplifyVector=TRUE)
for(i in seq_len(nrow(m$assets))){f<-file.path(directory,m$assets$file[i]);stopifnot(file.info(f)$size==m$assets$bytes[i],swelections:::.canonical_sha256(f)==m$assets$sha256[i]);y<-tibble::as_tibble(nanoparquet::read_parquet(f));stopifnot(identical(swelections:::.canonical_names_en(swelections:::.canonical_names_sv(y)),y));old<-file.path(args[3],basename(f));if(file.exists(old))stopifnot(swelections:::.canonical_sha256(old)==m$assets$sha256[i])}
cat('PASS 312 sources; 1451 independent controls; 16 language/detail/source projection checks; all 13 previous assets byte-identical; 14 asset checksums/schema round trips\n')
