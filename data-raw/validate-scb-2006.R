# Independent 2006 SCB checks. SCB tables are validation inputs, never package data.
# Rscript data-raw/validate-scb-2006.R RAW_ROOT
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop('Specify RAW_ROOT.')
if (!requireNamespace('haven', quietly = TRUE)) stop('Install haven for development validation.')
root <- file.path(args[[1]], '2006')
manifest <- utils::read.csv(file.path(root, 'archived-assessment-20261011', 'source_objects.csv'))
source_file <- function(file) file.path(root, 'archived-assessment-20261011', file)
read <- function(file) xml2::read_xml(file, options = c('NONET', 'NOBLANKS'))
number <- function(x, field) as.double(xml2::xml_attr(x, field))
checks <- 0L
assert <- function(a,b,label) {
  if (!identical(as.double(a),as.double(b))) stop(label, ': ', a, ' versus ', b)
  checks <<- checks + length(a)
}
for (v in c('RD','RF','KF')) {
  suffix <- c(RD='ri', RF='lt', KF='ko')[[v]]
  long <- haven::read_dta(file.path(root,'scb',paste0('valres_parti_valdistr2006_',suffix,'.dta')))
  wide <- haven::read_dta(file.path(root,'scb',paste0('valdist_',suffix,'2006.dta')))
  duplicates <- sum(duplicated(wide))
  assert(duplicates, if (v == 'RF') 102 else 0, paste(v,'wide duplicates'))
  # A temporary analytical projection; the original RF file is untouched.
  wide <- unique(wide)
  if (v == 'KF') {
    paths <- source_file(manifest$file[grepl('^KF municipality [0-9]{4}$',manifest$coverage)])
    areas <- lapply(paths,function(p) xml2::xml_find_first(read(p),'./KOMMUN'))
  } else {
    doc <- read(source_file(paste0('objects/direct-archived-final-',v,'-XML.xml')))
    areas <- as.list(xml2::xml_find_all(doc,'.//KRETS_RIKSDAG/KOMMUN'))
  }
  assert(length(areas),if (v == 'RF') 289 else 290,paste(v,'municipality coverage'))
  codes <- vapply(areas,function(x) xml2::xml_attr(x,'KOD'),'')
  stopifnot(!anyDuplicated(codes))
  for (i in seq_along(areas)) {
    area <- areas[[i]]; code <- codes[[i]]
    scb <- long[long$llkk == code,]
    assert(number(area,'RÖSTER'),sum(scb$antrost[!scb$partikod %in% c('9998','9999')]),paste(v,code,'valid'))
    for (kind in c('BLANK','OG')) {
      official <- number(xml2::xml_find_first(area,paste0('./OGILTIGA[@TEXT="',kind,'"]')),'RÖSTER')
      assert(official,sum(scb$antrost[scb$partikod == if (kind == 'BLANK') '9998' else '9999']),paste(v,code,kind))
    }
    definitions <- c(M='0001',C='0004',FP='0003',KD='0068',MP='0055',S='0002',V='0005')
    for (alias in names(definitions)) {
      count <- number(xml2::xml_find_first(area,paste0('./GILTIGA[@PARTI="',alias,'"]')),'RÖSTER')
      assert(count,sum(scb$antrost[scb$partikod == definitions[[alias]]]),paste(v,code,alias))
    }
  }
  totals <- colSums(as.data.frame(wide[paste0(suffix,'2006_',c('giltiga','blanka','ogiltiga','antrost','rostbr'))]), na.rm = TRUE)
  expected <- switch(v,RD=c(5551278,96922,2216,5650416,6892009),RF=c(5415740,141637,2372,5559749,7052595),KF=c(5521566,112063,2474,5636103,7098097))
  assert(totals,expected,paste(v,'national district totals'))
  cat('PASS',v,'SCB municipalities/major parties/invalid/national;',duplicates,'original wide duplicates\n')
}
x <- haven::read_dta(file.path(root,'scb','mandat2006.dta'))
assert(sum(as.matrix(x[grepl('_antmand$',names(x))])),13078,'KF SCB filled seats')
cat('PASS',checks,'independent SCB checks; source files unchanged\n')
