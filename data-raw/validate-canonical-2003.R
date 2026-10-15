# Independent direct XML/SND/SCB controls and public canonical equivalence.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop('Specify SOURCE_DIRECTORY SND_ZIP CANONICAL_DIRECTORY.')
if (!requireNamespace('readxl', quietly = TRUE)) stop('Install readxl for independent workbook validation.')
pkgload::load_all('.', quiet = TRUE)
root <- args[[1]]; out <- args[[3]]
read_counts <- function(n) {
 opt <- xml2::xml_find_all(n, './GILTIGA'); values <- as.integer(xml2::xml_attr(opt, 'RÖSTER'))
 option <- stats::setNames(values, xml2::xml_attr(opt,'PARTI'))
 valid <- as.integer(xml2::xml_attr(n,'RÖSTER'))
 invalid <- as.integer(xml2::xml_attr(xml2::xml_find_first(n,'./OGILTIGA'),'RÖSTER'))
 attendance <- xml2::xml_find_first(n,'./VALDELTAGANDE')
 cast <- as.integer(xml2::xml_attr(attendance,'SUMMA_RÖSTER'))
 if (xml2::xml_name(n)=='ONSDAGSDISTRIKT') cast <- valid + invalid
 stopifnot(setequal(names(option),c('JA','NEJ','BLANK')),sum(option)==valid,cast==valid+invalid)
 data.frame(code=xml2::xml_attr(n,'KOD'),type=xml2::xml_name(n),name=xml2::xml_attr(n,'NAMN'),
  yes=unname(option['JA']),no=unname(option['NEJ']),blank=unname(option['BLANK']),
  valid=valid,invalid=invalid,cast=cast,eligible=as.integer(xml2::xml_attr(attendance,'RÖSTBERÄTTIGADE')))
}
national<-xml2::read_xml(file.path(root,'final.xml'))
agg<-dplyr::bind_rows(lapply(xml2::xml_find_all(national,'.//*[@KOD]'),read_counts))
rows<-list();constituencies<-list()
for(m in xml2::xml_find_all(national,'.//KOMMUN')){
 code<-xml2::xml_attr(m,'KOD');x<-xml2::read_xml(file.path(root,'final-municipal',paste0(code,'.xml')))
 d<-dplyr::bind_rows(lapply(xml2::xml_find_all(x,'.//VALDISTRIKT|.//ONSDAGSDISTRIKT'),read_counts));d$municipality<-code
 total<-read_counts(xml2::xml_find_first(x,'./KOMMUN'));v<-c('yes','no','blank','valid','invalid','cast')
 stopifnot(identical(unname(as.integer(colSums(d[v]))),unname(as.integer(total[1,v]))))
 for(k in xml2::xml_find_all(x,'.//KRETS_KOMMUN')) {
  parent<-read_counts(k);kids<-dplyr::bind_rows(lapply(xml2::xml_find_all(k,'./VALDISTRIKT|./ONSDAGSDISTRIKT'),read_counts))
  stopifnot(all(colSums(kids[v])==unlist(parent[v])),sum(kids$eligible,na.rm=TRUE)==parent$eligible)
  constituencies[[length(constituencies)+1L]]<-parent
 }
 rows[[length(rows)+1L]]<-d
}
d<-dplyr::bind_rows(rows);stopifnot(nrow(d)==6372L,!anyDuplicated(d$code),sum(d$type=='VALDISTRIKT')==5976L,sum(d$type=='ONSDAGSDISTRIKT')==396L)
control<-agg[agg$type=='NATION',];v<-c('yes','no','blank','invalid','cast')
stopifnot(all(colSums(d[v])==unlist(control[v])),all(unlist(control[v])==c(2453899L,3265341L,121073L,3475L,5843788L)))
for(type in c('LÄN','KRETS_RIKSDAG','KOMMUN'))stopifnot(all(colSums(agg[agg$type==type,v])==unlist(control[v])))
# Independent workbook observations; never sum ÖÖsum together with ordinary rows.
tmp<-tempfile();dir.create(tmp);on.exit<-NULL
utils::unzip(args[[2]],exdir=tmp)
f<-list.files(tmp,pattern='valdistr.xlsx$',recursive=TRUE,full.names=TRUE);stopifnot(length(f)==1L)
s<-readxl::read_excel(f);names(s)<-c('county','county_name','municipality','municipality_name','code','name','eligible','turnout','cast','valid','invalid','yes','no','blank')
s$code<-sprintf('%08d',s$code);s$municipality<-sprintf('%04d',s$municipality)
ordinary<-s[s$code!='99999999',];summaries<-s[s$code=='99999999',];stopifnot(nrow(ordinary)==5976L,nrow(summaries)==290L)
j<-merge(ordinary,d[d$type=='VALDISTRIKT',],by='code');stopifnot(nrow(j)==5976L)
for(v in c('yes','no','blank','invalid','cast','valid','eligible'))stopifnot(identical(j[[paste0(v,'.x')]],as.double(j[[paste0(v,'.y')]])))
j<-merge(summaries,agg[agg$type=='KOMMUN',],by.x='municipality',by.y='code');stopifnot(nrow(j)==290L)
for(v in c('yes','no','blank','invalid','cast','valid','eligible'))stopifnot(all(j[[paste0(v,'.x')]]==j[[paste0(v,'.y')]]))
unlink(tmp,recursive=TRUE)
scb<-suppressMessages(readxl::read_excel(file.path(root,'scb-counties.xls'),col_names=FALSE))[9:30,]
co<-agg[agg$type%in%c('LÄN','NATION'),];co$key<-toupper(co$name);co$key[co$type=='NATION']<-'RIKET';idx<-match(scb[[1]],co$key);stopifnot(!anyNA(idx))
for(pair in list(c(2,'eligible'),c(3,'valid'),c(4,'invalid'),c(5,'cast'),c(8,'yes'),c(9,'no'),c(10,'blank')))stopifnot(all(as.double(scb[[as.integer(pair[1])]])==co[[pair[2]]][idx]))
scb<-suppressMessages(readxl::read_excel(file.path(root,'scb-municipalities.xls'),col_names=FALSE));scb[[1]]<-sub('[12]$','',scb[[1]])
co<-agg[agg$type=='KOMMUN',];co$name[co$code=='0484']<-'Eskilstuna';idx<-match(co$name,scb[[1]]);stopifnot(!anyNA(idx),all(abs(as.double(scb[[2]][idx])-round(100*co$yes/co$valid,1))<1e-8),all(abs(as.double(scb[[3]][idx])-round(100*co$no/co$valid,1))<1e-8))
cat('PASS independent XML: 6372 units, 290 municipalities, 396 containers; SND: 5976 districts + 290 totals; SCB: 22 count rows + 290 share pairs\n')
options(swelections.canonical_manifest=file.path(out,'manifest.json'),swelections.canonical_cache_dir=file.path(out,'validation-cache'))
# Check all API variants against the independently extracted source units/counts.
levels<-c(national='NATION',county='LÄN',parliamentary_constituency='KRETS_RIKSDAG',municipality='KOMMUN',municipal_constituency='KRETS_KOMMUN',district='DISTRICT')
for(level in names(levels)){
 expected<-if(level=='district')d else if(level=='municipal_constituency')dplyr::bind_rows(constituencies) else agg[agg$type==levels[[level]],]
 if(level=='municipal_constituency')expected<-expected[!grepl('00$',expected$code),]
 raw<-results(2003,election='referendum',level=level,source='local',data_dir=root,detail='full')
 stopifnot(nrow(raw)==3L*nrow(expected),!anyDuplicated(raw[c('source_unit_code','voting_option_code')]),!any(grepl('party',names(raw))))
 key<-paste(raw$source_unit_code,raw$voting_option_code)
 expected_long<-dplyr::bind_rows(lapply(c(JA='yes',NEJ='no',BLANK='blank'),function(col)data.frame(code=expected$code,votes=expected[[col]])))
 expected_key<-unlist(lapply(c('JA','NEJ','BLANK'),function(option)paste(expected$code,option)))
 stopifnot(identical(raw$votes,expected_long$votes[match(key,expected_key)]))
 for(language in c('en','sv'))for(detail in c('standard','full')) {
  a<-results(2003,election='referendum',level=level,source='local',data_dir=root,names=language,detail=detail)
  b<-results(2003,election='referendum',level=level,source='canonical',names=language,detail=detail)
  stopifnot(identical(a,b))
  en<-swelections:::.public_output_names(if(language=='sv')a else swelections:::.canonical_names_sv(a),'en')
  stopifnot(identical(en,raw[names(en)]))
  svlevel<-swelections:::.english_argument_values$level[[level]]
  sv<-valresultat(2003,val='F',niva=svlevel,source='canonical',names=language,detaljniva=detail)
  stopifnot(identical(a,sv))
 }
 if(level=='district')stopifnot(all(is.na(raw$eligible_voters[raw$district_type=='wednesday'])),all(is.na(raw$turnout[raw$district_type=='wednesday'])))
 cat('PASS public',level,nrow(raw),'rows, all language/detail/raw/canonical combinations\n')
}
# Validate each manifest checksum and round trip, without publishing anything.
m<-swelections:::.canonical_manifest(file.path(out,'manifest.json'));for(i in seq_len(nrow(m$assets))){p<-file.path(out,m$assets$file[i]);stopifnot(file.info(p)$size==m$assets$bytes[i],swelections:::.canonical_sha256(p)==m$assets$sha256[i])}
cat('PASS manifest/asset checksums; source values and independent denominators preserved\n')
