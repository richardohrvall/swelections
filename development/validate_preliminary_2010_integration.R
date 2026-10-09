.libPaths(c(normalizePath('.r-lib'),.libPaths()));pkgload::load_all('.',quiet=TRUE)
args <- commandArgs(trailingOnly=TRUE);dir <- args[[1]]
snap <- '.local-data/rkl/2010/valresultat/preliminary-collection-preservation-20261009'
validation <- jsonlite::fromJSON(file.path(snap,'validation.json'),simplifyVector=FALSE)
manifest <- jsonlite::fromJSON(file.path(snap,'source-manifest.json'))$sources
records <- list();counter <- 0L
number <- function(z) as.integer(.xml2014_html_number(gsub(' ','',z,fixed=TRUE)))
selected <- if(length(args)>1L) args[[2]] else c('RD','RF','KF')
for(v in selected) {
 letter <- c(RD='R',RF='L',KF='K')[[v]]
 x <- .canonical_names_sv(tibble::as_tibble(nanoparquet::read_parquet(file.path(dir,paste0('rkl2010-results-preliminar-',tolower(v),'.parquet')))))
 x <- x[x$.table=='valdistrikt',];collections <- unique(x[x$valdistriktstyp=='uppsamlingsdistrikt','valdistriktskod',drop=FALSE])
 stopifnot(nrow(collections)==if(v=='RF')392L else 395L)
 stopifnot(length(unique(x$valdistriktskod[!x$raknat]))==if(v=='RD')0L else 9L)
 unreported <- x[!x$raknat,]
 vote_fields <- intersect(c('antal_roster','antal_roster_fg','diff_antal_roster',
   'andel_roster','andel_roster_fg','diff_andel_roster','giltiga_roster','giltiga_roster_fg',
   'totalt_antal_roster','totalt_antal_roster_fg','blanka_roster','blanka_roster_fg',
   'ovriga_ogiltiga','ovriga_ogiltiga_fg','ogiltiga_roster','ogiltiga_roster_fg'),names(x))
 stopifnot(all(vapply(unreported[vote_fields],function(z)all(is.na(z)),FALSE)))
 pages <- manifest[manifest$role=='collection_district' & manifest$election==letter,];partial <- 0L;blank_cells <- 0L
 stopifnot(nrow(pages)==if(v=='RF')392L else 395L)
 for(i in seq_len(nrow(pages))) {
  doc <- xml2::read_html(file.path(snap,pages$file[[i]]),options='NONET')
  rows <- lapply(xml2::xml_find_all(doc,"//table[contains(@class,'sorteringsbar_tabell')]//tr"),function(r)trimws(gsub('\u00a0','',xml2::xml_text(xml2::xml_find_all(r,'./td')),fixed=TRUE)));rows <- rows[lengths(rows)==8]
  y <- x[x$valdistriktskod==pages$code[[i]],]
  valid <- rows[[which(vapply(rows,function(r)r[[2]]=='Giltiga r\u00f6ster',FALSE))]][[3]]
  if(nzchar(valid) && any(vapply(rows,function(r)!nzchar(r[[3]]),FALSE)))partial <- partial+1L
  for(r in rows) {
   field <- if(r[[2]]=='Giltiga r\u00f6ster')'giltiga_roster' else if(r[[1]]=='BLANK')'blanka_roster' else if(r[[1]]=='OG')'ovriga_ogiltiga' else 'antal_roster'
   z <- if(field!='antal_roster')y else if(r[[1]] %in% c('\u00d6VR','\u00d6VRIGA')) y[y$ovriga_partier %in% TRUE,] else y[y$partiforkortning %in% r[[1]],]
   stopifnot(nrow(z)>0)
   if(field=="antal_roster") stopifnot(all(vapply(z$diff_antal_roster,function(n)identical(n,number(r[[5]])),FALSE)))
   for(j in c(3L,7L)) {
    col <- paste0(field,if(j==7)'_fg' else '')
    stopifnot(all(vapply(z[[col]],function(n)identical(n,number(r[[j]])),FALSE)))
    if(!nzchar(r[[j]]))blank_cells <- blank_cells+1L
   }
  }
 }
 for(cmp in validation[[letter]]$comparisons) {
  mask <- switch(cmp$role,national=rep(TRUE,nrow(x)),municipality=x$kommunkod %in% cmp$code,
    municipal_constituency=x$kommunvalkretskod %in% cmp$code,constituency=x$valkretskod %in% cmp$code,
    region=x$lankod %in% cmp$code,regional_constituency=x$valkretskod %in% cmp$code)
  y <- x[mask,];stopifnot(nrow(y)>0)
  for(key in names(cmp$published)) {
   if(key=='ELIGIBLE')next
   field <- unname(c(VALID='giltiga_roster',BLANK='blanka_roster',OG='ovriga_ogiltiga')[key])
   if(key=='VDT') {
    z <- unique(y[c('valdistriktskod','giltiga_roster','blanka_roster','ovriga_ogiltiga')]); actual <- sum(z$giltiga_roster,na.rm=TRUE)+sum(z$blanka_roster,na.rm=TRUE)+sum(z$ovriga_ogiltiga,na.rm=TRUE)
   } else if(!is.na(field)) {
    z <- unique(y[c('valdistriktskod',field)]);actual <- sum(z[[field]],na.rm=TRUE)
   } else {
    party <- if(key=='ÖVR') y$ovriga_partier %in% TRUE else y$partiforkortning %in% key
    if(key=='ÖVR' && cmp$role=='national' && v!='RD') party <- !y$partiforkortning %in% c('M','C','FP','KD','S','V','MP','SD') | y$ovriga_partier %in% TRUE
    actual <- sum(y$antal_roster[party],na.rm=TRUE)
   }
   stopifnot(actual==cmp$published[[key]])
  }
  counter <- counter+1L
 }
 stopifnot(partial==c(RD=179L,RF=292L,KF=251L)[[v]])
 records[[v]] <- list(collections=nrow(collections),unreported=length(unique(x$valdistriktskod[!x$raknat])),partial_pages=partial,checked_blank_count_cells=blank_cells)
 cat('PASS preserved-source checks',v,'partial',partial,'blank count cells',blank_cells,'\n')
}
expected <- sum(vapply(selected,function(v)length(validation[[c(RD='R',RF='L',KF='K')[[v]]]]$comparisons),0L))
stopifnot(counter==expected)
jsonlite::write_json(list(aggregate_comparisons=counter,elections=records),paste0('.local-data/preliminary2010-source-validation-',paste(selected,collapse='-'),'.json'),auto_unbox=TRUE,pretty=TRUE)
cat('PASS',counter,'independent aggregate comparisons\n')
