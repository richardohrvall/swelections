# Independent XML controls; never normalise, rewrite or reconcile source values.
# Rscript data-raw/validate-sources-2002.R RAW_ROOT
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop('Specify RAW_ROOT.')
pkgload::load_all('.', quiet = TRUE)
s <- swelections:::.sources_2002('local', args[[1]])
read <- function(file) xml2::read_xml(swelections:::.xml2002_source(s, file), options = c('NONET', 'NOBLANKS'))
number <- function(node, field) as.double(xml2::xml_attr(node, field))
total <- function(nodes) sum(number(nodes, 'PERSONKRYSS'), na.rm = TRUE)
for (v in c('RD', 'RF', 'KF')) {
  files <- swelections:::.xml2002_files(s, v, v == 'KF')
  lists <- list(); area <- party <- other <- observed <- 0
  for (file in files) {
    doc <- read(file)
    areas <- xml2::xml_find_all(doc, switch(v,
      RD = './NATION/LÄN/KRETS_RIKSDAG', RF = './NATION/LÄN/KRETS_LANDSTING',
      KF = './KOMMUN/KRETS_KOMMUN'))
    area <- area + total(areas)
    party <- party + total(xml2::xml_find_all(areas, './GILTIGA', flatten = TRUE))
    other <- other + total(xml2::xml_find_all(areas, './GILTIGA[@PARTI="ÖVR"]', flatten = TRUE))
    observed <- observed + total(xml2::xml_find_all(areas, './GILTIGA/PERSONVAL', flatten = TRUE))
    for (a in areas) for (p in xml2::xml_find_all(a, './GILTIGA')) {
      for (l in xml2::xml_find_all(p, './VALSEDEL')) {
        lists[[length(lists) + 1L]] <- data.frame(file = file,
          area = xml2::xml_attr(a, 'KOD'), party = xml2::xml_attr(p, 'PARTI'),
          list = xml2::xml_attr(l, 'LISTNUMMER'), reported = number(l, 'PERSONKRYSS'),
          observed = total(xml2::xml_find_all(l, './PERSONVAL')))
      }
    }
  }
  x <- dplyr::bind_rows(lists)
  cat(v, 'AREA', area, 'PARTY', party, 'OTHER', other, 'IDENTIFIED', observed,
    'LIST', sum(x$reported, na.rm = TRUE), 'LIST_IDENTIFIED', sum(x$observed), '\n')
  bad <- x[!is.na(x$reported) & x$reported != x$observed, ]
  cat(v, 'list discrepancies', nrow(bad), '\n'); print(bad, row.names = FALSE)
  # Values are reported, not forced to agree. Public by-list validation stays strict.
  if (v == 'KF') {
    elected <- unfilled <- mandates <- 0
    for (file in files) {
      doc <- read(file)
      nodes <- xml2::xml_find_all(doc, './/GRUPP_VALDA/VALD')
      blank <- xml2::xml_attr(nodes, 'NAMN') %in% c('Kunde ej utses', 'Kunde inte utses')
      elected <- elected + sum(!blank); unfilled <- unfilled + sum(blank)
      mandates <- mandates + sum(number(xml2::xml_find_all(doc, './KOMMUN/GILTIGA'), 'MANDAT'), na.rm = TRUE)
      if (any(blank)) cat('UNFILLED', file, sum(blank), '\n')
    }
    stopifnot(elected == 13271, unfilled == 3, mandates == 13274)
    cat('PASS original KF mandates/elected/unfilled:', mandates, elected, unfilled, '\n')
  }
}
