# Rscript ... SOURCE_DIRECTORY EXTENDED_CANONICAL_DIRECTORY ORIGINAL_PROTOTYPE_DIRECTORY
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3L)
pkgload::load_all('.',quiet=TRUE)
root<-args[1];out<-args[2];old<-args[3]
cols<-c('eligible_swedish_citizens_in_sweden','eligible_swedish_citizens_abroad','eligible_foreign_citizens')
file<-file.path(root,'scb-electorate-composition.html');p<-jsonlite::read_json(paste0(file,'.provenance.json'),simplifyVector=TRUE)
stopifnot(file.info(file)$size==p$size,unname(tools::md5sum(file))==p$md5,swelections:::.canonical_sha256(file)==p$sha256)
# Independent source extraction: do not call production SCB parser/enrichment.
rows<-lapply(xml2::xml_find_all(xml2::read_html(file),'//table//tr'),function(tr)trimws(xml2::xml_text(xml2::xml_find_all(tr,'./td'))))
rows<-Filter(function(r) length(r)==6L&&grepl('^[0-9]+$',gsub('[[:space:]\u00a0]','',r[6])),rows)
e<-dplyr::bind_rows(lapply(rows,function(r)data.frame(name=r[1],domestic=as.integer(gsub('[[:space:]\u00a0]','',r[3])),abroad=as.integer(gsub('[[:space:]\u00a0]','',r[4])),foreign=as.integer(gsub('[[:space:]\u00a0]','',r[5])),total=as.integer(gsub('[[:space:]\u00a0]','',r[6])))))
stopifnot(nrow(e)==22L,!anyDuplicated(e$name),all(e$domestic+e$abroad+e$foreign==e$total))
country<-e[e$name=='HELA RIKET',];counties<-e[e$name!='HELA RIKET',];stopifnot(all(colSums(counties[2:5])==unlist(country[2:5])),all(unlist(country[2:5])==c(6648244L,106003L,323255L,7077502L)))
options(swelections.canonical_manifest=file.path(out,'manifest.json'),swelections.canonical_cache_dir=file.path(out,'validation-cache'))
for(level in c('national','county'))for(detail in c('standard','full'))for(lang in c('en','sv')){
 x<-results(2003,election='referendum',level=level,source='local',data_dir=root,names=lang,detail=detail)
 y<-results(2003,election='referendum',level=level,source='canonical',names=lang,detail=detail);stopifnot(identical(x,y))
 if(lang=='sv')x<-swelections:::.public_output_names(x,'en')
 k<-if(level=='national')rep('HELA RIKET',nrow(x))else toupper(x$county_name);idx<-match(k,e$name);stopifnot(!anyNA(idx),all(e$total[idx]==x$eligible_voters),all(rowSums(x[cols])==x$eligible_voters))
 for(i in seq_along(cols))stopifnot(identical(x[[cols[i]]],e[[c('domestic','abroad','foreign')[i]]][idx]))
 stopifnot(!any(grepl('party',names(x))),all(x$valid_votes+x$invalid_votes==x$total_votes))
}
# Entire old physical asset (all six levels) is a strict unchanged projection.
f<-'referendum2003-results-final.parquet';a<-tibble::as_tibble(nanoparquet::read_parquet(file.path(old,f)));b<-tibble::as_tibble(nanoparquet::read_parquet(file.path(out,f)))
stopifnot(nrow(b)==20694L,ncol(b)==46L,identical(a,b[names(a)]),setequal(setdiff(names(b),names(a)),cols))
pop<-b$.table%in%c('riket','lan');stopifnot(sum(pop)==66L)
for(col in cols)stopifnot(all(is.na(b[[col]][!pop])),all(!is.na(b[[col]][pop])),typeof(b[[col]])=='integer')
stopifnot(all(b$is_blank_option==(b$voting_option_code=='BLANK')),all(b$votes[b$is_blank_option]==b$blank_votes[b$is_blank_option]))
for(level in unique(b$.table)){
 z<-b[b$.table==level,];units<-z[!duplicated(z$source_unit_code),]
 sums<-tapply(z$votes,z$source_unit_code,sum);stopifnot(all(sums[units$source_unit_code]==units$valid_votes),all(units$valid_votes+units$invalid_votes==units$total_votes))
}
m<-swelections:::.canonical_manifest(file.path(out,'manifest.json'));stopifnot(is.data.frame(m$electorate_sources),nrow(m$electorate_sources)==1L,m$electorate_sources$url==swelections:::.referendum2003_electorate_url)
for(i in seq_len(nrow(m$assets))){p<-file.path(out,m$assets$file[i]);stopifnot(file.info(p)$size==m$assets$bytes[i],swelections:::.canonical_sha256(p)==m$assets$sha256[i])}
cat('PASS 22 SCB group totals; county/national reconciliation; all 16 raw/canonical language/detail pairs; unchanged 43-column reference projection across 20694 rows; 46-column Parquet schema; fine-level typed NA; valid Blank separated; source/asset hashes\n')
