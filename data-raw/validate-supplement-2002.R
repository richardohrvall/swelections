# Independent PDF/source controls: Rscript data-raw/validate-supplement-2002.R RAW_ROOT
# pdftotext is a development-only PDF extraction utility, never a package dependency.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=1L) stop('Specify RAW_ROOT.')
pkgload::load_all('.',quiet=TRUE)
s <- swelections:::.sources_2002('local',args[[1]])
p <- system.file('extdata','rd-2002-party-supplement-provenance.json',package='swelections')
provenance <- jsonlite::read_json(p)
pdf <- file.path(s$root,'valresultat','tillagg_ovriga.pdf')
stopifnot(unname(tools::md5sum(pdf))==provenance$md5,
 digest::digest(file=pdf,algo='sha256')==provenance$sha256)
if(!nzchar(Sys.which('pdftotext'))) stop('Independent validation requires pdftotext.')
lines <- system2('pdftotext',c('-layout',shQuote(normalizePath(pdf)),'-'),stdout=TRUE)
stopifnot(is.null(attr(lines,'status')))
parties <- c('0421','ND','NYD','Pop')
parse_counts <- function(x) vapply(1:4,function(j)
 suppressWarnings(as.integer(trimws(substr(x,c(41,51,81,100)[j],c(50,80,99,115)[j])))),integer(1))
body <- lines[(which(grepl('^Valkrets ',lines))+1):(which(grepl('^SUMMA',lines))-1)]
body <- body[nzchar(trimws(body))]
names <- trimws(substr(body,1,40))
names[names=='Kalmars län'] <- 'Kalmar län'
names[names=='Skåne läns norra/östra'] <- 'Skåne läns norra och östra'
doc <- xml2::read_xml(swelections:::.xml2002_source(s,'slutresultat_00R.xml'),options='NONET')
areas <- xml2::xml_find_all(doc,'./NATION/LÄN/KRETS_RIKSDAG')
j <- match(names,xml2::xml_attr(areas,'NAMN'));stopifnot(length(body)==29L,!anyNA(j))
expected <- do.call(rbind,lapply(seq_along(body),function(i)data.frame(
 area_code=xml2::xml_attr(areas[j[i]],'KOD'),party_alias=parties,votes=parse_counts(body[i]))))
sums <- parse_counts(lines[grepl('^SUMMA',lines)])
expected <- rbind(expected,data.frame(area_code='00',party_alias=parties,votes=sums))
lookup <- utils::read.csv(system.file('extdata','rd-2002-party-supplement.csv',package='swelections'),
 colClasses=c('character','character','integer'))
stopifnot(identical(expected,lookup),sum(is.na(expected$votes))==9L)
checks <- 0L
same <- function(a,b,label){if(!identical(a,b))stop(label,': ',paste(all.equal(a,b),collapse='; '));checks<<-checks+1L}
for(level in c('riket','riksdagsvalkrets','lan','kommun')){
 x <- swelections::valresultat(2002,val='RD',niva=level,source='local',data_dir=args[[1]],detaljniva='full')
 nodes <- switch(level,riket=xml2::xml_find_all(doc,'./NATION'),
  riksdagsvalkrets=areas,lan=xml2::xml_find_all(doc,'./NATION/LÄN'),
  kommun=xml2::xml_find_all(doc,'./NATION/LÄN/KRETS_RIKSDAG/KOMMUN'))
 for(node in nodes){code<-xml2::xml_attr(node,'KOD');g<-switch(level,riket=rep(TRUE,nrow(x)),
  riksdagsvalkrets=x$valkretskod==code,lan=x$lankod==code,kommun=x$kommunkod==code);a<-x[which(g),]
  valid<-as.integer(xml2::xml_attr(node,'RÖSTER'))
  same(unique(a$giltiga_roster),valid,paste(level,code,'valid'))
  same(as.integer(sum(as.double(a$antal_roster),na.rm=TRUE)),valid,paste(level,code,'partition'))
  cast<-as.integer(xml2::xml_attr(xml2::xml_find_first(node,'./VALDELTAGANDE'),'SUMMA_RÖSTER'))
  same(unique(a$totalt_antal_roster),cast,paste(level,code,'cast'))
  if(level=='kommun') {
    source_area <- xml2::xml_attr(xml2::xml_find_first(node,'ancestor::KRETS_RIKSDAG[1]'),'KOD')
    zeros <- expected[expected$area_code == source_area & !is.na(expected$votes) & expected$votes == 0L, ]
    for(p in zeros$party_alias) {
      hit <- if(p=='0421') a$partikod %in% '0421' else a$partiforkortning %in% p
      if(any(hit)) same(a$antal_roster[hit],0L,paste(code,p,'explicit containing-constituency zero'))
    }
    next
  }
  e<-if(level=='lan'){
   codes<-xml2::xml_attr(xml2::xml_find_all(node,'./KRETS_RIKSDAG'),'KOD')
   vals<-vapply(parties,function(p){z<-expected$votes[expected$area_code%in%codes & expected$party_alias==p];if(anyNA(z))NA_integer_ else as.integer(sum(z))},integer(1))
   data.frame(party_alias=parties,votes=vals)
  }else expected[expected$area_code==code,]
  for(i in seq_along(parties)){p<-parties[i];which_party<-if(p=='0421')a$partikod%in%'0421' else a$partiforkortning%in%p
   same(a$antal_roster[which_party],e$votes[e$party_alias==p],paste(level,code,p,'PDF/complete-county disclosure'))}
 }
}
cat('PASS independent PDF transcription: 107 disclosed / 9 undisclosed; ',checks,'public source/partition controls\n',sep='')
