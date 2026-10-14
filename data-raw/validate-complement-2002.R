# Independent complementary-source controls, including the official publication.
# Rscript data-raw/validate-complement-2002.R RAW_ROOT
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=1L) stop('Specify RAW_ROOT.')
root <- file.path(args[[1]],'2002')
pkgload::load_all('.',quiet=TRUE)
stopifnot(requireNamespace('haven',quietly=TRUE))
votes <- haven::read_dta(file.path(root,'scb/valres_parti_valdistr2002_ri.dta'))
member <- 'snd0237-10-3/data/Svenska valdata_Riksdagsvalet 2002.v2_1.sav'
tmp <- tempfile(fileext='.sav')
con <- unz(file.path(root,'snd/snd0237-10-3.zip'),member,'rb')
bytes <- readBin(con,'raw',n=1e8);close(con);writeBin(bytes,tmp)
snd <- haven::read_sav(tmp);unlink(tmp);snd[] <- lapply(snd,haven::zap_labels)
s <- swelections:::.sources_2002('local',args[[1]])
raw <- swelections:::.rd2002_complement(s,c('1380','1381','1384'))
checks <- 0L
for(code in names(raw)) {
 z <- votes[votes$llkk==code,]; t <- snd[as.character(snd$llkkff)==code,]
 district <- as.character(t$llkkffdd); district[district=='99999997'] <- paste0(code,'9800')
 out <- swelections:::.rd2002_complement_rows(raw[[code]],'valdistrikt')
 stopifnot(nrow(out)==sum(z$partikod!='9999'),!anyDuplicated(out[c('valdistriktskod','partikod','ovriga_partier')]))
 keys <- paste(z$llkkdddd,z$partikod); source_code <- ifelse(out$ovriga_partier,'9997',out$partikod)
 j <- match(paste(out$valdistriktskod,source_code),keys)
 stopifnot(!anyNA(j),identical(out$antal_roster,as.integer(z$antrost[j])))
 for(i in seq_along(district)) {
  d <- out[out$valdistriktskod==district[i],]
  stopifnot(sum(d$antal_roster)==t$giltiga[i],all(d$ogiltiga_roster==t$ogiltiga[i]),
    all(d$totalt_antal_roster==t$rostande[i]),all(d$antal_rostberattigade==t$tot[i]))
  checks <- checks+4L
 }
 postal <- out[out$valdistriktskod==paste0(code,'9800'),]
 stopifnot(all(is.na(postal$kommunvalkretskod)),all(is.na(out$antal_roster_fg)),all(is.na(out$blanka_roster)))
 cat('PASS',code,length(district),'districts',sum(t$giltiga),'valid',sum(t$ogiltiga),'invalid',sum(t$rostande),'cast',sum(t$tot),'source electorate\n')
}
# The full SCB publication provides independent ordinary/postal/municipal totals.
pdf <- file.path(root,'final-reconciliation-20261012/me01sa0301.pdf')
if(!file.exists(pdf) || !nzchar(Sys.which('pdftotext'))) stop('Preserved official SCB publication and pdftotext are required for this opt-in validation.')
text <- tempfile(fileext='.txt')
stopifnot(system2('pdftotext',c('-layout','-enc','UTF-8',shQuote(pdf),shQuote(text)))==0L)
con <- file(text,'rb'); lines <- readLines(con,encoding='UTF-8',warn=FALSE);close(con);unlink(text)
enc <- function(x) intToUtf8(utf8ToInt(x)-29L)
dec <- function(x) gsub('=',' ',intToUtf8(utf8ToInt(x)+29L),fixed=TRUE)
num <- '([0-9]+(?: [0-9]{3})*)'
pat <- paste0('^(.*?)\\s{2,}',num,'\\s+',num,'\\s+([0-9]{1,3},[0-9])',paste(rep(paste0('\\s+',num),10),collapse=''),'\\s*$')
postpat <- paste0('^räknade poströster',paste(rep(paste0('\\s+',num),11),collapse=''),'\\s*$')
totalpat <- paste0('^Hela kommunen\\s+',num,'\\s+',num,'\\s+([0-9]{1,3},[0-9])',paste(rep(paste0('\\s+',num),10),collapse=''),'\\s*$')
norm <- function(x) gsub('[^[:alnum:]]','',tolower(x))
fields <- c('tot','rostande','giltiga','ogiltiga','m','c','fp','kd','mp','s','v','vvr')
for(code in names(raw)) {
 st <- which(startsWith(lines,enc(paste0(code,' '))));st <- st[st>8500][1]
 end <- which(seq_along(lines)>st & startsWith(lines,enc('Hela kommunen')))[1]
 stopifnot(!is.na(st),!is.na(end))
 rows <- regmatches(lines[seq.int(st+1,end-1)],regexec(pat,lines[seq.int(st+1,end-1)],perl=TRUE));rows <- rows[lengths(rows)>0L]
 t <- snd[as.character(snd$llkkff)==code,]; ordinary <- t[t$llkkffdd!=99999997,]
 stopifnot(length(rows)==nrow(ordinary))
 for(row in rows) {
  j <- match(norm(row[2]),norm(ordinary$vdnamn));stopifnot(!is.na(j))
  actual <- as.double(unlist(ordinary[j,fields]));published <- as.numeric(gsub(' ','',row[c(3,4,6:15)]))
  stopifnot(identical(actual,published));checks <- checks+length(actual)
 }
 rows <- lines[seq.int(end+1,end+8)];p <- regmatches(rows,regexec(postpat,rows,perl=TRUE));p <- p[lengths(p)>0L][[1]]
 stopifnot(identical(as.numeric(gsub(' ','',p[-1])),as.double(unlist(t[t$llkkffdd==99999997,fields[-1]]))))
 p <- regmatches(dec(lines[end]),regexec(totalpat,dec(lines[end]),perl=TRUE))[[1]]
 stopifnot(identical(as.numeric(gsub(' ','',p[c(2,3,5:14)])),unname(vapply(t[fields],sum,0))))
 checks <- checks+23L
 cat('PASS independent official SCB publication',code,nrow(ordinary),'ordinary + collection + municipal controls\n')
}
cat('PASS complementary/publication numerical controls',checks,'\n')
